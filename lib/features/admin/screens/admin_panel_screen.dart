import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../generated/locale_keys.g.dart';

import '../../../app/router/app_router.gr.dart';
import '../../auth/models/user.dart';
import '../../../app/shared/widgets/responsive_layout.dart';
import '../cubits/admin_cubit.dart';

@RoutePage()
class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  @override
  void initState() {
    super.initState();
    context.read<AdminCubit>().loadUsers();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return BlocBuilder<AdminCubit, AdminState>(
      builder: (BuildContext context, AdminState state) {
        return Scaffold(
          appBar: ResponsiveLayout.isMobile(context)
              ? AppBar(
                  leading: IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: () => Scaffold.of(context).openDrawer(),
                  ),
                  title: Text(LocaleKeys.admin_panel.tr()),
                  centerTitle: true,
                )
              : null,
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(LocaleKeys.admin_panel.tr(), style: textTheme.headlineLarge),
                          const SizedBox(height: 4),
                          Text(
                            LocaleKeys.manage_users_permissions.tr(),
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => context.router.push(UserFormRoute()),
                      icon: const Icon(Icons.person_add),
                      label: Text(LocaleKeys.add_user.tr()),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (state.isLoading)
                  const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else
                  Expanded(
                    child: Card(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: state.users.length,
                        itemBuilder: (BuildContext context, int index) {
                          final User user = state.users[index];
                          return _UserTile(user: user);
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _UserTile extends StatelessWidget {
  final User user;

  const _UserTile({required this.user});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: user.role == UserRole.admin
                ? colorScheme.primaryContainer
                : colorScheme.secondaryContainer,
            child: Icon(
              user.role == UserRole.admin
                  ? Icons.admin_panel_settings
                  : Icons.person,
              color: user.role == UserRole.admin
                  ? colorScheme.primary
                  : colorScheme.secondary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.username, style: textTheme.titleMedium),
                const SizedBox(height: 2),
                Wrap(
                  spacing: 4,
                  children: [
                    Chip(
                      label: Text(
                        user.role == UserRole.admin ? LocaleKeys.admin_role.tr() : LocaleKeys.user_role.tr(),
                        style: textTheme.labelSmall,
                      ),
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                    ...user.permissions
                        .take(3)
                        .map(
                          (p) => Chip(
                            label: Text(p.name, style: textTheme.labelSmall),
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                    if (user.permissions.length > 3)
                      Chip(
                        label: Text(
                          '+${user.permissions.length - 3}',
                          style: textTheme.labelSmall,
                        ),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            itemBuilder: (BuildContext _) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(value: 'edit', child: Text(LocaleKeys.edit.tr())),
              PopupMenuItem<String>(
                value: 'delete',
                child: Text(LocaleKeys.delete.tr()),
              ),
            ],
            onSelected: (String value) {
              if (value == 'edit') {
                context.router.push(UserFormRoute(id: user.id));
              } else if (value == 'delete') {
                _confirmDelete(context, user);
              }
            },
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, User user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(LocaleKeys.delete_user.tr()),
        content: Text(LocaleKeys.confirm_delete_user.tr(args: [user.username])),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(LocaleKeys.cancel.tr()),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<AdminCubit>().deleteUser(user.id!);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(LocaleKeys.delete.tr()),
          ),
        ],
      ),
    );
  }
}
