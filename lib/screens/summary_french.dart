import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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

class SummaryFrenchPage extends StatefulWidget {
  const SummaryFrenchPage({Key? key, required this.inspectionData})
      : super(key: key);
  final InspectionData inspectionData;

  @override
  _SummaryFrenchPageState createState() => _SummaryFrenchPageState();
}

class _SummaryFrenchPageState extends State<SummaryFrenchPage> {
  String responseText = 'En attente de réponse...';

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
        .isModelDownloaded(TranslateLanguage.french.bcpCode)) {
      await modelManager.downloadModel(TranslateLanguage.french.bcpCode);
    }

    final onDeviceTranslator = OnDeviceTranslator(
      sourceLanguage: TranslateLanguage.english,
      targetLanguage: TranslateLanguage.french,
    );

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
      //               '''Imaginez que vous êtes un technicien de service inspectant un camion articulé. Ci-dessous les détails de diverses pièces à inspecter. Sur la base des informations fournies, offrez des recommandations détaillées pour la réparation. Par exemple, si le pare-brise est cassé ou si la couleur de l'huile est anormale, spécifiez les réparations et les étapes de maintenance nécessaires.''' +
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

      getTranslation(value?.output ?? 'Pas de sortie').then((text) {
        setState(() {
          responseText = text;
        });
      });
    } catch (e, stackTrace) {
      log('Erreur de chat Gemini', error: e, stackTrace: stackTrace);
      setState(() {
        responseText = 'Vous n\'avez pas une connexion Internet stable.';
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
                text: 'Détails de l\'inspection',
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
              _buildSectionTitle('Recommandation de frein', brakePrediction),
              _buildSectionTitle('Recommandation de moteur', enginePrediction),
              _buildSectionTitle(
                  'Recommandation de batterie', batteryPrediction),
              _buildSectionTitle(
                  'Recommandation extérieure', exteriorPrediction),
              _buildSectionTitle('Recommandation de pneus', tyrePrediction),
              _buildSectionTitle(
                  "Notes d'inspection", widget.inspectionData.inspectionNotes),
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
        title: const Text('Résumé de l\'inspection'),
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
              'Résultats de l\'inspection',
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
                  return Center(child: Text('Erreur: ${snapshot.error}'));
                } else if (!snapshot.hasData) {
                  return Center(child: Text('Pas de données'));
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
              'Actions recommandées',
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
                labelText: 'Notes de l\'inspecteur',
                border: OutlineInputBorder(),
              ),
            ),
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
              'Informations sur les pneus', inspectionData.tireImages),
          _buildTireInfo(),
          _buildSectionTitle(
              'Informations sur la batterie', inspectionData.batteryImages),
          _buildBatteryInfo(),
          _buildSectionTitle(
              'Informations extérieures', inspectionData.exteriorImages),
          _buildExteriorInfo(),
          _buildSectionTitle(
              'Informations sur les freins', inspectionData.brakeImages),
          _buildBrakeInfo(),
          _buildSectionTitle(
              'Informations sur le moteur', inspectionData.engineImages),
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
          _buildListTile('Pression du pneu avant gauche',
              '${inspectionData.leftFrontTirePressure} psi'),
          _buildListTile('Pression du pneu avant droit',
              '${inspectionData.rightFrontTirePressure} psi'),
          _buildListTile('État du pneu avant gauche',
              inspectionData.leftFrontTireCondition),
          _buildListTile('État du pneu avant droit',
              inspectionData.rightFrontTireCondition),
          _buildListTile('Pression du pneu arrière gauche',
              '${inspectionData.leftRearTirePressure} psi'),
          _buildListTile('Pression du pneu arrière droit',
              '${inspectionData.rightRearTirePressure} psi'),
          _buildListTile('État du pneu arrière gauche',
              inspectionData.leftRearTireCondition),
          _buildListTile('État du pneu arrière droit',
              inspectionData.rightRearTireCondition),
        ],
      ),
    );
  }

  Widget _buildBatteryInfo() {
    return Card(
      child: Column(
        children: [
          _buildListTile('Marque de la batterie', inspectionData.batteryMake),
          _buildListTile('Date de remplacement de la batterie',
              inspectionData.batteryReplacementDate),
          _buildListTile(
              'Tension de la batterie', '${inspectionData.batteryVoltage} V'),
          _buildListTile(
              'Niveau d\'eau de la batterie', inspectionData.batteryWaterLevel),
          _buildListTile('Dommage de la batterie',
              inspectionData.batteryDamage ? 'Oui' : 'Non'),
          _buildListTile('Fuite de la batterie',
              inspectionData.batteryLeak ? 'Oui' : 'Non'),
        ],
      ),
    );
  }

  Widget _buildExteriorInfo() {
    return Card(
      child: Column(
        children: [
          _buildListTile('Dommages extérieurs',
              inspectionData.exteriorDamage ? 'Oui' : 'Non'),
          _buildListTile(
              'Notes sur l\'extérieur', inspectionData.exteriorNotes),
          _buildListTile('Fuite d\'huile de suspension',
              inspectionData.oilLeakSuspension ? 'Oui' : 'Non'),
        ],
      ),
    );
  }

  Widget _buildBrakeInfo() {
    return Card(
      child: Column(
        children: [
          _buildListTile(
              'Niveau de liquide de frein', inspectionData.brakeFluidLevel),
          _buildListTile(
              'État du frein avant', inspectionData.brakeConditionFront),
          _buildListTile(
              'État du frein arrière', inspectionData.brakeConditionRear),
          _buildListTile('État du frein d\'urgence',
              inspectionData.emergencyBrakeCondition),
          _buildListTile(
              'État du liquide de frein', inspectionData.brakeFluidCondition),
          _buildListTile(
              'Couleur du liquide de frein', inspectionData.brakeFluidColor),
        ],
      ),
    );
  }

  Widget _buildEngineInfo() {
    return Card(
      child: Column(
        children: [
          _buildListTile('Dommages du moteur',
              inspectionData.engineDamage ? 'Oui' : 'Non'),
          _buildListTile('Notes sur les dommages du moteur',
              inspectionData.engineDamageNotes),
          _buildListTile(
              'État de l\'huile moteur', inspectionData.engineOilCondition),
          _buildListTile(
              'Couleur de l\'huile moteur', inspectionData.engineOilColor),
          _buildListTile('Fuite d\'huile moteur',
              inspectionData.engineOilLeak ? 'Oui' : 'Non'),
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
              'Informations sur les pneus', inspectionData.tireImages),
          _buildTireInfo(),
          _buildSectionTitle(
              'Informations sur la batterie', inspectionData.batteryImages),
          _buildBatteryInfo(),
          _buildSectionTitle(
              'Informations extérieures', inspectionData.exteriorImages),
          _buildExteriorInfo(),
          _buildSectionTitle(
              'Informations sur les freins', inspectionData.brakeImages),
          _buildBrakeInfo(),
          _buildSectionTitle(
              'Informations sur le moteur', inspectionData.engineImages),
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
          _buildListTile('Pression du pneu avant gauche',
              '${inspectionData.leftFrontTirePressure} psi'),
          _buildListTile('Pression du pneu avant droit',
              '${inspectionData.rightFrontTirePressure} psi'),
          _buildListTile('État du pneu avant gauche',
              inspectionData.leftFrontTireCondition),
          _buildListTile('État du pneu avant droit',
              inspectionData.rightFrontTireCondition),
          _buildListTile('Pression du pneu arrière gauche',
              '${inspectionData.leftRearTirePressure} psi'),
          _buildListTile('Pression du pneu arrière droit',
              '${inspectionData.rightRearTirePressure} psi'),
          _buildListTile('État du pneu arrière gauche',
              inspectionData.leftRearTireCondition),
          _buildListTile('État du pneu arrière droit',
              inspectionData.rightRearTireCondition),
        ],
      ),
    );
  }

  pw.Widget _buildBatteryInfo() {
    return pw.Container(
      child: pw.Column(
        children: [
          _buildListTile('Marque de la batterie', inspectionData.batteryMake),
          _buildListTile('Date de remplacement de la batterie',
              inspectionData.batteryReplacementDate),
          _buildListTile(
              'Tension de la batterie', '${inspectionData.batteryVoltage} V'),
          _buildListTile(
              'Niveau d\'eau de la batterie', inspectionData.batteryWaterLevel),
          _buildListTile('Dommage de la batterie',
              inspectionData.batteryDamage ? 'Oui' : 'Non'),
          _buildListTile('Fuite de la batterie',
              inspectionData.batteryLeak ? 'Oui' : 'Non'),
        ],
      ),
    );
  }

  pw.Widget _buildExteriorInfo() {
    return pw.Container(
      child: pw.Column(
        children: [
          _buildListTile('Dommages extérieurs',
              inspectionData.exteriorDamage ? 'Oui' : 'Non'),
          _buildListTile(
              'Notes sur l\'extérieur', inspectionData.exteriorNotes),
          _buildListTile('Fuite d\'huile de suspension',
              inspectionData.oilLeakSuspension ? 'Oui' : 'Non'),
        ],
      ),
    );
  }

  pw.Widget _buildBrakeInfo() {
    return pw.Container(
      child: pw.Column(
        children: [
          _buildListTile(
              'Niveau de liquide de frein', inspectionData.brakeFluidLevel),
          _buildListTile(
              'État du frein avant', inspectionData.brakeConditionFront),
          _buildListTile(
              'État du frein arrière', inspectionData.brakeConditionRear),
          _buildListTile('État du frein d\'urgence',
              inspectionData.emergencyBrakeCondition),
          _buildListTile(
              'État du liquide de frein', inspectionData.brakeFluidCondition),
          _buildListTile(
              'Couleur du liquide de frein', inspectionData.brakeFluidColor),
        ],
      ),
    );
  }

  pw.Widget _buildEngineInfo() {
    return pw.Container(
      child: pw.Column(
        children: [
          _buildListTile('Dommages du moteur',
              inspectionData.engineDamage ? 'Oui' : 'Non'),
          _buildListTile('Notes sur les dommages du moteur',
              inspectionData.engineDamageNotes),
          _buildListTile(
              'État de l\'huile moteur', inspectionData.engineOilCondition),
          _buildListTile(
              'Couleur de l\'huile moteur', inspectionData.engineOilColor),
          _buildListTile('Fuite d\'huile moteur',
              inspectionData.engineOilLeak ? 'Oui' : 'Non'),
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
          title: 'Prédiction des freins',
          futurePrediction: BrakeModel().getPrediction(data),
        ),
        _buildPredictionCardFuture(
          title: 'Prédiction du moteur',
          futurePrediction: EngineModel().getPrediction(data),
        ),
        _buildNotesCard(
          title: 'Notes sur les dommages du moteur',
          notes: data.engineDamageNotes,
        ),
        _buildPredictionCardFuture(
          title: 'Prédiction de la batterie',
          futurePrediction: BatteryModel().getPrediction(data),
        ),
        _buildPredictionCardFuture(
          title: 'Prédiction extérieure',
          futurePrediction: ExteriorModel().getPrediction(data),
        ),
        _buildNotesCard(
          title: 'Notes sur l\'extérieur',
          notes: data.exteriorNotes,
        ),
        _buildPredictionCardFuture(
          title: 'Prédiction des pneus',
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
                title: title, prediction: snapshot.data ?? 'Pas de données');
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
        subtitle: Text('Chargement...'),
      ),
    );
  }

  Widget _buildErrorCard(String title) {
    return Card(
      elevation: 3.0,
      margin: EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        title: Text(title),
        subtitle: Text('Erreur lors de la récupération des données'),
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
        subtitle: Text('Prédiction: $prediction'),
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
