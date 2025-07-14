import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:veteran/services/PredictionService.dart';

import '../history/DiseaseHistory.dart';

class PredictionReviewPage extends StatefulWidget {
  const PredictionReviewPage({super.key});

  @override
  State<PredictionReviewPage> createState() => _PredictionReviewPageState();
}

class _PredictionReviewPageState extends State<PredictionReviewPage> {
  bool _isRejected = false;
  bool _isAccepted = false;

  late TextEditingController recommendationController;
  late TextEditingController rejectionReasonController;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    recommendationController = TextEditingController();
    rejectionReasonController = TextEditingController();
  }

  @override
  void dispose() {
    recommendationController.dispose();
    rejectionReasonController.dispose();
    super.dispose();
  }

  Future<void> _updateAppointmentStatus(String appointmentId, String status,
      {String? rejectionReason}) async {
    try {
      final data = {'status': status};
      if (rejectionReason != null) {
        data['rejectionReason'] = rejectionReason;
      }
      await _firestore
          .collection('appointments')
          .doc(appointmentId)
          .update(data);
    } catch (e) {
      debugPrint('Error updating status: $e');
    }
  }

  Future<void> _updateAppointmentNotes(
      String appointmentId, String notes) async {
    try {
      await _firestore
          .collection('appointments')
          .doc(appointmentId)
          .update({'notes': notes});
    } catch (e) {
      debugPrint('Error updating notes: $e');
    }
  }

  Future<void> _showRejectionReasonDialog(String appointmentId) async {
    rejectionReasonController.clear();

    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reason for Rejection'),
          content: TextField(
            controller: rejectionReasonController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Please write the reason for rejection',
              border: OutlineInputBorder(),
            ),
          ),
          actions: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop(); // close dialog, no action
                  },
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  child: const Text('Send'),
                  onPressed: () async {
                    if (rejectionReasonController.text.trim().isEmpty) {
                      // Optionally show a warning here before returning
                      return;
                    }
                    await _updateAppointmentStatus(
                      appointmentId,
                      'rejected',
                      rejectionReason: rejectionReasonController.text.trim(),
                    );
                    setState(() {
                      _isRejected = true;
                    });
                    Navigator.of(context).pop(); // close dialog
                  },
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (args == null || !args.containsKey('appointment')) {
      return const Scaffold(
        body: Center(child: Text('No prediction data provided.')),
      );
    }

    if (args['appointment'] == null || args['disease'] == null) {
      return const Scaffold(
        body: Center(child: Text('No prediction data provided.')),
      );
    }

    final Appointment appointment = args['appointment'];
    debugPrint('appointment: $appointment');
    final disease = args['disease'];

    if (appointment.status == 'accepted') {
      setState(() {
        _isAccepted = true;
      });
    } else if (appointment.status == 'rejected') {
      setState(() {
        _isRejected = true;
      });
    }

    if (_isRejected) {
      return Scaffold(
        appBar: AppBar(title: const Text('Prediction Review')),
        body: const Center(
          child: Text(
            'Appointment Rejected',
            style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Prediction Review'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ... [Your previous UI content here] ...
            Text(
              'Review AI Diagnosis',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Provide your expert opinion and recommendations based on the AI\'s findings.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${appointment.animalName}',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    if (appointment.reason != null)
                      Text(
                        'Reason: ${appointment.reason}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    const SizedBox(height: 8),
                    Text(
                        'Appointment Date: ${appointment.appointmentDate != null ? "${appointment.appointmentDate!.month}/${appointment.appointmentDate!.day}/${appointment.appointmentDate!.year} ${appointment.appointmentDate!.hour}:${appointment.appointmentDate!.minute.toString().padLeft(2, '0')}" : "N/A"}'),
                    if (appointment.rejectionReason != null)
                      Text('Rejection Reason: ${appointment.rejectionReason}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: disease != null
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.error_outline,
                                  color: Colors.red),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'AI Diagnosis Details',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text.rich(
                            TextSpan(
                              children: [
                                const TextSpan(
                                  text: 'Predicted Disease: ',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                TextSpan(text: disease.diseaseName),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Text('Confidence Score:'),
                              const SizedBox(width: 12),
                              Expanded(
                                child: LinearProgressIndicator(
                                  value: disease.confidence,
                                  color: Colors.red,
                                  backgroundColor: Colors.red.withOpacity(0.2),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${(disease.confidence * 100).toStringAsFixed(1)}%',
                                style: const TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text('Animal Tag Number: ${disease.animalTagNumber}'),
                          const SizedBox(height: 12),
                          if (disease.annotatedImageUrl.isNotEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                disease.annotatedImageUrl,
                                width: double.infinity,
                                height: 160,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.broken_image, size: 100),
                              ),
                            ),
                          const SizedBox(height: 16),

                          // Updated Row with proper constraints
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Make History button flexible so it doesn't overflow
                              Expanded(
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.history),
                                  label: const Text('History'),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            DiseaseHistoryScreen(
                                          animalId: disease
                                              .animalId, // or wherever you get the animalId
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              SizedBox(
                                width: 48,
                                height: 48,
                                child: IconButton(
                                  icon: const Icon(Icons.bar_chart,
                                      size: 32, color: Colors.blue),
                                  tooltip: 'View Health Charts',
                                  onPressed: () {
                                    Navigator.pushNamed(
                                      context,
                                      '/chartsScreen',
                                      arguments: {
                                        'animalTagNumber':
                                            disease.animalTagNumber
                                      },
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      )
                    : Center(
                        child: Text(
                          'No AI diagnosis data available for this appointment.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),

            if (!_isAccepted)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style:
                          ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: () async {
                        await _showRejectionReasonDialog(appointment.id);
                      },
                      child: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green),
                      onPressed: () async {
                        await _updateAppointmentStatus(
                            appointment.id, 'under-review');
                        setState(() {
                          _isAccepted = true;
                        });
                      },
                      child: const Text('Accept'),
                    ),
                  ),
                ],
              ),

            if (_isAccepted)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Recommendations card and text field...
                  Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.medical_services_outlined,
                                  color: Colors.green),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'Your Recommendations & Treatment Plan',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: recommendationController,
                            maxLines: 4,
                            decoration: InputDecoration(
                              hintText:
                                  'e.g. Confirm diagnosis with X test. Prescribe Y medication for Z days.',
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('Back'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            if (recommendationController.text.isEmpty) {
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Recommendation Required'),
                                  content: const Text(
                                      'Please provide your recommendation before sending.'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(ctx).pop(),
                                      child: const Text('OK'),
                                    ),
                                  ],
                                ),
                              );
                            } else {
                              await _updateAppointmentNotes(appointment.id,
                                  recommendationController.text);
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Notification Sent'),
                                  content: const Text(
                                      'Notification successfully sent to the farmer.'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(ctx).pop(),
                                      child: const Text('OK'),
                                    ),
                                  ],
                                ),
                              );
                              await _updateAppointmentStatus(
                                  appointment.id, 'completed');
                            }
                          },
                          icon: const Icon(Icons.send),
                          label: const Text('Send'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
