import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  Locale _locale = const Locale('bn');
  SharedPreferences? _prefs;

  Locale get locale => _locale;
  bool get isBangla => _locale.languageCode == 'bn';
  bool get isEnglish => _locale.languageCode == 'en';
  String get languageName => _locale.languageCode == 'bn' ? 'বাংলা' : 'English';
  String get currentLanguageCode => _locale.languageCode;

  String? _userId;

  LanguageProvider() {
    _init();
  }

  Future<void> _init() async {
    await _loadLanguageFromPrefs();
  }

  // ✅ Update current user and reload language preference
  Future<void> updateUser(String? userId) async {
    if (_userId == userId) return;

    _userId = userId;
    debugPrint('🔄 LanguageProvider: User changed to $userId');
    await _loadLanguageFromPrefs();
  }

  // Set language by code
  Future<void> setLanguage(String languageCode) async {
    if (languageCode != 'en' && languageCode != 'bn') {
      debugPrint(
          '⚠️ Invalid language code: $languageCode, defaulting to Bangla');
      languageCode = 'bn';
    }

    _locale = Locale(languageCode);
    await _saveLanguageToPrefs(languageCode);
    notifyListeners();
    debugPrint('Language changed to: $languageName');
  }

  // Toggle between English and Bangla
  Future<void> toggleLanguage() async {
    final newCode = _locale.languageCode == 'en' ? 'bn' : 'en';
    await setLanguage(newCode);
  }

  // ✅ Load saved language from SharedPreferences
  Future<void> _loadLanguageFromPrefs() async {
    try {
      _prefs = await SharedPreferences.getInstance();

      // If user is logged in, try to load user-specific language
      String key = 'languageCode';
      if (_userId != null) {
        key = 'languageCode_$_userId';
      }

      String? savedLanguageCode = _prefs?.getString(key);

      // If no user-specific language, try global fallback (only if not logged in, or desired behavior)
      // For strict separation, we might want to default to 'en' if no user-specific setting exists.
      // Let's check global if user-specific is null AND user is NOT logged in.
      // Actually, if a user logs in and has no preference, we probably want default English, NOT the previous user's language.
      // So if _userId is set and no pref, default to 'en'.

      if (savedLanguageCode == null && _userId == null) {
        savedLanguageCode = _prefs?.getString('languageCode');
      }

      if (savedLanguageCode != null) {
        _locale = Locale(savedLanguageCode);
        debugPrint('✅ Loaded saved language for key $key: $languageName');
      } else {
        _locale = const Locale('bn');
        debugPrint('ℹ️ No saved language for key $key, using default: Bangla');
      }

      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error loading language from preferences: $e');
    }
  }

  // ✅ Save language to SharedPreferences
  Future<void> _saveLanguageToPrefs(String languageCode) async {
    try {
      _prefs ??= await SharedPreferences.getInstance();

      String key = 'languageCode';
      if (_userId != null) {
        key = 'languageCode_$_userId';
      }

      await _prefs!.setString(key, languageCode);
      debugPrint('💾 Language saved to preferences (Key: $key): $languageCode');
    } catch (e) {
      debugPrint('❌ Error saving language to preferences: $e');
    }
  }

  // ✅ Clear saved language (reset to default)
  Future<void> clearLanguagePreference() async {
    try {
      _prefs ??= await SharedPreferences.getInstance();

      String key = 'languageCode';
      if (_userId != null) {
        key = 'languageCode_$_userId';
      }

      await _prefs!.remove(key);
      _locale = const Locale('en');
      notifyListeners();
      debugPrint(
          '🗑️ Language preference cleared for key $key, reset to English');
    } catch (e) {
      debugPrint('❌ Error clearing language preference: $e');
    }
  }

  // ✅ Translation helper - returns translated text based on current language
  String translate(String key) {
    final translations = AppLocalizations.translations[_locale.languageCode];
    return translations?[key] ?? key;
  }

  // ✅ Get translation with fallback
  String t(String key, [String? fallback]) {
    final translation = translate(key);
    if (translation == key && fallback != null) {
      return fallback;
    }
    return translation;
  }
}

// ✅ Complete Translation Map (English & Bangla)
class AppLocalizations {
  static const Map<String, Map<String, String>> translations = {
    'en': {
      // ========== Common ==========
      'app_name': 'টুমার চর সমিতি',
      'welcome': 'Welcome',
      'welcome_back': 'Welcome Back',
      'loading': 'Loading...',
      'save': 'Save',
      'cancel': 'Cancel',
      'delete': 'Delete',
      'edit': 'Edit',
      'update': 'Update',
      'confirm': 'Confirm',
      'yes': 'Yes',
      'no': 'No',
      'ok': 'OK',
      'done': 'Done',
      'mark_all_read': 'Mark All Read',
      'all_marked_read': 'All notifications marked as read',
      'notification_deleted': 'Notification deleted',
      'days_ago': 'days ago',
      'hours_ago': 'hours ago',
      'minutes_ago': 'minutes ago',
      'just_now': 'Just now',
      'view_all': 'View All',
      'search': 'Search',
      'filter': 'Filter',
      'sort': 'Sort',
      'total': 'Total',
      'active': 'Active',
      'pending': 'Pending',
      'rejected': 'Rejected',
      'blocked': 'Blocked',
      'inactive': 'Inactive',
      'error': 'Error',
      'success': 'Success',
      'warning': 'Warning',
      'info': 'Information',
      'unknown': 'Unknown',
      'balance_info': 'Balance Info',
      'member_since': 'Member Since',
      'last_updated_at': 'Last Updated At',
      'recalculating_balance': 'Recalculating balance...',
      'balance_updated': 'Balance updated',
      'error_recalculating_balance': 'Error recalculating balance',
      'uploading_image': 'Uploading image...',
      'profile_picture_updated': 'Profile picture updated!',
      'months': 'months',
      'days': 'days',
      'invested': 'Invested',
      'expected': 'Expected',
      'duration': 'Duration',
      'progress': 'Progress',
      'monthly_breakdown': 'Monthly Deposit Breakdown',
      'deposit_history': 'Deposit Receipts History',
      'serial_no': 'Serial',
      'month_paid': 'Paid',
      'month_due': 'Due',
      'month_count_label': 'Month',
      'member_details': 'Member Details',
      'total_paid_months': 'Total Paid Months',

      // ========== Auth ==========
      'login': 'Login',
      'signup': 'Sign Up',
      'logout': 'Logout',
      'sign_in': 'Sign In',
      'sign_out': 'Sign Out',
      'sign_in_with_google': 'Sign in with Google',
      'sign_in_with_email': 'Sign in with Email',
      'email': 'Email',
      'password': 'Password',
      'all': 'All',
      'phone_number': 'Phone Number',
      'full_name': 'Full Name',
      'forgot_password': 'Forgot Password?',
      'reset_password': 'Reset Password',
      'create_account': 'Create Account',
      'already_have_account': 'Already have an account?',
      'dont_have_account': 'Don\'t have an account?',
      'select_role': 'Select Your Role',
      'user': 'User',
      'admin': 'Admin',
      'enter_email': 'Enter your email',
      'enter_password': 'Enter your password',
      'enter_phone': 'Enter your phone number',
      'enter_name': 'Enter your full name',

      // ========== Dashboard ==========
      'dashboard': 'Dashboard',
      'admin_dashboard': 'Admin Dashboard',
      'user_dashboard': 'User Dashboard',
      'home': 'Home',
      'users': 'Users',
      'account': 'My Account',
      'my_account': 'My Account',
      'investments': 'Investments',
      'loans': 'Loans',
      'members': 'Members',
      'total_balance': 'Total Balance',
      'current_balance': 'Current Balance',
      'total_investment': 'Total Investment',
      'due_amount': 'Due Amount',
      'total_deposits': 'Total Deposits',
      'total_joma': 'Total Collection',
      'my_total_balance': 'My Total Deposits',
      'my_total_joma': 'My Total Deposits',
      'user_total_balance': 'Total Deposits',
      'months_deposited': 'Months Paid',
      'months_due': 'Months Due',
      'total_months_deposited': 'Total Months Paid',
      'total_months_due': 'Total Due Months',
      'deposit_received_title': 'Deposit Received',
      'deposit_received_body': 'Deposit credited to account',
      'total_withdrawals': 'Total Withdrawals',
      'foundation_balance': 'Foundation Balance',
      'overview': 'Overview',
      'quick_actions': 'Quick Actions',
      'recent_activity': 'Recent Activity',

      // ========== User Management ==========
      'user_management': 'User Management',
      'manage_users': 'Manage Users',
      'all_users': 'All Users',
      'pending_users': 'Pending Users',
      'active_users': 'Active Users',
      'rejected_users': 'Rejected Users',
      'blocked_users': 'Blocked Users',
      'approve': 'Approve',
      'reject': 'Reject',
      'block': 'Block',
      'unblock': 'Unblock',
      'approve_user': 'Approve User',
      'reject_user': 'Reject User',
      'block_user': 'Block User',
      'user_details': 'User Details',
      'user_approved': 'User approved successfully',
      'user_rejected': 'User rejected',
      'user_blocked': 'User blocked',
      'no_users_found': 'No users found',
      'search_users': 'Search users...',
      'total_users': 'Total Users',
      'active_members': 'active members',
      'try_adjusting_search': 'Try adjusting your search or filter',
      'no_results_found': 'No results found',

      // ========== Admin Features ==========
      'deposit_management': 'Deposit Management',
      'add_deposit': 'Add Deposit',
      'manage_deposits': 'Add & manage',
      'investment_management': 'Investment Management',
      'track_investments': 'Track & update',
      'loan_management': 'Loan Management',
      'manage_loans': 'Manage loans',
      'communication': 'Communication',
      'send_message': 'Send Message',
      'send_messages': 'Send messages',
      'reports': 'Reports',
      'view_analytics': 'View analytics',

      // ========== Analytics Screen ==========
      'overall_statistics': 'Overall Statistics',
      'total_members': 'Total Members',
      'active_loans': 'Active Loans',
      'recent_transactions': 'Recent Transactions',
      'active_investments': 'Active Investments',

      // ========== Home Screen ==========

      'foundation_overview': 'Foundation Overview',

      'total_investments': 'Total Investments',
      'my_balance': 'My Balance',
      'my_deposits': 'My Deposits',
      'my_due': 'Loan Due',
      'loan_due': 'Loan Due',
      'total_remaining': 'Total Remaining',
      'months_left': 'months left',
      'loan_principal': 'Loan Principal',

      'no_recent_activity': 'No recent activity',
      'deposit_added': 'Deposit Added',
      'investment_made': 'Investment Made',
      'pending_approvals': 'Pending Approvals',
      'action_needed': 'Action needed',
      'total_loans': 'Total Loans',
      'total_debt': 'Total Debt',
      'remaining_amount': 'Remaining amount',
      'no_investments_yet': 'No investments yet',
      'no_loans_yet': 'No loans yet',
      'create_investment_hint':
          'Create your first investment from Investment Management',
      'create_loan_hint': 'Create your first loan from Loan Management',
      'remaining': 'Remaining',
      'left': 'Left',
      'due': 'Due',
      'paid': 'Paid',
      'online': 'Online',
      'offline': 'Offline',
      'profit': 'Profit',
      'interest': 'Interest',
      'interest_percentage': 'Interest',
      'please_login_to_view': 'Please login to view',
      'please_login_view_investments': 'Please login to view investments',
      'error_loading_investments': 'Error loading investments',
      'error_loading_members': 'Error loading members',
      'new_user_registered': 'New user registered',
      'created_account': 'created an account',

      // ========== Communication Screen ==========
      'communication_center': 'Communication Center',
      'sent_messages': 'Sent Messages',
      'templates': 'Templates',
      'total_sent': 'Total Sent',
      'read_rate': 'Read Rate',
      'no_messages_yet': 'No messages sent yet',
      'send_first_message': 'Send your first message to users',
      'using_template': 'Using template',
      'title_label': 'Title',
      'message_label': 'Message',
      'type_label': 'Type',
      'app_notification': 'App Notification',
      'message_sent_success': 'Message sent successfully',
      'select_user_error': 'Please select a user',
      'error_could_not_launch_sms': 'Could not launch SMS app',
      'error_loading_messages': 'Error loading messages',

      'notification': 'Notification',
      'sms': 'SMS',
      'both': 'Both',
      'sent_at': 'Sent At',
      'read_at': 'Read At',
      'close': 'Close',

      // ========== Add Deposit Screen ==========
      'add_deposit_subtitle': 'Add a deposit to update user balance',
      'select_user_label': 'Select User',
      'select_user_hint': 'Select a user',
      'amount_label': 'Amount (৳)',
      'enter_amount': 'Enter amount',
      'payment_method': 'Payment Method',
      'reference_number': 'Reference Number',
      'enter_reference': 'Enter reference number',
      'date_label': 'Date',
      'add_deposit_btn': 'Add Deposit',

      // ========== Account ==========
      'balance': 'Balance',
      'deposit': 'Deposit',
      'withdraw': 'Withdraw',
      'transaction_history': 'Transaction History',
      'account_details': 'Account Details',
      'joined': 'Joined',
      'last_updated': 'Last Updated',
      'status': 'Status',
      'role': 'Role',
      'admin_notes': 'Admin Notes',

      // ========== Settings ==========
      'settings': 'Settings',
      'general': 'General',
      'legal': 'Legal',
      'account_section': 'Account',
      'language': 'Language',
      'theme': 'Theme',
      'english': 'English',
      'bangla': 'Bangla',
      'light_mode': 'Light Mode',
      'dark_mode': 'Dark Mode',
      'notifications': 'Notifications',
      'profile': 'Profile',
      'edit_profile': 'Edit Profile',
      'edit_join_date': 'Edit Join Date',
      'edit_total_deposits': 'Edit Total Deposits',
      'change_password': 'Change Password',
      'privacy_policy': 'Privacy Policy',
      'terms_of_service': 'Terms of Service',
      'select_language': 'Select Language',
      'about': 'About',
      'version': 'Version',

      // ========== Terms & Privacy ==========
      'terms_title': 'Terms of Service',
      'legal_last_updated': 'Last updated: January 2026',
      'terms_1_title': '1. Acceptance of Terms',
      'terms_1_content':
          'By accessing and using the Foundation App, you accept and agree to be bound by the terms and provision of this agreement. If you do not agree to these terms, please do not use this application.',
      'terms_2_title': '2. User Account',
      'terms_2_content':
          'To access certain features of the app, you must register for an account. You are responsible for maintaining the confidentiality of your account credentials and for all activities that occur under your account.',
      'terms_3_title': '3. Financial Transactions',
      'terms_3_content':
          'All financial transactions including deposits, withdrawals, loans, and investments are subject to verification and approval by the admin. The Foundation App reserves the right to reject or reverse any transaction that violates our policies or local regulations.',
      'terms_4_title': '4. Loans and Investments',
      'terms_4_content':
          'Loan applications and investment opportunities are subject to approval. Interest rates, terms, and conditions will be clearly stated before any agreement. Users are responsible for repaying loans on time according to the agreed schedule.',
      'terms_5_title': '5. User Responsibilities',
      'terms_5_content':
          'Users must provide accurate and truthful information when registering and conducting transactions. Any fraudulent activity or misrepresentation may result in account suspension or termination and legal action.',
      'terms_6_title': '6. Limitations of Liability',
      'terms_6_content':
          'The Foundation App is provided "as is" without any warranties. We are not liable for any losses, damages, or issues arising from the use of this application, including but not limited to financial losses, data loss, or service interruptions.',
      'terms_7_title': '7. Privacy',
      'terms_7_content':
          'Your use of the Foundation App is also governed by our Privacy Policy. Please review our Privacy Policy to understand our practices regarding your personal information.',
      'terms_8_title': '8. Modifications',
      'terms_8_content':
          'We reserve the right to modify these terms at any time. Users will be notified of significant changes, and continued use of the app constitutes acceptance of the modified terms.',
      'terms_9_title': '9. Termination',
      'terms_9_content':
          'We may terminate or suspend your account at any time for violations of these terms, fraudulent activity, or any other reason deemed necessary for the protection of the platform and its users.',
      'terms_10_title': '10. Contact Information',
      'terms_10_content':
          'If you have any questions about these Terms of Service, please contact our support team through the app or email us at sis2024.bd@gmail.com',
      'copyright': '© 2026 Foundation App. All rights reserved.',

      'privacy_title': 'Privacy Policy',
      'privacy_intro_title': 'Introduction',
      'privacy_intro_content':
          'Foundation App ("we," "our," or "us") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application.',
      'privacy_1_title': '1. Information We Collect',
      'privacy_1_content':
          'We collect information that you provide directly to us, including:\n\n• Personal identification information (name, email address, phone number)\n• Financial information (transaction history, account balance, loan details, investment records)\n• Device information (device type, operating system, unique device identifiers)\n• Usage data (app interactions, features used, time spent)',
      'privacy_2_title': '2. How We Use Your Information',
      'privacy_2_content':
          'We use the collected information to:\n\n• Provide and maintain our services\n• Process transactions and manage your account\n• Send you notifications about your account activity\n• Improve and personalize your experience\n• Comply with legal obligations and prevent fraud\n• Communicate with you about updates and changes to our services',
      'privacy_3_title': '3. Information Sharing',
      'privacy_3_content':
          'We do not sell your personal information. We may share your information only in the following circumstances:\n\n• With your consent\n• To comply with legal obligations\n• To protect our rights and prevent fraud\n• With service providers who assist us in operating our app (under strict confidentiality agreements)',
      'privacy_4_title': '4. Data Security',
      'privacy_4_content':
          'We implement appropriate technical and organizational security measures to protect your personal information. However, no method of transmission over the internet or electronic storage is 100% secure. While we strive to protect your data, we cannot guarantee absolute security.',
      'privacy_5_title': '5. Your Rights',
      'privacy_5_content':
          'You have the right to:\n\n• Access your personal information\n• Request correction of inaccurate data\n• Request deletion of your data (subject to legal requirements)\n• Opt-out of certain data collection practices\n• Withdraw consent where applicable',
      'privacy_6_title': '6. Data Retention',
      'privacy_6_content':
          'We retain your personal information for as long as necessary to fulfill the purposes outlined in this Privacy Policy, unless a longer retention period is required by law or to resolve disputes.',
      'privacy_7_title': '7. Cookies and Tracking',
      'privacy_7_content':
          'Our app may use cookies and similar tracking technologies to collect information about your app usage and preferences. You can control cookie settings through your device settings.',
      'privacy_8_title': '8. Third-Party Services',
      'privacy_8_content':
          'Our app may contain links to third-party services. We are not responsible for the privacy practices of these third parties. We encourage you to review their privacy policies before providing any information.',
      'privacy_9_title': '9. Children\'s Privacy',
      'privacy_9_content':
          'Our app is not intended for use by children under the age of 18. We do not knowingly collect personal information from children. If we discover that we have collected information from a child, we will delete it immediately.',
      'privacy_10_title': '10. Changes to Privacy Policy',
      'privacy_10_content':
          'We may update this Privacy Policy from time to time. We will notify you of any significant changes by posting the new policy in the app and updating the "Last updated" date.',
      'privacy_11_title': '11. Contact Us',
      'privacy_11_content':
          'If you have questions or concerns about this Privacy Policy or our data practices, please contact us at:\n\nEmail: sis2024.bd@gmail.com\nAddress: Foundation App Support Team',

      // ========== Messages ==========
      'are_you_sure': 'Are you sure?',
      'confirm_logout': 'Are you sure you want to logout?',
      'confirm_delete': 'Are you sure you want to delete?',

      // ========== User History / New Features ==========
      'user_history': 'User History',
      'view_history': 'View History',
      'select_user_history': 'Select User (History)',
      'confirm_approve': 'Are you sure you want to approve this user?',
      'confirm_reject': 'Are you sure you want to reject this user?',
      'confirm_block': 'Are you sure you want to block this user?',
      'operation_success': 'Operation completed successfully',
      'operation_failed': 'Operation failed',
      'something_went_wrong': 'Something went wrong',
      'try_again': 'Please try again',
      'no_internet': 'No internet connection',
      'check_connection': 'Please check your connection',
      'coming_soon': 'Coming soon!',

      // ========== Status Messages ==========
      'account_pending': 'Account Pending Approval',
      'account_approved': 'Account Approved',
      'account_rejected': 'Account Rejected',
      'account_blocked': 'Account Blocked',
      'waiting_approval': 'Waiting for admin approval',
      'approval_message':
          'Your account is under review. You\'ll receive access once approved.',
      'rejection_message':
          'Your account request has been rejected. Please contact the administrator.',
      'blocked_message':
          'Your account has been blocked. Please contact the administrator.',

      'overdue': 'Overdue',
      'details': 'Details',
      'required_field': 'Required field',

      // ========== Loan Management ==========

      'create_loan_title': 'Create Loan',
      'loan_created_success': 'Loan created successfully',
      'total_collected': 'Total Collected',
      'search_loan_hint': 'Search by name, phone, or ID...',
      'payment_progress': 'Payment Progress',
      'update_payment': 'Update Payment',
      'record_payment': 'Record Payment',
      'borrower': 'Borrower',
      'enter_payment_amount': 'Enter payment amount',
      'record': 'Record',
      'payment_recorded_success': 'Payment recorded successfully',
      'loan_details': 'Loan Details',
      'borrower_name': 'Borrower Name',
      'borrower_phone': 'Phone',
      'loan_amount_label': 'Loan Amount',
      'total_amount': 'Total Amount',
      'paid_amount': 'Paid Amount',
      'interest_rate_label': 'Interest Rate',
      'due_date': 'Due Date',
      'delete_loan_title': 'Delete Loan',
      'delete_loan_confirm': 'Are you sure you want to delete the loan for',
      'loan_deleted_success': 'Loan deleted successfully',
      'error_loading_loans': 'Error loading loans',
      'no_loans_found': 'No loans found',
      'create_first_loan': 'Create your first loan',
      'create_loan': 'Create Loan',

      // ========== Investment Management ==========
      'create_investment_title': 'Create Investment',
      'investment_created_success': 'Investment created successfully',
      'total_invested': 'Total Invested',
      'expected_return': 'Expected Return',
      'total_profit': 'Total Profit',
      'investment_details': 'Investment Details',
      'project_name': 'Project Name',
      'investor': 'Investor',
      'sector': 'Sector',
      'investment_amount': 'Investment Amount',
      'actual_return': 'Actual Return',
      'delete_investment_title': 'Delete Investment',
      'delete_investment_confirm': 'Are you sure you want to delete',
      'investment_deleted_success': 'Investment deleted successfully',
      'update_investment_returns': 'Update Investment Returns',
      'actual_return_amount': 'Actual Return Amount',
      'returns_updated_success': 'Returns updated successfully',

      // ========== Sectors & Risk ==========
      'property': 'Property',
      'business': 'Business',
      'agriculture': 'Agriculture',
      'risk_low': 'Low',
      'risk_medium': 'Medium',
      'risk_high': 'High',

      // ========== Create Investment Form ==========
      'project_info': 'Project Information',
      'project_name_label': 'Project Name *',
      'project_name_hint': 'e.g., XYZ Plaza Construction',
      'enter_project_name': 'Please enter project name',
      'enter_project_desc': 'Enter project description',
      'sector_label': 'Sector *',
      'risk_level_label': 'Risk Level *',
      'financial_info': 'Financial Information',

      'enter_investment_amount': 'Please enter investment amount',
      'enter_valid_number': 'Please enter a valid number',
      'amount_positive': 'Amount must be greater than 0',
      'enter_expected_return': 'Enter expected return',
      'enter_expected_return_error': 'Please enter expected return',
      'return_positive': 'Return must be greater than 0',
      'timeline': 'Timeline',
      'start_date_label': 'Start Date',
      'end_date_label': 'Expected End Date',
      'start_date': 'Start Date',
      'monthly_tracking': 'Monthly Tracking',
      'no_schedule_available': 'No schedule available',

      // ========== Deposit Management ==========
      'deposit_added_success': 'Deposit added successfully',
      'total_deposit_title': 'Total Deposits',
      'transactions_count': 'transactions',
      'search_user_hint': 'Search by user name...',
      'cash': 'Cash',
      'bank_transfer': 'Bank Transfer',
      'mobile_banking': 'Mobile Banking',
      'error_loading_deposits': 'Error loading deposits',
      'no_deposits_found': 'No deposits found',
      'start_adding_deposit': 'Start by adding a deposit',
      'method': 'Method',
      'reference': 'Reference',
      'by_admin': 'By: Admin',
      'deposit_details': 'Deposit Details',
      'user_name': 'User Name',
      'delete_deposit_title': 'Delete Deposit',
      'delete_deposit_confirm': 'Are you sure you want to delete this deposit?',
      'deposit_deleted_success': 'Deposit deleted successfully',
      'error_deleting_deposit': 'Error deleting deposit',
      'deposit_management_title': 'Deposit Management',
      'transactions': 'transactions',
      'no_transactions': 'No transactions yet',
      'search_by_username': 'Search by user name...',
      'try_different_search': 'Try a different search',
      'by': 'By',
      'amount': 'Amount',
      'date': 'Date',
      'please_enter_amount': 'Please enter amount',
      'please_enter_reference': 'Please enter reference number',
      'deposit_added_for': 'Deposit added for',

      // ========== Create Loan Form Keys ==========
      'create_new_loan_info': 'Create a new loan record for a user',
      'select_user': 'Select User',
      'loading_users': 'Loading users...',
      'error_loading_users': 'Error loading users',
      'no_active_users': 'No active users found',
      'select_a_user': 'Select a user',
      'loan_amount': 'Loan Amount',
      'enter_loan_amount': 'Enter loan amount',
      'required': 'Required',
      'please_enter_valid_amount': 'Please enter a valid amount',
      'amount_must_be_greater_than_zero': 'Amount must be greater than zero',
      'interest_rate': 'Interest Rate',
      'enter_interest_rate': 'Enter interest rate',
      'please_enter_valid_rate': 'Please enter a valid rate',
      'rate_cannot_be_negative': 'Rate cannot be negative',
      'loan_duration': 'Loan Duration',
      '3_months': '3 Months',
      '6_months': '6 Months',
      '1_year': '1 Year',
      '2_years': '2 Years',
      'please_select_user': 'Please select a user',

      // ========== Loan Features ==========
      'loan_taken': 'Loan Taken',
      'payment_status': 'Payment Status',
      'paid_months': 'Paid',
      'due_months': 'Due',
      'overdue_months': 'Overdue',
      'loan_paid': 'Loan Repayment',
      'transaction': 'Transaction',

      // ========== Months ==========
      'january': 'January',
      'february': 'February',
      'march': 'March',
      'april': 'April',
      'may': 'May',
      'june': 'June',
      'july': 'July',
      'august': 'August',
      'september': 'September',
      'october': 'October',
      'november': 'November',
      'december': 'December',

      // ========== Status Values ==========
      'status_active': 'ACTIVE',
      'status_pending': 'PENDING',
      'status_completed': 'COMPLETED',
      'status_overdue': 'OVERDUE',
      'status_paid': 'PAID',
      'status_rejected': 'REJECTED',
      'status_blocked': 'BLOCKED',
      'status_failed': 'FAILED',
      'role_admin': 'ADMIN',
      'role_user': 'USER',
      'not_available': 'Not Available',
    },
    'bn': {
      // ========== Common ==========
      'app_name': 'টুমার চর সমিতি',
      'welcome': 'স্বাগতম',
      'welcome_back': 'পুনরায় স্বাগতম',
      'loading': 'লোড হচ্ছে...',
      'save': 'সংরক্ষণ',
      'cancel': 'বাতিল',
      'delete': 'মুছুন',
      'edit': 'সম্পাদনা',
      'update': 'আপডেট',
      'confirm': 'নিশ্চিত',
      'yes': 'হ্যাঁ',
      'no': 'না',
      'ok': 'ঠিক আছে',
      'done': 'সম্পন্ন',
      'mark_all_read': 'সব পড়া হিসেবে চিহ্নিত করুন',
      'all_marked_read': 'সব বিজ্ঞপ্তি পড়া হিসেবে চিহ্নিত',
      'notification_deleted': 'বিজ্ঞপ্তি মুছে ফেলা হয়েছে',
      'days_ago': 'দিন আগে',
      'hours_ago': 'ঘণ্টা আগে',
      'minutes_ago': 'মিনিট আগে',
      'just_now': 'এই মাত্র',
      'view_all': 'সব দেখুন',
      'search': 'অনুসন্ধান',
      'filter': 'ফিল্টার',
      'sort': 'সাজান',
      'total': 'মোট',
      'active': 'সক্রিয়',
      'pending': 'অপেক্ষমাণ',
      'rejected': 'প্রত্যাখ্যাত',
      'blocked': 'অবরুদ্ধ',
      'inactive': 'নিষ্ক্রিয়',
      'error': 'ত্রুটি',
      'success': 'সফল',
      'warning': 'সতর্কতা',
      'info': 'তথ্য',
      'unknown': 'অজানা',
      'balance_info': 'ব্যালেন্স তথ্য',
      'member_since': 'যোগদানের তারিখ',
      'last_updated_at': 'শেষ আপডেট',
      'recalculating_balance': 'ব্যালেন্স পুনরায় হিসাব করা হচ্ছে...',
      'balance_updated': 'ব্যালেন্স আপডেট হয়েছে',
      'error_recalculating_balance': 'ব্যালেন্স পুনরায় হিসাব করতে সমস্যা',
      'uploading_image': 'ছবি আপলোড হচ্ছে...',
      'profile_picture_updated': 'প্রোফাইল ছবি আপডেট হয়েছে!',
      'monthly_breakdown': 'মাসিক জমার সিরিয়াল তালিকা',
      'deposit_history': 'জমার রসিদ ও ট্রানজেকশন',
      'serial_no': 'সিরিয়াল',
      'month_paid': 'পরিশোধিত',
      'month_due': 'বাকি',
      'month_count_label': 'মাস',
      'member_details': 'সদস্যের বিস্তারিত বিবরণ',
      'total_paid_months': 'মোট পরিশোধিত মাস',

      // ========== Auth ==========
      'login': 'লগইন',
      'signup': 'সাইন আপ',
      'logout': 'লগআউট',
      'sign_in': 'সাইন ইন',
      'sign_out': 'সাইন আউট',
      'sign_in_with_google': 'গুগল দিয়ে সাইন ইন',
      'sign_in_with_email': 'ইমেইল দিয়ে সাইন ইন',
      'email': 'ইমেইল',
      'password': 'পাসওয়ার্ড',
      'all': 'সব',
      'phone_number': 'ফোন নম্বর',
      'full_name': 'পূর্ণ নাম',
      'forgot_password': 'পাসওয়ার্ড ভুলে গেছেন?',
      'reset_password': 'পাসওয়ার্ড রিসেট',
      'create_account': 'অ্যাকাউন্ট তৈরি করুন',
      'already_have_account': 'ইতিমধ্যে অ্যাকাউন্ট আছে?',
      'dont_have_account': 'অ্যাকাউন্ট নেই?',
      'select_role': 'আপনার ভূমিকা নির্বাচন করুন',
      'user': 'ব্যবহারকারী',
      'admin': 'অ্যাডমিন',
      'enter_email': 'আপনার ইমেইল লিখুন',
      'enter_password': 'আপনার পাসওয়ার্ড লিখুন',
      'enter_phone': 'আপনার ফোন নম্বর লিখুন',
      'enter_name': 'আপনার পূর্ণ নাম লিখুন',

      // ========== Dashboard ==========
      'dashboard': 'ড্যাশবোর্ড',
      'admin_dashboard': 'অ্যাডমিন ড্যাশবোর্ড',
      'user_dashboard': 'ব্যবহারকারী ড্যাশবোর্ড',
      'home': 'হোম',
      'users': 'সদস্যগণ',
      'account': 'আমার অ্যাকাউন্ট',
      'my_account': 'আমার অ্যাকাউন্ট',
      'investments': 'বিনিয়োগ',
      'loans': 'ঋণ',
      'members': 'সদস্যগণ',
      'total_balance': 'মোট ব্যালেন্স',
      'current_balance': 'বর্তমান ব্যালেন্স',
      'total_investment': 'মোট বিনিয়োগ',
      'due_amount': 'বকেয়া পরিমাণ',
      'total_deposits': 'মোট জমা',
      'total_joma': 'সর্বমোট জমা',
      'my_total_balance': 'আমার মোট জমা',
      'my_total_joma': 'আমার মোট জমা',
      'user_total_balance': 'মোট জমা',
      'months_deposited': 'মাস জমা',
      'months_due': 'মাস বাকি',
      'total_months_deposited': 'মোট জমা মাস',
      'total_months_due': 'মোট বাকি মাস',
      'deposit_received_title': 'টাকা জমা হয়েছে',
      'deposit_received_body': 'আপনার অ্যাকাউন্টে টাকা জমা হয়েছে।',
      'total_withdrawals': 'মোট তোলা',
      'foundation_balance': 'ফাউন্ডেশন ব্যালেন্স',
      'overview': 'সারসংক্ষেপ',
      'quick_actions': 'দ্রুত কার্যক্রম',
      'recent_activity': 'সাম্প্রতিক কার্যক্রম',

      // ========== User Management ==========
      'user_management': 'ব্যবহারকারী ব্যবস্থাপনা',
      'manage_users': 'ব্যবহারকারী পরিচালনা',
      'all_users': 'সব ব্যবহারকারী',
      'pending_users': 'অপেক্ষমাণ ব্যবহারকারী',
      'active_users': 'সক্রিয় ব্যবহারকারী',
      'rejected_users': 'প্রত্যাখ্যাত ব্যবহারকারী',
      'blocked_users': 'অবরুদ্ধ ব্যবহারকারী',
      'approve': 'অনুমোদন',
      'reject': 'প্রত্যাখ্যান',
      'block': 'অবরুদ্ধ',
      'unblock': 'আনব্লক',
      'approve_user': 'ব্যবহারকারী অনুমোদন',
      'reject_user': 'ব্যবহারকারী প্রত্যাখ্যান',
      'block_user': 'ব্যবহারকারী অবরুদ্ধ',
      'user_details': 'ব্যবহারকারীর বিবরণ',
      'user_approved': 'ব্যবহারকারী সফলভাবে অনুমোদিত',
      'user_rejected': 'ব্যবহারকারী প্রত্যাখ্যাত',
      'user_blocked': 'ব্যবহারকারী অবরুদ্ধ',
      'no_users_found': 'কোন ব্যবহারকারী পাওয়া যায়নি',
      'search_users': 'ব্যবহারকারী খুঁজুন...',
      'total_users': 'মোট ব্যবহারকারী',
      'active_members': 'সক্রিয় সদস্য',
      'try_adjusting_search':
          'আপনার অনুসন্ধান বা ফিল্টার পরিবর্তন করে চেষ্টা করুন',
      'no_results_found': 'কোনো ফলাফল পাওয়া যায়নি',

      // ========== Admin Features ==========
      'deposit_management': 'জমা ব্যবস্থাপনা',
      'add_deposit': 'জমা যোগ করুন',
      'manage_deposits': 'যোগ ও পরিচালনা',
      'investment_management': 'বিনিয়োগ ব্যবস্থাপনা',
      'track_investments': 'ট্র্যাক ও আপডেট',
      'loan_management': 'ঋণ ব্যবস্থাপনা',
      'manage_loans': 'ঋণ পরিচালনা',
      'communication': 'যোগাযোগ',
      'send_message': 'বার্তা পাঠান',
      'send_messages': 'বার্তা পাঠান',
      'reports': 'রিপোর্ট',
      'view_analytics': 'বিশ্লেষণ দেখুন',
      'active_investments': 'সক্রিয় বিনিয়োগ',
      'pending_approvals': 'অপেক্ষমাণ অনুমোদন',
      'action_needed': 'পদক্ষেপ প্রয়োজন',
      'total_loans': 'মোট ঋণ',
      'total_debt': 'মোট ঋণ',
      'remaining_amount': 'অবশিষ্ট পরিমাণ',
      'no_investments_yet': 'এখনও কোনো বিনিয়োগ নেই',
      'no_loans_yet': 'এখনও কোনো ঋণ নেই',
      'create_investment_hint':
          'ইনভেস্টমেন্ট ম্যানেজমেন্ট থেকে আপনার প্রথম বিনিয়োগ তৈরি করুন',
      'create_loan_hint': 'লোন ম্যানেজমেন্ট থেকে আপনার প্রথম ঋণ তৈরি করুন',
      'remaining': 'অবশিষ্ট',
      'left': 'বাকি',
      'due': 'বকেয়া',
      'paid': 'পরিশোধিত',
      'online': 'অনলাইন',
      'offline': 'অফলাইন',
      'profit': 'লাভ',
      'interest': 'সুদ',
      'interest_percentage': 'সুদ',
      'please_login_to_view': 'দেখতে লগইন করুন',
      'please_login_view_investments': 'বিনিয়োগ দেখতে লগইন করুন',
      'error_loading_investments': 'বিনিয়োগ লোড করতে সমস্যা',
      'error_loading_members': 'সদস্য লোড করতে সমস্যা',
      'new_user_registered': 'নতুন ব্যবহারকারী নিবন্ধিত',
      'created_account': 'একটি অ্যাকাউন্ট তৈরি করেছেন',

      'total_investments': 'মোট বিনিয়োগ',
      'my_balance': 'আমার ব্যালেন্স',
      'my_deposits': 'আমার আমানত',
      'my_due': 'ঋণের বকেয়া',
      'loan_due': 'ঋণের বকেয়া',
      'total_remaining': 'মোট বাকি',
      'months_left': 'মাস বাকি',
      'loan_principal': 'মূল ঋণ',

      // ========== Analytics Screen ==========
      'overall_statistics': 'সার্বিক পরিসংখ্যান',
      'total_members': 'মোট সদস্য',
      'active_loans': 'সক্রিয় ঋণ',
      'recent_transactions': 'সাম্প্রতিক লেনদেন',

      // ========== Communication Screen ==========
      'communication_center': 'যোগাযোগ কেন্দ্র',
      'sent_messages': 'পাঠানো বার্তা',
      'templates': 'টেমপ্লেট',
      'total_sent': 'মোট পাঠানো',
      'read_rate': 'পড়ার হার',
      'no_messages_yet': 'এখনও কোনো বার্তা পাঠানো হয়নি',
      'send_first_message': 'ব্যবহারকারীদের প্রথম বার্তা পাঠান',
      'using_template': 'টেমপ্লেট ব্যবহার করা হচ্ছে',
      'title_label': 'শিরোনাম',
      'message_label': 'বার্তা',
      'type_label': 'ধরণ',
      'app_notification': 'অ্যাপ বিজ্ঞপ্তি',
      'message_sent_success': 'বার্তা সফলভাবে পাঠানো হয়েছে',
      'select_user_error': 'অনুগ্রহ করে একজন ব্যবহারকারী নির্বাচন করুন',
      'error_could_not_launch_sms': 'এসএমএস অ্যাপ চালু করা যায়নি',
      'error_loading_messages': 'বার্তা লোড করতে সমস্যা',

      // ========== User History / New Features ==========
      'user_history': 'ব্যবহারকারীর ইতিহাস',
      'view_history': 'ইতিহাস দেখুন',
      'select_user_history': 'ব্যবহারকারী নির্বাচন করুন (ইতিহাস)',

      'notification': 'বিজ্ঞপ্তি',
      'sms': 'এসএমএস',
      'both': 'উভয়',
      'sent_at': 'পাঠানোর সময়',
      'read_at': 'পড়ার সময়',
      'close': 'বন্ধ করুন',

      // ========== Add Deposit Screen ==========
      'add_deposit_subtitle': 'ব্যবহারকারীর ব্যালেন্স আপডেট করতে জমা যোগ করুন',
      'select_user_label': 'ব্যবহারকারী নির্বাচন করুন',
      'select_user_hint': 'একজন ব্যবহারকারী নির্বাচন করুন',
      'amount_label': 'পরিমাণ (৳)',
      'enter_amount': 'পরিমাণ লিখুন',
      'payment_method': 'পেমেন্ট পদ্ধতি',
      'reference_number': 'রেফারেন্স নম্বর',
      'enter_reference': 'রেফারেন্স নম্বর লিখুন',
      'date_label': 'তারিখ',
      'add_deposit_btn': 'জমা যোগ করুন',

      // ========== Account ==========
      'balance': 'ব্যালেন্স',
      'deposit': 'জমা',
      'withdraw': 'তোলা',
      'transaction_history': 'লেনদেনের ইতিহাস',
      'account_details': 'অ্যাকাউন্টের বিবরণ',
      'joined': 'যোগদান',
      'last_updated': 'শেষ আপডেট',
      'status': 'স্ট্যাটাস',
      'role': 'ভূমিকা',
      'admin_notes': 'অ্যাডমিন নোট',

      // ========== Settings ==========
      'settings': 'সেটিংস',
      'general': 'সাধারণ',
      'legal': 'আইনি',
      'account_section': 'অ্যাকাউন্ট',
      'language': 'ভাষা',
      'theme': 'থিম',
      'english': 'ইংরেজি',
      'bangla': 'বাংলা',
      'light_mode': 'লাইট মোড',
      'dark_mode': 'ডার্ক মোড',
      'notifications': 'বিজ্ঞপ্তি',
      'profile': 'প্রোফাইল',
      'edit_profile': 'প্রোফাইল সম্পাদনা',
      'edit_join_date': 'যোগদানের তারিখ সম্পাদনা',
      'edit_total_deposits': 'মোট জমা সম্পাদনা',
      'change_password': 'পাসওয়ার্ড পরিবর্তন',
      'privacy_policy': 'গোপনীয়তা নীতি',
      'terms_of_service': 'পরিষেবার শর্তাবলী',
      'select_language': 'ভাষা নির্বাচন করুন',
      'about': 'সম্পর্কে',
      'version': 'সংস্করণ',

      // ========== Terms & Privacy (Bangla) ==========
      'terms_title': 'পরিষেবার শর্তাবলী',
      'legal_last_updated': 'সর্বশেষ আপডেট: জানুয়ারি ২০২৬',
      'terms_1_title': '১. শর্তাবলী গ্রহণ',
      'terms_1_content':
          'ফাউন্ডেশন অ্যাপ অ্যাক্সেস এবং ব্যবহার করে, আপনি এই চুক্তির শর্তাবলী এবং বিধিগুলি মেনে চলতে এবং এতে সম্মত হন। যদি আপনি এই শর্তাবলীতে সম্মত না হন, তবে দয়া করে এই অ্যাপ্লিকেশনটি ব্যবহার করবেন না।',
      'terms_2_title': '২. ব্যবহারকারী অ্যাকাউন্ট',
      'terms_2_content':
          'অ্যাপের কিছু বৈশিষ্ট্য অ্যাক্সেস করতে, আপনাকে একটি অ্যাকাউন্টের জন্য নিবন্ধন করতে হবে। আপনার অ্যাকাউন্টের ক্রেডেনশিয়ালগুলির গোপনীয়তা বজায় রাখা এবং আপনার অ্যাকাউন্টের অধীনে যা কিছু ঘটে তার জন্য আপনি দায়ী।',
      'terms_3_title': '৩. আর্থিক লেনদেন',
      'terms_3_content':
          'জমা, টাকা তোলা, ঋণ এবং বিনিয়োগ সহ সমস্ত আর্থিক লেনদেন অ্যাডমিনের যাচাইকরণ এবং অনুমোদনের সাপেক্ষে। ফাউন্ডেশন অ্যাপ এমন যেকোনো লেনদেন প্রত্যাখ্যান বা উল্টে দেওয়ার অধিকার রাখে যা আমাদের নীতি বা স্থানীয় আইন লঙ্ঘন করে।',
      'terms_4_title': '৪. ঋণ এবং বিনিয়োগ',
      'terms_4_content':
          'ঋণের আবেদন এবং বিনিয়োগের সুযোগগুলি অনুমোদনের সাপেক্ষে। যেকোনো চুক্তির আগে সুদের হার, শর্তাবলী এবং নিয়মাবলী স্পষ্টভাবে উল্লেখ করা হবে। ব্যবহারকারীরা সম্মত সময়সূচী অনুযায়ী সময়মতো ঋণ পরিশোধের জন্য দায়ী।',
      'terms_5_title': '৫. ব্যবহারকারীর দায়িত্ব',
      'terms_5_content':
          'নিবন্ধন এবং লেনদেন করার সময় ব্যবহারকারীদের সঠিক এবং সত্য তথ্য প্রদান করতে হবে। যেকোনো প্রতারণামূলক কার্যকলাপ বা ভুল তথ্যের কারণে অ্যাকাউন্ট স্থগিত বা বন্ধ এবং আইনি ব্যবস্থা নেওয়া হতে পারে।',
      'terms_6_title': '৬. দায়বদ্ধতার সীমাবদ্ধতা',
      'terms_6_content':
          'ফাউন্ডেশন অ্যাপটি "যেমন আছে" ভিত্তিতে প্রদান করা হয়। আর্থিক ক্ষতি, ডেটা লস বা পরিষেবা বিঘ্নিত হওয়া সহ এই অ্যাপ্লিকেশনটি ব্যবহারের ফলে উদ্ভূত কোনো ক্ষতি, ক্ষয়ক্ষতি বা সমস্যার জন্য আমরা দায়ী নই।',
      'terms_7_title': '৭. গোপনীয়তা',
      'terms_7_content':
          'ফাউন্ডেশন অ্যাপের আপনার ব্যবহার আমাদের গোপনীয়তা নীতি দ্বারাও নিয়ন্ত্রিত হয়। আপনার ব্যক্তিগত তথ্য সম্পর্কিত আমাদের অনুশীলনগুলি বুঝতে দয়া করে আমাদের গোপনীয়তা নীতি পর্যালোচনা করুন।',
      'terms_8_title': '৮. পরিবর্তন',
      'terms_8_content':
          'আমরা যেকোনো সময় এই শর্তাবলী পরিবর্তন করার অধিকার রাখি। উল্লেখযোগ্য পরিবর্তন সম্পর্কে ব্যবহারকারীদের অবহিত করা হবে এবং অ্যাপটির অবিচ্ছিন্ন ব্যবহার পরিবর্তিত শর্তাবলী গ্রহণ বলে গণ্য হবে।',
      'terms_9_title': '৯. সমাপ্তি',
      'terms_9_content':
          'আমরা এই শর্তাবলী লঙ্ঘন, প্রতারণামূলক কার্যকলাপ বা প্ল্যাটফর্ম এবং এর ব্যবহারকারীদের সুরক্ষার জন্য প্রয়োজনীয় অন্য যেকোনো কারণে যেকোনো সময় আপনার অ্যাকাউন্ট বন্ধ বা স্থগিত করতে পারি।',
      'terms_10_title': '১০. যোগাযোগের তথ্য',
      'terms_10_content':
          'এই পরিষেবার শর্তাবলী সম্পর্কে আপনার যদি কোনো প্রশ্ন থাকে, তবে দয়া করে অ্যাপের মাধ্যমে আমাদের সহায়ক দলের সাথে যোগাযোগ করুন বা sis2024.bd@gmail.com এ আমাদের ইমেল করুন।',
      'copyright': '© ২০২৬ ফাউন্ডেশন অ্যাপ। সর্বস্বত্ব সংরক্ষিত।',

      'privacy_title': 'গোপনীয়তা নীতি',
      'privacy_intro_title': 'ভূমিকা',
      'privacy_intro_content':
          'ফাউন্ডেশন অ্যাপ ("আমরা," "আমাদের") আপনার গোপনীয়তা রক্ষা করতে প্রতিশ্রুতিবদ্ধ। আপনি যখন আমাদের মোবাইল অ্যাপ্লিকেশন ব্যবহার করেন তখন আমরা কীভাবে আপনার তথ্য সংগ্রহ, ব্যবহার, প্রকাশ এবং সুরক্ষা করি তা এই গোপনীয়তা নীতি ব্যাখ্যা করে।',
      'privacy_1_title': '১. আমরা যে তথ্য সংগ্রহ করি',
      'privacy_1_content':
          'আমরা আপনার দেওয়া তথ্য সরাসরি সংগ্রহ করি, যার মধ্যে রয়েছে:\n\n• ব্যক্তিগত শনাক্তকরণ তথ্য (নাম, ইমেল ঠিকানা, ফোন নম্বর)\n• আর্থিক তথ্য (লেনদেনের ইতিহাস, অ্যাকাউন্টের ব্যালেন্স, ঋণের বিবরণ, বিনিয়োগ রেকর্ড)\n• ডিভাইসের তথ্য (ডিভাইসের ধরন, অপারেটিং সিস্টেম, অনন্য ডিভাইস শনাক্তকারী)\n• ব্যবহারের ডেটা (অ্যাপ ইন্টারঅ্যাকশন, ব্যবহৃত ফিচার, ব্যয় করা সময়)',
      'privacy_2_title': '২. আমরা কীভাবে আপনার তথ্য ব্যবহার করি',
      'privacy_2_content':
          'আমরা সংগৃহীত তথ্য ব্যবহার করি:\n\n• আমাদের পরিষেবাগুলি প্রদান এবং রক্ষণাবেক্ষণ করতে\n• লেনদেন প্রক্রিয়া করতে এবং আপনার অ্যাকাউন্ট পরিচালনা করতে\n• আপনার অ্যাকাউন্টের কার্যকলাপ সম্পর্কে বিজ্ঞপ্তি পাঠাতে\n• আপনার অভিজ্ঞতা উন্নত এবং ব্যক্তিগতকৃত করতে\n• আইনি বাধ্যবাধকতা মেনে চলতে এবং প্রতারণা প্রতিরোধ করতে\n• আমাদের পরিষেবাগুলির আপডেট এবং পরিবর্তন সম্পর্কে আপনার সাথে যোগাযোগ করতে',
      'privacy_3_title': '৩. তথ্য শেয়ার করা',
      'privacy_3_content':
          'আমরা আপনার ব্যক্তিগত তথ্য বিক্রি করি না। আমরা শুধুমাত্র নিম্নলিখিত পরিস্থিতিতে আপনার তথ্য শেয়ার করতে পারি:\n\n• আপনার সম্মতিতে\n• আইনি বাধ্যবাধকতা মেনে চলতে\n• আমাদের অধিকার রক্ষা করতে এবং প্রতারণা প্রতিরোধ করতে\n• পরিষেবা প্রদানকারীদের সাথে যারা আমাদের অ্যাপ পরিচালনায় সহায়তা করে (কঠোর গোপনীয়তা চুক্তির অধীনে)',
      'privacy_4_title': '৪. ডেটা নিরাপত্তা',
      'privacy_4_content':
          'আমরা আপনার ব্যক্তিগত তথ্য রক্ষা করার জন্য উপযুক্ত প্রযুক্তিগত এবং সাংগঠনিক নিরাপত্তা ব্যবস্থা গ্রহণ করি। তবে, ইন্টারনেটের মাধ্যমে ট্রান্সমিশন বা ইলেকট্রনিক স্টোরেজের কোনো পদ্ধতিই ১০০% নিরাপদ নয়। যদিও আমরা আপনার ডেটা রক্ষা করার চেষ্টা করি, আমরা সম্পূর্ণ নিরাপত্তার নিশ্চয়তা দিতে পারি না।',
      'privacy_5_title': '৫. আপনার অধিকার',
      'privacy_5_content':
          'আপনার অধিকার আছে:\n\n• আপনার ব্যক্তিগত তথ্য অ্যাক্সেস করা\n• ভুল ডেটা সংশোধনের অনুরোধ করা\n• আপনার ডেটা মুছে ফেলার অনুরোধ করা (আইনি প্রয়োজনীয়তা সাপেক্ষে)\n• নির্দিষ্ট ডেটা সংগ্রহের অনুশীলন থেকে অপ্ট-আউট করা\n• যেখানে প্রযোজ্য সেখানে সম্মতি প্রত্যাহার করা',
      'privacy_6_title': '৬. ডেটা সংরক্ষণ',
      'privacy_6_content':
          'আমরা এই গোপনীয়তা নীতিতে বর্ণিত উদ্দেশ্যগুলি পূরণ করার জন্য যতক্ষণ প্রয়োজন ততক্ষণ আপনার ব্যক্তিগত তথ্য সংরক্ষণ করি, যদি না আইন দ্বারা দীর্ঘতর সংরক্ষণের সময়কাল প্রয়োজন হয় বা বিরোধ সমাধানের জন্য প্রয়োজন হয়।',
      'privacy_7_title': '৭. কুকিজ এবং ট্র্যাকিং',
      'privacy_7_content':
          'আমাদের অ্যাপ আপনার অ্যাপ ব্যবহার এবং পছন্দ সম্পর্কে তথ্য সংগ্রহ করতে কুকিজ এবং অনুরূপ ট্র্যাকিং প্রযুক্তি ব্যবহার করতে পারে। আপনি আপনার ডিভাইস সেটিংসের মাধ্যমে কুকি সেটিংস নিয়ন্ত্রণ করতে পারেন।',
      'privacy_8_title': '৮. তৃতীয় পক্ষের পরিষেবা',
      'privacy_8_content':
          'আমাদের অ্যাপে তৃতীয় পক্ষের পরিষেবার লিঙ্ক থাকতে পারে। আমরা এই তৃতীয় পক্ষের গোপনীয়তা অনুশীলনের জন্য দায়ী নই। কোনো তথ্য প্রদান করার আগে তাদের গোপনীয়তা নীতি পর্যালোচনা করার জন্য আমরা আপনাকে উৎসাহিত করি।',
      'privacy_9_title': '৯. শিশুদের গোপনীয়তা',
      'privacy_9_content':
          'আমাদের অ্যাপটি ১৮ বছরের কম বয়সী শিশুদের ব্যবহারের জন্য নয়। আমরা জেনেশুনে শিশুদের কাছ থেকে ব্যক্তিগত তথ্য সংগ্রহ করি না। যদি আমরা আবিষ্কার করি যে আমরা একটি শিশুর কাছ থেকে তথ্য সংগ্রহ করেছি, আমরা তা অবিলম্বে মুছে ফেলব।',
      'privacy_10_title': '১০. গোপনীয়তা নীতি পরিবর্তন',
      'privacy_10_content':
          'আমরা সময় সময় এই গোপনীয়তা নীতি আপডেট করতে পারি। আমরা অ্যাপে নতুন নীতি পোস্ট করে এবং "সর্বশেষ আপডেট" তারিখ আপডেট করে আপনাকে উল্লেখযোগ্য পরিবর্তনগুলি সম্পর্কে অবহিত করব।',
      'privacy_11_title': '১১. যোগাযোগ করুন',
      'privacy_11_content':
          'এই গোপনীয়তা নীতি বা আমাদের ডেটা অনুশীলন সম্পর্কে আপনার যদি কোনো প্রশ্ন বা উদ্বেগ থাকে, তবে দয়া করে আমাদের সাথে এখানে যোগাযোগ করুন:\n\nইমেইল: sis2024.bd@gmail.com\nঠিকানা: ফাউন্ডেশন অ্যাপ সাপোর্ট টিম',

      // ========== Messages ==========
      'are_you_sure': 'আপনি কি নিশ্চিত?',
      'confirm_logout': 'আপনি কি লগআউট করতে চান?',
      'confirm_delete': 'আপনি কি মুছতে চান?',
      'confirm_approve': 'আপনি কি এই ব্যবহারকারীকে অনুমোদন করতে চান?',
      'confirm_reject': 'আপনি কি এই ব্যবহারকারীকে প্রত্যাখ্যান করতে চান?',
      'confirm_block': 'আপনি কি এই ব্যবহারকারীকে অবরুদ্ধ করতে চান?',
      'operation_success': 'অপারেশন সফলভাবে সম্পন্ন হয়েছে',
      'operation_failed': 'অপারেশন ব্যর্থ হয়েছে',
      'something_went_wrong': 'কিছু ভুল হয়েছে',
      'try_again': 'আবার চেষ্টা করুন',
      'no_internet': 'ইন্টারনেট সংযোগ নেই',
      'check_connection': 'আপনার সংযোগ পরীক্ষা করুন',
      'coming_soon': 'শীঘ্রই আসছে!',

      // ========== Status Messages ==========
      'account_pending': 'অ্যাকাউন্ট অনুমোদনের অপেক্ষায়',
      'account_approved': 'অ্যাকাউন্ট অনুমোদিত',
      'account_rejected': 'অ্যাকাউন্ট প্রত্যাখ্যাত',
      'account_blocked': 'অ্যাকাউন্ট অবরুদ্ধ',
      'waiting_approval': 'অ্যাডমিন অনুমোদনের জন্য অপেক্ষা করছে',
      'approval_message':
          'আপনার অ্যাকাউন্ট পর্যালোচনাধীন। অনুমোদিত হলে অ্যাক্সেস পাবেন।',
      'rejection_message':
          'আপনার অ্যাকাউন্ট অনুরোধ প্রত্যাখ্যান করা হয়েছে। প্রশাসকের সাথে যোগাযোগ করুন।',
      'blocked_message':
          'আপনার অ্যাকাউন্ট অবরুদ্ধ করা হয়েছে। প্রশাসকের সাথে যোগাযোগ করুন।',

      'overdue': 'খেলাপী',
      'details': 'বিস্তারিত',
      'required_field': 'আবশ্যক ক্ষেত্র',

      // ========== Loan Management ==========

      'create_loan_title': 'ঋণ তৈরি করুন',
      'loan_created_success': 'ঋণ সফলভাবে তৈরি হয়েছে',
      'total_collected': 'মোট আদায়',
      'search_loan_hint': 'নাম, ফোন বা আইডি দ্বারা অনুসন্ধান...',
      'payment_progress': 'পরিশোধের অগ্রগতি',
      'update_payment': 'পেমেন্ট আপডেট',
      'record_payment': 'পেমেন্ট রেকর্ড করুন',
      'borrower': 'ঋণগ্রহীতা',
      'enter_payment_amount': 'পেমেন্টের পরিমাণ দিন',
      'record': 'রেকর্ড করুন',
      'payment_recorded_success': 'পেমেন্ট সফলভাবে রেকর্ড হয়েছে',
      'loan_details': 'ঋণের বিবরণ',
      'borrower_name': 'ঋণগ্রহীতার নাম',
      'borrower_phone': 'ফোন',
      'loan_amount_label': 'ঋণের পরিমাণ',
      'total_amount': 'মোট পরিমাণ',
      'paid_amount': 'পরিশোধিত পরিমাণ',
      'interest_rate_label': 'সুদের হার',
      'due_date': 'প্রদেয় তারিখ',
      'delete_loan_title': 'ঋণ মুছুন',
      'delete_loan_confirm': 'আপনি কি এই ঋণটি মুছতে নিশ্চিত?',
      'loan_deleted_success': 'ঋণ সফলভাবে মুছে ফেলা হয়েছে',
      'error_loading_loans': 'ঋণ লোড করতে সমস্যা',
      'no_loans_found': 'কোনো ঋণ পাওয়া যায়নি',
      'create_first_loan': 'আপনার প্রথম ঋণ তৈরি করুন',
      'create_loan': 'ঋণ তৈরি করুন',

      // ========== Investment Management ==========
      'create_investment_title': 'বিনিয়োগ তৈরি করুন',
      'investment_created_success': 'বিনিয়োগ সফলভাবে তৈরি হয়েছে',
      'total_invested': 'মোট বিনিয়োগ',
      'expected_return': 'প্রত্যাশিত আয়',
      'total_profit': 'মোট লাভ',
      'no_investments_found': 'কোনো বিনিয়োগ পাওয়া যায়নি',
      'start_creating_investment': 'একটি বিনিয়োগ তৈরি করে শুরু করুন',
      'invested': 'বিনিয়োগকৃত',
      'expected': 'প্রত্যাশিত',
      'duration': 'সময়কাল',
      'months': 'মাস',
      'days': 'দিন',
      'progress': 'অগ্রগতি',
      'investment_details': 'বিনিয়োগের বিবরণ',
      'project_name': 'প্রকল্পের নাম',
      'investor': 'বিনিয়োগকারী',
      'sector': 'খাত',
      'investment_amount': 'বিনিয়োগের পরিমাণ',
      'actual_return': 'প্রকৃত আয়',
      'delete_investment_title': 'বিনিয়োগ মুছুন',
      'delete_investment_confirm': 'আপনি কি মুছতে নিশ্চিত',
      'investment_deleted_success': 'বিনিয়োগ সফলভাবে মুছে ফেলা হয়েছে',
      'update_investment_returns': 'বিনিয়োগের আয় আপডেট করুন',
      'actual_return_amount': 'প্রকৃত আয়ের পরিমাণ',
      'returns_updated_success': 'আয় সফলভাবে আপডেট হয়েছে',

      // ========== Sectors & Risk ==========
      'property': 'সম্পত্তি',
      'business': 'ব্যবসা',
      'agriculture': 'কৃষি',
      'risk_low': 'কম',
      'risk_medium': 'মাঝারি',
      'risk_high': 'উচ্চ',

      // ========== Create Investment Form ==========
      'project_info': 'প্রকল্পের তথ্য',
      'project_name_label': 'প্রকল্পের নাম *',
      'project_name_hint': 'যেমন, XYZ প্লাজা নির্মাণ',
      'enter_project_name': 'অনুগ্রহ করে প্রকল্পের নাম দিন',
      'enter_project_desc': 'প্রকল্পের বিবরণ দিন',
      'sector_label': 'খাত *',
      'risk_level_label': 'ঝুঁকির মাত্রা *',
      'financial_info': 'আর্থিক তথ্য',

      'enter_investment_amount': 'অনুগ্রহ করে বিনিয়োগের পরিমাণ দিন',
      'enter_valid_number': 'অনুগ্রহ করে একটি বৈধ সংখ্যা দিন',
      'amount_positive': 'পরিমাণ ০ এর বেশি হতে হবে',
      'enter_expected_return': 'প্রত্যাশিত আয় দিন',
      'enter_expected_return_error': 'অনুগ্রহ করে প্রত্যাশিত আয় দিন',
      'return_positive': 'আয় ০ এর বেশি হতে হবে',
      'timeline': 'সময়রেখা',
      'start_date_label': 'শুরুর তারিখ',
      'end_date_label': 'প্রত্যাশিত শেষ তারিখ',
      'start_date': 'শুরুর তারিখ',
      'monthly_tracking': 'মাসিক ট্র্যাকিং',
      'no_schedule_available': 'কোনো শিডিউল পাওয়া যায়নি',

      // ========== Deposit Management ==========
      'deposit_added_success': 'আমানত সফলভাবে যোগ করা হয়েছে',
      'total_deposit_title': 'মোট আমানত',
      'transactions_count': 'লেনদেন',
      'search_user_hint': 'ব্যবহারকারীর নাম দ্বারা অনুসন্ধান...',
      'cash': 'নগদ',
      'bank_transfer': 'ব্যাংক ট্রান্সফার',
      'mobile_banking': 'মোবাইল ব্যাংকিং',
      'error_loading_deposits': 'আমানত লোড করতে সমস্যা',
      'no_deposits_found': 'কোনো আমানত পাওয়া যায়নি',
      'start_adding_deposit': 'একটি আমানত যোগ করে শুরু করুন',
      'method': 'পদ্ধতি',
      'reference': 'রেফারেন্স',
      'by_admin': 'দ্বারা: অ্যাডমিন',
      'deposit_details': 'আমানতের বিবরণ',
      'user_name': 'ব্যবহারকারীর নাম',
      'delete_deposit_title': 'আমানত মুছুন',
      'delete_deposit_confirm': 'আপনি কি এই আমানতটি মুছতে নিশ্চিত?',
      'deposit_deleted_success': 'আমানত সফলভাবে মুছে ফেলা হয়েছে',
      'error_deleting_deposit': 'আমানত মুছতে সমস্যা',
      'deposit_management_title': 'জমা ব্যবস্থাপনা',
      'transactions': 'লেনদেন',
      'no_transactions': 'কোনো লেনদেন নেই',
      'search_by_username': 'ব্যবহারকারীর নাম দ্বারা অনুসন্ধান...',
      'try_different_search': 'ভিন্ন অনুসন্ধান চেষ্টা করুন',
      'by': 'দ্বারা',
      'amount': 'পরিমাণ',
      'date': 'তারিখ',
      'please_enter_amount': 'অনুগ্রহ করে পরিমাণ দিন',
      'please_enter_reference': 'অনুগ্রহ করে রেফারেন্স নম্বর দিন',
      'deposit_added_for': 'এর জন্য জমা যোগ করা হয়েছে',

      // ========== Create Loan Form Keys ==========
      'create_new_loan_info': 'ব্যবহারকারীর জন্য একটি নতুন ঋণ রেকর্ড তৈরি করুন',
      'select_user': 'ব্যবহারকারী নির্বাচন করুন',
      'loading_users': 'ব্যবহারকারী লোড হচ্ছে...',
      'error_loading_users': 'ব্যবহারকারী লোড করতে সমস্যা',
      'no_active_users': 'কোনো সক্রিয় ব্যবহারকারী পাওয়া যায়নি',
      'select_a_user': 'একজন ব্যবহারকারী নির্বাচন করুন',
      'loan_amount': 'ঋণের পরিমাণ',
      'enter_loan_amount': 'ঋণের পরিমাণ দিন',
      'required': 'আবশ্যক',
      'please_enter_valid_amount': 'অনুগ্রহ করে একটি বৈধ পরিমাণ দিন',
      'amount_must_be_greater_than_zero': 'পরিমাণ শূন্যের বেশি হতে হবে',
      'interest_rate': 'সুদের হার',
      'enter_interest_rate': 'সুদের হার দিন',
      'please_enter_valid_rate': 'অনুগ্রহ করে একটি বৈধ হার দিন',
      'rate_cannot_be_negative': 'হার নেতিবাচক হতে পারে না',
      'loan_duration': 'ঋণের মেয়াদ',
      '3_months': '৩ মাস',
      '6_months': '৬ মাস',
      '1_year': '১ বছর',
      '2_years': '২ বছর',
      'please_select_user': 'অনুগ্রহ করে একজন ব্যবহারকারী নির্বাচন করুন',

      // ========== Loan Features ==========
      'loan_taken': 'গৃহীত ঋণ',
      'payment_status': 'পরিশোধের অবস্থা',
      'paid_months': 'পরিশোধিত',
      'due_months': 'বকেয়া',
      'overdue_months': 'মেয়াদোত্তীর্ণ',
      'loan_paid': 'ঋণ পরিশোধ',
      'transaction': 'লেনদেন',

      // ========== Months ==========
      'january': 'জানুয়ারি',
      'february': 'ফেব্রুয়ারি',
      'march': 'মার্চ',
      'april': 'এপ্রিল',
      'may': 'মে',
      'june': 'জুন',
      'july': 'জুলাই',
      'august': 'আগস্ট',
      'september': 'সেপ্টেম্বর',
      'october': 'অক্টোবর',
      'november': 'নভেম্বর',
      'december': 'ডিসেম্বর',

      // ========== Status Values ==========
      'status_active': 'সক্রিয়',
      'status_pending': 'অপেক্ষমাণ',
      'status_completed': 'সম্পন্ন',
      'status_overdue': 'খেলাপী',
      'status_paid': 'পরিশোধিত',
      'status_rejected': 'প্রত্যাখ্যাত',
      'status_blocked': 'অবরুদ্ধ',
      'status_failed': 'ব্যর্থ',
      'role_admin': 'অ্যাডমিন',
      'role_user': 'ব্যবহারকারী',
      'not_available': 'পাওয়া যায়নি',
    },
  };
}
