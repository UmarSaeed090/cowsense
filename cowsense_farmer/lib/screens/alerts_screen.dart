import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/alert.dart';
import '../providers/sensor_provider.dart';
import '../models/animal.dart';
import 'package:intl/intl.dart';

class AlertsScreen extends StatefulWidget {
  final Animal animal;

  const AlertsScreen({
    super.key,
    required this.animal,
  });

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  bool pushEnabled = true;
  bool emailEnabled = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Consumer<SensorProvider>(
      builder: (context, provider, child) {
        final alerts = provider.getAlertsForAnimal(widget.animal.tagNumber);
        return Scaffold(
          backgroundColor: theme.colorScheme.surface,
          body: SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  floating: true,
                  pinned: true,
                  backgroundColor: theme.colorScheme.surface,
                  elevation: 0,
                  title: Text(
                    widget.animal.name,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  actions: [
                    if (alerts.isNotEmpty)
                      TextButton.icon(
                        onPressed: () =>
                            provider.clearAllAlerts(widget.animal.tagNumber),
                        icon: Icon(Icons.delete_outline,
                            color: theme.colorScheme.error),
                        label: Text(
                          'Clear All',
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                      ),
                    const SizedBox(width: 8),
                  ],
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (alerts.isEmpty)
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.notifications_off,
                                  size: 64,
                                  color: theme.colorScheme.outline,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No alerts yet',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: theme.colorScheme.outline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (alerts.isNotEmpty) ...[
                          ...alerts.map((alert) => Dismissible(
                                key: ValueKey(alert.time.toIso8601String() +
                                    alert.message),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.error,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20),
                                  child: Icon(
                                    Icons.delete,
                                    color: theme.colorScheme.onError,
                                  ),
                                ),
                                onDismissed: (_) => provider.removeAlert(alert),
                                child: Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                      color: alert.isCritical
                                          ? theme.colorScheme.error
                                              .withOpacity(0.2)
                                          : theme.colorScheme.outline
                                              .withOpacity(0.2),
                                    ),
                                  ),
                                  child: InkWell(
                                    onTap: () {
                                      setState(() {
                                        alert.read = true;
                                        provider.markAllAlertsRead(
                                            widget.animal.tagNumber);
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color:
                                                  _getAlertColor(alert, theme)
                                                      .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Icon(
                                              _getAlertIcon(alert),
                                              color:
                                                  _getAlertColor(alert, theme),
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        alert.message,
                                                        style: theme.textTheme
                                                            .titleMedium
                                                            ?.copyWith(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: _getAlertColor(
                                                              alert, theme),
                                                        ),
                                                      ),
                                                    ),
                                                    if (!alert.read)
                                                      Container(
                                                        width: 8,
                                                        height: 8,
                                                        decoration:
                                                            BoxDecoration(
                                                          color: theme
                                                              .colorScheme
                                                              .error,
                                                          shape:
                                                              BoxShape.circle,
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  alert.value,
                                                  style: theme
                                                      .textTheme.bodyLarge
                                                      ?.copyWith(
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  _formatTime(alert.time),
                                                  style: theme
                                                      .textTheme.bodySmall
                                                      ?.copyWith(
                                                    color: theme
                                                        .colorScheme.onSurface
                                                        .withOpacity(0.7),
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
                              )),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _getAlertIcon(Alert alert) {
    switch (alert.type) {
      case 'Temperature':
        return Icons.thermostat;
      case 'Heart Rate':
        return Icons.favorite;
      case 'SpO2':
        return Icons.bloodtype;
      case 'Notification':
      default:
        return Icons.notification_important;
    }
  }

  Color _getAlertColor(Alert alert, ThemeData theme) {
    if (alert.isCritical) {
      return theme.colorScheme.error;
    }
    switch (alert.type) {
      case 'Temperature':
        return Colors.orange;
      case 'Heart Rate':
        return Colors.purple;
      case 'SpO2':
        return Colors.blue;
      case 'Notification':
      default:
        return theme.colorScheme.primary;
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    if (now.difference(time).inDays == 0) {
      return 'Today, ${DateFormat.Hms().format(time)}';
    }
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(time);
  }
}
