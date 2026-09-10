import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:foundation_app/data/repositories/deposit_repository.dart';
import 'package:foundation_app/presentation/admin/screens/communication/communication_screen.dart';
import 'package:foundation_app/presentation/admin/screens/deposit_management/deposit_management_screen.dart';
import 'package:foundation_app/presentation/admin/screens/user_management/user_management_screen.dart';
import 'package:foundation_app/presentation/admin/screens/analytics/analytics_screen.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/theme_provider.dart';
import '../../../providers/language_provider.dart';
import '../../../providers/authprovider.dart';
import 'settings_screen.dart';
import '../widgets/metric_card.dart';
import '../widgets/quick_action_card.dart';
import 'tabs/transaction_tab.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final DepositRepository _depositRepository = DepositRepository();
  
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                image: const DecorationImage(
                  image: AssetImage('assets/images/somiti_logo.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                languageProvider.translate('admin_dashboard'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          // Theme Toggle
          IconButton(
            icon: Icon(
              themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
              size: 22,
            ),
            onPressed: () {
              themeProvider.toggleTheme();
            },
          ),
          // Language Toggle
          IconButton(
            icon: const Icon(Icons.language, size: 22),
            onPressed: () {
              languageProvider.toggleLanguage();
            },
          ),
          // Profile Menu
          PopupMenuButton<String>(
            icon: CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF7C3AED),
              child: Text(
                authProvider.userData?['name']?[0]?.toUpperCase() ?? 'A',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            onSelected: (value) {
              switch (value) {
                case 'settings':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                  break;
                case 'logout':
                  _showLogoutConfirmDialog(context);
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    const Icon(Icons.settings_outlined),
                    const SizedBox(width: 12),
                    Text(languageProvider.translate('settings')),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    const Icon(Icons.logout, color: Colors.red),
                    const SizedBox(width: 12),
                    Text(
                      languageProvider.translate('logout'),
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
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
              // Welcome Banner
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFFEC4899)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7C3AED).withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      child: Text(
                        authProvider.userData?['name']?[0]?.toUpperCase() ?? 'A',
                        style: const TextStyle(
                          color: Color(0xFF7C3AED),
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${languageProvider.translate('welcome_back')}, ${authProvider.userData?['name'] ?? 'Admin'}!',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            languageProvider.translate('admin_dashboard'),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.95),
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Key Metrics Section Header
              Text(
                languageProvider.translate('overview'),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),

              const SizedBox(height: 14),

              // Real-time Metrics from Firestore
              StreamBuilder<Map<String, dynamic>>(
                stream: _getRealTimeStats(),
                builder: (context, snapshot) {
                  final stats = snapshot.data ?? {
                    'totalUsers': 0,
                    'foundationBalance': 0.0,
                    'totalDeposits': 0.0,
                  };

                  final fBalance = (stats['foundationBalance'] as num?)?.toDouble() ?? 0.0;
                  final tDeposits = (stats['totalDeposits'] as num?)?.toDouble() ?? 0.0;

                  return Column(
                    children: [
                      // 1. Foundation Balance (Prominent Hero Card)
                      MetricCard(
                        title: languageProvider.translate('foundation_balance'),
                        value: '৳ ${NumberFormat('#,##0').format(fBalance)}',
                        icon: Icons.account_balance,
                        gradient: const [Color(0xFF7C3AED), Color(0xFFEC4899)],
                        trend: '',
                      ),
                      const SizedBox(height: 12),
                      // 2. Total Deposits & Total Members Grid
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.35,
                        children: [
                          // Total Deposits (Joma)
                          InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const DepositManagementScreen(),
                                ),
                              );
                            },
                            child: MetricCard(
                              title: languageProvider.translate('total_joma'),
                              value: '৳ ${NumberFormat('#,##0').format(tDeposits)}',
                              icon: Icons.savings,
                              gradient: const [Color(0xFF059669), Color(0xFF10B981)],
                              trend: '',
                            ),
                          ),
                          // Total Users / Members
                          InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const UserManagementScreen(),
                                ),
                              );
                            },
                            child: MetricCard(
                              title: languageProvider.translate('total_users'),
                              value: '${stats['totalUsers']}',
                              icon: Icons.people,
                              gradient: const [Color(0xFF2563EB), Color(0xFF3B82F6)],
                              trend: '+${stats['totalUsers']}',
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 28),

              // Quick Actions Section Header
              Text(
                languageProvider.translate('quick_actions'),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),

              const SizedBox(height: 14),

              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.0,
                children: [
                  // 1. User Management
                  QuickActionCard(
                    title: languageProvider.translate('user_management'),
                    subtitle: languageProvider.translate('manage_users'),
                    icon: Icons.people_outline,
                    color: const Color(0xFF7C3AED),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const UserManagementScreen(),
                        ),
                      );
                    },
                  ),
                  // 2. Deposit Management
                  QuickActionCard(
                    title: languageProvider.translate('deposit_management'),
                    subtitle: languageProvider.translate('manage_deposits'),
                    icon: Icons.account_balance_wallet_outlined,
                    color: const Color(0xFF059669),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DepositManagementScreen(),
                        ),
                      );
                    },
                  ),
                  // 4. User History
                  QuickActionCard(
                    title: languageProvider.translate('user_history'),
                    subtitle: languageProvider.translate('view_history'),
                    icon: Icons.history,
                    color: Colors.teal,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TransactionTab(showAppBar: true),
                        ),
                      );
                    },
                  ),
                  // 5. Communication
                  QuickActionCard(
                    title: languageProvider.translate('communication'),
                    subtitle: languageProvider.translate('send_messages'),
                    icon: Icons.message_outlined,
                    color: const Color(0xFFEC4899),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CommunicationCenterScreen(),
                        ),
                      );
                    },
                  ),
                  // 6. Reports & Analytics
                  QuickActionCard(
                    title: languageProvider.translate('reports'),
                    subtitle: languageProvider.translate('view_analytics'),
                    icon: Icons.bar_chart,
                    color: const Color(0xFF8B5CF6),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AnalyticsScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // Recent Activity Section Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    languageProvider.translate('recent_activity'),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const UserManagementScreen(),
                        ),
                      );
                    },
                    child: Text(languageProvider.translate('view_all')),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Real-time Recent Registrations
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .orderBy('createdAt', descending: true)
                    .limit(4)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          languageProvider.translate('no_recent_activity'),
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: snapshot.data!.docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final name = data['name'] ?? 'Unknown User';
                      final createdAt = data['createdAt'] as Timestamp?;
                      final timeAgo = createdAt != null
                          ? _getTimeAgo(createdAt.toDate())
                          : 'Recently';

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _buildActivityItem(
                          context,
                          languageProvider.translate('new_user_registered'),
                          '$name ${languageProvider.translate('created_account')}',
                          timeAgo,
                          Icons.person_add,
                          Colors.blue,
                          isDark,
                        ),
                      );
                    }).toList(),
                  );
                },
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // Real-time statistics stream
  Stream<Map<String, dynamic>> _getRealTimeStats() async* {
    await for (final usersSnapshot in FirebaseFirestore.instance.collection('users').snapshots()) {
      int totalUsers = 0;
      int pendingApprovals = 0;
      
      for (var doc in usersSnapshot.docs) {
        final data = doc.data();
        totalUsers++;
        if (data['status']?.toString().toLowerCase() == 'pending') {
          pendingApprovals++;
        }
      }
      
      final totalDeposits = await _depositRepository.getAllDepositsTotal();

      yield {
        'totalUsers': totalUsers,
        'pendingApprovals': pendingApprovals,
        'foundationBalance': totalDeposits,
        'totalDeposits': totalDeposits,
      };
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} min ago';
    } else {
      return 'Just now';
    }
  }

  Widget _buildActivityItem(
    BuildContext context,
    String title,
    String subtitle,
    String time,
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
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey,
                  fontSize: 11,
                ),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmDialog(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(languageProvider.translate('logout')),
        content: Text(languageProvider.translate('confirm_logout')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(languageProvider.translate('cancel')),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final authProvider = context.read<AuthProvider>();
              await authProvider.signOut();
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/',
                  (route) => false,
                );
              }
            },
            child: Text(
              languageProvider.translate('logout'),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}