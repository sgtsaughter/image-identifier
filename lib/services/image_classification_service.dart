import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart'; // For rootBundle
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

// A class to hold the result of a classification
class ClassificationResult {
  final String predictedName;
  final double confidence;

  ClassificationResult({required this.predictedName, required this.confidence});
}

class ImageClassificationService {
  List<String> _classNames = [];
  Interpreter? _interpreter;

  // Method to load class names (labels)
  Future<void> loadClassNames() async {
    try {
      String data = await rootBundle.loadString('assets/ml/labels.txt');
      _classNames = data.split('\n').map((line) => line.trim()).toList();
      _classNames.removeWhere((item) => item.isEmpty);
      print("Loaded class names from service: $_classNames");
      if (_classNames.isEmpty) {
        throw Exception("Class names list is empty after loading.");
      }
    } catch (e) {
      print("Error loading class names in service: $e");
      // Consider re-throwing or handling more gracefully depending on app requirements
      rethrow;
    }
  }

  // Method to load the TFLite model
  Future<void> _loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/ml/pokemon_model_gemini.tflite');
      _interpreter!.allocateTensors(); // Ensure tensors are allocated after loading
      print("TFLite model loaded successfully from service.");
    } catch (e) {
      print("Error loading TFLite model in service: $e");
      _interpreter = null; // Ensure interpreter is null if loading fails
      rethrow;
    }
  }

  // Initialize the service (load model and class names)
  Future<void> initialize() async {
    await loadClassNames();
    await _loadModel();
  }

  // Method to classify an image
  Future<ClassificationResult?> classifyImage(File imageFile) async {
    if (_interpreter == null) {
      print("Interpreter is not loaded. Cannot classify.");
      await _loadModel(); // Attempt to reload the model if it's not loaded
      if (_interpreter == null) return null; // If still not loaded, exit
    }
    if (_classNames.isEmpty) {
      print("Class names are not loaded. Cannot classify.");
      await loadClassNames(); // Attempt to reload class names
      if (_classNames.isEmpty) return null; // If still not loaded, exit
    }

    try {
      final inputShape = _interpreter!.getInputTensor(0).shape; // [1, 224, 224, 3]

      final image = img.decodeImage(imageFile.readAsBytesSync());
      if (image == null) {
        throw Exception("Failed to decode image in service.");
      }

      // Resize the image to the model's expected input size (e.g., 224x224)
      final resizedImage = img.copyResize(image, width: inputShape[1], height: inputShape[2]);

      // Convert the image to a Float32List
      var inputImage = Float32List(1 * inputShape[1] * inputShape[2] * inputShape[3]);
      int pixelIndex = 0;
      for (int i = 0; i < inputShape[1]; i++) { // height
        for (int j = 0; j < inputShape[2]; j++) { // width
          img.Pixel pixel = resizedImage.getPixel(j, i); // Get pixel (x,y)
          // Normalize pixel values to [0, 1]
          inputImage[pixelIndex++] = pixel.r / 255.0;
          inputImage[pixelIndex++] = pixel.g / 255.0;
          inputImage[pixelIndex++] = pixel.b / 255.0;
        }
      }

      // Reshape to [1, 224, 224, 3]
      var inputList = inputImage.reshape([1, inputShape[1], inputShape[2], inputShape[3]]);

      // Define the output
      var outputShape = _interpreter!.getOutputTensor(0).shape; // e.g., [1, 151]
      var output = List.filled(outputShape[1], 0.0).reshape(outputShape);

      // Run inference
      _interpreter!.run(inputList, output);

      // Process the output
      List<double> outputList = List<double>.from(output[0]);
      int maxIndex = 0;
      double maxValue = outputList[0];
      for (int i = 1; i < outputList.length; i++) {
        if (outputList[i] > maxValue) {
          maxValue = outputList[i];
          maxIndex = i;
        }
      }

      if (maxIndex < 0 || maxIndex >= _classNames.length) {
        throw Exception("Predicted index is out of bounds for class names.");
      }

      _interpreter!.close();
      _interpreter = null;

      return ClassificationResult(
        predictedName: _classNames[maxIndex].toLowerCase(),
        confidence: maxValue,
      );
    } catch (e) {
      print('Error during classification in service: $e');
      _interpreter?.close(); // Ensure interpreter is closed on error
      _interpreter = null;
      return null; // Or rethrow, or return a specific error object
    }
  }

  // Dispose of the interpreter when the service is no longer needed
  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    print("ImageClassificationService disposed.");
  }
}