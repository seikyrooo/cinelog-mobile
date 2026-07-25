import 'package:flutter/material.dart';
import '../models/media_item.dart';
import '../services/api_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController(text: 'Batman');
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
    final results = await ApiService.searchMedia(query, type: _selectedType);
    setState(() {
      _results = results;
      _isLoading = false;
    });
  }

  void _showSaveBottomSheet(MediaItem item) {
    String status = 'plan_to_watch';
    double rating = item.voteAverage > 0 ? (item.voteAverage.clamp(0, 10)) : 8.0;
    bool favorite = false;
    final notesController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Simpan ke List',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber.shade400,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.title,
                    style: const TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
                  const Text('Status Tontonan', style: TextStyle(color: Colors.white60)),
                  DropdownButton<String>(
                    value: status,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF1E293B),
                    style: const TextStyle(color: Colors.white),
                    items: const [
                      DropdownMenuItem(value: 'plan_to_watch', child: Text('📌 Plan to Watch')),
                      DropdownMenuItem(value: 'watching', child: Text('▶️ Watching')),
                      DropdownMenuItem(value: 'completed', child: Text('✅ Completed')),
                      DropdownMenuItem(value: 'on_hold', child: Text('⏸️ On Hold')),
                      DropdownMenuItem(value: 'dropped', child: Text('🚫 Dropped')),
                    ],
                    onChanged: (val) {
                      if (val != null) setModalState(() => status = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  Text('Rating (0.0 - 10.0): ${rating.toStringAsFixed(1)}', style: const TextStyle(color: Colors.white60)),
                  Slider(
                    value: rating,
                    min: 0,
                    max: 10,
                    divisions: 20,
                    activeColor: Colors.amber,
                    onChanged: (val) => setModalState(() => rating = val),
                  ),
                  CheckboxListTile(
                    title: const Text('⭐ Tandai Favorit', style: TextStyle(color: Colors.white)),
                    value: favorite,
                    activeColor: Colors.amber,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) => setModalState(() => favorite = val ?? false),
                  ),
                  TextField(
                    controller: notesController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Catatan / Impression',
                      labelStyle: TextStyle(color: Colors.white60),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber.shade600,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.all(14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        final success = await ApiService.addToWatchlist(
                          item: item,
                          status: status,
                          rating: rating,
                          favorite: favorite,
                          notes: notesController.text,
                        );
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                success
                                    ? '✅ Berhasil disimpan ke VPS DB!'
                                    : '⚠️ Gagal menyimpan. Silakan login terlebih dahulu.',
                              ),
                            ),
                          );
                        }
                      },
                      child: const Text('Simpan ke Database', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🔍 Cari Film & Series'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search Input Row
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onSubmitted: (_) => _performSearch(),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Cari judul...',
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: const Color(0xFF1E293B),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _performSearch,
                  icon: const Icon(Icons.search),
                  style: IconButton.styleFrom(backgroundColor: Colors.amber),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Filter Types
            Row(
              children: [
                _buildFilterChip('Semua', 'all'),
                const SizedBox(width: 8),
                _buildFilterChip('Movie', 'movie'),
                const SizedBox(width: 8),
                _buildFilterChip('TV Series', 'tv'),
              ],
            ),
            const SizedBox(height: 16),
            // Results Grid
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.amber))
                  : _results.isEmpty
                      ? const Center(
                          child: Text('Tidak ada hasil pencarian.', style: TextStyle(color: Colors.white54)),
                        )
                      : GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.6,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: _results.length,
                          itemBuilder: (context, index) {
                            final item = _results[index];
                            final imageUrl = item.posterPath.isNotEmpty
                                ? 'https://image.tmdb.org/t/p/w500${item.posterPath}'
                                : 'https://via.placeholder.com/300x450?text=No+Poster';

                            return Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E293B),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white10),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        Image.network(
                                          imageUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.movie, size: 40, color: Colors.white30)),
                                        ),
                                        Positioned(
                                          top: 8,
                                          left: 8,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: item.mediaType == 'tv' ? Colors.cyan.withOpacity(0.8) : Colors.purple.withOpacity(0.8),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              item.mediaType == 'tv' ? 'TV' : 'Movie',
                                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '⭐ ${item.voteAverage.toStringAsFixed(1)}',
                                          style: const TextStyle(fontSize: 12, color: Colors.amber),
                                        ),
                                        const SizedBox(height: 8),
                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.amber,
                                              foregroundColor: Colors.black,
                                              padding: const EdgeInsets.symmetric(vertical: 6),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                            ),
                                            onPressed: () => _showSaveBottomSheet(item),
                                            child: const Text('➕ Simpan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                          ),
                                        ),
                                      ],
                                    ),
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

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedType == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: Colors.purple.shade600,
      backgroundColor: const Color(0xFF1E293B),
      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.white60, fontWeight: FontWeight.bold),
      onSelected: (_) {
        setState(() => _selectedType = value);
        _performSearch();
      },
    );
  }
}
