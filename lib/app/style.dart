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
  static const Color white_backgroundColor = Color(0xFFF2F2F2);
  static const Color black_backgroundColor = Color(0xFF000000);
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

TextTheme whiteTextTheme() => TextTheme(
      // title: TextStyle(
      //   fontWeight: FontWeight.w700,
      //   color: Colors.yellow,
      // ),
      caption: TextStyle(
          fontWeight: FontWeight.w700,
          color: AppColors.enabledColor,
          fontSize: 12),

      /// Default text style in the most cases
      body1: TextStyle(
          fontWeight: FontWeight.w700,
          color: AppColors.enabledColor,
          fontSize: 14),
      body2: TextStyle(
          fontWeight: FontWeight.w700, color: AppColors.accent, fontSize: 14),
      display1: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.enabledColor),
      display2: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.enabledColor),
      display3: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColors.enabledColor),
      subtitle: TextStyle(
          fontWeight: FontWeight.w700,
          color: AppColors.enabledColor,
          fontSize: 11),
      button: TextStyle(
          fontWeight: FontWeight.w700,
          color: AppColors.enabledColor,
          fontSize: 20),
    );

TextTheme blackTextTheme() => TextTheme(
      // title: TextStyle(
      //   fontWeight: FontWeight.w700,
      //   color: Colors.yellow,
      // ),
      caption: TextStyle(
          fontWeight: FontWeight.w700,
          color: AppColors.brightText,
          fontSize: 12),

      /// Default text style in the most cases
      body1: TextStyle(
          fontWeight: FontWeight.w700,
          color: AppColors.brightText,
          fontSize: 14),
      body2: TextStyle(
          fontWeight: FontWeight.w700, color: AppColors.accent, fontSize: 14),
      display1: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.brightText),
      display2: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.brightText),
      display3: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColors.brightText),
      subtitle: TextStyle(
          fontWeight: FontWeight.w700,
          color: AppColors.brightText,
          fontSize: 11),
      button: TextStyle(
          fontWeight: FontWeight.w700,
          color: AppColors.brightText,
          fontSize: 20),
    );

ThemeData whiteTheme() => ThemeData(
    // Define the default Font Family
    brightness: Brightness.light,
    fontFamily: primaryFontFamily,
    primaryColor: AppColors.white_backgroundColor,
    accentColor: AppColors.accent,
    disabledColor: AppColors.disabledColor,
    scaffoldBackgroundColor: AppColors.white_backgroundColor,
    appBarTheme: AppBarTheme(
        elevation: 0.5,
        color: AppColors.white_backgroundColor,
        iconTheme: IconThemeData(
          size: 16.0,
          color: AppColors.enabledColor,
        ),
        textTheme: TextTheme(
            title: TextStyle(
                fontWeight: FontWeight.w700,
                fontFamily: primaryFontFamily,
                color: AppColors.enabledColor))),
    textTheme: whiteTextTheme(),
    dialogTheme: DialogTheme(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    buttonTheme: ButtonThemeData(
      textTheme: ButtonTextTheme.accent,
      colorScheme: ColorScheme.light(
        primary: AppColors.enabledColor,
        secondary: AppColors.enabledColor,
      ),
    ),
    tabBarTheme: TabBarTheme(
        unselectedLabelStyle:
            TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
        unselectedLabelColor: AppColors.enabledColor,
        labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
        labelColor: AppColors.accent),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
        foregroundColor: AppColors.accent, backgroundColor: AppColors.accent),

    /// Modifies the cursor color in TextFormField
    colorScheme: ColorScheme.light(primary: AppColors.accent),
    textSelectionColor: AppColors.accent.withOpacity(0.2),
    inputDecorationTheme: InputDecorationTheme(
      filled: false,
      labelStyle: TextStyle(
          fontWeight: FontWeight.w700,
          color: AppColors.enabledColor,
          fontSize: 14),
      hintStyle: TextStyle(color: AppColors.disabledColor),
      counterStyle: TextStyle(
          fontWeight: FontWeight.w700,
          color: AppColors.enabledColor,
          fontSize: 12),
      enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.borderShadow)),
      focusedBorder:
          UnderlineInputBorder(borderSide: BorderSide(color: AppColors.accent)),
    ),
    //canvasColor: Colors.transparent,
    iconTheme: IconThemeData(size: 16.0, color: AppColors.enabledColor),
    dividerColor: AppColors.borderShadow,
    bottomAppBarTheme: BottomAppBarTheme(elevation: 0.5, color: Colors.white),
    bottomAppBarColor: Colors.white);

ThemeData blackTheme() => ThemeData(
    // Define the default Font Family
    brightness: Brightness.dark,
    fontFamily: primaryFontFamily,
    primaryColor: AppColors.black_backgroundColor,
    accentColor: AppColors.brightText,
    // accentColor: AppColors.accent,
    disabledColor: AppColors.disabledColor,
    scaffoldBackgroundColor: AppColors.black_backgroundColor,
    appBarTheme: AppBarTheme(
        elevation: 0.5,
        color: AppColors.black_backgroundColor,
        iconTheme: IconThemeData(
          size: 16.0,
          color: AppColors.brightText,
        ),
        textTheme: TextTheme(
            title: TextStyle(
                fontWeight: FontWeight.w700,
                fontFamily: primaryFontFamily,
                color: AppColors.brightText))),
    textTheme: blackTextTheme(),
    dialogTheme: DialogTheme(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    buttonTheme: ButtonThemeData(
      textTheme: ButtonTextTheme.accent,
      colorScheme: ColorScheme.light(
        primary: AppColors.brightText,
        secondary: AppColors.brightText,
      ),
    ),
    tabBarTheme: TabBarTheme(
        unselectedLabelStyle:
            TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
        unselectedLabelColor: AppColors.brightText,
        labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
        labelColor: AppColors.accent),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
        foregroundColor: AppColors.accent, backgroundColor: AppColors.accent),

    /// Modifies the cursor color in TextFormField
    colorScheme: ColorScheme.light(primary: AppColors.accent),
    textSelectionColor: AppColors.accent.withOpacity(0.2),
    inputDecorationTheme: InputDecorationTheme(
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
    iconTheme: IconThemeData(size: 16.0, color: AppColors.brightText),
    dividerColor: AppColors.borderShadow,
    bottomAppBarTheme: BottomAppBarTheme(elevation: 0.5, color: Colors.white),
    bottomAppBarColor: Colors.white);
