import 'package:cloud_lms/shared/widgets/hero_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('HeroBanner shows greeting, name, and subtitle', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: HeroBanner(
            greeting: 'Good Morning,',
            name: 'Amy Student',
            subtitle: "Here's what's happening today.",
            color: Colors.teal,
            trailingIcon: Icons.school,
          ),
        ),
      ),
    );

    expect(find.text('Good Morning,'), findsOneWidget);
    expect(find.text('Amy Student'), findsOneWidget);
    expect(find.text("Here's what's happening today."), findsOneWidget);
    expect(find.byIcon(Icons.school), findsOneWidget);
  });
}
