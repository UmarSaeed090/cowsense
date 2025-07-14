import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SharedHealthReportsScreen extends StatefulWidget {
  const SharedHealthReportsScreen({Key? key}) : super(key: key);

  @override
  State<SharedHealthReportsScreen> createState() => _SharedHealthReportsScreenState();
}

class _SharedHealthReportsScreenState extends State<SharedHealthReportsScreen> {
  String _searchQuery = '';
  String _selectedFilter = 'All'; // To store the selected filter value

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;

    final statusColors = {
      'New': Colors.blue.shade600,
      'Viewed': Colors.orange.shade400,
      'Action Taken': Colors.green.shade600,
    };
    final statusTextColor = {
      'New': Colors.white,
      'Viewed': Colors.black,
      'Action Taken': Colors.white,
    };

    final padding = screenWidth < 400 ? 12.0 : 16.0;
    final cardFontSize = screenWidth < 350 ? 12.5 : 14.0;
    final spacing = screenWidth < 350 ? 6.0 : 8.0;

    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Shared Health Reports')),
      body: uid == null
          ? const Center(child: Text('Not logged in'))
          : StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc('veteran')
            .collection(uid)
            .doc('reports')
            .collection('sharedhealthreports')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text('Error loading reports.'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          // Filter documents based on the search query and selected filter
          final documents = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final animalName = data['animalName']?.toLowerCase() ?? '';
            final status = data['status'] ?? '';
            bool matchesSearchQuery = animalName.contains(_searchQuery.toLowerCase());
            bool matchesFilter = _selectedFilter == 'All' || status == _selectedFilter;
            return matchesSearchQuery && matchesFilter;
          }).toList();

          return SingleChildScrollView(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Review Farmer Reports',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                SizedBox(height: spacing),
                Text(
                  'Access and review health reports shared by farmers.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark ? Colors.grey[400] : Colors.grey[700],
                    fontSize: cardFontSize,
                  ),
                ),
                SizedBox(height: spacing * 2),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: (value) => setState(() => _searchQuery = value),
                        decoration: InputDecoration(
                          hintText: 'Search reports...',
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: isDark ? Colors.grey[800] : Colors.grey[200],
                          contentPadding: EdgeInsets.symmetric(horizontal: padding),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    GestureDetector(
                      onTap: () async {
                        // Show filter options when clicked
                        final selectedFilter = await showDialog<String>(
                          context: context,
                          builder: (BuildContext context) {
                            return SimpleDialog(
                              title: Text('Select Report Status'),
                              children: ['All', 'New', 'Viewed', 'Action Taken'].map((status) {
                                return SimpleDialogOption(
                                  onPressed: () {
                                    Navigator.pop(context, status);
                                  },
                                  child: Text(status),
                                );
                              }).toList(),
                            );
                          },
                        );
                        if (selectedFilter != null) {
                          setState(() {
                            _selectedFilter = selectedFilter;
                          });
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: padding, vertical: 12.0),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[800] : Colors.grey[200],
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.filter_list, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                            const SizedBox(width: 4.0),
                            Text(_selectedFilter,
                                style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600])),
                            const SizedBox(width: 4.0),
                            Icon(Icons.arrow_drop_down, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16.0),
                ListView.separated(
                  itemCount: documents.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  separatorBuilder: (context, index) => const SizedBox(height: 12.0),
                  itemBuilder: (context, index) {
                    final report = documents[index].data() as Map<String, dynamic>;
                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                      color: Theme.of(context).cardColor,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${report['animalName']} (${report['animalId']})',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: spacing),
                            Wrap(
                              spacing: 12,
                              runSpacing: spacing,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.description_outlined, size: 18),
                                    const SizedBox(width: 6),
                                    Text(report['reportType'],
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(fontSize: cardFontSize)),
                                  ],
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.calendar_today_outlined, size: 18),
                                    const SizedBox(width: 6),
                                    Text(report['dateShared'],
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(fontSize: cardFontSize)),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: statusColors[report['status']],
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                                  child: Text(
                                    report['status'],
                                    style: TextStyle(
                                      color: statusTextColor[report['status']],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: () {
                                    Navigator.pushNamed(
                                      context,
                                      '/prediction-review',
                                      arguments: report, // Pass the selected report map as arguments
                                    );
                                  },
                                  icon: Icon(Icons.visibility, color: isDark ? Colors.white : Colors.black),
                                  label: Text(
                                    'View',
                                    style: TextStyle(color: isDark ? Colors.white : Colors.black),
                                  ),
                                  style: TextButton.styleFrom(
                                    backgroundColor: isDark ? Colors.grey[700] : Colors.grey[300],
                                    padding: EdgeInsets.symmetric(
                                      horizontal: screenWidth < 360 ? 10 : 16,
                                      vertical: 8.0,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
