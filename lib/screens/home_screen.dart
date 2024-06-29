import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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
    return Center(
      child: Text('Complaints Screen'),
    );
  }
}

class ReportsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Reports Screen'),
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