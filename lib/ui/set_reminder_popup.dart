import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

Future<void> openSetReminder(BuildContext context, String bagId) async {
  final DatabaseReference bagRef =
      FirebaseDatabase.instance.ref('bags').child(bagId);
  TextEditingController messageController = TextEditingController();
  String selectedDate = 'none';
  final List<String> days = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday'
  ];

  await showDialog(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return AlertDialog(
            title: Text('Set Reminder'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Wrap(
                  spacing: 8.0, // Space between buttons
                  children: [
                    for (String day in days)
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            selectedDate = day;
                          });

                          final reminder = bagRef.child('reminders/$day');
                          reminder.get().then((DataSnapshot snapshot) {
                            if (snapshot.value != null) {
                              messageController.text = snapshot.value as String;
                            } else {
                              messageController.text = '';
                            }
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              selectedDate == day ? Colors.blue : null,
                        ),
                        child: Text(day[0].toUpperCase() + day.substring(1, 3),
                            style: TextStyle(
                                color:
                                    selectedDate == day ? Colors.white : null)),
                      ),
                  ],
                ),
                SizedBox(height: 16),
                selectedDate == 'none'
                    ? Text('Select a day')
                    : TextField(
                        controller: messageController,
                        decoration: InputDecoration(
                          labelText: 'Message',
                          border: OutlineInputBorder(),
                        ),
                      ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  if (selectedDate != 'none' &&
                      messageController.text.isNotEmpty) {
                    saveData(selectedDate, messageController.text, bagId);
                    Navigator.of(context).pop(); // Close the dialog
                  } else if (selectedDate != 'none' &&
                      messageController.text.isEmpty) {
                    deleteData(selectedDate, bagId);
                  } else {
                    // Show a warning if day or message is not set
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content:
                              Text('Please select a day and enter a message.')),
                    );
                  }
                },
                child: Text('Save'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('Close'),
              ),
            ],
          );
        },
      );
    },
  );
}

Future<void> saveData(String date, String data, bagId) async {
  final DatabaseReference bagRef =
      FirebaseDatabase.instance.ref('bags').child(bagId);

  await bagRef.child('reminders').update({
    date: data,
  });

  await bagRef.child('reminders').child('status').set(true);
  // print('Data saved: $dat
}

Future<void> deleteData(String date, bagId) async {
  final DatabaseReference bagRef =
      FirebaseDatabase.instance.ref('bags').child(bagId);

  await bagRef.child('reminders/$date').remove();
}
