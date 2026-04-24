import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/profile_screen.dart';
import 'services/api_service.dart';

void main() {
  runApp(const SugarNoteApp());
}

class SugarNoteApp extends StatelessWidget {
  const SugarNoteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SugarNote',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8B5E3C),
          primary: const Color(0xFF8B5E3C),
        ),
        fontFamily: 'serif',
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
      routes: {
        '/home':     (_) => const HomeScreen(),
        '/login':    (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
        '/favorites':(_) => const FavoritesScreen(),
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final token = await ApiService.getToken();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}