import 'screens/home_screen.dart';

import 'package:flutter/material.dart';

void main() {
  runApp(const BudgetApp());
}

class BudgetApp extends StatelessWidget {
  const BudgetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Budżet Domowy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 55, 55, 58),
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
