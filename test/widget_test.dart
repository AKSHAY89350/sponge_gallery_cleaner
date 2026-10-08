import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sponge_gallery_cleaner/main.dart';
import 'package:sponge_gallery_cleaner/features/gallery_core/providers/gallery_provider.dart';

void main() {
  testWidgets('App launches and shows loading or permission screen',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => GalleryProvider(),
        child: const SpongeApp(),
      ),
    );
    // App should render without crashing
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
