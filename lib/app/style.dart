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


// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
//
// class AppThemes {
//   static const MaterialColor black = MaterialColor(
//     _blackPrimaryValue,
//     <int, Color>{
//       50: Color(0xFFF0F0F0),
//       100: Color(0xFFE2E2E2),
//       200: Color(0xFFCCCCCC),
//       300: Color(0xFFC0C0C0),
//       350: Color(
//           0xFFB1B1B1), // only for raised button while pressed in light theme
//       400: Color(0xFF969696),
//       500: Color(_blackPrimaryValue),
//       600: Color(0xFF464646),
//       700: Color(0xFF363636),
//       800: Color(0xFF313131),
//       850: Color(0xFF242424), // only for background color in dark theme
//       900: Color(0xFF212121),
//     },
//   );
//   static const int _blackPrimaryValue = 0xFF505050;
//   static const kPrimaryColor = Color(0xFF45A336);
//   // static const kRedColor = Color(0xFFF44336);
//   static const kRedColor = Color(0xFFD50000);
//   // static const kBlueColor = Colors.blue;
//   static const kBlueColor = Color.fromRGBO(68, 150, 236, 1);
//   static const kOrangeColor = Colors.orange;
//   static const kLinkColor = Color(0xFF1790FF);
//   // static const kBackgroundColor = Color(0xFFF0F2F5);
//   static const kBackgroundColor = Color(0xFFF7F7FA);
//   static const kUnavailableColor = Color(0xFF494950);
//   static BorderSide cardBorder =
//       BorderSide(color: AppThemes.black.shade800, width: 0.5);
//
//   static final ThemeData darkTheme = lightTheme;
//   static final ThemeData lightTheme = ThemeData(
//     appBarTheme: AppBarTheme(
//       backgroundColor: kBackgroundColor,
//       iconTheme: IconThemeData(color: AppThemes.black.shade500),
//       actionsIconTheme: IconThemeData(color: AppThemes.black.shade500),
//     ),
//     cardTheme: CardTheme(
//       elevation: 0,
//       shape: RoundedRectangleBorder(side: cardBorder),
//     ),
//     iconTheme: IconThemeData(color: AppThemes.black.shade500),
//     textTheme: GoogleFonts.montserratTextTheme(TextTheme(
//       // Headlines
//       headline1: TextStyle(
//         fontSize: 36,
//         fontWeight: FontWeight.bold,
//         color: black.shade500,
//         fontFamilyFallback: const ["PlusJakartaSans"],
//       ),
//       headline2: TextStyle(
//         fontSize: 32,
//         fontWeight: FontWeight.bold,
//         color: black.shade500,
//         fontFamilyFallback: const ["PlusJakartaSans"],
//       ),
//       headline3: TextStyle(
//         fontSize: 28,
//         fontWeight: FontWeight.bold,
//         color: black.shade500,
//         fontFamilyFallback: const ["PlusJakartaSans"],
//       ),
//       headline4: TextStyle(
//         fontSize: 24,
//         fontWeight: FontWeight.bold,
//         color: black.shade500,
//         fontFamilyFallback: const ["PlusJakartaSans"],
//       ),
//       headline5: TextStyle(
//         fontSize: 20,
//         fontWeight: FontWeight.bold,
//         color: black.shade500,
//         fontFamilyFallback: const ["PlusJakartaSans"],
//       ),
//       headline6: TextStyle(
//         fontSize: 16,
//         fontWeight: FontWeight.bold,
//         color: black.shade500,
//         fontFamilyFallback: const ["PlusJakartaSans"],
//       ),
//       // Subtitles
//       subtitle1: TextStyle(
//         fontSize: 16,
//         color: black.shade600,
//         fontFamilyFallback: const ["PlusJakartaSans"],
//       ),
//       subtitle2: TextStyle(
//         fontSize: 12,
//         fontWeight: FontWeight.normal,
//         color: black.shade400,
//         fontFamilyFallback: const ["PlusJakartaSans"],
//       ),
//       bodyText1: TextStyle(
//         fontSize: 18,
//         fontWeight: FontWeight.normal,
//         color: black.shade600,
//         fontFamilyFallback: const ["PlusJakartaSans"],
//       ),
//       // Widgets uses this:
//       //    Text
//       bodyText2: TextStyle(
//         fontSize: 14,
//         fontWeight: FontWeight.normal,
//         color: black.shade600,
//         fontFamilyFallback: const ["PlusJakartaSans"],
//         // height: 1.5,
//       ),
//       //
//       caption: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
//       button: const TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
//     )),
//     tooltipTheme: TooltipThemeData(
//       padding: const EdgeInsets.fromLTRB(12, 5, 12, 7),
//       textStyle: GoogleFonts.montserrat(
//         textStyle: const TextStyle(
//           fontSize: 16,
//           fontWeight: FontWeight.normal,
//           color: Colors.white,
//           fontFamilyFallback: ["PlusJakartaSans"],
//         ),
//       ),
//     ),
//     listTileTheme: const ListTileThemeData(horizontalTitleGap: 0),
//     tabBarTheme: const TabBarTheme(
//       unselectedLabelColor: AppThemes.black,
//       indicatorSize: TabBarIndicatorSize.tab,
//       labelColor: AppThemes.kPrimaryColor,
//       // labelColor: Colors.white,
//       // indicator: MaterialIndicator(
//       //   height: 5,
//       //   // bottomLeftRadius: 0,
//       //   // bottomRightRadius: 0,
//       //   // strokeWidth: 5,
//       //   color: AppThemes.kPrimaryColor,
//       // ),
//       // indicator: BubbleTabIndicator(
//       //   indicatorRadius: 0,
//       //   indicatorHeight: 50,
//       //   indicatorColor: AppThemes.kPrimaryColor,
//       // ),
//       // indicator: UnderlineTabIndicator(
//       //   borderSide: const BorderSide(
//       //     color: AppThemes.kPrimaryColor,
//       //     width: 5,
//       //   ),
//       // ),
//       indicator: BoxDecoration(
//         border: Border(
//           bottom: BorderSide(color: AppThemes.kPrimaryColor, width: 5),
//           top: BorderSide(color: AppThemes.black, width: 0.505),
//           left: BorderSide(color: AppThemes.black, width: 0.5),
//           right: BorderSide(color: AppThemes.black, width: 0.5),
//         ),
//         color: Colors.white,
//       ),
//     ),
//     chipTheme: const ChipThemeData(
//         backgroundColor: Colors.white,
//         selectedColor: AppThemes.kPrimaryColor,
//         side: BorderSide(color: AppThemes.kPrimaryColor)),
//     focusColor: AppThemes.black.shade50,
//     primaryColor: const Color(_blackPrimaryValue),
//     colorScheme: ColorScheme.fromSwatch(
//       primarySwatch: AppThemes.black,
//     ).copyWith(
//       secondary: AppThemes.kPrimaryColor,
//     ),
//     primarySwatch: black,
//     visualDensity: VisualDensity.adaptivePlatformDensity,
//     inputDecorationTheme: const InputDecorationTheme(
//       fillColor: Colors.white,
//       contentPadding: EdgeInsets.only(top: 20, bottom: 20, left: 10),
//       enabledBorder: OutlineInputBorder(
//         borderSide: BorderSide(color: Color(0xFFA9A9B1), width: 0.5),
//         borderRadius: BorderRadius.all(Radius.zero),
//       ),
//       disabledBorder: OutlineInputBorder(
//         borderSide: BorderSide(
//           width: 0.5,
//           color: AppThemes.black,
//         ),
//         borderRadius: BorderRadius.all(Radius.zero),
//       ),
//       focusedBorder: OutlineInputBorder(
//         borderSide: BorderSide(width: 0.5),
//         borderRadius: BorderRadius.all(Radius.zero),
//       ),
//       errorBorder: OutlineInputBorder(
//         borderSide: BorderSide(width: 0.5, color: AppThemes.kRedColor),
//         borderRadius: BorderRadius.all(Radius.zero),
//       ),
//       focusedErrorBorder: OutlineInputBorder(
//         borderSide: BorderSide(width: 0.5, color: AppThemes.kRedColor),
//         borderRadius: BorderRadius.all(Radius.zero),
//       ),
//       floatingLabelBehavior: FloatingLabelBehavior.never,
//     ),
//     scaffoldBackgroundColor: kBackgroundColor,
//     outlinedButtonTheme: OutlinedButtonThemeData(
//       style: ElevatedButton.styleFrom(
//         foregroundColor: AppThemes.kPrimaryColor,
//         elevation: 0,
//         backgroundColor: Colors.white,
//         shadowColor: Colors.transparent,
//         padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
//         side: const BorderSide(color: kPrimaryColor, width: 0.75),
//         shape: const RoundedRectangleBorder(),
//         textStyle: GoogleFonts.montserrat(
//           letterSpacing: 0.2,
//           textStyle:
//               const TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
//         ),
//       ),
//     ),
//     elevatedButtonTheme: ElevatedButtonThemeData(
//       style: ElevatedButton.styleFrom(
//         foregroundColor: AppThemes.kPrimaryColor,
//         elevation: 0,
//         backgroundColor: Colors.white,
//         shadowColor: Colors.transparent,
//         padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
//         side: const BorderSide(color: kPrimaryColor, width: 0.75),
//         shape: const RoundedRectangleBorder(),
//         textStyle: GoogleFonts.montserrat(
//           letterSpacing: 0.2,
//           textStyle: const TextStyle(
//             fontSize: 16,
//             fontWeight: FontWeight.normal,
//             fontFamilyFallback: ["PlusJakartaSans"],
//           ),
//         ),
//       ),
//     ),
//     textButtonTheme: TextButtonThemeData(
//       style: ElevatedButton.styleFrom(
//         foregroundColor: AppThemes.kPrimaryColor,
//         elevation: 0,
//         backgroundColor: Colors.transparent,
//         shadowColor: Colors.transparent,
//         padding: const EdgeInsets.all(10),
//         side: BorderSide.none,
//         shape: const RoundedRectangleBorder(),
//         textStyle: GoogleFonts.montserrat(
//           letterSpacing: 0.2,
//           textStyle: const TextStyle(
//             fontSize: 16,
//             fontWeight: FontWeight.normal,
//             fontFamilyFallback: ["PlusJakartaSans"],
//           ),
//         ),
//       ),
//     ),
//   );
// }
