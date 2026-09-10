import 'package:flutter/material.dart';
import 'package:foundation_app/presentation/auth/screens/create_sccount_screen.dart';
import 'package:foundation_app/providers/authprovider.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';

class LoginScreen extends StatefulWidget {
  final bool isAdmin;
  
  const LoginScreen({
    Key? key,
    required this.isAdmin,
  }) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // For admin login
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  // Add new controllers for user login
  final _userUsernameController = TextEditingController();
  final _userPasswordController = TextEditingController();
  final _userFormKey = GlobalKey<FormState>();
  bool _obscureUserPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _userUsernameController.dispose();
    _userPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleUserUsernameLogin() async {
    if (!_userFormKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    
    debugPrint('🔐 User login attempt: ${_userUsernameController.text.trim()}');
    
    final success = await authProvider.signInWithUsernamePassword(
      username: _userUsernameController.text.trim(),
      password: _userPasswordController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      debugPrint('✅ Sign-in successful, checking user privileges...');
      
      // Wait a bit to ensure data is loaded
      await Future.delayed(const Duration(milliseconds: 1500));
      
      if (!mounted) return;
      
      // Strict user check (prevent admins from logging in here)
      if (authProvider.isAdmin) {
        debugPrint('❌ Admin account trying to use user login.');
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please use the Admin Login section'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
        
        await authProvider.signOut();
        return;
      }
      
      // Check if user account is active
      if (!authProvider.isApproved) {
        debugPrint('❌ User account not active. Status: ${authProvider.userStatus}');
        
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
            content: Text('Your account is ${authProvider.userStatus}. Please contact admin.'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
          ),
        );
        
        await authProvider.signOut();
        return;
      }
      
      debugPrint('✅ User login successful!');
      
      // Success - navigate to user dashboard
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/user-dashboard',
          (route) => false,
        );
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Login Successful!'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      
    } else {
      // Login failed
      if (authProvider.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage!),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    final authProvider = context.read<AuthProvider>();
    
    final success = await authProvider.signInWithGoogle();

    if (!mounted) return;

    if (success) {
      // Check if user needs to complete profile
      if (authProvider.needsProfileCompletion) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => CreateAccountScreen(
              defaultEmail: authProvider.user!.email ?? '',
              defaultName: authProvider.user!.displayName ?? '',
              photoUrl: authProvider.user!.photoURL,
            ),
          ),
        );
        return;
      }

      // Profile exists - check approval status
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (!mounted) return;

      if (authProvider.isPending) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.pending_actions, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Your account is pending approval by admin. Please wait.',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 4),
          ),
        );
        await authProvider.signOut();
        return;
      }

      if (authProvider.isRejected) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your account has been rejected. Contact admin.'),
            backgroundColor: Colors.red,
          ),
        );
        await authProvider.signOut();
        return;
      }

      // User role check
      if (authProvider.isAdmin) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please use admin login'),
            backgroundColor: Colors.red,
          ),
        );
        await authProvider.signOut();
        return;
      }

      // All checks passed - navigate to user dashboard
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/user-dashboard',
          (route) => false,
        );
      }
    } else {
      if (authProvider.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage!),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Replace the _handleAdminLogin method in LoginScreen with this:
  // ... (Keep existing _handleAdminLogin code) ...

Future<void> _handleAdminLogin() async {
// ... existing admin login code ...
    if (!_formKey.currentState!.validate()) return;

  final authProvider = context.read<AuthProvider>();
  
  debugPrint('🔐 Admin login attempt: ${_emailController.text.trim()}');
  
  final success = await authProvider.signInWithEmailPassword(
    email: _emailController.text.trim(),
    password: _passwordController.text.trim(),
  );

  if (!mounted) return;

  if (success) {
    debugPrint('✅ Sign-in successful, checking admin privileges...');
    
    // Wait a bit more to ensure data is loaded
    await Future.delayed(const Duration(milliseconds: 1500));
    
    if (!mounted) return;
    
    debugPrint('User role: ${authProvider.userRole}');
    debugPrint('User status: ${authProvider.userStatus}');
    debugPrint('Is admin: ${authProvider.isAdmin}');
    
    // Strict admin check
    if (authProvider.userRole != 'admin') {
      debugPrint('❌ Not an admin account. Role: ${authProvider.userRole}');
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'This account is not authorized as admin.\nPlease use admin credentials.',
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
      
      await authProvider.signOut();
      return;
    }
    
    // Check if admin account is active
    if (authProvider.userStatus != 'Active') {
      debugPrint('❌ Admin account not active. Status: ${authProvider.userStatus}');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Admin account status: ${authProvider.userStatus}\nContact system administrator.',
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 4),
        ),
      );
      
      await authProvider.signOut();
      return;
    }
    
    debugPrint('✅ Admin login successful!');
    
    // Success - navigate to admin dashboard
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/admin-dashboard',
        (route) => false,
      );
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Text('Welcome Admin!'),
          ],
        ),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
    
  } else {
    // Login failed
    debugPrint('❌ Login failed: ${authProvider.errorMessage}');
    
    if (authProvider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage!),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isAdmin ? 'Admin Login' : 'User Login'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: widget.isAdmin ? _buildAdminLogin() : _buildUserLogin(),
        ),
      ),
    );
  }

  // User Login (Username/Password & Google)
  Widget _buildUserLogin() {
    return Form(
      key: _userFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.lightPrimary, AppColors.lightSecondary],
              ),
              borderRadius: BorderRadius.circular(20),
              shape: BoxShape.rectangle,
            ),
            child: const Icon(
              Icons.person,
              size: 50,
              color: Colors.white,
            ),
          ),
          
          const SizedBox(height: 30),
          
          Text(
            'Welcome Back!',
            style: Theme.of(context).textTheme.displaySmall,
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 10),
          
          const Text(
            'Log in to access your account',
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 40),
          
          // --- Username or Email & Password Section ---
          TextFormField(
            controller: _userUsernameController,
            decoration: const InputDecoration(
              labelText: 'Username or Email',
              hintText: 'Enter username or email',
              prefixIcon: Icon(Icons.person_outline),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your username or email';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 20),
          
          TextFormField(
            controller: _userPasswordController,
            obscureText: _obscureUserPassword,
            decoration: InputDecoration(
              labelText: 'Password',
              hintText: 'Enter your password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureUserPassword ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () {
                  setState(() {
                    _obscureUserPassword = !_obscureUserPassword;
                  });
                },
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter password';
              }
              if (value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 30),
          
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              return SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: authProvider.isLoading ? null : _handleUserUsernameLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.lightPrimary,
                  ),
                  child: authProvider.isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Login',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              );
            },
          ),
          
          const SizedBox(height: 30),
          
          // // --- OR Divider ---
          // Row(
          //   children: [
          //     Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
          //     Padding(
          //       padding: const EdgeInsets.symmetric(horizontal: 16),
          //       child: Text(
          //         'OR',
          //         style: TextStyle(
          //           color: Colors.grey.shade500,
          //           fontWeight: FontWeight.w600,
          //         ),
          //       ),
          //     ),
          //     Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
          //   ],
          // ),
          
          // const SizedBox(height: 30),
          
          // // --- Google Sign-In Section ---
          // Consumer<AuthProvider>(
          //   builder: (context, authProvider, child) {
          //     return SizedBox(
          //       height: 56,
          //       child: ElevatedButton(
          //         onPressed: authProvider.isLoading ? null : _handleGoogleSignIn,
          //         style: ElevatedButton.styleFrom(
          //           backgroundColor: Colors.white,
          //           foregroundColor: Colors.black87,
          //           elevation: 2,
          //           shape: RoundedRectangleBorder(
          //             borderRadius: BorderRadius.circular(12),
          //             side: BorderSide(color: Colors.grey.shade300),
          //           ),
          //         ),
          //         child: Row(
          //           mainAxisAlignment: MainAxisAlignment.center,
          //           children: [
          //             Container(
          //               width: 24,
          //               height: 24,
          //               decoration: BoxDecoration(
          //                 color: Colors.white,
          //                 borderRadius: BorderRadius.circular(2),
          //               ),
          //               child: const Center(
          //                 child: Text(
          //                   'G',
          //                   style: TextStyle(
          //                     fontSize: 18,
          //                     fontWeight: FontWeight.bold,
          //                     color: Color(0xFF4285F4),
          //                   ),
          //                 ),
          //               ),
          //             ),
          //             const SizedBox(width: 12),
          //             const Text(
          //               'Sign in with Google',
          //               style: TextStyle(
          //                 fontSize: 16,
          //                 fontWeight: FontWeight.w600,
          //               ),
          //             ),
          //           ],
          //         ),
          //       ),
          //     );
          //   },
          // ),
        ],
      ),
    );
  }

  // Admin Login (Email/Password)
  Widget _buildAdminLogin() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 40),
          
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFFEC4899)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.admin_panel_settings,
              size: 50,
              color: Colors.white,
            ),
          ),
          
          const SizedBox(height: 40),
          
          Text(
            'Admin Login',
            style: Theme.of(context).textTheme.displaySmall,
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 10),
          
          const Text(
            'Sign in with your admin credentials',
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 40),
          
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'Enter admin email',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter email';
              }
              if (!value.contains('@')) {
                return 'Please enter valid email';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 20),
          
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Password',
              hintText: 'Enter password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter password';
              }
              if (value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 30),
          
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              return SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: authProvider.isLoading ? null : _handleAdminLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                  ),
                  child: authProvider.isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Login as Admin',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              );
            },
          ),
          
          const SizedBox(height: 30),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF7C3AED).withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.admin_panel_settings,
                  color: Color(0xFF7C3AED),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Admin accounts must be created manually in Firebase Console',
                    style: TextStyle(
                      color: const Color(0xFF7C3AED).withOpacity(0.9),
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}