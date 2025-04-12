import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;
import 'package:truck_check/models/inspection_data.dart';

class TyreModel {
  Future<String> getPrediction(InspectionData data) async {
    // print("🧪 Inspection data: ${data.toString()}");

    final interpreter = await tfl.Interpreter.fromAsset("tyre.tflite");

    int leftFrontTirePressure = data.leftFrontTirePressure;
    int rightFrontTirePressure = data.rightFrontTirePressure;
    int leftFrontTireCondition = (data.leftFrontTireCondition == "Good")
        ? 0
        : (data.leftFrontTireCondition == "Needs Replacement")
            ? 1
            : 2;
    int rightFrontTireCondition = (data.rightFrontTireCondition == "Good")
        ? 0
        : (data.leftFrontTireCondition == "Needs Replacement")
            ? 1
            : 2;
    int leftRearTirePressure = data.leftRearTirePressure;
    int rightRearTirePressure = data.rightRearTirePressure;
    int leftRearTireCondition = (data.leftRearTireCondition == "Good")
        ? 0
        : (data.leftRearTireCondition == "Needs Replacement")
            ? 1
            : 2;
    int rightRearTireCondition = (data.rightRearTireCondition == "Good")
        ? 0
        : (data.leftRearTireCondition == "Needs Replacement")
            ? 1
            : 2;

    final input = [
      [
        leftFrontTirePressure.toDouble(),
        rightFrontTirePressure.toDouble(),
        leftFrontTireCondition.toDouble(),
        rightFrontTireCondition.toDouble(),
        leftRearTirePressure.toDouble(),
        rightRearTirePressure.toDouble(),
        leftRearTireCondition.toDouble(),
        rightRearTireCondition.toDouble()
      ]
    ];

    var output = List.filled(39, 0).reshape([1, 39]);

    // print(input);
    // print(data);

    // Run the model
    interpreter.run(input, output);
    // print("Intrepreting");

    // Dispose of the interpreter
    interpreter.close();

    // Get the recommendation labels
    final List<String> recommendations = [
      'All tires are in critical condition with very low pressures. Immediate replacement is necessary for both front and rear tires to ensure safety and prevent further damage.',
      'All tires are significantly over-inflated and need immediate replacement.',
      'All tires are significantly over-inflated or need replacement. Immediate attention required.',
      'All tires are significantly under-inflated and need immediate replacement.',
      'All tires are significantly under-inflated and need immediate replacement. Regular maintenance is recommended.',
      'All tires are within acceptable ranges. Regular monitoring is advised.',
      'All tires are within the ideal range. Front tires are good, rear tires are slightly over-inflated but still acceptable.',
      'Front tires are in the ideal range. Rear tires are slightly over-inflated but acceptable.',
      'Front tires are over-inflated, but still acceptable. Rear tires are slightly over-inflated.',
      'Front tires are within the ideal range. Rear tires are slightly over-inflated but still acceptable.',
      'Immediate replacement needed for left front and right rear tires; others are in good condition with acceptable pressures.',
      'Immediate replacement needed for left front tire. Other tires are in good condition with acceptable pressures.',
      'Immediate replacement needed for right front tire; others are in good condition with acceptable pressures.',
      'Immediate replacement needed for right rear tire; others are in good condition with acceptable pressures.',
      'Left front tire is over-inflated and needs replacement. Other tires are within acceptable ranges.',
      'Left front tire is under-inflated, right rear tire needs replacement. Front right tire is good, rear left tire is acceptable.',
      'Left front tire needs immediate replacement due to very low pressure. Other tires are in acceptable ranges.',
      'Left front tire needs immediate replacement due to very low pressure. Other tires are within acceptable ranges.',
      'Left front tire needs replacement; other tires are in good condition with acceptable pressures.',
      'Left rear and right rear tires are under-inflated and need replacement. Other tires are good.',
      'Left rear tire needs immediate replacement due to very low pressure. Other tires are in acceptable ranges.',
      'Left rear tire needs replacement. Other tires are good.',
      'Left rear tire needs replacement; other tires are in acceptable condition and pressure ranges.',
      'Left rear tire needs replacement; other tires are in good condition with acceptable pressures.',
      'One tire needs immediate replacement (right rear), otherwise, other tires are in acceptable condition and pressure ranges.',
      'One tire needs replacement (left rear), others are in good condition with acceptable pressures.',
      'One tire needs replacement (right front), others are in good condition with acceptable pressures.',
      'Overall, one tire needs immediate replacement (left front), while other tires are in good condition with acceptable pressures.',
      'Overall, two tires need immediate replacement (left front and right rear), while other tires are in good condition with acceptable pressures.',
      'Right front tire needs replacement. Other tires are good.',
      'Right rear tire needs replacement. Other tires are good.',
      'The left front tire needs replacement, but other tires',
      'The left front tire needs replacement, but other tires are in good condition with acceptable pressures.',
      'The left rear tire needs replacement, while other tires are in acceptable condition and pressure ranges.',
      'The right rear tire needs replacement, while other tires are in good condition with acceptable pressures.',
      'The tires are generally in good condition with acceptable pressures, except for the left rear tire which needs replacement. Regular monitoring and maintenance recommended.',
      'The tires are generally in good condition with acceptable pressures. Regular monitoring recommended.',
      'Tire pressures vary; monitor for any anomalies.',
      ''
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
