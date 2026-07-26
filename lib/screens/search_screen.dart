import 'package:flutter/material.dart';
import '../models/media_item.dart';
import '../services/api_service.dart';
import 'media_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController(text: 'Breaking Bad');
  String _selectedType = 'all';
  bool _isLoading = false;
  List<MediaItem> _results = [];

  @override
  void initState() {
    super.initState();
    _performSearch();
  }

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() => _isLoading = true);
    final items = await ApiService.searchMedia(query, type: _selectedType);
    setState(() {
      _results = items;
      _isLoading = false;
    });
  }

  void _openDetailScreen(MediaItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MediaDetailScreen(item: item)),
    );
  }

  void _openSaveModal(MediaItem item) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SaveModalSheet(item: item),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('Cari Film & TV Shows', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search & Filter Box
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF1E293B),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Cari judul film atau series...',
                    hintStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    prefixIcon: const Icon(Icons.search, color: Colors.amber),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.send, color: Colors.amber),
                      onPressed: _performSearch,
                    ),
                  ),
                  onSubmitted: (_) => _performSearch(),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _filterChip('Semua', 'all'),
                    const SizedBox(width: 8),
                    _filterChip('Movies', 'movie'),
                    const SizedBox(width: 8),
                    _filterChip('TV Shows', 'tv'),
                  ],
                ),
              ],
            ),
          ),

          // Search Results
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.amber))
                : _results.isEmpty
                    ? const Center(
                        child: Text('Tidak ada hasil ditemukan', style: TextStyle(color: Colors.white54)),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.62,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: _results.length,
                        itemBuilder: (context, index) {
                          final item = _results[index];
                          final imageUrl = ApiService.getFullImageUrl(item);

                          return GestureDetector(
                            onTap: () => _openDetailScreen(item),
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E293B),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white.withOpacity(0.08)),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Stack(
                                      children: [
                                        imageUrl.isNotEmpty
                                            ? Image.network(
                                                imageUrl,
                                                width: double.infinity,
                                                height: double.infinity,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) => const Center(
                                                  child: Icon(Icons.movie, size: 48, color: Colors.white24),
                                                ),
                                              )
                                            : const Center(
                                                child: Icon(Icons.movie, size: 48, color: Colors.white24),
                                              ),
                                        Positioned(
                                          top: 8,
                                          left: 8,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: item.mediaType == 'tv' ? Colors.purple : Colors.blue,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              item.mediaType == 'tv' ? 'TV Show' : 'Movie',
                                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ),
                                        if (item.voteAverage > 0)
                                          Positioned(
                                            top: 8,
                                            right: 8,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.black87,
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                '★ ${item.voteAverage.toStringAsFixed(1)}',
                                                style: const TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              item.releaseDate.length >= 4 ? item.releaseDate.substring(0, 4) : '',
                                              style: const TextStyle(color: Colors.white54, fontSize: 11),
                                            ),
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.amber,
                                                foregroundColor: Colors.black,
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                minimumSize: Size.zero,
                                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                              ),
                                              onPressed: () => _openSaveModal(item),
                                              child: const Text('+ Simpan', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final isSelected = _selectedType == value;
    return ChoiceChip(
      label: Text(label, style: TextStyle(color: isSelected ? Colors.black : Colors.white, fontSize: 12)),
      selected: isSelected,
      selectedColor: Colors.amber,
      backgroundColor: const Color(0xFF0F172A),
      onSelected: (selected) {
        if (selected) {
          setState(() => _selectedType = value);
          _performSearch();
        }
      },
    );
  }
}

class _SaveModalSheet extends StatefulWidget {
  final MediaItem item;

  const _SaveModalSheet({required this.item});

  @override
  State<_SaveModalSheet> createState() => _SaveModalSheetState();
}

class _SaveModalSheetState extends State<_SaveModalSheet> {
  String _status = 'watching';
  double _rating = 4.0;
  bool _favorite = false;
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _seasonController = TextEditingController(text: '1');
  final TextEditingController _episodesController = TextEditingController(text: '0');
  final TextEditingController _totalEpisodesController = TextEditingController(text: '0');

  bool _isFetchingDetail = true;
  bool _isSaving = false;
  Map<String, dynamic>? _detailData;

  @override
  void initState() {
    super.initState();
    _status = widget.item.mediaType == 'tv' ? 'watching' : 'completed';
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    final detail = await ApiService.fetchMediaDetail(widget.item.tmdbId, widget.item.mediaType);
    if (mounted) {
      setState(() {
        _detailData = detail;
        _isFetchingDetail = false;
        if (detail != null && detail['total_episodes'] != null) {
          _totalEpisodesController.text = detail['total_episodes'].toString();
        }
      });
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);

    final success = await ApiService.addToWatchlist(
      item: widget.item,
      status: _status,
      rating: _rating,
      favorite: _favorite,
      notes: _notesController.text.trim(),
      seasonWatched: int.tryParse(_seasonController.text) ?? 1,
      episodesWatched: int.tryParse(_episodesController.text) ?? 0,
      totalEpisodes: int.tryParse(_totalEpisodesController.text) ?? 0,
      director: _detailData?['director'] ?? '',
      cast: _detailData?['cast'] ?? '',
      nextAirDate: _detailData?['next_air_date'] ?? '',
      nextEpisodeName: _detailData?['next_episode_name'] ?? '',
    );

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Berhasil disimpan ke watchlist'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal menyimpan ke watchlist. Pastikan kamu sudah login.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.item.title,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${widget.item.mediaType == 'tv' ? 'TV Show' : 'Movie'} • ${widget.item.releaseDate.length >= 4 ? widget.item.releaseDate.substring(0, 4) : ''}',
              style: const TextStyle(color: Colors.amber, fontSize: 12),
            ),
            const SizedBox(height: 12),

            // Detail Box (Director, Cast, Seasons)
            if (_isFetchingDetail)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text('Memuat detail sutradara & episode...', style: TextStyle(color: Colors.white54, fontSize: 12)),
              )
            else if (_detailData != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if ((_detailData!['director'] ?? '').isNotEmpty)
                      Text('Sutradara/Kreator: ${_detailData!['director']}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    if ((_detailData!['cast'] ?? '').isNotEmpty)
                      Text('Pemeran: ${_detailData!['cast']}', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                    if (widget.item.mediaType == 'tv' && _detailData!['next_air_date'] != null && (_detailData!['next_air_date'] as String).isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6.0),
                        child: Text(
                          '📅 Episode berikutnya: ${_detailData!['next_air_date']}',
                          style: const TextStyle(color: Colors.lightBlueAccent, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
              ),

            // Status Dropdown
            const Text('Status Tontonan', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(10),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _status,
                  dropdownColor: const Color(0xFF0F172A),
                  isExpanded: true,
                  style: const TextStyle(color: Colors.white),
                  items: const [
                    DropdownMenuItem(value: 'watching', child: Text('Sedang Nonton (Watching)')),
                    DropdownMenuItem(value: 'completed', child: Text('Selesai (Completed)')),
                    DropdownMenuItem(value: 'plan_to_watch', child: Text('Rencana Nonton (Plan to Watch)')),
                    DropdownMenuItem(value: 'on_hold', child: Text('Ditunda (On Hold)')),
                    DropdownMenuItem(value: 'dropped', child: Text('Dihentikan (Dropped)')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _status = val);
                  },
                ),
              ),
            ),
            const SizedBox(height: 14),

            // 5-Star Rating Selector
            const Text('Rating Kamu (1 - 5 Bintang)', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Row(
              children: [
                for (int star = 1; star <= 5; star++)
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      star <= _rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 28,
                    ),
                    onPressed: () => setState(() => _rating = star.toDouble()),
                  ),
                const SizedBox(width: 12),
                Text(
                  '${_rating.toStringAsFixed(1)} / 5.0',
                  style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // TV Episode Progress (If TV Show)
            if (widget.item.mediaType == 'tv') ...[
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Season', style: TextStyle(color: Colors.white70, fontSize: 11)),
                        const SizedBox(height: 4),
                        TextField(
                          controller: _seasonController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFF0F172A),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Eps Ditonton', style: TextStyle(color: Colors.white70, fontSize: 11)),
                        const SizedBox(height: 4),
                        TextField(
                          controller: _episodesController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFF0F172A),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Total Eps', style: TextStyle(color: Colors.white70, fontSize: 11)),
                        const SizedBox(height: 4),
                        TextField(
                          controller: _totalEpisodesController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFF0F172A),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
            ],

            // Favorite checkbox
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Tandai sebagai Favorit', style: TextStyle(color: Colors.white, fontSize: 13)),
              value: _favorite,
              activeColor: Colors.amber,
              onChanged: (val) => setState(() => _favorite = val ?? false),
            ),

            // Save Button
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                    : const Text('Simpan ke Watchlist', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
