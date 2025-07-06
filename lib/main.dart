// lib/main.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_tts/flutter_tts.dart';
// Removed: import 'package:flutter/services.dart'; - it's not directly used here

import 'string_extensions.dart';
import 'pokemon_api.dart';
import 'services/image_classification_service.dart';

// Import the new UI widgets
import 'widgets/pokedex_app_bar.dart';
import 'widgets/image_display.dart';
import 'widgets/prediction_info.dart';
import 'widgets/action_buttons_footer.dart';
import 'list_page.dart'; // Import the new ListPage

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: ImageClassifierScreen(),
    );
  }
}

class ImageClassifierScreen extends StatefulWidget {
  const ImageClassifierScreen({Key? key}) : super(key: key);

  @override
  _ImageClassifierScreenState createState() => _ImageClassifierScreenState();
}

class _ImageClassifierScreenState extends State<ImageClassifierScreen> with SingleTickerProviderStateMixin {
  File? _image;
  ClassificationResult? _classificationResult;
  bool _isClassifying = false;
  String _pokemonDescription = "";

  late ImageClassificationService _imageClassifierService;
  late FlutterTts _flutterTts;

  late AnimationController _animationController;
  late Animation<double> _blinkingAnimation;

  // Define cut properties and border thickness as constants (local to this class)
  static const double _cutBottomHorizontalOffset = 30.0;
  static const double _cutLeftVerticalOffset = 30.0;
  static const double _outerWhiteBorderThickness = 25.0;
  // This _totalPaddingForImage is derived from _outerWhiteBorderThickness
  static const double _totalPaddingForImage = _outerWhiteBorderThickness;


  @override
  void initState() {
    super.initState();
    _imageClassifierService = ImageClassificationService();
    _flutterTts = FlutterTts();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200), // Blinking speed (hardcoded)
    );
    _blinkingAnimation = Tween(begin: 0.0, end: 1.0).animate(_animationController);

    _initializeServices();
  }

  Future<void> _initializeServices() async {
    await _imageClassifierService.initialize();
    await _initTts(); // Await TTS initialization for consistency
  }

  @override
  void dispose() {
    _animationController.dispose();
    _flutterTts.stop();
    _imageClassifierService.dispose();
    super.dispose();
  }

  Future<void> _initTts() async { // Made async for consistency
    _flutterTts.setLanguage("en-US"); // Hardcoded
    _flutterTts.setVolume(1.0);     // Hardcoded
    _flutterTts.setPitch(.5);       // Hardcoded
    _flutterTts.setSpeechRate(0.5); // Hardcoded

    _flutterTts.setStartHandler(() {
      setState(() {
        _animationController.repeat(reverse: true);
      });
    });

    _flutterTts.setCompletionHandler(() {
      setState(() {
        _animationController.stop();
        _animationController.value = 0.0;
      });
    });

    _flutterTts.setCancelHandler(() {
      setState(() {
        _animationController.stop();
        _animationController.value = 0.0;
      });
    });

    _flutterTts.setErrorHandler((message) {
      setState(() {
        _animationController.stop();
        _animationController.value = 0.0;
        print("TTS Error: $message");
      });
    });
  }

  Future<void> _speak(String text) async {
    if (text.isNotEmpty) {
      await _flutterTts.speak(text);
    }
  }

  Future<void> _handleImageSelection(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _classificationResult = null; // Clear previous result
        _pokemonDescription = ""; // Clear previous description
      });
      await _classifyImage(); // Await classification
    }
  }

  Future<void> _classifyImage() async {
    if (_image == null) {
      _showSnackBar('Please select an image.');
      return;
    }

    setState(() {
      _isClassifying = true;
      _pokemonDescription = "Loading description...";
    });

    try {
      final result = await _imageClassifierService.classifyImage(_image!);
      if (result != null) {
        setState(() {
          _classificationResult = result;
        });

        String predictedName = result.predictedName.toCapitalize();
        String fetchedDescription = (await PokemonApi.getPokemonDescription(result.predictedName)) ?? "No description found.";

        setState(() {
          _pokemonDescription = "$predictedName, $fetchedDescription";
          _isClassifying = false;
        });

        await _speak(predictedName);
        await _flutterTts.awaitSpeakCompletion(true);
        await Future.delayed(const Duration(milliseconds: 1000)); // Hardcoded delay
        if (_pokemonDescription.length > predictedName.length + 2) {
          await _speak(_pokemonDescription.substring(predictedName.length + 2)); // Speak description after name
        }
      } else {
        setState(() {
          _isClassifying = false;
          _pokemonDescription = "Could not classify image.";
        });
        _showSnackBar('Failed to classify image.');
      }
    } catch (e) {
      print('Error during classification: $e');
      setState(() {
        _isClassifying = false;
        _pokemonDescription = "Error: ${e.toString()}";
      });
      _showSnackBar('An error occurred during classification: $e');
    } finally {
      setState(() {
        _isClassifying = false;
      });
    }
  }

  // New: Method to handle navigation to the ListPage
  void _handleViewList() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ListPage(),
      ),
    );
  }

  // Helper method for showing SnackBars
  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDB2E37), // Hardcoded Pokedex Red
      appBar: PokedexAppBar(blinkingAnimation: _blinkingAnimation),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0), // Hardcoded padding
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ImageDisplay(
                imageFile: _image,
                cutBottomHorizontalOffset: _cutBottomHorizontalOffset, // Passed local constant
                cutLeftVerticalOffset: _cutLeftVerticalOffset,       // Passed local constant
                outerWhiteBorderThickness: _outerWhiteBorderThickness, // Passed local constant
              ),
              const SizedBox(height: 20), // Hardcoded spacing
              PredictionInfo(
                isClassifying: _isClassifying,
                classificationResult: _classificationResult,
                pokemonDescription: _pokemonDescription,
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: ActionButtonsFooter(
        onPickImage: _handleImageSelection,
        onViewList: _handleViewList, // Pass the new handler
      ),
    );
  }
}