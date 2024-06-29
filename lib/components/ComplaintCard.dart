import 'package:flutter/material.dart';
import 'package:truck_check/main.dart';
import 'package:truck_check/screens/complaints.dart';

import '../models/inspection_data.dart';

class InspectionCard extends StatelessWidget {
  final InspectionData inspectionData;

  const InspectionCard({
    required this.inspectionData,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MyHomePage(
                inspectionData: inspectionData,
              ),
            ),
          );
        },
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.network(inspectionData.url),
              SizedBox(height: 8),
              Text('Truck Serial Number: ${inspectionData.truckSerialNumber}'),
              Text('Truck Model: ${inspectionData.truckModel}'),
              Text('Inspection ID: ${inspectionData.inspectionId}'),
              Text('Date & Time of Inspection: ${inspectionData.dateTime}'),
              Text('Location of Inspection: ${inspectionData.location}'),
              Text('Geo Coordinates: ${inspectionData.geoCoordinates}'),
              Text('Service Meter Hours: ${inspectionData.serviceMeterHours}'),
              Text('Customer Name: ${inspectionData.customerName}'),
              Text('CAT Customer ID: ${inspectionData.catCustomerId}'),
            ],
          ),
        ),
      ),
    );
  }
}
