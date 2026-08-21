import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/media_item.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'media_detail_screen.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  List<SocialActivityItem> _activities = [];
  List<CommunityUser> _users = [];
  bool _isLoadingActivities = false;
  bool _isLoadingUsers = false;
  final Map<int, bool> _togglingFollow = {};

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadActivities();
    _loadUsers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadActivities() async {
    setState(() => _isLoadingActivities = true);
    final data = await ApiService.fetchSocialActivities(type: 'following');
    if (mounted) {
      setState(() {
        _activities = data;
        _isLoadingActivities = false;
      });
    }
  }

  Future<void> _loadUsers([String? query]) async {
    setState(() => _isLoadingUsers = true);
    final data = await ApiService.fetchCommunityUsers(query: query);
    if (mounted) {
      setState(() {
        _users = data;
        _isLoadingUsers = false;
      });
    }
  }

  Future<void> _toggleFollow(CommunityUser user) async {
    if (_togglingFollow[user.id] == true) return;
    setState(() => _togglingFollow[user.id] = true);

    final currentlyFollowing = user.isFollowing;
    setState(() {
      user.isFollowing = !currentlyFollowing;
    });

    final success = currentlyFollowing
        ? await ApiService.unfollowUser(user.id)
        : await ApiService.followUser(user.id);

    if (!success && mounted) {
      setState(() {
        user.isFollowing = currentlyFollowing;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update follow status')),
      );
    }
    if (mounted) {
      setState(() => _togglingFollow[user.id] = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgPrimary,
        title: Text(
          'Community',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w900,
            fontSize: 22,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary, size: 20),
            onPressed: () {
              if (_tabController.index == 0) {
                _loadActivities();
              } else {
                _loadUsers(_searchController.text.trim());
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accentRed,
          indicatorWeight: 2.5,
          labelColor: Colors.white,
          unselectedLabelColor: AppColors.textMuted,
          labelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 0.5),
          tabs: const [
            Tab(text: 'ACTIVITY FEED'),
            Tab(text: 'DISCOVER CINEPHILES'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildActivityTab(),
          _buildDiscoverTab(),
        ],
      ),
    );
  }

  Widget _buildActivityTab() {
    if (_isLoadingActivities) {
      return const Center(child: CircularProgressIndicator(color: AppColors.accentRed));
    }

    if (_activities.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadActivities,
        color: AppColors.accentRed,
        backgroundColor: AppColors.bgCard,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
          children: [
            Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.bgSurface,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: const Icon(Icons.forum_outlined, color: AppColors.textMuted, size: 30),
              ),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                'No Activity Yet',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.white),
              ),
            ),
            const SizedBox(height: 6),
            const Center(
              child: Text(
                'Follow other movie lovers in the Discover tab to see their reviews and scores here.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton.icon(
                onPressed: () => _tabController.animateTo(1),
                icon: const Icon(Icons.search_rounded, size: 16),
                label: const Text('Find Cinephiles'),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadActivities,
      color: AppColors.accentRed,
      backgroundColor: AppColors.bgCard,
      child: ListView.builder(
        padding: const EdgeInsets.all(14),
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        itemCount: _activities.length,
        itemBuilder: (context, index) {
          final act = _activities[index];
          return _buildActivityCard(act);
        },
      ),
    );
  }

  Widget _buildActivityCard(SocialActivityItem act) {
    final hasReview = act.review.isNotEmpty || act.notes.isNotEmpty;
    final reviewText = act.review.isNotEmpty ? act.review : act.notes;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Avatar, Username, Action, Rating
          Row(
            children: [
              CircleAvatar(
                radius: 17,
                backgroundColor: AppColors.accentRedSubtle,
                backgroundImage: act.user != null && act.user!.avatarUrl.isNotEmpty
                    ? NetworkImage(ApiService.getAvatarUrl(act.user!.avatarUrl))
                    : null,
                child: act.user == null || act.user!.avatarUrl.isEmpty
                    ? Text(
                        act.user != null && act.user!.username.isNotEmpty
                            ? act.user!.username.substring(0, 1).toUpperCase()
                            : 'C',
                        style: const TextStyle(color: AppColors.accentRed, fontWeight: FontWeight.w800, fontSize: 12),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '@${act.user?.username ?? "cinephile"}',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Colors.white),
                    ),
                    Text(
                      _getActivitySubtitle(act),
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              if (act.rating > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.starGoldSubtle,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0x66FFB800)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded, color: AppColors.starGold, size: 13),
                      const SizedBox(width: 2),
                      Text(
                        act.rating.toStringAsFixed(1),
                        style: const TextStyle(color: AppColors.starGold, fontWeight: FontWeight.w900, fontSize: 11),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Media Thumbnail Box
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MediaDetailScreen(item: act.movie),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      width: 44,
                      height: 64,
                      color: AppColors.bgPrimary,
                      child: act.movie.posterPath.isNotEmpty || act.movie.localPosterPath.isNotEmpty
                          ? Image.network(
                              ApiService.getFullImageUrl(act.movie),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(Icons.movie_outlined, color: AppColors.textMuted),
                            )
                          : const Icon(Icons.movie_outlined, color: AppColors.textMuted),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          act.movie.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppColors.bgPrimary,
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                act.movie.mediaType.toUpperCase(),
                                style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: AppColors.textSecondary),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              act.movie.releaseDate.length >= 4 ? act.movie.releaseDate.substring(0, 4) : '',
                              style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 18),
                ],
              ),
            ),
          ),

          // User Review Quote Box
          if (hasReview) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: const BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
                border: Border(left: BorderSide(color: AppColors.accentRed, width: 3)),
              ),
              child: Text(
                '"$reviewText"',
                style: const TextStyle(
                  fontStyle: FontStyle.italic,
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getActivitySubtitle(SocialActivityItem act) {
    if (act.review.isNotEmpty || act.notes.isNotEmpty) {
      return 'wrote a review';
    }
    if (act.status == 'completed') {
      return 'completed';
    }
    if (act.status == 'watching') {
      if (act.movie.mediaType == 'tv' && act.episodesWatched > 0) {
        return 'watching (Ep ${act.episodesWatched})';
      }
      return 'started watching';
    }
    if (act.favorite) {
      return 'favorited';
    }
    return 'logged an update';
  }

  Widget _buildDiscoverTab() {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(14),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Search username or bio...',
                hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, color: AppColors.textMuted, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _loadUsers();
                        },
                      )
                    : null,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              onChanged: (val) {
                _loadUsers(val.trim());
              },
            ),
          ),
        ),

        // User list
        Expanded(
          child: _isLoadingUsers
              ? const Center(child: CircularProgressIndicator(color: AppColors.accentRed))
              : _users.isEmpty
                  ? Center(
                      child: Text(
                        _searchController.text.isNotEmpty ? 'No users found' : 'No public profiles yet',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => _loadUsers(_searchController.text.trim()),
                      color: AppColors.accentRed,
                      backgroundColor: AppColors.bgCard,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                        itemCount: _users.length,
                        itemBuilder: (context, index) {
                          final user = _users[index];
                          return _buildUserCard(user);
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildUserCard(CommunityUser user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 19,
                backgroundColor: AppColors.accentRedSubtle,
                backgroundImage: user.avatarUrl.isNotEmpty
                    ? NetworkImage(ApiService.getAvatarUrl(user.avatarUrl))
                    : null,
                child: user.avatarUrl.isEmpty
                    ? Text(
                        user.username.isNotEmpty ? user.username.substring(0, 1).toUpperCase() : 'U',
                        style: const TextStyle(color: AppColors.accentRed, fontWeight: FontWeight.w800),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '@${user.username}',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Colors.white),
                    ),
                    if (user.bio.isNotEmpty)
                      Text(
                        user.bio,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                      ),
                  ],
                ),
              ),
              if (!user.isSelf)
                ElevatedButton(
                  onPressed: () => _toggleFollow(user),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: user.isFollowing ? AppColors.bgElevated : AppColors.accentRed,
                    foregroundColor: user.isFollowing ? AppColors.textSecondary : Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    minimumSize: const Size(60, 32),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: Text(
                    user.isFollowing ? 'Following' : 'Follow',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Stats Row
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatPill('Logged', user.watchedCount.toString()),
                _buildStatPill('Followers', user.followersCount.toString()),
                _buildStatPill('Following', user.followingCount.toString()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatPill(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Colors.white),
        ),
        Text(
          label.toUpperCase(),
          style: const TextStyle(fontSize: 8, color: AppColors.textMuted, fontWeight: FontWeight.w800, letterSpacing: 0.5),
        ),
      ],
    );
  }
}
