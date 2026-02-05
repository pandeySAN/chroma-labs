import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../data/models/appointment_model.dart';
import '../providers/auth_provider.dart';
import '../providers/appointment_provider.dart';
import '../widgets/skeleton_loaders.dart';
import 'login_screen.dart';

/// Modern Doctor Home Screen - Appointments Dashboard
class DoctorHomeScreen extends StatefulWidget {
  const DoctorHomeScreen({super.key});

  @override
  State<DoctorHomeScreen> createState() => _DoctorHomeScreenState();
}

class _DoctorHomeScreenState extends State<DoctorHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAppointments();
    });
  }

  Future<void> _loadAppointments() async {
    await context.read<AppointmentProvider>().fetchAppointments();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(context),
      body: RefreshIndicator(
        onRefresh: () => context.read<AppointmentProvider>().refreshAppointments(),
        color: const Color(0xFF00B8A9),
        backgroundColor: Colors.white,
        child: _buildBody(context),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    
    return AppBar(
      backgroundColor: const Color(0xFF0F2A3D),
      foregroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Consumer<AppointmentProvider>(
        builder: (context, provider, _) {
          return Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00B8A9), Color(0xFF6FCF4E)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.calendar_today_rounded, size: 24),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'My Appointments',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                  if (provider.isDemoMode)
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6FCF4E),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'DEMO',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
      actions: [
        // Doctor name badge
        if (authProvider.currentDoctor != null)
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.medical_services, size: 16),
                const SizedBox(width: 6),
                Text(
                  authProvider.currentDoctor!.specialization,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        const SizedBox(width: 8),
        // Demo mode button
        Consumer<AppointmentProvider>(
          builder: (context, provider, _) {
            return IconButton(
              icon: Icon(
                provider.isDemoMode ? Icons.science : Icons.science_outlined,
                color: provider.isDemoMode ? const Color(0xFF6FCF4E) : Colors.white,
              ),
              tooltip: provider.isDemoMode ? 'Exit Demo Mode' : 'Load Demo Data',
              onPressed: () {
                provider.toggleDemoMode();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(
                          provider.isDemoMode ? Icons.science_outlined : Icons.science,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          provider.isDemoMode 
                              ? 'Demo mode disabled' 
                              : 'Demo mode enabled - showing sample appointments',
                        ),
                      ],
                    ),
                    backgroundColor: const Color(0xFF00B8A9),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            );
          },
        ),
        // Refresh button
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          tooltip: 'Refresh',
          onPressed: () {
            final provider = context.read<AppointmentProvider>();
            if (provider.isDemoMode) {
              provider.loadDemoAppointments();
            } else {
              provider.fetchAppointments();
            }
          },
        ),
        // Logout button
        IconButton(
          icon: const Icon(Icons.logout_rounded),
          tooltip: 'Logout',
          onPressed: () => _showLogoutDialog(context),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    return Consumer<AppointmentProvider>(
      builder: (context, provider, child) {
        // Loading state
        if (provider.isLoading && !provider.hasAppointments) {
          return _buildLoadingState();
        }

        // Error state
        if (provider.errorMessage != null && !provider.hasAppointments) {
          return _buildErrorState(provider.errorMessage!);
        }

        // Empty state
        if (!provider.hasAppointments) {
          return _buildEmptyState();
        }

        // Appointments list
        return _buildAppointmentsList(provider.appointments);
      },
    );
  }

  Widget _buildLoadingState() {
    // Use skeleton loaders for better perceived performance
    return const AppointmentListSkeleton(itemCount: 4);
  }

  Widget _buildErrorState(String error) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: MediaQuery.of(context).size.height - 200,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FadeInContent(
                  delay: const Duration(milliseconds: 100),
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Icon(
                      Icons.error_outline_rounded,
                      size: 48,
                      color: Colors.red.shade400,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const FadeInContent(
                  delay: Duration(milliseconds: 200),
                  child: Text(
                    'Failed to load appointments',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                FadeInContent(
                  delay: const Duration(milliseconds: 300),
                  child: Text(
                    error,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                FadeInContent(
                  delay: const Duration(milliseconds: 400),
                  child: ElevatedButton.icon(
                    onPressed: _loadAppointments,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00B8A9),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: MediaQuery.of(context).size.height - 200,
        child: Center(
          child: FadeInContent(
            duration: const Duration(milliseconds: 500),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FadeInContent(
                  delay: const Duration(milliseconds: 100),
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00B8A9).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Icon(
                      Icons.calendar_today_outlined,
                      size: 56,
                      color: Color(0xFF00B8A9),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const FadeInContent(
                  delay: Duration(milliseconds: 200),
                  child: Text(
                    'No appointments yet',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                FadeInContent(
                  delay: const Duration(milliseconds: 300),
                  child: Text(
                    'New bookings will appear here.\nPull down to refresh.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey.shade500,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                FadeInContent(
                  delay: const Duration(milliseconds: 400),
                  child: OutlinedButton.icon(
                    onPressed: _loadAppointments,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Refresh'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF00B8A9),
                      side: const BorderSide(color: Color(0xFF00B8A9)),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppointmentsList(List<Appointment> appointments) {
    // Group appointments by date
    final Map<String, List<Appointment>> grouped = {};
    for (final appointment in appointments) {
      final dateKey = DateFormat('yyyy-MM-dd').format(appointment.date);
      grouped.putIfAbsent(dateKey, () => []).add(appointment);
    }

    final sortedDates = grouped.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      itemCount: sortedDates.length,
      itemBuilder: (context, dateIndex) {
        final dateKey = sortedDates[dateIndex];
        final dateAppointments = grouped[dateKey]!;
        final date = DateTime.parse(dateKey);
        
        // Calculate stagger delay based on position
        final baseDelay = Duration(milliseconds: dateIndex * 80);
        
        return FadeInContent(
          delay: baseDelay,
          duration: const Duration(milliseconds: 350),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date header with fade-in
              _buildDateHeader(date),
              const SizedBox(height: 12),
              // Appointments for this date with staggered fade-in
              ...dateAppointments.asMap().entries.map((entry) {
                final appointmentIndex = entry.key;
                final appointment = entry.value;
                
                return FadeInContent(
                  delay: baseDelay + Duration(milliseconds: 60 * (appointmentIndex + 1)),
                  duration: const Duration(milliseconds: 400),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _AppointmentCard(
                      appointment: appointment,
                      onVideoCall: appointment.hasVideoCall
                          ? () => _launchVideoCall(appointment.videoCallLink!)
                          : null,
                      onStatusChange: (newStatus) async {
                        HapticFeedback.lightImpact();
                        await context.read<AppointmentProvider>()
                            .updateAppointmentStatus(appointment.id, newStatus);
                      },
                    ),
                  ),
                );
              }),
              if (dateIndex < sortedDates.length - 1)
                const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final appointmentDate = DateTime(date.year, date.month, date.day);
    
    String label;
    Color labelColor;
    
    if (appointmentDate == today) {
      label = 'Today';
      labelColor = const Color(0xFF00B8A9);
    } else if (appointmentDate == today.add(const Duration(days: 1))) {
      label = 'Tomorrow';
      labelColor = const Color(0xFF10B981);
    } else {
      label = DateFormat('EEEE, MMMM d, y').format(date);
      labelColor = const Color(0xFF64748B);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: labelColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.calendar_today, size: 16, color: labelColor),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: labelColor,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchVideoCall(String url) async {
    final uri = Uri.parse(url);
    
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.white),
                  SizedBox(width: 12),
                  Text('Could not open video call link'),
                ],
              ),
              backgroundColor: Colors.red.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error launching video call: $e'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    }
  }

  Future<void> _showLogoutDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        contentPadding: const EdgeInsets.all(24),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.logout_rounded, color: Colors.red.shade400),
            ),
            const SizedBox(width: 16),
            const Text('Logout'),
          ],
        ),
        content: const Text(
          'Are you sure you want to logout? You will need to sign in again to access your appointments.',
          style: TextStyle(fontSize: 15, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<AuthProvider>().logout();
      context.read<AppointmentProvider>().clear();

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }
}

/// Modern Appointment Card Widget
class _AppointmentCard extends StatelessWidget {
  final Appointment appointment;
  final VoidCallback? onVideoCall;
  final Function(String)? onStatusChange;

  const _AppointmentCard({
    required this.appointment,
    this.onVideoCall,
    this.onStatusChange,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Avatar, Name, Status
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Patient Avatar
                _buildPatientAvatar(),
                const SizedBox(width: 16),
                
                // Patient Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appointment.patientName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        appointment.patientEmail,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                
                // Status Badge
                _buildStatusBadge(),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Divider
            Container(
              height: 1,
              color: const Color(0xFFE2E8F0),
            ),
            
            const SizedBox(height: 20),
            
            // Date and Time Row
            Row(
              children: [
                _buildInfoChip(
                  icon: Icons.calendar_today_outlined,
                  label: _formatDate(appointment.date),
                  color: const Color(0xFF00B8A9),
                ),
                const SizedBox(width: 16),
                _buildInfoChip(
                  icon: Icons.access_time_rounded,
                  label: appointment.formattedTime,
                  color: const Color(0xFF6FCF4E),
                ),
              ],
            ),
            
            // Notes Section
            if (appointment.hasNotes) ...[
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.notes_rounded,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Patient Notes',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      appointment.notes!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF475569),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            // Video Call Button
            if (appointment.hasVideoCall && 
                (appointment.isScheduled || appointment.isInProgress)) ...[
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onVideoCall,
                  icon: const Icon(Icons.video_call_rounded, size: 22),
                  label: const Text(
                    'Start Video Call',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00B8A9),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPatientAvatar() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF00B8A9),
            Color(0xFF6FCF4E),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00B8A9).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Center(
        child: Text(
          appointment.patientInitials,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color bgColor;
    Color textColor;
    IconData icon;
    
    switch (appointment.status) {
      case 'scheduled':
        bgColor = const Color(0xFFDCFCE7);
        textColor = const Color(0xFF16A34A);
        icon = Icons.event_available;
        break;
      case 'in_progress':
        bgColor = const Color(0xFFDBEAFE);
        textColor = const Color(0xFF2563EB);
        icon = Icons.play_circle_outline;
        break;
      case 'completed':
        bgColor = const Color(0xFFF1F5F9);
        textColor = const Color(0xFF64748B);
        icon = Icons.check_circle_outline;
        break;
      default:
        bgColor = const Color(0xFFF1F5F9);
        textColor = const Color(0xFF64748B);
        icon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 6),
          Text(
            appointment.statusDisplay,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final appointmentDate = DateTime(date.year, date.month, date.day);
    
    if (appointmentDate == today) {
      return 'Today';
    } else if (appointmentDate == today.add(const Duration(days: 1))) {
      return 'Tomorrow';
    } else {
      return DateFormat('MMM d, yyyy').format(date);
    }
  }
}
