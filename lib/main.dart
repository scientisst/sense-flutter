import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sense/colors.dart';
import 'package:sense/utils/device_settings.dart';
import 'homepage.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) {
        return DeviceSettings();
      },
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: MyColors.primary,
    ));
    return MaterialApp(
      title: 'Sense',
      theme: ThemeData(
        disabledColor: MyColors.lightGrey,
        primaryColor: MyColors.primary,
        accentColor: MyColors.primary,
        scaffoldBackgroundColor: const Color(0xFFFEFEFE),
        appBarTheme: const AppBarTheme(
          backgroundColor: MyColors.primary,
          centerTitle: true,
        ),
        primaryIconTheme: const IconThemeData(
          color: Colors.white,
        ),
        iconTheme: const IconThemeData(
            //color: Colors.white,
            ),
        accentIconTheme: const IconThemeData(
          color: MyColors.primary,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          unselectedItemColor: MyColors.lightGrey,
          selectedItemColor: MyColors.primary,
        ),
        buttonTheme: const ButtonThemeData(buttonColor: MyColors.primary),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            primary: MyColors.primary,
            elevation: 0,
            side: const BorderSide(
              color: MyColors.primary,
              width: 2,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(100),
            ),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            primary: MyColors.primary,
            //onPrimary: Colors.grey[1000],
            //onSurface: Colors.grey[1000],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(100),
            ), //alignment: Alignment.center,
          ),
        ),
        sliderTheme: SliderThemeData.fromPrimaryColors(
          primaryColor: MyColors.primary,
          primaryColorDark: MyColors.lightGrey,
          primaryColorLight: MyColors.primary,
          valueIndicatorTextStyle: const TextStyle(),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            primary: MyColors.primary,
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(
              color: MyColors.primary,
            ),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(
              color: MyColors.primary,
            ),
          ),
          hintStyle: TextStyle(
            color: Colors.black54,
          ),
        ),
        tabBarTheme: const TabBarTheme(
          labelColor: MyColors.primary,
          indicator: UnderlineTabIndicator(
            borderSide: BorderSide(
              color: MyColors.primary,
              width: 4.0,
            ),
            insets: EdgeInsets.only(
              bottom: 48,
            ),
          ),
        ),
      ),
      home: const Scaffold(
        body: SafeArea(
          child: HomePage(),
          //child: Options(),
        ),
      ),
    );
  }
}
