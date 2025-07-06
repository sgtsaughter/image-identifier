// lib/models/scanned_pokemon.dart
class ScannedPokemon {
  final String name;
  final String description;
  final String? imagePath; // Nullable as it might not always have an image
  final double confidence; // Add confidence field

  ScannedPokemon({
    required this.name,
    required this.description,
    this.imagePath,
    required this.confidence, // Make it required
  });

  // Convert ScannedPokemon to a Map (for potential future persistence)
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'imagePath': imagePath,
      'confidence': confidence,
    };
  }

  // Create ScannedPokemon from a Map
  factory ScannedPokemon.fromMap(Map<String, dynamic> map) {
    return ScannedPokemon(
      name: map['name'] as String,
      description: map['description'] as String,
      imagePath: map['imagePath'] as String?,
      confidence: map['confidence'] as double, // Retrieve confidence
    );
  }
}