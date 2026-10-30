import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const String baseUrl = 'https://neworangepage27.conveyor.cloud/api';

class Api {
  static String? token, role, name;
  static final fontScale = ValueNotifier<double>(1.0);
  static final seedColor = ValueNotifier<Color>(const Color(0xFF6C63FF));

  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };

  static Future<http.Response> get(String p) =>
      http.get(Uri.parse('$baseUrl/$p'), headers: headers);
  static Future<http.Response> post(String p, Map b) =>
      http.post(Uri.parse('$baseUrl/$p'), headers: headers, body: jsonEncode(b));
  static Future<http.Response> put(String p, Map b) =>
      http.put(Uri.parse('$baseUrl/$p'), headers: headers, body: jsonEncode(b));
  static Future<http.Response> delete(String p) =>
      http.delete(Uri.parse('$baseUrl/$p'), headers: headers);

  static Future<void> saveSession(Map d) async {
    token = d['token'];
    role = d['role'];
    name = d['fullName'];
    final p = await SharedPreferences.getInstance();
    await p.setString('token', token!);
    await p.setString('role', role ?? '');
    await p.setString('name', name ?? '');
  }

  static Future<bool> loadSession() async {
    final p = await SharedPreferences.getInstance();
    fontScale.value = p.getDouble('font') ?? 1.0;
    seedColor.value = Color(p.getInt('color') ?? 0xFF6C63FF);
    token = p.getString('token');
    role = p.getString('role');
    name = p.getString('name');
    return token != null;
  }

  static Future<void> saveSettings() async {
    final p = await SharedPreferences.getInstance();
    await p.setDouble('font', fontScale.value);
    await p.setInt('color', seedColor.value.toARGB32());
  }

  static Future<void> logout() async {
    final p = await SharedPreferences.getInstance();
    await p.remove('token');
    await p.remove('role');
    await p.remove('name');
    token = null;
    role = null;
    name = null;
  }
}