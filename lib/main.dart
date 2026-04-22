import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'providers/customer_provider.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://qszapumpeaovkjudzrdn.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFzemFwdW1wZWFvdmtqdWR6cmRuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY4MzUyNjQsImV4cCI6MjA5MjQxMTI2NH0.Z95kmbCdfaX0eiIekzeeo8rBf5TQ5bVIL0Ucxeout4g',
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CustomerProvider()),
      ],
      child: const TailorApp(),
    ),
  );
}

class TailorApp extends StatelessWidget {
  const TailorApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tailor Measurements App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const HomeScreen(),
    );
  }
}
