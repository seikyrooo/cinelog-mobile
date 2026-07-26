import 'package:flutter/material.dart';
import '../models/media_item.dart';
import '../services/api_service.dart';
import 'media_detail_screen.dart';

class WatchlistScreen extends StatefulWidget {
  const WatchlistScreen({super.key});

  @override
  State<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen> with TickerProviderStateMixin {
  late TabController _mainTabController;
  late TabController _tvSubTabController;

  bool _isLoading = true;
  List<WatchlistItem> _items = [];
  String _activeStatus = 'all';
  bool _favoriteOnly = false;

  @override
  void initState() {
    super.initState();
    _mainTabController = TabController(length: 2, vsync: this);
    _tvSubTabController = TabController(length: 2, vsync: this);

    _mainTabController.addListener(() {
      if (!_mainTabController.indexIsChanging) {
        _fetchWatchlist();
      }
    });

    _fetchWatchlist();
  }

  @override
  void dispose() {
    _mainTabController.dispose();
    _tvSubTabController.dispose();
    super.dispose();
  }

  Future<void> _fetchWatchlist() async {
    setState(() => _isLoading = true);
    final mediaType = _mainTabController.index == 0 ? 'tv' : 'movie';
    final items = await ApiService.fetchWatchlist(
      status: _activeStatus == 'all' ? null : _activeStatus,
      favorite: _favoriteOnly ? true : null,
      mediaType: mediaType,
    );

    if (mounted) {
      setState(() {
        _items = items;
        _isLoading = false;
      });
    }
  }

  Future<void> _incrementEpisode(WatchlistItem item) async {
    final updatedItem = await ApiService.incrementEpisodeProgress(item.id);
    if (updatedItem != null && mounted) {
      _fetchWatchlist();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Progres ${item.movie.title} diperbarui! (Eps ${updatedItem.episodesWatched})'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _openDetailScreen(MediaItem movie) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MediaDetailScreen(item: movie),
      ),
    );
  }

  void _openEditModal(WatchlistItem item) {
    final statusController = TextEditingController(text: item.status);
    final notesController = TextEditingController(text: item.notes);
    double ratingVal = item.rating > 0 ? item.rating : 4.0;
    bool isFavorite = item.favorite;
    int seasonWatched = item.seasonWatched;
    int episodesWatched = item.episodesWatched;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Edit ${item.movie.title}',
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white54),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Rating Stars 1-5
                  const Text('Rating Kamu (1-5 Bintang):', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 4),
                  Row(
                    children: List.generate(5, (index) {
                      final starNum = index + 1;
                      return IconButton(
                        icon: Icon(
                          starNum <= ratingVal ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 28,
                        ),
                        onPressed: () {
                          setModalState(() => ratingVal = starNum.toDouble());
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 12),

                  // Status Dropdown
                  DropdownButtonFormField<String>(
                    value: statusController.text,
                    dropdownColor: const Color(0xFF0F172A),
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Status Tontonan',
                      labelStyle: TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'watching', child: Text('Sedang Nonton (Watching)')),
                      DropdownMenuItem(value: 'completed', child: Text('Selesai (Completed)')),
                      DropdownMenuItem(value: 'plan_to_watch', child: Text('Rencana Nonton (Plan to Watch)')),
                      DropdownMenuItem(value: 'on_hold', child: Text('Ditunda (On Hold)')),
                      DropdownMenuItem(value: 'dropped', child: Text('Dihentikan (Dropped)')),
                    ],
                    onChanged: (val) {
                      if (val != null) setModalState(() => statusController.text = val);
                    },
                  ),
                  const SizedBox(height: 12),

                  if (item.movie.mediaType == 'tv') ...[
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: seasonWatched.toString(),
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              labelText: 'Season',
                              labelStyle: TextStyle(color: Colors.white70),
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (val) => seasonWatched = int.tryParse(val) ?? 1,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            initialValue: episodesWatched.toString(),
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              labelText: 'Eps Nonton',
                              labelStyle: TextStyle(color: Colors.white70),
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (val) => episodesWatched = int.tryParse(val) ?? 0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],

                  CheckboxListTile(
                    title: const Text('Tandai sebagai Favorit', style: TextStyle(color: Colors.white)),
                    value: isFavorite,
                    activeColor: Colors.amber,
                    checkColor: Colors.black,
                    onChanged: (val) => setModalState(() => isFavorite = val ?? false),
                  ),

                  TextField(
                    controller: notesController,
                    maxLines: 2,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Catatan / Review Singkat',
                      labelStyle: TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () async {
                        await ApiService.updateWatchlistItem(
                          item.id,
                          status: statusController.text,
                          rating: ratingVal,
                          favorite: isFavorite,
                          notes: notesController.text,
                          seasonWatched: seasonWatched,
                          episodesWatched: episodesWatched,
                        );
                        if (context.mounted) {
                          Navigator.pop(context);
                          _fetchWatchlist();
                        }
                      },
                      child: const Text('Simpan Perubahan', style: TextStyle(fontWeight: FontWeight.bold)),
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

  Future<void> _deleteItem(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Hapus Tontonan?', style: TextStyle(color: Colors.white)),
        content: const Text('Apakah kamu yakin ingin menghapus item ini dari watchlist?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal', style: TextStyle(color: Colors.white54))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Hapus', style: TextStyle(color: Colors.redAccent))),
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
          controller: _mainTabController,
          indicatorColor: Colors.amber,
          labelColor: Colors.amber,
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(icon: Icon(Icons.tv), text: 'TV Shows'),
            Tab(icon: Icon(Icons.movie), text: 'Movies'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _mainTabController,
        children: [
          _buildTvShowsTab(),
          _buildMoviesTab(),
        ],
      ),
    );
  }

  // TV Shows View matching TV Time app
  Widget _buildTvShowsTab() {
    return Column(
      children: [
        // Sub-tabs: WATCH LIST vs UPCOMING
        Container(
          color: const Color(0xFF1E293B),
          child: TabBar(
            controller: _tvSubTabController,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
            tabs: const [
              Tab(text: 'WATCH LIST'),
              Tab(text: 'UPCOMING'),
            ],
          ),
        ),

        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.amber))
              : TabBarView(
                  controller: _tvSubTabController,
                  children: [
                    _buildTvWatchlistTab(),
                    _buildTvUpcomingTab(),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildTvWatchlistTab() {
    final watchNextItems = _items.where((i) {
      final total = i.movie.totalEpisodes > 0 ? i.movie.totalEpisodes : i.totalEpisodes;
      final isTamat = i.status == 'completed' || (total > 0 && i.episodesWatched >= total);
      return !isTamat && (i.status == 'watching' || i.status == 'plan_to_watch');
    }).toList();

    final idleItems = _items.where((i) {
      final total = i.movie.totalEpisodes > 0 ? i.movie.totalEpisodes : i.totalEpisodes;
      final isTamat = i.status == 'completed' || (total > 0 && i.episodesWatched >= total);
      return !isTamat && i.status == 'on_hold';
    }).toList();

    final historyItems = _items.where((i) {
      final total = i.movie.totalEpisodes > 0 ? i.movie.totalEpisodes : i.totalEpisodes;
      return i.status == 'completed' || (total > 0 && i.episodesWatched >= total);
    }).toList();

    if (_items.isEmpty) {
      return const Center(child: Text('Belum ada TV Show di watchlist.', style: TextStyle(color: Colors.white54)));
    }

    return RefreshIndicator(
      onRefresh: _fetchWatchlist,
      color: Colors.amber,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Section 1: WATCH NEXT
          if (watchNextItems.isNotEmpty) ...[
            _sectionPillBadge('WATCH NEXT', Colors.white, Colors.black),
            const SizedBox(height: 10),
            ...watchNextItems.map((item) => _buildTvTimeCard(item, isCompleted: false)),
            const SizedBox(height: 20),
          ],

          // Section 2: HAVENT WATCHED FOR A WHILE
          if (idleItems.isNotEmpty) ...[
            _sectionPillBadge('HAVENT WATCHED FOR A WHILE', const Color(0xFF475569), Colors.white),
            const SizedBox(height: 10),
            ...idleItems.map((item) => _buildTvTimeCard(item, isCompleted: false)),
            const SizedBox(height: 20),
          ],

          // Section 3: WATCHED HISTORY
          if (historyItems.isNotEmpty) ...[
            _sectionPillBadge('WATCHED HISTORY', const Color(0xFF334155), Colors.white70),
            const SizedBox(height: 10),
            ...historyItems.map((item) => _buildTvTimeCard(item, isCompleted: true)),
          ],
        ],
      ),
    );
  }

  Widget _buildTvUpcomingTab() {
    final upcomingItems = _items.where((i) => i.movie.nextAirDate.isNotEmpty).toList();

    if (upcomingItems.isEmpty) {
      return const Center(child: Text('Belum ada episode mendatang.', style: TextStyle(color: Colors.white54)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: upcomingItems.length,
      itemBuilder: (context, index) {
        final item = upcomingItems[index];
        final imageUrl = ApiService.getFullImageUrl(item.movie);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF111827),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: imageUrl.isNotEmpty
                    ? Image.network(imageUrl, width: 75, height: 110, fit: BoxFit.cover)
                    : Container(width: 75, height: 110, color: const Color(0xFF0F172A), child: const Icon(Icons.tv, color: Colors.white24)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.movie.title.toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '📅 Rilis: ${item.movie.nextAirDate}',
                      style: const TextStyle(color: Colors.lightBlueAccent, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    if (item.movie.nextEpisodeName.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        '"${item.movie.nextEpisodeName}"',
                        style: const TextStyle(color: Colors.white70, fontSize: 12, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _sectionPillBadge(String title, Color bg, Color textCol) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          title,
          style: TextStyle(color: textCol, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 0.5),
        ),
      ),
    );
  }

  Widget _buildTvTimeCard(WatchlistItem item, {required bool isCompleted}) {
    final imageUrl = ApiService.getFullImageUrl(item.movie);
    final totalEps = item.movie.totalEpisodes > 0 ? item.movie.totalEpisodes : item.totalEpisodes;
    final nextEpsNum = (item.episodesWatched) + 1;
    final remainingCount = (isCompleted || (totalEps > 0 && item.episodesWatched >= totalEps)) ? 0 : (totalEps > 0 ? (totalEps - item.episodesWatched) : 0);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Poster
          GestureDetector(
            onTap: () => _openDetailScreen(item.movie),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: imageUrl.isNotEmpty
                  ? Image.network(imageUrl, width: 85, height: 120, fit: BoxFit.cover)
                  : Container(width: 85, height: 120, color: const Color(0xFF0F172A), child: const Icon(Icons.tv, color: Colors.white24)),
            ),
          ),
          const SizedBox(width: 14),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title Tag >
                GestureDetector(
                  onTap: () => _openDetailScreen(item.movie),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.15)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            item.movie.title.toUpperCase(),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right, color: Colors.white, size: 14),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),

                // Season & Episode Headline (e.g. S03 | E01 +51 eps lagi)
                Row(
                  children: [
                    Text(
                      isCompleted
                          ? 'S${_padZero(item.seasonWatched)} | E${_padZero(item.episodesWatched)}'
                          : 'S${_padZero(item.seasonWatched)} | E${_padZero(nextEpsNum)}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    if (!isCompleted && remainingCount > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.lightBlueAccent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '+$remainingCount eps lagi',
                          style: const TextStyle(color: Colors.lightBlueAccent, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),

                // Episode Title
                Text(
                  isCompleted
                      ? 'Semua episode telah ditonton 100%'
                      : (item.movie.nextEpisodeName.isNotEmpty
                          ? 'Next: "${item.movie.nextEpisodeName}"'
                          : 'Episode $nextEpsNum'),
                  style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),

                if (!isCompleted && nextEpsNum == 1)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
                    child: const Text('PREMIERE', style: TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ),

          // Big Circular Checkmark Button (TV Time style)
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _incrementEpisode(item),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted ? Colors.green : Colors.white,
              ),
              child: Icon(
                Icons.check,
                color: isCompleted ? Colors.white : Colors.black,
                size: 26,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _padZero(int n) => n < 10 ? '0$n' : '$n';

  // Movies Grid View
  Widget _buildMoviesTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.amber));
    }
    if (_items.isEmpty) {
      return const Center(child: Text('Belum ada film di watchlist.', style: TextStyle(color: Colors.white54)));
    }

    return RefreshIndicator(
      onRefresh: _fetchWatchlist,
      color: Colors.amber,
      child: GridView.builder(
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

          return GestureDetector(
            onTap: () => _openDetailScreen(item.movie),
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
                            ? Image.network(imageUrl, width: double.infinity, height: double.infinity, fit: BoxFit.cover)
                            : const Center(child: Icon(Icons.movie, size: 48, color: Colors.white24)),
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: item.status == 'completed' ? Colors.green : Colors.blue,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              item.status.toUpperCase(),
                              style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        if (item.favorite)
                          const Positioned(
                            top: 8,
                            right: 8,
                            child: Icon(Icons.star, color: Colors.amber, size: 20),
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.movie.title,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              item.movie.releaseDate.length >= 4 ? item.movie.releaseDate.substring(0, 4) : '',
                              style: const TextStyle(color: Colors.white54, fontSize: 11),
                            ),
                            if (item.rating > 0)
                              Text('★ ${item.rating}', style: const TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: const Icon(Icons.edit, color: Colors.white54, size: 16),
                              onPressed: () => _openEditModal(item),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: const Icon(Icons.delete, color: Colors.redAccent, size: 16),
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
      ),
    );
  }
}
