import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
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

class SummarySpanishPage extends StatefulWidget {
  const SummarySpanishPage({Key? key, required this.inspectionData})
      : super(key: key);
  final InspectionData inspectionData;

  @override
  _SummarySpanishPageState createState() => _SummarySpanishPageState();
}

class _SummarySpanishPageState extends State<SummarySpanishPage> {
  String responseText = 'Esperando respuesta...';

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

  Future<String> getTranslation(String text) async {
    final modelManager = OnDeviceTranslatorModelManager();
    if (await modelManager
        .isModelDownloaded(TranslateLanguage.spanish.bcpCode)) {
      await modelManager.downloadModel(TranslateLanguage.spanish.bcpCode);
    }

    final onDeviceTranslator = OnDeviceTranslator(
        sourceLanguage: TranslateLanguage.english,
        targetLanguage: TranslateLanguage.spanish);

    return onDeviceTranslator.translateText(text);
  }

  Future<void> _sendMessage() async {
    try {
      await Gemini.init(
          apiKey: "AIzaSyBPc-P9xs_4CSiqXzawDxv5adniQ1ewLyE",
          enableDebugging: true);
      final gemini = Gemini.instance;

      // final generationConfig = GenerationConfig(
      //   temperature: 1,
      //   topP: 0.95,
      //   topK: 64,
      //   maxOutputTokens: 8192,
      // );

      // final value = await gemini.chat(
      //   generationConfig: generationConfig,
      //   [
      //     Content(
      //       parts: [
      //         Parts(
      //           text:
      //               '''Imagine you are a service technician inspecting an articulated truck. Below are the details of various parts that need inspection. Based on the provided information, offer detailed recommendations for repair. For example, if the windshield is broken or the oil color is abnormal, specify the necessary repairs and maintenance steps.''' +
      //                   widget.inspectionData.toString(),
      //         )
      //       ],
      //       role: 'user',
      //     ),
      //   ],
      // );

      final value = await gemini.text(
        '''Imagine you are a service technician inspecting an articulated truck. Below are the details of various parts that need inspection. Based on the provided information, offer detailed recommendations for repair. For example, if the windshield is broken or the oil color is abnormal, specify the necessary repairs and maintenance steps.''' +
            widget.inspectionData.toString(),
      );

      getTranslation(value?.output ?? 'No output').then((text) => {
            setState(() {
              responseText = text;
            })
          });
    } catch (e, stackTrace) {
      log('Gemini chat error', error: e, stackTrace: stackTrace);
      setState(() {
        responseText = 'No tienes una conexión a Internet estable.';
      });
    }
  }

  Future<void> _saveAsPDF() async {
    final pdf = pw.Document();

    final fontData = await rootBundle.load('assets/fonts/hindi.ttf');
    final ttf = pw.Font.ttf(fontData);

    final response = await getTranslation(responseText);

    // Function to build inspection summary content
    void _buildInspectionSummaryContent() {
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) => [
            pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 10),
              child:
                  InspectionSummaryPdf(inspectionData: widget.inspectionData),
            ),
            pw.Header(
                level: 1,
                text: 'Detalles de inspección',
                textStyle: pw.TextStyle(font: ttf)),
            pw.Padding(padding: const pw.EdgeInsets.only(top: 10)),
            pw.Paragraph(
              style:
                  pw.TextStyle(fontSize: 16, color: PdfColors.black, font: ttf),
              text: response,
            ),
          ],
        ),
      );
    }

    final brakePrediction = await getTranslation(
        await BrakeModel().getPrediction(widget.inspectionData));
    final enginePrediction = await getTranslation(
        await EngineModel().getPrediction(widget.inspectionData));
    final batteryPrediction = await getTranslation(
        await BatteryModel().getPrediction(widget.inspectionData));
    final exteriorPrediction = await getTranslation(
        await ExteriorModel().getPrediction(widget.inspectionData));
    final tyrePrediction = await getTranslation(
        await TyreModel().getPrediction(widget.inspectionData));

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
                      font: ttf,
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
              _buildSectionTitle('Recomendación de freno', brakePrediction),
              _buildSectionTitle('Engine Recommendation', enginePrediction),
              _buildSectionTitle('Recomendación del motor', batteryPrediction),
              _buildSectionTitle('Recomendación exterior', exteriorPrediction),
              _buildSectionTitle('Recomendación de neumáticos', tyrePrediction),
              _buildSectionTitle(
                  "Notas de inspección", widget.inspectionData.inspectionNotes)
            ],
          );
        },
      ),
    );

    // Call the function to build content
    _buildInspectionSummaryContent();

    // Save PDF to local storage

    // Save PDF to temporary directory
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/summary.pdf');
    await file.writeAsBytes(await pdf.save());

    // Upload PDF to Firebase Storage
    FirebaseStorage storage = FirebaseStorage.instance;
    final ref = storage.ref();
    final pdfRef = ref.child(
        'pdfs/${widget.inspectionData.inspectionId}.pdf'); // Replace with your desired path and filename

    try {
      await pdfRef.putFile(file);
    } on FirebaseException catch (e) {
      print(e);
    }

    await OpenFile.open(file.path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resumen de inspección'),
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
              'Resultados de la inspección',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
            ),
            const SizedBox(height: 20),
            FutureBuilder(
              future: getTranslation(responseText),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData) {
                  return Center(child: Text('No data'));
                } else {
                  return MarkdownBody(
                    data: snapshot.data as String,
                    styleSheet: MarkdownStyleSheet(
                      p: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                      h1: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent,
                          ),
                      h2: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent,
                          ),
                      // Add more styles as needed
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 20),
            Text(
              'Acciones recomendadas',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
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
                  hintText: 'Introduzca aquí las notas de inspección...',
                  border: OutlineInputBorder(),
                ))
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
          _buildSectionTitle(
              'Información sobre neumáticos', inspectionData.tireImages),
          _buildTireInfo(),
          _buildSectionTitle(
              'Información de la batería', inspectionData.batteryImages),
          _buildBatteryInfo(),
          _buildSectionTitle(
              'Información exterior', inspectionData.exteriorImages),
          _buildExteriorInfo(),
          _buildSectionTitle(
              'Información de frenos', inspectionData.brakeImages),
          _buildBrakeInfo(),
          _buildSectionTitle(
              'Información del motor', inspectionData.engineImages),
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
          _buildListTile('Presión del Neumático Delantero Izquierdo',
              '${inspectionData.leftFrontTirePressure} psi'),
          _buildListTile('Presión del Neumático Delantero Derecho',
              '${inspectionData.rightFrontTirePressure} psi'),
          _buildListTile('Condición del Neumático Delantero Izquierdo',
              inspectionData.leftFrontTireCondition),
          _buildListTile('Condición del Neumático Delantero Derecho',
              inspectionData.rightFrontTireCondition),
          _buildListTile('Presión del Neumático Trasero Izquierdo',
              '${inspectionData.leftRearTirePressure} psi'),
          _buildListTile('Presión del Neumático Trasero Derecho',
              '${inspectionData.rightRearTirePressure} psi'),
          _buildListTile('Condición del Neumático Trasero Izquierdo',
              inspectionData.leftRearTireCondition),
          _buildListTile('Condición del Neumático Trasero Derecho',
              inspectionData.rightRearTireCondition),
        ],
      ),
    );
  }

  Widget _buildBatteryInfo() {
    return Card(
      child: Column(
        children: [
          _buildListTile('Marca de la Batería', inspectionData.batteryMake),
          _buildListTile('Fecha de Reemplazo de la Batería',
              inspectionData.batteryReplacementDate),
          _buildListTile(
              'Voltaje de la Batería', '${inspectionData.batteryVoltage} V'),
          _buildListTile(
              'Nivel de Agua de la Batería', inspectionData.batteryWaterLevel),
          _buildListTile(
              'Daño en la Batería', inspectionData.batteryDamage ? 'Sí' : 'No'),
          _buildListTile(
              'Fuga de la Batería', inspectionData.batteryLeak ? 'Sí' : 'No'),
        ],
      ),
    );
  }

  Widget _buildExteriorInfo() {
    return Card(
      child: Column(
        children: [
          _buildListTile(
              'Daño Exterior', inspectionData.exteriorDamage ? 'Sí' : 'No'),
          _buildListTile('Notas del Exterior', inspectionData.exteriorNotes),
          _buildListTile('Fuga de Aceite en la Suspensión',
              inspectionData.oilLeakSuspension ? 'Sí' : 'No'),
        ],
      ),
    );
  }

  Widget _buildBrakeInfo() {
    return Card(
      child: Column(
        children: [
          _buildListTile(
              'Nivel del Líquido de Frenos', inspectionData.brakeFluidLevel),
          _buildListTile('Condición del Freno Delantero',
              inspectionData.brakeConditionFront),
          _buildListTile(
              'Condición del Freno Trasero', inspectionData.brakeConditionRear),
          _buildListTile('Condición del Freno de Emergencia',
              inspectionData.emergencyBrakeCondition),
          _buildListTile('Condición del Líquido de Frenos',
              inspectionData.brakeFluidCondition),
          _buildListTile(
              'Color del Líquido de Frenos', inspectionData.brakeFluidColor),
        ],
      ),
    );
  }

  Widget _buildEngineInfo() {
    return Card(
      child: Column(
        children: [
          _buildListTile(
              'Daño del Motor', inspectionData.engineDamage ? 'Sí' : 'No'),
          _buildListTile(
              'Notas de Daño del Motor', inspectionData.engineDamageNotes),
          _buildListTile('Condición del Aceite del Motor',
              inspectionData.engineOilCondition),
          _buildListTile(
              'Color del Aceite del Motor', inspectionData.engineOilColor),
          _buildListTile('Fuga de Aceite del Motor',
              inspectionData.engineOilLeak ? 'Sí' : 'No'),
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
          _buildSectionTitle(
              'Información de los Neumáticos', inspectionData.tireImages),
          _buildTireInfo(),
          _buildSectionTitle(
              'Información de la Batería', inspectionData.batteryImages),
          _buildBatteryInfo(),
          _buildSectionTitle(
              'Información del Exterior', inspectionData.exteriorImages),
          _buildExteriorInfo(),
          _buildSectionTitle(
              'Información de los Frenos', inspectionData.brakeImages),
          _buildBrakeInfo(),
          _buildSectionTitle(
              'Información del Motor', inspectionData.engineImages),
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
          _buildListTile('Presión del Neumático Delantero Izquierdo',
              '${inspectionData.leftFrontTirePressure} psi'),
          _buildListTile('Presión del Neumático Delantero Derecho',
              '${inspectionData.rightFrontTirePressure} psi'),
          _buildListTile('Condición del Neumático Delantero Izquierdo',
              inspectionData.leftFrontTireCondition),
          _buildListTile('Condición del Neumático Delantero Derecho',
              inspectionData.rightFrontTireCondition),
          _buildListTile('Presión del Neumático Trasero Izquierdo',
              '${inspectionData.leftRearTirePressure} psi'),
          _buildListTile('Presión del Neumático Trasero Derecho',
              '${inspectionData.rightRearTirePressure} psi'),
          _buildListTile('Condición del Neumático Trasero Izquierdo',
              inspectionData.leftRearTireCondition),
          _buildListTile('Condición del Neumático Trasero Derecho',
              inspectionData.rightRearTireCondition),
        ],
      ),
    );
  }

  pw.Widget _buildBatteryInfo() {
    return pw.Container(
      child: pw.Column(
        children: [
          _buildListTile('Marca de la Batería', inspectionData.batteryMake),
          _buildListTile('Fecha de Reemplazo de la Batería',
              inspectionData.batteryReplacementDate),
          _buildListTile(
              'Voltaje de la Batería', '${inspectionData.batteryVoltage} V'),
          _buildListTile(
              'Nivel de Agua de la Batería', inspectionData.batteryWaterLevel),
          _buildListTile(
              'Daño en la Batería', inspectionData.batteryDamage ? 'Sí' : 'No'),
          _buildListTile(
              'Fuga de la Batería', inspectionData.batteryLeak ? 'Sí' : 'No'),
        ],
      ),
    );
  }

  pw.Widget _buildExteriorInfo() {
    return pw.Container(
      child: pw.Column(
        children: [
          _buildListTile(
              'Daño Exterior', inspectionData.exteriorDamage ? 'Sí' : 'No'),
          _buildListTile('Notas del Exterior', inspectionData.exteriorNotes),
          _buildListTile('Fuga de Aceite en la Suspensión',
              inspectionData.oilLeakSuspension ? 'Sí' : 'No'),
        ],
      ),
    );
  }

  pw.Widget _buildBrakeInfo() {
    return pw.Container(
      child: pw.Column(
        children: [
          _buildListTile(
              'Nivel del Líquido de Frenos', inspectionData.brakeFluidLevel),
          _buildListTile('Condición del Freno Delantero',
              inspectionData.brakeConditionFront),
          _buildListTile(
              'Condición del Freno Trasero', inspectionData.brakeConditionRear),
          _buildListTile('Condición del Freno de Emergencia',
              inspectionData.emergencyBrakeCondition),
          _buildListTile('Condición del Líquido de Frenos',
              inspectionData.brakeFluidCondition),
          _buildListTile(
              'Color del Líquido de Frenos', inspectionData.brakeFluidColor),
        ],
      ),
    );
  }

  pw.Widget _buildEngineInfo() {
    return pw.Container(
      child: pw.Column(
        children: [
          _buildListTile(
              'Daño del Motor', inspectionData.engineDamage ? 'Sí' : 'No'),
          _buildListTile(
              'Notas de Daño del Motor', inspectionData.engineDamageNotes),
          _buildListTile('Condición del Aceite del Motor',
              inspectionData.engineOilCondition),
          _buildListTile(
              'Color del Aceite del Motor', inspectionData.engineOilColor),
          _buildListTile('Fuga de Aceite del Motor',
              inspectionData.engineOilLeak ? 'Sí' : 'No'),
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

  Widget _buildPredictionCardFuture(
      {required String title, required Future<String> futurePrediction}) {
    return FutureBuilder(
      future: futurePrediction,
      builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingCard(title);
        } else {
          if (snapshot.hasError) {
            return _buildErrorCard(title);
          } else {
            return _buildPredictionCard(
                title: title, prediction: snapshot.data ?? 'No data');
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

  Widget _buildPredictionCard(
      {required String title, required String prediction}) {
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
