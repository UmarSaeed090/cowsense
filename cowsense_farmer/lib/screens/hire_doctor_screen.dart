import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/veterinarian.dart';
import '../models/appointment.dart';
import '../models/animal.dart';
import '../providers/veterinarian_provider.dart';
import '../screens/appointment_details_screen.dart';
import '../providers/auth_provider.dart';

class HireDoctorScreen extends StatelessWidget {
  final Animal animal;

  const HireDoctorScreen({
    Key? key,
    required this.animal,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
        title: Text('Hire a Doctor'),
        elevation: 2,
        centerTitle: true,
      ),
      body: Container(
        child: Consumer<VeterinarianProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (provider.error != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Color(0xFFCB2213),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading veterinarians',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      provider.error!,
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        provider.clearError();
                        provider.loadAnimalAppointments(animal.id!);
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            final veterinarians = provider.veterinarians;
            final appointment = provider.appointments
                .where((appointment) => appointment.animalId == animal.id)
                .firstOrNull;

            // Add sorting to show booked veterinarians first
            final sortedVets = [...veterinarians];
            sortedVets.sort((a, b) {
              final aBooked = a.appointments?.contains(animal.id) ?? false;
              final bBooked = b.appointments?.contains(animal.id) ?? false;
              if (aBooked && !bBooked) return -1;
              if (!aBooked && bBooked) return 1;
              return a.name.compareTo(b.name);
            });

            if (veterinarians.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.medical_services_outlined,
                      size: 80,
                      color: Colors.grey.withOpacity(0.5),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'No Veterinarians Available',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'There are no veterinarians available at the moment.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.grey[600],
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sortedVets.length,
              itemBuilder: (context, index) {
                final veterinarian = sortedVets[index];
                return _buildVeterinarianCard(
                    context, veterinarian, provider, appointment);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildVeterinarianCard(BuildContext context, Veterinarian veterinarian,
      VeterinarianProvider provider, Appointment? appointment) {
    final isBooked = veterinarian.appointments?.contains(animal.id) ?? false;
    final card = Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile image and basic info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile image
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: veterinarian.imageUrl != null
                      ? CachedNetworkImageProvider(veterinarian.imageUrl!)
                      : null,
                  child: veterinarian.imageUrl == null
                      ? const Icon(Icons.person, size: 40, color: Colors.grey)
                      : null,
                ),
                const SizedBox(width: 16),
                // Basic info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        veterinarian.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        veterinarian.specialization,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber, size: 20),
                          const SizedBox(width: 4),
                          Text(
                            veterinarian.rating.toStringAsFixed(1),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '(${veterinarian.totalReviews} reviews)',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Divider
          const Divider(height: 1),

          // Additional info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(
                  context,
                  Icons.work_outline,
                  'Experience',
                  veterinarian.experience,
                ),
                const SizedBox(height: 8),
                _buildInfoRow(
                  context,
                  Icons.school_outlined,
                  'Education',
                  veterinarian.education,
                ),
                if (veterinarian.languages != null &&
                    veterinarian.languages!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    context,
                    Icons.language_outlined,
                    'Languages',
                    veterinarian.languages!.join(', '),
                  ),
                ],
                if (veterinarian.bio != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    'About',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    veterinarian.bio!,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ],
            ),
          ),

          // Book appointment button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showAppointmentDialog(
                    context, veterinarian, provider, appointment),
                icon: const Icon(Icons.calendar_today),
                label: (veterinarian.appointments != null &&
                        veterinarian.appointments!.contains(animal.id))
                    ? const Text('View Appointment')
                    : const Text('Book Appointment'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    return isBooked
        ? Banner(
            message: 'Booked',
            location: BannerLocation.topEnd,
            color: Theme.of(context).colorScheme.primary,
            child: card,
          )
        : card;
  }

  Widget _buildInfoRow(
      BuildContext context, IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  Future<void> _showAppointmentDialog(
      BuildContext context,
      Veterinarian veterinarian,
      VeterinarianProvider provider,
      Appointment? appointment) async {
    // Check if animal already has an appointment with this veterinarian
    if (appointment != null &&
        veterinarian.appointments != null &&
        veterinarian.appointments!.contains(animal.id)) {
      Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AppointmentDetailsScreen(
              appointment: appointment,
            ),
          ));
      return;
    }

    final reasonController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Book Appointment'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Date and Time',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              // Date picker
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Date'),
                subtitle: Text(
                  DateFormat('MMMM dd, yyyy').format(selectedDate),
                ),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 30)),
                  );
                  if (date != null) {
                    selectedDate = date;
                    (context as Element).markNeedsBuild();
                  }
                },
              ),
              // Time picker
              ListTile(
                leading: const Icon(Icons.access_time),
                title: const Text('Time'),
                subtitle: Text(selectedTime.format(context)),
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: selectedTime,
                  );
                  if (time != null) {
                    selectedTime = time;
                    (context as Element).markNeedsBuild();
                  }
                },
              ),
              const SizedBox(height: 16),
              Text(
                'Reason for Visit',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: reasonController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Please describe the reason for the visit...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please provide a reason for the visit'),
                    backgroundColor: Color(0xFFCB2213),
                  ),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            child: const Text('Book'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final userId =
            Provider.of<AuthProvider>(context, listen: false).user?.uid;
        final appointmentDateTime = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          selectedTime.hour,
          selectedTime.minute,
        );

        final appointment = Appointment(
          animalId: animal.id!,
          animalName: animal.name,
          veterinarianId: veterinarian.id,
          veterinarianName: veterinarian.name,
          appointmentDate: appointmentDateTime,
          reason: reasonController.text.trim(),
          status: AppointmentStatus.pending,
          createdAt: DateTime.now(),
          userId: userId!,
        );

        await provider.createAppointment(appointment);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Appointment booked successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to book appointment: $e'),
              backgroundColor: Color(0xFFCB2213),
            ),
          );
        }
      }
    }
  }
}
