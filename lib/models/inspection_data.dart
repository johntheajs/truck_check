import 'dart:io';

class InspectionData {
  int leftFrontTirePressure;
  int rightFrontTirePressure;
  String leftFrontTireCondition;
  String rightFrontTireCondition;
  int leftRearTirePressure;
  int rightRearTirePressure;
  String leftRearTireCondition;
  String rightRearTireCondition;
  String batteryMake;
  String batteryReplacementDate;
  int batteryVoltage;
  String batteryWaterLevel;
  bool batteryDamage;
  bool batteryLeak;
  bool exteriorDamage;
  String exteriorNotes;
  bool oilLeakSuspension;
  String brakeFluidLevel;
  String brakeConditionFront;
  String brakeConditionRear;
  String emergencyBrakeCondition;
  bool engineDamage;
  String engineDamageNotes;
  String engineOilCondition;
  String engineOilColor;
  String brakeFluidCondition;
  String brakeFluidColor;
  String inspectionNotes;
  bool engineOilLeak;

  List<File> tireImages = []; // Initialize lists with empty mutable lists
  List<File> batteryImages = [];
  List<File> exteriorImages = [];
  List<File> brakeImages = [];
  List<File> engineImages = [];

  InspectionData({
    this.leftFrontTirePressure = 0,
    this.rightFrontTirePressure = 0,
    this.leftFrontTireCondition = '',
    this.rightFrontTireCondition = '',
    this.leftRearTirePressure = 0,
    this.rightRearTirePressure = 0,
    this.leftRearTireCondition = '',
    this.rightRearTireCondition = '',
    this.batteryMake = '',
    this.batteryReplacementDate = '',
    this.batteryVoltage = 0,
    this.batteryWaterLevel = 'Good',
    this.batteryDamage = false,
    this.batteryLeak = false,
    this.exteriorDamage = false,
    this.exteriorNotes = '',
    this.oilLeakSuspension = false,
    this.brakeFluidLevel = '',
    this.brakeConditionFront = '',
    this.brakeConditionRear = '',
    this.emergencyBrakeCondition = '',
    this.engineDamage = false,
    this.engineDamageNotes = '',
    this.engineOilCondition = '',
    this.engineOilColor = '',
    this.brakeFluidCondition = '',
    this.brakeFluidColor = '',
    this.engineOilLeak = false,
    this.inspectionNotes=''
  });

  @override
  String toString() {
    return
      'leftFrontTirePressure: $leftFrontTirePressure, '
          'rightFrontTirePressure: $rightFrontTirePressure, '
          'leftFrontTireCondition: $leftFrontTireCondition, '
          'rightFrontTireCondition: $rightFrontTireCondition, '
          'leftRearTirePressure: $leftRearTirePressure, '
          'rightRearTirePressure: $rightRearTirePressure, '
          'leftRearTireCondition: $leftRearTireCondition, '
          'rightRearTireCondition: $rightRearTireCondition, '
          'batteryMake: $batteryMake, '
          'batteryReplacementDate: $batteryReplacementDate, '
          'batteryVoltage: $batteryVoltage, '
          'batteryWaterLevel: $batteryWaterLevel, '
          'batteryDamage: $batteryDamage, '
          'batteryLeak: $batteryLeak, '
          'exteriorDamage: $exteriorDamage, '
          'exteriorNotes: $exteriorNotes, '
          'oilLeakSuspension: $oilLeakSuspension, '
          'brakeFluidLevel: $brakeFluidLevel, '
          'brakeConditionFront: $brakeConditionFront, '
          'brakeConditionRear: $brakeConditionRear, '
          'emergencyBrakeCondition: $emergencyBrakeCondition, '
          'engineDamage: $engineDamage, '
          'engineDamageNotes: $engineDamageNotes, '
          'engineOilCondition: $engineOilCondition, '
          'engineOilColor: $engineOilColor, '
          'brakeFluidCondition: $brakeFluidCondition, '
          'brakeFluidColor: $brakeFluidColor, '
          'engineOilLeak: $engineOilLeak';
  }
}
