import 'package:aphasia_rehab_fe/features/home/home_page.dart';
import 'package:aphasia_rehab_fe/features/practice/practice_page.dart';
import 'package:aphasia_rehab_fe/features/profile/profile_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:aphasia_rehab_fe/colors.dart';

class BottomNavBar extends StatefulWidget {
  const BottomNavBar({super.key});

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const HomePage(),
    const PracticePage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashFactory: NoSplash.splashFactory, // This removes the ripple
          highlightColor:
              Colors.transparent, // This removes the "held down" glow
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          type: BottomNavigationBarType.fixed,
          selectedItemColor:
              AppColors.yellowSecondary, // Color for the active label
          unselectedItemColor:
              AppColors.textSecondary, // Color for the inactive label
          selectedFontSize: 12.0,
          unselectedFontSize: 12.0,
          items: [
            BottomNavigationBarItem(
              icon: SvgPicture.asset(
                'assets/icons/home_icon.svg',
                colorFilter: const ColorFilter.mode(
                  AppColors.textSecondary,
                  BlendMode.srcIn,
                ),
                width: 24,
              ),
              activeIcon: SvgPicture.asset(
                'assets/icons/home_icon.svg',
                colorFilter: const ColorFilter.mode(
                  AppColors.yellowSecondary,
                  BlendMode.srcIn,
                ),
                width: 24,
              ),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: SvgPicture.asset(
                'assets/icons/practice_icon.svg',
                colorFilter: const ColorFilter.mode(
                  AppColors.textSecondary,
                  BlendMode.srcIn,
                ),
                width: 24,
              ),
              activeIcon: SvgPicture.asset(
                'assets/icons/practice_icon.svg',
                colorFilter: const ColorFilter.mode(
                  AppColors.yellowSecondary,
                  BlendMode.srcIn,
                ),
                width: 24,
              ),
              label: 'Practice',
            ),
            BottomNavigationBarItem(
              icon: SvgPicture.asset(
                'assets/icons/profile_icon.svg',
                colorFilter: const ColorFilter.mode(
                  AppColors.textSecondary,
                  BlendMode.srcIn,
                ),
                width: 24,
              ),
              activeIcon: SvgPicture.asset(
                'assets/icons/profile_icon.svg',
                colorFilter: const ColorFilter.mode(
                  AppColors.yellowSecondary,
                  BlendMode.srcIn,
                ),
                width: 24,
              ),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
