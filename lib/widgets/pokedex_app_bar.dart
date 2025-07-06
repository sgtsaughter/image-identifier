import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class PokedexAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Animation<double> blinkingAnimation;

  const PokedexAppBar({
    Key? key,
    required this.blinkingAnimation,
  }) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(140);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: preferredSize.height,
      backgroundColor: const Color(0xFFDB2E37),
      title: null, // Remove the title
      flexibleSpace: SafeArea(
        child: Stack(
          children: [
            SvgPicture.asset(
              "assets/pokedex-header.svg",
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
            Positioned(
              top: 20, // Adjusted as per previous discussion
              left: 16, // Adjusted as per previous discussion
              child: FadeTransition(
                opacity: blinkingAnimation,
                child: Container(
                  width: 75,
                  height: 75,
                  decoration: BoxDecoration(
                    color: Colors.cyanAccent.withOpacity(0.7),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}