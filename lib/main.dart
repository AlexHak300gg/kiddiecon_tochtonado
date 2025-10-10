import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';

import 'screens/role_selection_screen.dart';
import 'firebase_options.dart'; // <-- этот файл создаётся автоматически после flutterfire configure

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Инициализация Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'KiddieCoin',
      theme: ThemeData(
        textTheme: GoogleFonts.nunitoTextTheme(),
        primarySwatch: Colors.blue,
      ),
      home: const RoleSelectionScreen(), // экран выбора роли
    );
  }
}
