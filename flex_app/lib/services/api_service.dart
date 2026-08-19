import 'dart:convert';
import 'package:http/http.dart' as http;

/// Handles every call to your Flask backend.
///
/// IMPORTANT - set baseUrl based on how you're testing:
///   - Testing in Chrome (on this same computer): use http://127.0.0.1:5000
///   - Testing on an Android emulator: use http://10.0.2.2:5000
///     (10.0.2.2 is a special address emulators use to mean "the host computer")
///   - Testing on your actual physical phone: use http://<your computer's local IP>:5000
///     (the 192.168.x.x address you saw when the Flask server started)
class ApiService {
  static const String baseUrl = 'http://127.0.0.1:5000';

  /// "YYYY-MM-DD" for today - the format every endpoint expects for dates.
  static String todayString() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  // ---------------- HOME ----------------

  static Future<Map<String, dynamic>> getHomeSummary() async {
    final response = await http.get(Uri.parse('$baseUrl/api/home'));
    _checkOk(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  // ---------------- TARGETS ----------------

  static Future<Map<String, dynamic>> getTargets() async {
    final response = await http.get(Uri.parse('$baseUrl/api/targets'));
    _checkOk(response);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<void> setTargets({required int calories, required double protein}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/targets'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'target_calories': calories, 'target_protein': protein}),
    );
    _checkOk(response);
  }

  // ---------------- FOOD PRESETS ----------------

  static Future<List<Map<String, dynamic>>> getPresets() async {
    final response = await http.get(Uri.parse('$baseUrl/api/foods/presets'));
    _checkOk(response);
    return List<Map<String, dynamic>>.from(jsonDecode(response.body) as List);
  }

  static Future<void> addPreset({
    required String name,
    required int calories,
    required double protein,
    double baseGrams = 100,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/foods/presets'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'calories': calories, 'protein': protein, 'base_grams': baseGrams}),
    );
    _checkOk(response);
  }

  // ---------------- FOOD LOG ----------------

  /// Pass a date ("YYYY-MM-DD") to get just that day, or omit for every entry ever logged.
  static Future<List<Map<String, dynamic>>> getFoods({String? date}) async {
    final uri = date == null
        ? Uri.parse('$baseUrl/api/foods')
        : Uri.parse('$baseUrl/api/foods?date=$date');
    final response = await http.get(uri);
    _checkOk(response);
    return List<Map<String, dynamic>>.from(jsonDecode(response.body) as List);
  }

  static Future<void> addFood({
    required String date,
    required String name,
    required int calories,
    required double protein,
    double? grams,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/foods'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'date': date, 'name': name, 'calories': calories, 'protein': protein,
        if (grams != null) 'grams': grams,
      }),
    );
    _checkOk(response);
  }

  static Future<void> updateFood({
    required int id,
    String? name,
    int? calories,
    double? protein,
    double? grams,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (calories != null) body['calories'] = calories;
    if (protein != null) body['protein'] = protein;
    if (grams != null) body['grams'] = grams;
    final response = await http.put(
      Uri.parse('$baseUrl/api/foods/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    _checkOk(response);
  }

  static Future<void> deleteFood(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/api/foods/$id'));
    _checkOk(response);
  }

  static void _checkOk(http.Response response) {
    if (response.statusCode != 200) {
      throw Exception('Server error (status ${response.statusCode})');
    }
  }
}