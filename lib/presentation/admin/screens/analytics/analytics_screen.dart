import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../../providers/language_provider.dart';
import '../../../../providers/theme_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/repositories/deposit_repository.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DepositRepository _depositRepository = DepositRepository();
  
  String _selectedPeriod = 'Month';
  final List<String> _periods = ['Week', 'Month', 'Year', 'All Time'];
  double _foundationBalance = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchFoundationBalance();
  }

  Future<void> _fetchFoundationBalance() async {
    try {
      final totalDeposits = await _depositRepository.getAllDepositsTotal();
      if (mounted) {
        setState(() {
          _foundationBalance = totalDeposits;
        });
      }
    } catch (e) {
      debugPrint('Error calculating foundation balance: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: Text(languageProvider.translate('reports')),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () => _exportData(context),
            tooltip: 'Download Report',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Foundation Balance Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFFEC4899)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7C3AED).withOpacity(0.3),
                    spreadRadius: 2,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.account_balance, color: Colors.white, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        languageProvider.translate('foundation_balance'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '৳ ${NumberFormat('#,##0.00', 'en_US').format(_foundationBalance)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Updated in real-time',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            // Period Selector
            _buildPeriodSelector(isDark),
            
            const SizedBox(height: 24),
            
            // Summary Cards
            StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('users').snapshots(),
              builder: (context, userSnapshot) {
                return StreamBuilder<QuerySnapshot>(
                  stream: _firestore.collection('deposits').snapshots(),
                  builder: (context, depositSnapshot) {
                    if (!userSnapshot.hasData || !depositSnapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final stats = _calculateStats(
                      userSnapshot.data!.docs,
                      depositSnapshot.data!.docs,
                    );

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          languageProvider.translate('overall_statistics'),
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 16),
                        
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1.4,
                          children: [
                            _buildStatCard(
                              languageProvider.translate('total_members'),
                              '${stats['totalUsers']}',
                              Icons.people,
                              const Color(0xFF7C3AED),
                              isDark,
                            ),
                            _buildStatCard(
                              languageProvider.translate('total_joma'),
                              '৳ ${NumberFormat('#,##0', 'en_US').format(stats['totalDeposits'])}',
                              Icons.savings,
                              const Color(0xFF10B981),
                              isDark,
                            ),
                            _buildStatCard(
                              languageProvider.translate('active_members'),
                              '${stats['activeUsers']}',
                              Icons.check_circle_outline,
                              const Color(0xFF3B82F6),
                              isDark,
                            ),
                            _buildStatCard(
                              languageProvider.translate('pending_approvals'),
                              '${stats['pendingUsers']}',
                              Icons.pending_actions,
                              const Color(0xFFF59E0B),
                              isDark,
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 32),
                        
                        Text(
                          languageProvider.translate('recent_transactions'),
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 16),
                        
                        _buildRecentTransactions(isDark, depositSnapshot.data!.docs),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSelector(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Row(
        children: _periods.map((period) {
          final isSelected = period == _selectedPeriod;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedPeriod = period),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected 
                    ? const Color(0xFF7C3AED) 
                    : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  period,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.white : null,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, bool isDark) {
    return Container(
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions(bool isDark, List<QueryDocumentSnapshot> deposits) {
    final recentDeposits = deposits.take(5).toList();
    
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: recentDeposits.length,
      itemBuilder: (context, index) {
        final deposit = recentDeposits[index].data() as Map<String, dynamic>;
        final date = (deposit['date'] as Timestamp?)?.toDate() ?? DateTime.now();
        final amount = (deposit['amount'] as num?)?.toDouble() ?? 0;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.arrow_downward,
                  color: Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      deposit['userName'] ?? 'Unknown',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      DateFormat('MMM dd, yyyy').format(date),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Text(
                '+৳ ${NumberFormat('#,##0', 'en_US').format(amount)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF10B981),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Map<String, dynamic> _calculateStats(
    List<QueryDocumentSnapshot> users,
    List<QueryDocumentSnapshot> deposits,
  ) {
    double totalDeposits = 0;
    int activeUsers = 0;
    int pendingUsers = 0;

    for (var doc in users) {
      final data = doc.data() as Map<String, dynamic>;
      final status = data['status']?.toString().toLowerCase();
      if (status == 'active') {
        activeUsers++;
      } else if (status == 'pending') {
        pendingUsers++;
      }
    }

    for (var doc in deposits) {
      final data = doc.data() as Map<String, dynamic>;
      if (data['status'] == 'completed') {
        totalDeposits += (data['amount'] as num?)?.toDouble() ?? 0;
      }
    }

    return {
      'totalUsers': users.length,
      'activeUsers': activeUsers,
      'pendingUsers': pendingUsers,
      'totalDeposits': totalDeposits,
    };
  }

  Future<void> _exportData(BuildContext context) async {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    
    try {
      final pdf = pw.Document();
      final font = await PdfGoogleFonts.hindSiliguriRegular();
      final fontBold = await PdfGoogleFonts.hindSiliguriBold();

      final users = await _firestore.collection('users').get();
      final deposits = await _firestore.collection('deposits').get();

      final stats = _calculateStats(
        users.docs,
        deposits.docs,
      );

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return [
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      languageProvider.translate('reports'),
                      style: pw.TextStyle(
                        fontSize: 28,
                        fontWeight: pw.FontWeight.bold,
                        font: fontBold,
                      ),
                    ),
                    pw.Text(
                      DateFormat('MMM dd, yyyy').format(DateTime.now()),
                      style: pw.TextStyle(
                        font: font,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 30),
              
              pw.Container(
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400, width: 1.5),
                  borderRadius: pw.BorderRadius.circular(12),
                  color: PdfColors.grey100,
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      languageProvider.translate('overall_statistics'),
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                        font: fontBold,
                      ),
                    ),
                    pw.Divider(thickness: 2, color: PdfColors.grey600),
                    pw.SizedBox(height: 15),
                    _buildPdfRow(
                      languageProvider.translate('foundation_balance'),
                      '৳ ${NumberFormat('#,##0.00', 'en_US').format(_foundationBalance)}',
                      font,
                      fontBold,
                    ),
                    _buildPdfRow(
                      languageProvider.translate('total_joma'),
                      '৳ ${NumberFormat('#,##0.00', 'en_US').format(stats['totalDeposits'])}',
                      font,
                      fontBold,
                    ),
                    _buildPdfRow(
                      languageProvider.translate('total_members'),
                      '${stats['totalUsers']}',
                      font,
                      fontBold,
                    ),
                    _buildPdfRow(
                      languageProvider.translate('active_members'),
                      '${stats['activeUsers']}',
                      font,
                      fontBold,
                    ),
                  ],
                ),
              ),
              
              pw.SizedBox(height: 30),
              
              pw.Text(
                languageProvider.translate('recent_transactions'),
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  font: fontBold,
                ),
              ),
              pw.SizedBox(height: 15),
              
              ...deposits.docs.take(10).map((doc) {
                final data = doc.data();
                final date = (data['date'] as Timestamp).toDate();
                final amount = (data['amount'] as num?)?.toDouble() ?? 0;
                
                return pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  margin: const pw.EdgeInsets.only(bottom: 8),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey400, width: 1),
                    borderRadius: pw.BorderRadius.circular(8),
                    color: PdfColors.white,
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              data['userName'] ?? 'Unknown User',
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                font: fontBold,
                                fontSize: 14,
                              ),
                            ),
                            pw.SizedBox(height: 4),
                            pw.Text(
                              DateFormat('MMM dd, yyyy').format(date),
                              style: pw.TextStyle(
                                fontSize: 12,
                                color: PdfColors.grey700,
                                font: font,
                              ),
                            ),
                          ],
                        ),
                      ),
                      pw.Text(
                        '+৳ ${NumberFormat('#,##0.00', 'en_US').format(amount)}',
                        style: pw.TextStyle(
                          color: PdfColors.green700,
                          fontWeight: pw.FontWeight.bold,
                          font: fontBold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              
              pw.SizedBox(height: 40),
              
              pw.Divider(thickness: 1.5, color: PdfColors.grey400),
              pw.SizedBox(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Generated by Foundation App',
                    style: pw.TextStyle(
                      fontSize: 11,
                      font: font,
                      color: PdfColors.grey600,
                    ),
                  ),
                  pw.Text(
                    'Page 1 of 1',
                    style: pw.TextStyle(
                      fontSize: 11,
                      font: font,
                      color: PdfColors.grey600,
                    ),
                  ),
                ],
              ),
            ];
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'Foundation_Report_${DateFormat('yyyyMMdd').format(DateTime.now())}',
        format: PdfPageFormat.a4,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${languageProvider.translate('error')}: $e')),
        );
      }
    }
  }
  
  pw.Widget _buildPdfRow(String label, String value, pw.Font font, pw.Font fontBold) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              font: font,
              fontSize: 14,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              font: fontBold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
