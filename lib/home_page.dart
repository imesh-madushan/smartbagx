import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smartbagx/auth/auth_services.dart';
import 'package:smartbagx/auth_page.dart';
import 'package:smartbagx/bag_des.dart';
import 'package:smartbagx/model/bag.dart';
import 'package:smartbagx/profile_page.dart';
import 'ui/add_new_bag_popup.dart';

class HomePage extends StatefulWidget {
  final User user = AuthServices.firebaseAuth.currentUser!;
  HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Bag>? _bags;
  bool _isLoading = true;
  final DatabaseReference _bagRef = FirebaseDatabase.instance.ref('bags');

  @override
  void initState() {
    super.initState();
    _addBagsListener();
  }

  void _addBagsListener() {
    _bagRef
        .orderByChild('ownerId')
        .equalTo(widget.user.uid)
        .onValue
        .listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        final List<Bag> updatedBags = [];
        data.forEach((key, value) {
          if (value['ownerId'] == widget.user.uid) {
            Bag bag = Bag(
              name: value['name'] ?? 'Unknown',
              id: key,
            );
            bag.lost = value['lost'];
            bag.battery = value['battery'];
            updatedBags.add(bag);
          }
        });

        setState(() {
          _bags = updatedBags;
          _isLoading = false;
        });
      } else {
        setState(() {
          _bags = [];
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final userFirstName = widget.user.displayName!.split(' ')[0];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfilePage()),
                );
              },
              icon: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: widget.user.photoURL != null
                    ? Image.network(
                        widget.user.photoURL!,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                      )
                    : Image.asset('assets/images/user.png',
                        width: 40, height: 40, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(width: 12),
            Text(userFirstName, style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.logout,
              size: 28,
            ),
            onPressed: () async {
              await AuthServices.googleSignIn.signOut();
              await AuthServices.firebaseAuth.signOut();

              if (context.mounted) {
                // check if context is still mounted
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const AuthPage()),
                );
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child:
                  CircularProgressIndicator()) // display spinner while fetching data
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    child: Row(
                      children: [
                        Text('Your bags',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 20)),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Icon(
                            Icons.add,
                            size: 26,
                          ),
                          onPressed: () {
                            // add a new bag
                            showAddBagDialog(context);
                          },
                        ),
                      ],
                    )),
                _bags == null || _bags!.isEmpty
                    ? Center(child: Text('No bags found.'))
                    : Expanded(
                        child: ListView.builder(
                          itemCount: _bags!.length,
                          itemBuilder: (context, index) {
                            final bag = _bags![index];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => BagDes(bag: bag)),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Row(
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(bag.name,
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16)),
                                          // Row(
                                          //   children: [
                                          //     Transform.rotate(
                                          //         angle: 90 * 3.1415927 / 180,
                                          //         child: Icon(
                                          //           bag.battery == 100
                                          //               ? Icons
                                          //                   .battery_full_rounded
                                          //               : bag.battery > 80
                                          //                   ? Icons
                                          //                       .battery_6_bar_rounded
                                          //                   : bag.battery > 60
                                          //                       ? Icons
                                          //                           .battery_4_bar_rounded
                                          //                       : bag.battery >
                                          //                               40
                                          //                           ? Icons
                                          //                               .battery_2_bar_rounded
                                          //                           : bag.battery >
                                          //                                   20
                                          //                               ? Icons
                                          //                                   .battery_2_bar_rounded
                                          //                               : Icons
                                          //                                   .battery_alert_rounded,
                                          //           size: 24,
                                          //         )),
                                          //     const SizedBox(width: 3),
                                          //     Text(
                                          //         bag.battery.toString() + '%'),
                                          //   ],
                                          // ),
                                        ],
                                      ),
                                      const Spacer(),
                                      bag.lost
                                          ? const Text(
                                              'Alarm On !',
                                              style: TextStyle(
                                                  color: Colors.red,
                                                  fontWeight: FontWeight.bold),
                                            )
                                          : const SizedBox(),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              ],
            ),
    );
  }
}
