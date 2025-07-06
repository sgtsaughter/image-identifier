// lib/list_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/scanned_pokemon_list_service.dart';
import '../models/scanned_pokemon.dart';

class ListPage extends StatelessWidget {
  const ListPage({Key? key}) : super(key: key);

  static const int _totalPokemonCount = 151;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<ScannedPokemonListService>(
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
          Consumer<ScannedPokemonListService>(
            builder: (context, scannedPokemonListService, child) {
              // Conditionally render the IconButton
              return scannedPokemonListService.scannedPokemonList.isEmpty
                  ? const SizedBox.shrink() // If list is empty, show nothing
                  : IconButton(
                icon: const Icon(
                  Icons.delete_forever,
                  size: 30.0,
                  color: Colors.white,
                ),
                onPressed: () async {
                  final bool? confirm = await showDialog<bool>(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Clear All Scanned Pokémon?'),
                        content: const Text(
                            'Are you sure you want to delete all scanned Pokémon from the list? This action cannot be undone.'),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop(false);
                            },
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop(true);
                            },
                            child: const Text('Delete All', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      );
                    },
                  );

                  if (confirm == true) {
                    Provider.of<ScannedPokemonListService>(context, listen: false).clearList();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Pokedex cleared!')),
                    );
                  }
                },
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