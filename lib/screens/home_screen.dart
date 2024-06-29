import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:truck_check/models/inspection_data.dart';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import '../components/ComplaintCard.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    ComplaintsScreen(),
    ReportsScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        children: _screens,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.warning),
            label: 'Complaints',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt),
            label: 'Reports',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class ComplaintsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(8.0),
      child: SingleChildScrollView(
        child: Column(
          children: [
            InspectionCard(
              inspectionData: InspectionData(
              url: 'https://s7d2.scene7.com/is/image/Caterpillar/CM20190610-c4f7f-ea3e5',
              truckSerialNumber: '7301234',
              truckModel: '730',
              inspectionId: 1002,
              dateTime: '2024-06-29 10:00 AM',
              location: 'Warehouse A',
              geoCoordinates: '40.7128° N, 74.0060° W',
              serviceMeterHours: '1500 hours',
              inspectorSignature: 'John Doe',
              customerName: 'ABC Construction',
              catCustomerId: 'C12345',
              )
            ),
            InspectionCard(
              inspectionData: InspectionData(
              url: 'https://s7d2.scene7.com/is/image/Caterpillar/CM20190610-c4f7f-ea3e5',
              truckSerialNumber: '730EJ73245',
              truckModel: '730 EJ',
              inspectionId: 1003,
              dateTime: '2024-06-29 11:30 AM',
              location: 'Site B',
              geoCoordinates: '34.0522° N, 118.2437° W',
              serviceMeterHours: '2000 hours',
              inspectorSignature: 'Jane Smith',
              customerName: 'XYZ Landscaping',
              catCustomerId: 'C67890',
              )
            ),
            InspectionCard(
              inspectionData: InspectionData(
              url: 'https://s7d2.scene7.com/is/image/Caterpillar/CM20190610-c4f7f-ea3e5',
              truckSerialNumber: '73592849',
              truckModel: '735',
              inspectionId: 1004,
              dateTime: '2024-06-29 2:00 PM',
              location: 'Garage C',
              geoCoordinates: '51.5074° N, 0.1278° W',
              serviceMeterHours: '1800 hours',
              inspectorSignature: 'Mike Johnson',
              customerName: 'DEF Industries',
              catCustomerId: 'C54321',
            ),
            )
          ],
        ),
      ),
    );
  }
}




class ReportsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return PDFListScreen();
  }
}


class PDFListScreen extends StatefulWidget {

  PDFListScreen({Key? key}) : super(key: key);

  @override
  _PDFListScreenState createState() => _PDFListScreenState();
}

class _PDFListScreenState extends State<PDFListScreen> {
  late List<Reference> pdfReferences;
  late FirebaseStorage storage;

  @override
  void initState() {
    super.initState();
    storage = FirebaseStorage.instance;
    fetchPDFList();
  }

  Future<void> fetchPDFList() async {
    try {
      final ref = storage.ref().child('pdfs/');
      ListResult result = await ref.listAll();
      setState(() {
        pdfReferences = result.items;
      });
    } catch (e) {
      print('Error fetching PDF list: $e');
    }
  }

  Future<void> downloadPDF(int index) async {
    try {
      Reference ref = pdfReferences[index];
      String downloadUrl = await ref.getDownloadURL();
      Directory appDocDir = await getApplicationDocumentsDirectory();
      String filePath = '${appDocDir.path}/PDF_${index + 1}.pdf';

      final Uri url = Uri.parse(downloadUrl);
      launchUrl(url);
      // Show notification after download

      setState(() {
        // Optionally, update UI if needed after download
      });
    } catch (e) {
      print('Error downloading PDF: $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('PDF List'),
      ),
      body: pdfReferences != null
          ? ListView.builder(
        itemCount: pdfReferences.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text('PDF ${index + 1}'),
            leading: Icon(Icons.picture_as_pdf),
            trailing: IconButton(
              icon: Icon(Icons.file_download),
              onPressed: () {
                downloadPDF(index);
              },
            ),
          );
        },
      )
          : Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}


class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late User? _currentUser; // Firebase user
  late String _email; // User's email address

  @override
  void initState() {
    super.initState();
    _fetchCurrentUser();
  }

  void _fetchCurrentUser() {
    _currentUser = FirebaseAuth.instance.currentUser;
    if (_currentUser != null) {
      _email = _currentUser!.email!;
    }
  }


  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
        future: _fetchProfileData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text('No data found.'));
          }

          // Extract data from Firestore document
          var data = snapshot.data!.data() as Map<String, dynamic>;
          String email = data['email'];
          int inspectorId = data['inspectorId'];
          String inspectorName = data['inspectorName'];

          return Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SizedBox(height: 30,),
                Center(
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: AssetImage('assets/images/avatar.png'), // Replace with actual image path
                  ),
                ),

                SizedBox(height: 30),
                ListTile(
                  leading: Icon(Icons.email, color: Colors.blue),
                  title: Text(
                    'Email',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    email,
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                SizedBox(height: 16),
                ListTile(
                  leading: Icon(Icons.perm_identity, color: Colors.green),
                  title: Text(
                    'Inspector ID',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    inspectorId.toString(),
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                SizedBox(height: 16),
                ListTile(
                  leading: Icon(Icons.person, color: Colors.orange),
                  title: Text(
                    'Inspector Name',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    inspectorName,
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          );

        },
    );
  }

  // Fetch profile data from Firestore based on current user's email
  Future<DocumentSnapshot> _fetchProfileData() async {

    if (_currentUser == null) {
      throw Exception('User not authenticated.');
    }

    String email = _currentUser!.email!;
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('inspectors')
        .where('email', isEqualTo: email)
        .get();

    if (querySnapshot.docs.isEmpty) {
      throw Exception('Profile data not found for email: $email');
    }

    return querySnapshot.docs.first;
  }
}