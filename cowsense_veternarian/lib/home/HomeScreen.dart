import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../notification/NotificationDetailScreen.dart';
import '../userCredential/VeteranProfileModel.dart';
import '../services/VeteranProfileService.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  VeteranProfile? profile;
  bool isLoading = true;
  int activeChatsCount = 0;
  int sharedProfilesCount = 0;
  int pendingPredictionsCount = 0;


  @override
  void initState() {
    super.initState();
    _loadProfile(); // Load profile when the screen initializes
    _fetchCounts(); // Fetch counts for chats, shared profiles, and predictions
  }

  // Method to load the profile
  Future<void> _loadProfile() async {
    final fetchedProfile = await VeteranProfileService.fetchProfile();
    if (mounted) {
      setState(() {
        profile = fetchedProfile;
        isLoading = false;
      });
    }
  }

  // Method to fetch the counts for active chats, shared profiles, and pending predictions
  Future<void> _fetchCounts() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // Fetch active chats count
    final activeChatsSnapshot = await FirebaseFirestore.instance
        .collection('chatRooms')
        .where('participants', arrayContains: uid)
        .get();

    setState(() {
      activeChatsCount = activeChatsSnapshot.size; // Get the size of the query snapshot
    });

    // Fetch shared profiles count
    final sharedProfilesSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc('veteran')
        .collection(uid)
        .doc('reports')
        .collection('sharedhealthreports')
        .get();

    setState(() {
      sharedProfilesCount = sharedProfilesSnapshot.size;
    });

    // Fetch pending predictions count
    final pendingPredictionsSnapshot = await FirebaseFirestore.instance
        .collection('appointments')
        .where('veterinarianId', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .get();

    setState(() {
      pendingPredictionsCount = pendingPredictionsSnapshot.size;
    });

  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome, Dr. ${profile?.name ?? 'Guest'}!',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/shared-health-report'),
              child: _dashboardTile(
                context, 'Shared Profiles', '$sharedProfilesCount', 'Animals shared by farmers', Icons.group,
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/prediction-list'),
              child: _dashboardTile(
                context, 'Pending Reviews', '$pendingPredictionsCount', 'Predictions needing your input', Icons.pending_actions,
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/chat'),
              child: _dashboardTile(
                context, 'Recent Chats', '$activeChatsCount', 'Active conversations', Icons.chat,
              ),
            ),
            const SizedBox(height: 24),
            _sectionTitle(context, 'Recently Shared Profiles', icon: Icons.list_alt),
            _recentlySharedProfiles(context),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/shared-health-report');
                },
                child: const Text("View All Shared Reports"),
              ),
            ),
            const SizedBox(height: 16),
            _sectionTitle(context, 'Notifications', icon: Icons.notifications),
            recentNotifications(context),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/notifications');
                },
                child: const Text("View All Notifications"),
              ),
            ),
            const SizedBox(height: 24),
            _sectionTitle(context, 'Key Actions'),
            _actionButtonsRow(context),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _recentlySharedProfiles(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Text("Not signed in.");

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc('veteran')
          .collection(uid)
          .doc('reports')
          .collection('sharedhealthreports')
          .orderBy('dateShared', descending: true)
          .limit(3)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final docs = snapshot.data?.docs;
        if (docs == null || docs.isEmpty) {
          return const Text("No shared profiles.");
        }
        return Column(
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return _sharedProfileTile(
              context,
              '${data['animalName']} (${data['animalId']})',
              data['farmer'] ?? 'Unknown',
              data['dateShared'] ?? 'Unknown',
              data['status'] ?? 'New',
              Colors.blue,
              data, // Pass the entire data to the tile
            );
          }).toList(),
        );
      },
    );
  }

  Widget recentNotifications(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Text("Not signed in.");
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: uid) // Fetch notifications for the current user only
          .orderBy('date', descending: true) // Order by date in descending order (most recent first)
          .limit(3) // Limit the notifications to 3
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final docs = snapshot.data?.docs;
        if (docs == null || docs.isEmpty) {
          return const Text("No notifications.");
        }

        return Column(
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final notificationId = doc.id;  // Get the notificationId from the document

            return _notificationTile(
              context,
              _getNotificationIcon(data['icon']), // Icon based on the notification type
              data['message'] ?? 'No message available',
              data['time'] ?? 'Unknown',
              notificationId, // Pass the notificationId to _notificationTile
              isError: data['isError'] ?? false,
            );
          }).toList(),
        );
      },
    );
  }

  IconData _getNotificationIcon(String iconName) {
    switch (iconName) {
      case 'monitor_heart':
        return Icons.monitor_heart; // Replace with correct icon
      case 'warning':
        return Icons.warning;
      case 'chat':
        return Icons.chat;
      default:
        return Icons.notifications; // Default icon if none is specified
    }
  }

  Widget _dashboardTile(
      BuildContext context, String title, String value, String subtitle, IconData icon) {
    final theme = Theme.of(context);
    final color = theme.colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: color.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(value,
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold, fontSize: 20)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(fontSize: 12),
                    softWrap: true),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Icon(icon, size: 28, color: color.primary),
        ],
      ),
    );
  }

  Widget _sharedProfileTile(
      BuildContext context,
      String name,
      String sender,
      String date,
      String status,
      Color statusColor,
      Map<String, dynamic> reportData, // Add this parameter to pass the data
      ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: GestureDetector(
        onTap: () {
          // Navigate to the /prediction-review screen with the report data
          Navigator.pushNamed(
            context,
            '/prediction-review',
            arguments: reportData, // Pass the report data to the screen
          );
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.black12.withOpacity(0.03),
          ),
          child: ListTile(
            title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text("From: $sender | Shared: $date"),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(status,
                  style: TextStyle(
                      color: statusColor, fontWeight: FontWeight.w600)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _notificationTile(BuildContext context, IconData icon, String message,
      String time, String notificationId, {bool isError = false}) {
    final color = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: GestureDetector(
        onTap: () {
          // Navigate to the NotificationDetailScreen when tapped
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NotificationDetailScreen(notificationId: notificationId),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isError ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
          ),
          child: ListTile(
            leading: Icon(icon, color: isError ? color.error : color.primary),
            title: Text(message, style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(time),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 24),
      child: Row(
        children: [
          if (icon != null) Icon(icon, size: 20),
          if (icon != null) const SizedBox(width: 8),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }

  Widget _actionButtonsRow(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _actionButton(context, Icons.folder_shared, 'View Shared Cases',
            '/shared-health-report'),
        _actionButton(
            context, Icons.analytics, 'Review Predictions', '/prediction-list'),
        _actionButton(
            context, Icons.chat_bubble, 'Communicate', '/chat'), // chat route
      ],
    );
  }

  Widget _actionButton(
      BuildContext context, IconData icon, String label, String route) {
    final color = Theme.of(context).colorScheme;
    return ElevatedButton.icon(
      onPressed: () {
        Navigator.pushNamed(context, route);
      },
      icon: Icon(icon, color: color.onPrimary),
      label: Text(label, style: TextStyle(color: color.onPrimary)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.primary,
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
