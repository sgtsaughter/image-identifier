// lib/list_page.dart
import 'package:flutter/material.dart';

class ListPage extends StatelessWidget {
  const ListPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pokemon List'),
        backgroundColor: const Color(0xFFDB2E37), // Reusing Pokedex red for consistency
        leading: IconButton( // Back button
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop(); // Pops the current route off the navigation stack
          },
        ),
      ),
      body: const Center(
        child: Text(
          'Pokemon List page goes here',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}