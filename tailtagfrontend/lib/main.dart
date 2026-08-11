import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/tag_provider.dart';
import 'screens/main_screen.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';

void main() {
  runApp(const TailTagApp());
}

class TailTagApp extends StatelessWidget {
  const TailTagApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TagProvider()..loadTags(),
      child: MaterialApp(
        title: 'TailTag',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorSchemeSeed: Colors.teal,
          useMaterial3: true,
        ),
        home: const AuthGate(),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: AuthService().getToken(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final token = snapshot.data;
        if (token != null && token.isNotEmpty) {
          return const MainScreen();
        }
        return const LoginScreen();
      },
    );
  }
}
