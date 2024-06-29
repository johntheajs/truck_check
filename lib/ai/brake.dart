import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;
import 'package:truck_check/models/inspection_data.dart';

class BrakeModel {
  Future<String> getPrediction(InspectionData data) async {

    final interpreter = await tfl.Interpreter.fromAsset("assets/brake.tflite");

    int brakeFluidLevel = data.brakeFluidLevel=='Good'?0:data.brakeFluidLevel=='Ok'?2:1;
    int brakeConditionFront = data.brakeConditionFront=='Good'?0:data.brakeConditionFront=='Ok'?2:1;
    int brakeConditionRear = data.brakeConditionRear=='Good'?0:data.brakeConditionRear=='Ok'?2:1;
    int emergencyBrake = data.emergencyBrakeCondition=='Good'?0:data.emergencyBrakeCondition=='Ok'?2:1;
    final input = [
      [brakeFluidLevel,brakeConditionFront, brakeConditionRear, emergencyBrake]
    ];

    var output = List.filled(7, 0).reshape([1, 7]);

    // Run the model
    interpreter.run(input, output);

    // Dispose of the interpreter
    interpreter.close();

    // Get the recommendation labels
    List<String> recommendations = [
      "All components functioning adequately, sufficient fluid.",
      "All components in good condition, adequate brake fluid.",
      "All components in good condition, sufficient brake fluid.",
      "Front brakes good, rear brakes okay, adequate fluid.",
      "Front brakes need replacement, rear brakes okay, good fluid.",
      "Front brakes okay, rear brakes good, adequate fluid.",
      "Low emergency brake, both brakes need replacement, low fluid."
    ];



    int recommendedIndex = output[0].indexOf(output[0].reduce((double curr, double next) => curr > next ? curr : next));

    return recommendations[recommendedIndex];
  }
}
