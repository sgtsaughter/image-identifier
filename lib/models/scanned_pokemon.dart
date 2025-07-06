// lib/models/scanned_pokemon.dart
import 'dart:convert'; // For JSON encoding/decoding

class ScannedPokemon {
  final String name;
  final String description;

  ScannedPokemon({
    required this.name,
    required this.description,
  });

  // Convert a ScannedPokemon object into a Map.
  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
  };

  // Convert a Map into a ScannedPokemon object.
  factory ScannedPokemon.fromJson(Map<String, dynamic> json) {
    return ScannedPokemon(
      name: json['name'] as String,
      description: json['description'] as String,
    );
  }

  // Override toString for better debugging
  @override
  String toString() => 'ScannedPokemon(name: $name, description: $description)';
}