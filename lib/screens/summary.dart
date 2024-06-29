import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:open_file/open_file.dart';
import 'package:truck_check/ai/battery.dart';
import 'package:truck_check/ai/brake.dart';
import 'package:truck_check/ai/exterior.dart';
import 'package:truck_check/ai/tyre.dart';

import '../ai/engine.dart';
import '../models/inspection_data.dart';

class SummaryPage extends StatefulWidget {
  const SummaryPage({Key? key, required this.inspectionData}) : super(key: key);
  final InspectionData inspectionData;

  @override
  _SummaryPageState createState() => _SummaryPageState();
}

class _SummaryPageState extends State<SummaryPage> {
  String responseText = 'Awaiting response...';
  TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _sendMessage();
  }

  Future<void> _sendMessage() async {
    try {
      await Gemini.init(apiKey: "AIzaSyBPc-P9xs_4CSiqXzawDxv5adniQ1ewLyE", enableDebugging: true);
      final gemini = Gemini.instance;

      final generationConfig = GenerationConfig(
        temperature: 1,
        topP: 0.95,
        topK: 64,
        maxOutputTokens: 8192,
      );

      final value = await gemini.chat(
        generationConfig: generationConfig,
        [
          Content(
            parts: [
              Parts(
                text:
                '''Imagine you are a service technician inspecting an articulated truck. Below are the details of various parts that need inspection. Based on the provided information, offer detailed recommendations for repair. For example, if the windshield is broken or the oil color is abnormal, specify the necessary repairs and maintenance steps.''' +
                    widget.inspectionData.toString(),
              )
            ],
            role: 'user',
          ),
        ],
      );

      setState(() {
        responseText = value?.output ?? 'No output';
      });

    } catch (e, stackTrace) {
      log('Gemini chat error', error: e, stackTrace: stackTrace);
      setState(() {
        responseText = 'You dont have a stable internet connection';
      });
    }

  }

  Future<void> _saveAsPDF() async {
    final pdf = pw.Document();

    // Function to build inspection summary content
    void _buildInspectionSummaryContent() {
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) => [
            pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 10),
              child: InspectionSummaryPdf(inspectionData: widget.inspectionData),
            ),
            pw.Header(level: 1, text: 'Inspection Results'),
            pw.Padding(padding: const pw.EdgeInsets.only(top: 10)),
            pw.Paragraph(
              style: pw.TextStyle(fontSize: 16, color: PdfColors.black),
              text: responseText,
            ),
          ],
        ),
      );
    }



    final brakePrediction = await BrakeModel().getPrediction(widget.inspectionData);
    final enginePrediction = await EngineModel().getPrediction(widget.inspectionData);
    final batteryPrediction = await BatteryModel().getPrediction(widget.inspectionData);
    final exteriorPrediction = await ExteriorModel().getPrediction(widget.inspectionData);
    final tyrePrediction = await TyreModel().getPrediction(widget.inspectionData);


    pdf.addPage(
      pw.Page(
        build: (context) {

          pw.Widget _buildSectionTitle(String title, String subtitle) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 10.0),
                  child: pw.Text(
                    title,
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue,
                    ),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 10.0),
                  child: pw.Text(
                    subtitle,
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.black,
                    ),
                  ),
                )
              ],
            );
          }

          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Brake Recommendation', brakePrediction),
              _buildSectionTitle('Engine Recommendation', enginePrediction),
              _buildSectionTitle('Battery Recommendation', batteryPrediction),
              _buildSectionTitle('Exterior Recommendation', exteriorPrediction),
              _buildSectionTitle('Tyre Recommendation', tyrePrediction),
              _buildSectionTitle("Inspection Notes", widget.inspectionData.inspectionNotes)
            ],
          );
        },
      ),
    );




    // Call the function to build content
    _buildInspectionSummaryContent();

    // Save PDF to local storage
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/summary.pdf');
    await file.writeAsBytes(await pdf.save());

    // Open the PDF file
    await OpenFile.open(file.path);
  }

  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inspection Summary'),
        backgroundColor: Colors.lightBlueAccent,
        actions: [
          IconButton(
            onPressed: _saveAsPDF,
            icon: Icon(Icons.save_alt),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InspectionSummaryPage(inspectionData: widget.inspectionData),
            Text(
              'Inspection Results',
              style: Theme.of(context).textTheme.headline5?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
            const SizedBox(height: 20),
            MarkdownBody(
              data: responseText,
              styleSheet: MarkdownStyleSheet(
                p: Theme.of(context).textTheme.bodyText1?.copyWith(
                  fontSize: 16,
                  color: Colors.black87,
                ),
                h1: Theme.of(context).textTheme.headline5?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
                h2: Theme.of(context).textTheme.headline6?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
                // Add more styles as needed
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Recommended Actions',
              style: Theme.of(context).textTheme.headline5?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),

        TextField(
          controller: _controller,
          maxLines: null,
          onChanged: (value) {
            widget.inspectionData.inspectionNotes = value;
          },
          decoration: InputDecoration(
            hintText: 'Enter inspection notes here...',
            border: OutlineInputBorder(),
          )
        )

          ],
        ),
      ),
    );
  }
}

class InspectionSummaryPage extends StatelessWidget {
  final InspectionData inspectionData;

  InspectionSummaryPage({required this.inspectionData});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          _buildSectionTitle('Tire Information', inspectionData.tireImages),
          _buildTireInfo(),
          _buildSectionTitle('Battery Information', inspectionData.batteryImages),
          _buildBatteryInfo(),
          _buildSectionTitle('Exterior Information', inspectionData.exteriorImages),
          _buildExteriorInfo(),
          _buildSectionTitle('Brake Information', inspectionData.brakeImages),
          _buildBrakeInfo(),
          _buildSectionTitle('Engine Information', inspectionData.engineImages),
          _buildEngineInfo(),
          InspectionResultsWidget(data: inspectionData)
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, List<File> images) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ),
        _buildImageGallery(images),
      ],
    );
  }

  Widget _buildImageGallery(List<File> images) {
    if (images.isEmpty) {
      return SizedBox.shrink();
    }

    return Container(
      height: 150,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Image.file(images[index]),
          );
        },
      ),
    );
  }

  Widget _buildTireInfo() {
    return Card(
      child: Column(
        children: [
          _buildListTile('Left Front Tire Pressure', '${inspectionData.leftFrontTirePressure} psi'),
          _buildListTile('Right Front Tire Pressure', '${inspectionData.rightFrontTirePressure} psi'),
          _buildListTile('Left Front Tire Condition', inspectionData.leftFrontTireCondition),
          _buildListTile('Right Front Tire Condition', inspectionData.rightFrontTireCondition),
          _buildListTile('Left Rear Tire Pressure', '${inspectionData.leftRearTirePressure} psi'),
          _buildListTile('Right Rear Tire Pressure', '${inspectionData.rightRearTirePressure} psi'),
          _buildListTile('Left Rear Tire Condition', inspectionData.leftRearTireCondition),
          _buildListTile('Right Rear Tire Condition', inspectionData.rightRearTireCondition),
        ],
      ),
    );
  }

  Widget _buildBatteryInfo() {
    return Card(
      child: Column(
        children: [
          _buildListTile('Battery Make', inspectionData.batteryMake),
          _buildListTile('Battery Replacement Date', inspectionData.batteryReplacementDate),
          _buildListTile('Battery Voltage', '${inspectionData.batteryVoltage} V'),
          _buildListTile('Battery Water Level', inspectionData.batteryWaterLevel),
          _buildListTile('Battery Damage', inspectionData.batteryDamage ? 'Yes' : 'No'),
          _buildListTile('Battery Leak', inspectionData.batteryLeak ? 'Yes' : 'No'),
        ],
      ),
    );
  }

  Widget _buildExteriorInfo() {
    return Card(
      child: Column(
        children: [
          _buildListTile('Exterior Damage', inspectionData.exteriorDamage ? 'Yes' : 'No'),
          _buildListTile('Exterior Notes', inspectionData.exteriorNotes),
          _buildListTile('Oil Leak Suspension', inspectionData.oilLeakSuspension ? 'Yes' : 'No'),
        ],
      ),
    );
  }

  Widget _buildBrakeInfo() {
    return Card(
      child: Column(
        children: [
          _buildListTile('Brake Fluid Level', inspectionData.brakeFluidLevel),
          _buildListTile('Brake Condition Front', inspectionData.brakeConditionFront),
          _buildListTile('Brake Condition Rear', inspectionData.brakeConditionRear),
          _buildListTile('Emergency Brake Condition', inspectionData.emergencyBrakeCondition),
          _buildListTile('Brake Fluid Condition', inspectionData.brakeFluidCondition),
          _buildListTile('Brake Fluid Color', inspectionData.brakeFluidColor),
        ],
      ),
    );
  }

  Widget _buildEngineInfo() {
    return Card(
      child: Column(
        children: [
          _buildListTile('Engine Damage', inspectionData.engineDamage ? 'Yes' : 'No'),
          _buildListTile('Engine Damage Notes', inspectionData.engineDamageNotes),
          _buildListTile('Engine Oil Condition', inspectionData.engineOilCondition),
          _buildListTile('Engine Oil Color', inspectionData.engineOilColor),
          _buildListTile('Engine Oil Leak', inspectionData.engineOilLeak ? 'Yes' : 'No'),
        ],
      ),
    );
  }

  Widget _buildListTile(String title, String subtitle) {
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
    );
  }
}


class InspectionSummaryPdf extends pw.StatelessWidget {
  final InspectionData inspectionData;

  InspectionSummaryPdf({required this.inspectionData});

  @override
  pw.Widget build(pw.Context context) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8.0),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Tire Information', inspectionData.tireImages),
          _buildTireInfo(),
          _buildSectionTitle('Battery Information', inspectionData.batteryImages),
          _buildBatteryInfo(),
          _buildSectionTitle('Exterior Information', inspectionData.exteriorImages),
          _buildExteriorInfo(),
          _buildSectionTitle('Brake Information', inspectionData.brakeImages),
          _buildBrakeInfo(),
          _buildSectionTitle('Engine Information', inspectionData.engineImages),
          _buildEngineInfo(),
        ],
      ),
    );
  }

  pw.Widget _buildSectionTitle(String title, List<File> images) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 10.0),
          child: pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue,
            ),
          ),
        ),
        _buildImageGallery(images),
      ],
    );
  }

  pw.Widget _buildImageGallery(List<File> images) {
    if (images.isEmpty) {
      return pw.SizedBox.shrink();
    }

    return pw.Container(
      height: 150,
      child: pw.ListView.builder(
        itemCount: images.length,
        itemBuilder: (context, index) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(8.0),
          );
        },
      ),
    );
  }

  pw.Widget _buildTireInfo() {
    return pw.Container(
      child: pw.Column(
        children: [
          _buildListTile('Left Front Tire Pressure', '${inspectionData.leftFrontTirePressure} psi'),
          _buildListTile('Right Front Tire Pressure', '${inspectionData.rightFrontTirePressure} psi'),
          _buildListTile('Left Front Tire Condition', inspectionData.leftFrontTireCondition),
          _buildListTile('Right Front Tire Condition', inspectionData.rightFrontTireCondition),
          _buildListTile('Left Rear Tire Pressure', '${inspectionData.leftRearTirePressure} psi'),
          _buildListTile('Right Rear Tire Pressure', '${inspectionData.rightRearTirePressure} psi'),
          _buildListTile('Left Rear Tire Condition', inspectionData.leftRearTireCondition),
          _buildListTile('Right Rear Tire Condition', inspectionData.rightRearTireCondition),
        ],
      ),
    );
  }

  pw.Widget _buildBatteryInfo() {
    return pw.Container(
      child: pw.Column(
        children: [
          _buildListTile('Battery Make', inspectionData.batteryMake),
          _buildListTile('Battery Replacement Date', inspectionData.batteryReplacementDate),
          _buildListTile('Battery Voltage', '${inspectionData.batteryVoltage} V'),
          _buildListTile('Battery Water Level', inspectionData.batteryWaterLevel),
          _buildListTile('Battery Damage', inspectionData.batteryDamage ? 'Yes' : 'No'),
          _buildListTile('Battery Leak', inspectionData.batteryLeak ? 'Yes' : 'No'),
        ],
      ),
    );
  }

  pw.Widget _buildExteriorInfo() {
    return pw.Container(
      child: pw.Column(
        children: [
          _buildListTile('Exterior Damage', inspectionData.exteriorDamage ? 'Yes' : 'No'),
          _buildListTile('Exterior Notes', inspectionData.exteriorNotes),
          _buildListTile('Oil Leak Suspension', inspectionData.oilLeakSuspension ? 'Yes' : 'No'),
        ],
      ),
    );
  }

  pw.Widget _buildBrakeInfo() {
    return pw.Container(
      child: pw.Column(
        children: [
          _buildListTile('Brake Fluid Level', inspectionData.brakeFluidLevel),
          _buildListTile('Brake Condition Front', inspectionData.brakeConditionFront),
          _buildListTile('Brake Condition Rear', inspectionData.brakeConditionRear),
          _buildListTile('Emergency Brake Condition', inspectionData.emergencyBrakeCondition),
          _buildListTile('Brake Fluid Condition', inspectionData.brakeFluidCondition),
          _buildListTile('Brake Fluid Color', inspectionData.brakeFluidColor),
        ],
      ),
    );
  }

  pw.Widget _buildEngineInfo() {
    return pw.Container(
      child: pw.Column(
        children: [
          _buildListTile('Engine Damage', inspectionData.engineDamage ? 'Yes' : 'No'),
          _buildListTile('Engine Damage Notes', inspectionData.engineDamageNotes),
          _buildListTile('Engine Oil Condition', inspectionData.engineOilCondition),
          _buildListTile('Engine Oil Color', inspectionData.engineOilColor),
          _buildListTile('Engine Oil Leak', inspectionData.engineOilLeak ? 'Yes' : 'No'),
        ],
      ),
    );
  }

  pw.Widget _buildListTile(String title, String subtitle) {
    return pw.Container(
      margin: pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.black,
            ),
          ),
          pw.Text(
            subtitle,
            style: pw.TextStyle(
              color: PdfColors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
class InspectionResultsWidget extends StatelessWidget {
  final InspectionData data;

  InspectionResultsWidget({required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildPredictionCardFuture(
          title: 'Brake Prediction',
          futurePrediction: BrakeModel().getPrediction(data),
        ),
        _buildPredictionCardFuture(
          title: 'Engine Prediction',
          futurePrediction: EngineModel().getPrediction(data),
        ),
        _buildNotesCard(
          title: 'Engine Damage Notes',
          notes: data.engineDamageNotes,
        ),
        _buildPredictionCardFuture(
          title: 'Battery Prediction',
          futurePrediction: BatteryModel().getPrediction(data),
        ),
        _buildPredictionCardFuture(
          title: 'Exterior Prediction',
          futurePrediction: ExteriorModel().getPrediction(data),
        ),
        _buildNotesCard(
          title: 'Exterior Notes',
          notes: data.exteriorNotes,
        ),
        _buildPredictionCardFuture(
          title: 'Tyre Prediction',
          futurePrediction: TyreModel().getPrediction(data),
        ),
      ],
    );
  }

  Widget _buildPredictionCardFuture({required String title, required Future<String> futurePrediction}) {
    return FutureBuilder(
      future: futurePrediction,
      builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingCard(title);
        } else {
          if (snapshot.hasError) {
            return _buildErrorCard(title);
          } else {
            return _buildPredictionCard(title: title, prediction: snapshot.data ?? 'No data');
          }
        }
      },
    );
  }

  Widget _buildLoadingCard(String title) {
    return Card(
      elevation: 3.0,
      margin: EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        title: Text(title),
        subtitle: Text('Loading...'),
      ),
    );
  }

  Widget _buildErrorCard(String title) {
    return Card(
      elevation: 3.0,
      margin: EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        title: Text(title),
        subtitle: Text('Error fetching data'),
      ),
    );
  }

  Widget _buildPredictionCard({required String title, required String prediction}) {
    return Card(
      elevation: 3.0,
      margin: EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        title: Text(title),
        subtitle: Text('Prediction: $prediction'),
      ),
    );
  }

  Widget _buildNotesCard({required String title, required String notes}) {
    return Card(
      elevation: 3.0,
      margin: EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        title: Text(title),
        subtitle: Text('Notes: $notes'),
      ),
    );
  }
}