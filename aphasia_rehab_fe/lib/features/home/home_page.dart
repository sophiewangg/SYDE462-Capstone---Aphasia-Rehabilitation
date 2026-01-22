import 'package:aphasia_rehab_fe/common/continue_session.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            mainAxisAlignment: .center,
            crossAxisAlignment: .start,
            children: [
              Text(
                "Welcome back, Kelly",
                style: Theme.of(context).textTheme.titleLarge,
              ),
              ContinueSession(),
            ],
          ),
        ),
      ),
    );
  }
}
