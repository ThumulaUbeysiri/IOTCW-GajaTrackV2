import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class AdminViewDriversView extends StatefulWidget {
  @override
  State<AdminViewDriversView> createState() => _AdminViewDriversViewState();
}

class _AdminViewDriversViewState extends State<AdminViewDriversView> {
  final dbRef = FirebaseDatabase.instance.ref().child('users');
  List<Map<String, dynamic>> drivers = [];

  @override
  void initState() {
    super.initState();
    _fetchDrivers();
  }

  Future<void> _fetchDrivers() async {
    final snapshot = await dbRef.get();
    List<Map<String, dynamic>> loadedDrivers = [];

    for (final user in snapshot.children) {
      final data = Map<String, dynamic>.from(user.value as Map);
      if (data['role'] == 'driver') {
        loadedDrivers.add({'email': data['email'], 'uid': user.key});
      }
    }

    setState(() => drivers = loadedDrivers);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Driver Accounts',
          style: TextStyle(color: Colors.white),  // Black title text
        ),
        backgroundColor: Colors.green.shade600,
        iconTheme: const IconThemeData(color: Colors.white),  // Black back button
      ),
      backgroundColor: Colors.green.shade50,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: drivers.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : ListView.separated(
          itemCount: drivers.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (context, index) {
            final driver = drivers[index];
            return ListTile(
              leading: const Icon(Icons.person, color: Colors.green),
              title: Text(driver['email']),
              subtitle: Text('UID: ${driver['uid']}'),
            );
          },
        ),
      ),
    );
  }
}
