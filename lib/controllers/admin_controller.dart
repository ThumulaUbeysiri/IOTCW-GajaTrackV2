import 'package:firebase_database/firebase_database.dart';
import '../models/elephant.dart';

class AdminController {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  // Fetch all elephants from Firebase DB
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
