// lib/list_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/scanned_pokemon_list_service.dart';
import '../models/scanned_pokemon.dart';

class ListPage extends StatelessWidget {
  const ListPage({Key? key}) : super(key: key);

  // Define the total number of Pokémon as a constant here
  static const int _totalPokemonCount = 151;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<ScannedPokemonListService>( // Use Consumer for the title
          builder: (context, scannedPokemonListService, child) {
            return Text(
              'Scanned Pokémon: ${scannedPokemonListService.uniquePokemonCount}/$_totalPokemonCount',
            );
          },
        ),
        backgroundColor: const Color(0xFFDB2E37),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: () {
              Provider.of<ScannedPokemonListService>(context, listen: false).clearList();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Scanned list cleared!')),
              );
            },
          ),
        ],
      ),
      body: Consumer<ScannedPokemonListService>(
        builder: (context, scannedPokemonListService, child) {
          if (scannedPokemonListService.scannedPokemonList.isEmpty) {
            return const Center(
              child: Text(
                'No Pokémon scanned yet!',
                style: TextStyle(fontSize: 18, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            );
          }
          return ListView.builder(
            itemCount: scannedPokemonListService.scannedPokemonList.length,
            itemBuilder: (context, index) {
              final pokemon = scannedPokemonListService.scannedPokemonList[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                elevation: 2,
                child: ListTile(
                  title: Text(
                    pokemon.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  subtitle: Text(
                    pokemon.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.of(context).pop(pokemon);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}