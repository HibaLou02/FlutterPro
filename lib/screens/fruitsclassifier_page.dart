// ignore_for_file: avoid_print

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/fruit_classifier.dart';

class FruitsClassifierPage extends StatefulWidget {
  const FruitsClassifierPage({super.key});

  @override
  State<FruitsClassifierPage> createState() => _FruitsClassifierPageState();
}

class _FruitsClassifierPageState extends State<FruitsClassifierPage> {
  final _picker = ImagePicker();
  late final FruitClassifier _clf;

  File? _imageFile;
  String? _result;
  double? _score;
  bool _busy = true;
  String _status = 'Chargement du modèle…';

  @override
  void initState() {
    super.initState();
    print('FruitsClassifierPage loaded');
    _init();
  }

  @override
  void dispose() {
    _clf.close();
    super.dispose();
  }

  Future<void> _init() async {
    try {
      setState(() {
        _busy = true;
        _status = 'Chargement du modèle...';
      });

      // Initialisation du classifieur
      _clf = FruitClassifier(isQuantized: false);

      // Chargement du modèle de manière asynchrone
      await _clf.load().then((_) {
        if (mounted) {
          setState(() {
            _busy = false;
            _status = 'Prêt ✔';
          });
        }
      }).catchError((error) {
        if (mounted) {
          setState(() {
            _busy = false;
            _status = 'Erreur lors du chargement du modèle: $error';
          });
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _status = 'Erreur initialisation: $e';
        });
      }
    }
  }

  Future<void> _pick(ImageSource source) async {
    final x = await _picker.pickImage(
        source: source, maxWidth: 1024, imageQuality: 95);
    if (x == null) return;
    setState(() {
      _imageFile = File(x.path);
      _result = null;
      _score = null;
    });
  }

  Future<void> _showResultModal(BuildContext context) async {
    if (_result == null || _score == null) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Résultat de la classification'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Fruit: $_result'),
              Text('Confiance: ${((_score ?? 0) * 100).toStringAsFixed(1)} %'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fermer'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _classify() async {
    if (_imageFile == null) return;
    setState(() => _busy = true);
    try {
      final res = await _clf.classifyFile(_imageFile!);
      setState(() {
        _result = res.key;
        _score = res.value;
      });
      await _showResultModal(context); // Show modal after classification
    } catch (e) {
      setState(() => _status = 'Erreur inférence: $e');
    } finally {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isImageSelected = _imageFile != null;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Fruit Classifier',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.teal,
        elevation: 0,
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_busy)
              LinearProgressIndicator(
                minHeight: 3,
                backgroundColor: Colors.teal[100],
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.teal),
              ),
            if (!_busy && _status != 'Prêt ✔')
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  color: _status.contains('Erreur')
                      ? Colors.red[50]
                      : Colors.teal[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      _status.contains('Erreur')
                          ? Icons.error_outline
                          : Icons.info_outline,
                      color:
                          _status.contains('Erreur') ? Colors.red : Colors.teal,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _status,
                        style: TextStyle(
                          color: _status.contains('Erreur')
                              ? Colors.red[800]
                              : Colors.teal[800],
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Image Preview Card
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: double.infinity,
                        height: isImageSelected ? size.height * 0.4 : 200,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: _imageFile == null
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.photo_library_rounded,
                                    size: 60,
                                    color: Colors.grey[300],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Aucune image sélectionnée',
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Choisis une image de fruit 🍎🍌🍊',
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 14,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Image.file(
                                  _imageFile!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                ),
                              ),
                      ),
                      const SizedBox(height: 24),

                      // Prediction Result
                      if (_result != null)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.teal[50],
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.analytics,
                                      color: Colors.teal,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Résultat de l\'analyse',
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          _result!,
                                          style: GoogleFonts.poppins(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.teal[900],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getConfidenceColor(_score ?? 0),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${((_score ?? 0) * 100).toStringAsFixed(0)}%',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              LinearProgressIndicator(
                                value: _score ?? 0,
                                backgroundColor: Colors.grey[200],
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  _getConfidenceColor(_score ?? 0),
                                ),
                                minHeight: 8,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom Action Buttons
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.photo_library_rounded,
                          label: 'Galerie',
                          color: Colors.teal,
                          onPressed:
                              _busy ? null : () => _pick(ImageSource.gallery),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.camera_alt_rounded,
                          label: 'Caméra',
                          color: Colors.blue,
                          onPressed:
                              _busy ? null : () => _pick(ImageSource.camera),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _busy || !isImageSelected ? null : _classify,
                      icon: const Icon(Icons.analytics_rounded, size: 20),
                      label: const Text('Analyser l\'image'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                        textStyle: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: color),
      label: Text(
        label,
        style: TextStyle(color: color),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        side: BorderSide(color: color.withOpacity(0.3)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Color _getConfidenceColor(double score) {
    if (score > 0.7) return Colors.green;
    if (score > 0.4) return Colors.orange;
    return Colors.red;
  }
}
