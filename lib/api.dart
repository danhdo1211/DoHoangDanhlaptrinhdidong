import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const String baseUrl = 'https://greatashkayak49.conveyor.cloud';

class Api {
  static String? token;
  static String? role;
  static String? name;

  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };

  static Future<http.Response> get(String path) =>
      http.get(Uri.parse('$baseUrl/$path'), headers: headers);

  static Future<http.Response> post(String path, Map body) =>
      http.post(Uri.parse('$baseUrl/$path'),
          headers: headers, body: jsonEncode(body));

  static Future<http.Response> put(String path, Map body) =>
      http.put(Uri.parse('$baseUrl/$path'),
          headers: headers, body: jsonEncode(body));

  static Future<http.Response> delete(String path) =>
      http.delete(Uri.parse('$baseUrl/$path'), headers: headers);

  static Future<void> saveSession(Map data) async {
    token = data['token'];
    role = data['role'];
    name = data['fullName'];
    final p = await SharedPreferences.getInstance();
    await p.setString('token', token!);
    await p.setString('role', role!);
    await p.setString('name', name ?? '');
  }

  static Future<bool> loadSession() async {
    final p = await SharedPreferences.getInstance();
    token = p.getString('token');
    role = p.getString('role');
    name = p.getString('name');
    return token != null;
  }

  static Future<void> logout() async {
    final p = await SharedPreferences.getInstance();
    await p.clear();
    token = null;
    role = null;
  }
}