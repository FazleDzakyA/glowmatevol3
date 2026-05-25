import 'package:flutter/material.dart';

// ✅ IMPORT HALAMAN YANG SUDAH ADA
import '../pages/splash/splash_page.dart';
import '../pages/onboarding/onboarding_page.dart';
import '../pages/auth/login_page.dart';
import '../pages/auth/register_page.dart';
import '../pages/home/home_page.dart';
import '../pages/profile/profile_page.dart';
import '../pages/tracker/tracker_page.dart';
import '../pages/calendar/beauty_calendar_page.dart';
import '../pages/community/community_page.dart';
import '../pages/chatbot/chatbot_page.dart';
import '../pages/scan/face_scan_page.dart';
import '../pages/tutorials/tutorials_page.dart';
import '../pages/settings/settings_page.dart';
import '../pages/badge/badge_screen.dart'; 

// ✅ IMPORT BARU UNTUK FITUR PREMIUM
import '../pages/premium/upgrade_premium_page.dart';

// ✅ IMPORT BARU UNTUK EDIT PROFILE
import '../pages/settings/edit_profile_page.dart'; // Pastikan file ini sudah dibuat!

class AppRoutes {
  // Named Routes Constants
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String profile = '/profile';
  static const String tracker = '/tracker';
  static const String calendar = '/calendar';
  static const String community = '/community';
  static const String chatbot = '/chatbot';
  static const String faceScan = '/facescan';
  static const String tutorials = '/tutorials';
  static const String settings = '/settings';
  static const String badge = '/badge'; 
  
  // ✅ ROUTE BARU
  static const String upgradePremium = '/upgrade-premium';
  static const String editProfile = '/edit-profile'; // ✅ TAMBAHKAN KONSTANTA INI

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/splash':
        return MaterialPageRoute(builder: (_) => const SplashPage());
      case '/onboarding':
        return MaterialPageRoute(builder: (_) => const OnboardingPage());
      case '/login':
        return MaterialPageRoute(builder: (_) => const LoginPage());
      case '/register':
        return MaterialPageRoute(builder: (_) => const RegisterPage());
      case '/home':
        return MaterialPageRoute(builder: (_) => const HomePage());
      case '/profile':
        return MaterialPageRoute(builder: (_) => const ProfilePage());
      case '/tracker':
        return MaterialPageRoute(builder: (_) => const TrackerPage());
      case '/calendar':
        return MaterialPageRoute(builder: (_) => const BeautyCalendarPage());
      case '/community':
        return MaterialPageRoute(builder: (_) => const CommunityPage());
      case '/chatbot':
        return MaterialPageRoute(builder: (_) => const ChatbotPage());
      case '/facescan':
        return MaterialPageRoute(builder: (_) => const FaceScanPage());
      case '/tutorials':
        return MaterialPageRoute(builder: (_) => const TutorialsPage());
      case '/settings':
        return MaterialPageRoute(builder: (_) => const SettingsPage());
      case '/badge':
        return MaterialPageRoute(builder: (_) => const BadgeScreen());
      
      // ✅ CASE BARU UNTUK UPGRADE PREMIUM
      case '/upgrade-premium':
        return MaterialPageRoute(builder: (_) => const UpgradePremiumPage());
      
      // ✅ CASE BARU UNTUK EDIT PROFILE
      case '/edit-profile':
        return MaterialPageRoute(builder: (_) => const EditProfilePage());
      
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }
}