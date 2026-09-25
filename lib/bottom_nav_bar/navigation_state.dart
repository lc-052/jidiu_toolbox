import 'package:flutter/material.dart';

// lib/bottom_nav_bar/navigation_state.dart
abstract class NavItem {
  final String title;
  final IconData icon;
  final Widget page;

  const NavItem({required this.title, required this.icon, required this.page});
}
