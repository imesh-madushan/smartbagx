import 'package:firebase_auth/firebase_auth.dart';
import 'package:smartbagx/model/location.dart';
import 'package:smartbagx/model/reminders.dart';

class Bag {
  final user = FirebaseAuth.instance.currentUser;
  String name;
  final String id;
  late int weight;
  late int battery;
  late String ownerId;
  late Location location;
  late bool lost;
  late Reminders reminders;

  Bag({required this.name, required this.id});
}
