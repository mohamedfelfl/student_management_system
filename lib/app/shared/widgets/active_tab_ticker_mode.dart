import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart';

/// Pauses the animations of a tab page while another tab is selected.
///
/// [AutoTabsRouter] keeps visited tabs alive in an [IndexedStack], which hides
/// them without muting their tickers, so a repeating animation (or a spinner)
/// in a hidden tab keeps scheduling frames for the rest of the session.
class ActiveTabTickerMode extends StatelessWidget {
  final Widget child;

  const ActiveTabTickerMode({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final RouteData routeData = context.routeData;
    final RoutingController parent = routeData.router;
    // Pushed as a stand-alone page rather than shown as a tab.
    if (parent is! TabsRouter) return child;

    return ListenableBuilder(
      listenable: parent,
      builder: (BuildContext context, Widget? child) => TickerMode(
        enabled: parent.current.name == routeData.name,
        child: child!,
      ),
      child: child,
    );
  }
}
