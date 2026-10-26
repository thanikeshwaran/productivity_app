import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Generic persistence for a list of JSON-serializable entities under one
/// SharedPreferences key. This is the temporary local implementation behind
/// each repository interface - swapping it for a Firestore-backed
/// implementation later requires no changes to any screen (see
/// data/repositories/*_repository.dart).
class JsonListStore<T> {
  JsonListStore({
    required this.prefsKey,
    required this.toJson,
    required this.fromJson,
  });

  final String prefsKey;
  final Map<String, dynamic> Function(T item) toJson;
  final T Function(Map<String, dynamic> json) fromJson;

  Future<List<T>> readAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(prefsKey);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((e) => fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> writeAll(List<T> items) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(items.map(toJson).toList());
    await prefs.setString(prefsKey, raw);
  }
}
