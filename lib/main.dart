import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/tag_provider.dart';
import 'screens/home_screen.dart';

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
        home: const HomeScreen(),
      ),
    );
  }
}