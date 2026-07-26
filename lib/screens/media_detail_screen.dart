import 'package:flutter/material.dart';
import '../models/media_item.dart';
import '../services/api_service.dart';

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

  @override
  void initState() {
    super.initState();
    _loadDetail();
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

  @override
  Widget build(BuildContext context) {
    final backdropUrl = widget.item.backdropPath.isNotEmpty
        ? 'https://image.tmdb.org/t/p/w780${widget.item.backdropPath}'
        : ApiService.getFullImageUrl(widget.item);

    final posterUrl = ApiService.getFullImageUrl(widget.item);
    final totalSeasons = _detailData?['total_seasons'] ?? widget.item.totalSeasons;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: CustomScrollView(
        slivers: [
          // Banner SliverAppBar
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            backgroundColor: const Color(0xFF1E293B),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.item.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  shadows: [Shadow(color: Colors.black87, blurRadius: 10)],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  backdropUrl.isNotEmpty
                      ? Image.network(backdropUrl, fit: BoxFit.cover)
                      : Container(color: const Color(0xFF1E293B)),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          const Color(0xFF0F172A).withOpacity(0.9),
                          const Color(0xFF0F172A),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Details Body
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Poster & Main Info Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: posterUrl.isNotEmpty
                            ? Image.network(posterUrl, width: 100, height: 150, fit: BoxFit.cover)
                            : Container(width: 100, height: 150, color: const Color(0xFF1E293B), child: const Icon(Icons.movie, size: 48, color: Colors.white24)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: widget.item.mediaType == 'tv' ? Colors.purple : Colors.blue,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                widget.item.mediaType == 'tv' ? 'TV Show' : 'Movie',
                                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Rilis: ${widget.item.releaseDate}',
                              style: const TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.star, color: Colors.amber, size: 18),
                                const SizedBox(width: 4),
                                Text(
                                  '${(widget.item.voteAverage / 2).toStringAsFixed(1)} / 5.0',
                                  style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ],
                            ),
                            if (_detailData?['media_status'] != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Status: ${_detailData!['media_status']}',
                                style: const TextStyle(color: Colors.lightGreenAccent, fontSize: 12),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Director & Cast Box
                  if (_isLoadingDetail)
                    const Center(child: CircularProgressIndicator(color: Colors.amber))
                  else if (_detailData != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.08)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if ((_detailData!['director'] ?? '').isNotEmpty) ...[
                            Text(
                              'Sutradara / Pembuat:',
                              style: TextStyle(color: Colors.amber.shade300, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                            Text(
                              _detailData!['director'],
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                            ),
                            const SizedBox(height: 8),
                          ],
                          if ((_detailData!['cast'] ?? '').isNotEmpty) ...[
                            Text(
                              'Pemeran Utama:',
                              style: TextStyle(color: Colors.amber.shade300, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                            Text(
                              _detailData!['cast'],
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ],
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Overview / Synopsis
                  const Text('Sinopsis', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(
                    widget.item.overview.isNotEmpty ? widget.item.overview : 'Belum ada ringkasan sinopsis.',
                    style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                  ),

                  // TV Series Season & Episodes Section
                  if (widget.item.mediaType == 'tv') ...[
                    const SizedBox(height: 24),
                    const Text('Daftar Season & Episode', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),

                    // Season Chips Selector
                    if (totalSeasons > 0)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: List.generate(totalSeasons, (index) {
                            final seasonNum = index + 1;
                            final isSelected = _selectedSeason == seasonNum;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: ChoiceChip(
                                label: Text('Season $seasonNum', style: TextStyle(color: isSelected ? Colors.black : Colors.white, fontSize: 12)),
                                selected: isSelected,
                                selectedColor: Colors.amber,
                                backgroundColor: const Color(0xFF1E293B),
                                onSelected: (selected) {
                                  if (selected) _loadSeasonEpisodes(seasonNum);
                                },
                              ),
                            );
                          }),
                        ),
                      ),

                    const SizedBox(height: 12),

                    // Episode List
                    if (_isLoadingEpisodes)
                      const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: Colors.amber)))
                    else if (_episodes.isEmpty)
                      const Text('Belum ada data episode untuk season ini.', style: TextStyle(color: Colors.white54, fontSize: 13))
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _episodes.length,
                        itemBuilder: (context, index) {
                          final eps = _episodes[index];
                          final stillPath = eps['still_path'] ?? '';
                          final stillUrl = stillPath.isNotEmpty ? 'https://image.tmdb.org/t/p/w300$stillPath' : '';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white.withOpacity(0.06)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: stillUrl.isNotEmpty
                                      ? Image.network(stillUrl, width: 85, height: 55, fit: BoxFit.cover)
                                      : Container(width: 85, height: 55, color: const Color(0xFF0F172A), child: const Icon(Icons.tv, color: Colors.white24)),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Eps ${eps['episode_number']}: ${eps['name'] ?? ''}',
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                      if (eps['air_date'] != null)
                                        Text('Tayang: ${eps['air_date']}', style: const TextStyle(color: Colors.white54, fontSize: 10)),
                                      const SizedBox(height: 4),
                                      Text(
                                        eps['overview'] ?? '',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(color: Colors.white70, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
