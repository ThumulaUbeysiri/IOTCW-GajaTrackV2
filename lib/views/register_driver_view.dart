import 'package:flutter/material.dart';
import '../controllers/auth_controller.dart';

class RegisterDriverView extends StatefulWidget {
  @override
  State<RegisterDriverView> createState() => _RegisterDriverViewState();
}

class _RegisterDriverViewState extends State<RegisterDriverView> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final AuthController _auth = AuthController();
  bool loading = false;

  void registerDriver() async {
    setState(() => loading = true);
    final success = await _auth.registerDriver(
      emailController.text.trim(),
      passwordController.text.trim(),
    );
    setState(() => loading = false);
    final msg = success != null ? 'Driver registered!' : 'Failed to register driver';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    if (success != null) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Register Driver')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: 'Driver Email'),
            ),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(labelText: 'Password'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: loading ? null : registerDriver,
              child: loading ? CircularProgressIndicator() : Text('Register'),
            )
          ],
        ),
      ),
    );
  }
}
