// ignore_for_file: avoid_print

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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

  Future<void> _init() async {
    try {
      // Mets true si ton .tflite est quantifié
      _clf = FruitClassifier(isQuantized: false);
      await _clf.load();
      setState(() {
        _busy = false;
        _status = 'Prêt ✔';
      });
    } catch (e) {
      setState(() {
        _busy = false;
        _status = 'Erreur chargement: $e';
      });
    }
  }

  @override
  void dispose() {
    _clf.close();
    super.dispose();
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fruit Classifier'),
        backgroundColor: Colors.teal,
        elevation: 2,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_busy) const LinearProgressIndicator(minHeight: 3),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(_status,
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Center(
                child: _imageFile == null
                    ? const Text('Choisis une image de fruit 🍎🍌🍊')
                    : Image.file(_imageFile!, fit: BoxFit.contain),
              ),
            ),
            if (_result != null)
              Card(
                child: ListTile(
                  title: Text('Prédiction: $_result'),
                  subtitle: Text(
                      'Confiance: ${((_score ?? 0) * 100).toStringAsFixed(1)} %'),
                ),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.photo),
                    label: const Text('Galerie'),
                    onPressed: _busy ? null : () => _pick(ImageSource.gallery),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Caméra'),
                    onPressed: _busy ? null : () => _pick(ImageSource.camera),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              icon: const Icon(Icons.analytics),
              label: const Text('Classer l’image'),
              onPressed: _busy ? null : _classify,
            ),
          ],
        ),
      ),
    );
  }
}
