// lib/models/scanned_pokemon.dart
import 'dart:convert';

class ScannedPokemon {
  final String name;
  final String description;
  final String? imagePath; // New: Optional path to the locally stored image

  ScannedPokemon({
    required this.name,
    required this.description,
    this.imagePath, // Make it optional
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'imagePath': imagePath, // Include imagePath in JSON
  };

  factory ScannedPokemon.fromJson(Map<String, dynamic> json) {
    return ScannedPokemon(
      name: json['name'] as String,
      description: json['description'] as String,
      imagePath: json['imagePath'] as String?, // Retrieve imagePath from JSON
    );
  }

  @override
  String toString() => 'ScannedPokemon(name: $name, description: $description, imagePath: $imagePath)';
}