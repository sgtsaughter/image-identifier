// pokemon_api.dart
import 'package:http/http.dart' as http;
import 'dart:convert';

class PokemonApi {
  static Future<String?> getPokemonDescription(String pokemonName) async {
    final url = Uri.parse('https://pokeapi.co/api/v2/pokemon-species/$pokemonName/');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Access flavor_text_entries and find the first English entry
        if (data['flavor_text_entries'] != null && data['flavor_text_entries'] is List) {
          for (var entry in data['flavor_text_entries']) {
            if (entry is Map && entry['language'] is Map && entry['language']['name'] == 'en') {
              return entry['flavor_text'].toString().replaceAll('\n', ' ');
            }
          }
        }
        return "No description found in English"; // Return if no English description
      } else {
        print('Failed to load Pokemon data: ${response.statusCode}');
        return "Failed to load Pokemon data";
      }
    } catch (e) {
      print('Error fetching Pokemon data: $e');
      return "Error fetching Pokemon data";
    }
  }
}