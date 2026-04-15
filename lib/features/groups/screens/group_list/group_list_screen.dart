import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../../app/shared/widgets/responsive_layout.dart';
import '../../../../app/router/app_router.gr.dart';
import '../../../../generated/locale_keys.g.dart';
import '../../cubits/group_cubit.dart';

@RoutePage()
class GroupListScreen extends StatefulWidget {
  const GroupListScreen({super.key});

  @override
  State<GroupListScreen> createState() => _GroupListScreenState();
}

class _GroupListScreenState extends State<GroupListScreen> {
  @override
  void initState() {
    super.initState();
    context.read<GroupCubit>().loadGroups();
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          LocaleKeys.groups.tr(),
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
        leading: ResponsiveLayout.isMobile(context)
            ? IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openDrawer(),
              )
            : null,
      ),
      body: BlocBuilder<GroupCubit, GroupState>(
        builder: (BuildContext context, GroupState state) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!ResponsiveLayout.isMobile(context))
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          LocaleKeys.groups.tr(),
                          style: textTheme.headlineLarge,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => context.router.push(GroupFormRoute()),
                        icon: const Icon(Icons.add),
                        label: Text(LocaleKeys.add_group.tr()),
                      ),
                    ],
                  ),
                const SizedBox(height: 16),
                if (state.isLoading)
                  const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (state.groups.isEmpty)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.groups_outlined,
                            size: 64,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            LocaleKeys.no_groups_yet.tr(),
                            style: textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final width = constraints.maxWidth;
                          final crossAxisCount = width > 1200
                              ? 3
                              : width > 800
                              ? 2
                              : 1;
                          final itemWidth =
                              (width - (crossAxisCount - 1) * 16) /
                              crossAxisCount;

                          return Wrap(
                            spacing: 16,
                            runSpacing: 16,
                            children: state.groups.map((g) {
                              return SizedBox(
                                width: itemWidth,
                                child: Card(
                                  child: InkWell(
                                    onTap: () {
                                      context.router.push(
                                        GroupFormRoute(id: g['id'] as int),
                                      );
                                    },
                                    borderRadius: BorderRadius.circular(28),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.groups,
                                                color: colorScheme.primary,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  g['name']?.toString() ?? '',
                                                  style: textTheme.titleMedium,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              PopupMenuButton<String>(
                                                itemBuilder: (BuildContext _) =>
                                                    <PopupMenuEntry<String>>[
                                                      PopupMenuItem<String>(
                                                        value: 'edit',
                                                        child: Text(
                                                          LocaleKeys.edit.tr(),
                                                        ),
                                                      ),
                                                      PopupMenuItem<String>(
                                                        value: 'delete',
                                                        child: Text(
                                                          LocaleKeys.delete
                                                              .tr(),
                                                        ),
                                                      ),
                                                    ],
                                                onSelected: (String v) {
                                                  if (v == 'edit') {
                                                    context.router.push(
                                                      GroupFormRoute(
                                                        id: g['id'] as int,
                                                      ),
                                                    );
                                                  } else {
                                                    context
                                                        .read<GroupCubit>()
                                                        .deleteGroup(
                                                          g['id'] as int,
                                                        );
                                                  }
                                                },
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          if (g['schedules'] != null &&
                                              (g['schedules'] as List)
                                                  .isNotEmpty)
                                            Wrap(
                                              spacing: 8,
                                              runSpacing: 4,
                                              crossAxisAlignment:
                                                  WrapCrossAlignment.center,
                                              children: [
                                                ...(g['schedules'] as List).map((
                                                  s,
                                                ) {
                                                  return Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 4,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: colorScheme
                                                          .surfaceContainerHighest,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            6,
                                                          ),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Icon(
                                                          Icons.calendar_today,
                                                          size: 10,
                                                          color: colorScheme
                                                              .primary,
                                                        ),
                                                        const SizedBox(
                                                          width: 4,
                                                        ),
                                                        Text(
                                                          '${s['day_of_week']} ${s['time']}',
                                                          style: textTheme
                                                              .labelSmall
                                                              ?.copyWith(
                                                                fontSize: 10,
                                                              ),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                }),
                                              ],
                                            ),
                                          const SizedBox(height: 16),
                                          Row(
                                            children: [
                                              const Spacer(),
                                              Chip(
                                                label: Text(
                                                  LocaleKeys.students_count.tr(
                                                    args: [
                                                      (g['student_count'] ?? 0)
                                                          .toString(),
                                                    ],
                                                  ),
                                                ),
                                                visualDensity:
                                                    VisualDensity.compact,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
