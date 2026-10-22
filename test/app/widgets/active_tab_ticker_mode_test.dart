import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:student_management_system/app/shared/widgets/active_tab_ticker_mode.dart';

final Map<String, bool> tickerEnabled = {};
late TabsRouter tabsRouter;

Widget _tab(String name) => ActiveTabTickerMode(
      child: Builder(
        builder: (BuildContext context) {
          tickerEnabled[name] = TickerMode.valuesOf(context).enabled;
          return Text(name);
        },
      ),
    );

class _TestRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
        AutoRoute(
          path: '/',
          initial: true,
          page: PageInfo(
            'Shell',
            builder: (_) => AutoTabsRouter(
              routes: const [PageRouteInfo('TabA'), PageRouteInfo('TabB')],
              builder: (BuildContext context, Widget child) {
                tabsRouter = AutoTabsRouter.of(context);
                return child;
              },
            ),
          ),
          children: [
            AutoRoute(
              path: 'a',
              initial: true,
              page: PageInfo('TabA', builder: (_) => _tab('TabA')),
            ),
            AutoRoute(
              path: 'b',
              page: PageInfo('TabB', builder: (_) => _tab('TabB')),
            ),
          ],
        ),
      ];
}

void main() {
  testWidgets('only the selected tab keeps its tickers enabled', (
    WidgetTester tester,
  ) async {
    final router = _TestRouter();
    await tester.pumpWidget(MaterialApp.router(routerConfig: router.config()));
    await tester.pumpAndSettle();

    expect(tickerEnabled['TabA'], isTrue);

    tabsRouter.setActiveIndex(1);
    await tester.pumpAndSettle();
    expect(tickerEnabled['TabA'], isFalse);
    expect(tickerEnabled['TabB'], isTrue);

    tabsRouter.setActiveIndex(0);
    await tester.pumpAndSettle();
    expect(tickerEnabled['TabA'], isTrue);
    expect(tickerEnabled['TabB'], isFalse);
  });
}
