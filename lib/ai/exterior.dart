import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;
import 'package:truck_check/models/inspection_data.dart';

class ExteriorModel {
  Future<String> getPrediction(InspectionData data) async {
    // print("🧪 Inspection data: ${data.toString()}");

    final interpreter = await tfl.Interpreter.fromAsset("exterior.tflite");

    int exteriorDamage = data.exteriorDamage == 'No' ? 0 : 1;
    int oilLeakSuspension = data.oilLeakSuspension == 'No' ? 0 : 1;

    final input = [
      [0.toDouble(), exteriorDamage.toDouble(), oilLeakSuspension.toDouble()]
    ];

    var output = List.filled(7, 0).reshape([1, 7]);

    // print(input);
    // print(data);

    // Run the model
    interpreter.run(input, output);
    // print("Intrepreting");

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

    // int recommendedIndex = output[0].indexOf(output[0]
    //     .reduce((double curr, double next) => curr > next ? curr : next));

    double maxVal = (output[0] as List<double>)
        .reduce((curr, next) => curr > next ? curr : next);
    int recommendedIndex = (output[0] as List<double>).indexOf(maxVal);

    // print("RECOMENDATION INDEX");
    // print(recommendedIndex);

    return recommendations[recommendedIndex];
  }
}
