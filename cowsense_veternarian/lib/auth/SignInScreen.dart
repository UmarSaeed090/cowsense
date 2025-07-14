import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../userCredential/VeteranProfileLocal.dart';
import '../services/VeteranProfileService.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _passwordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState == null || !_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save();

    setState(() => _isLoading = true);
    try {
      UserCredential cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      User? user = cred.user;
      if (user == null) {
        throw Exception("Login failed: no Firebase user.");
      }
      if (!user.emailVerified) {
        Navigator.pushReplacementNamed(context, '/emailVerification');
        return;
      }
      final profile = await VeteranProfileService.fetchProfile();
      if (!mounted) return;  // ensure widget is still mounted:contentReference[oaicite:9]{index=9}
      if (profile == null) {
        _showErrorDialog('No user found. Sign up first.');
      } else {
        await VeteranProfileLocal.saveToLocal(profile);
        Navigator.pushReplacementNamed(context, '/navigation');
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String errorMsg;
      if (e.code == 'user-not-found') {
        errorMsg = 'No user found for that email.';
      } else if (e.code == 'wrong-password') {
        errorMsg = 'Wrong password provided for that user.';
      } else {
        errorMsg = 'Login failed. ${e.message ?? 'Please try again.'}';
      }
      _showErrorDialog(errorMsg);
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog('An unexpected error occurred. ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loginWithGoogle() async {
    // Initialize GoogleSignIn instance
    final googleSignIn = GoogleSignIn();

    // Disconnect the current Google account to force account selection
    try {
      if (await googleSignIn.isSignedIn()) {
        await googleSignIn.signOut();
      }
      await googleSignIn.disconnect();
    } catch (e) {
      print("Error during sign-out: $e");
    }

    setState(() => _isLoading = true);
    try {
      // Trigger the Google Sign-In process
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        return; // Canceled by user
      }

      // Get the authentication details from Google
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Check if the access token and ID token are not null
      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        throw Exception("Google sign-in failed: Missing tokens.");
      }

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase using Google credentials
      UserCredential cred = await FirebaseAuth.instance.signInWithCredential(credential);
      User? user = cred.user;

      if (user == null) {
        throw FirebaseAuthException(code: 'no-user', message: 'User not found');
      }

      // Fetch profile from the custom service or Firestore
      final profile = await VeteranProfileService.fetchProfile();
      if (profile == null) {
        _showErrorDialog('No user found. Please sign up first.');
        return;
      }

      // Save profile locally
      await VeteranProfileLocal.saveToLocal(profile);

      // Navigate to the main screen or dashboard
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/navigation');
      }

    } on FirebaseAuthException catch (e) {
      if (mounted) {
        _showErrorDialog('Google sign-in failed. ${e.message ?? 'Please try again.'}');
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('An error occurred during Google sign-in. ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _goToForgotPassword() {
    Navigator.pushNamed(context, '/forgotPassword');
  }

  void _goToSignUp() {
    Navigator.pushReplacementNamed(context, '/signUp');
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
                                  'Welcome Back',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.sora(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Let\'s get started by filling out the form below.',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Email is required';
                                    } else if (!value.contains('@')) {
                                      return 'Enter a valid email';
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
                                    if (value == null || value.isEmpty) {
                                      return 'Password is required';
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
                                    onPressed: _isLoading ? null : _login,
                                    child: _isLoading
                                        ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                        : Text(
                                      'Log In',
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextButton(
                                  onPressed: _goToForgotPassword,
                                  style: TextButton.styleFrom(
                                    minimumSize: const Size(110, 25),
                                    tapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    'Forgot Password?',
                                    style: GoogleFonts.inter(
                                      color: const Color(0xFF00796B),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'Or sign in with',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed:
                                    _isLoading ? null : _loginWithGoogle,
                                    icon: const FaIcon(
                                        FontAwesomeIcons.google,
                                        size: 20),
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
                                  onTap: _goToSignUp,
                                  child: RichText(
                                    text: TextSpan(
                                      text: 'Don\'t have an account?  ',
                                      style: GoogleFonts.inter(
                                        color: Colors.grey[600],
                                      ),
                                      children: [
                                        TextSpan(
                                          text: 'Sign Up here',
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
