import 'package:flutter/material.dart';
import '../services/image_classification_service.dart'; // Import ClassificationResult
import '../string_extensions.dart'; // For .toCapitalize()

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
    if (isClassifying) {
      return const CircularProgressIndicator();
    } else if (classificationResult != null) {
      return Column(
        children: [
          Text(
            'Prediction: ${classificationResult!.predictedName.toCapitalize()} (Confidence: ${(classificationResult!.confidence * 100).toStringAsFixed(2)}%)',
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Open Sans, Lato',
                color: Colors.yellowAccent),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              pokemonDescription,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontFamily: 'Open Sans, Lato', color: Colors.white),
            ),
          ),
        ],
      );
    } else {
      return const SizedBox.shrink();
    }
  }
}