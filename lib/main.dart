// lib/main.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';

import 'string_extensions.dart';
import 'pokemon_api.dart';
import 'services/image_classification_service.dart';
import 'services/scanned_pokemon_list_service.dart';
import 'models/scanned_pokemon.dart';

import 'widgets/pokedex_app_bar.dart';
import 'widgets/image_display.dart';
import 'widgets/prediction_info.dart';
import 'widgets/action_buttons_footer.dart';
import 'list_page.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => ScannedPokemonListService(),
      child: const MyApp(),
    ),
  );
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
  File? _image; // This will now hold the image when loaded from disk or taken
  ClassificationResult? _classificationResult;
  bool _isClassifying = false;
  String _pokemonDescription = "";

  late ImageClassificationService _imageClassifierService;
  late FlutterTts _flutterTts;

  late AnimationController _animationController;
  late Animation<double> _blinkingAnimation;

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
      duration: const Duration(milliseconds: 200),
    );
    _blinkingAnimation = Tween(begin: 0.0, end: 1.0).animate(_animationController);

    _initializeServices();
  }

  // Modified: _displayAndSpeakPokemon now handles image loading
  Future<void> _displayAndSpeakPokemon(ScannedPokemon pokemon) async {
    setState(() {
      _classificationResult = ClassificationResult(predictedName: pokemon.name, confidence: 1.0);
      _pokemonDescription = "${pokemon.name.toCapitalize()}, ${pokemon.description}";
      _isClassifying = false;

      // New: Load the image from the stored path
      if (pokemon.imagePath != null) {
        _image = File(pokemon.imagePath!);
      } else {
        _image = null; // Clear image if no path is available
      }
    });

    await _speak(pokemon.name.toCapitalize());
    await _flutterTts.awaitSpeakCompletion(true);
    await Future.delayed(const Duration(milliseconds: 1000));
    if (_pokemonDescription.length > pokemon.name.length + 2) {
      await _speak(_pokemonDescription.substring(pokemon.name.length + 2));
    }
  }

  Future<void> _initializeServices() async {
    await _imageClassifierService.initialize();
    await _initTts();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _flutterTts.stop();
    _imageClassifierService.dispose();
    super.dispose();
  }

  Future<void> _initTts() async {
    _flutterTts.setLanguage("en-US");
    _flutterTts.setVolume(1.0);
    _flutterTts.setPitch(.5);
    _flutterTts.setSpeechRate(0.5);

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
        _image = File(pickedFile.path); // Set the image file
        _classificationResult = null;
        _pokemonDescription = "";
      });
      await _classifyImage();
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
        String predictedName = result.predictedName.toCapitalize();
        String fetchedDescription = (await PokemonApi.getPokemonDescription(result.predictedName)) ?? "No description found.";

        setState(() {
          _classificationResult = result;
          _pokemonDescription = "$predictedName, $fetchedDescription";
          _isClassifying = false;
        });

        // Modified: Add imagePath when adding to the list service
        Provider.of<ScannedPokemonListService>(context, listen: false).addPokemon(
          ScannedPokemon(name: predictedName, description: fetchedDescription, imagePath: _image!.path),
        );

        await _speak(predictedName);
        await _flutterTts.awaitSpeakCompletion(true);
        await Future.delayed(const Duration(milliseconds: 1000));
        if (_pokemonDescription.length > predictedName.length + 2) {
          await _speak(_pokemonDescription.substring(predictedName.length + 2));
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

  void _handleViewList() async {
    final ScannedPokemon? selectedPokemon = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ListPage(),
      ),
    );

    if (selectedPokemon != null) {
      _displayAndSpeakPokemon(selectedPokemon);
    }
  }

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
      backgroundColor: const Color(0xFFDB2E37),
      appBar: PokedexAppBar(blinkingAnimation: _blinkingAnimation),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ImageDisplay now gets the image from _image
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
        onViewList: _handleViewList,
      ),
    );
  }
}