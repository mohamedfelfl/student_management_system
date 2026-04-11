import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../../../auth/models/user.dart';
import '../../../auth/cubits/auth_cubit.dart';
import '../../../groups/cubits/group_cubit.dart';
import '../../../students/cubits/student_cubit.dart';
import '../../cubits/notes_cubit.dart';
import '../../cubits/notes_state.dart';
import '../../models/note.dart';

class NotesDeliveryTab extends StatefulWidget {
  const NotesDeliveryTab({super.key});

  @override
  State<NotesDeliveryTab> createState() => _NotesDeliveryTabState();
}

class _NotesDeliveryTabState extends State<NotesDeliveryTab> {
  int? _selectedGroupId;

  @override
  void initState() {
    super.initState();
    context.read<GroupCubit>().loadGroups();
    context.read<StudentCubit>().loadStudents();
  }

  @override
  void dispose() {
    context.read<NotesCubit>().clearPendingDeliveries();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = context.read<AuthCubit>().state.maybeWhen(
          authenticated: (u) => u,
          orElse: () => null,
        );
    final canManageNodes = user?.can(UserPermission.manageNotes) ?? false;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          // Filter Section
          Container(
            color: theme.colorScheme.surface,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Note Selection
                BlocBuilder<NotesCubit, NotesState>(
                  builder: (context, state) {
                    return DropdownButtonFormField<int>(
                      key: ValueKey('note_selection_${state.selectedNoteId}'),
                      initialValue: state.selectedNoteId,
                      decoration: InputDecoration(
                        labelText: LocaleKeys.select_note.tr(),
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.menu_book),
                      ),
                      items: state.notes.map((Note note) {
                        return DropdownMenuItem<int>(
                          value: note.id,
                          child: Text('${note.name} - ${note.price} ${LocaleKeys.currency_symbol.tr()}'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        context.read<NotesCubit>().selectNoteForDelivery(val);
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),
                // Group / Search Selection
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: BlocBuilder<GroupCubit, GroupState>(
                        builder: (context, groupState) {
                          return DropdownButtonFormField<int?>(
                            key: ValueKey('group_selection_$_selectedGroupId'),
                            initialValue: _selectedGroupId,
                            decoration: InputDecoration(
                              labelText: LocaleKeys.school_group.tr(),
                              border: const OutlineInputBorder(),
                            ),
                            items: [
                              DropdownMenuItem<int?>(
                                value: null,
                                child: Text(LocaleKeys.all_students.tr()),
                              ),
                              ...groupState.groups.map((g) {
                                return DropdownMenuItem<int?>(
                                  value: g['id'] as int,
                                  child: Text(g['name'] as String),
                                );
                              }),
                            ],
                            onChanged: (val) {
                              setState(() => _selectedGroupId = val);
                              context.read<StudentCubit>().filterByGroup(val);
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: TextField(
                        decoration: InputDecoration(
                          labelText: LocaleKeys.search_hint.tr(),
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.search),
                        ),
                        onChanged: (val) {
                          context.read<StudentCubit>().search(val);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Students List
          Expanded(
            child: BlocBuilder<NotesCubit, NotesState>(
              builder: (context, noteState) {
                if (noteState.selectedNoteId == null) {
                  return Center(
                    child: Text(
                      'Please select a note first.',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                }

                if (noteState.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                return BlocListener<NotesCubit, NotesState>(
                  listenWhen: (prev, curr) => prev.lastSaveTimestamp != curr.lastSaveTimestamp && curr.lastSaveTimestamp != null,
                  listener: (context, state) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(LocaleKeys.delivery_success.tr()),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: BlocBuilder<StudentCubit, StudentState>(
                    builder: (context, studentState) {
                      if (studentState.isLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final visibleStudentIds = studentState.students.map((s) => s['id'] as int).toList();
                      final allPending = visibleStudentIds.every((id) => noteState.pendingDeliveries[id] == true);

                      return Column(
                        children: [
                          CheckboxListTile(
                            controlAffinity: ListTileControlAffinity.leading,
                            value: allPending,
                            onChanged: canManageNodes
                                ? (bool? val) {
                                    if (val != null) {
                                      context.read<NotesCubit>().updateBatchDeliveryLocal(visibleStudentIds, val);
                                    }
                                  }
                                : null,
                            title: Text(
                              LocaleKeys.select_deselect_all.tr(),
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            tileColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                          ),
                          const Divider(height: 1),
                          Expanded(
                            child: ListView.builder(
                              itemCount: studentState.students.length,
                              itemBuilder: (context, index) {
                                final student = studentState.students[index];
                                final studentId = student['id'] as int;
                                final isPending = noteState.pendingDeliveries[studentId] == true;
                                final isDelivered = noteState.currentDeliveries[studentId] == true;

                                return CheckboxListTile(
                                  controlAffinity: ListTileControlAffinity.leading,
                                  value: isPending,
                                  onChanged: canManageNodes
                                      ? (bool? val) {
                                          if (val != null) {
                                            context.read<NotesCubit>().updateDeliveryStatusLocal(studentId, val);
                                          }
                                        }
                                      : null,
                                  title: Text(student['name'] as String),
                                  subtitle: Text(student['group_name']?.toString() ?? LocaleKeys.no_group.tr()),
                                  secondary: Text(
                                    isDelivered ? LocaleKeys.delivered.tr() : LocaleKeys.not_delivered.tr(),
                                    style: theme.textTheme.labelMedium?.copyWith(
                                      color: isDelivered 
                                          ? Colors.green 
                                          : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                                      fontWeight: isDelivered ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          if (canManageNodes && noteState.selectedNoteId != null)
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton.icon(
                                  onPressed: noteState.isLoading 
                                      ? null 
                                      : () => context.read<NotesCubit>().saveDeliveries(),
                                  icon: noteState.isLoading 
                                      ? const SizedBox(
                                          width: 20, 
                                          height: 20, 
                                          child: CircularProgressIndicator(strokeWidth: 2)
                                        )
                                      : const Icon(Icons.save),
                                  label: Text(LocaleKeys.save_all.tr().toUpperCase()),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: theme.colorScheme.primary,
                                    foregroundColor: theme.colorScheme.onPrimary,
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
