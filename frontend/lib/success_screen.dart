import 'package:flutter/material.dart';

class SuccessScreen extends StatelessWidget {
  final String email;
  final String password;

  SuccessScreen({required this.email, required this.password});

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
            Text('Player Login Successful!'),
            SizedBox(height: 16.0),
            Text('Email: $email'),
            SizedBox(height: 16.0),
            Text('Password: $password'),
          ],
        ),
      ),
    );
  }
}