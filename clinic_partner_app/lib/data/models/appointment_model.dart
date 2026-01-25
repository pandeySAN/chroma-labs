import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Appointment model representing a doctor-patient appointment
class Appointment {
  final int id;
  final String patientName;
  final String patientEmail;
  final DateTime date;
  final String time;
  final String status;
  final String? videoCallLink;
  final String? notes;

  Appointment({
    required this.id,
    required this.patientName,
    required this.patientEmail,
    required this.date,
    required this.time,
    required this.status,
    this.videoCallLink,
    this.notes,
  });

  // ===========================================
  // JSON Serialization
  // ===========================================

  /// Create Appointment from JSON map
  factory Appointment.fromJson(Map<String, dynamic> json) {
    // Handle nested patient object or flat structure
    String patientName;
    String patientEmail;
    
    if (json['patient'] is Map) {
      final patient = json['patient'] as Map<String, dynamic>;
      patientName = patient['name'] as String? ?? '';
      patientEmail = patient['email'] as String? ?? '';
    } else {
      patientName = json['patient_name'] as String? ?? '';
      patientEmail = json['patient_email'] as String? ?? '';
    }

    return Appointment(
      id: json['id'] as int,
      patientName: patientName,
      patientEmail: patientEmail,
      date: DateTime.parse(json['date'] as String),
      time: json['time'] as String,
      status: json['status'] as String,
      videoCallLink: json['video_call_link'] as String?,
      notes: json['notes'] as String?,
    );
  }

  /// Convert Appointment to JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patient_name': patientName,
      'patient_email': patientEmail,
      'date': DateFormat('yyyy-MM-dd').format(date),
      'time': time,
      'status': status,
      'video_call_link': videoCallLink,
      'notes': notes,
    };
  }

  // ===========================================
  // Formatted Getters
  // ===========================================

  /// Get formatted date (e.g., "Jan 19, 2026")
  String get formattedDate => DateFormat('MMM dd, yyyy').format(date);

  /// Get formatted date short (e.g., "19/01/2026")
  String get formattedDateShort => DateFormat('dd/MM/yyyy').format(date);

  /// Get formatted time (e.g., "09:00 AM")
  String get formattedTime {
    try {
      final parts = time.split(':');
      if (parts.length >= 2) {
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        final dateTime = DateTime(2000, 1, 1, hour, minute);
        return DateFormat('hh:mm a').format(dateTime);
      }
    } catch (_) {}
    return time;
  }

  /// Get time without seconds (e.g., "09:00")
  String get timeShort {
    final parts = time.split(':');
    if (parts.length >= 2) {
      return '${parts[0]}:${parts[1]}';
    }
    return time;
  }

  /// Get formatted date and time together
  String get formattedDateTime => '$formattedDate at $formattedTime';

  // ===========================================
  // Status Helpers
  // ===========================================

  /// Check if appointment has video call link
  bool get hasVideoCall => 
      videoCallLink != null && videoCallLink!.isNotEmpty;

  /// Check if appointment has notes
  bool get hasNotes => 
      notes != null && notes!.isNotEmpty;

  /// Check if appointment is scheduled
  bool get isScheduled => status == 'scheduled';

  /// Check if appointment is in progress
  bool get isInProgress => status == 'in_progress';

  /// Check if appointment is completed
  bool get isCompleted => status == 'completed';

  /// Get display text for status
  String get statusDisplay {
    switch (status) {
      case 'scheduled':
        return 'Scheduled';
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      default:
        return status;
    }
  }

  /// Get color for status
  Color get statusColor {
    switch (status) {
      case 'scheduled':
        return const Color(0xFF2196F3); // Blue
      case 'in_progress':
        return const Color(0xFFFF9800); // Orange
      case 'completed':
        return const Color(0xFF4CAF50); // Green
      default:
        return const Color(0xFF9E9E9E); // Grey
    }
  }

  /// Get light background color for status
  Color get statusBackgroundColor => statusColor.withOpacity(0.1);

  /// Get icon for status
  IconData get statusIcon {
    switch (status) {
      case 'scheduled':
        return Icons.schedule;
      case 'in_progress':
        return Icons.play_circle_outline;
      case 'completed':
        return Icons.check_circle_outline;
      default:
        return Icons.help_outline;
    }
  }

  // ===========================================
  // Date Helpers
  // ===========================================

  /// Check if appointment is today
  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// Check if appointment is in the past
  bool get isPast {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final appointmentDate = DateTime(date.year, date.month, date.day);
    return appointmentDate.isBefore(today);
  }

  /// Check if appointment is in the future
  bool get isFuture {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final appointmentDate = DateTime(date.year, date.month, date.day);
    return appointmentDate.isAfter(today);
  }

  /// Get patient initials for avatar
  String get patientInitials {
    final names = patientName.trim().split(' ');
    if (names.isEmpty) return '?';
    if (names.length == 1) return names[0][0].toUpperCase();
    return '${names[0][0]}${names[names.length - 1][0]}'.toUpperCase();
  }

  // ===========================================
  // Copy With
  // ===========================================

  /// Create a copy with updated fields
  Appointment copyWith({
    int? id,
    String? patientName,
    String? patientEmail,
    DateTime? date,
    String? time,
    String? status,
    String? videoCallLink,
    String? notes,
  }) {
    return Appointment(
      id: id ?? this.id,
      patientName: patientName ?? this.patientName,
      patientEmail: patientEmail ?? this.patientEmail,
      date: date ?? this.date,
      time: time ?? this.time,
      status: status ?? this.status,
      videoCallLink: videoCallLink ?? this.videoCallLink,
      notes: notes ?? this.notes,
    );
  }

  @override
  String toString() {
    return 'Appointment(id: $id, patient: $patientName, date: $formattedDate, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Appointment && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
