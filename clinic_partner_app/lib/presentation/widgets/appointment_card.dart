import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/appointment_model.dart';

/// Reusable appointment card widget
class AppointmentCard extends StatelessWidget {
  final Appointment appointment;
  final VoidCallback? onTap;
  final VoidCallback? onStart;
  final VoidCallback? onComplete;
  final VoidCallback? onVideoCall;

  const AppointmentCard({
    super.key,
    required this.appointment,
    this.onTap,
    this.onStart,
    this.onComplete,
    this.onVideoCall,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(appointment.status);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(statusColor),
                const SizedBox(height: 16),
                _buildTimeRow(),
                if (appointment.hasVideoCall) _buildVideoCallButton(),
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Color statusColor) {
    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: const Color(0xFF1A73E8).withOpacity(0.1),
          child: Text(
            appointment.patientInitials,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A73E8),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                appointment.patientName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                appointment.patientEmail,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            appointment.statusDisplay,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: statusColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeRow() {
    return Row(
      children: [
        Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          appointment.formattedTime,
          style: TextStyle(fontSize: 14, color: Colors.grey[700]),
        ),
        const SizedBox(width: 16),
        Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          DateFormat('MMM dd, yyyy').format(appointment.date),
          style: TextStyle(fontSize: 14, color: Colors.grey[700]),
        ),
      ],
    );
  }

  Widget _buildVideoCallButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: onVideoCall,
          icon: const Icon(Icons.video_call),
          label: const Text('Join Video Call'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF1A73E8),
            side: const BorderSide(color: Color(0xFF1A73E8)),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    if (appointment.isScheduled && onStart != null) {
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onStart,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A73E8),
              foregroundColor: Colors.white,
            ),
            child: const Text('Start Appointment'),
          ),
        ),
      );
    } else if (appointment.isInProgress && onComplete != null) {
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onComplete,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Complete Appointment'),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'scheduled':
        return Colors.blue;
      case 'in_progress':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
