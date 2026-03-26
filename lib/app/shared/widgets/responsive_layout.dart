import 'package:flutter/material.dart';

/// Responsive layout wrapper that adapts between mobile and desktop.
///
/// On desktop (≥ 900px): Shows a navigation rail on the side + expanded content.
/// On mobile (< 900px): Full-width content with drawer navigation.
class ResponsiveLayout extends StatelessWidget {
  final Widget mobileBody;
  final Widget? desktopBody;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<NavigationRailDestination> destinations;
  final Widget? leading;

  static const double breakpoint = 900;

  const ResponsiveLayout({
    super.key,
    required this.mobileBody,
    this.desktopBody,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
    this.leading,
    this.trailing,
  });

  final Widget? trailing;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= breakpoint;

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < breakpoint;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    if (width >= breakpoint) {
      return Row(
        children: [
          NavigationRail(
            selectedIndex: selectedIndex,
            onDestinationSelected: onDestinationSelected,
            destinations: destinations,
            labelType: width >= 1200
                ? NavigationRailLabelType.none
                : NavigationRailLabelType.all,
            selectedLabelTextStyle: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
            unselectedLabelTextStyle: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            leading: leading,
            trailing: trailing,
            extended: width >= 1200,
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: desktopBody ?? mobileBody),
        ],
      );
    }

    return mobileBody;
  }
}
