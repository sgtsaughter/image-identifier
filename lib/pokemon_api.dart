// pokemon_api.dart
import 'package:http/http.dart' as http;
import 'dart:convert';

//TODO: Make header that looks like top of pokedex (big blue dot and red, yellow, green circles)
// Add border around pokemon image
// Below the image have a Gallery and Camera icon instead of buttons
// Maybe have the big button in the header light up while the tts is happening.
// Maybe have it blink as it's talking (need to see what data comes back from the tts library)
// Maybe have a second page that will save past scanned in pokemon.

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