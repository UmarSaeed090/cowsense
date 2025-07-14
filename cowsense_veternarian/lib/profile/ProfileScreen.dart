import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../userCredential/VeteranProfileLocal.dart';
import '../userCredential/VeteranProfileModel.dart';
import '../services/VeteranProfileService.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  VeteranProfile? profile;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final fetched = await VeteranProfileService.fetchProfile();
    setState(() {
      profile = fetched;
      isLoading = false;
    });
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null && profile != null) {
      // Update avatar locally in the profile object
      setState(() {
        profile = profile!.copyWith(avatar: pickedFile.path);
      });

      // Save the updated profile asynchronously in the background
      await VeteranProfileService.saveProfile(profile!);
      await VeteranProfileLocal.saveToLocal(profile!);
    }
  }

  Future<void> _editProfile() async {
    if (profile == null) return;

    final name = TextEditingController(text: profile?.name);
    final phone = TextEditingController(text: profile?.phone);
    final license = TextEditingController(text: profile?.license);

    String? _selectedCity = profile?.city; // Set the selected city to the current city in profile

    // List of cities in Pakistan (add more cities as required)
    final List<String> _cities = [
      "Islamabad",
      "Karachi",
      "Lahore",
      "Quetta",
      "Peshawar",
      "Faisalabad",
      "Rawalpindi",
      "Multan",
      "Sialkot",
      "Gujranwala",
      "Bahawalpur",
      "Sargodha",
      "Hyderabad",
      "Mardan",
      "Sukkur",
      "Gujrat",
      "Swat",
      "Mingora",
      "Kotli",
      "Mirpur",
    ];

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Profile'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: _pickAvatar, // Pick avatar when tapped
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircleAvatar(
                        radius: 48,
                        backgroundImage: profile?.avatar != null && profile!.avatar!.isNotEmpty
                            ? FileImage(File(profile!.avatar!))
                            : const AssetImage('assets/avatar.jpg') as ImageProvider,
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(8),
                        child: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _buildTextField('Name', name),
                const SizedBox(height: 12),
                _buildTextField('Phone', phone),
                const SizedBox(height: 12),
                // Dropdown for city selection
                DropdownButtonFormField<String>(
                  value: _selectedCity,
                  onChanged: (newCity) {
                    setState(() {
                      _selectedCity = newCity;
                    });
                  },
                  items: _cities.map<DropdownMenuItem<String>>((String city) {
                    return DropdownMenuItem<String>(
                      value: city,
                      child: Text(city),
                    );
                  }).toList(),
                  decoration: InputDecoration(
                    labelText: 'City of Practice',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (_selectedCity == null || _selectedCity!.isEmpty) {
                      return 'Please select a city';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                _buildTextField('License No.', license),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                // Validation
                if (!_validatePhone(phone.text)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid phone number.')),
                  );
                  return;
                }

                if (!_validateEmail(FirebaseAuth.instance.currentUser?.email ?? '')) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid email address.')),
                  );
                  return;
                }

                if (!_validateLicense(license.text)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('License number must be digits only.')),
                  );
                  return;
                }

                // Prepare the updated profile values
                final updated = profile!.copyWith(
                  name: name.text.trim(),
                  phone: phone.text.trim(),
                  city: _selectedCity ?? '', // Use the selected city
                  license: license.text.trim(),
                );

                // Save the updated profile
                await VeteranProfileService.saveProfile(updated);
                await VeteranProfileLocal.saveToLocal(updated);

                // Update the UI with the new profile
                setState(() => profile = updated);

                // Close the dialog and show a success message
                if (context.mounted) Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile updated.')),
                );
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  bool _validateLicense(String license) {
    final licenseRegExp = RegExp(r'^\d+$'); // Check if the license consists only of digits
    return licenseRegExp.hasMatch(license);
  }

  bool _validatePhone(String phone) {
    final phoneRegExp = RegExp(r'^\+?\d{11,13}$');
    return phoneRegExp.hasMatch(phone);
  }

  bool _validateEmail(String email) {
    final emailRegExp = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegExp.hasMatch(email);
  }

  Future<void> _confirmSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await FirebaseAuth.instance.signOut();
      await VeteranProfileLocal.clearLocal();

      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
    }
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: color.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              _editProfile();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              color: color.primary,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundImage: profile?.avatar != null && profile!.avatar!.isNotEmpty
                        ? FileImage(File(profile!.avatar!))
                        : const AssetImage('assets/avatar.jpg') as ImageProvider,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    profile?.name ?? 'Loading...',
                    style: theme.textTheme.titleLarge?.copyWith(color: color.onPrimary),
                  ),
                  Text(
                    'Veterinary Specialist',
                    style: theme.textTheme.bodyMedium?.copyWith(color: color.onPrimary.withOpacity(0.8)),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _profileTile(context, icon: Icons.email, title: 'Email', value: FirebaseAuth.instance.currentUser?.email ?? 'No Email'),
                  _profileTile(context, icon: Icons.phone, title: 'Phone', value: profile?.phone ?? 'No Phone'),
                  _profileTile(context, icon: Icons.location_on, title: 'Location', value: profile?.city ?? 'No City'),
                  _profileTile(context, icon: Icons.calendar_today, title: 'Joined', value: _formatDate(profile?.dob?.toIso8601String())),
                  _profileTile(
                    context,
                    icon: Icons.verified_user,
                    title: 'License Number',
                    value: profile?.license ?? 'No License',
                    trailing: Icon(
                      profile?.licenseStatus == 'verified' ? Icons.check_circle_outline : Icons.error_outline,
                      color: profile?.licenseStatus == 'verified' ? Colors.green : Colors.red,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _confirmSignOut,
                    icon: const Icon(Icons.logout),
                    label: const Text('Sign Out'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _profileTile(BuildContext context, {required IconData icon, required String title, required String value, Widget? trailing}) {
    final color = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color.onSurfaceVariant)),
                Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null) return '-';
    try {
      final date = DateTime.parse(isoDate);
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return '-';
    }
  }
}
