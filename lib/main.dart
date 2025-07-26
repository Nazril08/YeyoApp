import 'package:flutter/material.dart';
import 'package:yeyo/pages/splash_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nzr App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF7B61FF), 
        scaffoldBackgroundColor: const Color(0xFF1A1A2E), 
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: Colors.white70),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF2E2E48),
          elevation: 4,
          shadowColor: Colors.black.withOpacity(0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.white),
          headlineMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          titleMedium: TextStyle(color: Colors.white70),
          labelLarge: TextStyle(color: Colors.white),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF7B61FF),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        )),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF7B61FF),
          foregroundColor: Colors.white,
        ),
        iconTheme: const IconThemeData(
          color: Colors.white70,
        ),
        textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
          foregroundColor: Colors.white70,
        )),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF2E2E48),
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        )
      ),
      themeMode: ThemeMode.dark, // Force dark mode
      home: const SplashPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
