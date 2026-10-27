import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/config.dart';
import 'core/storage.dart';
import 'core/theme.dart';
import 'models/user.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home_nav.dart';
import 'screens/splash/animated_parking_splash.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set clean light system navigation & status bar on Android
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  await AppConfig.init();
  final initialUser = await StorageService.getUser();

  runApp(ParkMeApp(initialUser: initialUser));
}

class ParkMeApp extends StatelessWidget {
  final UserSession? initialUser;

  const ParkMeApp({super.key, this.initialUser});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ParkMe',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: AnimatedParkingSplash(initialUser: initialUser),
      routes: {
        '/home': (_) => const HomeNav(),
        '/login': (_) => const LoginScreen(),
      },
    );
  }
}
