import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/media_item.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class MediaDetailScreen extends StatefulWidget {
  final MediaItem item;

  const MediaDetailScreen({super.key, required this.item});

  @override
  State<MediaDetailScreen> createState() => _MediaDetailScreenState();
}

class _MediaDetailScreenState extends State<MediaDetailScreen> {
  bool _isLoadingDetail = true;
  Map<String, dynamic>? _detailData;

  int _selectedSeason = 1;
  bool _isLoadingEpisodes = false;
  List<dynamic> _episodes = [];

  // Watchlist state for this item
  bool _isInWatchlist = false;
  WatchlistItem? _watchlistItem;
  bool _isSavingProgress = false;

  @override
  void initState() {
    super.initState();
    _loadDetail();
    _checkWatchlistStatus();
  }

  Future<void> _checkWatchlistStatus() async {
    final list = await ApiService.getWatchlist(mediaType: widget.item.mediaType);
    final found = list.where((i) => i.movie.tmdbId == widget.item.tmdbId || i.movieId == widget.item.id).toList();
    if (found.isNotEmpty && mounted) {
      setState(() {
        _isInWatchlist = true;
        _watchlistItem = found.first;
      });
    }
  }

  Future<void> _loadDetail() async {
    final detail = await ApiService.fetchMediaDetail(widget.item.tmdbId, widget.item.mediaType);
    if (mounted) {
      setState(() {
        _detailData = detail;
        _isLoadingDetail = false;
      });

      if (widget.item.mediaType == 'tv') {
        _loadSeasonEpisodes(1);
      }
    }
  }

  Future<void> _loadSeasonEpisodes(int season) async {
    setState(() {
      _selectedSeason = season;
      _isLoadingEpisodes = true;
    });

    final eps = await ApiService.fetchTVSeasonEpisodes(widget.item.tmdbId, season);
    if (mounted) {
      setState(() {
        _episodes = eps;
        _isLoadingEpisodes = false;
      });
    }
  }

  bool _isEpisodeWatched(int episodeNumber) {
    if (_watchlistItem == null) return false;
    final total = widget.item.totalEpisodes > 0 ? widget.item.totalEpisodes : (_detailData?['total_episodes'] ?? 0);
    if (total > 0 && _watchlistItem!.episodesWatched >= total) return true;
    // Calculate cumulative episode index
    final cumulative = ((_selectedSeason - 1) * 10) + episodeNumber;
    return cumulative <= _watchlistItem!.episodesWatched;
  }

  Future<void> _toggleEpisode(int episodeNumber) async {
    if (_isSavingProgress) return;
    setState(() => _isSavingProgress = true);

    if (!_isInWatchlist) {
      // Auto add to watchlist
      await ApiService.addToWatchlist(
        item: widget.item,
        status: 'watching',
        rating: 0,
        favorite: false,
        notes: '',
        seasonWatched: _selectedSeason,
        episodesWatched: episodeNumber,
      );
      await _checkWatchlistStatus();
    } else if (_watchlistItem != null) {
      final isWatched = _isEpisodeWatched(episodeNumber);
      final newWatched = isWatched ? episodeNumber - 1 : episodeNumber;
      await ApiService.updateWatchlist(
        id: _watchlistItem!.id,
        status: _watchlistItem!.status,
        rating: _watchlistItem!.rating,
        favorite: _watchlistItem!.favorite,
        notes: _watchlistItem!.notes,
        seasonWatched: _selectedSeason,
        episodesWatched: newWatched,
      );
      await _checkWatchlistStatus();
    }

    if (mounted) {
      setState(() => _isSavingProgress = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final backdropUrl = ApiService.getFullBackdropUrl(widget.item);
    final posterUrl = ApiService.getFullImageUrl(widget.item);
    final totalSeasons = _detailData?['total_seasons'] ?? widget.item.totalSeasons;

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          // Cinematic Sliver App Bar
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: AppColors.bgPrimary,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0x99000000),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (backdropUrl.isNotEmpty)
                    Image.network(
                      backdropUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(color: AppColors.bgCard),
                    )
                  else
                    Container(color: AppColors.bgCard),
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x4D000000),
                          Color(0x99000000),
                          AppColors.bgPrimary,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Main Detail Body
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Poster + Title Header Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: SizedBox(
                          width: 95,
                          height: 140,
                          child: posterUrl.isNotEmpty
                              ? Image.network(posterUrl, fit: BoxFit.cover)
                              : Container(color: AppColors.bgCard),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.item.title,
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Badges Row
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.accentRed,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    widget.item.mediaType == 'tv' ? 'TV SERIES' : 'MOVIE',
                                    style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (widget.item.voteAverage > 0) ...[
                                  const Icon(Icons.star_rounded, color: AppColors.starGold, size: 16),
                                  const SizedBox(width: 2),
                                  Text(
                                    '${widget.item.voteAverage.toStringAsFixed(1)} / 10',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Release: ${widget.item.releaseDate}',
                              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                            ),
                            if (_detailData?['media_status'] != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Status: ${_detailData!['media_status']}',
                                style: const TextStyle(color: AppColors.successGreen, fontSize: 11, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Metadata Box
                  if (_isLoadingDetail)
                    const Center(child: CircularProgressIndicator(color: AppColors.accentRed))
                  else if (_detailData != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.bgSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if ((_detailData!['director'] ?? '').isNotEmpty) ...[
                            const Text('DIRECTOR / CREATOR', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w800, fontSize: 10)),
                            const SizedBox(height: 2),
                            Text(_detailData!['director'], style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 10),
                          ],
                          if ((_detailData!['cast'] ?? '').isNotEmpty) ...[
                            const Text('MAIN CAST', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w800, fontSize: 10)),
                            const SizedBox(height: 2),
                            Text(_detailData!['cast'], style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          ],
                        ],
                      ),
                    ),
                  const SizedBox(height: 20),

                  // Synopsis
                  Text(
                    'SYNOPSIS',
                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.item.overview.isNotEmpty ? widget.item.overview : 'No synopsis available.',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5),
                  ),

                  // TV Seasons & Episodes
                  if (widget.item.mediaType == 'tv') ...[
                    const SizedBox(height: 28),
                    Text(
                      'SEASONS & EPISODES',
                      style: GoogleFonts.outfit(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 10),

                    // Season Chips
                    if (totalSeasons > 0)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: List.generate(totalSeasons, (index) {
                            final seasonNum = index + 1;
                            final isSelected = _selectedSeason == seasonNum;
                            return GestureDetector(
                              onTap: () => _loadSeasonEpisodes(seasonNum),
                              child: Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.accentRed : AppColors.bgSurface,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: isSelected ? AppColors.accentRed : AppColors.borderSubtle),
                                ),
                                child: Text(
                                  'Season $seasonNum',
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : AppColors.textSecondary,
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    const SizedBox(height: 14),

                    // Episode List
                    if (_isLoadingEpisodes)
                      const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: AppColors.accentRed)))
                    else if (_episodes.isEmpty)
                      const Text('No episodes listed for this season.', style: TextStyle(color: AppColors.textMuted, fontSize: 12))
                    else
                      ..._episodes.map((eps) {
                        final epsNum = eps['episode_number'] ?? 1;
                        final epsName = eps['name'] ?? 'Episode $epsNum';
                        final stillPath = eps['still_path'] ?? '';
                        final airDate = eps['air_date'] ?? '';
                        final overview = eps['overview'] ?? '';
                        final isWatched = _isEpisodeWatched(epsNum);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isWatched ? const Color(0x1422C55E) : AppColors.bgSurface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isWatched ? const Color(0x3322C55E) : AppColors.borderSubtle),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Episode Still
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  width: 90,
                                  height: 55,
                                  color: AppColors.bgCard,
                                  child: stillPath.isNotEmpty
                                      ? Image.network(
                                          'https://image.tmdb.org/t/p/w300$stillPath',
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.tv, color: AppColors.textMuted)),
                                        )
                                      : const Center(child: Icon(Icons.tv, color: AppColors.textMuted)),
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'E$epsNum • $epsName',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Colors.white),
                                    ),
                                    if (airDate.isNotEmpty)
                                      Text(airDate, style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
                                    if (overview.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        overview,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, height: 1.3),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Watched Checkmark Toggle
                              IconButton(
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                                icon: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: isWatched ? AppColors.accentRed : AppColors.bgCard,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: isWatched ? AppColors.accentRed : AppColors.borderLight),
                                  ),
                                  child: Icon(
                                    Icons.check_rounded,
                                    color: isWatched ? Colors.white : AppColors.textMuted,
                                    size: 18,
                                  ),
                                ),
                                onPressed: () => _toggleEpisode(epsNum),
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
