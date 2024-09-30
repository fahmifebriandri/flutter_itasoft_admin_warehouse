import 'dart:convert';

import 'package:http/http.dart' as http;

class LoginResponse {
  final bool isAdmin;
  final String username;
  final String token;

  LoginResponse({required this.isAdmin, required this.username, required this.token});

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      isAdmin: json['isAdmin'],
      username: json['username'],
      token: json['token'],
    );
  }
}

class LoginModel {
  final String apiUrl = 'https://itasoft.int.joget.cloud/jw/api/sso';
  final String apiKey = '6a9ed2eaf0ff4274ab2370bed8ea31fc';
  final String apiId = 'API-b8b98d97-008d-4b83-aa59-cb133665638b';

  Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        'api_key': apiKey,
        'api_id': apiId,
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'j_username': username,
        'j_password': password,
      },
    );

    if (response.statusCode == 200) {
      var responseData = json.decode(response.body);
      return {
        'success': true,
        'data': responseData,
      };
    } else {
      return {
        'success': false,
        'message': 'Login gagal! Username atau password salah.',
      };
    }
  }
}
