import 'package:flutter/material.dart';
import '../models/inspection_data.dart';
import 'checklist.dart';

class ComplaintsScreen extends StatelessWidget {

  final InspectionData inspectionData;

  const ComplaintsScreen({
    required this.inspectionData,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Complaints'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(
            elevation: 3,
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            child: ListTile(
              title: Text('Check Vehicle Checklist'),
              subtitle: Text('Open the checklist for vehicle inspection'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CarPartsScreen(inspectionData: inspectionData,)),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
