import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'login_model.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final LoginModel _loginModel = LoginModel();

  void _login() async {
    String username = _usernameController.text;
    String password = _passwordController.text;
    // Menerima hasil dari metode login
    Map<String, dynamic> result = await _loginModel.login(username, password);
    if (result['success']) {
      // Login berhasil
      Map<String, dynamic> resultData = result['data'];
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await Future.wait([
        prefs.setString('token', resultData['token']),
        prefs.setString('username', resultData['username']),
      ]);

      Navigator.pushReplacementNamed(context, '/home');
      print('Username: ${resultData['username']}');
      print('Token: ${resultData['token']}');
      print('isAdmin: ${resultData['isAdmin']}');
    } else {
      String errorMessage = result['message'];
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Icon login di tengah
                      const Icon(
                        Icons.apple,
                        size: 100, // Ukuran ikon
                      ),
                      const SizedBox(height: 30), // Jarak 30px dengan kolom username
                      // Kolom Username
                      TextField(
                        controller: _usernameController,
                        decoration: const InputDecoration(labelText: 'Username'),
                      ),
                      // Kolom Password
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(labelText: 'Password'),
                      ),
                      const SizedBox(height: 20),
                      // Tombol Login
                      ElevatedButton(
                        onPressed: _login,
                        child: const Text('Login'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
