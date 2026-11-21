import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const _seed = Colors.brown;

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorSchemeSeed: _seed,
        brightness: Brightness.light,
      );
}
