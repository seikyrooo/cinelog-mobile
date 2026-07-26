import 'package:flutter/material.dart';
import '../models/media_item.dart';
import '../services/api_service.dart';

class WatchlistScreen extends StatefulWidget {
  const WatchlistScreen({super.key});

  @override
  State<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<WatchlistItem> _items = [];
  String _activeStatus = 'all';
  bool _favoriteOnly = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        _fetchWatchlist();
      }
    });
    _fetchWatchlist();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchWatchlist() async {
    setState(() => _isLoading = true);
    final mediaType = _tabController.index == 0 ? 'tv' : 'movie';
    final list = await ApiService.getWatchlist(
      status: _activeStatus,
      favoriteOnly: _favoriteOnly,
      mediaType: mediaType,
    );
    if (mounted) {
      setState(() {
        _items = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _incrementEpisode(WatchlistItem item) async {
    final success = await ApiService.incrementEpisodeProgress(item.id);
    if (success) {
      _fetchWatchlist();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('+1 Episode ditonton: ${item.movie.title}'),
            duration: const Duration(seconds: 1),
            backgroundColor: Colors.purple,
          ),
        );
      }
    }
  }

  void _openEditModal(WatchlistItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditModalSheet(item: item, onSave: _fetchWatchlist),
    );
  }

  Future<void> _deleteItem(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Hapus Item', style: TextStyle(color: Colors.white)),
        content: const Text('Hapus item ini dari watchlist kamu?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal', style: TextStyle(color: Colors.white54))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hapus', style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );

    if (confirmed == true) {
      await ApiService.deleteWatchlist(id);
      _fetchWatchlist();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('Watchlist Saya', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.amber,
          labelColor: Colors.amber,
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(icon: Icon(Icons.tv), text: 'TV Shows (Series)'),
            Tab(icon: Icon(Icons.movie), text: 'Movies'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Filter Chips Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: const Color(0xFF1E293B),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterChip('Semua', 'all'),
                  const SizedBox(width: 8),
                  _filterChip('Watching', 'watching'),
                  const SizedBox(width: 8),
                  _filterChip('Completed', 'completed'),
                  const SizedBox(width: 8),
                  _filterChip('Plan to Watch', 'plan_to_watch'),
                  const SizedBox(width: 12),
                  FilterChip(
                    label: const Text('★ Favorit', style: TextStyle(fontSize: 12)),
                    selected: _favoriteOnly,
                    selectedColor: Colors.amber,
                    checkmarkColor: Colors.black,
                    backgroundColor: const Color(0xFF0F172A),
                    labelStyle: TextStyle(color: _favoriteOnly ? Colors.black : Colors.white),
                    onSelected: (val) {
                      setState(() => _favoriteOnly = val);
                      _fetchWatchlist();
                    },
                  ),
                ],
              ),
            ),
          ),

          // Main Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.amber))
                : _items.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.bookmark_border, size: 64, color: Colors.white24),
                            const SizedBox(height: 12),
                            Text(
                              'Belum ada ${_tabController.index == 0 ? 'TV Show' : 'Film'} di kategori ini.',
                              style: const TextStyle(color: Colors.white54),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchWatchlist,
                        color: Colors.amber,
                        child: _tabController.index == 0 ? _buildTvShowsList() : _buildMoviesGrid(),
                      ),
          ),
        ],
      ),
    );
  }

  // TV Time Style List View (With Swipe to Increment Episode)
  Widget _buildTvShowsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final item = _items[index];
        final imageUrl = ApiService.getFullImageUrl(item.movie);
        final totalEps = item.movie.totalEpisodes > 0 ? item.movie.totalEpisodes : item.totalEpisodes;
        final progressRatio = totalEps > 0 ? (item.episodesWatched / totalEps).clamp(0.0, 1.0) : 0.0;

        return Dismissible(
          key: Key('show_${item.id}'),
          direction: DismissDirection.startToEnd,
          background: Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 20),
            color: Colors.purple.shade700,
            child: const Row(
              children: [
                Icon(Icons.add_circle, color: Colors.white, size: 28),
                SizedBox(width: 8),
                Text('+1 Episode Nonton!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          confirmDismiss: (_) async {
            await _incrementEpisode(item);
            return false; // Don't remove item from list UI on swipe
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Poster
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: imageUrl.isNotEmpty
                      ? Image.network(imageUrl, width: 75, height: 110, fit: BoxFit.cover)
                      : Container(width: 75, height: 110, color: const Color(0xFF0F172A), child: const Icon(Icons.tv, color: Colors.white24)),
                ),
                const SizedBox(width: 12),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.between,
                        children: [
                          Expanded(
                            child: Text(
                              item.movie.title,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: item.status == 'watching'
                                  ? Colors.purple
                                  : item.status == 'completed'
                                      ? Colors.green
                                      : Colors.blueGrey,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              item.status.toUpperCase(),
                              style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Episode Progress Box
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.between,
                              children: [
                                Text(
                                  'Season ${item.seasonWatched} • Eps ${item.episodesWatched}${totalEps > 0 ? ' / $totalEps' : ''}',
                                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                                if (totalEps > 0)
                                  Text(
                                    '${(progressRatio * 100).toInt()}%',
                                    style: const TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                              ],
                            ),
                            if (totalEps > 0) ...[
                              const SizedBox(height: 6),
                              LinearProgressIndicator(
                                value: progressRatio,
                                backgroundColor: Colors.white10,
                                color: Colors.amber,
                                minHeight: 4,
                              ),
                            ],
                            if (item.movie.nextAirDate.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 6.0),
                                child: Text(
                                  '📅 Next: ${item.movie.nextAirDate}',
                                  style: const TextStyle(color: Colors.lightBlueAccent, fontSize: 11),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Action Buttons
                      Row(
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            icon: const Icon(Icons.add, size: 14),
                            label: const Text('+1 Eps', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            onPressed: () => _incrementEpisode(item),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: const Icon(Icons.edit, color: Colors.white54, size: 18),
                            onPressed: () => _openEditModal(item),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: const Icon(Icons.delete, color: Colors.redAccent, size: 18),
                            onPressed: () => _deleteItem(item.id),
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
    );
  }

  // Movies Grid View
  Widget _buildMoviesGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.65,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final item = _items[index];
        final imageUrl = ApiService.getFullImageUrl(item.movie);

        return Container(
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
                          )
                        : const Center(child: Icon(Icons.movie, size: 48, color: Colors.white24)),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: item.status == 'completed' ? Colors.green : Colors.blue,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item.status.toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    if (item.rating > 0)
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
                            '★ ${item.rating.toStringAsFixed(1)}',
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
                      item.movie.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.edit, color: Colors.white54, size: 18),
                          onPressed: () => _openEditModal(item),
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.delete, color: Colors.redAccent, size: 18),
                          onPressed: () => _deleteItem(item.id),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _filterChip(String label, String value) {
    final isSelected = _activeStatus == value;
    return ChoiceChip(
      label: Text(label, style: TextStyle(color: isSelected ? Colors.black : Colors.white, fontSize: 12)),
      selected: isSelected,
      selectedColor: Colors.amber,
      backgroundColor: const Color(0xFF0F172A),
      onSelected: (selected) {
        if (selected) {
          setState(() => _activeStatus = value);
          _fetchWatchlist();
        }
      },
    );
  }
}

class _EditModalSheet extends StatefulWidget {
  final WatchlistItem item;
  final VoidCallback onSave;

  const _EditModalSheet({required this.item, required this.onSave});

  @override
  State<_EditModalSheet> createState() => _EditModalSheetState();
}

class _EditModalSheetState extends State<_EditModalSheet> {
  late String _status;
  late double _rating;
  late bool _favorite;
  late TextEditingController _notesController;
  late TextEditingController _seasonController;
  late TextEditingController _episodesController;
  late TextEditingController _totalEpisodesController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _status = widget.item.status;
    _rating = widget.item.rating > 0 ? widget.item.rating : 4.0;
    _favorite = widget.item.favorite;
    _notesController = TextEditingController(text: widget.item.notes);
    _seasonController = TextEditingController(text: widget.item.seasonWatched.toString());
    _episodesController = TextEditingController(text: widget.item.episodesWatched.toString());
    _totalEpisodesController = TextEditingController(
      text: (widget.item.totalEpisodes > 0 ? widget.item.totalEpisodes : widget.item.movie.totalEpisodes).toString(),
    );
  }

  Future<void> _update() async {
    setState(() => _isSaving = true);
    final success = await ApiService.updateWatchlist(
      id: widget.item.id,
      status: _status,
      rating: _rating,
      favorite: _favorite,
      notes: _notesController.text.trim(),
      seasonWatched: int.tryParse(_seasonController.text) ?? 1,
      episodesWatched: int.tryParse(_episodesController.text) ?? 0,
      totalEpisodes: int.tryParse(_totalEpisodesController.text) ?? 0,
    );

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        widget.onSave();
        Navigator.pop(context);
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
            Text('Edit Watchlist: ${widget.item.movie.title}', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            // Status Dropdown
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

            // 5 Star Rating Bar
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
            if (widget.item.movie.mediaType == 'tv') ...[
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

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isSaving ? null : _update,
                child: _isSaving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                    : const Text('Update Watchlist', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
