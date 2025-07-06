import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ActionButtonsFooter extends StatelessWidget {
  final Function(ImageSource source) onPickImage;

  const ActionButtonsFooter({
    Key? key,
    required this.onPickImage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      iconSize: 40,
      items: [
        BottomNavigationBarItem(
          icon: IconButton(
            onPressed: () => onPickImage(ImageSource.gallery),
            icon: const Icon(Icons.insert_photo),
          ),
          label: "Select From Gallery",
        ),
        BottomNavigationBarItem(
          icon: IconButton(
            onPressed: () => onPickImage(ImageSource.camera),
            icon: const Icon(Icons.camera),
          ),
          label: "Take a Picture",
        ),
      ],
    );
  }
}