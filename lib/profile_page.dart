import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:smartbagx/auth/auth_services.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final User user = AuthServices.firebaseAuth.currentUser!;
  TextEditingController nameController = TextEditingController();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DatabaseReference _bagRef = FirebaseDatabase.instance.ref('bags');
  late final String contactNo;

  @override
  void initState() {
    super.initState();
    _contactListener();
  }

  void _contactListener() async {
    _firestore.collection('users').doc(user.uid).get().then((event) {
      if (event.exists && event.get('contactNo') != null) {
        contactNo = event.get('contactNo');
        nameController.text = contactNo;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Profile Page'),
          actions: [
            IconButton(
              onPressed: () async {
                await AuthServices.signOut();
              },
              icon: Icon(Icons.logout),
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(12),
              child: TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'Contact No'),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: () async {
                String contactNoNew = nameController.text.trim();

                if (contactNoNew.isNotEmpty) {
                  // Update contact no in firestore
                  await _firestore
                      .collection('users')
                      .doc(user.uid)
                      .update({'contactNo': contactNoNew});

                  // Update contact no in realtime database
                  _bagRef
                      .orderByChild('ownerId')
                      .equalTo(user.uid)
                      .once()
                      .then((DatabaseEvent event) {
                    if (event.snapshot.value != null) {
                      Map<dynamic, dynamic> values =
                          event.snapshot.value as Map<dynamic, dynamic>;
                      values.forEach((key, values) {
                        _bagRef.child(key).update({'contactNo': contactNoNew});
                      });
                    }
                  });

                  contactNo = contactNoNew;

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Contact No updated successfully')),
                  );
                } else {
                  // Delete contact no in firestore
                  await _firestore
                      .collection('users')
                      .doc(user.uid)
                      .update({'contactNo': FieldValue.delete()});

                  // Delete contact no in realtime database
                  _bagRef
                      .orderByChild('ownerId')
                      .equalTo(user.uid)
                      .once()
                      .then((DatabaseEvent event) {
                    if (event.snapshot.value != null) {
                      Map<dynamic, dynamic> values =
                          event.snapshot.value as Map<dynamic, dynamic>;
                      values.forEach((key, values) {
                        _bagRef.child(key).update({'contactNo': null});
                      });
                    }
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Contact No deleted')),
                  );
                }
              },
              child: Text('Update'),
            ),
          ],
        ));
  }
}
