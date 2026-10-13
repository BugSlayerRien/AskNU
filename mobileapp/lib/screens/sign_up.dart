import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  final _studentIdCtrl = TextEditingController();
  final _departmentCtrl = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptTerms = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please accept the terms and conditions')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final user = await AuthService.instance.signUp(
        _emailCtrl.text.trim(),
        _passCtrl.text.trim(),
      );

      if (user != null) {
        // Create user document with additional fields
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'email': user.email,
          'firstName': _firstNameCtrl.text.trim(),
          'lastName': _lastNameCtrl.text.trim(),
          'fullName': '${_firstNameCtrl.text.trim()} ${_lastNameCtrl.text.trim()}',
          'studentId': _studentIdCtrl.text.trim(),
          'department': _departmentCtrl.text.trim(),
          'role': 'user',
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
          'notifications': true,
          'questionsAsked': 0,
          'faqsViewed': 0,
        });

        if (!mounted) return;
        
        // Show welcome message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Welcome to AskNU, ${_firstNameCtrl.text.trim()}!'),
            duration: const Duration(seconds: 3),
          ),
        );

      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String message = 'Sign up failed';
      if (e.code == 'email-already-in-use') {
        message = 'Email is already registered';
      } else if (e.code == 'weak-password') {
        message = 'Password is too weak';
      } else if (e.code == 'invalid-email') {
        message = 'Invalid email address';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$message: ${e.message}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign up failed: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    _studentIdCtrl.dispose();
    _departmentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
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
                  child: Image(
                    image: const AssetImage('assets/logo.png'),
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
                  'Join AskNU',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Create your account to get started',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),

                // Registration Form
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
                          // Personal Information Section
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Personal Information',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: 12),

                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _firstNameCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'First Name',
                                    prefixIcon: Icon(Icons.person_outline),
                                  ),
                                  validator: (v) => v == null || v.isEmpty
                                      ? 'First name is required'
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _lastNameCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'Last Name',
                                  ),
                                  validator: (v) => v == null || v.isEmpty
                                      ? 'Last name is required'
                                      : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Academic Information Section
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Academic Information',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: 12),

                          TextFormField(
                            controller: _studentIdCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Student ID',
                              prefixIcon: Icon(Icons.badge_outlined),
                            ),
                            validator: (v) => v == null || v.isEmpty
                                ? 'Student ID is required'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _departmentCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Department',
                              prefixIcon: Icon(Icons.school_outlined),
                            ),
                            validator: (v) => v == null || v.isEmpty
                                ? 'Department is required'
                                : null,
                          ),
                          const SizedBox(height: 16),

                          // Account Information Section
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Account Information',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: 12),

                          TextFormField(
                            controller: _emailCtrl,
                            decoration: const InputDecoration(
                              labelText: 'University Email',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Email is required';
                              if (!v.contains('@') || !v.contains('.')) {
                                return 'Enter a valid email';
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
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _confirmPassCtrl,
                            decoration: InputDecoration(
                              labelText: 'Confirm Password',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed: () {
                                  setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                                },
                              ),
                            ),
                            obscureText: _obscureConfirmPassword,
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Please confirm password';
                              if (v != _passCtrl.text) return 'Passwords do not match';
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          // Terms and Conditions
                          Row(
                            children: [
                              Checkbox(
                                value: _acceptTerms,
                                onChanged: (value) {
                                  setState(() => _acceptTerms = value ?? false);
                                },
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    // Show terms and conditions
                                    showDialog(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Terms and Conditions'),
                                        content: SingleChildScrollView(
                                          child: Text(
                                            'By creating an account, you agree to:\n\n'
                                            '1. Use AskNU for academic purposes only\n'
                                            '2. Respect other users and maintain a professional environment\n'
                                            '3. Not share your account credentials\n'
                                            '4. Follow university policies and guidelines\n\n'
                                            'Your data will be protected according to our privacy policy.',
                                          ),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.of(ctx).pop(),
                                            child: const Text('Close'),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  child: const Text(
                                    'I agree to the terms and conditions',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Sign Up Button
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
                                      'Create Account',
                                      style: TextStyle(fontSize: 16),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Sign In Link
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Already have an account?'),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/sign-in'),
                      child: const Text('Sign In'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}