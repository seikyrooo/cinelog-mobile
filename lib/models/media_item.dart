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
  final String director;
  final String cast;
  final int totalSeasons;
  final int totalEpisodes;
  final String nextAirDate;
  final String nextEpisodeName;
  final String mediaStatus;

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
    this.director = '',
    this.cast = '',
    this.totalSeasons = 0,
    this.totalEpisodes = 0,
    this.nextAirDate = '',
    this.nextEpisodeName = '',
    this.mediaStatus = '',
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
      director: json['director'] ?? '',
      cast: json['cast'] ?? '',
      totalSeasons: json['total_seasons'] ?? 0,
      totalEpisodes: json['total_episodes'] ?? 0,
      nextAirDate: json['next_air_date'] ?? '',
      nextEpisodeName: json['next_episode_name'] ?? '',
      mediaStatus: json['media_status'] ?? '',
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
      director: json['director'] ?? '',
      cast: json['cast'] ?? '',
      totalSeasons: json['total_seasons'] ?? 0,
      totalEpisodes: json['total_episodes'] ?? 0,
      nextAirDate: json['next_air_date'] ?? '',
      nextEpisodeName: json['next_episode_name'] ?? '',
      mediaStatus: json['media_status'] ?? '',
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
  final int seasonWatched;
  final int episodesWatched;
  final int totalEpisodes;
  final MediaItem movie;

  WatchlistItem({
    required this.id,
    required this.userId,
    required this.movieId,
    required this.status,
    required this.rating,
    required this.favorite,
    required this.notes,
    required this.seasonWatched,
    required this.episodesWatched,
    required this.totalEpisodes,
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
      seasonWatched: json['season_watched'] ?? 1,
      episodesWatched: json['episodes_watched'] ?? 0,
      totalEpisodes: json['total_episodes'] ?? 0,
      movie: MediaItem.fromDbJson(json['movie'] ?? {}),
    );
  }
}
