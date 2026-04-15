import 'dart:convert';

import 'package:auto_route/auto_route.dart';
import 'package:crypto/crypto.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/cubits/locale_cubit.dart';
import '../../../app/di/injection.dart';
import '../../../app/services/database_service.dart';
import '../../../app/shared/widgets/responsive_layout.dart';
import '../../../generated/locale_keys.g.dart';
import '../../auth/cubits/auth_cubit.dart';
import '../../auth/models/user.dart';
import '../cubits/settings_cubit.dart';
import '../services/device_binding_service.dart';

@RoutePage()
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<SettingsCubit>().loadSettings();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return BlocConsumer<SettingsCubit, SettingsState>(
      listener: (context, state) {
        if (state.successMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.successMessage!),
              backgroundColor: Colors.green.shade700,
              behavior: SnackBarBehavior.floating,
            ),
          );
          context.read<SettingsCubit>().clearMessage();
        }
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: colorScheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
          context.read<SettingsCubit>().clearMessage();
        }
      },
      builder: (context, state) {
        final authState = context.watch<AuthCubit>().state;
        final isAdmin = authState.maybeWhen(
          authenticated: (user) => user.role == UserRole.admin,
          orElse: () => false,
        );
        final currentUser = authState.maybeWhen(
          authenticated: (user) => user,
          orElse: () => null,
        );

        return Scaffold(
          appBar: ResponsiveLayout.isMobile(context)
              ? AppBar(
                  leading: IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: () => Scaffold.of(context).openDrawer(),
                  ),
                  title: Text(LocaleKeys.settings.tr()),
                  centerTitle: true,
                )
              : null,
          body: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.settings,
                            color: colorScheme.onPrimaryContainer,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                LocaleKeys.settings.tr(),
                                style: textTheme.headlineLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                LocaleKeys.settings_header_desc.tr(),
                                style: textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // ── GENERAL & APPEARANCE (everyone) ──
                    _buildSectionHeader(
                      context,
                      icon: Icons.palette_outlined,
                      title: LocaleKeys.general_appearance.tr(),
                      subtitle: LocaleKeys.theme_lang_desc.tr(),
                    ),
                    const SizedBox(height: 12),
                    _buildSettingsCard(context, [
                      _buildThemeModeTile(context, state),
                      const Divider(height: 1),
                      _buildLanguageTile(context, state),
                    ]),

                    // Admin-only sections
                    if (isAdmin) ...[
                      const SizedBox(height: 32),

                      // ── SECURITY ──
                      _buildSectionHeader(
                        context,
                        icon: Icons.shield_outlined,
                        title: LocaleKeys.security.tr(),
                        subtitle: LocaleKeys.security_desc.tr(),
                      ),
                      const SizedBox(height: 12),
                      _buildSettingsCard(context, [
                        _buildChangePasswordTile(context, currentUser),
                      ]),

                      const SizedBox(height: 32),

                      // ── DEVICE BINDING ──
                      _buildSectionHeader(
                        context,
                        icon: Icons.devices,
                        title: LocaleKeys.device_binding.tr(),
                        subtitle: LocaleKeys.device_binding_desc.tr(),
                      ),
                      const SizedBox(height: 12),
                      _buildDeviceBindingCard(context, state),

                      const SizedBox(height: 32),

                      // ── DATABASE MANAGEMENT ──
                      _buildSectionHeader(
                        context,
                        icon: Icons.storage,
                        title: LocaleKeys.database_management.tr(),
                        subtitle: LocaleKeys.database_management_desc.tr(),
                      ),
                      const SizedBox(height: 12),
                      _buildDatabaseInfoCard(context, state),
                      const SizedBox(height: 12),
                      _buildBackupCard(context, state),
                      const SizedBox(height: 12),
                      _buildExportCard(context, state),
                      const SizedBox(height: 12),
                      _buildDangerZoneCard(context, state),
                    ],

                    const SizedBox(height: 32),

                    // ── ABOUT ──
                    _buildSectionHeader(
                      context,
                      icon: Icons.info_outline,
                      title: LocaleKeys.about_system_info.tr(),
                      subtitle: LocaleKeys.about_system_info_desc.tr(),
                    ),
                    const SizedBox(height: 12),
                    _buildAboutCard(context, state),

                    const SizedBox(height: 48),
                  ],
                ),
        );
      },
    );
  }

  // ─── SECTION HEADER ───
  Widget _buildSectionHeader(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Icon(icon, color: colorScheme.primary, size: 20),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            Text(
              subtitle,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── SETTINGS CARD WRAPPER ───
  Widget _buildSettingsCard(BuildContext context, List<Widget> children) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(children: children),
      ),
    );
  }

  // ─── SWITCH TILE ───
  Widget _buildSwitchTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return SwitchListTile(
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: colorScheme.primary, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
    );
  }

  // ─── ACTION TILE ───
  Widget _buildActionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (iconColor ?? colorScheme.primary).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor ?? colorScheme.primary, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.w600, color: iconColor),
      ),
      subtitle: Text(subtitle),
      trailing: Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
      onTap: onTap,
    );
  }

  // ─── THEME MODE TILE ───
  Widget _buildThemeModeTile(BuildContext context, SettingsState state) {
    final colorScheme = Theme.of(context).colorScheme;
    final localeMode = context.watch<LocaleCubit>().state.themeMode.name;

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.dark_mode, color: colorScheme.primary, size: 20),
      ),
      title: Text(
        LocaleKeys.theme.tr(),
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        localeMode == 'dark'
            ? LocaleKeys.dark.tr()
            : localeMode == 'light'
            ? LocaleKeys.light.tr()
            : LocaleKeys.system.tr(),
      ),
      trailing: SegmentedButton<String>(
        segments: const [
          ButtonSegment(value: 'light', icon: Icon(Icons.light_mode, size: 18)),
          ButtonSegment(
            value: 'system',
            icon: Icon(Icons.settings_suggest, size: 18),
          ),
          ButtonSegment(value: 'dark', icon: Icon(Icons.dark_mode, size: 18)),
        ],
        selected: {localeMode},
        onSelectionChanged: (set) {
          final mode = set.first;
          context.read<SettingsCubit>().setThemeMode(mode);
          final localeCubit = context.read<LocaleCubit>();
          if (mode == 'dark') {
            localeCubit.setThemeMode(ThemeMode.dark);
          } else if (mode == 'light') {
            localeCubit.setThemeMode(ThemeMode.light);
          } else {
            localeCubit.setThemeMode(ThemeMode.system);
          }
        },
        showSelectedIcon: false,
        style: ButtonStyle(
          visualDensity: VisualDensity.compact,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }

  // ─── LANGUAGE TILE ───
  Widget _buildLanguageTile(BuildContext context, SettingsState state) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.language, color: colorScheme.primary, size: 20),
      ),
      title: Text(
        LocaleKeys.language.tr(),
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(state.language == 'ar' ? 'العربية' : 'English'),
      trailing: SegmentedButton<String>(
        segments: const [
          ButtonSegment(value: 'ar', label: Text('عربي')),
          ButtonSegment(value: 'en', label: Text('EN')),
        ],
        selected: {state.language},
        onSelectionChanged: (set) {
          final lang = set.first;
          context.read<SettingsCubit>().setLanguage(lang);
          context.read<LocaleCubit>().setLanguage(lang);
          context.setLocale(Locale(lang));
        },
        showSelectedIcon: false,
        style: ButtonStyle(
          visualDensity: VisualDensity.compact,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }

  Widget _buildChangePasswordTile(BuildContext context, User? currentUser) {
    return _buildActionTile(
      context,
      icon: Icons.key,
      title: LocaleKeys.change_password.tr(),
      subtitle: LocaleKeys.change_password_desc.tr(),
      onTap: () => _showChangePasswordDialog(context, currentUser),
    );
  }

  Widget _buildDeviceBindingCard(BuildContext context, SettingsState state) {
    final colorScheme = Theme.of(context).colorScheme;

    final statusColor = state.deviceBindingStatus == DeviceBindingStatus.bound
        ? Colors.green
        : state.deviceBindingStatus == DeviceBindingStatus.mismatch
        ? colorScheme.error
        : Colors.orange;

    final statusText = state.deviceBindingStatus == DeviceBindingStatus.bound
        ? '✅ ${LocaleKeys.device_bound.tr()}'
        : state.deviceBindingStatus == DeviceBindingStatus.mismatch
        ? '❌ ${LocaleKeys.device_mismatch.tr()}'
        : '⚠️ ${LocaleKeys.device_not_bound.tr()}';

    return _buildSettingsCard(context, [
      Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(LocaleKeys.device.tr(), state.deviceName),
            const SizedBox(height: 8),
            _buildInfoRow(LocaleKeys.os.tr(), state.osInfo),
            const SizedBox(height: 8),
            _buildInfoRow(
              LocaleKeys.device_id.tr(),
              state.deviceFingerprint.length > 16
                  ? '${state.deviceFingerprint.substring(0, 16)}...'
                  : state.deviceFingerprint,
              copyText: state.deviceFingerprint,
            ),
            const SizedBox(height: 16),
            if (state.deviceBindingStatus == DeviceBindingStatus.unbound)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _bindDevice(context, state),
                  icon: const Icon(Icons.lock),
                  label: Text(LocaleKeys.bind_device.tr()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                  ),
                ),
              ),
            if (state.deviceBindingStatus == DeviceBindingStatus.bound)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showTransferDialog(context, state),
                  icon: const Icon(Icons.swap_horiz),
                  label: Text(LocaleKeys.transfer_device.tr()),
                ),
              ),
          ],
        ),
      ),
    ]);
  }

  Widget _buildInfoRow(String label, String value, {String? copyText}) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        SizedBox(
          width: 80,
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
          ),
        ),
        if (copyText != null) ...[
          const SizedBox(width: 8),
          IconButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: copyText));
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(LocaleKeys.copied_to_clipboard.tr()),
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            icon: const Icon(Icons.copy, size: 16),
            tooltip: LocaleKeys.copy.tr(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            color: colorScheme.primary,
          ),
        ],
      ],
    );
  }

  // ─── DATABASE INFO CARD ───
  Widget _buildDatabaseInfoCard(BuildContext context, SettingsState state) {
    final colorScheme = Theme.of(context).colorScheme;

    final sizeStr = _formatBytes(state.databaseSize);

    return _buildSettingsCard(context, [
      Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: colorScheme.primary, size: 18),
                const SizedBox(width: 8),
                Text(
                  LocaleKeys.database_status.tr(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '🔒 ${LocaleKeys.encrypted.tr()}',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 24,
              runSpacing: 12,
              children: [
                _buildStatChip(
                  context,
                  LocaleKeys.size.tr(),
                  sizeStr,
                  Icons.sd_storage,
                ),
                _buildStatChip(
                  context,
                  LocaleKeys.students_stat.tr(),
                  '${state.recordCounts['students'] ?? 0}',
                  Icons.people,
                ),
                _buildStatChip(
                  context,
                  LocaleKeys.groups_stat.tr(),
                  '${state.recordCounts['groups'] ?? 0}',
                  Icons.groups,
                ),
                _buildStatChip(
                  context,
                  LocaleKeys.payments_stat.tr(),
                  '${state.recordCounts['payments'] ?? 0}',
                  Icons.payment,
                ),
                _buildStatChip(
                  context,
                  LocaleKeys.attendance_stat.tr(),
                  '${state.recordCounts['attendance'] ?? 0}',
                  Icons.fact_check,
                ),
                _buildStatChip(
                  context,
                  LocaleKeys.exams_stat.tr(),
                  '${state.recordCounts['exams'] ?? 0}',
                  Icons.quiz,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        context.read<SettingsCubit>().optimizeDatabase(),
                    icon: const Icon(Icons.auto_fix_high, size: 18),
                    label: Text(LocaleKeys.optimize.tr()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        context.read<SettingsCubit>().checkIntegrity(),
                    icon: const Icon(Icons.health_and_safety, size: 18),
                    label: Text(LocaleKeys.integrity_check.tr()),
                  ),
                ),
              ],
            ),
            if (state.integrityStatus.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: state.integrityStatus == 'ok'
                      ? Colors.green.withValues(alpha: 0.1)
                      : colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  LocaleKeys.integrity.tr(args: [state.integrityStatus]),
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: state.integrityStatus == 'ok'
                        ? Colors.green
                        : colorScheme.error,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    ]);
  }

  Widget _buildStatChip(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // ─── BACKUP CARD ───
  Widget _buildBackupCard(BuildContext context, SettingsState state) {
    final colorScheme = Theme.of(context).colorScheme;

    return _buildSettingsCard(context, [
      _buildSwitchTile(
        context,
        icon: Icons.backup,
        title: LocaleKeys.auto_backup.tr(),
        subtitle: LocaleKeys.auto_backup_desc.tr(),
        value: state.autoBackupEnabled,
        onChanged: (v) => context.read<SettingsCubit>().setAutoBackup(v),
      ),
      const Divider(height: 1),
      ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.inventory, color: colorScheme.primary, size: 20),
        ),
        title: Text(
          LocaleKeys.max_backups.tr(),
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          LocaleKeys.max_backups_desc.tr(args: [state.maxBackups.toString()]),
        ),
        trailing: DropdownButton<int>(
          value: state.maxBackups,
          underline: const SizedBox.shrink(),
          items: [
            DropdownMenuItem(value: 3, child: Text('3')),
            DropdownMenuItem(value: 5, child: Text('5')),
            DropdownMenuItem(value: 10, child: Text('10')),
            DropdownMenuItem(value: 20, child: Text('20')),
          ],
          onChanged: (v) {
            if (v != null) context.read<SettingsCubit>().setMaxBackups(v);
          },
        ),
      ),
      const Divider(height: 1),
      Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: state.isSaving
                        ? null
                        : () => context.read<SettingsCubit>().createBackup(),
                    icon: state.isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save, size: 18),
                    label: Text(LocaleKeys.create_backup_now.tr()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: state.isSaving
                        ? null
                        : () => _confirmAction(
                            context,
                            title: LocaleKeys.import_backup.tr(),
                            message: LocaleKeys.confirm_restore_from_file.tr(),
                            onConfirm: () => context
                                .read<SettingsCubit>()
                                .importBackupFromFile(),
                          ),
                    icon: const Icon(Icons.file_upload, size: 18),
                    label: Text(LocaleKeys.import_backup.tr()),
                  ),
                ),
              ],
            ),
            if (state.backups.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                '${LocaleKeys.recent_backups.tr()} (${state.backups.length})',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              ...state.backups
                  .take(5)
                  .map(
                    (backup) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Icon(
                            Icons.file_present,
                            size: 16,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              backup.name,
                              style: const TextStyle(fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            backup.formattedSize,
                            style: TextStyle(
                              fontSize: 11,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () => _confirmAction(
                              context,
                              title: LocaleKeys.restore_backup.tr(),
                              message: LocaleKeys.restore_backup_msg.tr(
                                args: [backup.name],
                              ),
                              onConfirm: () => context
                                  .read<SettingsCubit>()
                                  .restoreBackup(backup.path),
                            ),
                            child: Icon(
                              Icons.restore,
                              size: 18,
                              color: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          InkWell(
                            onTap: () => _confirmAction(
                              context,
                              title: LocaleKeys.delete_backup.tr(),
                              message: LocaleKeys.delete_backup_confirm.tr(
                                args: [backup.name],
                              ),
                              onConfirm: () => context
                                  .read<SettingsCubit>()
                                  .deleteBackup(backup.path),
                            ),
                            child: Icon(
                              Icons.delete_outline,
                              size: 18,
                              color: colorScheme.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
            ],
          ],
        ),
      ),
    ]);
  }

  // ─── EXPORT CARD ───
  Widget _buildExportCard(BuildContext context, SettingsState state) {
    return _buildSettingsCard(context, [
      _buildActionTile(
        context,
        icon: Icons.people,
        title: LocaleKeys.export_students.tr(),
        subtitle: LocaleKeys.export_students_desc.tr(),
        onTap: () => context.read<SettingsCubit>().exportCsv('students'),
      ),
      const Divider(height: 1),
      _buildActionTile(
        context,
        icon: Icons.payment,
        title: LocaleKeys.export_payments.tr(),
        subtitle: LocaleKeys.export_payments_desc.tr(),
        onTap: () => context.read<SettingsCubit>().exportCsv('payments'),
      ),
      const Divider(height: 1),
      _buildActionTile(
        context,
        icon: Icons.fact_check,
        title: LocaleKeys.export_attendance.tr(),
        subtitle: LocaleKeys.export_attendance_desc.tr(),
        onTap: () => context.read<SettingsCubit>().exportCsv('attendance'),
      ),
      const Divider(height: 1),
      _buildActionTile(
        context,
        icon: Icons.quiz,
        title: LocaleKeys.export_marks.tr(),
        subtitle: LocaleKeys.export_marks_desc.tr(),
        onTap: () => context.read<SettingsCubit>().exportCsv('marks'),
      ),
    ]);
  }

  // ─── DANGER ZONE CARD ───
  Widget _buildDangerZoneCard(BuildContext context, SettingsState state) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.error.withValues(alpha: 0.3)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: colorScheme.error, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    LocaleKeys.danger_zone.tr(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.error,
                    ),
                  ),
                ],
              ),
            ),
            _buildActionTile(
              context,
              icon: Icons.delete_sweep,
              title: LocaleKeys.purge_old_data.tr(),
              subtitle: LocaleKeys.purge_old_data_desc.tr(),
              iconColor: Colors.orange,
              onTap: () => _showPurgeDialog(context),
            ),
            const Divider(height: 1),
            _buildActionTile(
              context,
              icon: Icons.delete_forever,
              title: LocaleKeys.reset_all_data.tr(),
              subtitle: LocaleKeys.reset_all_data_desc.tr(),
              iconColor: colorScheme.error,
              onTap: () => _showResetConfirmDialog(context),
            ),
          ],
        ),
      ),
    );
  }

  // ─── ABOUT CARD ───
  Widget _buildAboutCard(BuildContext context, SettingsState state) {
    final colorScheme = Theme.of(context).colorScheme;

    return _buildSettingsCard(context, [
      ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.apps, color: colorScheme.primary, size: 20),
        ),
        title: Text(
          LocaleKeys.app_version.tr(),
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        trailing: Text(
          '1.0.0',
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
      ),
      const Divider(height: 1),
      ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.storage, color: colorScheme.primary, size: 20),
        ),
        title: Text(
          LocaleKeys.database_version.tr(),
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        trailing: Text(
          'v14',
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
      ),
      const Divider(height: 1),
      ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.person, color: colorScheme.primary, size: 20),
        ),
        title: Text(
          LocaleKeys.developer.tr(),
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        trailing: Text(
          LocaleKeys.developer_name.tr(),
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
      ),
      const Divider(height: 1),
      _buildActionTile(
        context,
        icon: Icons.article,
        title: LocaleKeys.open_source_licenses.tr(),
        subtitle: LocaleKeys.open_source_licenses_desc.tr(),
        onTap: () => showLicensePage(
          context: context,
          applicationName: LocaleKeys.app_title.tr(),
          applicationVersion: '1.0.0',
        ),
      ),
    ]);
  }

  // ─── DIALOGS ───

  Future<void> _showChangePasswordDialog(
    BuildContext context,
    User? currentUser,
  ) async {
    if (currentUser == null) return;

    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(LocaleKeys.change_password.tr()),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: oldPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: LocaleKeys.current_password.tr(),
                ),
                validator: (v) => v == null || v.isEmpty
                    ? LocaleKeys.required_field.tr()
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: newPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: LocaleKeys.new_password.tr(),
                ),
                validator: (v) => v == null || v.isEmpty
                    ? LocaleKeys.required_field.tr()
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: LocaleKeys.confirm_new_password.tr(),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return LocaleKeys.required_field.tr();
                  }
                  if (v != newPasswordController.text) {
                    return LocaleKeys.passwords_do_not_match.tr();
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(LocaleKeys.cancel.tr()),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                // Verify old password using salt
                final db = await getIt<DatabaseService>().database;
                final userRow = await db.query(
                  'users',
                  columns: ['salt'],
                  where: 'id = ?',
                  whereArgs: [currentUser.id],
                );
                final salt = userRow.isNotEmpty
                    ? userRow.first['salt'] as String?
                    : null;
                final oldToHash = salt != null
                    ? '$salt${oldPasswordController.text}'
                    : oldPasswordController.text;
                final oldHash = sha256
                    .convert(utf8.encode(oldToHash))
                    .toString();
                if (oldHash != currentUser.passwordHash) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(LocaleKeys.invalid_current_password.tr()),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                  return;
                }

                // Update password with new salt
                final (newHash, newSalt) = AuthCubit.hashPasswordWithSalt(
                  newPasswordController.text,
                );
                await db.update(
                  'users',
                  {'password_hash': newHash, 'salt': newSalt},
                  where: 'id = ?',
                  whereArgs: [currentUser.id],
                );

                if (dialogContext.mounted) Navigator.pop(dialogContext);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(LocaleKeys.password_changed_success.tr()),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
            child: Text(LocaleKeys.change.tr()),
          ),
        ],
      ),
    );
  }

  void _confirmAction(
    BuildContext context, {
    required String title,
    required String message,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(LocaleKeys.cancel.tr()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              onConfirm();
            },
            child: Text(LocaleKeys.yes.tr()),
          ),
        ],
      ),
    );
  }

  Future<void> _showPurgeDialog(BuildContext context) async {
    int years = 2;
    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(LocaleKeys.purge_old_data.tr()),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(LocaleKeys.purge_old_data_msg.tr()),
              const SizedBox(height: 16),
              DropdownButton<int>(
                value: years,
                items: [
                  DropdownMenuItem(
                    value: 1,
                    child: Text('1 ${LocaleKeys.year.tr()}'),
                  ),
                  DropdownMenuItem(
                    value: 2,
                    child: Text('2 ${LocaleKeys.years.tr()}'),
                  ),
                  DropdownMenuItem(
                    value: 3,
                    child: Text('3 ${LocaleKeys.years.tr()}'),
                  ),
                  DropdownMenuItem(
                    value: 5,
                    child: Text('5 ${LocaleKeys.years.tr()}'),
                  ),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => years = v);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(LocaleKeys.cancel.tr()),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(dialogContext);
                if (context.mounted) {
                  _confirmWithPassword(
                    context,
                    title: LocaleKeys.confirm_purge.tr(),
                    message: LocaleKeys.confirm_purge_msg.tr(
                      args: [years.toString()],
                    ),
                    onConfirm: () =>
                        context.read<SettingsCubit>().purgeOldData(years),
                  );
                }
              },
              child: Text(LocaleKeys.purge.tr()),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showResetConfirmDialog(BuildContext context) async {
    _confirmWithPassword(
      context,
      title: LocaleKeys.reset_all_data.tr(),
      message: LocaleKeys.reset_all_data_warning.tr(),
      onConfirm: () => context.read<SettingsCubit>().resetAllData(),
    );
  }

  /// Password confirmation dialog for sensitive operations.
  Future<void> _confirmWithPassword(
    BuildContext context, {
    required String title,
    required String message,
    required VoidCallback onConfirm,
  }) async {
    final passwordController = TextEditingController();
    final authState = context.read<AuthCubit>().state;
    final currentUser = authState.maybeWhen(
      authenticated: (user) => user,
      orElse: () => null,
    );

    if (currentUser == null) return;

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: LocaleKeys.enter_password.tr(),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(LocaleKeys.cancel.tr()),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () async {
              final db = await getIt<DatabaseService>().database;
              final userRow = await db.query(
                'users',
                columns: ['salt'],
                where: 'id = ?',
                whereArgs: [currentUser.id],
              );
              final salt = userRow.isNotEmpty
                  ? userRow.first['salt'] as String?
                  : null;
              final toHash = salt != null
                  ? '$salt${passwordController.text}'
                  : passwordController.text;
              final hash = sha256.convert(utf8.encode(toHash)).toString();
              if (hash == currentUser.passwordHash) {
                if (dialogContext.mounted) Navigator.pop(dialogContext);
                onConfirm();
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(LocaleKeys.invalid_current_password.tr()),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: Text(LocaleKeys.confirm.tr()),
          ),
        ],
      ),
    );
  }

  Future<void> _bindDevice(BuildContext context, SettingsState state) async {
    final deviceBindingService = getIt<DeviceBindingService>();
    final fingerprint = await deviceBindingService.generateFingerprint();
    await deviceBindingService.bindDevice(fingerprint);

    // Generate and store license key
    final licenseKey = deviceBindingService.generateLicenseKey(fingerprint);
    await deviceBindingService.storeLicenseKey(licenseKey);

    if (mounted && context.mounted) {
      context.read<SettingsCubit>().loadSettings();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(LocaleKeys.device_binding_success.tr()),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _showTransferDialog(
    BuildContext context,
    SettingsState state,
  ) async {
    final codeController = TextEditingController();

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(LocaleKeys.transfer_device.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(LocaleKeys.transfer_desc.tr()),
            const SizedBox(height: 16),
            TextField(
              controller: codeController,
              decoration: InputDecoration(
                labelText: LocaleKeys.transfer_code.tr(),
                hintText: LocaleKeys.transfer_code_hint.tr(),
              ),
              textCapitalization: TextCapitalization.characters,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(LocaleKeys.cancel.tr()),
          ),
          ElevatedButton(
            onPressed: () async {
              final deviceBindingService = getIt<DeviceBindingService>();
              debugPrint('Device Fingerprint: ${state.deviceFingerprint}');
              final isValid = deviceBindingService.validateTransferCode(
                codeController.text,
                state.deviceFingerprint,
              );

              if (isValid) {
                await deviceBindingService.unbindDevice();
                if (dialogContext.mounted) Navigator.pop(dialogContext);
                if (context.mounted) {
                  context.read<SettingsCubit>().loadSettings();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(LocaleKeys.device_unbound_success.tr()),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(LocaleKeys.invalid_transfer_code.tr()),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: Text(LocaleKeys.transfer.tr()),
          ),
        ],
      ),
    );
  }

  // ─── HELPERS ───

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
