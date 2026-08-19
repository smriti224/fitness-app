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

  /// Fetches everything the Home tab needs in one call.
  static Future<Map<String, dynamic>> getHomeSummary() async {
    final response = await http.get(Uri.parse('$baseUrl/api/home'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to load home summary (status ${response.statusCode})');
    }
  }
}
