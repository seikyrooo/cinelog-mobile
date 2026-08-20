import 'package:flutter/material.dart';
import '../models/media_item.dart';
import '../services/api_service.dart';
import 'media_detail_screen.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  List<SocialActivityItem> _activities = [];
  List<CommunityUser> _users = [];
  bool _isLoadingActivities = false;
  bool _isLoadingUsers = false;
  final Map<int, bool> _togglingFollow = {};

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
        const SnackBar(content: Text('Gagal memperbarui status follow')),
      );
    }
    if (mounted) {
      setState(() => _togglingFollow[user.id] = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const accentRed = Color(0xFFE50914);
    const bgSurface = Color(0xFF181818);
    const bgCard = Color(0xFF1F1F1F);

    return Scaffold(
      backgroundColor: const Color(0xFF141414),
      appBar: AppBar(
        backgroundColor: const Color(0xFF141414),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: accentRed.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: accentRed.withOpacity(0.4)),
              ),
              child: const Icon(Icons.people_alt, color: accentRed, size: 18),
            ),
            const SizedBox(width: 10),
            const Text(
              'Community',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 20,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: accentRed,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.bolt, size: 18), text: 'Activity Feed'),
            Tab(icon: Icon(Icons.explore, size: 18), text: 'Discover Cinephiles'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Following Activity Stream
          _buildActivityTab(accentRed, bgSurface, bgCard),
          // Tab 2: Discover Cinephiles
          _buildDiscoverTab(accentRed, bgSurface, bgCard),
        ],
      ),
    );
  }

  Widget _buildActivityTab(Color accentRed, Color bgSurface, Color bgCard) {
    if (_isLoadingActivities) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFE50914)));
    }

    if (_activities.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadActivities,
        color: accentRed,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
          children: [
            Center(
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.bolt, color: Colors.white38, size: 36),
              ),
            ),
            const SizedBox(height: 18),
            const Center(
              child: Text(
                'Belum Ada Aktivitas',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
              ),
            ),
            const SizedBox(height: 8),
            const Center(
              child: Text(
                'Ikuti pecinta film lain di tab Discover Cinephiles untuk melihat ulasan dan rating mereka di sini!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 13, height: 1.4),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton.icon(
                onPressed: () => _tabController.animateTo(1),
                icon: const Icon(Icons.search, size: 16),
                label: const Text('Cari Teman Cinephile'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentRed,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadActivities,
      color: accentRed,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        itemCount: _activities.length,
        itemBuilder: (context, index) {
          final act = _activities[index];
          return _buildActivityCard(act, accentRed, bgCard);
        },
      ),
    );
  }

  Widget _buildActivityCard(SocialActivityItem act, Color accentRed, Color bgCard) {
    final hasReview = act.review.isNotEmpty || act.notes.isNotEmpty;
    final reviewText = act.review.isNotEmpty ? act.review : act.notes;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Avatar, Username, Action, Rating
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: accentRed.withOpacity(0.2),
                backgroundImage: act.user != null && act.user!.avatarUrl.isNotEmpty
                    ? NetworkImage(ApiService.getAvatarUrl(act.user!.avatarUrl))
                    : null,
                child: act.user == null || act.user!.avatarUrl.isEmpty
                    ? Text(
                        act.user != null && act.user!.username.isNotEmpty
                            ? act.user!.username.substring(0, 1).toUpperCase()
                            : 'C',
                        style: const TextStyle(color: Color(0xFFFF6B6B), fontWeight: FontWeight.bold),
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
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                    ),
                    Text(
                      _getActivitySubtitle(act),
                      style: const TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                  ],
                ),
              ),
              if (act.rating > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.amber.withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 14),
                      const SizedBox(width: 3),
                      Text(
                        act.rating.toStringAsFixed(1),
                        style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.w900, fontSize: 12),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Media Thumbnail & Info Box (Tappable to Detail)
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
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      width: 44,
                      height: 64,
                      color: Colors.white10,
                      child: act.movie.posterPath.isNotEmpty || act.movie.localPosterPath.isNotEmpty
                          ? Image.network(
                              ApiService.getFullImageUrl(act.movie),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(Icons.movie, color: Colors.white24),
                            )
                          : const Icon(Icons.movie, color: Colors.white24),
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
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                act.movie.mediaType.toUpperCase(),
                                style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white70),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              act.movie.releaseDate.length >= 4 ? act.movie.releaseDate.substring(0, 4) : '',
                              style: const TextStyle(color: Colors.white38, fontSize: 11),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.white38),
                ],
              ),
            ),
          ),

          // User Review Quote Box
          if (hasReview) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(6),
                  bottomRight: Radius.circular(6),
                ),
                border: Border(left: BorderSide(color: accentRed, width: 3)),
              ),
              child: Text(
                '"$reviewText"',
                style: const TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.white70,
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
      return 'memberikan ulasan & rating';
    }
    if (act.status == 'completed') {
      return 'selesai menonton';
    }
    if (act.status == 'watching') {
      if (act.movie.mediaType == 'tv' && act.episodesWatched > 0) {
        return 'sedang menonton (Eps ${act.episodesWatched})';
      }
      return 'sedang menonton';
    }
    if (act.favorite) {
      return 'menambahkan ke favorit';
    }
    return 'mencatat tontonan';
  }

  Widget _buildDiscoverTab(Color accentRed, Color bgSurface, Color bgCard) {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(14),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Cari username atau bio...',
              hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
              prefixIcon: const Icon(Icons.search, color: Colors.white38, size: 20),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.white38, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        _loadUsers();
                      },
                    )
                  : null,
              filled: true,
              fillColor: bgSurface,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: accentRed),
              ),
            ),
            onChanged: (val) {
              _loadUsers(val.trim());
            },
          ),
        ),

        // User list
        Expanded(
          child: _isLoadingUsers
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFE50914)))
              : _users.isEmpty
                  ? Center(
                      child: Text(
                        _searchController.text.isNotEmpty ? 'Tidak ada user ditemukan' : 'Belum ada profil publik',
                        style: const TextStyle(color: Colors.white54),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => _loadUsers(_searchController.text.trim()),
                      color: accentRed,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        itemCount: _users.length,
                        itemBuilder: (context, index) {
                          final user = _users[index];
                          return _buildUserCard(user, accentRed, bgCard);
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildUserCard(CommunityUser user, Color accentRed, Color bgCard) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: accentRed.withOpacity(0.2),
                backgroundImage: user.avatarUrl.isNotEmpty
                    ? NetworkImage(ApiService.getAvatarUrl(user.avatarUrl))
                    : null,
                child: user.avatarUrl.isEmpty
                    ? Text(
                        user.username.isNotEmpty ? user.username.substring(0, 1).toUpperCase() : 'U',
                        style: const TextStyle(color: Color(0xFFFF6B6B), fontWeight: FontWeight.bold),
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
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                    ),
                    if (user.bio.isNotEmpty)
                      Text(
                        user.bio,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white54, fontSize: 11),
                      ),
                  ],
                ),
              ),
              if (!user.isSelf)
                ElevatedButton(
                  onPressed: () => _toggleFollow(user),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: user.isFollowing ? Colors.green.withOpacity(0.2) : accentRed,
                    foregroundColor: user.isFollowing ? Colors.greenAccent : Colors.white,
                    side: user.isFollowing ? const BorderSide(color: Colors.greenAccent, width: 0.8) : null,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: const Size(60, 32),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: Text(
                    user.isFollowing ? 'Following ✓' : '+ Follow',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          // Stats Row
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
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
          style: const TextStyle(fontSize: 8, color: Colors.white38, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
