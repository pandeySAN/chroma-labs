import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../appointments/domain/entities/appointment_entity.dart';
import '../utils/receipt_downloader_stub.dart'
    if (dart.library.html) '../utils/receipt_downloader_web.dart'
    as receipt_dl;

class BookingSuccessScreen extends StatefulWidget {
  final AppointmentEntity appointment;
  final String? paymentId;

  const BookingSuccessScreen({
    super.key,
    required this.appointment,
    this.paymentId,
  });

  @override
  State<BookingSuccessScreen> createState() => _BookingSuccessScreenState();
}

class _BookingSuccessScreenState extends State<BookingSuccessScreen>
    with TickerProviderStateMixin {
  late AnimationController _checkController;
  late AnimationController _confettiController;
  late AnimationController _cardController;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;
  late Animation<double> _cardSlide;
  late List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );
    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _scaleAnim = CurvedAnimation(
      parent: _checkController,
      curve: Curves.elasticOut,
    );
    _fadeAnim = CurvedAnimation(
      parent: _checkController,
      curve: Curves.easeIn,
    );
    _cardSlide = CurvedAnimation(
      parent: _cardController,
      curve: Curves.easeOutCubic,
    );

    final rng = Random();
    _particles = List.generate(60, (i) => _Particle(rng));

    _checkController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _confettiController.forward();
    });
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _cardController.forward();
    });
  }

  @override
  void dispose() {
    _checkController.dispose();
    _confettiController.dispose();
    _cardController.dispose();
    super.dispose();
  }

  String get _formattedDate {
    try {
      return DateFormat('EEE, d MMM yyyy')
          .format(DateTime.parse(widget.appointment.date));
    } catch (_) {
      return widget.appointment.date;
    }
  }

  String get _formattedTime {
    try {
      final parts = widget.appointment.time.split(':');
      if (parts.length >= 2) {
        final h = int.parse(parts[0]);
        final m = int.parse(parts[1]);
        final dt = DateTime(0, 0, 0, h, m);
        return DateFormat('h:mm a').format(dt);
      }
    } catch (_) {}
    return widget.appointment.time;
  }

  void _downloadReceipt() {
    try {
      receipt_dl.downloadReceipt(
        doctorName: widget.appointment.doctorName,
        specialization: widget.appointment.doctorSpecialization,
        clinicName: widget.appointment.clinicName,
        date: _formattedDate,
        time: _formattedTime,
        consultationFee: widget.appointment.consultationFee,
        appointmentId: widget.appointment.id,
        paymentId: widget.paymentId,
      );
    } catch (_) {
      _showReceiptDialog();
    }
  }

  void _showReceiptDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Payment Receipt',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ReceiptDialogRow('Receipt No', '#APT-${widget.appointment.id}'),
            _ReceiptDialogRow('Doctor', 'Dr. ${widget.appointment.doctorName}'),
            _ReceiptDialogRow(
                'Specialization', widget.appointment.doctorSpecialization),
            _ReceiptDialogRow('Clinic', widget.appointment.clinicName),
            _ReceiptDialogRow('Date', _formattedDate),
            _ReceiptDialogRow('Time', _formattedTime),
            if (widget.paymentId != null)
              _ReceiptDialogRow('Transaction ID', widget.paymentId!),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Amount Paid',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
                Text(
                  '₹${widget.appointment.consultationFee.toStringAsFixed(0)}',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final fee = widget.appointment.consultationFee;
    final feeStr =
        '₹${NumberFormat('#,##0', 'en_IN').format(fee.toInt())}';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── Confetti ────────────────────────────────────────────
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _confettiController,
              builder: (_, __) => CustomPaint(
                painter: _ConfettiPainter(
                    _confettiController.value, _particles, size),
              ),
            ),
          ),

          // ── Content ─────────────────────────────────────────────
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              child: Column(
                children: [
                  const SizedBox(height: 24),

                  // Animated check
                  FadeTransition(
                    opacity: _fadeAnim,
                    child: ScaleTransition(
                      scale: _scaleAnim,
                      child: Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: AppColors.success, width: 2.5),
                        ),
                        child: const Icon(Icons.check_rounded,
                            size: 62, color: AppColors.success),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  FadeTransition(
                    opacity: _fadeAnim,
                    child: Column(
                      children: [
                        Text(
                          'Payment Successful!',
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Your appointment has been confirmed.',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: AppColors.textGrey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (fee > 0) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '$feeStr paid',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Receipt card
                  SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.3),
                      end: Offset.zero,
                    ).animate(_cardSlide),
                    child: FadeTransition(
                      opacity: _cardSlide,
                      child: _buildReceiptCard(feeStr),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Download receipt button
                  SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.3),
                      end: Offset.zero,
                    ).animate(_cardSlide),
                    child: FadeTransition(
                      opacity: _cardSlide,
                      child: Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 2,
                              ),
                              onPressed: _downloadReceipt,
                              icon: Icon(
                                kIsWeb
                                    ? Icons.download_rounded
                                    : Icons.receipt_long_rounded,
                                size: 20,
                              ),
                              label: Text(
                                kIsWeb
                                    ? 'Download Receipt'
                                    : 'View Receipt',
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                side: const BorderSide(
                                    color: AppColors.primary, width: 1.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: () => Navigator.of(context)
                                  .popUntil((r) => r.isFirst),
                              child: Text(
                                'View My Appointments',
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context)
                                .popUntil((r) => r.isFirst),
                            child: Text(
                              'Back to Home',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: AppColors.textGrey,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptCard(String feeStr) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Teal header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                const Icon(Icons.receipt_long_rounded,
                    color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Text(
                  'Receipt #APT-${widget.appointment.id}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'PAID',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _ReceiptRow(
                  icon: Icons.person_rounded,
                  label: 'Doctor',
                  value: 'Dr. ${widget.appointment.doctorName}',
                ),
                _ReceiptRow(
                  icon: Icons.medical_services_rounded,
                  label: 'Specialization',
                  value: widget.appointment.doctorSpecialization,
                ),
                _ReceiptRow(
                  icon: Icons.business_rounded,
                  label: 'Clinic',
                  value: widget.appointment.clinicName,
                ),
                _ReceiptRow(
                  icon: Icons.calendar_today_rounded,
                  label: 'Date',
                  value: _formattedDate,
                ),
                _ReceiptRow(
                  icon: Icons.access_time_rounded,
                  label: 'Time',
                  value: _formattedTime,
                ),
                if (widget.paymentId != null &&
                    widget.paymentId!.isNotEmpty)
                  _ReceiptRow(
                    icon: Icons.tag_rounded,
                    label: 'Transaction ID',
                    value: widget.paymentId!,
                    valueStyle: const TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                const Divider(height: 24, color: AppColors.divider),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Paid',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    Text(
                      feeStr,
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
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
}

// ─── Receipt Row ──────────────────────────────────────────────────────────────
class _ReceiptRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final TextStyle? valueStyle;
  const _ReceiptRow(
      {required this.icon,
      required this.label,
      required this.value,
      this.valueStyle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: AppColors.textGrey)),
                Text(
                  value,
                  style: valueStyle ??
                      GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceiptDialogRow extends StatelessWidget {
  final String label;
  final String value;
  const _ReceiptDialogRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 12, color: AppColors.textGrey)),
          Text(value,
              style: GoogleFonts.poppins(
                  fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ─── Confetti Particle ────────────────────────────────────────────────────────
class _Particle {
  final double x;
  final double startY;
  final double size;
  final Color color;
  final double speed;
  final double amplitude;
  final double frequency;
  final double phase;
  final double rotationSpeed;

  static const _colors = [
    Color(0xFF14919B),
    Color(0xFF45D97B),
    Color(0xFFFFD700),
    Color(0xFFFF6B9D),
    Color(0xFF6C63FF),
    Color(0xFFFF8C42),
    Color(0xFF4CE68A),
  ];

  _Particle(Random rng)
      : x = rng.nextDouble(),
        startY = -rng.nextDouble() * 0.5,
        size = 6 + rng.nextDouble() * 8,
        color = _colors[rng.nextInt(_colors.length)],
        speed = 0.6 + rng.nextDouble() * 0.4,
        amplitude = 20 + rng.nextDouble() * 40,
        frequency = 2 + rng.nextDouble() * 4,
        phase = rng.nextDouble() * pi * 2,
        rotationSpeed = (rng.nextDouble() - 0.5) * 10;
}

class _ConfettiPainter extends CustomPainter {
  final double progress;
  final List<_Particle> particles;
  final Size screenSize;

  _ConfettiPainter(this.progress, this.particles, this.screenSize);

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;
    for (final p in particles) {
      final t = (progress * p.speed).clamp(0.0, 1.0);
      final yPos = (p.startY + t * 1.4) * size.height;
      if (yPos > size.height + 20) continue;
      final xPos = p.x * size.width +
          sin(t * p.frequency * pi + p.phase) * p.amplitude;

      final opacity = t < 0.7 ? 1.0 : 1.0 - ((t - 0.7) / 0.3);
      final paint = Paint()
        ..color = p.color.withValues(alpha: opacity.clamp(0, 1))
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(xPos, yPos);
      canvas.rotate(t * p.rotationSpeed);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset.zero, width: p.size, height: p.size * 0.55),
          const Radius.circular(2),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) =>
      old.progress != progress;
}
