import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _loading = true);
    
    try {
      if (kDebugMode) {
        debugPrint('DEBUG: Starting sign in process...');
      }
      
      final user = await AuthService.instance.signIn(
        _emailCtrl.text.trim(), 
        _passCtrl.text.trim()
      );
      
      if (!mounted) return;
      
      if (user != null) {
        if (kDebugMode) {
          debugPrint('DEBUG: Sign in successful for: ${user.email}');
        }
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Signed in successfully!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      
      String message = 'Sign in failed';
      
      switch (e.code) {
        case 'user-not-found':
          message = 'No account found with this email';
          break;
        case 'wrong-password':
          message = 'Incorrect password';
          break;
        case 'invalid-email':
          message = 'Invalid email address';
          break;
        case 'user-disabled':
          message = 'This account has been disabled';
          break;
        case 'too-many-requests':
          message = 'Too many attempts. Try again later';
          break;
        case 'network-request-failed':
          message = 'Network error. Check your internet connection';
          break;
        case 'operation-not-allowed':
          message = 'Email/password sign in is not enabled';
          break;
        default:
          message = 'Sign in failed: ${e.message}';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
      
      if (kDebugMode) {
        debugPrint('DEBUG: FirebaseAuthException: ${e.code} - ${e.message}');
      }
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
      
      if (kDebugMode) {
        debugPrint('DEBUG: General error: $e');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _loading = true);
    
    try {
      final user = await AuthService.instance.signInWithGoogle();
      
      if (!mounted) return;
      
      if (user != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Signed in with Google successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Google sign in cancelled'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Google sign in failed: ${e.message ?? e.code}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Google sign in failed: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _navigateToSignUp() {
    Navigator.pushNamed(context, '/sign-up');
  }

  void _navigateToForgotPassword() {
    Navigator.pushNamed(context, '/forgot-password');
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign In'),
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              )
            : null,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              children: [
                // Logo and App Name
                const SizedBox(height: 20),
                Hero(
                  tag: 'app-logo',
                  child: Image.asset(
                    'assets/logo.png',
                    width: 80,
                    height: 80,
                    errorBuilder: (c, e, s) => CircleAvatar(
                      radius: 36,
                      backgroundColor: Theme.of(context).primaryColor,
                      child: const Icon(Icons.school, size: 40, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Welcome',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Sign in to your AskNU account',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),

                // Sign In Form
                Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextFormField(
                            controller: _emailCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Email is required';
                              if (!v.contains('@') || !v.contains('.')) {
                                return 'Enter a valid email address';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passCtrl,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed: () {
                                  setState(() => _obscurePassword = !_obscurePassword);
                                },
                              ),
                            ),
                            obscureText: _obscurePassword,
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Password is required';
                              if (v.length < 6) return 'Password must be at least 6 characters';
                              return null;
                            },
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _navigateToForgotPassword,
                              child: const Text('Forgot Password?'),
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _loading ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: _loading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(),
                                    )
                                  : const Text(
                                      'Sign In',
                                      style: TextStyle(fontSize: 16),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Row(
                            children: [
                              Expanded(child: Divider()),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                child: Text('OR'),
                              ),
                              Expanded(child: Divider()),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _loading ? null : _signInWithGoogle,
                              icon: Image.asset(
                                'assets/google_icon.png',
                                width: 20,
                                height: 20,
                                errorBuilder: (c, e, s) => const Icon(Icons.g_mobiledata),
                              ),
                              label: const Text('Continue with Google'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Sign Up Link
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account?"),
                    TextButton(
                      onPressed: _navigateToSignUp,
                      child: const Text('Create Account'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Debug info (visible only in debug mode)
                if (const bool.fromEnvironment('dart.vm.product') == false)
                  Card(
                    color: Colors.grey[100],
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          const Text(
                            'Debug Info',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          FutureBuilder<User?>(
                            future: Future.value(AuthService.instance.currentUser),
                            builder: (context, snapshot) {
                              return Text(
                                'Current User: ${snapshot.data?.email ?? "None"}',
                                style: const TextStyle(fontSize: 10),
                              );
                            },
                          ),
                        ],
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