import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/media_item.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
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
  String _currentMediaType = 'tv';

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
          content: Text('Episode logged for ${item.movie.title}'),
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _WatchlistEditSheet(
        item: item,
        onSaved: _fetchWatchlist,
        onDeleted: () {
          _fetchWatchlist();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgPrimary,
        title: Text(
          'Watchlist',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w900,
            fontSize: 22,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary, size: 20),
            onPressed: _fetchWatchlist,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Container(
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.bgSurface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Row(
                children: [
                  _buildMediaTypeTab('TV Shows', 'tv'),
                  _buildMediaTypeTab('Movies', 'movie'),
                ],
              ),
            ),
          ),
        ),
      ),
      body: _currentMediaType == 'tv' ? _buildTvExperience() : _buildMoviesExperience(),
    );
  }

  Widget _buildMediaTypeTab(String title, String type) {
    final isSelected = _currentMediaType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_currentMediaType != type) {
            setState(() => _currentMediaType = type);
            _fetchWatchlist();
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.accentRed : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.textMuted,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTvExperience() {
    return Column(
      children: [
        Container(
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: AppColors.borderSubtle, width: 1),
            ),
          ),
          child: TabBar(
            controller: _tvSubTabController,
            indicatorColor: AppColors.accentRed,
            indicatorWeight: 2.5,
            labelColor: Colors.white,
            unselectedLabelColor: AppColors.textMuted,
            labelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 0.5),
            tabs: const [
              Tab(text: 'WATCH LIST'),
              Tab(text: 'RADAR / UPCOMING'),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.accentRed))
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
      final isDone = i.status == 'completed' || (total > 0 && i.episodesWatched >= total);
      return !isDone && (i.status == 'watching' || i.status == 'plan_to_watch');
    }).toList();

    final onHoldItems = _items.where((i) {
      final total = i.movie.totalEpisodes > 0 ? i.movie.totalEpisodes : i.totalEpisodes;
      final isDone = i.status == 'completed' || (total > 0 && i.episodesWatched >= total);
      return !isDone && i.status == 'on_hold';
    }).toList();

    final historyItems = _items.where((i) {
      final total = i.movie.totalEpisodes > 0 ? i.movie.totalEpisodes : i.totalEpisodes;
      return i.status == 'completed' || (total > 0 && i.episodesWatched >= total);
    }).toList();

    if (_items.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bookmark_outline_rounded, size: 48, color: AppColors.textMuted),
            SizedBox(height: 12),
            Text(
              'No TV series in your watchlist yet',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchWatchlist,
      color: AppColors.accentRed,
      backgroundColor: AppColors.bgCard,
      child: ListView(
        padding: const EdgeInsets.all(16),
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        children: [
          if (watchNextItems.isNotEmpty) ...[
            _sectionPillBadge('WATCH NEXT', AppColors.accentRed, Colors.white),
            const SizedBox(height: 10),
            ...watchNextItems.map((item) => _buildTvTimeCard(item, isCompleted: false)),
            const SizedBox(height: 20),
          ],
          if (onHoldItems.isNotEmpty) ...[
            _sectionPillBadge('ON HOLD', AppColors.bgElevated, AppColors.textSecondary),
            const SizedBox(height: 10),
            ...onHoldItems.map((item) => _buildTvTimeCard(item, isCompleted: false)),
            const SizedBox(height: 20),
          ],
          if (historyItems.isNotEmpty) ...[
            _sectionPillBadge('COMPLETED HISTORY', const Color(0xFF1E293B), const Color(0xFF4ADE80)),
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
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.radar_rounded, size: 48, color: AppColors.textMuted),
            SizedBox(height: 12),
            Text(
              'No upcoming TV series episodes scheduled',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchWatchlist,
      color: AppColors.accentRed,
      backgroundColor: AppColors.bgCard,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        itemCount: upcomingItems.length,
        itemBuilder: (context, index) {
          final item = upcomingItems[index];
          final imageUrl = ApiService.getFullImageUrl(item.movie);

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 65,
                    height: 95,
                    child: imageUrl.isNotEmpty
                        ? Image.network(imageUrl, fit: BoxFit.cover)
                        : Container(color: AppColors.bgCard),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () => _openDetailScreen(item.movie),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                item.movie.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.textMuted),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.infoBlueSubtle,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0x4D3B82F6)),
                        ),
                        child: Text(
                          'Airs: ${item.movie.nextAirDate}',
                          style: const TextStyle(color: Color(0xFF93C5FD), fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                      ),
                      if (item.movie.nextEpisodeName.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Next: "${item.movie.nextEpisodeName}"',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ],
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

  Widget _sectionPillBadge(String title, Color bgCol, Color textCol) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: bgCol,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          title,
          style: TextStyle(color: textCol, fontWeight: FontWeight.w800, fontSize: 10, letterSpacing: 0.5),
        ),
      ),
    );
  }

  Widget _buildTvTimeCard(WatchlistItem item, {required bool isCompleted}) {
    final backdropUrl = ApiService.getFullBackdropUrl(item.movie);
    final posterUrl = ApiService.getFullImageUrl(item.movie);
    final imageUrl = backdropUrl.isNotEmpty ? backdropUrl : posterUrl;
    final totalEps = item.movie.totalEpisodes > 0 ? item.movie.totalEpisodes : item.totalEpisodes;
    final nextEpsNum = (item.episodesWatched) + 1;
    final remainingCount = (isCompleted || (totalEps > 0 && item.episodesWatched >= totalEps))
        ? 0
        : (totalEps > 0 ? (totalEps - item.episodesWatched) : 0);

    final episodeTitle = isCompleted
        ? 'Series Completed ✓'
        : (item.movie.nextEpisodeName.isNotEmpty
            ? item.movie.nextEpisodeName
            : 'Episode $nextEpsNum');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 16:9 Episode Thumbnail Frame
              GestureDetector(
                onTap: () => _openDetailScreen(item.movie),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Stack(
                    children: [
                      Container(
                        width: 115,
                        height: 72,
                        color: AppColors.bgCard,
                        child: imageUrl.isNotEmpty
                            ? Image.network(imageUrl, fit: BoxFit.cover)
                            : const SizedBox.shrink(),
                      ),
                      Positioned.fill(
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Colors.black87],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 5,
                        bottom: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xCC000000),
                            borderRadius: BorderRadius.circular(3),
                            border: Border.all(color: Colors.white24, width: 0.8),
                          ),
                          child: Text(
                            'S${_padZero(item.seasonWatched > 0 ? item.seasonWatched : 1)} | E${_padZero(isCompleted ? (item.episodesWatched > 0 ? item.episodesWatched : totalEps) : nextEpsNum)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Title, Episode Name, and Rate
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Show Title
                    GestureDetector(
                      onTap: () => _openDetailScreen(item.movie),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              item.movie.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.textMuted),
                        ],
                      ),
                    ),
                    const SizedBox(height: 3),

                    // Episode Title
                    Text(
                      episodeTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Minimalist Rate Pill & Remaining Info
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => _openEditModal(item),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: item.rating > 0 ? AppColors.starGoldSubtle : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: item.rating > 0 ? const Color(0x66FFB800) : AppColors.borderLight,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.star_rounded,
                                  size: 12,
                                  color: item.rating > 0 ? AppColors.starGold : AppColors.textMuted,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  item.rating > 0 ? '${item.rating.toStringAsFixed(1)}/10' : 'Rate',
                                  style: TextStyle(
                                    color: item.rating > 0 ? AppColors.starGold : AppColors.textSecondary,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (remainingCount > 0 && !isCompleted) ...[
                          const SizedBox(width: 6),
                          Text(
                            '$remainingCount eps left',
                            style: const TextStyle(color: Color(0xFFFF8585), fontSize: 10, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Check button
              IconButton(
                icon: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isCompleted ? AppColors.successGreen : AppColors.bgCard,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isCompleted ? AppColors.successGreen : AppColors.borderSubtle,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.check_rounded,
                      size: 20,
                      color: isCompleted ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                ),
                onPressed: isCompleted ? null : () => _incrementEpisode(item),
              ),
            ],
          ),

          // Episode Overview / Synopsis (if available)
          if (item.movie.overview.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              item.movie.overview,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11.5,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMoviesExperience() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.accentRed));
    }

    if (_items.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.movie_outlined, size: 48, color: AppColors.textMuted),
            SizedBox(height: 12),
            Text('No movies in your watchlist yet', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchWatchlist,
      color: AppColors.accentRed,
      backgroundColor: AppColors.bgCard,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.60,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
        ),
        itemCount: _items.length,
        itemBuilder: (context, index) {
          final item = _items[index];
          final imageUrl = ApiService.getFullImageUrl(item.movie);

          return GestureDetector(
            onTap: () => _openDetailScreen(item.movie),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.bgSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        imageUrl.isNotEmpty
                            ? Image.network(imageUrl, fit: BoxFit.cover)
                            : Container(color: AppColors.bgCard),
                        if (item.rating > 0)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xD9000000),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.star_rounded, color: AppColors.starGold, size: 12),
                                  const SizedBox(width: 2),
                                  Text(
                                    item.rating.toStringAsFixed(1),
                                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
                                  ),
                                ],
                              ),
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
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              item.movie.releaseDate.length >= 4 ? item.movie.releaseDate.substring(0, 4) : '',
                              style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                            ),
                            GestureDetector(
                              onTap: () => _openEditModal(item),
                              child: const Icon(Icons.more_horiz_rounded, size: 18, color: AppColors.textMuted),
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

  String _padZero(int num) => num < 10 ? '0$num' : '$num';
}

class _WatchlistEditSheet extends StatefulWidget {
  final WatchlistItem item;
  final VoidCallback onSaved;
  final VoidCallback onDeleted;

  const _WatchlistEditSheet({
    required this.item,
    required this.onSaved,
    required this.onDeleted,
  });

  @override
  State<_WatchlistEditSheet> createState() => _WatchlistEditSheetState();
}

class _WatchlistEditSheetState extends State<_WatchlistEditSheet> {
  late double _rating;
  late bool _favorite;
  late TextEditingController _notesController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _rating = widget.item.rating > 0 ? widget.item.rating : 8.0;
    _favorite = widget.item.favorite;
    _notesController = TextEditingController(text: widget.item.notes);
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final isMovie = widget.item.movie.mediaType == 'movie';
    final statusVal = (isMovie && _rating > 0) ? 'completed' : (_rating > 0 ? 'completed' : widget.item.status);

    await ApiService.updateWatchlist(
      id: widget.item.id,
      status: statusVal,
      rating: _rating,
      favorite: _favorite,
      notes: _notesController.text.trim(),
      seasonWatched: widget.item.seasonWatched,
      episodesWatched: widget.item.episodesWatched,
      totalEpisodes: widget.item.totalEpisodes,
    );
    if (mounted) {
      setState(() => _isSaving = false);
      Navigator.pop(context);
      widget.onSaved();
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgSurface,
        title: const Text('Remove from Watchlist', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        content: Text('Are you sure you want to remove "${widget.item.movie.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ApiService.deleteWatchlist(widget.item.id);
      if (mounted) {
        Navigator.pop(context);
        widget.onDeleted();
      }
    }
  }

  Future<void> _deleteRate() async {
    setState(() {
      _rating = 0.0;
      _isSaving = true;
    });
    final isMovie = widget.item.movie.mediaType == 'movie';
    await ApiService.updateWatchlist(
      id: widget.item.id,
      status: isMovie ? 'watching' : widget.item.status,
      rating: 0.0,
      favorite: _favorite,
      notes: _notesController.text.trim(),
      seasonWatched: widget.item.seasonWatched,
      episodesWatched: widget.item.episodesWatched,
      totalEpisodes: widget.item.totalEpisodes,
    );
    if (!mounted) return;
    setState(() => _isSaving = false);
    Navigator.pop(context);
    widget.onSaved();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.item.movie.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444)),
                  onPressed: _delete,
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Rating Score Chips
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Score', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w700)),
                Text(
                  _rating > 0 ? '${_rating.toInt()} / 10' : 'Unrated',
                  style: TextStyle(
                    color: _rating > 0 ? AppColors.starGold : AppColors.textMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(10, (index) {
                  final score = (index + 1).toDouble();
                  final isSelected = _rating == score;
                  return GestureDetector(
                    onTap: () => setState(() {
                      if (_rating == score) {
                        _rating = 0.0;
                      } else {
                        _rating = score;
                      }
                    }),
                    child: Container(
                      margin: const EdgeInsets.only(right: 6),
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.accentRed : AppColors.bgCard,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? AppColors.accentRed : AppColors.borderSubtle,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: isSelected ? Colors.white : AppColors.textSecondary,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 16),

            // Notes / Review
            TextField(
              controller: _notesController,
              maxLines: 2,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: const InputDecoration(
                hintText: 'Notes or thoughts...',
              ),
            ),
            const SizedBox(height: 12),

            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Favorite', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
              value: _favorite,
              activeThumbColor: AppColors.accentRed,
              onChanged: (val) => setState(() => _favorite = val),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                if (widget.item.rating > 0 || _rating > 0) ...[
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 46,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0x55EF4444)),
                          backgroundColor: const Color(0x1AEF4444),
                          foregroundColor: const Color(0xFFEF4444),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                        ),
                        icon: const Icon(Icons.delete_sweep_rounded, size: 16, color: Color(0xFFEF4444)),
                        label: const Text('Delete Rate', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                        onPressed: _isSaving ? null : _deleteRate,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  flex: 3,
                  child: SizedBox(
                    height: 46,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      child: _isSaving
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
