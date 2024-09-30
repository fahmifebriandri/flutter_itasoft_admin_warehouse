import 'package:flutter/material.dart';

import 'screen/home/home_screen.dart';
import 'screen/login/login_screen.dart';
import 'splash_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // Definisikan route di sini
      initialRoute: '/',  // Mulai dari halaman SplashScreen
      routes: {
        '/': (context) => const SplashScreen(), // Halaman splash
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}
