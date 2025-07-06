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
    // Define the cut properties for the angled corner.
    const double cutBottomHorizontalOffset = 30.0;
    const double cutLeftVerticalOffset = 30.0;

    // Define the thickness of the outer white border
    const double outerWhiteBorderThickness = 25.0; //

    // Calculate total padding required for the image to fit within the borders
    final double totalPaddingForImage = outerWhiteBorderThickness;


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
                  ? SizedBox(
                width: 200 + (totalPaddingForImage * 2), // Original image size + total padding
                height: 200 + (totalPaddingForImage * 2), // Original image size + total padding
                child: CustomPaint(
                  painter: PokedexDisplayPainter(
                    outerBorderColor: Colors.white,
                    outerBorderThickness: outerWhiteBorderThickness,
                    innerBorderColor: Colors.transparent, // Not used for border drawing
                    innerBorderThickness: 0.0, // Not used for border drawing
                    cutBottomHorizontalOffset: cutBottomHorizontalOffset,
                    cutLeftVerticalOffset: cutLeftVerticalOffset,
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(totalPaddingForImage),
                    child: ClipPath(
                      clipper: PokedexImageClipper(
                        cutBottomHorizontalOffset: cutBottomHorizontalOffset,
                        cutLeftVerticalOffset: cutLeftVerticalOffset,
                      ),
                      child: Image.file(
                        _image!,
                        height: 200, // The actual display height of the image within the clip
                        width: 200,  // The actual display width of the image within the clip
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              )
                  : Text('No image selected'),
              SizedBox(height: 20),
              _isClassifying
                  ? CircularProgressIndicator()
                  : _output != null
                  ? Column(
                children: [
                  Text(
                    'Prediction: ${_predictedName.toCapitalize()} (Confidence: ${(_confidence * 100).toStringAsFixed(2)}%)',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Open Sans, Lato',
                        color: Colors.yellowAccent),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      _pokemonDescription,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, fontFamily: 'Open Sans, Lato', color: Colors.white),
                    ),
                  ),
                ],
              )
                  : SizedBox.shrink(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(iconSize: 40, items: [
        BottomNavigationBarItem(
          icon: IconButton(onPressed: pickImage, icon: Icon(Icons.insert_photo)),
          label: "Select From Gallery",
        ),
        BottomNavigationBarItem(
            icon: IconButton(onPressed: pickImageFromCamera, icon: Icon(Icons.camera)),
            label: "Take a Picture"),
      ]),
    );
  }
}

// Custom Painter Class for the Pokedex Display Border
class PokedexDisplayPainter extends CustomPainter {
  final Color outerBorderColor;
  final double outerBorderThickness;
  final Color innerBorderColor; // Not used for border drawing anymore
  final double innerBorderThickness; // Not used for border drawing anymore
  final double cutBottomHorizontalOffset;
  final double cutLeftVerticalOffset;

  PokedexDisplayPainter({
    required this.outerBorderColor,
    required this.outerBorderThickness,
    required this.innerBorderColor,
    required this.innerBorderThickness,
    required this.cutBottomHorizontalOffset,
    required this.cutLeftVerticalOffset,
  });

  // Constants for the two red dots at the top
  static const double topDotRadius = 3.0;
  // Adjusted to fixed pixel offsets from the top edge for more precise placement
  static const double topDotYOffset = 4.0; // Distance from the top outer edge
  static const double topDotHorizontalSpacing = 10.0; // Half the spacing between the two dots

  // Constants for the single red dot at the bottom-left
  static const double bottomLeftDotRadius = 6.0;
  // Adjusted to fixed pixel offsets relative to the cut corner for precise placement
  static const double bottomLeftDotXOffsetFromLeft = 12.0; // Distance from the left outer edge
  static const double bottomLeftDotYOffsetFromBottomCut = 12.0; // Distance from the bottom edge of the cut


  // Constants for the three horizontal black lines
  static const double lineThickness = 2.0; // Thickness of the line itself
  static const double lineHeight = 2.0; // Height of each individual line (same as thickness for solid lines)
  static const double lineWidth = 15.0; // Length of each line
  static const double lineSpacing = 4.0; // Vertical space between lines
  // Adjusted to fixed pixel offsets from the outer edges for precise placement
  static const double linesRightOffsetFromOuterEdge = 20.0; // Distance from the right outer edge of the canvas
  static const double linesBottomOffsetFromOuterEdge = -6.0; // Distance from the bottom outer edge of the canvas

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw the outer (white) border
    final outerPaint = Paint()
      ..color = outerBorderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = outerBorderThickness;

    final outerPath = Path();
    outerPath.moveTo(0, 0); // Top-left
    outerPath.lineTo(size.width, 0); // Top-right
    outerPath.lineTo(size.width, size.height); // Bottom-right
    outerPath.lineTo(cutBottomHorizontalOffset, size.height); // Bottom edge before the cut
    outerPath.lineTo(0, size.height - cutLeftVerticalOffset); // Left edge before the cut
    outerPath.close();

    canvas.drawPath(outerPath, outerPaint);

    // 2. Draw the two red dots at the top
    final dotPaint = Paint()
      ..color = Color.fromARGB(200, 204, 0, 0) //
      ..style = PaintingStyle.fill;

    // Calculate positions for top dots using fixed offsets
    final double topDotY = topDotYOffset;
    final double centerWidth = size.width / 2;

    canvas.drawCircle(Offset(centerWidth - topDotHorizontalSpacing, topDotY), topDotRadius, dotPaint);
    canvas.drawCircle(Offset(centerWidth + topDotHorizontalSpacing, topDotY), topDotRadius, dotPaint);

    // 3. Draw the red dot at the bottom-left
    // Position it using fixed offsets relative to the outer edges or cut
    final double bottomLeftDotX = bottomLeftDotXOffsetFromLeft;
    final double bottomLeftDotY = size.height - cutLeftVerticalOffset + (cutLeftVerticalOffset - bottomLeftDotYOffsetFromBottomCut);

    canvas.drawCircle(Offset(bottomLeftDotX, bottomLeftDotY), bottomLeftDotRadius, dotPaint);

    // 4. Draw the three horizontal black lines
    final linePaint = Paint()
      ..color = Colors.black //
      ..style = PaintingStyle.fill; // Using fill for rectangles

    // Calculate starting Y position for the bottom-most line.
    // Use fixed offsets from the outer edges to place them within the border.
    final double baseLineY = size.height - linesBottomOffsetFromOuterEdge - lineHeight;
    final double baseLineX = size.width - linesRightOffsetFromOuterEdge - lineWidth;

    for (int i = 0; i < 3; i++) {
      // For each line, move it up by its height plus the spacing from the previous line.
      final double currentLineY = baseLineY - (i * (lineHeight + lineSpacing));
      canvas.drawRect(
        Rect.fromLTWH(baseLineX, currentLineY, lineWidth, lineHeight),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is PokedexDisplayPainter) {
      return oldDelegate.outerBorderColor != outerBorderColor ||
          oldDelegate.outerBorderThickness != outerBorderThickness ||
          oldDelegate.cutBottomHorizontalOffset != cutBottomHorizontalOffset ||
          oldDelegate.cutLeftVerticalOffset != cutLeftVerticalOffset;
    }
    return true;
  }
}

// Custom Clipper Class for the Image
class PokedexImageClipper extends CustomClipper<Path> {
  final double cutBottomHorizontalOffset;
  final double cutLeftVerticalOffset;

  PokedexImageClipper({
    required this.cutBottomHorizontalOffset,
    required this.cutLeftVerticalOffset,
  });

  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, 0); // Top-left
    path.lineTo(size.width, 0); // Top-right
    path.lineTo(size.width, size.height); // Bottom-right

    path.lineTo(cutBottomHorizontalOffset, size.height); // Bottom edge before the cut
    path.lineTo(0, size.height - cutLeftVerticalOffset); // Left edge before the cut
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    if (oldClipper is PokedexImageClipper) {
      return oldClipper.cutBottomHorizontalOffset != cutBottomHorizontalOffset ||
          oldClipper.cutLeftVerticalOffset != cutLeftVerticalOffset;
    }
    return false;
  }
}