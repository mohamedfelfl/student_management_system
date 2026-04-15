import 'dart:convert';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

import '../../../app/di/injection.dart';
import '../../../app/router/app_router.gr.dart';
import '../../../app/services/database_service.dart';
import '../../auth/cubits/auth_cubit.dart';
import '../services/device_binding_service.dart';
import '../services/settings_service.dart';

/// First-launch setup wizard.
///
/// Shown when no admin user exists. Guides the user through:
/// 1. Creating an admin account (username + password)
/// 2. Binding the device (hardware fingerprint + license key)
@RoutePage()
class SetupWizardScreen extends StatefulWidget {
  const SetupWizardScreen({super.key});

  @override
  State<SetupWizardScreen> createState() => _SetupWizardScreenState();
}

class _SetupWizardScreenState extends State<SetupWizardScreen> {
  final _pageController = PageController();
  int _currentStep = 0;

  // Step 1: Admin account
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _step1FormKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  // Step 2: Device binding
  String _fingerprint = '';
  String _deviceName = '';
  String _osInfo = '';
  bool _isBindingDevice = false;
  bool _deviceBound = false;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadDeviceInfo();
  }

  Future<void> _loadDeviceInfo() async {
    final service = getIt<DeviceBindingService>();
    final fingerprint = await service.generateFingerprint();
    setState(() {
      _fingerprint = fingerprint;
      _deviceName = service.getDeviceName();
      _osInfo = service.getOsInfo();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Stack(
        children: [
          // Background decoration
          Positioned(
            top: -size.height * 0.08,
            left: -size.width * 0.08,
            child: Container(
              width: size.width * 0.35,
              height: size.width * 0.35,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.primary.withValues(alpha: 0.05),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.05),
                    blurRadius: 100,
                    spreadRadius: 100,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: -size.height * 0.08,
            right: -size.width * 0.08,
            child: Container(
              width: size.width * 0.35,
              height: size.width * 0.35,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.tertiary.withValues(alpha: 0.05),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.tertiary.withValues(alpha: 0.05),
                    blurRadius: 100,
                    spreadRadius: 100,
                  ),
                ],
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    children: [
                      // Logo & Title
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.primary.withValues(alpha: 0.1),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            'assets/images/logo.png',
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Welcome! Let\'s set up your app',
                        textAlign: TextAlign.center,
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Complete these steps to get started',
                        textAlign: TextAlign.center,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Stepper indicator
                      Row(
                        children: [
                          _buildStepIndicator(0, 'Account', Icons.person),
                          _buildStepConnector(0),
                          _buildStepIndicator(1, 'Device', Icons.devices),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Step content
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: ElevationOverlay.applySurfaceTint(
                            colorScheme.surface,
                            colorScheme.surfaceTint,
                            1,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: colorScheme.outlineVariant.withValues(
                              alpha: 0.2,
                            ),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: SizedBox(
                          height: 420,
                          child: PageView(
                            controller: _pageController,
                            physics: const NeverScrollableScrollPhysics(),
                            children: [
                              SingleChildScrollView(
                                child: _buildStep1Account(
                                  colorScheme,
                                  textTheme,
                                ),
                              ),
                              SingleChildScrollView(
                                child: _buildStep2Device(
                                  colorScheme,
                                  textTheme,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Navigation buttons
                      Row(
                        children: [
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: _currentStep > 0
                                  ? OutlinedButton(
                                      onPressed: _previousStep,
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 24,
                                          vertical: 16,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      child: const Text('Back'),
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: _isSubmitting ? null : _nextStep,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: colorScheme.onPrimary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 48,
                                vertical: 16,
                              ),
                              elevation: 2,
                              shadowColor: colorScheme.primary.withValues(
                                alpha: 0.3,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    _currentStep == 1
                                        ? 'Complete Setup'
                                        : 'Next',
                                  ),
                          ),
                          const Expanded(child: SizedBox.shrink()),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── STEP INDICATORS ───

  Widget _buildStepIndicator(int step, String label, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;
    final isActive = _currentStep >= step;

    return Expanded(
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive
                  ? colorScheme.primary
                  : colorScheme.surfaceContainerHigh,
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              icon,
              size: 20,
              color: isActive
                  ? colorScheme.onPrimary
                  : colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepConnector(int beforeStep) {
    final colorScheme = Theme.of(context).colorScheme;
    final isActive = _currentStep > beforeStep;

    return SizedBox(
      width: 40,
      child: Divider(
        thickness: 2,
        color: isActive ? colorScheme.primary : colorScheme.outlineVariant,
      ),
    );
  }

  // ─── STEP 1: ADMIN ACCOUNT ───

  Widget _buildStep1Account(ColorScheme colorScheme, TextTheme textTheme) {
    return Form(
      key: _step1FormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Create Admin Account',
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'This will be the main administrator account.',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _usernameController,
            decoration: InputDecoration(
              labelText: 'Username',
              prefixIcon: const Icon(Icons.person_outline),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Username is required' : null,
            autofocus: true,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            validator: (v) =>
                v == null || v.isEmpty ? 'Password is required' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirm,
            decoration: InputDecoration(
              labelText: 'Confirm Password',
              prefixIcon: const Icon(Icons.lock_outline),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Confirm your password';
              if (v != _passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  // ─── STEP 2: DEVICE BINDING ───

  Widget _buildStep2Device(ColorScheme colorScheme, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bind to This Device',
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'This app will be restricted to this computer only.',
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _buildDeviceInfoRow(Icons.computer, 'Device', _deviceName),
              const SizedBox(height: 12),
              _buildDeviceInfoRow(Icons.info_outline, 'OS', _osInfo),
              const SizedBox(height: 12),
              _buildDeviceInfoRow(
                Icons.fingerprint,
                'Fingerprint',
                _fingerprint.length > 20
                    ? '${_fingerprint.substring(0, 20)}...'
                    : _fingerprint,
                copyText: _fingerprint,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        if (_deviceBound)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'Device bound successfully!',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          )
        else
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isBindingDevice ? null : _bindCurrentDevice,
              icon: _isBindingDevice
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.lock),
              label: const Text('Bind to This Device'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDeviceInfoRow(
    IconData icon,
    String label,
    String value, {
    String? copyText,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 18, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 12),
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontFamily: 'monospace',
              fontSize: 13,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (copyText != null) ...[
          const SizedBox(width: 8),
          IconButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: copyText));
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Copied to clipboard'),
                    behavior: SnackBarBehavior.floating,
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            icon: const Icon(Icons.copy, size: 16),
            tooltip: 'Copy',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            color: colorScheme.primary,
          ),
        ],
      ],
    );
  }

  // ─── STEP 3: ACADEMIC YEAR ───

  // ─── NAVIGATION ───

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _nextStep() async {
    if (_currentStep == 0) {
      if (!(_step1FormKey.currentState?.validate() ?? false)) return;
      setState(() => _currentStep = 1);
      _pageController.animateToPage(
        1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else if (_currentStep == 1) {
      if (!_deviceBound) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please bind this device first'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      await _completeSetup();
    }
  }

  Future<void> _bindCurrentDevice() async {
    setState(() => _isBindingDevice = true);
    try {
      final service = getIt<DeviceBindingService>();
      await service.bindDevice(_fingerprint);
      final licenseKey = service.generateLicenseKey(_fingerprint);
      await service.storeLicenseKey(licenseKey);

      setState(() {
        _deviceBound = true;
        _isBindingDevice = false;
      });
    } catch (e) {
      setState(() => _isBindingDevice = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to bind device: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _completeSetup() async {
    setState(() => _isSubmitting = true);

    try {
      final dbService = getIt<DatabaseService>();
      final Database db = await dbService.database;

      // 1. Create admin user with salted password
      final (passwordHash, salt) = AuthCubit.hashPasswordWithSalt(
        _passwordController.text,
      );

      await db.insert('users', {
        'username': _usernameController.text.trim(),
        'password_hash': passwordHash,
        'salt': salt,
        'role': 'admin',
        'permissions': jsonEncode([
          'manageStudents',
          'manageGroups',
          'managePayments',
          'manageAttendance',
          'manageExams',
          'viewReports',
          'manageUsers',
          'manageAssistants',
          'manageNotes',
        ]),
      });

      // 3. Mark setup as completed
      final settingsService = getIt<SettingsService>();
      await settingsService.setBool(SettingsKeys.setupCompleted, true);

      // Navigate to login
      if (mounted) {
        context.router.replaceAll([const LoginRoute()]);
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Setup failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
