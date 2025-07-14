import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/appointment.dart';
import '../screens/chat_screen.dart';
import '../providers/chat_provider.dart';
import '../providers/veterinarian_provider.dart';
import 'package:provider/provider.dart';

class AppointmentDetailsScreen extends StatelessWidget {
  final Appointment appointment;

  const AppointmentDetailsScreen({
    Key? key,
    required this.appointment,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointment Details'),
        elevation: 2,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: appointment.status == AppointmentStatus.pending
                      ? const Text('Cancel Appointment')
                      : const Text('Delete Appointment'),
                  content: appointment.status == AppointmentStatus.pending
                      ? const Text(
                          'Are you sure you want to cancel this appointment? This action cannot be undone.')
                      : const Text(
                          'Are you sure you want to delete this appointment? This action cannot be undone.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: TextButton.styleFrom(
                        foregroundColor: Color(0xFFCB2213),
                      ),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );

              if (confirmed == true && context.mounted) {
                try {
                  Provider.of<VeterinarianProvider>(context, listen: false)
                      .deleteAppointment(
                    appointment.id!,
                    appointment.veterinarianId,
                    appointment.animalId,
                  );

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Appointment deleted successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    Navigator.pop(context);
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to delete appointment: $e'),
                        backgroundColor: Color(0xFFCB2213),
                      ),
                    );
                  }
                }
              }
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[900]!
                  : Colors.blue[50]!,
              Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[800]!
                  : Colors.white,
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatusCard(context),
              const SizedBox(height: 24),
              _buildInfoSection(
                context,
                'Animal Information',
                [
                  _buildInfoRow('Name', appointment.animalName),
                ],
              ),
              const SizedBox(height: 24),
              _buildInfoSection(
                context,
                'Veterinarian Information',
                [
                  _buildInfoRow('Name', 'Dr. ${appointment.veterinarianName}'),
                  ElevatedButton(
                    onPressed: () async {
                      // INSERT_YOUR_CODE
                      final veterinarianId =
                          appointment.veterinarianId; // INSERT_YOUR_CODE
                      final chatProvider =
                          Provider.of<ChatProvider>(context, listen: false);

                      // Get or create the room ID
                      String roomId = chatProvider.chatRooms
                          .firstWhere((room) =>
                              room.participants.contains(veterinarianId))
                          .id;
                      if (roomId.isEmpty) {
                        // Create the room ID
                        roomId = await chatProvider.createRoom(
                          appointment.userId,
                          veterinarianId,
                        );
                      }
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            roomId: roomId,
                            otherUser: veterinarianId,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Contact Veterinarian'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildInfoSection(
                context,
                'Appointment Details',
                [
                  _buildInfoRow(
                    'Date',
                    DateFormat('MMMM dd, yyyy')
                        .format(appointment.appointmentDate),
                  ),
                  _buildInfoRow(
                    'Time',
                    DateFormat('hh:mm a').format(appointment.appointmentDate),
                  ),
                  _buildInfoRow('Reason', appointment.reason),
                  if (appointment.rejectionReason != null)
                    _buildInfoRow(
                        'Rejection Reason', appointment.rejectionReason!),
                ],
              ),
              const SizedBox(height: 24),
              _buildInfoSection(
                context,
                'Additional Information',
                [
                  _buildInfoRow(
                    'Created At',
                    DateFormat('MMMM dd, yyyy hh:mm a')
                        .format(appointment.createdAt),
                  ),
                ],
              ),
              if (appointment.notes != null) ...[
                const SizedBox(height: 24),
                _buildNotesSection(context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (appointment.status) {
      case AppointmentStatus.pending:
        statusColor = Colors.orange;
        statusText = 'Pending';
        statusIcon = Icons.hourglass_empty;
        break;
      case AppointmentStatus.accepted:
        statusColor = Colors.green;
        statusText = 'Accepted';
        statusIcon = Icons.check;
        break;
      case AppointmentStatus.rejected:
        statusColor = Color(0xFFCB2213);
        statusText = 'Rejected';
        statusIcon = Icons.close;
        break;
      case AppointmentStatus.completed:
        statusColor = Colors.blue;
        statusText = 'Completed';
        statusIcon = Icons.done_all;
        break;
      case AppointmentStatus.cancelled:
        statusColor = Colors.grey;
        statusText = 'Cancelled';
        statusIcon = Icons.cancel;
        break;
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              statusColor.withOpacity(0.2),
              statusColor.withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: statusColor,
              child: Icon(
                statusIcon,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Status',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    statusText,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
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

  Widget _buildInfoSection(
      BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: children,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.note, color: Colors.blue),
            const SizedBox(width: 8),
            Text(
              'Notes',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: Colors.blue.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.blue.withOpacity(0.05),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appointment.notes!,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
