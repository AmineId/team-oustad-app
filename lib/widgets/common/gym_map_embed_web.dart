import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

final Set<String> _registeredMapViews = {};

/// Carte Google Maps intégrée via iframe (pas de clé API nécessaire, format
/// d'embed public standard) — construite uniquement à partir de l'adresse
/// texte de la salle, aucune coordonnée GPS stockée côté serveur.
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

  @override
  Widget build(BuildContext context) {
    final viewType = 'gym-map-embed-${address.hashCode}';
    if (_registeredMapViews.add(viewType)) {
      ui_web.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
        final iframe = web.HTMLIFrameElement()
          ..src =
              'https://www.google.com/maps?q=${Uri.encodeComponent(address)}&output=embed'
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100%'
          ..loading = 'lazy';
        return iframe;
      });
    }
    return ClipRRect(
      borderRadius: borderRadius,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: HtmlElementView(viewType: viewType),
      ),
    );
  }
}
