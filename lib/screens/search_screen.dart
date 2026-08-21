import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/media_item.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'media_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with AutomaticKeepAliveClientMixin {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  String _selectedType = 'all';
  bool _isSearching = false;
  bool _isLoadingResults = false;
  List<MediaItem> _searchResults = [];

  // Discovery Shelves
  bool _isLoadingShelves = true;
  List<MediaItem> _trendingList = [];
  List<MediaItem> _popularMovies = [];
  List<MediaItem> _topShows = [];
  MediaItem? _spotlightItem;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadDiscoveryFeeds();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadDiscoveryFeeds() async {
    setState(() => _isLoadingShelves = true);
    try {
      final trending = await ApiService.fetchTrendingMedia(type: 'all', time: 'week');
      final movies = await ApiService.fetchDiscoverMedia(type: 'movie', sort: 'popularity.desc');
      final tv = await ApiService.fetchDiscoverMedia(type: 'tv', sort: 'popularity.desc');

      if (mounted) {
        setState(() {
          _trendingList = trending;
          _popularMovies = movies;
          _topShows = tv;
          if (trending.isNotEmpty) {
            _spotlightItem = trending.first;
          }
          _isLoadingShelves = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingShelves = false);
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 350), () {
      _performSearch(query.trim());
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) return;
    setState(() {
      _isSearching = true;
      _isLoadingResults = true;
    });

    final items = await ApiService.searchMedia(query, type: _selectedType);
    if (mounted) {
      setState(() {
        _searchResults = items;
        _isLoadingResults = false;
      });
    }
  }

  void _openDetailScreen(MediaItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MediaDetailScreen(item: item)),
    );
  }

  void _openSaveModal(MediaItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _QuickSaveSheet(item: item),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: _loadDiscoveryFeeds,
          color: AppColors.accentRed,
          backgroundColor: AppColors.bgCard,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              // Sleek App Bar with Logo
              SliverAppBar(
                floating: true,
                pinned: false,
                snap: true,
                backgroundColor: const Color(0xF2101012),
                title: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: AppColors.accentRed,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: const Center(
                        child: Text(
                          'C',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'CINELOG',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                actions: [
                  if (_isSearching)
                    TextButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _isSearching = false;
                          _searchResults = [];
                        });
                      },
                      child: const Text('Cancel', style: TextStyle(color: AppColors.accentRed, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),

              // Search Bar & Filter Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    children: [
                      // Modern Search Box
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.bgSurface,
                          borderRadius: BorderRadius.circular(50),
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: TextField(
                          controller: _searchController,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          onChanged: _onSearchChanged,
                          onSubmitted: (val) => _performSearch(val.trim()),
                          decoration: InputDecoration(
                            hintText: 'Search movies, TV series, anime...',
                            hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                            prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 20),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, color: AppColors.textMuted, size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {
                                        _isSearching = false;
                                        _searchResults = [];
                                      });
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Filter Pills
                      Row(
                        children: [
                          _buildFilterChip('All', 'all'),
                          const SizedBox(width: 8),
                          _buildFilterChip('Movies', 'movie'),
                          const SizedBox(width: 8),
                          _buildFilterChip('TV Shows', 'tv'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Body Content
              if (_isSearching) ...[
                _buildSearchResultsSliver(),
              ] else if (_isLoadingShelves) ...[
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.accentRed),
                  ),
                ),
              ] else ...[
                // Spotlight Hero Card
                if (_spotlightItem != null)
                  SliverToBoxAdapter(
                    child: _buildSpotlightHero(_spotlightItem!),
                  ),

                // Shelf 1: Trending This Week
                if (_trendingList.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _buildMediaShelf(
                      title: 'Trending This Week',
                      subtitle: 'Most watched worldwide',
                      items: _trendingList,
                    ),
                  ),

                // Shelf 2: Popular Movies
                if (_popularMovies.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _buildMediaShelf(
                      title: 'Popular Movies',
                      subtitle: 'Blockbusters and award winners',
                      items: _popularMovies,
                    ),
                  ),

                // Shelf 3: Top TV Shows
                if (_topShows.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _buildMediaShelf(
                      title: 'Top TV Series',
                      subtitle: 'Binge-worthy shows',
                      items: _topShows,
                    ),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedType == value;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedType = value);
        if (_searchController.text.trim().isNotEmpty) {
          _performSearch(_searchController.text.trim());
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentRed : AppColors.bgSurface,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected ? AppColors.accentRed : AppColors.borderSubtle,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildSpotlightHero(MediaItem item) {
    final backdropUrl = ApiService.getFullBackdropUrl(item);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: GestureDetector(
        onTap: () => _openDetailScreen(item),
        child: Container(
          height: 220,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderSubtle),
            boxShadow: const [
              BoxShadow(
                color: Color(0x80000000),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
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

              // Gradient Overlay
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Color(0x66000000),
                      Color(0xF2101012),
                    ],
                  ),
                ),
              ),

              // Content Details
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.accentRed,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'FEATURED',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        if (item.voteAverage > 0) ...[
                          const SizedBox(width: 8),
                          Row(
                            children: [
                              const Icon(Icons.star_rounded, color: AppColors.starGold, size: 14),
                              const SizedBox(width: 2),
                              Text(
                                item.voteAverage.toStringAsFixed(1),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.overview,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMediaShelf({
    required String title,
    required String subtitle,
    required List<MediaItem> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 3,
                    height: 14,
                    decoration: BoxDecoration(
                      color: AppColors.accentRed,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 190,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return _buildShelfCard(item);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildShelfCard(MediaItem item) {
    final posterUrl = ApiService.getFullImageUrl(item);

    return GestureDetector(
      onTap: () => _openDetailScreen(item),
      child: Container(
        width: 110,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 150,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.borderSubtle),
                color: AppColors.bgCard,
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (posterUrl.isNotEmpty)
                    Image.network(
                      posterUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(Icons.movie_outlined, color: AppColors.textMuted, size: 28),
                      ),
                    )
                  else
                    const Center(
                      child: Icon(Icons.movie_outlined, color: AppColors.textMuted, size: 28),
                    ),
                  if (item.voteAverage > 0)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xCC000000),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded, color: AppColors.starGold, size: 10),
                            const SizedBox(width: 2),
                            Text(
                              item.voteAverage.toStringAsFixed(1),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              item.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResultsSliver() {
    if (_isLoadingResults) {
      return const SliverFillRemaining(
        child: Center(
          child: CircularProgressIndicator(color: AppColors.accentRed),
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.search_off_rounded, color: AppColors.textMuted, size: 48),
              const SizedBox(height: 12),
              Text(
                'No results found for "${_searchController.text}"',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.58,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final item = _searchResults[index];
            return _buildSearchResultCard(item);
          },
          childCount: _searchResults.length,
        ),
      ),
    );
  }

  Widget _buildSearchResultCard(MediaItem item) {
    final posterUrl = ApiService.getFullImageUrl(item);

    return GestureDetector(
      onTap: () => _openDetailScreen(item),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(12),
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
                  if (posterUrl.isNotEmpty)
                    Image.network(
                      posterUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppColors.bgCard,
                        child: const Icon(Icons.movie_outlined, color: AppColors.textMuted),
                      ),
                    )
                  else
                    Container(
                      color: AppColors.bgCard,
                      child: const Icon(Icons.movie_outlined, color: AppColors.textMuted),
                    ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: item.mediaType == 'tv' ? AppColors.accentRed : Colors.white24,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item.mediaType == 'tv' ? 'TV' : 'MOVIE',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
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
                          color: const Color(0xD9000000),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded, color: AppColors.starGold, size: 12),
                            const SizedBox(width: 2),
                            Text(
                              item.voteAverage.toStringAsFixed(1),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
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
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item.releaseDate.length >= 4 ? item.releaseDate.substring(0, 4) : '',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                      ),
                      GestureDetector(
                        onTap: () => _openSaveModal(item),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.accentRedSubtle,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.accentRedBorder),
                          ),
                          child: const Text(
                            '+ Log',
                            style: TextStyle(
                              color: AppColors.accentRed,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
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
  }
}

class _QuickSaveSheet extends StatefulWidget {
  final MediaItem item;
  const _QuickSaveSheet({required this.item});

  @override
  State<_QuickSaveSheet> createState() => _QuickSaveSheetState();
}

class _QuickSaveSheetState extends State<_QuickSaveSheet> {
  String _status = 'watching';
  bool _favorite = false;
  final bool _isPublicFeed = true;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _status = widget.item.mediaType == 'tv' ? 'watching' : 'plan_to_watch';
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);

    final success = await ApiService.addToWatchlist(
      item: widget.item,
      status: _status,
      rating: 0,
      favorite: _favorite,
      notes: '',
      isPublicFeed: _isPublicFeed,
    );

    if (mounted) {
      setState(() => _isSaving = false);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Added to watchlist' : 'Failed to save. Please login first.',
          ),
          backgroundColor: success ? AppColors.bgElevated : const Color(0xFFEF4444),
        ),
      );
    }
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
            // Handle Bar
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
                    widget.item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Status Selector Pills
            const Text(
              'Watchlist Category',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _status = 'watching'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _status == 'watching' ? AppColors.accentRed : AppColors.bgCard,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _status == 'watching' ? AppColors.accentRed : AppColors.borderSubtle,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          widget.item.mediaType == 'tv' ? 'Watching' : 'Plan to Watch',
                          style: TextStyle(
                            color: _status == 'watching' ? Colors.white : AppColors.textSecondary,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _status = 'completed'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _status == 'completed' ? AppColors.accentRed : AppColors.bgCard,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _status == 'completed' ? AppColors.accentRed : AppColors.borderSubtle,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'Completed',
                          style: TextStyle(
                            color: _status == 'completed' ? Colors.white : AppColors.textSecondary,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Toggle Switches
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Add to Favorites', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
              value: _favorite,
              activeThumbColor: AppColors.accentRed,
              onChanged: (val) => setState(() => _favorite = val),
            ),

            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Save to Watchlist', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
