import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../generated/locale_keys.g.dart';

/// About & system information card.
class AboutSection extends StatelessWidget {
  const AboutSection({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return _buildSettingsCard(context, [
      ListTile(
        leading: _buildLeading(context, Icons.apps),
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
        leading: _buildLeading(context, Icons.storage),
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
        leading: _buildLeading(context, Icons.person),
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
      ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (colorScheme.primary).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.article, color: colorScheme.primary, size: 20),
        ),
        title: Text(
          LocaleKeys.open_source_licenses.tr(),
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(LocaleKeys.open_source_licenses_desc.tr()),
        trailing: Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
        onTap: () => showLicensePage(
          context: context,
          applicationName: LocaleKeys.app_title.tr(),
          applicationVersion: '1.0.0',
        ),
      ),
    ]);
  }

  Widget _buildLeading(BuildContext context, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: colorScheme.primary, size: 20),
    );
  }

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
}
