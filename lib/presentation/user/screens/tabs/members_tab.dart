import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../providers/language_provider.dart';
import '../../../../data/repositories/user_repository.dart';
import '../../../../data/models/user_model.dart';

class MembersTab extends StatefulWidget {
  const MembersTab({Key? key}) : super(key: key);

  @override
  State<MembersTab> createState() => _MembersTabState();
}

class _MembersTabState extends State<MembersTab> {
  final UserRepository _userRepository = UserRepository();
  String _searchQuery = '';
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RefreshIndicator(
      onRefresh: () async {
        setState(() {});
        await Future.delayed(const Duration(milliseconds: 400));
      },
      child: Column(
        children: [
          // Header Section with Search and Stats
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.lightPrimary, AppColors.lightSecondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // Real-time member count header
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .where('status', isEqualTo: 'Active')
                        .snapshots(),
                    builder: (context, snapshot) {
                      final memberCount =
                          snapshot.hasData ? snapshot.data!.docs.length : 0;

                      return Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.people,
                              color: Colors.white,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  languageProvider.translate('members'),
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$memberCount ${languageProvider.translate('active')} ${languageProvider.translate('members')}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  // Search Bar
                  TextField(
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: languageProvider.translate('search_users'),
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.65),
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Colors.white,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.white70),
                              onPressed: () {
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.2),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Filter Chips
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: languageProvider.translate('all_users'),
                    isSelected: _selectedFilter == 'All',
                    onTap: () {
                      setState(() {
                        _selectedFilter = 'All';
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: languageProvider.translate('active'),
                    isSelected: _selectedFilter == 'Active',
                    onTap: () {
                      setState(() {
                        _selectedFilter = 'Active';
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: languageProvider.translate('pending'),
                    isSelected: _selectedFilter == 'Pending',
                    onTap: () {
                      setState(() {
                        _selectedFilter = 'Pending';
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: languageProvider.translate('blocked'),
                    isSelected: _selectedFilter == 'Blocked',
                    onTap: () {
                      setState(() {
                        _selectedFilter = 'Blocked';
                      });
                    },
                  ),
                ],
              ),
            ),
          ),

          // Members List
          Expanded(
            child: StreamBuilder<List<UserModel>>(
              stream: _userRepository.getAllUsersStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 60,
                          color: Colors.red[400],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          languageProvider.translate('error_loading_members'),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  );
                }

                final allUsers = snapshot.data ?? [];

                if (allUsers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 60,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          languageProvider.translate('no_users_found'),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  );
                }

                final members = allUsers.where((user) {
                  final status = user.status.toString();
                  if (_selectedFilter != 'All' &&
                      status.toLowerCase() != _selectedFilter.toLowerCase()) {
                    return false;
                  }

                  final name = user.name.toString().toLowerCase();
                  final email = user.email.toString().toLowerCase();
                  final phone = user.phone.toString();

                  return _searchQuery.isEmpty ||
                      name.contains(_searchQuery.toLowerCase()) ||
                      email.contains(_searchQuery.toLowerCase()) ||
                      phone.contains(_searchQuery);
                }).toList();

                if (members.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 60,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          languageProvider.translate('no_results_found'),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  );
                }

                final now = DateTime.now();

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount: members.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final user = members[index];
                    final createdAt = user.createdAt;
                    
                    // Calculate months deposited & due months (1000 TK per month standard)
                    final totalDeposits = user.totalDeposits;
                    final paidMonths = (totalDeposits / 1000.0).floor();
                    
                    final totalExpectedMonths =
                        (now.year - createdAt.year) * 12 + now.month - createdAt.month + 1;
                    
                    final dueMonths = (totalExpectedMonths - paidMonths).clamp(0, 999);

                    return _MemberCard(
                      user: user,
                      name: user.name,
                      phone: user.phone,
                      email: user.email,
                      totalDeposits: totalDeposits,
                      paidMonths: paidMonths,
                      dueMonths: dueMonths,
                      totalExpectedMonths: totalExpectedMonths,
                      status: user.status,
                      createdAt: createdAt,
                      role: user.role,
                      photoUrl: user.photoUrl,
                      onTap: () {
                        _showMemberDepositDetailsSheet(
                          context,
                          user: user,
                          paidMonths: paidMonths,
                          dueMonths: dueMonths,
                          totalExpectedMonths: totalExpectedMonths,
                          totalDeposits: totalDeposits,
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showMemberDepositDetailsSheet(
    BuildContext context, {
    required UserModel user,
    required int paidMonths,
    required int dueMonths,
    required int totalExpectedMonths,
    required double totalDeposits,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _MemberDetailBottomSheet(
        user: user,
        paidMonths: paidMonths,
        dueMonths: dueMonths,
        totalExpectedMonths: totalExpectedMonths,
        totalDeposits: totalDeposits,
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 7,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.lightPrimary
              : Theme.of(context).brightness == Brightness.dark
                  ? AppColors.darkCardBg
                  : AppColors.lightCardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.lightPrimary
                : Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkBorder
                    : AppColors.lightBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : Theme.of(context).textTheme.bodyMedium?.color,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  final UserModel user;
  final String name;
  final String phone;
  final String email;
  final double totalDeposits;
  final int paidMonths;
  final int dueMonths;
  final int totalExpectedMonths;
  final String status;
  final DateTime createdAt;
  final String role;
  final String? photoUrl;
  final VoidCallback onTap;

  const _MemberCard({
    required this.user,
    required this.name,
    required this.phone,
    required this.email,
    required this.totalDeposits,
    required this.paidMonths,
    required this.dueMonths,
    required this.totalExpectedMonths,
    required this.status,
    required this.createdAt,
    required this.role,
    this.photoUrl,
    required this.onTap,
  });

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
      case 'blocked':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor = _getStatusColor(status);
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Avatar, Name, Email & Status Badge
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: role == 'admin'
                          ? const LinearGradient(
                              colors: [Color(0xFF7C3AED), Color(0xFFEC4899)],
                            )
                          : const LinearGradient(
                              colors: [AppColors.lightPrimary, AppColors.lightSecondary],
                            ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: (photoUrl != null && photoUrl!.isNotEmpty)
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: CachedNetworkImage(
                                imageUrl: photoUrl!,
                                width: 48,
                                height: 48,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.person, color: Colors.grey),
                                ),
                                errorWidget: (context, url, error) => Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : 'U',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            )
                          : Text(
                              name.isNotEmpty ? name[0].toUpperCase() : 'U',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        if (phone.isNotEmpty)
                          Text(
                            phone,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: isDark ? Colors.white70 : Colors.black87,
                                ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      languageProvider.translate('status_${status.toLowerCase()}').toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),
              Divider(
                height: 1,
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
              const SizedBox(height: 12),

              // Total Months Deposited, Due Months, Total Deposit Amount
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 1. Months Deposited (কত মাস জমা)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.green.withOpacity(0.25)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          languageProvider.translate('total_months_deposited'),
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.green[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '$paidMonths ${languageProvider.translate('months')}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 2. Due Months (বাকি কত মাস)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: (dueMonths > 0 ? Colors.red : Colors.blue).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: (dueMonths > 0 ? Colors.red : Colors.blue).withOpacity(0.25),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          languageProvider.translate('total_months_due'),
                          style: TextStyle(
                            fontSize: 10,
                            color: dueMonths > 0 ? Colors.red[700] : Colors.blue[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '$dueMonths ${languageProvider.translate('months')}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: dueMonths > 0 ? Colors.red : Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 3. Total Deposited (মোট জমা টাকা)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        languageProvider.translate('total_deposits'),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '৳ ${NumberFormat('#,##0').format(totalDeposits)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.lightPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Detailed Modal Bottom Sheet showing Month-by-Month Serial Breakdown & Receipts
class _MemberDetailBottomSheet extends StatefulWidget {
  final UserModel user;
  final int paidMonths;
  final int dueMonths;
  final int totalExpectedMonths;
  final double totalDeposits;

  const _MemberDetailBottomSheet({
    Key? key,
    required this.user,
    required this.paidMonths,
    required this.dueMonths,
    required this.totalExpectedMonths,
    required this.totalDeposits,
  }) : super(key: key);

  @override
  State<_MemberDetailBottomSheet> createState() => _MemberDetailBottomSheetState();
}

class _MemberDetailBottomSheetState extends State<_MemberDetailBottomSheet> {
  int _selectedTabIndex = 0; // 0: Monthly Serial Breakdown, 1: Receipts List

  String _toBanglaDigits(int number, bool isBangla) {
    if (!isBangla) return number.toString();
    const banglaDigits = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    return number.toString().split('').map((ch) {
      final idx = int.tryParse(ch);
      return idx != null ? banglaDigits[idx] : ch;
    }).join('');
  }

  String _getMonthSerialName(int index, bool isBangla) {
    final serial = index + 1;
    if (isBangla) {
      switch (serial) {
        case 1:
          return '১ম মাস';
        case 2:
          return '২য় মাস';
        case 3:
          return '৩য় মাস';
        case 4:
          return '৪র্থ মাস';
        case 5:
          return '৫ম মাস';
        case 6:
          return '৬ষ্ঠ মাস';
        case 7:
          return '৭ম মাস';
        case 8:
          return '৮ম মাস';
        case 9:
          return '৯ম মাস';
        case 10:
          return '১০ম মাস';
        default:
          return '${_toBanglaDigits(serial, true)}তম মাস';
      }
    } else {
      switch (serial) {
        case 1:
          return '1st Month';
        case 2:
          return '2nd Month';
        case 3:
          return '3rd Month';
        default:
          return '${serial}th Month';
      }
    }
  }

  String _formatBanglaMonthYear(DateTime date, bool isBangla) {
    if (isBangla) {
      const banglaMonths = [
        'জানুয়ারি',
        'ফেব্রুয়ারি',
        'মার্চ',
        'এপ্রিল',
        'মে',
        'জুন',
        'জুলাই',
        'আগস্ট',
        'সেপ্টেম্বর',
        'অক্টোবর',
        'নভেম্বর',
        'ডিসেম্বর'
      ];
      final monthName = banglaMonths[date.month - 1];
      final yearStr = _toBanglaDigits(date.year, true);
      return '$monthName $yearStr';
    } else {
      return DateFormat('MMMM yyyy').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isBangla = languageProvider.locale.languageCode == 'bn';

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Drag Handle
          const SizedBox(height: 12),
          Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 12),

          // Header Title and Close Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  languageProvider.translate('member_details'),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Member Profile Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: widget.user.role == 'admin'
                            ? [const Color(0xFF7C3AED), const Color(0xFFEC4899)]
                            : [AppColors.lightPrimary, AppColors.lightSecondary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.lightPrimary.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.white.withOpacity(0.25),
                          child: Text(
                            widget.user.name.isNotEmpty
                                ? widget.user.name[0].toUpperCase()
                                : 'U',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.user.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              if (widget.user.phone.isNotEmpty)
                                Row(
                                  children: [
                                    const Icon(Icons.phone, size: 14, color: Colors.white70),
                                    const SizedBox(width: 6),
                                    Text(
                                      widget.user.phone,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today, size: 13, color: Colors.white70),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${languageProvider.translate('member_since')}: ${_formatBanglaMonthYear(widget.user.createdAt, isBangla)}',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 3 Summary Cards: Total Money, Paid Months, Due Months
                  Row(
                    children: [
                      // 1. Total Deposits (মোট জমা)
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.blue.withOpacity(0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                languageProvider.translate('total_joma'),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.blue[700],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '৳ ${NumberFormat('#,##0').format(widget.totalDeposits)}',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // 2. Paid Months (পরিশোধিত মাস)
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.green.withOpacity(0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                languageProvider.translate('total_paid_months'),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.green[700],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${widget.paidMonths} ${languageProvider.translate('months')}',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // 3. Due Months (বাকি মাস)
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: (widget.dueMonths > 0 ? Colors.red : Colors.teal)
                                .withOpacity(0.08),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: (widget.dueMonths > 0 ? Colors.red : Colors.teal)
                                  .withOpacity(0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                languageProvider.translate('total_months_due'),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: widget.dueMonths > 0
                                      ? Colors.red[700]
                                      : Colors.teal[700],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${widget.dueMonths} ${languageProvider.translate('months')}',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: widget.dueMonths > 0 ? Colors.red : Colors.teal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // View Selector (Segmented tabs)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCardBg : Colors.grey[100],
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() => _selectedTabIndex = 0),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _selectedTabIndex == 0
                                    ? AppColors.lightPrimary
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                languageProvider.translate('monthly_breakdown'),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: _selectedTabIndex == 0
                                      ? Colors.white
                                      : (isDark ? Colors.white70 : Colors.black87),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() => _selectedTabIndex = 1),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _selectedTabIndex == 1
                                    ? AppColors.lightPrimary
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                languageProvider.translate('deposit_history'),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: _selectedTabIndex == 1
                                      ? Colors.white
                                      : (isDark ? Colors.white70 : Colors.black87),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // TAB 0: Month-by-Month Serial Breakdown
                  if (_selectedTabIndex == 0) ...[
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: widget.totalExpectedMonths > 0
                          ? widget.totalExpectedMonths
                          : 1,
                      separatorBuilder: (context, i) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final isPaid = i < widget.paidMonths;
                        final targetDate = DateTime(
                          widget.user.createdAt.year,
                          widget.user.createdAt.month + i,
                          1,
                        );
                        final serialLabel = _getMonthSerialName(i, isBangla);
                        final monthYearText =
                            _formatBanglaMonthYear(targetDate, isBangla);

                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isPaid
                                ? Colors.green.withOpacity(0.06)
                                : Colors.red.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isPaid
                                  ? Colors.green.withOpacity(0.3)
                                  : Colors.red.withOpacity(0.25),
                            ),
                          ),
                          child: Row(
                            children: [
                              // Serial Indicator Badge
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: isPaid ? Colors.green : Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  _toBanglaDigits(i + 1, isBangla),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              // Month & Serial Name
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      monthYearText,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      serialLabel,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark
                                            ? Colors.white70
                                            : Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Status & Amount
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isPaid
                                          ? Colors.green.withOpacity(0.15)
                                          : Colors.red.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isPaid
                                              ? Icons.check_circle
                                              : Icons.hourglass_top,
                                          size: 13,
                                          color: isPaid ? Colors.green : Colors.red,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          isPaid
                                              ? languageProvider
                                                  .translate('month_paid')
                                              : languageProvider
                                                  .translate('month_due'),
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: isPaid ? Colors.green : Colors.red,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    isPaid ? '৳ ১,০০০' : '৳ ১,০০০ (বকেয়া)',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isPaid
                                          ? (isDark ? Colors.white70 : Colors.black87)
                                          : Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],

                  // TAB 1: Actual Receipts List
                  if (_selectedTabIndex == 1) ...[
                    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance
                          .collection('deposits')
                          .where('userId', isEqualTo: widget.user.id)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        final docs = snapshot.data?.docs ?? [];
                        if (docs.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.receipt_long_outlined,
                                    size: 48,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'এখনো কোনো জমার রসিদ পাওয়া যায়নি',
                                    style: TextStyle(color: Colors.grey[500]),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        // Sort in-memory to prevent indexing requirements
                        final deposits = docs.map((d) => d.data()).toList();
                        deposits.sort((a, b) {
                          final aDate = (a['date'] as Timestamp?)?.toDate() ?? DateTime.now();
                          final bDate = (b['date'] as Timestamp?)?.toDate() ?? DateTime.now();
                          return bDate.compareTo(aDate);
                        });

                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: deposits.length,
                          separatorBuilder: (context, i) => const SizedBox(height: 10),
                          itemBuilder: (context, i) {
                            final item = deposits[i];
                            final amount = (item['amount'] as num?)?.toDouble() ?? 0.0;
                            final date = (item['date'] as Timestamp?)?.toDate() ?? DateTime.now();
                            final depositType = item['depositType'] ?? 'Cash';
                            final referenceId = item['referenceId'] ?? '';

                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.check_circle_outline,
                                      color: Colors.green,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '৳ ${NumberFormat('#,##0').format(amount)}',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          DateFormat('dd MMM yyyy, hh:mm a').format(date),
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isDark ? Colors.white70 : Colors.grey[600],
                                          ),
                                        ),
                                        if (referenceId.isNotEmpty)
                                          Text(
                                            'Ref: $referenceId ($depositType)',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.grey[500],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'Completed',
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
