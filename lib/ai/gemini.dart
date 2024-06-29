import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';


class ChatExample extends StatefulWidget {
  @override
  _ChatExampleState createState() => _ChatExampleState();
}

class _ChatExampleState extends State<ChatExample> {
  String responseText = 'Awaiting response...';

  @override
  void initState() {
    super.initState();
    _sendMessage();
  }

  Future<void> _sendMessage() async {
    await Gemini.init(apiKey: "AIzaSyBPc-P9xs_4CSiqXzawDxv5adniQ1ewLyE", enableDebugging: true);
    final gemini = Gemini.instance;

    final generationConfig = GenerationConfig(
      temperature: 1,
      topP: 0.95,
      topK: 64,
      maxOutputTokens: 8192,
    );


    gemini.chat(
      generationConfig: generationConfig,
      [ Content(
          parts: [
            Parts(text:
            '''
            You have to summarize the inspection details of tires, battery, brakes and engines of articulated trucks and suggest recommendation like broken windshied, oil color etc

            1. TIRES
            Tire Pressure for Left Front: 105 psi
            Tire Pressure for Right Front: 110 psi
            Tire condition for Left Front: Good
            Tire condition for Right Front: Good
            Tire Pressure for Left Rear (Outer): 85 psi
            Tire Pressure for Right Rear (Outer): 80 psi
            Tire condition for Left Rear (Outer): Ok
            Tire condition for Right Rear (Outer): Ok
            Tire Pressure for Left Rear (Inner): 90 psi
            Tire Pressure for Right Rear (Inner): 95 psi
            Tire condition for Left Rear (Inner): Needs Replacement
            Tire condition for Right Rear (Inner): Ok
            Overall Tire Summary: Front tires are in good condition with acceptable pressure. Right rear tires show slightly uneven wear but are within acceptable limits. Left rear outer tire is nearing replacement threshold. Left rear inner tire requires immediate replacement.
            ''')],
        role: 'user'
        ),
      ],
    ).then((value) => setState(() {
      responseText = value?.output ?? 'without output';
    }))
        .catchError((e) => log('chat', error: e));


  }

  @override
  Widget build(BuildContext context) {
    return
          Padding(
            padding: EdgeInsets.all(25),
            child: Text(responseText, style: TextStyle(
              fontSize: 10,
              color: Colors.white
            ),),
          );
  }
}
