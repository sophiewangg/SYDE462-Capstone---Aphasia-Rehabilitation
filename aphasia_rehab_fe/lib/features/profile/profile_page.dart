import 'package:flutter/material.dart';
import 'package:aphasia_rehab_fe/colors.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: AppColors.background);
  }
}
