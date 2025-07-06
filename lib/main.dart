import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'pokemon_api.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'string_extensions.dart';
import 'services/image_classification_service.dart';

import 'widgets/pokedex_app_bar.dart';
import 'widgets/image_display.dart';
import 'widgets/prediction_info.dart';
import 'widgets/action_buttons_footer.dart';

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
  // bool _isSpeaking is managed internally by _initTts handlers now for the animation

  // Define cut properties and border thickness as constants
  static const double _cutBottomHorizontalOffset = 30.0;
  static const double _cutLeftVerticalOffset = 30.0;
  static const double _outerWhiteBorderThickness = 25.0;
  static const double _totalPaddingForImage = _outerWhiteBorderThickness;


  @override
  void initState() {
    super.initState();
    _imageClassifierService = ImageClassificationService();
    _flutterTts = FlutterTts();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200), // Blinking speed
    );
    _blinkingAnimation = Tween(begin: 0.0, end: 1.0).animate(_animationController);

    _initializeServices();
  }

  Future<void> _initializeServices() async {
    await _imageClassifierService.initialize();
    _initTts();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _flutterTts.stop();
    _imageClassifierService.dispose();
    super.dispose();
  }

  void _initTts() {
    _flutterTts.setLanguage("en-US");
    _flutterTts.setVolume(1.0);
    _flutterTts.setPitch(.5);
    _flutterTts.setSpeechRate(0.5);

    _flutterTts.setStartHandler(() {
      setState(() {
        _animationController.repeat(reverse: true); // Start blinking when speech begins
      });
    });

    _flutterTts.setCompletionHandler(() {
      setState(() {
        _animationController.stop(); // Stop blinking
        _animationController.value = 0.0; // Reset opacity to off state (fully transparent)
      });
    });

    _flutterTts.setCancelHandler(() {
      setState(() {
        _animationController.stop(); // Stop blinking
        _animationController.value = 0.0; // Reset opacity to off state
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
      _classifyImage();
    }
  }

  Future<void> _classifyImage() async {
    if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image.')),
      );
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
        _pokemonDescription = (await PokemonApi.getPokemonDescription(result.predictedName)) ?? "No description found.";

        setState(() {
          _pokemonDescription = "$predictedName, $_pokemonDescription";
          _isClassifying = false;
        });

        await _speak(predictedName);
        await _flutterTts.awaitSpeakCompletion(true);
        await Future.delayed(const Duration(milliseconds: 1000));
        if (_pokemonDescription.length > predictedName.length + 2) {
          await _speak(_pokemonDescription.substring(predictedName.length + 2)); // Speak description after name
        }
      } else {
        setState(() {
          _isClassifying = false;
          _pokemonDescription = "Could not classify image.";
        });
        if (mounted) { // Check if the widget is still mounted before showing SnackBar
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to classify image.')),
          );
        }
      }
    } catch (e) {
      print('Error during classification: $e');
      setState(() {
        _isClassifying = false;
        _pokemonDescription = "Error: ${e.toString()}";
      });
      if (mounted) { // Check if the widget is still mounted before showing SnackBar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred during classification: $e')),
        );
      }
    } finally {
      setState(() {
        _isClassifying = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDB2E37),
      appBar: PokedexAppBar(blinkingAnimation: _blinkingAnimation),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ImageDisplay(
                imageFile: _image,
                cutBottomHorizontalOffset: _cutBottomHorizontalOffset,
                cutLeftVerticalOffset: _cutLeftVerticalOffset,
                outerWhiteBorderThickness: _outerWhiteBorderThickness,
              ),
              const SizedBox(height: 20),
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
      ),
    );
  }
}