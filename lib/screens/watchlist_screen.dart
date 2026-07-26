import 'package:flutter/material.dart';
import '../models/media_item.dart';
import '../services/api_service.dart';
import 'media_detail_screen.dart';

class WatchlistScreen extends StatefulWidget {
  final String initialMediaType; // 'tv' or 'movie'
  const WatchlistScreen({super.key, this.initialMediaType = 'tv'});

  @override
  State<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tvSubTabController;

  bool _isLoading = true;
  List<WatchlistItem> _items = [];
  final String _activeStatus = 'all';
  final bool _favoriteOnly = false;
  late String _currentMediaType;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _currentMediaType = widget.initialMediaType;
    _tvSubTabController = TabController(length: 2, vsync: this);
    _fetchWatchlist();
  }

  @override
  void dispose() {
    _tvSubTabController.dispose();
    super.dispose();
  }

  Future<void> _fetchWatchlist() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final items = await ApiService.getWatchlist(
      status: _activeStatus == 'all' ? null : _activeStatus,
      favoriteOnly: _favoriteOnly,
      mediaType: _currentMediaType,
    );

    if (mounted) {
      setState(() {
        _items = items;
        _isLoading = false;
      });
    }
  }

  Future<void> _incrementEpisode(WatchlistItem item) async {
    final success = await ApiService.incrementEpisodeProgress(item.id);
    if (success && mounted) {
      _fetchWatchlist();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Progres ${item.movie.title} diperbarui!'),
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
    double ratingVal = item.rating > 0 ? item.rating : 8.0;
    bool isFavorite = item.favorite;
    int seasonWatched = item.seasonWatched > 0 ? item.seasonWatched : 1;
    int episodesWatched = item.episodesWatched;

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
                left: 20,
                right: 20,
                top: 20,
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
                        'Edit Watchlist',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white70),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  Text(
                    item.movie.title,
                    style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    initialValue: statusController.text,
                    decoration: const InputDecoration(
                      labelText: 'Status Tontonan',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'watching', child: Text('Sedang Nonton (Watching)')),
                      DropdownMenuItem(value: 'completed', child: Text('Selesai (Completed)')),
                      DropdownMenuItem(value: 'plan_to_watch', child: Text('Rencana Nonton')),
                      DropdownMenuItem(value: 'on_hold', child: Text('Ditunda (On Hold)')),
                      DropdownMenuItem(value: 'dropped', child: Text('Dihentikan (Dropped)')),
                    ],
                    onChanged: (val) {
                      if (val != null) statusController.text = val;
                    },
                  ),
                  const SizedBox(height: 14),

                  Text('Rating (1 - 10): ${ratingVal.toStringAsFixed(1)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Slider(
                    value: ratingVal,
                    min: 1.0,
                    max: 10.0,
                    divisions: 18,
                    activeColor: Colors.amber,
                    label: ratingVal.toStringAsFixed(1),
                    onChanged: (val) => setModalState(() => ratingVal = val),
                  ),
                  const SizedBox(height: 10),

                  if (_currentMediaType == 'tv') ...[
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: seasonWatched.toString(),
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Season Watched', border: OutlineInputBorder()),
                            onChanged: (v) => seasonWatched = int.tryParse(v) ?? 1,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            initialValue: episodesWatched.toString(),
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Episodes Watched', border: OutlineInputBorder()),
                            onChanged: (v) => episodesWatched = int.tryParse(v) ?? 0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                  ],

                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Tandai sebagai Favorit'),
                    value: isFavorite,
                    activeColor: Colors.amber,
                    onChanged: (val) => setModalState(() => isFavorite = val ?? false),
                  ),
                  const SizedBox(height: 10),

                  TextField(
                    controller: notesController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Catatan / Review',
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
                        await ApiService.updateWatchlist(
                          id: item.id,
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

  void _deleteItem(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Item'),
        content: const Text('Apakah kamu yakin ingin menghapus tontonan ini dari Watchlist?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await ApiService.deleteWatchlist(id);
      if (success && mounted) {
        _fetchWatchlist();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item berhasil dihapus')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentMediaType == 'tv' ? 'TV Shows Watchlist' : 'Movies Watchlist',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF0F172A),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.amber),
            onPressed: _fetchWatchlist,
          ),
        ],
      ),
      body: _currentMediaType == 'tv' ? _buildTvExperience() : _buildMoviesExperience(),
    );
  }

  Widget _buildTvExperience() {
    return Column(
      children: [
        Container(
          color: const Color(0xFF0F172A),
          child: TabBar(
            controller: _tvSubTabController,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white38,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
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
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          if (watchNextItems.isNotEmpty) ...[
            _sectionPillBadge('WATCH NEXT', Colors.white, Colors.black),
            const SizedBox(height: 10),
            ...watchNextItems.map((item) => _buildTvTimeCard(item, isCompleted: false)),
            const SizedBox(height: 20),
          ],
          if (idleItems.isNotEmpty) ...[
            _sectionPillBadge('HAVENT WATCHED FOR A WHILE', const Color(0xFF475569), Colors.white),
            const SizedBox(height: 10),
            ...idleItems.map((item) => _buildTvTimeCard(item, isCompleted: false)),
            const SizedBox(height: 20),
          ],
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
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 70,
                  height: 100,
                  child: imageUrl.isNotEmpty
                      ? Image.network(imageUrl, fit: BoxFit.cover)
                      : Container(color: Colors.grey[900]),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.movie.title.toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 14, color: Colors.lightBlueAccent),
                        const SizedBox(width: 6),
                        Text(
                          'Rilis: ${item.movie.nextAirDate}',
                          style: const TextStyle(color: Colors.lightBlueAccent, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    if (item.movie.nextEpisodeName.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Judul Eps: "${item.movie.nextEpisodeName}"',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
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

  Widget _sectionPillBadge(String title, Color bgCol, Color textCol) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: bgCol,
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
    final remainingCount = (isCompleted || (totalEps > 0 && item.episodesWatched >= totalEps))
        ? 0
        : (totalEps > 0 ? (totalEps - item.episodesWatched) : 0);

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
          GestureDetector(
            onTap: () => _openDetailScreen(item.movie),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 75,
                height: 105,
                child: imageUrl.isNotEmpty
                    ? Image.network(imageUrl, fit: BoxFit.cover)
                    : Container(color: Colors.grey[900]),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => _openDetailScreen(item.movie),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.15)),
                    ),
                    child: Text(
                      '${item.movie.title.toUpperCase()} >',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 6),

                if (isCompleted) ...[
                  Row(
                    children: [
                      Text(
                        'S${_padZero(item.seasonWatched > 0 ? item.seasonWatched : 1)} | E${_padZero(item.episodesWatched > 0 ? item.episodesWatched : totalEps)}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'TAMAT (${item.episodesWatched > 0 ? item.episodesWatched : totalEps} eps)',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text('Semua episode telah ditonton 100%', style: TextStyle(color: Colors.white70, fontSize: 12)),
                ] else ...[
                  Row(
                    children: [
                      Text(
                        'S${_padZero(item.seasonWatched > 0 ? item.seasonWatched : 1)} | E${_padZero(nextEpsNum)}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      if (remainingCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.lightBlueAccent.withOpacity(0.12),
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
                  Text(
                    item.movie.nextEpisodeName.isNotEmpty
                        ? 'Next: "${item.movie.nextEpisodeName}"'
                        : 'Next: Episode $nextEpsNum',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 6),

                  Row(
                    children: [
                      if (nextEpsNum == 1)
                        Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
                          child: const Text('PREMIERE', style: TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.bold)),
                        ),
                      if (item.favorite)
                        Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(4)),
                          child: const Text('★ FAVORIT', style: TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          if (!isCompleted)
            IconButton(
              icon: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: const Icon(Icons.check, color: Colors.black, size: 22),
              ),
              onPressed: () => _incrementEpisode(item),
            )
          else
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
              child: const Icon(Icons.check, color: Colors.white, size: 22),
            ),
        ],
      ),
    );
  }

  Widget _buildMoviesExperience() {
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
          childAspectRatio: 0.62,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
        ),
        itemCount: _items.length,
        itemBuilder: (context, index) {
          final item = _items[index];
          final imageUrl = ApiService.getFullImageUrl(item.movie);

          return Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      GestureDetector(
                        onTap: () => _openDetailScreen(item.movie),
                        child: Positioned.fill(
                          child: imageUrl.isNotEmpty
                              ? Image.network(imageUrl, fit: BoxFit.cover)
                              : Container(color: Colors.grey[900]),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            item.status.toUpperCase(),
                            style: const TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      if (item.favorite)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('★ FAV', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                          ),
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (item.rating > 0)
                            Text(
                              '★ ${item.rating.toStringAsFixed(1)}',
                              style: const TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          Row(
                            children: [
                              IconButton(
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.edit, size: 16, color: Colors.white70),
                                onPressed: () => _openEditModal(item),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                constraints: const BoxConstraints(),
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.delete, size: 16, color: Colors.redAccent),
                                onPressed: () => _deleteItem(item.id),
                              ),
                            ],
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
      ),
    );
  }

  String _padZero(int num) {
    return num < 10 ? '0$num' : '$num';
  }
}
