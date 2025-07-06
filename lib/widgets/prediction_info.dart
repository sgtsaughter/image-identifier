// lib/widgets/prediction_info.dart
import 'package:flutter/material.dart';
import '../services/image_classification_service.dart'; // Ensure this is imported for ClassificationResult
import '../string_extensions.dart'; // Import for toCapitalize()

class PredictionInfo extends StatelessWidget {
  final bool isClassifying;
  final ClassificationResult? classificationResult;
  final String pokemonDescription;

  const PredictionInfo({
    Key? key,
    required this.isClassifying,
    this.classificationResult,
    required this.pokemonDescription,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const Color screenBackgroundColor = Color(0xFF1A1A1A);
    const Color textColor = Colors.white;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: screenBackgroundColor,
        border: Border.all(color: Colors.black, width: 4.0),
        borderRadius: BorderRadius.circular(15.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 7,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isClassifying)
            Column(
              children: const [
                SizedBox(height: 30),
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                ),
                SizedBox(height: 20),
                Text(
                  "Scanning...",
                  style: TextStyle(color: textColor, fontSize: 18),
                ),
                SizedBox(height: 30),
              ],
            )
          else if (classificationResult != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pokémon Name - Ensure capitalization
                Text(
                  classificationResult!.predictedName.toCapitalize(), // Added .toCapitalize()
                  style: const TextStyle(
                    color: textColor,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'PixelifySans',
                  ),
                ),
                const SizedBox(height: 5),
                // Confidence - Formatted as percentage
                Text(
                  'Confidence: ${(classificationResult!.confidence * 100).toStringAsFixed(2)}%', // Multiplied by 100 and formatted
                  style: TextStyle(
                    color: textColor.withOpacity(0.8),
                    fontSize: 18,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const Divider(color: Colors.grey, thickness: 1.5, height: 25),

                // Description - No change needed here
                Text(
                  pokemonDescription,
                  textAlign: TextAlign.justify,
                  style: const TextStyle(
                    color: textColor,
                    fontSize: 17,
                    height: 1.4,
                  ),
                ),
              ],
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40.0),
              child: Text(
                pokemonDescription.isEmpty ? 'Scan a Pokémon to begin!' : pokemonDescription,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: pokemonDescription.isEmpty ? Colors.grey : textColor,
                  fontSize: 18,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }
}