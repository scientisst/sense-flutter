import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:scientisst_sense/scientisst_sense.dart';
import 'package:sense/colors.dart';
import 'package:sense/utils/address.dart';
import 'homepage.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<Address>(create: (_) => Address(null)),
        ProxyProvider<Address, Sense?>(
          create: (BuildContext context) => null,
          update: (BuildContext context, Address address, Sense? sense) {
            if (address.address == null) {
              return null;
            } else {
              if (sense != null && address.address == sense.address) {
                return sense;
              } else {
                return Sense(address.address!);
              }
            }
          },
        ),
      ],
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
