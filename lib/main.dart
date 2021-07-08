import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sense/colors.dart';
import 'homepage.dart';

void main() {
  runApp(MyApp());
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
        accentColor: MyColors.orange,
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ), //alignment: Alignment.center,
          ),
        ),
      ),
      home: const HomePage(),
    );
  }
}
