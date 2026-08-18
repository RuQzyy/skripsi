import 'package:flutter/material.dart';

/// Route dengan transisi fade halus, dipakai untuk perpindahan
/// antar halaman lewat bottom navigation bar (Home, Pengumuman, Profile)
/// supaya animasinya senada dengan CurvedNavigationBar.
Route<T> fadePageRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 350),
    reverseTransitionDuration: const Duration(milliseconds: 350),
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final fade = CurvedAnimation(
        parent: animation,
        curve: Curves.easeInOut,
      );

      return FadeTransition(
        opacity: fade,
        child: child,
      );
    },
  );
}