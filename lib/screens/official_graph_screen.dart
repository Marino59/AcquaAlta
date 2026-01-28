import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:photo_view/photo_view.dart';

import 'package:flutter/foundation.dart';

class OfficialGraphScreen extends StatelessWidget {
  const OfficialGraphScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Grafico Ufficiale", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: PhotoView.customChild(
        // Set initial scale to cover to make it visible immediately
        initialScale: PhotoViewComputedScale.covered,
        minScale: PhotoViewComputedScale.contained * 0.5,
        maxScale: PhotoViewComputedScale.covered * 4.0,
        backgroundDecoration: const BoxDecoration(color: Colors.white),
        // Wrap the image in a RotatedBox to turn it 90 degrees clockwise ONLY if in portrait
        child: RotatedBox(
          quarterTurns: MediaQuery.of(context).orientation == Orientation.landscape ? 0 : 1, 
          child: Image.network(
            _getUrl('https://www.comune.venezia.it/sites/default/files/publicCPSM/png/bollettino_grafico.jpg'),
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
               return Column(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                   const Icon(Icons.error_outline, size: 50, color: Colors.red),
                   const SizedBox(height: 10),
                   const Text("Errore caricamento grafico."),
                   TextButton(
                     onPressed: () {}, // Ideally retry
                     child: const Text("Riprova"),
                   )
                 ],
               );
            },
          ),
        ),
      ),
    );
  }

  String _getUrl(String url) {
    if (kIsWeb) {
      // Use images.weserv.nl which is specialized for images and faster/more reliable than generic proxies
      // We strip the scheme because weserv prefers it (or handles it better without double https)
      final uri = Uri.parse(url);
      return 'https://images.weserv.nl/?url=${uri.host}${uri.path}${uri.query}';
    }
    return url;
  }
}
