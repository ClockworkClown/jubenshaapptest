import 'package:flutter/material.dart';

class AdminSuccessScreen extends StatelessWidget {
  final String username;
  final String password;

  AdminSuccessScreen({required this.username, required this.password});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login Successful'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Admin Login Successful!'),
            SizedBox(height: 16.0),
            Text('Username: $username'),
            SizedBox(height: 16.0),
            Text('Password: $password'),
          ],
        ),
      ),
    );
  }
}