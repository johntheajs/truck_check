import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:truck_check/models/inspection_data.dart';
import 'package:truck_check/screens/summary.dart';


class CarPartsScreen extends StatefulWidget {

  final inspectionData;
  const CarPartsScreen ({ Key? key, this.inspectionData }): super(key: key);

  @override
  _CarPartsScreenState createState() => _CarPartsScreenState();
}

class _CarPartsScreenState extends State<CarPartsScreen> {
  bool _showTiresForm = false;
  bool _showBatteryForm = false;
  bool _showExteriorForm = false;
  bool _showBrakesForm = false;
  bool _showEngineForm = false;


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text(
            'Car Parts Inspection',
            style: TextStyle(color: Colors.black),
          ),
        ),
        backgroundColor: Color(0xFFFDB813), // Yellow background
      ),
      body: Container(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              _buildHeader('Tires', () {
                setState(() {
                  _showTiresForm = !_showTiresForm;
                });
              }),
              if (_showTiresForm) TiresForm(inspectionData: widget.inspectionData),
              _buildHeader('Battery', () {
                setState(() {
                  _showBatteryForm = !_showBatteryForm;
                });
              }),
              if (_showBatteryForm) BatteryForm(inspectionData: widget.inspectionData),
              _buildHeader('Exterior', () {
                setState(() {
                  _showExteriorForm = !_showExteriorForm;
                });
              }),
              if (_showExteriorForm) ExteriorForm(inspectionData: widget.inspectionData),
              _buildHeader('Brakes', () {
                setState(() {
                  _showBrakesForm = !_showBrakesForm;
                });
              }),
              if (_showBrakesForm) BrakesForm(inspectionData: widget.inspectionData),
              _buildHeader('Engine', () {
                setState(() {
                  _showEngineForm = !_showEngineForm;
                });
              }),
              if (_showEngineForm) EngineForm(inspectionData: widget.inspectionData),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SummaryPage(inspectionData: widget.inspectionData),
                    ),
                  );
                },
                child: Text('Generate Summary'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String title, VoidCallback onTap) {
    return ListTile(
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      trailing: Icon(
        _showTiresForm ? Icons.arrow_drop_up : Icons.arrow_drop_down,
      ),
      onTap: onTap,
    );
  }
}

class TiresForm extends StatefulWidget {
  final InspectionData inspectionData;

  TiresForm({required this.inspectionData});

  @override
  State<TiresForm> createState() => _TiresFormState();
}

class _TiresFormState extends State<TiresForm> {
  int? leftFrontPressure;
  int? rightFrontPressure;
  String? leftFrontCondition;
  String? rightFrontCondition;
  int? leftRearPressure;
  int? rightRearPressure;
  String? leftRearCondition;
  String? rightRearCondition;

  void _pickImage(BuildContext context, Function(File) onImageSelected) async {
    final ImagePicker _picker = ImagePicker();

    // Pick an image
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      File pickedFile = File(image.path);
      onImageSelected(pickedFile);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: 'Tire Pressure for Left Front (in psi)'),
          onChanged: (value) {
            setState(() {
              leftFrontPressure = int.tryParse(value);
              widget.inspectionData.leftFrontTirePressure = leftFrontPressure ?? 0;
            });
          },
        ),
        TextField(
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: 'Tire Pressure for Right Front (in psi)'),
          onChanged: (value) {
            setState(() {
              rightFrontPressure = int.tryParse(value);
              widget.inspectionData.rightFrontTirePressure = rightFrontPressure ?? 0;
            });
          },
        ),
        DropdownButtonFormField<String>(
          value: leftFrontCondition,
          decoration: InputDecoration(labelText: 'Tire Condition for Left Front'),
          items: ['Good', 'Ok', 'Needs Replacement']
              .map((condition) => DropdownMenuItem(
            value: condition,
            child: Text(condition),
          ))
              .toList(),
          onChanged: (value) {
            setState(() {
              leftFrontCondition = value;
              widget.inspectionData.leftFrontTireCondition = value!;
            });
          },
        ),
        DropdownButtonFormField<String>(
          value: rightFrontCondition,
          decoration: InputDecoration(labelText: 'Tire Condition for Right Front'),
          items: ['Good', 'Ok', 'Needs Replacement']
              .map((condition) => DropdownMenuItem(
            value: condition,
            child: Text(condition),
          ))
              .toList(),
          onChanged: (value) {
            setState(() {
              rightFrontCondition = value;
              widget.inspectionData.rightFrontTireCondition = value!;
            });
          },
        ),
        TextField(
          decoration: InputDecoration(labelText: 'Tire Pressure for Left Rear'),
          keyboardType: TextInputType.number,
          onChanged: (value) {
            setState(() {
              leftRearPressure = int.tryParse(value);
              widget.inspectionData.leftRearTirePressure = leftRearPressure ?? 0;
            });
          },
        ),
        TextField(
          decoration: InputDecoration(labelText: 'Tire Pressure for Right Rear'),
          keyboardType: TextInputType.number,
          onChanged: (value) {
            setState(() {
              rightRearPressure = int.tryParse(value);
              widget.inspectionData.rightRearTirePressure = rightRearPressure ?? 0;
            });
          },
        ),
        DropdownButtonFormField<String>(
          value: leftRearCondition,
          decoration: InputDecoration(labelText: 'Tire Condition for Left Rear'),
          items: ['Good', 'Ok', 'Needs Replacement']
              .map((condition) => DropdownMenuItem(
            value: condition,
            child: Text(condition),
          ))
              .toList(),
          onChanged: (value) {
            setState(() {
              leftRearCondition = value;
              widget.inspectionData.leftRearTireCondition = value!;
            });
          },
        ),
        DropdownButtonFormField<String>(
          value: rightRearCondition,
          decoration: InputDecoration(labelText: 'Tire Condition for Right Rear'),
          items: ['Good', 'Ok', 'Needs Replacement']
              .map((condition) => DropdownMenuItem(
            value: condition,
            child: Text(condition),
          ))
              .toList(),
          onChanged: (value) {
            setState(() {
              rightRearCondition = value;
              widget.inspectionData.rightRearTireCondition = value!;
            });
          },
        ),
        SizedBox(height: 10),
        Text(
          'Attached Images:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 5),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: widget.inspectionData.tireImages.map((image) {
            return Stack(
              children: [
                Image.file(image, width: 100, height: 100, fit: BoxFit.cover),
                Positioned(
                  right: 0,
                  top: 0,
                  child: IconButton(
                    icon: Icon(Icons.remove_circle),
                    onPressed: () {
                      setState(() {
                        widget.inspectionData.tireImages.remove(image);
                      });
                    },
                  ),
                ),
              ],
            );
          }).toList(),
        ),
        SizedBox(height: 10),
        ElevatedButton(
          onPressed: () {
            _pickImage(context, (file) {
              setState(() {
                widget.inspectionData.tireImages.add(file);
              });
            });
          },
          child: Text('Attach images of tire'),
        ),
      ],
    );
  }
}


class BatteryForm extends StatefulWidget {
  final InspectionData inspectionData;

  BatteryForm({required this.inspectionData});

  @override
  _BatteryFormState createState() => _BatteryFormState();
}

class _BatteryFormState extends State<BatteryForm> {
  DateTime? _selectedDate;
  String? _selectedWaterLevel;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate)
      setState(() {
        _selectedDate = picked;
        widget.inspectionData.batteryReplacementDate = DateFormat('yyyy-MM-dd').format(picked);
      });
  }

  void _pickImage(BuildContext context, Function(File) onImageSelected) async {
    final ImagePicker _picker = ImagePicker();

    // Pick an image
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      File pickedFile = File(image.path);
      onImageSelected(pickedFile);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          decoration: InputDecoration(labelText: 'Battery Make'),
          onChanged: (value) {
            widget.inspectionData.batteryMake = value;
          },
        ),
        ListTile(
          title: Text(
            "Battery Replacement Date: ${_selectedDate == null ? "Not set" : DateFormat('yyyy-MM-dd').format(_selectedDate!)}",
          ),
          trailing: Icon(Icons.calendar_today),
          onTap: () => _selectDate(context),
        ),
        TextField(
          decoration: InputDecoration(labelText: 'Battery Voltage'),
          keyboardType: TextInputType.number,
          onChanged: (value) {
            widget.inspectionData.batteryVoltage = int.tryParse(value) ?? 0;
          },
        ),
        DropdownButtonFormField<String>(
          value: _selectedWaterLevel,
          decoration: InputDecoration(labelText: 'Battery Water Level'),
          items: ['Good', 'Ok', 'Low']
              .map((level) => DropdownMenuItem(
            value: level,
            child: Text(level),
          ))
              .toList(),
          onChanged: (value) {
            setState(() {
              _selectedWaterLevel = value;
              widget.inspectionData.batteryWaterLevel = value!;
            });
          },
        ),
        CheckboxListTile(
          title: Text('Condition of Battery (Any damage)'),
          value: widget.inspectionData.batteryDamage,
          onChanged: (value) {
            setState(() {
              widget.inspectionData.batteryDamage = value!;
            });
          },
        ),
        CheckboxListTile(
          title: Text('Any Leak / Rust in Battery'),
          value: widget.inspectionData.batteryLeak,
          onChanged: (value) {
            setState(() {
              widget.inspectionData.batteryLeak = value!;
            });
          },
        ),
        SizedBox(height: 10),
        Text(
          'Attached Images:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 5),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: widget.inspectionData.batteryImages.map((image) {
            return Stack(
              children: [
                Image.file(image, width: 100, height: 100, fit: BoxFit.cover),
                Positioned(
                  right: 0,
                  top: 0,
                  child: IconButton(
                    icon: Icon(Icons.remove_circle),
                    onPressed: () {
                      setState(() {
                        widget.inspectionData.batteryImages.remove(image);
                      });
                    },
                  ),
                ),
              ],
            );
          }).toList(),
        ),
        SizedBox(height: 10),
        ElevatedButton(
          onPressed: () {
            _pickImage(context, (file) {
              setState(() {
                widget.inspectionData.batteryImages.add(file);
              });
            });
          },
          child: Text('Attach images of battery'),
        ),
      ],
    );
  }
}

class ExteriorForm extends StatefulWidget {
  final InspectionData inspectionData;

  ExteriorForm({required this.inspectionData});

  @override
  _ExteriorFormState createState() => _ExteriorFormState();
}

class _ExteriorFormState extends State<ExteriorForm> {
  void _pickImage(BuildContext context, Function(File) onImageSelected) async {
    final ImagePicker _picker = ImagePicker();

    // Pick an image
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      File pickedFile = File(image.path);
      onImageSelected(pickedFile);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CheckboxListTile(
          title: Text('Rust, Dent or Damage to Exterior'),
          value: widget.inspectionData.exteriorDamage,
          onChanged: (value) {
            setState(() {
              widget.inspectionData.exteriorDamage = value!;
            });
          },
        ),
        TextField(
          decoration: InputDecoration(labelText: 'Explain in notes'),
          onChanged: (value) {
            setState(() {
              widget.inspectionData.exteriorNotes = value;
            });
          },
        ),
        CheckboxListTile(
          title: Text('Oil leak in Suspension'),
          value: widget.inspectionData.oilLeakSuspension,
          onChanged: (value) {
            setState(() {
              widget.inspectionData.oilLeakSuspension = value!;
            });
          },
        ),
        SizedBox(height: 10),
        Text(
          'Attached Images:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 5),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: widget.inspectionData.exteriorImages.map((image) {
            return Stack(
              children: [
                Image.file(image, width: 100, height: 100, fit: BoxFit.cover),
                Positioned(
                  right: 0,
                  top: 0,
                  child: IconButton(
                    icon: Icon(Icons.remove_circle),
                    onPressed: () {
                      setState(() {
                        // Remove the image from the list
                        widget.inspectionData.exteriorImages.remove(image);
                      });
                    },
                  ),
                ),
              ],
            );
          }).toList(),
        ),
        SizedBox(height: 10),
        ElevatedButton(
          onPressed: () {
            _pickImage(context, (file) {
              setState(() {
                // Add the picked image to the list
                widget.inspectionData.exteriorImages.add(file);
              });
            });
          },
          child: Text('Attach images of exterior'),
        ),
      ],
    );
  }
}

class BrakesForm extends StatefulWidget {
  final InspectionData inspectionData;

  BrakesForm({required this.inspectionData});

  @override
  _BrakesFormState createState() => _BrakesFormState();
}

class _BrakesFormState extends State<BrakesForm> {
  String? _selectedFluidLevel;
  String? _selectedConditionFront;
  String? _selectedConditionRear;
  String? _selectedEmergencyBrakeCondition;

  void _pickImage(BuildContext context, Function(File) onImageSelected) async {
    final ImagePicker _picker = ImagePicker();

    // Pick an image
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      File pickedFile = File(image.path);
      onImageSelected(pickedFile);
    }
  }

  @override
  void initState() {
    super.initState();
    // Initialize selected values from inspectionData if they are not already set
    _selectedFluidLevel = widget.inspectionData.brakeFluidLevel.isNotEmpty
        ? widget.inspectionData.brakeFluidLevel
        : null;
    _selectedConditionFront = widget.inspectionData.brakeConditionFront.isNotEmpty
        ? widget.inspectionData.brakeConditionFront
        : null;
    _selectedConditionRear = widget.inspectionData.brakeConditionRear.isNotEmpty
        ? widget.inspectionData.brakeConditionRear
        : null;
    _selectedEmergencyBrakeCondition = widget.inspectionData.emergencyBrakeCondition.isNotEmpty
        ? widget.inspectionData.emergencyBrakeCondition
        : null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value: _selectedFluidLevel,
          decoration: InputDecoration(labelText: 'Brake Fluid Level'),
          items: ['Good', 'Ok', 'Low']
              .map((level) => DropdownMenuItem(
            value: level,
            child: Text(level),
          ))
              .toList(),
          onChanged: (value) {
            setState(() {
              _selectedFluidLevel = value;
              widget.inspectionData.brakeFluidLevel = value!;
            });
          },
        ),
        DropdownButtonFormField<String>(
          value: _selectedConditionFront,
          decoration: InputDecoration(labelText: 'Brake Condition for Front'),
          items: ['Good', 'Ok', 'Needs Replacement']
              .map((condition) => DropdownMenuItem(
            value: condition,
            child: Text(condition),
          ))
              .toList(),
          onChanged: (value) {
            setState(() {
              _selectedConditionFront = value;
              widget.inspectionData.brakeConditionFront = value!;
            });
          },
        ),
        DropdownButtonFormField<String>(
          value: _selectedConditionRear,
          decoration: InputDecoration(labelText: 'Brake Condition for Rear'),
          items: ['Good', 'Ok', 'Needs Replacement']
              .map((condition) => DropdownMenuItem(
            value: condition,
            child: Text(condition),
          ))
              .toList(),
          onChanged: (value) {
            setState(() {
              _selectedConditionRear = value;
              widget.inspectionData.brakeConditionRear = value!;
            });
          },
        ),
        DropdownButtonFormField<String>(
          value: _selectedEmergencyBrakeCondition,
          decoration: InputDecoration(labelText: 'Emergency Brake'),
          items: ['Good', 'Ok', 'Low']
              .map((condition) => DropdownMenuItem(
            value: condition,
            child: Text(condition),
          ))
              .toList(),
          onChanged: (value) {
            setState(() {
              _selectedEmergencyBrakeCondition = value;
              widget.inspectionData.emergencyBrakeCondition = value!;
            });
          },
        ),
        SizedBox(height: 10),
        Text(
          'Attached Images:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 5),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: widget.inspectionData.brakeImages.map((image) {
            return Stack(
              children: [
                Image.file(image, width: 100, height: 100, fit: BoxFit.cover),
                Positioned(
                  right: 0,
                  top: 0,
                  child: IconButton(
                    icon: Icon(Icons.remove_circle),
                    onPressed: () {
                      setState(() {
                        // Remove the image from the list
                        widget.inspectionData.brakeImages.remove(image);
                      });
                    },
                  ),
                ),
              ],
            );
          }).toList(),
        ),
        SizedBox(height: 10),
        ElevatedButton(
          onPressed: () {
            _pickImage(context, (file) {
              setState(() {
                // Add the picked image to the list
                widget.inspectionData.brakeImages.add(file);
              });
            });
          },
          child: Text('Attach images of brakes'),
        ),
      ],
    );
  }
}

class EngineForm extends StatefulWidget {
  final InspectionData inspectionData;

  EngineForm({required this.inspectionData});

  @override
  _EngineFormState createState() => _EngineFormState();
}

class _EngineFormState extends State<EngineForm> {
  bool _engineDamage = false;
  String _engineDamageNotes = '';
  String? _engineOilCondition;
  String? _engineOilColor;
  String? _brakeFluidCondition;
  String? _brakeFluidColor;
  bool _engineOilLeak = false;

  void _pickImage(BuildContext context, Function(File) onImageSelected) async {
    final ImagePicker _picker = ImagePicker();

    // Pick an image
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      File pickedFile = File(image.path);
      onImageSelected(pickedFile);
    }
  }

  @override
  void initState() {
    super.initState();
    // Initialize selected values from inspectionData if they are not already set
    _engineDamage = widget.inspectionData.engineDamage;
    _engineDamageNotes = widget.inspectionData.engineDamageNotes;
    _engineOilCondition = widget.inspectionData.engineOilCondition.isNotEmpty
        ? widget.inspectionData.engineOilCondition
        : null;
    _engineOilColor = widget.inspectionData.engineOilColor.isNotEmpty
        ? widget.inspectionData.engineOilColor
        : null;
    _brakeFluidCondition = widget.inspectionData.brakeFluidCondition.isNotEmpty
        ? widget.inspectionData.brakeFluidCondition
        : null;
    _brakeFluidColor = widget.inspectionData.brakeFluidColor.isNotEmpty
        ? widget.inspectionData.brakeFluidColor
        : null;
    _engineOilLeak = widget.inspectionData.engineOilLeak;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CheckboxListTile(
          title: Text('Rust, Dents or Damage in Engine'),
          value: _engineDamage,
          onChanged: (value) {
            setState(() {
              _engineDamage = value!;
              widget.inspectionData.engineDamage = value;
            });
          },
        ),
        TextField(
          decoration: InputDecoration(labelText: 'Explain in notes'),
          onChanged: (value) {
            setState(() {
              _engineDamageNotes = value;
              widget.inspectionData.engineDamageNotes = value;
            });
          },
        ),
        DropdownButtonFormField<String>(
          value: _engineOilCondition,
          decoration: InputDecoration(labelText: 'Engine Oil Condition'),
          items: ['Good', 'Bad']
              .map((condition) => DropdownMenuItem(
            value: condition,
            child: Text(condition),
          ))
              .toList(),
          onChanged: (value) {
            setState(() {
              _engineOilCondition = value;
              widget.inspectionData.engineOilCondition = value!;
            });
          },
        ),
        DropdownButtonFormField<String>(
          value: _engineOilColor,
          decoration: InputDecoration(labelText: 'Engine Oil Color'),
          items: ['Clean', 'Brown', 'Black']
              .map((color) => DropdownMenuItem(
            value: color,
            child: Text(color),
          ))
              .toList(),
          onChanged: (value) {
            setState(() {
              _engineOilColor = value;
              widget.inspectionData.engineOilColor = value!;
            });
          },
        ),
        DropdownButtonFormField<String>(
          value: _brakeFluidCondition,
          decoration: InputDecoration(labelText: 'Brake Fluid Condition'),
          items: ['Good', 'Bad']
              .map((condition) => DropdownMenuItem(
            value: condition,
            child: Text(condition),
          ))
              .toList(),
          onChanged: (value) {
            setState(() {
              _brakeFluidCondition = value;
              widget.inspectionData.brakeFluidCondition = value!;
            });
          },
        ),
        DropdownButtonFormField<String>(
          value: _brakeFluidColor,
          decoration: InputDecoration(labelText: 'Brake Fluid Color'),
          items: ['Clean', 'Brown', 'Black']
              .map((color) => DropdownMenuItem(
            value: color,
            child: Text(color),
          ))
              .toList(),
          onChanged: (value) {
            setState(() {
              _brakeFluidColor = value;
              widget.inspectionData.brakeFluidColor = value!;
            });
          },
        ),
        CheckboxListTile(
          title: Text('Any oil leak in Engine'),
          value: _engineOilLeak,
          onChanged: (value) {
            setState(() {
              _engineOilLeak = value!;
              widget.inspectionData.engineOilLeak = value;
            });
          },
        ),
        SizedBox(height: 10),
        Text(
          'Attached Images:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 5),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: widget.inspectionData.engineImages.map((image) {
            return Stack(
              children: [
                Image.file(image, width: 100, height: 100, fit: BoxFit.cover),
                Positioned(
                  right: 0,
                  top: 0,
                  child: IconButton(
                    icon: Icon(Icons.remove_circle),
                    onPressed: () {
                      setState(() {
                        // Remove the image from the list
                        widget.inspectionData.engineImages.remove(image);
                      });
                    },
                  ),
                ),
              ],
            );
          }).toList(),
        ),
        SizedBox(height: 10),
        ElevatedButton(
          onPressed: () {
            _pickImage(context, (file) {
              setState(() {
                // Add the picked image to the list
                widget.inspectionData.engineImages.add(file);
              });
            });
          },
          child: Text('Attach images of engine'),
        ),
      ],
    );
  }
}

Future<void> _pickImage(BuildContext context, Function(File) onImagePicked) async {
  final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
  if (pickedFile != null) {
    onImagePicked(File(pickedFile.path));
  }
}
