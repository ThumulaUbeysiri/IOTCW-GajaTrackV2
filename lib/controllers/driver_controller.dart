import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import '../models/elephant.dart';
import '../models/train.dart';

class DriverController {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  // Get real-time GPS position of phone (train)
  Future<Train> getCurrentTrainLocation() async {
    Position position = await Geolocator.getCurrentPosition();
    return Train(lat: position.latitude, lon: position.longitude);
  }

  // Fetch all elephants
  Future<List<Elephant>> fetchElephants() async {
    final snapshot = await _dbRef.child('elephants').get();
    List<Elephant> elephants = [];
    if (snapshot.exists) {
      for (final child in snapshot.children) {
        elephants.add(Elephant.fromMap(child.key!, Map<String, dynamic>.from(child.value as Map)));
      }
    }
    return elephants;
  }
}
