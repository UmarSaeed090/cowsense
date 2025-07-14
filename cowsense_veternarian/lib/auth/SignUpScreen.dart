import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();

  bool _passwordVisible = false;
  bool _isLoading = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  void _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      final user = userCredential.user;
      if (user != null) {
        await user.updateDisplayName(_usernameController.text.trim());
        await user.sendEmailVerification();

        await FirebaseFirestore.instance
            .collection('users')
            .doc('veteran')
            .collection(user.uid)
            .doc('profile')
            .set({
          'username': _usernameController.text.trim(),
          'email': _emailController.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
        });

        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/registration');
      }
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          _showErrorDialog('This email is already registered.');
          break;
        case 'invalid-email':
          _showErrorDialog('This email address is invalid.');
          break;
        case 'weak-password':
          _showErrorDialog('Your password is too weak.');
          break;
        default:
          _showErrorDialog(e.message ?? 'Registration failed.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _loginWithGoogle() async {
    // Check if the user is already signed in to Google and disconnect if needed
    final googleSignIn = GoogleSignIn();
    if (await googleSignIn.isSignedIn()) {
      await googleSignIn.signOut();  // Sign out from the previous session
    }

    setState(() => _isLoading = true);
    try {
      // Trigger the Google Sign-In process
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        return; // Canceled by the user
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Check if the accessToken and idToken are null before proceeding
      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        throw Exception("Google sign-in failed: Missing token.");
      }

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in with Firebase using the Google credentials
      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCredential.user;

      if (user == null) {
        throw FirebaseAuthException(code: 'no-user', message: 'User not found');
      }

      // Check if the user's profile exists in Firestore
      final profileRef = FirebaseFirestore.instance
          .collection('users')
          .doc('veteran')
          .collection(user.uid)
          .doc('profile');

      final doc = await profileRef.get();
      if (!doc.exists) {
        // Create a new profile if it doesn't exist
        await profileRef.set({
          'username': user.displayName ?? 'Unnamed User',
          'email': user.email ?? 'No Email',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (!mounted) return;
      // Navigate to the next screen after successful login
      Navigator.pushReplacementNamed(context, '/registration');
    } on FirebaseAuthException catch (e) {
      _showErrorDialog(e.message ?? 'Google sign-in failed.');
    } catch (e) {
      _showErrorDialog('An error occurred during Google sign-in: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _goToLogin() {
    Navigator.pushReplacementNamed(context, '/login');
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.textTheme.bodyMedium?.color ?? Colors.black;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Row(
          children: [
            Expanded(
              flex: 6,
              child: Container(
                height: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.primaryColor,
                      const Color(0xFF00796B),
                    ],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(top: 70),
                  child: Column(
                    children: [
                      Container(
                        width: 200,
                        height: 70,
                        alignment: Alignment.center,
                        child: Text(
                          'Veteran',
                          style: GoogleFonts.sora(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 570),
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: theme.scaffoldBackgroundColor,
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              )
                            ],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  'Get Started',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.sora(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Let\'s get started by filling out the form below',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                TextFormField(
                                  controller: _usernameController,
                                  validator: (value) =>
                                  value == null || value.isEmpty ? 'Username is required' : null,
                                  decoration: InputDecoration(
                                    labelText: 'Username',
                                  ).applyDefaults(theme.inputDecorationTheme),
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Email is required';
                                    }
                                    // Regular expression to validate email with '@' and any domain ending with a valid extension
                                    final emailRegExp = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
                                    if (!emailRegExp.hasMatch(value)) {
                                      return 'Enter a valid email (e.g., user@domain.com)';
                                    }
                                    return null;
                                  },
                                  decoration: InputDecoration(
                                    labelText: 'Email',
                                  ).applyDefaults(theme.inputDecorationTheme),
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: !_passwordVisible,
                                  validator: (value) {
                                    // Check if the password is at least 6 characters long
                                    if (value == null || value.isEmpty) {
                                      return 'Password is required';
                                    } else if (value.length < 6) {
                                      return 'Password must be at least 6 characters';
                                    }

                                    // Check if the password contains at least one digit
                                    if (!RegExp(r'\d').hasMatch(value)) {
                                      return 'Password must contain at least one digit';
                                    }

                                    // Check if the password contains at least one special character
                                    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
                                      return 'Password must contain at least one special character';
                                    }

                                    return null;
                                  },
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _passwordVisible
                                            ? Icons.visibility
                                            : Icons.visibility_off,
                                        color: isDark ? Colors.white70 : Colors.grey,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _passwordVisible = !_passwordVisible;
                                        });
                                      },
                                    ),
                                  ).applyDefaults(theme.inputDecorationTheme),
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _signUp,
                                    child: _isLoading
                                        ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                        : Text(
                                      'Create Account',
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'Or sign up with',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: _isLoading ? null : _loginWithGoogle,
                                    icon: const FaIcon(FontAwesomeIcons.google, size: 20),
                                    label: Text(
                                      'Continue with Google',
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 30),
                                GestureDetector(
                                  onTap: _goToLogin,
                                  child: RichText(
                                    text: TextSpan(
                                      text: 'Already have an account?  ',
                                      style: GoogleFonts.inter(
                                        color: Colors.grey[600],
                                      ),
                                      children: [
                                        TextSpan(
                                          text: 'Sign In here',
                                          style: GoogleFonts.inter(
                                            color: theme.primaryColor,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
