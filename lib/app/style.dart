/*
 * Copyright (c) 2019. Belákovics Ákos EV.  All rights reserved.
 * Author: Ákos Belákovics
 */

import 'package:flutter/material.dart';

class AppColors {
  // static const Color brightText = Colors.white;
  static const Color brightText = Color(0xFFD0D0D0);
  static const Color darkText = Colors.black;
  static const Color buttonShadow = Color(0xFFE9E9E9);
  static const Color borderShadow = Color(0xFFE0E0E0);
  static const Color whiteBackgroundColor = Color(0xFFF2F2F2);
  static const Color blackBackgroundColor = Color(0xFF000000);
  static const Color enabledColor = Color(0xFF32383d);
  static const Color disabledColor = Color(0xFF606060);
  // static const Color accent = Color(0xFF074DFC);
  static const Color accent = Color(0xFFFFEB3B);
  static const Color accent2 = Color(0xFFFF3762);
  static const Color ok = Color(0xFF43A047);
  static const Color error = Color(0xFFD32F2F);
  static const Color red = Color(0xFFEA4335);

  static const Color textColor = Colors.black;
  // https://brandpalettes.com
  static const Color google = Color(0xFFED750A);
  static const Color facebook = Color(0xFF3C5A99);

  static const Color youtube = Color(0xFFFF001B);
  static const Color pinterest = Color(0xFFc8232c);
  static const Color twitter = Color(0xFF00aced);
  static const Color adwords = Colors.greenAccent;
}

// Theme ////////////////////////////////////////////////////////////////
String primaryFontFamily = 'Lato';
String secondaryFontFamily = 'Roboto';
//////////////////////////////////////////////////////////////////////////

TextTheme blackTextTheme() => const TextTheme(
      // title: TextStyle(
      //   fontWeight: FontWeight.w700,
      //   color: Colors.yellow,
      // ),
      caption: TextStyle(
          fontWeight: FontWeight.w700,
          color: AppColors.brightText,
          fontSize: 12),

      /// Default text style in the most cases
      bodyText1: TextStyle(
          fontWeight: FontWeight.w700,
          color: AppColors.brightText,
          fontSize: 14),
      bodyText2: TextStyle(
          fontWeight: FontWeight.w700,
          color: AppColors.brightText,
          fontSize: 14),
      // displayLarge: const TextStyle(
      //     fontSize: 14,
      //     fontWeight: FontWeight.w700,
      //     color: AppColors.brightText),
      // displayMedium: const TextStyle(
      //     fontSize: 12,
      //     fontWeight: FontWeight.w700,
      //     color: AppColors.brightText),
      // displaySmall: const TextStyle(
      //     fontSize: 10,
      //     fontWeight: FontWeight.w700,
      //     color: AppColors.brightText),
      subtitle1: TextStyle(
          fontWeight: FontWeight.w700,
          color: AppColors.brightText,
          fontSize: 11),
      button: TextStyle(
          fontWeight: FontWeight.w700,
          color: AppColors.brightText,
          fontSize: 20),
    );

ThemeData blackTheme() => ThemeData(
    // Define the default Font Family
    // brightness: Brightness.dark,
    fontFamily: primaryFontFamily,
    primaryColor: AppColors.blackBackgroundColor,
    // accentColor: AppColors.accent,
    disabledColor: AppColors.disabledColor,
    scaffoldBackgroundColor: AppColors.blackBackgroundColor,
    appBarTheme: AppBarTheme(
        elevation: 0.5,
        color: AppColors.blackBackgroundColor,
        iconTheme: const IconThemeData(
          size: 16.0,
          color: AppColors.brightText,
        ),
        titleTextStyle: TextStyle(
            fontWeight: FontWeight.w700,
            fontFamily: primaryFontFamily,
            color: AppColors.brightText)),
    textTheme: blackTextTheme(),
    dialogTheme: DialogTheme(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    buttonTheme: const ButtonThemeData(
      textTheme: ButtonTextTheme.accent,
      colorScheme: ColorScheme.light(
        primary: AppColors.brightText,
        secondary: AppColors.brightText,
      ),
    ),
    tabBarTheme: const TabBarTheme(
        unselectedLabelStyle:
            TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
        unselectedLabelColor: AppColors.brightText,
        labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
        labelColor: AppColors.accent),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
        foregroundColor: AppColors.accent, backgroundColor: AppColors.accent),
    textSelectionTheme: TextSelectionThemeData(
        selectionColor: AppColors.accent.withOpacity(0.2)),
    inputDecorationTheme: const InputDecorationTheme(
      filled: false,
      labelStyle: TextStyle(
          fontWeight: FontWeight.w700,
          color: AppColors.brightText,
          fontSize: 14),
      hintStyle: TextStyle(color: AppColors.disabledColor),
      counterStyle: TextStyle(
          fontWeight: FontWeight.w700,
          color: AppColors.brightText,
          fontSize: 12),
      enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.borderShadow)),
      focusedBorder:
          UnderlineInputBorder(borderSide: BorderSide(color: AppColors.accent)),
    ),
    //canvasColor: Colors.transparent,
    iconTheme: const IconThemeData(size: 16.0, color: AppColors.brightText),
    dividerColor: AppColors.borderShadow,
    bottomAppBarTheme:
        const BottomAppBarTheme(elevation: 0.5, color: Colors.white),
    bottomAppBarColor: Colors.white,
    colorScheme: const ColorScheme.light(primary: AppColors.accent)
        .copyWith(secondary: AppColors.brightText));
