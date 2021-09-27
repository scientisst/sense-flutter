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
      statusBarColor: MyColors.grey,
    ));
    return MaterialApp(
      title: 'Sense',
      theme: ThemeData(
        disabledColor: MyColors.lightGrey,
        primaryColor: MyColors.grey,
        accentColor: MyColors.brown,
        scaffoldBackgroundColor: const Color(0xFFFEFEFE),
        appBarTheme: const AppBarTheme(
          backgroundColor: MyColors.grey,
          centerTitle: true,
        ),
        primaryIconTheme: const IconThemeData(
          color: MyColors.orange,
        ),
        iconTheme: const IconThemeData(
          color: MyColors.orange,
        ),
        accentIconTheme: const IconThemeData(
          color: MyColors.orange,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          unselectedItemColor: MyColors.lightGrey,
          selectedItemColor: MyColors.grey,
        ),
        buttonTheme: const ButtonThemeData(buttonColor: MyColors.brown),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            //primary: MyColors.brown,
            //onPrimary: Colors.grey[1000],
            //onSurface: Colors.grey[1000],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ), //alignment: Alignment.center,
          ),
        ),
        sliderTheme: SliderThemeData.fromPrimaryColors(
          primaryColor: MyColors.brown,
          primaryColorDark: MyColors.lightGrey,
          primaryColorLight: MyColors.grey,
          valueIndicatorTextStyle: const TextStyle(),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            primary: MyColors.orange,
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
