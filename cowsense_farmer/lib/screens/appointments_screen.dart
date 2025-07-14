import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/appointment.dart';
import '../providers/veterinarian_provider.dart';
import 'appointment_details_screen.dart';
import '../providers/auth_provider.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({Key? key}) : super(key: key);

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  AppointmentStatus? _selectedStatus;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: const Text(
          'Appointments',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
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
                      'Error loading appointments',
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
                        provider.loadAnimalAppointments(
                            Provider.of<AuthProvider>(context, listen: false)
                                .user!
                                .uid);
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            final appointments = provider.appointments;
            final filteredAppointments = _selectedStatus == null
                ? appointments
                : appointments
                    .where(
                        (appointment) => appointment.status == _selectedStatus)
                    .toList();

            if (filteredAppointments.isEmpty) {
              return Column(
                children: [
                  _buildStatusFilter(),
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 80,
                            color: Colors.grey.withOpacity(0.5),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            _selectedStatus == null
                                ? 'No Appointments'
                                : 'No ${_selectedStatus.toString().split('.').last} Appointments',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _selectedStatus == null
                                ? 'You don\'t have any appointments yet.'
                                : 'You don\'t have any ${_selectedStatus.toString().split('.').last.toLowerCase()} appointments.',
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }

            return Column(
              children: [
                _buildStatusFilter(),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredAppointments.length,
                    itemBuilder: (context, index) {
                      final appointment = filteredAppointments[index];
                      return _buildAppointmentCard(context, appointment);
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatusFilter() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildFilterChip(null, 'All'),
          ...AppointmentStatus.values.map(
            (status) => _buildFilterChip(
              status,
              status.toString().split('.').last,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(AppointmentStatus? status, String label) {
    final isSelected = _selectedStatus == status;
    final color = status == null ? Colors.blue : _getStatusColor(status);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Text(label),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : color,
          fontWeight: FontWeight.bold,
        ),
        backgroundColor: Colors.white,
        selectedColor: color,
        checkmarkColor: Colors.white,
        onSelected: (selected) {
          setState(() {
            _selectedStatus = selected ? status : null;
          });
        },
      ),
    );
  }

  Widget _buildAppointmentCard(BuildContext context, Appointment appointment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  AppointmentDetailsScreen(appointment: appointment),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: _getStatusColor(appointment.status),
                    child: Icon(
                      _getStatusIcon(appointment.status),
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appointment.animalName,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'With Dr. ${appointment.veterinarianName}',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusChip(context, appointment.status),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.calendar_today,
                      size: 20, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('MMMM dd, yyyy')
                        .format(appointment.appointmentDate),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.access_time, size: 20, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('hh:mm a').format(appointment.appointmentDate),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                appointment.reason,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context, AppointmentStatus status) {
    Color chipColor;
    String statusText;

    switch (status) {
      case AppointmentStatus.pending:
        chipColor = Colors.orange;
        statusText = 'Pending';
        break;
      case AppointmentStatus.accepted:
        chipColor = Colors.green;
        statusText = 'Accepted';
        break;
      case AppointmentStatus.rejected:
        chipColor = Color(0xFFCB2213);
        statusText = 'Rejected';
        break;
      case AppointmentStatus.completed:
        chipColor = Colors.blue;
        statusText = 'Completed';
        break;
      case AppointmentStatus.cancelled:
        chipColor = Colors.grey;
        statusText = 'Cancelled';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          color: chipColor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Color _getStatusColor(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.pending:
        return Colors.orange;
      case AppointmentStatus.accepted:
        return Colors.green;
      case AppointmentStatus.rejected:
        return Color(0xFFCB2213);
      case AppointmentStatus.completed:
        return Colors.blue;
      case AppointmentStatus.cancelled:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.pending:
        return Icons.hourglass_empty;
      case AppointmentStatus.accepted:
        return Icons.check;
      case AppointmentStatus.rejected:
        return Icons.close;
      case AppointmentStatus.completed:
        return Icons.done_all;
      case AppointmentStatus.cancelled:
        return Icons.cancel;
    }
  }
}
