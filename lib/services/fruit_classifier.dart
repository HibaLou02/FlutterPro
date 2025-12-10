import 'dart:io';
import 'dart:math' as math;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/services.dart' show rootBundle;

class FruitClassifier {
  late final Interpreter _interpreter;
  late final List<String> _labels;
  late final Tensor _inputTensor;
  late final Tensor _outputTensor;

  final bool isQuantized;

  FruitClassifier({this.isQuantized = false});

  Future<void> load() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/model/model.tflite');

      // Get input tensors and verify we have at least one
      final inputTensors = _interpreter.getInputTensors();
      if (inputTensors.isEmpty) {
        throw Exception('No input tensors found in the model');
      }
      _inputTensor = inputTensors.first;

      // Get output tensors and verify we have at least one
      final outputTensors = _interpreter.getOutputTensors();
      if (outputTensors.isEmpty) {
        throw Exception('No output tensors found in the model');
      }
      _outputTensor = outputTensors.first;

      // Load labels
      try {
        final labelsFile =
            await rootBundle.loadString('assets/model/labels.txt');
        _labels = labelsFile
            .split('\n')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      } catch (e) {
        throw Exception('Failed to load labels: $e');
      }
    } catch (e) {
      // Clean up resources if initialization fails
      if (_interpreter != null) {
        _interpreter.close();
      }
      rethrow; // Re-throw to be handled by the UI
    }
  }

  /// Prétraitement image: resize à la taille d'entrée du modèle
  img.Image _preprocess(img.Image image) {
    final s = _inputTensor.shape; // [1, H, W, 3]
    final resized = img.copyResize(
      image,
      width: s[2],
      height: s[1],
      interpolation: img.Interpolation.linear,
    );
    return resized;
  }

  /// Convertit l'image en Tensor input
  Object _imageToInput(img.Image image) {
    final shape = _inputTensor.shape; // ex: [1, H, W, 3]
    final h = shape[1], w = shape[2];

    // Récupère les octets RGB (par défaut sans alpha)
    final rgb = image.getBytes();

    if (isQuantized) {
      // uint8 [1, H, W, 3]
      final input = List.generate(
        1,
        (_) => List.generate(
          h,
          (y) => List.generate(
            w,
            (x) {
              final i = (y * w + x) * 3;
              return [rgb[i], rgb[i + 1], rgb[i + 2]]; // 0..255
            },
          ),
        ),
      );
      return input;
    } else {
      // float32 normalisé [0,1] [1, H, W, 3]
      final input = List.generate(
        1,
        (_) => List.generate(
          h,
          (y) => List.generate(
            w,
            (x) {
              final i = (y * w + x) * 3;
              return [
                rgb[i] / 255.0,
                rgb[i + 1] / 255.0,
                rgb[i + 2] / 255.0,
              ];
            },
          ),
        ),
      );
      return input;
    }
  }

  /// Lance l'inférence et renvoie (label, score)
  Future<MapEntry<String, double>> classifyFile(File file) async {
    final bytes = await file.readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) throw Exception('Image invalide');

    final pre = _preprocess(image);
    final input = _imageToInput(pre);

    // Prépare le buffer de sortie selon la forme du modèle
    final outShape = _outputTensor.shape; // ex: [1, N_CLASSES]
    final nClasses = outShape.last;
    final output = isQuantized
        ? List.generate(1, (_) => List.filled(nClasses, 0))
        : List.generate(1, (_) => List.filled(nClasses, 0.0));

    _interpreter.run(input, output);

    // Convertit en List<double>
    final scores = List<double>.generate(
      nClasses,
      (i) => isQuantized
          ? (output[0][i] as int).toDouble()
          : (output[0][i] as double),
    );

    // Trouve l’indice top-1
    int topIdx = 0;
    double topScore = -1e9;
    for (int i = 0; i < scores.length; i++) {
      if (scores[i] > topScore) {
        topScore = scores[i];
        topIdx = i;
      }
    }

    // Si quantifié, re-scale via quantizationParams si disponibles
    if (isQuantized) {
      final params = _outputTensor.params;
      topScore = params.scale != 0
          ? (scores[topIdx] * params.scale + params.zeroPoint)
          : scores[topIdx];
    }

    final label =
        (topIdx < _labels.length) ? _labels[topIdx] : 'unknown_$topIdx';
    // Softmax optionnel si le modèle ne l’a pas déjà
    final softmax = _softmax(scores)[topIdx];

    return MapEntry(label, softmax);
  }

  List<double> _softmax(List<double> x) {
    final m = x.reduce(math.max);
    final exps = x.map((v) => math.exp(v - m)).toList();
    final sum = exps.reduce((a, b) => a + b);
    return exps.map((e) => e / sum).toList();
  }

  void close() {
    _interpreter.close();
  }
}
