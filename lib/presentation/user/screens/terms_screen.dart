import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/language_provider.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(languageProvider.translate('terms_title')),
        elevation: 0,
        backgroundColor: isDark ? AppColors.darkCardBg : AppColors.lightPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.lightPrimary, AppColors.lightSecondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.description,
                    color: Colors.white,
                    size: 40,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          languageProvider.translate('terms_title'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          languageProvider.translate('legal_last_updated'),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Content
            _buildSection(
              context,
              title: languageProvider.translate('terms_1_title'),
              content: languageProvider.translate('terms_1_content'),
              isDark: isDark,
            ),

            _buildSection(
              context,
              title: languageProvider.translate('terms_2_title'),
              content: languageProvider.translate('terms_2_content'),
              isDark: isDark,
            ),

            _buildSection(
              context,
              title: languageProvider.translate('terms_3_title'),
              content: languageProvider.translate('terms_3_content'),
              isDark: isDark,
            ),

            _buildSection(
              context,
              title: languageProvider.translate('terms_4_title'),
              content: languageProvider.translate('terms_4_content'),
              isDark: isDark,
            ),

            _buildSection(
              context,
              title: languageProvider.translate('terms_5_title'),
              content: languageProvider.translate('terms_5_content'),
              isDark: isDark,
            ),

            _buildSection(
              context,
              title: languageProvider.translate('terms_6_title'),
              content: languageProvider.translate('terms_6_content'),
              isDark: isDark,
            ),

            _buildSection(
              context,
              title: languageProvider.translate('terms_7_title'),
              content: languageProvider.translate('terms_7_content'),
              isDark: isDark,
            ),

            _buildSection(
              context,
              title: languageProvider.translate('terms_8_title'),
              content: languageProvider.translate('terms_8_content'),
              isDark: isDark,
            ),

            _buildSection(
              context,
              title: languageProvider.translate('terms_9_title'),
              content: languageProvider.translate('terms_9_content'),
              isDark: isDark,
            ),

            _buildSection(
              context,
              title: languageProvider.translate('terms_10_title'),
              content: languageProvider.translate('terms_10_content'),
              isDark: isDark,
            ),

            const SizedBox(height: 32),

            // Footer
            Center(
              child: Text(
                languageProvider.translate('copyright'),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required String content,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.lightPrimary,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              content,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.6,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
