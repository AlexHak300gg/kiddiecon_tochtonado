import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // создаётся автоматически после flutterfire configure

import 'screens/role_selection_screen.dart';
import 'screens/preim_screen.dart';
import 'screens/registration_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔹 Инициализация Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 🔹 Проверка сохранённой роли (SharedPreferences)
  final prefs = await SharedPreferences.getInstance();
  final savedRole = prefs.getString('userRole');

  runApp(MyApp(initialRole: savedRole));
}

class MyApp extends StatelessWidget {
  final String? initialRole;

  const MyApp({super.key, this.initialRole});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KiddieCoin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: GoogleFonts.nunitoTextTheme(),
      ),
      // 🔹 Если роль не выбрана — показываем экран выбора
      // 🔹 Если уже выбрана — открываем сразу экран преимуществ
      home: initialRole == null
          ? const RoleSelectionScreen()
          : PreimScreen(role: initialRole!),
      routes: {
        '/role': (context) => const RoleSelectionScreen(),
        '/preim': (context) => const PreimScreen(role: 'child'),
        '/register': (context) => const RegistrationScreen(),
      },
    );
  }
}
