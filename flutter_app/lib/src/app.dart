import 'package:flutter/material.dart';
import 'features/auth/auth_gate.dart';

class IrkopCellApp extends StatelessWidget {
  const IrkopCellApp({super.key});

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF12325C);
    return MaterialApp(
      title: 'IRKOP Konter',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: navy,
          primary: navy,
          secondary: const Color(0xFF4F8CFF),
          surface: const Color(0xFFF8FAFD),
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAFD),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: Color(0xFFF8FAFD),
          surfaceTintColor: Colors.transparent,
          titleTextStyle: TextStyle(
            color: Color(0xFF16243A),
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          margin: EdgeInsets.zero,
          color: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: const BorderSide(color: Color(0xFFE7ECF3)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE0E7F0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE0E7F0)),
          ),
        ),
        navigationBarTheme: const NavigationBarThemeData(
          height: 70,
          indicatorColor: Color(0xFFE3ECFF),
          labelTextStyle: WidgetStatePropertyAll(
            TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ),
      ),
      home: const AuthGate(),
      builder: (context, child) => ScrollConfiguration(
        behavior: const _NoGlowScrollBehavior(),
        child: child!,
      ),
    );
  }
}

class _NoGlowScrollBehavior extends MaterialScrollBehavior {
  const _NoGlowScrollBehavior();
  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => child;
}
