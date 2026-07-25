import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/media_item.dart';

class ApiService {
  // Production VPS Server:
  static String baseUrl = 'https://cinelog.dwikooo.cloud';

  // Untuk Debugging Android Emulator (Localhost PC):
  // static String baseUrl = 'http://10.0.2.2:3000';

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  static Future<void> setToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
  }

  static Future<Map<String, dynamic>> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/api/auth/login');
    final resp = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    final data = jsonDecode(resp.body);
    if (resp.statusCode == 200 && data['token'] != null) {
      await setToken(data['token']);
      return {'success': true, 'token': data['token']};
    }
    return {'success': false, 'error': data['error'] ?? 'Login gagal'};
  }

  static Future<Map<String, dynamic>> register(String username, String email, String password) async {
    final url = Uri.parse('$baseUrl/api/auth/register');
    final resp = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'email': email, 'password': password}),
    );

    final data = jsonDecode(resp.body);
    if (resp.statusCode == 201) {
      return {'success': true, 'message': data['message']};
    }
    return {'success': false, 'error': data['error'] ?? 'Register gagal'};
  }

  static Future<List<MediaItem>> searchMedia(String query, {String type = 'all'}) async {
    final url = Uri.parse('$baseUrl/api/search?q=${Uri.encodeComponent(query)}&type=$type');
    final resp = await http.get(url);

    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      final List results = data['data'] ?? [];
      return results.map((e) => MediaItem.fromSearchJson(e)).toList();
    }
    return [];
  }

  static Future<List<WatchlistItem>> getWatchlist({String? status, bool favoriteOnly = false}) async {
    final token = await getToken();
    if (token == null) return [];

    String queryParams = '';
    if (status != null && status.isNotEmpty && status != 'all') {
      queryParams += 'status=$status&';
    }
    if (favoriteOnly) {
      queryParams += 'favorite=true';
    }

    final url = Uri.parse('$baseUrl/api/user/watchlist?$queryParams');
    final resp = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      final List results = data['data'] ?? [];
      return results.map((e) => WatchlistItem.fromJson(e)).toList();
    }
    return [];
  }

  static Future<bool> addToWatchlist({
    required MediaItem item,
    required String status,
    required double rating,
    required bool favorite,
    required String notes,
  }) async {
    final token = await getToken();
    if (token == null) return false;

    final url = Uri.parse('$baseUrl/api/user/watchlist');
    final resp = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'tmdb_id': item.tmdbId,
        'media_type': item.mediaType,
        'title': item.title,
        'overview': item.overview,
        'poster_path': item.posterPath,
        'backdrop_path': item.backdropPath,
        'release_date': item.releaseDate,
        'vote_average': item.voteAverage,
        'status': status,
        'rating': rating,
        'favorite': favorite,
        'notes': notes,
      }),
    );

    return resp.statusCode == 200;
  }

  static Future<bool> updateWatchlist({
    required int id,
    required String status,
    required double rating,
    required bool favorite,
    required String notes,
  }) async {
    final token = await getToken();
    if (token == null) return false;

    final url = Uri.parse('$baseUrl/api/user/watchlist/$id');
    final resp = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'status': status,
        'rating': rating,
        'favorite': favorite,
        'notes': notes,
      }),
    );

    return resp.statusCode == 200;
  }

  static Future<bool> deleteWatchlist(int id) async {
    final token = await getToken();
    if (token == null) return false;

    final url = Uri.parse('$baseUrl/api/user/watchlist/$id');
    final resp = await http.delete(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    return resp.statusCode == 200;
  }
}
