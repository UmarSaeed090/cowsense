import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/auth_provider.dart';
import 'package:image_picker/image_picker.dart';
import '../screens/profile_details_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _profileAnimation;
  late Animation<double> _menuAnimation;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _profileAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _menuAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        // TODO: Implement image upload to Firebase Storage
        // For now, just show a snackbar
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Image upload functionality coming soon!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final userProfile = authProvider.userProfile;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Profile Header
          SliverToBoxAdapter(
            child: AnimatedBuilder(
              animation: _profileAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _profileAnimation.value,
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - _profileAnimation.value)),
                    child: child,
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 30, 20, 20),
                child: Column(
                  children: [
                    // Profile Image with red border
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFFCB2213),
                              Colors.red.shade600
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFCB2213).withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: CircleAvatar(
                            backgroundColor: Colors.white,
                            child: ClipOval(
                              child: userProfile?.photoUrl != null
                                  ? CachedNetworkImage(
                                      imageUrl: userProfile!.photoUrl!,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                      errorWidget:
                                          (context, error, stackTrace) {
                                        return const Icon(Icons.person,
                                            size: 40, color: Colors.grey);
                                      },
                                    )
                                  : const Icon(Icons.person,
                                      size: 40, color: Colors.grey),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Username with subtle shadow
                    Text(
                      userProfile?.displayName ?? user?.displayName ?? 'User',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                        shadows: [
                          Shadow(
                            blurRadius: 3,
                            color: Colors.black.withOpacity(0.1),
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Email with subtle container
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.email_outlined,
                              size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 8),
                          Text(
                            user?.email ?? 'No email',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Profile Options
          SliverToBoxAdapter(
            child: AnimatedBuilder(
              animation: _menuAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _menuAnimation.value,
                  child: Transform.translate(
                    offset: Offset(0, 30 * (1 - _menuAnimation.value)),
                    child: child,
                  ),
                );
              },
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Option cards
                    _buildOptionCard(
                      iconData: Icons.lock_outlined,
                      title: 'Change Password',
                      subtitle: 'Update your password',
                      onTap: () {
                        Navigator.pushNamed(context, '/change_password');
                      },
                    ),
                    _buildOptionCard(
                      iconData: Icons.person_outlined,
                      title: 'Personal Details',
                      subtitle: 'View and edit your information',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ProfileDetailsScreen(),
                          ),
                        );
                      },
                    ),
                    _buildOptionCard(
                      iconData: Icons.description_outlined,
                      title: 'Term & Conditions',
                      subtitle: 'Read our terms and conditions',
                      onTap: () {
                        // TODO: Implement terms and conditions
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                                  Text('Terms and conditions coming soon!')),
                        );
                      },
                    ),
                    _buildOptionCard(
                      iconData: Icons.headset_mic_outlined,
                      title: 'Customer Support',
                      subtitle: 'Get help from our support team',
                      onTap: () {
                        // TODO: Implement customer support
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Customer support coming soon!')),
                        );
                      },
                    ),
                    _buildOptionCard(
                      iconData: Icons.rate_review_outlined,
                      title: 'Give Feedback',
                      subtitle: 'Share your thoughts with us',
                      onTap: () {
                        // TODO: Implement feedback
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                                  Text('Feedback functionality coming soon!')),
                        );
                      },
                    ),

                    const SizedBox(height: 30),

                    // Logout and Delete buttons
                    _buildActionButton(
                      title: 'Log Out',
                      iconData: Icons.logout,
                      isPrimary: true,
                      onTap: () => _showLogoutDialog(context),
                    ),
                    const SizedBox(height: 16),
                    _buildActionButton(
                      title: 'Delete Account',
                      iconData: Icons.delete_outline,
                      isPrimary: false,
                      onTap: () => _showDeleteDialog(context),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard({
    required IconData iconData,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon container with gradient
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFFCB2213).withOpacity(0.1),
                        Color(0xFFCB2213).withOpacity(0.2)
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    iconData,
                    color: Color(0xFFCB2213),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),

                // Text content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),

                // Arrow indicator
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.grey[500],
                    size: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String title,
    required IconData iconData,
    required bool isPrimary,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(iconData),
        label: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? Color(0xFFCB2213) : Colors.white,
          foregroundColor: isPrimary ? Colors.white : Colors.grey[800],
          elevation: isPrimary ? 4 : 0,
          shadowColor: isPrimary
              ? Color(0xFFCB2213).withOpacity(0.4)
              : Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isPrimary ? Colors.transparent : Colors.grey[300]!,
              width: 1,
            ),
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _buildCustomDialog(
        context: context,
        title: 'Log Out',
        content: 'Are you sure you want to log out of your account?',
        iconData: Icons.logout,
        confirmText: 'Log Out',
        onConfirm: () async {
          Navigator.pop(context);
          try {
            await Provider.of<AuthProvider>(context, listen: false).signOut();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Logged out successfully')),
              );
            }
            Navigator.of(context).pushReplacementNamed('/auth');
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error logging out: $e')),
              );
            }
          }
        },
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _buildCustomDialog(
        context: context,
        title: 'Delete Account',
        content:
            'This will permanently delete your account and all associated data. This action cannot be undone.',
        iconData: Icons.delete_forever,
        confirmText: 'Delete',
        onConfirm: () async {
          Navigator.pop(context);
          try {
            await Provider.of<AuthProvider>(context, listen: false)
                .user
                ?.delete();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Account deleted successfully')),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error deleting account: $e')),
              );
            }
          }
        },
      ),
    );
  }

  Widget _buildCustomDialog({
    required BuildContext context,
    required String title,
    required String content,
    required IconData iconData,
    required String confirmText,
    required VoidCallback onConfirm,
  }) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon header
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Color(0xFFCB2213).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                iconData,
                size: 36,
                color: Color(0xFFCB2213),
              ),
            ),
            const SizedBox(height: 24),

            // Title
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Content
            Text(
              content,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 24),

            // Buttons
            Row(
              children: [
                // Cancel button
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[700],
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Confirm button
                Expanded(
                  child: ElevatedButton(
                    onPressed: onConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFCB2213),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      confirmText,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
