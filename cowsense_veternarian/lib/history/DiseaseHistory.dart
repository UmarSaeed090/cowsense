import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../services/PredictionService.dart';

class DiseaseHistoryScreen extends StatefulWidget {
  final String animalId;

  const DiseaseHistoryScreen({Key? key, required this.animalId}) : super(key: key);

  @override
  State<DiseaseHistoryScreen> createState() => _DiseaseHistoryScreenState();
}

class _DiseaseHistoryScreenState extends State<DiseaseHistoryScreen> {
  List<DiseaseDetection> diseaseHistory = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadDiseaseHistory();
  }

  Future<void> _loadDiseaseHistory() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      // Replace with your own fetch method
      // diseaseHistory = await getDiseaseHistory(widget.animalId);

      // Example stub:
      await Future.delayed(const Duration(seconds: 1));
      diseaseHistory = []; // Replace with actual fetched data

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> _showDeleteConfirmation(DiseaseDetection detection) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Disease Record'),
        content: const Text(
          'Are you sure you want to delete this disease detection record? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        // Replace with your delete method
        // await ApiService.deleteDiseaseDetection(detection.id!, detection.annotatedImageUrl);

        // For demo, remove from list locally
        setState(() {
          diseaseHistory.removeWhere((d) => d.id == detection.id);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Disease record deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete disease record: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildConfidenceChip(double confidence) {
    Color chipColor;
    if (confidence >= 0.8) {
      chipColor = Colors.red;
    } else if (confidence >= 0.5) {
      chipColor = Colors.orange;
    } else {
      chipColor = Colors.yellow[800]!;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: chipColor.withOpacity(0.3)),
      ),
      child: Text(
        '${(confidence * 100).toStringAsFixed(1)}%',
        style: TextStyle(
          color: chipColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDiseaseCard(DiseaseDetection detection) {
    final dateFormat = DateFormat('MMM dd, yyyy - hh:mm a');
    final formattedDate = detection.detectedAt != null
        ? dateFormat.format(detection.detectedAt!)
        : 'Unknown date';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image section
          if (detection.annotatedImageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: CachedNetworkImage(
                imageUrl: detection.annotatedImageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[200],
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[200],
                  child: const Center(child: Icon(Icons.error, color: Colors.red)),
                ),
              ),
            ),

          // Content section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        detection.diseaseName,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    _buildConfidenceChip(detection.confidence),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  formattedDate,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _showDeleteConfirmation(detection),
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      label: const Text(
                        'Delete',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Disease History'),
        elevation: 2,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.brightness == Brightness.dark ? Colors.grey[900]! : Colors.blue[50]!,
              theme.brightness == Brightness.dark ? Colors.grey[800]! : Colors.white,
            ],
          ),
        ),
        child: Builder(
          builder: (context) {
            if (isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (error != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading disease history',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error!,
                      style: theme.textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }
            if (diseaseHistory.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.medical_services_outlined, size: 80, color: Colors.grey.withOpacity(0.5)),
                    const SizedBox(height: 24),
                    Text('No Disease History', style: theme.textTheme.headlineSmall),
                    const SizedBox(height: 16),
                    Text(
                      'No diseases have been detected for this animal yet.',
                      style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: diseaseHistory.length,
              itemBuilder: (context, index) => _buildDiseaseCard(diseaseHistory[index]),
            );
          },
        ),
      ),
    );
  }
}
