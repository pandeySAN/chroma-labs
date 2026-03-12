import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/doctor_model.dart';
import '../providers/auth_provider.dart';
import '../widgets/app_logo.dart';
import 'doctor_home_screen.dart';

/// Screen for registering a user as a doctor
class DoctorRegistrationScreen extends StatefulWidget {
  const DoctorRegistrationScreen({super.key});

  @override
  State<DoctorRegistrationScreen> createState() => _DoctorRegistrationScreenState();
}

class _DoctorRegistrationScreenState extends State<DoctorRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _specializationController = TextEditingController();
  
  List<Clinic> _clinics = [];
  Clinic? _selectedClinic;
  bool _isLoadingClinics = true;
  bool _isRegistering = false;

  final List<String> _commonSpecializations = [
    'General Practitioner',
    'Cardiologist',
    'Dermatologist',
    'Neurologist',
    'Orthopedic Surgeon',
    'Pediatrician',
    'Psychiatrist',
    'Radiologist',
    'Surgeon',
    'Urologist',
    'Other',
  ];

  String? _selectedSpecialization;

  @override
  void initState() {
    super.initState();
    _loadClinics();
  }

  @override
  void dispose() {
    _specializationController.dispose();
    super.dispose();
  }

  Future<void> _loadClinics() async {
    try {
      final clinics = await context.read<AuthProvider>().getClinics();
      if (mounted) {
        setState(() {
          _clinics = clinics;
          _isLoadingClinics = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingClinics = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF153A4D),
              Color(0xFF0F2A3D),
              Color(0xFF0A2533),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 40),
                _buildHeader(),
                const SizedBox(height: 32),
                _buildRegistrationForm(authProvider),
                const SizedBox(height: 24),
                _buildSkipOption(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: const Color(0xFF00B8A9).withOpacity(0.2),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: const AppLogo(size: 100, borderRadius: 28),
        ),
        const SizedBox(height: 24),
        const Text(
          'Complete Your Profile',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        ShaderMask(
          shaderCallback: (bounds) {
            return const LinearGradient(
              colors: [
                Color(0xFF00B8A9),
                Color(0xFF6FCF4E),
              ],
            ).createShader(bounds);
          },
          child: Text(
            'Register as a doctor to access appointments',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildRegistrationForm(AuthProvider authProvider) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Doctor Registration',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please fill in your professional details',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            
            // User info card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF00B8A9).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xFF00B8A9),
                    radius: 24,
                    child: Text(
                      authProvider.userInitials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          authProvider.userName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          authProvider.userEmail,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Specialization dropdown
            DropdownButtonFormField<String>(
              initialValue: _selectedSpecialization,
              decoration: InputDecoration(
                labelText: 'Specialization',
                hintText: 'Select your specialization',
                prefixIcon: const Icon(Icons.medical_services_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              items: _commonSpecializations.map((spec) {
                return DropdownMenuItem(value: spec, child: Text(spec));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedSpecialization = value;
                  if (value == 'Other') {
                    _specializationController.clear();
                  } else {
                    _specializationController.text = value ?? '';
                  }
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select a specialization';
                }
                return null;
              },
            ),
            
            // Custom specialization field (only if "Other" is selected)
            if (_selectedSpecialization == 'Other') ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _specializationController,
                decoration: InputDecoration(
                  labelText: 'Enter Your Specialization',
                  hintText: 'e.g., Oncologist',
                  prefixIcon: const Icon(Icons.edit_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                validator: (value) {
                  if (_selectedSpecialization == 'Other' && 
                      (value == null || value.isEmpty)) {
                    return 'Please enter your specialization';
                  }
                  return null;
                },
              ),
            ],
            const SizedBox(height: 16),
            
            // Clinic dropdown (optional)
            if (_isLoadingClinics)
              const Center(child: CircularProgressIndicator())
            else if (_clinics.isNotEmpty)
              DropdownButtonFormField<Clinic>(
                initialValue: _selectedClinic,
                decoration: InputDecoration(
                  labelText: 'Clinic (Optional)',
                  hintText: 'Select your clinic',
                  prefixIcon: const Icon(Icons.local_hospital_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                items: _clinics.map((clinic) {
                  return DropdownMenuItem(
                    value: clinic,
                    child: Text(clinic.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedClinic = value);
                },
              ),
            
            const SizedBox(height: 32),
            
            // Register button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isRegistering ? null : _handleRegistration,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00B8A9),
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isRegistering
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Register as Doctor',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkipOption() {
    return Column(
      children: [
        Text(
          'Not a doctor?',
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 14,
          ),
        ),
        TextButton(
          onPressed: _handleLogout,
          child: const Text(
            'Logout and use a different account',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
              decorationColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleRegistration() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isRegistering = true);

    final specialization = _selectedSpecialization == 'Other'
        ? _specializationController.text.trim()
        : _selectedSpecialization!;

    final success = await context.read<AuthProvider>().registerAsDoctor(
      specialization: specialization,
      clinicId: _selectedClinic?.id,
    );

    setState(() => _isRegistering = false);

    if (success && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DoctorHomeScreen()),
      );
    } else if (mounted) {
      final error = context.read<AuthProvider>().errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text(error ?? 'Registration failed')),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  Future<void> _handleLogout() async {
    await context.read<AuthProvider>().logout();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }
}
