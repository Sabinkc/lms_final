import 'package:cloud_lms/shared/widgets/pull_to_refresh.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child, VoidCallback onRefresh) => MaterialApp(
      home: Scaffold(
        body: PullToRefresh(
          onRefresh: () async => onRefresh(),
          child: child,
        ),
      ),
    );

void main() {
  testWidgets('pulling down on a non-scrolling body (empty/error state) refreshes', (tester) async {
    var refreshed = 0;
    await tester.pumpWidget(_host(const Center(child: Text('Nothing here yet')), () => refreshed++));

    await tester.fling(find.text('Nothing here yet'), const Offset(0, 400), 1000);
    await tester.pumpAndSettle();

    expect(refreshed, 1);
  });

  testWidgets('pulling down on a body with its own list refreshes', (tester) async {
    var refreshed = 0;
    await tester.pumpWidget(_host(
      ListView(children: [for (var i = 0; i < 50; i++) ListTile(title: Text('Row $i'))]),
      () => refreshed++,
    ));

    await tester.fling(find.text('Row 2'), const Offset(0, 400), 1000);
    await tester.pumpAndSettle();

    expect(refreshed, 1);
  });

  testWidgets('a body with a fixed header and an expanded list still refreshes from the list', (tester) async {
    var refreshed = 0;
    await tester.pumpWidget(_host(
      Column(
        children: [
          const Text('Header'),
          Expanded(child: ListView(children: [for (var i = 0; i < 50; i++) ListTile(title: Text('Row $i'))])),
        ],
      ),
      () => refreshed++,
    ));

    await tester.fling(find.text('Row 2'), const Offset(0, 400), 1000);
    await tester.pumpAndSettle();

    expect(refreshed, 1);
  });
}
