import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/shared/widgets/responsive_layout.dart';
import '../../../../app/router/app_router.gr.dart';
import '../../../../generated/locale_keys.g.dart';
import '../../cubits/group_cubit.dart';

@RoutePage()
class GroupFormScreen extends StatefulWidget {
  final int? id;
  const GroupFormScreen({super.key, this.id});

  @override
  State<GroupFormScreen> createState() => _GroupFormScreenState();
}

class _GroupFormScreenState extends State<GroupFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final List<String> _selectedDays = [];
  final Map<String, TimeOfDay> _dayTimes = {};
  bool _isEditing = false;

  final List<String> _days = <String>[
    'Saturday',
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.id != null) {
      _isEditing = true;
      _loadGroup();
      // Load linked students for this group
      context.read<GroupCubit>().loadGroupStudents(widget.id!);
      context.read<GroupCubit>().loadAvailableStudents();
    }
  }

  void _loadGroup() {
    final List<Map<String, dynamic>> groups = context
        .read<GroupCubit>()
        .state
        .groups;
    final Map<String, dynamic>? g = groups
        .where((Map<String, dynamic> g) => g['id'] == widget.id)
        .firstOrNull;
    if (g != null) {
      _nameController.text = g['name']?.toString() ?? '';

      final List<dynamic> schedules = g['schedules'] ?? [];
      for (final s in schedules) {
        final day = _normalizeDay(s['day_of_week']?.toString().trim() ?? '');
        final timeStr = s['time']?.toString().trim();
        if (day.isNotEmpty && timeStr != null) {
          if (!_selectedDays.contains(day)) {
            _selectedDays.add(day);
          }
          final time = _parseTime(timeStr);
          if (time != null) {
            _dayTimes[day] = time;
          }
        }
      }
      setState(() {});
    }
  }

  String _normalizeDay(String day) {
    if (day.isEmpty) return day;
    switch (day) {
      case 'السبت':
        return 'Saturday';
      case 'الأحد':
      case 'الاحد':
        return 'Sunday';
      case 'الإثنين':
      case 'الاثنين':
        return 'Monday';
      case 'الثلاثاء':
        return 'Tuesday';
      case 'الأربعاء':
      case 'الاربعاء':
        return 'Wednesday';
      case 'الخميس':
        return 'Thursday';
      case 'الجمعة':
        return 'Friday';
      default:
        return day;
    }
  }

  String _translateDay(String day) {
    switch (day) {
      case 'Saturday':
        return LocaleKeys.saturday.tr();
      case 'Sunday':
        return LocaleKeys.sunday.tr();
      case 'Monday':
        return LocaleKeys.monday.tr();
      case 'Tuesday':
        return LocaleKeys.tuesday.tr();
      case 'Wednesday':
        return LocaleKeys.wednesday.tr();
      case 'Thursday':
        return LocaleKeys.thursday.tr();
      case 'Friday':
        return LocaleKeys.friday.tr();
      default:
        return day;
    }
  }

  TimeOfDay? _parseTime(String text) {
    if (text.isEmpty) return null;
    try {
      final RegExp re = RegExp(
        r'(\d{1,2}):(\d{2})\s*(AM|PM)?',
        caseSensitive: false,
      );
      final match = re.firstMatch(text);
      if (match != null) {
        int hour = int.parse(match.group(1)!);
        final int minute = int.parse(match.group(2)!);
        final String? period = match.group(3);
        if (period != null) {
          if (period.toUpperCase() == 'PM' && hour < 12) hour += 12;
          if (period.toUpperCase() == 'AM' && hour == 12) hour = 0;
        }
        return TimeOfDay(hour: hour, minute: minute);
      }
    } catch (_) {}
    return null;
  }

  String _formatTime(TimeOfDay time) {
    final int hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final String minute = time.minute.toString().padLeft(2, '0');
    final String period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  Future<void> _pickTime(String day) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _dayTimes[day] ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _dayTimes[day] = picked;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: ResponsiveLayout.isMobile(context)
            ? IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openDrawer(),
              )
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.router.maybePop(),
              ),
        title: Text(
          _isEditing ? LocaleKeys.edit_group.tr() : LocaleKeys.add_group.tr(),
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Group Name ──
                  TextFormField(
                    controller: _nameController,
                    style: textTheme.titleMedium,
                    decoration: InputDecoration(
                      labelText: LocaleKeys.group_name.tr(),
                      prefixIcon: const Icon(Icons.groups),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (v) => v == null || v.isEmpty
                        ? LocaleKeys.required_field.tr()
                        : null,
                  ),
                  SizedBox(height: 32.h),

                  // ── Days Selection (Chips) ──
                  Text(
                    LocaleKeys.day_of_week.tr(),
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _days.map((day) {
                      final isSelected = _selectedDays.contains(day);
                      return FilterChip(
                        label: Text(_translateDay(day)),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedDays.add(day);
                              // Default time if not set
                              _dayTimes[day] ??= const TimeOfDay(
                                hour: 14,
                                minute: 0,
                              );
                            } else {
                              _selectedDays.remove(day);
                              _dayTimes.remove(day);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  if (_selectedDays.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0, left: 12.0),
                      child: Text(
                        LocaleKeys.select_day.tr(),
                        style: TextStyle(
                          color: colorScheme.error,
                          fontSize: 12,
                        ),
                      ),
                    ),

                  SizedBox(height: 24.h),

                  // ── Time Selection for Each Day ──
                  if (_selectedDays.isNotEmpty) ...[
                    Text(
                      LocaleKeys.time.tr(),
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    ..._selectedDays.map((day) {
                      final time = _dayTimes[day];
                      return Padding(
                        padding: EdgeInsets.only(bottom: 8.h),
                        child: Card(
                          elevation: 0,
                          color: colorScheme.surfaceContainerHighest.withValues(
                            alpha: 0.3,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: colorScheme.outlineVariant),
                          ),
                          child: ListTile(
                            leading: Icon(
                              Icons.calendar_today,
                              size: 20,
                              color: colorScheme.primary,
                            ),
                            title: Text(
                              _translateDay(day),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            trailing: TextButton.icon(
                              onPressed: () => _pickTime(day),
                              icon: const Icon(Icons.access_time, size: 18),
                              label: Text(
                                time != null
                                    ? _formatTime(time)
                                    : LocaleKeys.time.tr(),
                              ),
                              style: TextButton.styleFrom(
                                backgroundColor: colorScheme.primaryContainer,
                                foregroundColor: colorScheme.onPrimaryContainer,
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16.w,
                                  vertical: 8.h,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],

                  SizedBox(height: 32.h),

                  // ── Save Button ──
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton.icon(
                      onPressed: _submit,
                      icon: Icon(_isEditing ? Icons.save : Icons.add),
                      label: Text(
                        _isEditing
                            ? LocaleKeys.update.tr()
                            : LocaleKeys.create.tr(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  // ── Student Linking Section (edit mode only) ──
                  if (_isEditing) ...[
                    SizedBox(height: 40.h),
                    const Divider(),
                    SizedBox(height: 16.h),
                    _buildStudentLinkingSection(textTheme, colorScheme),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStudentLinkingSection(
    TextTheme textTheme,
    ColorScheme colorScheme,
  ) {
    return BlocBuilder<GroupCubit, GroupState>(
      builder: (context, state) {
        final students = state.groupStudents;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Icon(Icons.people, color: colorScheme.primary, size: 28),
                SizedBox(width: 8.w),
                Text(
                  LocaleKeys.linked_students.tr(
                    args: [students.length.toString()],
                  ),
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: () => _showAddStudentDialog(colorScheme),
                  icon: const Icon(Icons.person_add, size: 20),
                  label: Text(LocaleKeys.add_students_to_group.tr()),
                ),
              ],
            ),
            SizedBox(height: 16.h),

            if (students.isEmpty)
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(32.r),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.group_off,
                      size: 48,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      LocaleKeys.no_students_in_group.tr(),
                      style: textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: students.map((s) {
                  return InputChip(
                    avatar: CircleAvatar(
                      backgroundColor: colorScheme.primary,
                      child: Text(
                        (s['name']?.toString() ?? '?')[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    label: Text(
                      s['name']?.toString() ?? '',
                      style: textTheme.bodyLarge,
                    ),
                    deleteIcon: const Icon(Icons.close, size: 18),
                    deleteButtonTooltipMessage: LocaleKeys.remove_from_group
                        .tr(),
                    onDeleted: () {
                      context.read<GroupCubit>().unlinkStudentFromGroup(
                        s['id'] as int,
                        widget.id!,
                      );
                    },
                    onPressed: () {
                      context.router.push(
                        StudentDetailRoute(id: s['id'] as int),
                      );
                    },
                  );
                }).toList(),
              ),
          ],
        );
      },
    );
  }

  void _showAddStudentDialog(ColorScheme colorScheme) {
    // Load available students (those not in any group)
    context.read<GroupCubit>().loadAvailableStudents();

    showDialog(
      context: context,
      builder: (dialogContext) {
        final searchController = TextEditingController();

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(LocaleKeys.add_students_to_group.tr()),
              content: SizedBox(
                width: 500,
                height: 400,
                child: Column(
                  children: [
                    TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: LocaleKeys.search_students.tr(),
                        prefixIcon: const Icon(Icons.search),
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (query) {
                        this.context.read<GroupCubit>().loadAvailableStudents(
                          search: query,
                        );
                      },
                    ),
                    SizedBox(height: 12.h),
                    Expanded(
                      child: BlocBuilder<GroupCubit, GroupState>(
                        bloc: this.context.read<GroupCubit>(),
                        builder: (context, state) {
                          final available = state.availableStudents;
                          if (available.isEmpty) {
                            return Center(
                              child: Text(
                                LocaleKeys.no_students_found.tr(),
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            );
                          }
                          return ListView.separated(
                            itemCount: available.length,
                            separatorBuilder: (_, _) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final s = available[index];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: colorScheme.primaryContainer,
                                  child: Text(
                                    (s['name']?.toString() ?? '?')[0]
                                        .toUpperCase(),
                                    style: TextStyle(
                                      color: colorScheme.onPrimaryContainer,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  s['name']?.toString() ?? '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  s['serial_number']?.toString() ?? '',
                                ),
                                trailing: IconButton(
                                  icon: Icon(
                                    Icons.add_circle,
                                    color: colorScheme.primary,
                                  ),
                                  onPressed: () {
                                    this.context
                                        .read<GroupCubit>()
                                        .linkStudentToGroup(
                                          s['id'] as int,
                                          widget.id!,
                                        );
                                  },
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(LocaleKeys.cancel.tr()),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // Custom validation for days
    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(LocaleKeys.select_day.tr()),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    final List<Map<String, dynamic>> schedules = _selectedDays.map((day) {
      final time = _dayTimes[day] ?? const TimeOfDay(hour: 14, minute: 0);
      return {'day_of_week': day, 'time': _formatTime(time)};
    }).toList();

    final Map<String, Object?> data = {
      'name': _nameController.text.trim(),
      'schedules': schedules,
    };

    final GroupCubit cubit = context.read<GroupCubit>();
    if (_isEditing) {
      await cubit.updateGroup(widget.id!, data);
    } else {
      await cubit.createGroup(data);
    }

    if (mounted) {
      context.router.maybePop();
    }
  }
}
