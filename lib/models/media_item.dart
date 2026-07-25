class MediaItem {
  final int id;
  final int tmdbId;
  final String mediaType; // "movie" or "tv"
  final String title;
  final String overview;
  final String posterPath;
  final String backdropPath;
  final String releaseDate;
  final double voteAverage;
  final String localPosterPath;
  final String localBackdropPath;

  MediaItem({
    required this.id,
    required this.tmdbId,
    required this.mediaType,
    required this.title,
    required this.overview,
    required this.posterPath,
    required this.backdropPath,
    required this.releaseDate,
    required this.voteAverage,
    this.localPosterPath = '',
    this.localBackdropPath = '',
  });

  factory MediaItem.fromSearchJson(Map<String, dynamic> json) {
    return MediaItem(
      id: json['id'] ?? 0,
      tmdbId: json['id'] ?? 0,
      mediaType: json['media_type'] ?? 'movie',
      title: json['title'] ?? json['name'] ?? '',
      overview: json['overview'] ?? '',
      posterPath: json['poster_path'] ?? '',
      backdropPath: json['backdrop_path'] ?? '',
      releaseDate: json['release_date'] ?? json['first_air_date'] ?? '',
      voteAverage: (json['vote_average'] ?? 0.0).toDouble(),
    );
  }

  factory MediaItem.fromDbJson(Map<String, dynamic> json) {
    return MediaItem(
      id: json['id'] ?? 0,
      tmdbId: json['tmdb_id'] ?? 0,
      mediaType: json['media_type'] ?? 'movie',
      title: json['title'] ?? '',
      overview: json['overview'] ?? '',
      posterPath: json['poster_path'] ?? '',
      backdropPath: json['backdrop_path'] ?? '',
      releaseDate: json['release_date'] ?? '',
      voteAverage: (json['vote_average'] ?? 0.0).toDouble(),
      localPosterPath: json['local_poster_path'] ?? '',
      localBackdropPath: json['local_backdrop_path'] ?? '',
    );
  }
}

class WatchlistItem {
  final int id;
  final int userId;
  final int movieId;
  final String status;
  final double rating;
  final bool favorite;
  final String notes;
  final MediaItem movie;

  WatchlistItem({
    required this.id,
    required this.userId,
    required this.movieId,
    required this.status,
    required this.rating,
    required this.favorite,
    required this.notes,
    required this.movie,
  });

  factory WatchlistItem.fromJson(Map<String, dynamic> json) {
    return WatchlistItem(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      movieId: json['movie_id'] ?? 0,
      status: json['status'] ?? 'plan_to_watch',
      rating: (json['rating'] ?? 0.0).toDouble(),
      favorite: json['favorite'] ?? false,
      notes: json['notes'] ?? '',
      movie: MediaItem.fromDbJson(json['movie'] ?? {}),
    );
  }
}
