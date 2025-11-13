

import 'package:flutter/material.dart';
import '/screens/splash_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {  //Root level widget no state changes
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {  //inherited build method 
    return MaterialApp(
      title: 'Learning Categories',
      theme: ThemeData(             //global visual theme
        primarySwatch: Colors.deepPurple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
      ),
      home:const SplashScreen(), //display the SplashScreen() as the first page
    );
  }
}