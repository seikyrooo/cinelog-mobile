import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/media_item.dart';

class ApiService {
  // Production VPS Server:
  static String baseUrl = 'https://cinelog.dwikooo.cloud';

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

  static Future<Map<String, dynamic>?> fetchMediaDetail(int id, String mediaType) async {
    final url = Uri.parse('$baseUrl/api/detail?id=$id&type=$mediaType');
    try {
      final resp = await http.get(url);
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        return data['data'];
      }
    } catch (_) {}
    return null;
  }

  static Future<List<dynamic>> fetchTVSeasonEpisodes(int tmdbId, int seasonNumber) async {
    final url = Uri.parse('$baseUrl/api/tv/season?id=$tmdbId&season=$seasonNumber');
    try {
      final resp = await http.get(url);
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        return data['data'] ?? [];
      }
    } catch (_) {}
    return [];
  }

  static Future<List<WatchlistItem>> getWatchlist({
    String? status,
    bool favoriteOnly = false,
    String? mediaType,
  }) async {
    final token = await getToken();
    if (token == null) return [];

    List<String> queryParts = [];
    if (status != null && status.isNotEmpty && status != 'all') {
      queryParts.add('status=$status');
    }
    if (favoriteOnly) {
      queryParts.add('favorite=true');
    }
    if (mediaType != null && mediaType.isNotEmpty && mediaType != 'all') {
      queryParts.add('media_type=$mediaType');
    }

    final queryStr = queryParts.isNotEmpty ? '?${queryParts.join('&')}' : '';
    final url = Uri.parse('$baseUrl/api/user/watchlist$queryStr');
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
    int seasonWatched = 1,
    int episodesWatched = 0,
    int totalEpisodes = 0,
    String director = '',
    String cast = '',
    String nextAirDate = '',
    String nextEpisodeName = '',
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
        'director': director.isNotEmpty ? director : item.director,
        'cast': cast.isNotEmpty ? cast : item.cast,
        'total_seasons': item.totalSeasons,
        'next_air_date': nextAirDate.isNotEmpty ? nextAirDate : item.nextAirDate,
        'next_episode_name': nextEpisodeName.isNotEmpty ? nextEpisodeName : item.nextEpisodeName,
        'status': status,
        'rating': rating,
        'favorite': favorite,
        'notes': notes,
        'season_watched': seasonWatched,
        'episodes_watched': episodesWatched,
        'total_episodes': totalEpisodes > 0 ? totalEpisodes : item.totalEpisodes,
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
    int seasonWatched = 1,
    int episodesWatched = 0,
    int totalEpisodes = 0,
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
        'season_watched': seasonWatched,
        'episodes_watched': episodesWatched,
        'total_episodes': totalEpisodes,
      }),
    );

    return resp.statusCode == 200;
  }

  static Future<bool> incrementEpisodeProgress(int id) async {
    final token = await getToken();
    if (token == null) return false;

    final url = Uri.parse('$baseUrl/api/user/watchlist/$id/progress');
    final resp = await http.put(
      url,
      headers: {'Authorization': 'Bearer $token'},
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

  static Future<List<MediaItem>> fetchTrendingMedia({String type = 'all', String time = 'week'}) async {
    final url = Uri.parse('$baseUrl/api/trending?type=$type&time=$time');
    try {
      final resp = await http.get(url);
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final List list = data['data'] ?? [];
        return list.map((e) => MediaItem.fromSearchJson(e)).toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<List<MediaItem>> fetchDiscoverMedia({String type = 'movie', String sort = 'popularity.desc'}) async {
    final url = Uri.parse('$baseUrl/api/discover?type=$type&sort=$sort');
    try {
      final resp = await http.get(url);
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final List list = data['data'] ?? [];
        return list.map((e) => MediaItem.fromSearchJson(e)).toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<List<CommunityUser>> fetchCommunityUsers({String? query}) async {
    final token = await getToken();
    final url = Uri.parse(query != null && query.isNotEmpty 
      ? '$baseUrl/api/users/search?q=${Uri.encodeComponent(query)}'
      : '$baseUrl/api/users/discover');
    
    final headers = <String, String>{};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    try {
      final resp = await http.get(url, headers: headers);
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final List list = data['data'] ?? [];
        return list.map((e) => CommunityUser.fromJson(e)).toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<List<SocialActivityItem>> fetchSocialActivities({String type = 'following', int limit = 30}) async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/api/community/activity?type=$type&limit=$limit');
    
    final headers = <String, String>{};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    try {
      final resp = await http.get(url, headers: headers);
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final List list = data['data'] ?? [];
        return list.map((e) => SocialActivityItem.fromJson(e)).toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<bool> followUser(int userId) async {
    final token = await getToken();
    if (token == null) return false;
    final url = Uri.parse('$baseUrl/api/me/follow/$userId');
    try {
      final resp = await http.post(url, headers: {'Authorization': 'Bearer $token'});
      return resp.statusCode == 200 || resp.statusCode == 201;
    } catch (_) {}
    return false;
  }

  static Future<bool> unfollowUser(int userId) async {
    final token = await getToken();
    if (token == null) return false;
    final url = Uri.parse('$baseUrl/api/me/follow/$userId');
    try {
      final resp = await http.delete(url, headers: {'Authorization': 'Bearer $token'});
      return resp.statusCode == 200;
    } catch (_) {}
    return false;
  }

  static String getFullImageUrl(MediaItem movie) {
    if (movie.localPosterPath.isNotEmpty) {
      if (movie.localPosterPath.startsWith('/')) {
        return '$baseUrl/api${movie.localPosterPath}';
      }
      return '$baseUrl/api/${movie.localPosterPath}';
    }
    if (movie.posterPath.isNotEmpty) {
      return 'https://image.tmdb.org/t/p/w500${movie.posterPath}';
    }
    return '';
  }

  static String getFullBackdropUrl(MediaItem movie) {
    if (movie.localBackdropPath.isNotEmpty) {
      if (movie.localBackdropPath.startsWith('/')) {
        return '$baseUrl/api${movie.localBackdropPath}';
      }
      return '$baseUrl/api/${movie.localBackdropPath}';
    }
    if (movie.backdropPath.isNotEmpty) {
      return 'https://image.tmdb.org/t/p/w780${movie.backdropPath}';
    }
    return '';
  }

  static String getAvatarUrl(String avatarPath) {
    if (avatarPath.isEmpty) return '';
    if (avatarPath.startsWith('http://') || avatarPath.startsWith('https://')) {
      return avatarPath;
    }
    if (avatarPath.startsWith('/api/uploads/')) {
      return '$baseUrl$avatarPath';
    }
    if (avatarPath.startsWith('/uploads/')) {
      return '$baseUrl/api$avatarPath';
    }
    return '$baseUrl/api/uploads/avatars/$avatarPath';
  }
}
