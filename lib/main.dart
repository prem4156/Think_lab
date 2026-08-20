import 'package:flutter/material.dart';
import 'screens/dashboard_screen.dart';
import 'screens/login_screen.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ThinkLabApp());
}

class ThinkLabApp extends StatelessWidget {
  const ThinkLabApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Think Lab - Mind Gym',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.pastelTheme,
      home: FutureBuilder<bool>(
        future: StorageService.instance.isLoggedIn(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: AppTheme.bgDark,
              body: Center(
                child: CircularProgressIndicator(color: AppTheme.primaryNeon),
              ),
            );
          }
          if (snapshot.data == true) {
            return const DashboardScreen();
          }
          return const LoginScreen();
        },
      ),
    );
  }
}
