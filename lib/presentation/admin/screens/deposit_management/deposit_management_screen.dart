import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/deposit_model.dart';
import '../../../../data/repositories/deposit_repository.dart';
import '../../../../services/local/connectivity_service.dart';
import '../../../../providers/language_provider.dart';
import 'add_deposit_screen.dart';

class DepositManagementScreen extends StatefulWidget {
  const DepositManagementScreen({Key? key}) : super(key: key);

  @override
  State<DepositManagementScreen> createState() => _DepositManagementScreenState();
}

class _DepositManagementScreenState extends State<DepositManagementScreen> {
  String _selectedFilter = 'All';
  String _searchQuery = '';
  final _depositRepository = DepositRepository();

  List<DepositModel> _filterDeposits(List<DepositModel> deposits) {
    return deposits.where((deposit) {
      final matchesSearch = _searchQuery.isEmpty ||
          deposit.userName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          deposit.reference.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          deposit.id.contains(_searchQuery);

      final matchesFilter = _selectedFilter == 'All' || 
          deposit.method.toLowerCase() == _selectedFilter.toLowerCase();

      return matchesSearch && matchesFilter;
    }).toList();
  }

  double _calculateTotalDeposits(List<DepositModel> deposits) {
    return deposits
        .where((d) => d.status.toLowerCase() == 'completed')
        .fold(0.0, (sum, deposit) => sum + deposit.amount);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final connectivity = Provider.of<ConnectivityService>(context);
    final lang = Provider.of<LanguageProvider>(context);

    // Dynamic filters
    final filterLabels = {
      'All': lang.translate('view_all'),
      'Cash': lang.translate('cash'),
      'Bank Transfer': lang.translate('bank_transfer'),
      'Mobile Banking': lang.translate('mobile_banking'),
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.translate('deposit_management_title')),
        elevation: 0,
        actions: [
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
                      connectivity.isOnline ? lang.translate('online') : lang.translate('offline'),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddDepositScreen(),
            ),
          );
          if (result == true && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(lang.translate('deposit_added_success')),
                backgroundColor: AppColors.lightSuccess,
              ),
            );
          }
        },
        label: Text(lang.translate('add_deposit')),
        icon: const Icon(Icons.add),
        backgroundColor: AppColors.lightSuccess,
      ),
      body: Column(
        children: [
          // Total Deposits Card
          StreamBuilder<List<DepositModel>>(
            stream: _depositRepository.getAllDepositsStream(),
            builder: (context, snapshot) {
              final deposits = snapshot.data ?? [];
              final total = _calculateTotalDeposits(deposits);
              final transactionCount = deposits
                  .where((d) => d.status.toLowerCase() == 'completed')
                  .length;

              return Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.lightSuccess, AppColors.lightSuccess.withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.lightSuccess.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.account_balance_wallet, color: Colors.white, size: 32),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(lang.translate('total_deposits'), style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14)),
                          const SizedBox(height: 4),
                          Text('৳ ${total.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('$transactionCount ${lang.translate('transactions')}', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // Search and Filter Section
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                TextField(
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    hintText: lang.translate('search_by_username'),
                    prefixIcon: const Icon(Icons.search),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All', filterLabels['All']!, isDark),
                      const SizedBox(width: 8),
                      _buildFilterChip('Cash', filterLabels['Cash']!, isDark),
                      const SizedBox(width: 8),
                      _buildFilterChip('Bank Transfer', filterLabels['Bank Transfer']!, isDark),
                      const SizedBox(width: 8),
                      _buildFilterChip('Mobile Banking', filterLabels['Mobile Banking']!, isDark),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),

          // Deposit List
          Expanded(
            child: StreamBuilder<List<DepositModel>>(
              stream: _depositRepository.getAllDepositsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(color: AppColors.lightPrimary));
                }

                if (snapshot.hasError) {
                  print('❌ Deposit Stream Error: ${snapshot.error}');
                  print('❌ Deposit Stream Stack Trace: ${snapshot.stackTrace}');
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 80, color: Colors.red[400]),
                        const SizedBox(height: 16),
                        Text(lang.translate('error_loading_deposits'), style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text('${snapshot.error}', style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
                        ),
                      ],
                    ),
                  );
                }

                final deposits = snapshot.data ?? [];
                final filteredDeposits = _filterDeposits(deposits);

                if (filteredDeposits.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.account_balance_wallet_outlined, size: 80, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(lang.translate('no_deposits_found'), style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 8),
                        Text(
                          _searchQuery.isEmpty ? lang.translate('start_adding_deposit') : lang.translate('try_different_search'),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                  itemCount: filteredDeposits.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) => _buildDepositCard(filteredDeposits[index], isDark, lang),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String filterValue, String label, bool isDark) {
    final isSelected = _selectedFilter == filterValue;
    return InkWell(
      onTap: () => setState(() => _selectedFilter = filterValue),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.lightPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.lightPrimary : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
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

  Widget _buildDepositCard(DepositModel deposit, bool isDark, LanguageProvider lang) {
    final statusColor = deposit.status.toLowerCase() == 'completed'
        ? Colors.green
        : deposit.status.toLowerCase() == 'pending'
            ? Colors.orange
            : Colors.red;

    return InkWell(
      onTap: () => _showDepositDetails(deposit, isDark, lang),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.lightSuccess.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.arrow_downward, color: AppColors.lightSuccess, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        deposit.userName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ID: ${deposit.id.substring(0, deposit.id.length > 10 ? 10 : deposit.id.length)}',
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '৳ ${deposit.amount.toStringAsFixed(1)}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.lightSuccess,
                          ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(lang.translate('method'), style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
                    Text(deposit.method, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(lang.translate('reference'), style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
                    Text(deposit.reference, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    deposit.status.toUpperCase(),
                    style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(DateFormat('dd/MM/yyyy').format(deposit.date), style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
                Text('${lang.translate('by')}: Admin', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ],
        ),
      ),
    );
  }


  void _showDepositDetails(DepositModel deposit, bool isDark, LanguageProvider lang) {
    final statusColor = deposit.status.toLowerCase() == 'completed'
        ? Colors.green
        : deposit.status.toLowerCase() == 'pending'
            ? Colors.orange
            : Colors.red;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCardBg : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    lang.translate('deposit_details'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      deposit.status.toUpperCase(),
                      style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildDetailRow(lang.translate('user_name'), deposit.userName),
              _buildDetailRow(lang.translate('amount'), '৳ ${deposit.amount.toStringAsFixed(2)}', color: Colors.green),
              _buildDetailRow(lang.translate('method'), deposit.method),
              _buildDetailRow(lang.translate('reference'), deposit.reference),
              _buildDetailRow(lang.translate('date'), DateFormat('MMM dd, yyyy').format(deposit.date)),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context); // Close sheet
                        _navigateToEditScreen(deposit); // Navigate to edit
                      },
                      icon: const Icon(Icons.edit, color: AppColors.lightPrimary),
                      label: Text(lang.translate('edit')),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.lightPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: AppColors.lightPrimary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _deleteDeposit(deposit.id, lang);
                      },
                      icon: const Icon(Icons.delete),
                      label: Text(lang.translate('delete')),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  void _navigateToEditScreen(DepositModel deposit) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddDepositScreen(deposit: deposit),
      ),
    );
    
    // Result handling is already done in the screen itself showing snackbar, 
    // but we might want to refresh if needed, though StreamBuilder handles it.
  }

  void _deleteDeposit(String depositId, LanguageProvider lang) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(lang.translate('delete_deposit_title')),
        content: Text(lang.translate('delete_deposit_confirm')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(lang.translate('cancel'))),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _depositRepository.deleteDeposit(depositId);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(lang.translate('deposit_deleted_success'))),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${lang.translate('error')}: $e')),
                  );
                }
              }
            },
            child: Text(lang.translate('delete'), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}