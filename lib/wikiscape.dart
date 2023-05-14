import 'package:flutter/material.dart';

import 'homepage.dart';

class Wikiscape extends StatelessWidget {
  const Wikiscape({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wikiscape',
      theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity),
      home: const HomePage(title: 'Wikiscape'),
    );
  }
}
