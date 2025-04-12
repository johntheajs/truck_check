import 'package:flutter/material.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:truck_check/screens/login_screen.dart';
import 'models/inspection_data.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/checklist.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  final modelManager = OnDeviceTranslatorModelManager();
  if (await modelManager.isModelDownloaded(TranslateLanguage.english.bcpCode)) {
    await modelManager.downloadModel(TranslateLanguage.english.bcpCode);
  }
  if (await modelManager.isModelDownloaded(TranslateLanguage.spanish.bcpCode)) {
    await modelManager.downloadModel(TranslateLanguage.spanish.bcpCode);
  }
  if (await modelManager.isModelDownloaded(TranslateLanguage.hindi.bcpCode)) {
    await modelManager.downloadModel(TranslateLanguage.hindi.bcpCode);
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inspection Assist',
      theme: ThemeData(
        colorScheme:
            ColorScheme.fromSeed(seedColor: Color.fromARGB(255, 246, 225, 63)),
        useMaterial3: true,
      ),
      // home: const MyHomePage(title: 'Inspection Checklist'),
      home: LoginScreen(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.inspectionData});

  final InspectionData inspectionData;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final onDeviceTranslator = OnDeviceTranslator(
      sourceLanguage: TranslateLanguage.english,
      targetLanguage: TranslateLanguage.hindi);

  final PageController _pageController = PageController();
  final List<Map<String, String>> checklistItems = [
    {'title': 'Hat', 'description': 'Protects from sunlight and minor debris.'},
    {
      'title': 'Suit',
      'description':
          'Full-body coverall to keep clothes clean and provide protection.'
    },
    {
      'title': 'Stylus Pen',
      'description': 'For accurate input on touch screens.'
    },
    {
      'title': 'Gloves',
      'description': 'Protects hands from dirt, grime, and minor injuries.'
    },
    {
      'title': 'Glasses',
      'description':
          'Safety glasses to protect eyes from debris and chemical splashes.'
    },
    {
      'title': 'Equipment Box',
      'description': 'Holds and organizes all necessary tools and equipment.'
    },
    {
      'title': 'High-Visibility Vest',
      'description': 'Ensures visibility in all work environments.'
    },
    {
      'title': 'Ear Protection',
      'description': 'Necessary in loud environments to prevent hearing damage.'
    },
    {
      'title': 'Face Mask/Respirator',
      'description':
          'Protects against dust, fumes, and other airborne particles.'
    },
    {
      'title': 'Flashlight',
      'description': 'Essential for inspecting dark or hard-to-see areas.'
    },
    {
      'title': 'Inspection Mirror',
      'description':
          'Useful for viewing parts of the vehicle that are difficult to see directly.'
    },
    {
      'title': 'Digital Camera/Smartphone',
      'description':
          'For documenting the condition of the vehicle and any issues found.'
    },
    {
      'title': 'First Aid Kit',
      'description': 'For any minor injuries that might occur.'
    },
    {
      'title': 'Tablet or Laptop',
      'description':
          'For accessing digital manuals, checklists, and recording data.'
    },
  ];

  void _goToNextPage() {
    if (_pageController.page!.toInt() == checklistItems.length - 1) {
      Navigator.push(
        context,
        // MaterialPageRoute(
        //     builder: (context) => ComplaintsScreen(
        //           inspectionData: widget.inspectionData,
        //         )),
        MaterialPageRoute(
            builder: (context) => CarPartsScreen(
                  inspectionData: widget.inspectionData,
                )),
      );
    } else {
      _pageController.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.inspectionData.customerName),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: checklistItems.length,
        physics: NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          final item = checklistItems[index];
          return Center(
            child: FractionallySizedBox(
              widthFactor: 0.9,
              heightFactor: 0.5,
              child: Card(
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        item['title']!,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        item['description']!,
                        style: TextStyle(
                          fontSize: 18,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: _goToNextPage,
                        child: Text('All Set'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
