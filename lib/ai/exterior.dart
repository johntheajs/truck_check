import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;
import 'package:truck_check/models/inspection_data.dart';

class ExteriorModel {
  Future<String> getPrediction(InspectionData data) async {
    final interpreter =
        await tfl.Interpreter.fromAsset("assets/exterior.tflite");

    int exteriorDamage = data.exteriorDamage == 'No' ? 0 : 1;
    int oilLeakSuspension = data.oilLeakSuspension == 'No' ? 0 : 1;

    final input = [
      [0, exteriorDamage, oilLeakSuspension]
    ];

    var output = List.filled(7, 0).reshape([1, 7]);

    // Run the model
    interpreter.run(input, output);

    // Dispose of the interpreter
    interpreter.close();

    // Get the recommendation labels
    List<String> recommendations = [
      'Check and fix suspension', // 0
      'Clean and apply rustproof', // 1
      'Clean rust, repaint', // 2
      'Fix rust, check suspension', // 3
      'No action needed', // 4
      'Repair exterior and fix suspension', // 5
      'Repair exterior damage' // 6
    ];

    int recommendedIndex = output[0].indexOf(output[0]
        .reduce((double curr, double next) => curr > next ? curr : next));

    print("RECOMENDATION INDEX");
    print(recommendedIndex);

    return recommendations[recommendedIndex];
  }
}
