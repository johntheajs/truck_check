import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;
import 'package:truck_check/models/inspection_data.dart';

class EngineModel {
  Future<String> getPrediction(InspectionData data) async {
    // Load the TFLite interpreter
    final interpreter = await tfl.Interpreter.fromAsset("assets/engine.tflite");

    // Map inspection data to integer values
    int engineDamage = data.engineDamage ? 1 : 0;
    int engineOilCondition = (data.engineOilCondition == "Good") ? 1 : 0;
    int engineOilColor = (data.engineOilColor == "Black")
        ? 0
        : (data.engineOilColor == "Brown")
            ? 1
            : 2;
    int brakeFluidCondition = (data.brakeFluidCondition == "Bad") ? 0 : 1;
    int brakeFluidColor = (data.brakeFluidColor == "Black")
        ? 0
        : (data.brakeFluidColor == "Brown")
            ? 1
            : 2;
    int engineOilLeak = data.engineOilLeak ? 1 : 0;

    // Prepare the input tensor
    final input = [
      [
        engineDamage,
        engineOilCondition,
        engineOilColor,
        brakeFluidCondition,
        brakeFluidColor,
        engineOilLeak
      ]
    ];

    // Prepare the output tensor
    var output = List.filled(12, 0).reshape([1, 12]);

    // Run the model
    interpreter.run(input, output);

    // Dispose of the interpreter
    interpreter.close();

    // Get the recommendation labels
    List<String> recommendations = [
      'Adjust tension',
      'Change oil',
      'Check fittings',
      'Check levels',
      'Check seals',
      'Clean connections',
      'Flush system',
      'Inspect hoses',
      'Replace cap',
      'Replace filter',
      'Replace gasket',
      'Replace seals'
    ];

    // Find the index of the highest probability
    int recommendedIndex = output[0].indexOf(output[0]
        .reduce((double curr, double next) => curr > next ? curr : next));

    print("RECOMENDATION INDEX");

    print(recommendedIndex);

    return recommendations[recommendedIndex];
  }
}
