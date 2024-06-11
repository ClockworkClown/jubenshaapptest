import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:register.dart';
import 'package:player_homescreen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dart:convert';

import 'adminlogin.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String _email = '', _password = '';

  Future<void> _login() async {
    final formData = {
      'email': _email,
      'password': _password,
    };

    final response = await http.post(
      Uri.parse('http://localhost:3000/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(formData),
    );

    if (response.statusCode == 200) {
      // Login successful
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('email', _email);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PlayerHomeScreen(email: _email),
        ),
      );
    } else {
      // Login failed
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error'),
          content: Text('Invalid credentials'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: 'Email'),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter your email';
                  }
                  return null;
                },
                onSaved: (value) => _email = value!,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter your password';
                  }
                  return null;
                },
                onSaved: (value) => _password = value!,
              ),
              SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    _login();
                  }
                },
                child: Text('Login'),
              ),
              SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RegistrationScreen(
                      ),
                    ),
                  );
                },
                child: Text('Register'),
              ),
              SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AdminLogin(
                      ),
                    ),
                  );
                },
                child: Text('Admin Login'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
