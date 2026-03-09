import 'package:aphasia_rehab_fe/features/session/managers/dashboard_manager.dart';
import 'package:aphasia_rehab_fe/features/session/managers/hint_manager.dart';
import 'package:aphasia_rehab_fe/features/session/managers/scenario_sim_manager.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'common/bottom_nav_bar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  await dotenv.load(fileName: ".env");
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ScenarioSimManager()),
        ChangeNotifierProxyProvider<ScenarioSimManager, HintManager>(
          create: (context) => context.read<ScenarioSimManager>().hintManager,
          update: (_, scenario, __) => scenario.hintManager,
        ),
        ChangeNotifierProxyProvider<ScenarioSimManager, DashboardManager>(
          create: (context) =>
              context.read<ScenarioSimManager>().dashboardManager,
          update: (_, scenario, __) => scenario.dashboardManager,
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aphasia Rehab',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        textTheme: GoogleFonts.lexendTextTheme(
          const TextTheme(
            titleLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            bodyMedium: TextStyle(fontSize: 16),
            bodyLarge: TextStyle(fontSize: 18),
            bodySmall: TextStyle(fontSize: 14),
          ),
        ),
      ),
      // Point home to your new feature page
      home: const BottomNavBar(),
    );
  }
}
