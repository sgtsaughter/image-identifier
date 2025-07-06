// lib/widgets/action_buttons_footer.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ActionButtonsFooter extends StatelessWidget {
  final Function(ImageSource source) onPickImage;
  final VoidCallback onViewList; // New: Callback for the List button

  const ActionButtonsFooter({
    Key? key,
    required this.onPickImage,
    required this.onViewList, // New: Make it required
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      iconSize: 40, // Keeping this hardcoded as per your decision
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
        // New BottomNavigationBarItem for the "List" page
        BottomNavigationBarItem(
          icon: IconButton(
            onPressed: onViewList, // Use the new callback
            icon: const Icon(Icons.list), // A suitable icon for a list
          ),
          label: "List",
        ),
      ],
    );
  }
}