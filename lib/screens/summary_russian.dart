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
import 'package:truck_check/screens/summary.dart';

import '../ai/engine.dart';
import '../models/inspection_data.dart';

class SummaryRussianPage extends StatefulWidget {
  const SummaryRussianPage({Key? key, required this.inspectionData}) : super(key: key);
  final InspectionData inspectionData;

  @override
  _SummaryRussianPageState createState() => _SummaryRussianPageState();
}

class _SummaryRussianPageState extends State<SummaryRussianPage> {
  String responseText = 'Ожидание ответа...'; // Russian translation

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
    if (await modelManager.isModelDownloaded(TranslateLanguage.russian.bcpCode)) {
      await modelManager.downloadModel(TranslateLanguage.russian.bcpCode);
    }

    final onDeviceTranslator = OnDeviceTranslator(
      sourceLanguage: TranslateLanguage.english,
      targetLanguage: TranslateLanguage.russian,
    );

    return onDeviceTranslator.translateText(text);
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
            role: 'пользователь', // Role in Russian
          ),
        ],
      );

      getTranslation(value?.output ?? 'Нет вывода').then((text) => {
        setState(() {
          responseText = text;
        })
      });
    } catch (e, stackTrace) {
      log('Ошибка чата Gemini', error: e, stackTrace: stackTrace);
      setState(() {
        responseText = 'У вас нет стабильного подключения к интернету.'; // Russian translation
      });
    }
  }

  Future<void> _saveAsPDF() async {
    final pdf = pw.Document();

    final fontData = await rootBundle.load('assets/fonts/russian.ttf');
    final ttf = pw.Font.ttf(fontData);

    final response = await getTranslation(responseText);

    void _buildInspectionSummaryContent() {
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) => [
            pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 10),
              child: InspectionSummaryPdf(inspectionData: widget.inspectionData),
            ),
            pw.Header(level: 1, text: 'Детали инспекции', textStyle: pw.TextStyle(font: ttf)), // Russian translation
            pw.Padding(padding: const pw.EdgeInsets.only(top: 10)),
            pw.Paragraph(
              style: pw.TextStyle(fontSize: 16, color: PdfColors.black, font: ttf),
              text: response,
            ),
          ],
        ),
      );
    }

    final brakePrediction = await getTranslation(await BrakeModel().getPrediction(widget.inspectionData));
    final enginePrediction = await getTranslation(await EngineModel().getPrediction(widget.inspectionData));
    final batteryPrediction = await getTranslation(await BatteryModel().getPrediction(widget.inspectionData));
    final exteriorPrediction = await getTranslation(await ExteriorModel().getPrediction(widget.inspectionData));
    final tyrePrediction = await getTranslation(await TyreModel().getPrediction(widget.inspectionData));


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
                      font: ttf,
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
              _buildSectionTitle('Рекомендации по тормозам', brakePrediction), // Translated to Russian
              _buildSectionTitle('Рекомендации по двигателю', enginePrediction), // Translated to Russian
              _buildSectionTitle('Рекомендации по батарее', batteryPrediction), // Translated to Russian
              _buildSectionTitle('Рекомендации по экстерьеру', exteriorPrediction), // Translated to Russian
              _buildSectionTitle('Рекомендации по шинам', tyrePrediction), // Translated to Russian
              _buildSectionTitle('Заметки по инспекции', widget.inspectionData.inspectionNotes), // Translated to Russian
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
    final pdfRef = ref.child('pdfs/${widget.inspectionData.inspectionId}.pdf');

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
        title: const Text('Резюме инспекции'),
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
              'Результаты инспекции',
              style: Theme.of(context).textTheme.headline5?.copyWith(
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
                  return Center(child: Text('Ошибка: ${snapshot.error}'));
                } else if (!snapshot.hasData) {
                  return Center(child: Text('Нет данных'));
                } else {
                  return MarkdownBody(
                    data: snapshot.data as String,
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
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 20),
            Text(
              'Рекомендуемые действия',
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
                hintText: 'Введите здесь заметки по инспекции...',
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
          _buildSectionTitle('Информация о шинах', inspectionData.tireImages),
          _buildTireInfo(),
          _buildSectionTitle('Информация о батарее', inspectionData.batteryImages),
          _buildBatteryInfo(),
          _buildSectionTitle('Внешняя информация', inspectionData.exteriorImages),
          _buildExteriorInfo(),
          _buildSectionTitle('Информация о тормозах', inspectionData.brakeImages),
          _buildBrakeInfo(),
          _buildSectionTitle('Информация о двигателе', inspectionData.engineImages),
          _buildEngineInfo(),
          InspectionResultsWidget(data: inspectionData),
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
          _buildListTile('Давление передней левой шины', '${inspectionData.leftFrontTirePressure} psi'),
          _buildListTile('Давление передней правой шины', '${inspectionData.rightFrontTirePressure} psi'),
          _buildListTile('Состояние передней левой шины', inspectionData.leftFrontTireCondition),
          _buildListTile('Состояние передней правой шины', inspectionData.rightFrontTireCondition),
          _buildListTile('Давление задней левой шины', '${inspectionData.leftRearTirePressure} psi'),
          _buildListTile('Давление задней правой шины', '${inspectionData.rightRearTirePressure} psi'),
          _buildListTile('Состояние задней левой шины', inspectionData.leftRearTireCondition),
          _buildListTile('Состояние задней правой шины', inspectionData.rightRearTireCondition),
        ],
      ),
    );
  }

  Widget _buildBatteryInfo() {
    return Card(
      child: Column(
        children: [
          _buildListTile('Марка батареи', inspectionData.batteryMake),
          _buildListTile('Дата замены батареи', inspectionData.batteryReplacementDate),
          _buildListTile('Напряжение батареи', '${inspectionData.batteryVoltage} V'),
          _buildListTile('Уровень воды в батарее', inspectionData.batteryWaterLevel),
          _buildListTile('Повреждение батареи', inspectionData.batteryDamage ? 'Да' : 'Нет'),
          _buildListTile('Утечка батареи', inspectionData.batteryLeak ? 'Да' : 'Нет'),
        ],
      ),
    );
  }

  Widget _buildExteriorInfo() {
    return Card(
      child: Column(
        children: [
          _buildListTile('Внешнее повреждение', inspectionData.exteriorDamage ? 'Да' : 'Нет'),
          _buildListTile('Заметки по внешнему виду', inspectionData.exteriorNotes),
          _buildListTile('Утечка масла в подвеске', inspectionData.oilLeakSuspension ? 'Да' : 'Нет'),
        ],
      ),
    );
  }

  Widget _buildBrakeInfo() {
    return Card(
      child: Column(
        children: [
          _buildListTile('Уровень тормозной жидкости', inspectionData.brakeFluidLevel),
          _buildListTile('Состояние передних тормозов', inspectionData.brakeConditionFront),
          _buildListTile('Состояние задних тормозов', inspectionData.brakeConditionRear),
          _buildListTile('Состояние аварийного тормоза', inspectionData.emergencyBrakeCondition),
          _buildListTile('Состояние тормозной жидкости', inspectionData.brakeFluidCondition),
          _buildListTile('Цвет тормозной жидкости', inspectionData.brakeFluidColor),
        ],
      ),
    );
  }

  Widget _buildEngineInfo() {
    return Card(
      child: Column(
        children: [
          _buildListTile('Повреждение двигателя', inspectionData.engineDamage ? 'Да' : 'Нет'),
          _buildListTile('Заметки о повреждении двигателя', inspectionData.engineDamageNotes),
          _buildListTile('Состояние масла в двигателе', inspectionData.engineOilCondition),
          _buildListTile('Цвет масла в двигателе', inspectionData.engineOilColor),
          _buildListTile('Утечка масла в двигателе', inspectionData.engineOilLeak ? 'Да' : 'Нет'),
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

class InspectionResultsWidget extends StatelessWidget {
  final InspectionData data;

  InspectionResultsWidget({required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildPredictionCardFuture(
          title: 'Прогноз тормозов',
          futurePrediction: BrakeModel().getPrediction(data),
        ),
        _buildPredictionCardFuture(
          title: 'Прогноз двигателя',
          futurePrediction: EngineModel().getPrediction(data),
        ),
        _buildNotesCard(
          title: 'Заметки о повреждении двигателя',
          notes: data.engineDamageNotes,
        ),
        _buildPredictionCardFuture(
          title: 'Прогноз батареи',
          futurePrediction: BatteryModel().getPrediction(data),
        ),
        _buildPredictionCardFuture(
          title: 'Прогноз внешнего состояния',
          futurePrediction: ExteriorModel().getPrediction(data),
        ),
        _buildNotesCard(
          title: 'Заметки по внешнему виду',
          notes: data.exteriorNotes,
        ),
        _buildPredictionCardFuture(
          title: 'Прогноз шин',
          futurePrediction: TyreModel().getPrediction(data),
        ),
      ],
    );
  }

  Widget _buildPredictionCardFuture({
    required String title,
    required Future<String> futurePrediction,
  }) {
    return Card(
      child: FutureBuilder<String>(
        future: futurePrediction,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return ListTile(
              title: Text(title),
              subtitle: Center(child: CircularProgressIndicator()),
            );
          } else if (snapshot.hasError) {
            return ListTile(
              title: Text(title),
              subtitle: Text('Ошибка: ${snapshot.error}'),
            );
          } else {
            return ListTile(
              title: Text(title),
              subtitle: Text(snapshot.data ?? 'Нет данных'),
            );
          }
        },
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