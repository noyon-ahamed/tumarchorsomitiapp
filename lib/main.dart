import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:foundation_app/config/theme/app_theme.dart';
import 'package:foundation_app/presentation/user/screens/admin_dashboard_screen.dart';
import 'package:foundation_app/services/local/connectivity_service.dart';
import 'package:foundation_app/services/local/database_helper.dart';
import 'package:foundation_app/services/local/sync_service.dart';
import 'package:foundation_app/services/notification_service.dart';
import 'package:provider/provider.dart';
import 'services/firebase/firebase_service.dart';
import 'providers/authprovider.dart';
import 'providers/theme_provider.dart';
import 'providers/language_provider.dart';
import 'presentation/auth/screens/role_selection_screen.dart';
import 'presentation/auth/screens/splash_screen.dart';
import 'presentation/user/screens/user_dashboard_screen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await FirebaseService.initialize();
  await DatabaseHelper().database;
  await SyncService().initialize();
  await ConnectivityService().initialize();
  
  // Initialize Notification Service (includes FCM)
  final notificationService = NotificationService();
  await notificationService.init();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => SyncService()),
        ChangeNotifierProvider(create: (_) => ConnectivityService()),
        
      ],
      child: Consumer2<ThemeProvider, LanguageProvider>(
        builder: (context, themeProvider, languageProvider, child) {
          return MaterialApp(
            title: 'টুমার চর সমিতি',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            locale: languageProvider.locale,
            supportedLocales: const [
              Locale('en', ''),
              Locale('bn', ''),
            ],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            builder: (context, child) {
              return LanguageSyncWrapper(child: child!);
            },
            home: const SplashScreen(),
            routes: {
              '/login': (context) => const RoleSelectionScreen(),
              '/admin-dashboard': (context) => const AdminDashboardScreen(),
              '/user-dashboard': (context) => const UserDashboardScreen(),
            },
            debugShowMaterialGrid: false,
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        debugPrint(
          'AuthWrapper rebuild: isLoading=${authProvider.isLoading}, '
          'isLoggedIn=${authProvider.isLoggedIn}, '
          'userData=${authProvider.userData != null}, '
          'needsProfile=${authProvider.needsProfileCompletion}, '
          'role=${authProvider.userRole}, '
          'status=${authProvider.userStatus}',
        );

        // Show loading while checking auth state
        if (authProvider.isLoading) {
          debugPrint('Showing loading screen');
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Not logged in - show role selection
        if (!authProvider.isLoggedIn) {
          debugPrint('Not logged in - showing role selection');
          return const RoleSelectionScreen();
        }

        // User logged in but needs to complete profile
        if (authProvider.needsProfileCompletion) {
          debugPrint('User needs profile completion - navigating to CreateAccountScreen');
          // This will be handled by the login screen's pushReplacement
          // But fallback to show loading while profile is being completed
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Setting up your profile...'),
                ],
              ),
            ),
          );
        }

        debugPrint('User logged in, checking status...');

        // Check user status - if pending, show approval screen
        if (authProvider.isPending) {
          debugPrint('User pending - showing pending screen');
          return const PendingApprovalScreen();
        }

        if (authProvider.isRejected) {
          debugPrint('User rejected - showing rejected screen');
          return const RejectedAccountScreen();
        }

        // User is approved - show appropriate dashboard
        // Show dashboard if we have userData (either from Firestore or fallback)
        if (authProvider.userData != null) {
          if (authProvider.isAdmin) {
            debugPrint('Showing admin dashboard');
            return AdminDashboardScreen();
          } else {
            debugPrint('Showing user dashboard');
            return UserDashboardScreen();
          }
        }

        // Fallback - still waiting for user data
        debugPrint('Waiting for user data');
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }
}

// Pending Approval Screen
class PendingApprovalScreen extends StatelessWidget {
  const PendingApprovalScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.pending_actions,
                    size: 60,
                    color: Colors.orange,
                  ),
                ),
                
                const SizedBox(height: 32),
                
                Text(
                  'Account Pending Approval',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 16),
                
                Text(
                  'Your account is currently under review by an administrator. You\'ll receive access once approved.',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 32),
                
                ElevatedButton.icon(
                  onPressed: () async {
                    await authProvider.reloadUserData();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Check Status'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                TextButton.icon(
                  onPressed: () async {
                    await authProvider.signOut();
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Sign Out'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Rejected Account Screen
class RejectedAccountScreen extends StatelessWidget {
  const RejectedAccountScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.cancel_outlined,
                    size: 60,
                    color: Colors.red,
                  ),
                ),
                
                const SizedBox(height: 32),
                
                Text(
                  'Account Rejected',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 16),
                
                Text(
                  'Your account request has been rejected. Please contact the administrator for more information.',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 32),
                
                ElevatedButton.icon(
                  onPressed: () async {
                    await authProvider.signOut();
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Sign Out'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ✅ Wrapper to sync language settings with user account
class LanguageSyncWrapper extends StatefulWidget {
  final Widget child;
  const LanguageSyncWrapper({Key? key, required this.child}) : super(key: key);

  @override
  State<LanguageSyncWrapper> createState() => _LanguageSyncWrapperState();
}

class _LanguageSyncWrapperState extends State<LanguageSyncWrapper> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authProvider = Provider.of<AuthProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    
    // Update language provider with current user ID
    // This allows LanguageProvider to switch preferences
    // We use addPostFrameCallback to avoid state updates during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      languageProvider.updateUser(authProvider.user?.uid);
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}