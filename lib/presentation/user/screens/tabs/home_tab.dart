import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../providers/language_provider.dart';
import '../../../../providers/authprovider.dart';
import '../../../../data/repositories/deposit_repository.dart';
import '../../../../data/repositories/user_repository.dart';
import '../../../../data/repositories/transaction_repository.dart';
import '../../../../data/models/deposit_model.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({Key? key}) : super(key: key);

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final DepositRepository _depositRepository = DepositRepository();
  final UserRepository _userRepository = UserRepository();
  final TransactionRepository _transactionRepository = TransactionRepository();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final userId = authProvider.userData?['uid'] ?? authProvider.user?.uid ?? '';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RefreshIndicator(
      onRefresh: () async {
        setState(() {});
        await Future.delayed(const Duration(milliseconds: 400));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Header Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.lightPrimary,
                    AppColors.lightSecondary.withOpacity(0.85),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.lightPrimary.withOpacity(0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  if (authProvider.userData?['photoUrl'] != null &&
                      (authProvider.userData!['photoUrl'] as String).isNotEmpty)
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white,
                      backgroundImage: CachedNetworkImageProvider(
                        authProvider.userData!['photoUrl'] as String,
                      ),
                    )
                  else
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white,
                      child: Text(
                        authProvider.userData?['name']?[0]?.toUpperCase() ?? 'U',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.lightPrimary,
                        ),
                      ),
                    ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          languageProvider.translate('welcome_back'),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (authProvider.isLoading || authProvider.userData == null)
                          const SizedBox(
                            height: 18,
                            width: 120,
                            child: LinearProgressIndicator(
                              backgroundColor: Colors.white24,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        else
                          Text(
                            authProvider.userData?['name'] ?? 'User',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.verified_user,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Foundation Overview Section Header
            Row(
              children: [
                const Icon(Icons.account_balance, size: 20, color: AppColors.lightPrimary),
                const SizedBox(width: 8),
                Text(
                  languageProvider.translate('foundation_overview'),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Stream for Foundation & User Stats
            StreamBuilder<Map<String, dynamic>>(
              stream: _getOverviewData(userId),
              builder: (context, snapshot) {
                final data = snapshot.data ?? {
                  'foundationBalance': 0.0,
                  'foundationTotalDeposits': 0.0,
                  'myBalance': 0.0,
                  'myDeposits': 0.0,
                };

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top 2 Cards: Foundation Balance & Total Collection (Joma)
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            label: languageProvider.translate('foundation_balance'),
                            value: '৳ ${_formatNumber(data['foundationBalance'])}',
                            icon: Icons.account_balance,
                            gradient: const [Color(0xFF7C3AED), Color(0xFF9333EA)],
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMetricCard(
                            label: languageProvider.translate('total_joma'),
                            value: '৳ ${_formatNumber(data['foundationTotalDeposits'])}',
                            icon: Icons.savings,
                            gradient: const [Color(0xFF059669), Color(0xFF10B981)],
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // User Account Section Header
                    Row(
                      children: [
                        const Icon(Icons.person, size: 20, color: AppColors.lightSecondary),
                        const SizedBox(width: 8),
                        Text(
                          languageProvider.translate('my_account'),
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Bottom 2 Cards: User Balance & User Total Balance (Joma)
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            label: languageProvider.translate('my_balance'),
                            value: '৳ ${_formatNumber(data['myBalance'])}',
                            icon: Icons.account_balance_wallet,
                            gradient: const [Color(0xFF2563EB), Color(0xFF3B82F6)],
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMetricCard(
                            label: languageProvider.translate('my_total_balance'),
                            value: '৳ ${_formatNumber(data['myDeposits'])}',
                            icon: Icons.paid,
                            gradient: const [Color(0xFF0D9488), Color(0xFF14B8A6)],
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 28),

            // Recent Activities Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.history, size: 20, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      languageProvider.translate('recent_activity'),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Real-time Activities Stream
            StreamBuilder<List<DepositModel>>(
              stream: _depositRepository.getUserDepositsStream(userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                final deposits = snapshot.data ?? [];

                if (deposits.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      ),
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            languageProvider.translate('no_recent_activity'),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey,
                                ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: deposits.take(5).length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final dep = deposits[index];
                    return _buildActivityItem(
                      context,
                      languageProvider.translate('deposit_added'),
                      dep.description ?? '${dep.method} - ${dep.reference}',
                      '+৳ ${_formatNumber(dep.amount)}',
                      DateFormat('MMM dd, yyyy').format(dep.date),
                      Icons.arrow_downward,
                      AppColors.lightSuccess,
                      isDark,
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Stream overview data in real-time
  Stream<Map<String, dynamic>> _getOverviewData(String userId) {
    if (userId.isEmpty) {
      return Stream.value({
        'foundationBalance': 0.0,
        'foundationTotalDeposits': 0.0,
        'myBalance': 0.0,
        'myDeposits': 0.0,
      });
    }

    // Combine snapshots from users and deposits for instantaneous real-time sync
    return _firestore.collection('users').doc(userId).snapshots().asyncMap((userDoc) async {
      try {
        final userData = userDoc.data() ?? {};
        final myBalance = (userData['balance'] as num?)?.toDouble() ?? 0.0;
        final myDeposits = (userData['totalDeposits'] as num?)?.toDouble() ?? 0.0;

        // Foundation-wide calculations from completed deposits
        final totalDeposits = await _depositRepository.getAllDepositsTotal();

        return {
          'foundationBalance': totalDeposits,
          'foundationTotalDeposits': totalDeposits,
          'myBalance': myBalance > 0 ? myBalance : myDeposits,
          'myDeposits': myDeposits,
        };
      } catch (e) {
        debugPrint('❌ Error in _getOverviewData: $e');
        return {
          'foundationBalance': 0.0,
          'foundationTotalDeposits': 0.0,
          'myBalance': 0.0,
          'myDeposits': 0.0,
        };
      }
    });
  }

  Widget _buildMetricCard({
    required String label,
    required String value,
    required IconData icon,
    required List<Color> gradient,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: gradient[0].withOpacity(0.28),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.92),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.2,
              ),
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(
    BuildContext context,
    String title,
    String subtitle,
    String amount,
    String date,
    IconData icon,
    Color color,
    bool isDark,
  ) {
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
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: color,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  date,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                        fontSize: 11,
                      ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.lightSuccess,
                ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(dynamic number) {
    if (number == null) return '0';
    try {
      final val = (number as num).toDouble();
      return NumberFormat('#,##0.00').format(val);
    } catch (_) {
      return number.toString();
    }
  }
}
