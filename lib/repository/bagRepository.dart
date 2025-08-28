import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:smartbagx/auth/auth_services.dart';
import 'package:smartbagx/model/bag.dart';
import 'package:firebase_database/firebase_database.dart';

class Bagrepository {
  final User user = AuthServices.firebaseAuth.currentUser!;
  final _realtimeDB = FirebaseDatabase.instance.ref();

  //never used
  Future<List<Bag>?> getBags() async {
    try {
      final bagRef = _realtimeDB.child('bags');
      final snapshot =
          await bagRef.orderByChild('ownerId').equalTo(user.uid).once();
      final List<Bag> bags = [];

      if (snapshot.snapshot.value != null) {
        Map<dynamic, dynamic> bagMap =
            snapshot.snapshot.value as Map<dynamic, dynamic>;
        bagMap.forEach((key, value) {
          // Ensure the bag is owned by the correct user
          if (value['ownerId'] == user.uid) {
            bags.add(Bag(
              name: value['name'],
              id: value['id'],
            ));
          }
        });
      }

      if (bags.isNotEmpty) {
        return bags;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  Future<String> addBag(String bagName, String bagID) async {
    try {
      //check if the bag is valid by checking in real-time database
      final isItemExistInRTD = await checkBagAvailability(bagID);

      switch (isItemExistInRTD) {
        case 'new':
          await _realtimeDB.child('bags/$bagID').update({
            'ownerId': user.uid,
            'name': bagName,
          });
          return 'Bag added successfully';
        case 'owned':
          return 'Bag already owned by you';
        case 'notowned':
          return 'Bag already owned by another user';
        case 'notexist':
          return 'Bag does not exist';
        case 'error':
          return 'Error occurred';
        default:
          return 'Error occurred';
      }
    } catch (e) {
      return 'Failed to add bag';
    }
  }

  //check if a item exists in the real-time database
  Future<String> checkBagAvailability(String bagID) async {
    try {
      final snapshot = await _realtimeDB.child('bags/$bagID').once();

      if (snapshot.snapshot.value != null) {
        //check if the bag is owned by the same user
        final bagData = snapshot.snapshot.value as Map<dynamic, dynamic>?;

        if (bagData?['ownerId'] == null) {
          return 'new';
        } else if (bagData?['ownerId'] == user.uid.toString()) {
          return 'owned';
        } else {
          return 'notowned';
        }
      } else {
        return 'notexist';
      }
    } catch (e) {
      return 'error';
    }
  }

  //rename bag
  Future<void> renameBag(String bagID, String newName) async {
    try {
      await _realtimeDB.child('bags/$bagID').update({'name': newName});
    } catch (e) {
      print('Error renaming bag: $e');
    }
  }

  //update contact number
  Future<void> updateContactNumber(String contactNo, String bagID) async {
    try {
      await _realtimeDB.child('bags/${bagID}').update({'contactNo': contactNo});
    } catch (e) {
      print('Error updating contact number: $e');
    }
  }

  //remove this function, cuz this is for testing
  Future<void> addBagsToRealtimeDB() async {
    final databaseRef = FirebaseDatabase.instance.ref();

    final bags = [
      {
        "id": "abcd1",
        "name": "Bag 1",
        "ownerId": "QKzb7M4mSrSW8ethBqqcMqBsQ6I2",
        "battery": 100,
        "weight": 5,
        "last_location": {
          "latitude": 12.9716,
          "longitude": 77.5946,
          "last_updated": "2021-06-01T12:00:00Z"
        },
        "lost": false,
        "reminders": {
          "status": false,
          "sunday": "History, Maths, Science",
          "monday": null,
          "tuesday": "Science, English, Biology",
          "wednesday": null,
          "thursday": null,
          "friday": null,
          "saturday": null
        }
      },
      {
        "id": "abcd2",
        "name": "Bag 2",
        "ownerId": "QKzb7M4mSrSW8ethBqqcMqBsQ6I2",
        "battery": 50,
        "weight": 5,
        "last_location": {
          "latitude": 12.9716,
          "longitude": 77.5946,
          "last_updated": "2021-06-01T12:00:00Z"
        },
        "lost": false,
        "reminders": {
          "status": false,
          "sunday": "History, Maths, Science",
          "monday": null,
          "tuesday": "Science, English, Biology",
          "wednesday": null,
          "thursday": null,
          "friday": null,
          "saturday": null
        }
      },
      {
        "id": "abcd3",
        "battery": 18,
        "weight": 5,
        "last_location": {
          "latitude": 12.9716,
          "longitude": 77.5946,
          "last_updated": "2021-06-01T12:00:00Z"
        },
        "lost": false,
        "reminders": {
          "status": false,
          "sunday": "History, Maths, Science",
          "monday": null,
          "tuesday": "Science, English, Biology",
          "wednesday": null,
          "thursday": null,
          "friday": null,
          "saturday": null
        }
      }
    ];

    try {
      for (var bag in bags) {
        final bagID = bag['id']; // Use bag ID as the document key
        await databaseRef.child('bags/$bagID').set(bag);
      }
    } catch (e) {
      print(e);
    }
  }
}
