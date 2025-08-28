import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:smartbagx/auth/auth_services.dart';
import 'package:smartbagx/model/bag.dart';
import 'package:smartbagx/model/location.dart';
import 'package:smartbagx/model/reminders.dart';
import 'package:smartbagx/ui/bag_rename_popup.dart';
import 'package:smartbagx/ui/set_reminder_popup.dart';

class BagDes extends StatefulWidget {
  final Bag bag;
  const BagDes({super.key, required this.bag});

  @override
  _BagDesState createState() => _BagDesState();
}

class _BagDesState extends State<BagDes> {
  final User user = AuthServices.firebaseAuth.currentUser!;
  bool _isLoading = true;
  late Bag bag;
  final DatabaseReference _bagRef = FirebaseDatabase.instance.ref('bags');
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();

  @override
  void initState() {
    super.initState();
    bag = Bag(name: widget.bag.name, id: widget.bag.id);
    _listenBag();
  }

  void _listenBag() {
    // Listen for updates
    _bagRef.child(widget.bag.id).onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        print("bag data: $data");
        _updateBag(data);
      }
    });
  }

  void _updateBag(data) {
    setState(() {
      _isLoading = false;

      try {
        bag.name = data['name'];
        bag.battery = data['battery'];
        bag.weight = data['weight'];
        bag.lost = data['lost'];

        final location = Location(
            latitude: data['last_location']['latitude'],
            longitude: data['last_location']['longitude'],
            lastUpdated: data['last_location']['last_updated']);
        bag.location = location;

        final remindersData = data['reminders'];
        final reminders = Reminders(data['reminders']['status']);
        reminders.sunday = remindersData['sunday'] ?? '';
        reminders.monday = remindersData['monday'] ?? '';
        reminders.tuesday = remindersData['tuesday'] ?? '';
        reminders.wednesday = remindersData['wednesday'] ?? '';
        reminders.thursday = remindersData['thursday'] ?? '';
        reminders.friday = remindersData['friday'] ?? '';
        reminders.saturday = remindersData['saturday'] ?? '';
        bag.reminders = reminders;

        //if reminders deleted in add+ then update status to false
        if (bag.reminders.status == true &&
            (bag.reminders.sunday.isEmpty &&
                bag.reminders.monday.isEmpty &&
                bag.reminders.tuesday.isEmpty &&
                bag.reminders.wednesday.isEmpty &&
                bag.reminders.thursday.isEmpty &&
                bag.reminders.friday.isEmpty &&
                bag.reminders.saturday.isEmpty)) {
          _bagRef.child(widget.bag.id).update({
            'reminders/status': false,
          });
        }

        bag.ownerId = data['ownerId'];
      } catch (e) {
        print('bagdes: Error updating bag: $e');
      }
    });
  }

  Future<void> gotoBag(CameraPosition bagPosition) async {
    final GoogleMapController controller = await _controller.future;
    await controller.animateCamera(CameraUpdate.newCameraPosition(bagPosition));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Text(
                bag.name,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              IconButton(
                onPressed: () {
                  showBagRenameDialog(context, bag.id);
                },
                icon: Icon(Icons.edit),
              ),
            ],
          ),
          actions: [
            IconButton(
              onPressed: () async {
                //delete bag
                await _bagRef.child(widget.bag.id).remove();
              },
              icon: Icon(Icons.delete_rounded, color: Colors.red),
            ),
          ],
        ),
        body: _isLoading
            ? Center(
                child: CircularProgressIndicator(),
              )
            : Stack(
                children: [
                  Column(
                    children: [
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                          ),
                          Text('Bag ID: '),
                          Text(bag.id),
                        ],
                      ),
                      // Row(
                      //   children: [
                      //     Padding(
                      //       padding: const EdgeInsets.all(8.0),
                      //     ),
                      //     Text('Battery: '),
                      //     Text('${bag.battery}%'),
                      //   ],
                      // ),
                      // Row(
                      //   children: [
                      //     Padding(
                      //       padding: const EdgeInsets.all(8.0),
                      //     ),
                      //     Text('Weight: '),
                      //     Text('${bag.weight} Kg'),
                      //   ],
                      // ),
                      Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                          ),
                          Text('Last Updated: '),
                          Text('${bag.location.lastUpdated}'),
                        ],
                      ),

                      //reminders section
                      Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                          ),
                          Text('Reminders: '),
                          Transform.scale(
                              scale: 0.75,
                              child: Switch(
                                value: bag.reminders.status,
                                onChanged: (bool value) async {
                                  if (value == false) {
                                    _bagRef.child(widget.bag.id).update({
                                      'reminders/status': value,
                                    });
                                    return;
                                  }

                                  if (bag.reminders.sunday.isEmpty &&
                                      bag.reminders.monday.isEmpty &&
                                      bag.reminders.tuesday.isEmpty &&
                                      bag.reminders.wednesday.isEmpty &&
                                      bag.reminders.thursday.isEmpty &&
                                      bag.reminders.friday.isEmpty &&
                                      bag.reminders.saturday.isEmpty) {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(SnackBar(
                                      content: Text(
                                          'Please set at least one reminder!'),
                                    ));
                                    print('Please set at least one reminder!');
                                    return;
                                  }

                                  _bagRef.child(widget.bag.id).update({
                                    'reminders/status': value,
                                  });
                                },
                                activeColor: Colors.green,
                              )),
                          TextButton(
                            onPressed: () {
                              openSetReminder(context, bag.id);
                            },
                            child: Row(
                              children: [
                                Text('Add'),
                                Icon(Icons.add),
                              ],
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 4),
                      bag.lost
                          ? Container(
                              margin: const EdgeInsets.fromLTRB(0, 0, 0, 4),
                              child: Text(
                                'Lost Alarm Triggered!',
                                style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold),
                              ),
                            )
                          : Container(),

                      //button to ring bag
                      ElevatedButton(
                        onPressed: () {
                          _bagRef.child(widget.bag.id).update({
                            'lost': !bag.lost,
                          });
                        },
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all(
                              bag.lost ? Colors.green : Colors.red),
                        ),
                        child: SizedBox(
                          width: 170,
                          height: 50,
                          child: Center(
                            child: bag.lost
                                ? Text('Turn off Alarm',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 15))
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('Trigger Lost Alarm',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 15)),
                                      const SizedBox(width: 10),
                                      Icon(
                                        Icons.notification_important_sharp,
                                        color: Colors.yellow,
                                        size: 24,
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      //bag location map
                      Flexible(
                        child: GoogleMap(
                          mapType: MapType.hybrid,
                          initialCameraPosition: CameraPosition(
                              target: LatLng(bag.location.latitude,
                                  bag.location.longitude),
                              zoom: 15),
                          onMapCreated: (GoogleMapController controller) {
                            _controller.complete(controller);
                          },
                          markers: {
                            Marker(
                              markerId: MarkerId('current_location'),
                              position: LatLng(bag.location.latitude,
                                  bag.location.longitude),
                            ),
                          },
                          zoomControlsEnabled: false,
                        ),
                      ),
                    ],
                  ),

                  //button for recenter map to bag location
                  Positioned(
                      bottom: 20,
                      right: 20,
                      child: FloatingActionButton(
                        child: Icon(Icons.location_searching),
                        backgroundColor: Colors.white,
                        onPressed: () {
                          gotoBag(CameraPosition(
                            target: LatLng(
                                bag.location.latitude, bag.location.longitude),
                            zoom: 15,
                          ));
                        },
                      ))
                ],
              ));
  }
}
