import 'package:flutter/material.dart';
import '../models/media_item.dart';
import '../services/api_service.dart';

class WatchlistScreen extends StatefulWidget {
  const WatchlistScreen({super.key});

  @override
  State<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen> {
  bool _isLoading = true;
  List<WatchlistItem> _list = [];
  String _selectedStatus = 'all';
  bool _favoriteOnly = false;

  @override
  void initState() {
    super.initState();
    _fetchWatchlist();
  }

  Future<void> _fetchWatchlist() async {
    setState(() => _isLoading = true);
    final items = await ApiService.getWatchlist(status: _selectedStatus, favoriteOnly: _favoriteOnly);
    setState(() {
      _list = items;
      _isLoading = false;
    });
  }

  String _getPosterUrl(MediaItem movie) {
    if (movie.localPosterPath.isNotEmpty) {
      return '${ApiService.baseUrl}${movie.localPosterPath}';
    }
    if (movie.posterPath.isNotEmpty) {
      return 'https://image.tmdb.org/t/p/w500${movie.posterPath}';
    }
    return 'https://via.placeholder.com/300x450?text=No+Poster';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('⭐ List Tontonan Saya'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchWatchlist,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Status Chips Filter
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildStatusChip('Semua', 'all'),
                  const SizedBox(width: 8),
                  _buildStatusChip('▶️ Watching', 'watching'),
                  const SizedBox(width: 8),
                  _buildStatusChip('✅ Completed', 'completed'),
                  const SizedBox(width: 8),
                  _buildStatusChip('📌 Plan to Watch', 'plan_to_watch'),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('⭐ Favorit'),
                    selected: _favoriteOnly,
                    selectedColor: Colors.amber,
                    backgroundColor: const Color(0xFF1E293B),
                    labelStyle: TextStyle(color: _favoriteOnly ? Colors.black : Colors.white60, fontWeight: FontWeight.bold),
                    onSelected: (val) {
                      setState(() => _favoriteOnly = val);
                      _fetchWatchlist();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.amber))
                  : _list.isEmpty
                      ? const Center(
                          child: Text(
                            'Belum ada film/series tersimpan.\nSilakan login atau cari film untuk disimpan.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white54),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _list.length,
                          itemBuilder: (context, index) {
                            final item = _list[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E293B),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white10),
                              ),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.network(
                                      _getPosterUrl(item.movie),
                                      width: 70,
                                      height: 100,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        width: 70,
                                        height: 100,
                                        color: Colors.white10,
                                        child: const Icon(Icons.movie, color: Colors.white30),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              item.movie.mediaType == 'tv' ? '📺 TV Series' : '🎬 Movie',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: item.movie.mediaType == 'tv' ? Colors.cyan : Colors.purpleAccent,
                                              ),
                                            ),
                                            const Spacer(),
                                            if (item.favorite) const Text('⭐ Favorit', style: TextStyle(fontSize: 11, color: Colors.amber)),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          item.movie.title,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Status: ${item.status.replaceAll('_', ' ')}',
                                          style: const TextStyle(fontSize: 12, color: Colors.amber),
                                        ),
                                        if (item.rating > 0)
                                          Text(
                                            'Rating Pribadi: ${item.rating} / 10',
                                            style: const TextStyle(fontSize: 12, color: Colors.white70),
                                          ),
                                        if (item.notes.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 4),
                                            child: Text(
                                              '"${item.notes}"',
                                              style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.white54),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                    onPressed: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text('Hapus Item?'),
                                          content: Text('Hapus ${item.movie.title} dari watchlist?'),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
                                            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hapus', style: TextStyle(color: Colors.red))),
                                          ],
                                        ),
                                      );

                                      if (confirm == true) {
                                        await ApiService.deleteWatchlist(item.id);
                                        _fetchWatchlist();
                                      }
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label, String value) {
    final isSelected = _selectedStatus == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: Colors.purple.shade600,
      backgroundColor: const Color(0xFF1E293B),
      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.white60, fontWeight: FontWeight.bold),
      onSelected: (_) {
        setState(() => _selectedStatus = value);
        _fetchWatchlist();
      },
    );
  }
}
