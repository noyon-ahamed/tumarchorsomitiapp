import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/language_provider.dart';
import '../../../providers/theme_provider.dart';
import '../../../providers/authprovider.dart';
import '../../auth/screens/login_screen.dart';
import 'terms_screen.dart';
import 'privacy_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final userData = authProvider.userData ?? {};
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: Text(languageProvider.translate('settings')),
        elevation: 0,
        backgroundColor: isDark ? AppColors.darkCardBg : AppColors.lightPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Simply pop back to previous screen
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // General Section
            _buildSectionHeader(context, languageProvider.translate('general')),
            const SizedBox(height: 16),
            
            _buildSettingsTile(
              context,
              icon: Icons.language,
              title: languageProvider.translate('language'),
              subtitle: languageProvider.currentLanguageCode == 'bn' ? 'বাংলা' : 'English',
              onTap: () => _showLanguageDialog(context),
              isDark: isDark,
            ),
            
            _buildSettingsTile(
              context,
              icon: isDark ? Icons.light_mode : Icons.dark_mode,
              title: languageProvider.translate('theme'),
              subtitle: isDark ? languageProvider.translate('dark_mode') : languageProvider.translate('light_mode'),
              onTap: () {
                themeProvider.toggleTheme();
              },
              isDark: isDark,
            ),

            // Account Section
            _buildSectionHeader(context, languageProvider.translate('account_section')),
            const SizedBox(height: 16),
            
            _buildSettingsTile(
              context,
              icon: Icons.person,
              title: languageProvider.translate('full_name'),
              subtitle: userData['name'] ?? 'User',
              isDark: isDark,
              onTap: () {}, // Read-only for now
            ),
            
            _buildSettingsTile(
              context,
              icon: Icons.email,
              title: languageProvider.translate('email'),
              subtitle: userData['email'] ?? '',
              isDark: isDark,
              onTap: () {},
            ),

            if (userData['phone'] != null && userData['phone'].toString().isNotEmpty)
              _buildSettingsTile(
                context,
                icon: Icons.phone,
                title: languageProvider.translate('phone'),
                subtitle: userData['phone'],
                isDark: isDark,
                onTap: () {},
              ),

            _buildSettingsTile(
              context,
              icon: Icons.badge,
              title: languageProvider.translate('role'),
              subtitle: (userData['role'] ?? 'User').toString().toUpperCase(),
              isDark: isDark,
              onTap: () {},
            ),

            _buildSettingsTile(
              context,
              icon: Icons.verified_user,
              title: languageProvider.translate('status'),
              subtitle: (userData['status'] ?? 'Active').toString().toUpperCase(),
              isDark: isDark,
              onTap: () {},
            ),

            const SizedBox(height: 32),

            // Legal Section
            _buildSectionHeader(context, languageProvider.translate('legal')),
            const SizedBox(height: 16),
            
            _buildSettingsTile(
              context,
              icon: Icons.description,
              title: languageProvider.translate('terms_of_service'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TermsScreen()),
                );
              },
              isDark: isDark,
            ),
            
            _buildSettingsTile(
              context,
              icon: Icons.privacy_tip,
              title: languageProvider.translate('privacy_policy'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PrivacyScreen()),
                );
              },
              isDark: isDark,
            ),
            
            _buildSettingsTile(
              context,
              icon: Icons.info,
              title: languageProvider.translate('about'),
              subtitle: '${languageProvider.translate('version')} 1.0.0',
              // onTap: () {
              //   // Show about dialog
              //   showAboutDialog(
              //     context: context,
              //     applicationName: 'Foundation App',
              //     applicationVersion: '1.0.0',
              //     // applicationIcon: Container(
              //     //   padding: const EdgeInsets.all(8),
              //     //   decoration: BoxDecoration(
              //     //     color: AppColors.lightPrimary,
              //     //     borderRadius: BorderRadius.circular(12),
              //     //   ),
              //     //   child: const Icon(Icons.foundation, color: Colors.white),
              //     // ),
              //     // children: [
              //     //   const Text('A comprehensive solution for foundation management.'),
              //     // ],
              //   );
              // },
              isDark: isDark,
            ),

            const SizedBox(height: 32),
            
            // Logout
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                   _showLogoutDialog(context);
                },
                icon: const Icon(Icons.logout),
                label: Text(languageProvider.translate('logout')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.lightError,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
    Color? iconColor,
    Color? textColor,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
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
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (iconColor ?? AppColors.lightPrimary).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: iconColor ?? AppColors.lightPrimary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              if (onTap != null)
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey[400],
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(languageProvider.translate('select_language')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('English'),
              value: 'en',
              groupValue: languageProvider.currentLanguageCode,
              onChanged: (value) {
                if (value != null) {
                  languageProvider.setLanguage(value);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<String>(
              title: const Text('বাংলা (Bangla)'),
              value: 'bn',
              groupValue: languageProvider.currentLanguageCode,
              onChanged: (value) {
                if (value != null) {
                  languageProvider.setLanguage(value);
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
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
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              // Clear all navigation stack and go to login
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen(isAdmin: false)),
                (route) => false, // Remove all previous routes
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.lightError,
            ),
            child: Text(languageProvider.translate('logout')),
          ),
        ],
      ),
    );
  }
}