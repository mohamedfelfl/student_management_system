import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import '../../../generated/locale_keys.g.dart';
import 'tabs/notes_crud_tab.dart';
import 'tabs/notes_delivery_tab.dart';
import '../../../app/shared/widgets/active_tab_ticker_mode.dart';

@RoutePage()
class NotesScreen extends StatelessWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      ActiveTabTickerMode(child: Builder(builder: _buildTabContent));

  Widget _buildTabContent(BuildContext context) {
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: context.router.canPop() ? Text(LocaleKeys.study_notes.tr()) : null,
          bottom: TabBar(
            indicatorColor: theme.colorScheme.primary,
            labelColor: theme.colorScheme.onSurface,
            unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
            tabs: [
              Tab(
                icon: const Icon(Icons.menu_book),
                text: LocaleKeys.manage_notes.tr(),
              ),
              Tab(
                icon: const Icon(Icons.assignment_turned_in),
                text: LocaleKeys.notes_delivery.tr(),
              ),
            ],
          ),
        ),
        body: const TabBarView(children: [NotesCrudTab(), NotesDeliveryTab()]),
      ),
    );
  }
}
