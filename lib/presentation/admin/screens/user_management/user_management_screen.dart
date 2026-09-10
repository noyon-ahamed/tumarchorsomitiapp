import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/user_model.dart';
import '../../../../data/repositories/user_repository.dart';
import '../../../../services/local/connectivity_service.dart';
import '../../../../providers/language_provider.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({Key? key}) : super(key: key);

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  String _selectedFilter = 'All';
  String _searchQuery = '';
  late UserRepository _userRepository;

  @override
  void initState() {
    super.initState();
    _userRepository = UserRepository();
  }

  List<UserModel> _filterUsers(List<UserModel> users) {
    return users.where((user) {
      // Search filter
      final matchesSearch = _searchQuery.isEmpty ||
          user.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          user.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          user.phone.contains(_searchQuery);

      // Status filter - FIXED: Proper case matching
      final matchesFilter = _selectedFilter == 'All' ||
          user.status.toLowerCase() == _selectedFilter.toLowerCase();

      return matchesSearch && matchesFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final connectivity = Provider.of<ConnectivityService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(languageProvider.translate('user_management')),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.published_with_changes),
            tooltip: 'Fix Balance Discrepancies',
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Reconcile All Balances?'),
                  content: const Text(
                    'This will recalculate total deposits and available balance for ALL users in the database. Use this only to fix discrepancies.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Reconcile'),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Starting global reconciliation...')),
                );
                
                try {
                  await _userRepository.reconcileAllUsersBalances();
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Global Reconciliation Complete!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('❌ Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: connectivity.isOnline 
                    ? Colors.green.withOpacity(0.2)
                    : Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      connectivity.isOnline ? Icons.cloud_done : Icons.cloud_off,
                      size: 14,
                      color: connectivity.isOnline ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      connectivity.isOnline 
                        ? languageProvider.translate('online') 
                        : languageProvider.translate('offline'),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: connectivity.isOnline ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCardBg : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: languageProvider.translate('search_users'),
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Filter Chips - FIXED
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(languageProvider.translate('all'), languageProvider.translate('all'), isDark),
                      const SizedBox(width: 8),
                      _buildFilterChip(languageProvider.translate('active'), 'Active', isDark),
                      const SizedBox(width: 8),
                      _buildFilterChip(languageProvider.translate('pending'), 'Pending', isDark),
                      const SizedBox(width: 8),
                      _buildFilterChip(languageProvider.translate('blocked'), 'Blocked', isDark),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // User List
          Expanded(
            child: StreamBuilder<List<UserModel>>(
              stream: _userRepository.getAllUsersStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: AppColors.lightPrimary,
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 80,
                          color: Colors.red[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading users',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          snapshot.error.toString(),
                          style: Theme.of(context).textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                final users = snapshot.data ?? [];
                final filteredUsers = _filterUsers(users);

                if (filteredUsers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          languageProvider.translate('no_users_found'),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          languageProvider.translate('try_different_search'),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredUsers.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final user = filteredUsers[index];
                    return _buildUserCard(user, isDark, languageProvider);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, bool isDark) {
    final isSelected = _selectedFilter == value;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedFilter = value;
        });
        debugPrint('Filter changed to: $value');
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.lightPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.lightPrimary
                : isDark
                    ? AppColors.darkBorder
                    : AppColors.lightBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : null,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard(UserModel user, bool isDark, LanguageProvider languageProvider) {
    final statusColor = _getStatusColor(user.status);
    final statusLabel = user.status.toUpperCase();

    return InkWell(
      onTap: () => _showUserDetailsBottomSheet(user, isDark, languageProvider),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Column(
          children: [
            // Header with avatar and basic info
            Row(
              children: [
                // Avatar
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: user.role == 'admin'
                        ? const LinearGradient(
                            colors: [Color(0xFF7C3AED), Color(0xFFEC4899)],
                          )
                        : const LinearGradient(
                            colors: [
                              AppColors.lightPrimary,
                              AppColors.lightSecondary
                            ],
                          ),
                    borderRadius: BorderRadius.circular(12),
                    image: (user.photoUrl.isNotEmpty) ? DecorationImage(
                      image: CachedNetworkImageProvider(user.photoUrl),
                      fit: BoxFit.cover,
                    ) : null,
                  ),
                  child: Center(
                    child: (user.photoUrl.isNotEmpty) ? Container() : Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // User info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (user.phone.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          user.phone,
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    languageProvider.translate(user.status.toLowerCase()),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Divider
            Divider(
              height: 1,
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
            const SizedBox(height: 12),
            // Balance and date info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      languageProvider.translate('balance'),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '৳ ${user.balance.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      languageProvider.translate('joined'),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('MMM dd, yyyy').format(user.createdAt),
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ],
                ),
              ],
            ),
            // ✅ DEPOSIT DUE INDICATOR
            _buildDueIndicator(user, languageProvider),
            // ✅ Action buttons for PENDING users
            if (user.status.toLowerCase() == 'pending') ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _approveUser(user.id, user.name),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _rejectUser(user.id, user.name),
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Reject'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showUserDetailsBottomSheet(UserModel user, bool isDark, LanguageProvider languageProvider) {
    final statusColor = _getStatusColor(user.status);

    showModalBottomSheet(
      context: context,
      isDismissible: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCardBg : Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: user.role == 'admin'
                            ? const LinearGradient(
                                colors: [Color(0xFF7C3AED), Color(0xFFEC4899)],
                              )
                            : const LinearGradient(
                                colors: [
                                  AppColors.lightPrimary,
                                  AppColors.lightSecondary
                                ],
                              ),
                        borderRadius: BorderRadius.circular(12),
                        image: (user.photoUrl.isNotEmpty) ? DecorationImage(
                          image: CachedNetworkImageProvider(user.photoUrl),
                          fit: BoxFit.cover,
                        ) : null,
                      ),
                      child: Center(
                        child: (user.photoUrl.isNotEmpty) ? Container() : Text(
                          user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name,
                            style:
                                Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              languageProvider.translate(user.status.toLowerCase()),
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Details
                 _buildDetailRow(languageProvider.translate('email'), user.email),
                _buildDetailRow(languageProvider.translate('phone_number'), user.phone.isNotEmpty ? user.phone : 'N/A'),
                _buildDetailRow(languageProvider.translate('role'), languageProvider.translate(user.role.toLowerCase())),
                 _buildDetailRow(
                  languageProvider.translate('balance'),
                  '৳ ${user.balance.toStringAsFixed(2)}',
                  color: Colors.green,
                ),
                _buildDetailRow(
                  languageProvider.translate('joined'),
                  DateFormat('MMM dd, yyyy').format(user.createdAt),
                ),
                _buildDetailRow(
                  languageProvider.translate('last_updated'),
                  DateFormat('MMM dd, yyyy').format(user.updatedAt),
                ),
                if (user.adminNotes != null && user.adminNotes!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    languageProvider.translate('admin_notes'),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkBorder.withOpacity(0.5)
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      user.adminNotes!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                // Action buttons
                if (user.status.toLowerCase() == 'pending')
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _approveUser(user.id, user.name);
                          },
                          icon: const Icon(Icons.check),
                          label: Text(languageProvider.translate('approve')),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _rejectUser(user.id, user.name);
                          },
                          icon: const Icon(Icons.close),
                          label: Text(languageProvider.translate('reject')),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                if (user.status.toLowerCase() == 'active') ...[
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _blockUser(user.id, user.name);
                    },
                    icon: const Icon(Icons.block),
                    label: Text(languageProvider.translate('block_user')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                
                const SizedBox(height: 12),
                // Edit Deposits Button (Migration Tool)
                OutlinedButton.icon(
                  onPressed: () => _editTotalDeposits(user),
                  icon: const Icon(Icons.account_balance_wallet, size: 20),
                  label: Text(languageProvider.translate('edit_total_deposits')),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 12),
                // Edit Join Date Button (Always available for migration)
                OutlinedButton.icon(
                  onPressed: () => _editJoinDate(user),
                  icon: const Icon(Icons.calendar_month, size: 20),
                  label: Text(languageProvider.translate('edit_join_date')),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _editJoinDate(UserModel user) async {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: user.createdAt,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != user.createdAt) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.id).update({
          'createdAt': Timestamp.fromDate(picked),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(languageProvider.translate('operation_success')),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${languageProvider.translate('operation_failed')}: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }


  

  Future<void> _editTotalDeposits(UserModel user) async {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final controller = TextEditingController(text: user.totalDeposits.toStringAsFixed(0));
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(languageProvider.translate('edit_total_deposits')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Update the total historical deposits for ${user.name}. This will also adjust their current balance.'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Total Deposits (৳)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(languageProvider.translate('cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(languageProvider.translate('save')),
          ),
        ],
      ),
    );

    if (result == true) {
      final newAmount = double.tryParse(controller.text);
      if (newAmount == null) return;

      try {
        await _userRepository.updateUserTotalDeposits(user.id, newAmount);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(languageProvider.translate('operation_success'))),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${languageProvider.translate('operation_failed')}: $e')),
          );
        }
      }
    }
  }

  Widget _buildDetailRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'blocked':
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildDueIndicator(UserModel user, LanguageProvider languageProvider) {
    if (user.status.toLowerCase() != 'active') return const SizedBox.shrink();

    final now = DateTime.now();
    final totalExpectedMonths = (now.year - user.createdAt.year) * 12 + now.month - user.createdAt.month + 1;
    final currentTotalDeposits = user.totalDeposits;
    final pendingMonths = ((totalExpectedMonths * 1000.0 - currentTotalDeposits) / 1000.0).ceil();

    if (pendingMonths <= 0) return const SizedBox.shrink();

    String dueText = '';
    if (pendingMonths == 1) {
      String monthName = '';
      for (int i = 0; i < totalExpectedMonths; i++) {
        if ((i + 1) * 1000.0 > currentTotalDeposits) {
          final dueMonthDate = DateTime(user.createdAt.year, user.createdAt.month + i);
          monthName = DateFormat('MMMM').format(dueMonthDate).toLowerCase();
          break;
        }
      }
      dueText = '${languageProvider.translate('due')}: ${languageProvider.translate(monthName)}';
    } else {
      dueText = '${languageProvider.translate('due')}: $pendingMonths ${languageProvider.translate('months')}';
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.orange.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber_rounded, size: 14, color: Colors.orange),
            const SizedBox(width: 6),
            Text(
              dueText,
              style: const TextStyle(
                color: Colors.orange,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ APPROVE USER - Fixed
  Future<void> _approveUser(String uid, String name) async {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    try {
      debugPrint('🔄 Approving user: $uid ($name)');

      // Show loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Text(languageProvider.translate('approving_user')),
              ],
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }

      // Update user status in Firestore
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'status': 'Active',
        'approvedAt': FieldValue.serverTimestamp(),
        'approvedBy': FirebaseAuth.instance.currentUser?.uid,
      });

      debugPrint('✅ User approved successfully: $uid');

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('$name ${languageProvider.translate('user_approved')}')),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error approving user: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('${languageProvider.translate('operation_failed')}: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  // ✅ REJECT USER - Fixed
  Future<void> _rejectUser(String uid, String name) async {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    // Show confirmation dialog first
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject User?'),
        content: Text('Are you sure you want to reject $name?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      debugPrint('🔄 Rejecting user: $uid ($name)');

      // Show loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 12),
                Text('Rejecting user...'),
              ],
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Update user status
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'status': 'Rejected',
        'rejectedAt': FieldValue.serverTimestamp(),
        'rejectedBy': FirebaseAuth.instance.currentUser?.uid,
      });

      debugPrint('✅ User rejected successfully: $uid');

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.block, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('$name has been rejected')),
              ],
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error rejecting user: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Failed to reject user: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  // ✅ BLOCK USER
  void _blockUser(String userId, String userName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Block User'),
        content: Text('Block $userName from accessing the platform?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _userRepository.updateUserStatus(userId, 'Blocked');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$userName blocked')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error blocking user: $e')),
                  );
                }
              }
            },
            child: const Text('Block', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}