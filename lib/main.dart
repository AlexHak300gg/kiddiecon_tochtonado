import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';

import 'screens/app_security_wrapper.dart';
import 'firebase_options.dart'; // <-- этот файл создаётся автоматически после flutterfire configure
import 'services/daily_interest_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Инициализация Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ✅ Настройка фонового начисления процентов (AlarmManager + таймер)
  await DailyInterestService.initialize();

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
      home: const AppSecurityWrapper(), // экран безопасности
    );
  }
}
