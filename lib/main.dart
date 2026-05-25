import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // ✅ IMPORT FLUTTER DOTENV

// ✅ 1. IMPORT FILE CONFIG INI (Hasil dari flutterfire configure)
import 'firebase_options.dart'; 

// ✅ Import Controller
import 'controllers/auth_controller.dart';
import 'controllers/theme_controller.dart';
import 'controllers/tutorials_controller.dart'; 

// ✅ Import Routes
import 'routes/app_routes.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // ✅ 2. INITIALIZE FIREBASE
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ✅ 3. BUAT INSTANCE AUTHCONTROLLER & INIT DATA USER
  final authController = AuthController();
  await authController.init(); // Memuat data user dari Local Storage jika ada

  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    print("File .env tidak ditemukan (mungkin di environment CI/CD). Menggunakan Env Var sistem.");
  }

  runApp(MyApp(authController: authController));
}

class MyApp extends StatelessWidget {
  final AuthController authController;

  const MyApp({super.key, required this.authController});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // ✅ GUNAKAN INSTANCE YANG SUDAH DI-INIT DI MAIN
        ChangeNotifierProvider.value(value: authController),
        
        ChangeNotifierProvider(create: (_) => ThemeController()),
        ChangeNotifierProvider(create: (_) => TutorialsController()), 
      ],
      child: Consumer<ThemeController>(
        builder: (context, themeCtrl, child) {
          return MaterialApp(
            title: 'GlowMate',
            debugShowCheckedModeBanner: false,
            
            themeMode: themeCtrl.themeMode, 
            
            // ✅ TEMA LIGHT MODE
            theme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.light,
              primaryColor: const Color(0xFFF8A9BB), 
              scaffoldBackgroundColor: Colors.white, 
              cardColor: Colors.white, 
              
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black87,
                elevation: 0,
              ),
              
              textTheme: const TextTheme(
                bodyLarge: TextStyle(color: Colors.black87),
                bodyMedium: TextStyle(color: Colors.black54),
              ),
              
              iconTheme: const IconThemeData(color: Colors.black87),
            ),
            
            // ✅ TEMA DARK MODE
            darkTheme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.dark,
              primaryColor: const Color(0xFFF8A9BB),
              scaffoldBackgroundColor: const Color(0xFF121212), 
              cardColor: const Color(0xFF1E1E2E), 
              
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              
              textTheme: const TextTheme(
                bodyLarge: TextStyle(color: Colors.white),
                bodyMedium: TextStyle(color: Colors.white70),
              ),
              
              iconTheme: const IconThemeData(color: Colors.white),
            ),
            
            initialRoute: AppRoutes.splash, 
            onGenerateRoute: AppRoutes.generateRoute,
          );
        },
      ),
    );
  }
}