import 'dart:io';
import 'package:flutter/material.dart';
import 'package:veteran/chat/chat_list_screen.dart';
import '../chatBot/Chat.dart';
import '../home/HomeScreen.dart';
import '../predictions/PredictionListPage.dart';
import '../userCredential/VeteranProfileModel.dart';
import '../reports/SharedHealthReport.dart';
import '../services/VeteranProfileService.dart';

class Navigation extends StatefulWidget {
  const Navigation({super.key});

  @override
  State<Navigation> createState() => _NavigationState();
}

class _NavigationState extends State<Navigation> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    HomeScreen(), // Home Dashboard Page
    const SharedHealthReportsScreen(),
    PredictionListPage(),
    ChatListScreen(),
  ];

  Future<VeteranProfile?> _loadProfile() async {
    return await VeteranProfileService.fetchProfile();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;

    return Scaffold(
      appBar: _selectedIndex == 0 // Check if we are on the home page
          ? AppBar(
              title: Text('Veterinarian AI Dashboard',
                  style: TextStyle(fontSize: 18)),
              elevation: 0,
              actions: [
                FutureBuilder<VeteranProfile?>(
                  future: _loadProfile(), // Call the method to load profile
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: CircleAvatar(
                          radius: 18,
                          child:
                              CircularProgressIndicator(), // Show loading indicator
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: CircleAvatar(
                          radius: 18,
                          backgroundImage: const AssetImage('assets/avatar.jpg')
                              as ImageProvider,
                        ),
                      );
                    }

                    final profile = snapshot.data;
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: GestureDetector(
                        onTap: () {
                          // Navigate to the profile screen when tapped
                          Navigator.pushNamed(context, '/profile');
                        },
                        child: CircleAvatar(
                          radius: 18,
                          backgroundImage: profile?.avatar != null &&
                                  profile!.avatar!.isNotEmpty
                              ? FileImage(File(profile.avatar!))
                              : const AssetImage('assets/avatar.jpg')
                                  as ImageProvider,
                        ),
                      ),
                    );
                  },
                ),
              ],
            )
          : null, // Set to null when not on the home page
      body: _screens[
          _selectedIndex], // Use _selectedIndex to show the correct screen
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: color.primary,
        unselectedItemColor: color.onSurface.withOpacity(0.6),
        showUnselectedLabels: true,
        onTap: (index) {
          setState(() {
            _selectedIndex = index; // Update the selected index on tap
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Cases'),
          BottomNavigationBarItem(
              icon: Icon(Icons.checklist), label: 'Reviews'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
        ],
      ),
    );
  }
}
