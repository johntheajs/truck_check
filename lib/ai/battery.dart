import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;
import 'package:truck_check/models/inspection_data.dart';

class BatteryModel {
  Future<String> getPrediction(InspectionData data) async {
    // Load the TFLite interpreter
    final interpreter =
        await tfl.Interpreter.fromAsset("assets/battery.tflite");

    // Map inspection data to integer values
    int batteryMake = data.batteryMake == 'CAT' ? 0 : 1;
    int batteryVoltage = data.batteryVoltage;
    int batteryWaterLevel = data.batteryWaterLevel == 'Good'
        ? 0
        : data.batteryWaterLevel == 'Low'
            ? 1
            : 2;
    int batteryCondition = data.batteryDamage == 'Yes' ? 1 : 0;
    int batteryLeak = data.batteryLeak == 'Yes' ? 1 : 0;

    // Prepare the input tensor
    final input = [
      [
        batteryMake,
        1,
        batteryVoltage,
        batteryWaterLevel,
        batteryCondition,
        batteryLeak
      ]
    ];

    // Prepare the output tensor
    var output = List.filled(45, 0).reshape([1, 45]);

    // Run the model
    interpreter.run(input, output);

    // Dispose of the interpreter
    interpreter.close();

    // Get the recommendation labels
    List<String> recommendations = [
      "Battery has low voltage and rust, replace battery.",
      "Battery has low voltage and rust, replace soon.",
      "Battery has low voltage and shows rust, replace immediately.",
      "Battery is in fairly good condition, water level needs occasional checking.",
      "Battery is in fairly good condition, water level needs regular checking. Replacement not needed immediately.",
      "Battery is in good condition, monitor voltage, replacement not needed immediately.",
      "Battery is in good condition, no replacement needed.",
      "Battery is in good condition, replacement not needed immediately.",
      "Battery is in good condition, water level needs occasional checking.",
      "Battery is in good condition, water level needs occasional checking. Replacement not needed immediately.",
      "Battery is old with low voltage and rust, replace battery.",
      "Battery is old with low voltage and signs of rust. Replacement recommended",
      "Battery is old with low voltage and signs of rust. Replacement recommended.",
      "Battery is old with low voltage and water level, replace battery.",
      "Battery is old, low voltage and rust present, replace battery soon.",
      "Battery is old, voltage low, water level low, and shows rust. Replace battery soon.",
      "Battery is old, voltage low, water level low, and shows rust. Replace battery.",
      "Battery is very old with low voltage and rust, replace battery urgently.",
      "Battery is very old with low voltage and rust, replace urgently.",
      "Battery is very old with low voltage and significant rust, replace urgently.",
      "Battery is very old, voltage very low, and water level is low with rust. Replace battery urgently.",
      "Battery shows significant wear, low voltage, and rust. Replace battery soon.",
      "Battery shows significant wear, low voltage, and rust. Replace battery.",
      "Battery shows signs of damage and leakage, replace immediately.",
      "Battery shows signs of damage and leakage, replace soon.",
      "Battery shows signs of damage, low voltage and rust, replace battery soon.",
      "Battery shows signs of damage, low voltage and rust, replace battery.",
      "Battery shows signs of wear, low voltage and rust, replace battery.",
      "Battery shows signs of wear, low voltage and rust, replace soon.",
      "Battery shows signs of wear, low voltage, and rust, replace battery.",
      "Battery shows signs of wear, replace soon.",
      "Battery voltage is low, consider replacement soon.",
      "Battery voltage is normal, but water level is low. Check water level regularly, replacement not needed immediately.",
      "Battery voltage is normal, water level needs checking.",
      "Battery voltage is normal, water level needs checking. Replacement not needed immediately.",
      "Battery voltage is normal, water level needs occasional checking.",
      "Battery voltage is normal, water level needs regular checking.",
      "Battery voltage is slightly low, but overall in good condition.",
      "Battery voltage is slightly low, check water level regularly.",
      "Battery voltage is slightly low, monitor regularly.",
      "Battery voltage is slightly low, water level needs checking.",
      "Battery voltage slightly low, but overall in good condition. Monitor voltage, replacement not needed immediately.",
      "Battery voltage slightly low, check water level regularly. Replacement not needed immediately.",
      "Battery voltage slightly low, monitor regularly. Replacement not needed immediately.",
      "Battery voltage slightly low, water level needs checking. Replacement not needed immediately."
    ];

    // Find the index of the highest probability
    int recommendedIndex = output[0].indexOf(output[0]
        .reduce((double curr, double next) => curr > next ? curr : next));
    print("RECOMENDATION INDEX");

    print(recommendedIndex);

    return recommendations[recommendedIndex];
  }
}
