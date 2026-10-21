import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/theme.dart';

/// Repli non-web : la vitrine publique n'est servie qu'en build web
/// (team-oustad.com), mais ce fichier partagé est quand même compilé sur
/// toutes les plateformes — ici une carte cliquable ouvrant Maps en externe
/// plutôt qu'un iframe (API web-only, voir gym_map_embed_web.dart).
class GymMapEmbed extends StatelessWidget {
  final String address;
  final double height;
  final BorderRadius borderRadius;

  const GymMapEmbed({
    super.key,
    required this.address,
    this.height = 220,
    this.borderRadius = const BorderRadius.all(Radius.circular(18)),
  });

  Future<void> _open() async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: InkWell(
        onTap: _open,
        child: Container(
          height: height,
          width: double.infinity,
          color: AppColors.darkElevated,
          child: const Center(
            child: Icon(Icons.map_rounded, color: AppColors.primary, size: 40),
          ),
        ),
      ),
    );
  }
}
