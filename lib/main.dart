import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/services.dart';
import 'pokemon_api.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'string_extensions.dart';
import 'package:flutter_svg/flutter_svg.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ImageClassifierScreen(),
    );
  }
}

class ImageClassifierScreen extends StatefulWidget {
  @override
  _ImageClassifierScreenState createState() => _ImageClassifierScreenState();
}

class _ImageClassifierScreenState extends State<ImageClassifierScreen> {
  File? _image;
  List<double>? _output;
  double _confidence = 0.0;
  List<String> class_names = [];
  bool _isClassifying = false;
  String _predictedName = "";
  String _pokemonDescription = "";
  FlutterTts flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    initTts();
    loadClassNames();
  }

  initTts() async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setVolume(1.0);
    await flutterTts.setPitch(.5);
    await flutterTts.setSpeechRate(0.5);
  }

  Future _speak(String text) async {
    await flutterTts.speak(text);
  }

  Future<void> loadClassNames() async {
    try {
      String data = await rootBundle.loadString('assets/ml/labels.txt');
      class_names = data.split('\n').map((line) => line.trim()).toList();
      class_names.removeWhere((item) => item.isEmpty);
      print("Loaded class names: $class_names");
    } catch (e) {
      print("Error loading class names: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading labels.txt")),
      );
    }
  }

  Future pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
      _classifyImage();
    }
  }

  Future pickImageFromCamera() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
      _classifyImage();
    }
  }

  Future _classifyImage() async {
    if (_image == null || class_names.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select an image and ensure labels are loaded.')),
      );
      return;
    }

    setState(() {
      _isClassifying = true;
      _pokemonDescription = "Loading description...";
    });

    try {
      final interpreter = await Interpreter.fromAsset('assets/ml/pokemon_model_gemini.tflite');
      interpreter.allocateTensors();

      final inputShape = interpreter.getInputTensor(0).shape;

      final image = img.decodeImage(File(_image!.path).readAsBytesSync());
      if (image == null) {
        throw Exception("Failed to decode image.");
      }

      final resizedImage = img.copyResize(image, width: 224, height: 224);

      var inputImage = Float32List(1 * inputShape[1] * inputShape[2] * inputShape[3]);
      int index = 0;
      for (int i = 0; i < inputShape[1]; i++) {
        for (int j = 0; j < inputShape[2]; j++) {
          img.Pixel pixel = resizedImage.getPixel(j, i);
          inputImage[index++] = pixel.r / 255.0;
          inputImage[index++] = pixel.g / 255.0;
          inputImage[index++] = pixel.b / 255.0;
        }
      }

      var inputList = inputImage.reshape([1, inputShape[1], inputShape[2], inputShape[3]]);

      var output = List.filled(interpreter.getOutputTensor(0).shape[1], 0.0).reshape(interpreter.getOutputTensor(0).shape);

      interpreter.run(inputList, output);

      setState(() {
        _output = List<double>.from(output[0]);
        int maxIndex = _output!.indexOf(_output!.reduce((curr, next) => curr > next ? curr : next));
        _confidence = _output![maxIndex];
        _predictedName = class_names[maxIndex].toLowerCase();
      });

      _pokemonDescription = (await PokemonApi.getPokemonDescription(_predictedName))!;
      setState(() {
        _pokemonDescription = "${_predictedName.toCapitalize()}, $_pokemonDescription";
        _isClassifying = false;
      });

      await flutterTts.speak(_predictedName.toCapitalize());
      await flutterTts.awaitSpeakCompletion(true);
      await Future.delayed(Duration(milliseconds: 1000));
      await flutterTts.speak(_pokemonDescription.substring(_predictedName.length + 2));
    } catch (e) {
      print('Error during classification: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred during classification: $e')),
      );
    } finally {
      setState(() {
        _isClassifying = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFDB2E37),
      appBar: AppBar(
        toolbarHeight: 140,
        backgroundColor: Color(0xFFDB2E37),
        title: null, // Remove the title
        flexibleSpace: SafeArea(
          child: SvgPicture.asset(
            "assets/pokedex-header.svg",
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _image != null
                  ? Image.file(_image!, height: 200)
                  : Text('No image selected'),
              SizedBox(height: 20),
              _isClassifying
                  ? CircularProgressIndicator()
                  : _output != null
                  ? Column(
                children: [
                  Text(
                    'Prediction: ${_predictedName.toCapitalize()} (Confidence: ${(_confidence * 100).toStringAsFixed(2)}%)',
                    style: TextStyle(fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      _pokemonDescription,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              )
                  : SizedBox.shrink(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
          iconSize: 40,
          items: [
        BottomNavigationBarItem(
          icon: IconButton(onPressed: pickImage, icon: Icon(Icons.insert_photo)),
          label: "Select From Gallery",
        ),
        BottomNavigationBarItem(
            icon: IconButton(onPressed: pickImageFromCamera, icon: Icon(Icons.camera)),
            label: "Take a Picture"
        ),
      ]),
    );
  }
}