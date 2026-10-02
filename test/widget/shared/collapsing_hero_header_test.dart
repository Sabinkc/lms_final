import 'package:cloud_lms/shared/widgets/collapsing_hero_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the full banner, then collapses into a one-line greeting bar on scroll', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: CustomScrollView(
          slivers: [
            const CollapsingHeroHeader(greeting: 'Good Morning,', name: 'Sabin', subtitle: 'Here is today.'),
            SliverToBoxAdapter(child: Container(height: 2000)),
          ],
        ),
      ),
    ));
    expect(find.text('Here is today.'), findsOneWidget);
    expect(find.text('Sabin'), findsOneWidget);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
    await tester.pump();

    expect(find.text('Here is today.'), findsNothing);
    expect(find.textContaining('Sabin', findRichText: true), findsOneWidget);
    // Still pinned in the slim bar at the very top.
    final greeting = tester.getRect(find.textContaining('Sabin', findRichText: true));
    expect(greeting.bottom, lessThan(60));
  });
}
