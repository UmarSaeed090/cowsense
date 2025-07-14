import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isSignIn = true;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFF4B2B), Color(0xFF007AFF)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'CowSense',
                      style: GoogleFonts.sora(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      width: 370,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: isSignIn
                          ? _SignInForm(
                              onToggle: () => setState(() => isSignIn = false))
                          : _SignUpForm(
                              onToggle: () => setState(() => isSignIn = true)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SignInForm extends StatefulWidget {
  final VoidCallback onToggle;
  const _SignInForm({required this.onToggle});
  @override
  State<_SignInForm> createState() => _SignInFormState();
}

class _SignInFormState extends State<_SignInForm> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _showPassword = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Welcome Back',
          style: GoogleFonts.sora(fontSize: 26, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          "Let's get started by filling out the form below.",
          style: GoogleFonts.inter(fontSize: 15, color: Colors.black54),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            hintText: 'Email',
            filled: true,
            fillColor: const Color(0xFFF5F6FA),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _passwordController,
          obscureText: !_showPassword,
          decoration: InputDecoration(
            hintText: 'Password',
            filled: true,
            fillColor: const Color(0xFFF5F6FA),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: BorderSide.none,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                  _showPassword ? Icons.visibility : Icons.visibility_off,
                  color: Colors.grey),
              onPressed: () => setState(() => _showPassword = !_showPassword),
            ),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!, style: const TextStyle(color: Color(0xFFCB2213))),
        ],
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF4B2B),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24)),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: auth.isLoading
                ? null
                : () async {
                    setState(() => _error = null);
                    final email = _emailController.text.trim();
                    final password = _passwordController.text.trim();

                    // Validate email format
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                        .hasMatch(email)) {
                      setState(
                          () => _error = 'Please enter a valid email address');
                      return;
                    }
                    try {
                      await auth.signIn(email, password);
                      // Don't need navigation here as AppRouter will handle it automatically
                      // when auth state changes
                    } catch (e) {
                      if (mounted) {
                        setState(() => _error = e.toString());
                      }
                    }
                  },
            child: auth.isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : Text('Log In',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color:
                            Theme.of(context).colorScheme.onPrimaryContainer)),
          ),
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.center,
          child: TextButton(
            onPressed: () {
              Navigator.of(context).pushNamed('/forget-password');
            },
            child: const Text('Forgot Password ?',
                style: TextStyle(
                    color: Color(0xFF007AFF), fontWeight: FontWeight.w500)),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: const [
            Expanded(child: Divider()),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: Text('Or sign up with',
                  style: TextStyle(color: Colors.black54)),
            ),
            Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: Image.asset('assets/images/google_logo.png',
                width: 24, height: 24),
            label: const Text('Continue with Google',
                style: TextStyle(fontWeight: FontWeight.w600)),
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white,
              side: const BorderSide(color: Color(0xFFE0E0E0)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: auth.isLoading
                ? null
                : () async {
                    setState(() => _error = null);
                    try {
                      await auth.signInWithGoogle();
                      if (mounted) {
                        Navigator.of(context).pushNamed('/home');
                      }
                    } catch (e) {
                      if (mounted) {
                        setState(() => _error = e.toString());
                      }
                    }
                  },
          ),
        ),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Don't have an account? ",
                style: TextStyle(color: Colors.black54)),
            GestureDetector(
              onTap: widget.onToggle,
              child: const Text('Sign Up here',
                  style: TextStyle(
                      color: Color(0xFFFF4B2B), fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ],
    );
  }
}

class _SignUpForm extends StatefulWidget {
  final VoidCallback onToggle;
  const _SignUpForm({required this.onToggle});
  @override
  State<_SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends State<_SignUpForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _showPassword = false;
  String? _error;
  Future<void> _signUpWithGoogle(AuthProvider auth) async {
    setState(() => _error = null);
    try {
      await auth.signInWithGoogle();
      if (mounted) {
        Navigator.of(context).pushNamed('/home');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Get Started',
            style: GoogleFonts.sora(fontSize: 26, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Create a new account',
            style: GoogleFonts.inter(fontSize: 15, color: Colors.black54),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _nameController,
            validator: (value) =>
                value == null || value.isEmpty ? 'Name is required' : null,
            decoration: InputDecoration(
              hintText: 'Name',
              filled: true,
              fillColor: const Color(0xFFF5F6FA),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Email is required';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                  .hasMatch(value)) {
                return 'Please enter a valid email address';
              }
              return null;
            },
            decoration: InputDecoration(
              hintText: 'Email',
              filled: true,
              fillColor: const Color(0xFFF5F6FA),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            obscureText: !_showPassword,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Password is required';
              }
              if (value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              if (!RegExp(r'\d').hasMatch(value)) {
                return 'Password must contain at least one digit';
              }
              if (!RegExp(r'[!@#\$%\^&*(),.?":{}|<>]').hasMatch(value)) {
                return 'Password must contain at least one special character';
              }
              return null;
            },
            decoration: InputDecoration(
              hintText: 'Password',
              filled: true,
              fillColor: const Color(0xFFF5F6FA),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _showPassword ? Icons.visibility : Icons.visibility_off,
                  color: Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    _showPassword = !_showPassword;
                  });
                },
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Color(0xFFCB2213))),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF4B2B),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: auth.isLoading
                  ? null
                  : () async {
                      if (!_formKey.currentState!.validate()) return;
                      setState(() => _error = null);
                      try {
                        await auth.signUp(
                          _emailController.text.trim(),
                          _passwordController.text.trim(),
                          _nameController.text.trim(),
                        );
                        // Don't need navigation here as AppRouter will handle it automatically
                        // when auth state changes
                      } catch (e) {
                        if (mounted) {
                          setState(() => _error = e.toString());
                        }
                      }
                    },
              child: auth.isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text('Sign Up',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context)
                              .colorScheme
                              .onPrimaryContainer)),
            ),
          ),
          const SizedBox(height: 8),
          const Row(
            children: [
              Expanded(child: Divider()),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: Text('Or sign up with',
                    style: TextStyle(color: Colors.black54)),
              ),
              Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: Image.asset('assets/images/google_logo.png',
                  width: 24, height: 24),
              label: const Text('Continue with Google',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                side: const BorderSide(color: Color(0xFFE0E0E0)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: auth.isLoading ? null : () => _signUpWithGoogle(auth),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Already have an account? ',
                  style: TextStyle(color: Colors.black54)),
              GestureDetector(
                onTap: widget.onToggle,
                child: const Text('Sign In here',
                    style: TextStyle(
                        color: Color(0xFFFF4B2B), fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
