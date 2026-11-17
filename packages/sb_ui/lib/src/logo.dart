import 'package:flutter/material.dart';

enum SbLogoVariant { full, mark, horizontal }

/// SpongeBubble logo. The artwork has a navy background, so place it on
/// navy surfaces (headers, sidebar, splash).
class SbLogo extends StatelessWidget {
  const SbLogo({super.key, this.variant = SbLogoVariant.full, this.height = 40});

  final SbLogoVariant variant;
  final double height;

  @override
  Widget build(BuildContext context) {
    final file = switch (variant) {
      SbLogoVariant.full => 'assets/logo_full.png',
      SbLogoVariant.mark => 'assets/logo_mark.png',
      SbLogoVariant.horizontal => 'assets/logo_horizontal.png',
    };
    return Image.asset(file, package: 'sb_ui', height: height, fit: BoxFit.contain, semanticLabel: 'SpongeBubble');
  }
}
