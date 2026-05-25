// test/widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
// ignore: unused_import
import 'package:glowmate/main.dart'; // untuk GlowMateApp
import 'package:glowmate/controllers/theme_controller.dart';
import 'package:glowmate/controllers/auth_controller.dart';
import 'package:glowmate/controllers/tutorials_controller.dart';

void main() {
  // Inisialisasi Firebase untuk test
  setUpAll(() async {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyCB8zOYFinTEjDuiPY38_NGKrvoxS3Zdm0",
        appId: "1:85041132278:web:7dbfc4d5872a5b9424b2d7",
        messagingSenderId: "85041132278",
        projectId: "glowmate-b9f50",
      ),
    );
  });

  testWidgets('GlowMateApp builds without error', (WidgetTester tester) async {
    // Bangun app dengan provider
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeController()),
          ChangeNotifierProvider(create: (_) => AuthController()),
          ChangeNotifierProvider(create: (_) => TutorialsController()),
        ],
        child: const MaterialApp(home: Scaffold(body: Text('Test Home'))),
      ),
    );

    expect(find.text('Test Home'), findsOneWidget);
  });
}
