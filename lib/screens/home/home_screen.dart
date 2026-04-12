import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:greenfield_club/models/banner.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../providers/providers.dart';
import '../../models/models.dart';
import '../../widgets/shared_widgets.dart';
import '../booking/book_ground_screen.dart';
import '../feedback/feedback_screen.dart';
import '../fund/fundraiser_screen.dart';
import '../contact/contact_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _bannerCtrl = PageController();
  int _bannerIdx = 0;

  @override
  void initState() {
    super.initState();
    // Auto-advance banner
    Future.delayed(const Duration(seconds: 1), _autoBanner);
  }

  void _autoBanner() {
    if (!mounted) return;
    final banners = ref.read(bannersProvider).valueOrNull ?? [];
    if (banners.length > 1 && _bannerCtrl.hasClients) {
      final next = (_bannerIdx + 1) % banners.length;
      _bannerCtrl.animateToPage(
        next,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
    Future.delayed(const Duration(seconds: 3), _autoBanner);
  }

  @override
  void dispose() {
    _bannerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentAppUserProvider).valueOrNull;
    final _rawBanners = ref.watch(bannersProvider).valueOrNull;
    final banners = (_rawBanners == null || _rawBanners.isEmpty)
        ? _defaultBanners()
        : _rawBanners;
    final news = ref.watch(newsProvider).valueOrNull ?? [];
    final myBookings = ref.watch(userBookingsProvider).valueOrNull ?? [];

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: CustomScrollView(
        slivers: [
          // ── App Bar ──
          SliverAppBar(
            expandedHeight: 0,
            pinned: true,
            backgroundColor: AppColors.forest,
            title: Row(
              children: [
                // const SizedBox(width: 8),
                Image.asset("assets/logo.png",width: 25,height: 25,),
                const SizedBox(width: 8),
                const Text('Edathara Samskarika Samithi',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                const Spacer(),
                if (user != null)
                  GestureDetector(
                    onTap: () => _showProfile(context),
                    child: UserAvatar(name: user.name, photoUrl: user.photoUrl),
                  ),
              ],
            ),
            automaticallyImplyLeading: false,
          ),

          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Greeting ──
                Container(
                  color: AppColors.forest,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Good ${_greeting()},',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7), fontSize: 13,
                            ),
                          ),
                          Text(
                            user?.name.split(' ').first ?? 'Member',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      if (user?.isAdmin == true)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.gold,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('ADMIN',
                              style: TextStyle(
                                  color: AppColors.ink, fontSize: 11, fontWeight: FontWeight.w800)),
                        ),
                    ],
                  ),
                ),

                // ── Banner Slider ──
                Container(
                  color: AppColors.forest,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 150,
                        child: PageView.builder(
                          controller: _bannerCtrl,
                          onPageChanged: (i) => setState(() => _bannerIdx = i),
                          itemCount: banners.length,
                          itemBuilder: (_, i) => _buildBannerCard(banners[i]),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SmoothPageIndicator(
                        controller: _bannerCtrl,
                        count: banners.length,
                        effect: WormEffect(
                          dotHeight: 6, dotWidth: 6,
                          activeDotColor: AppColors.mint,
                          dotColor: Colors.white.withOpacity(0.3),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Quick Actions ──
                      _QuickActions().animate().fadeIn(delay: 100.ms),
                      const SizedBox(height: 24),

                      // ── My Bookings ──
                      if (myBookings.isNotEmpty) ...[
                        const SectionHeader(title: 'Upcoming Bookings'),
                        const SizedBox(height: 12),
                        ...myBookings.map((b) => _BookingCard(booking: b)),
                        const SizedBox(height: 24),
                      ],

                      // ── News Feed ──
                      SectionHeader(
                        title: 'Latest News',
                        action: user?.isAdmin == true ? '+ Post' : null,
                        onAction: () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => const PostNewsScreen(),
                        )),
                      ),
                      const SizedBox(height: 12),
                      if (news.isEmpty)
                        const EmptyState(
                          emoji: '📰',
                          title: 'No news yet',
                          subtitle: 'Admin will post news and updates here',
                        )
                      else
                        ...news.asMap().entries.map((e) =>
                          _NewsCard(post: e.value, index: e.key)
                              .animate().fadeIn(delay: (e.key * 80).ms).slideY(begin: 0.1)
                        ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerCard(BannerModel b) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: hexToColor(b.colorHex),
        image: b.imageUrl != null
            ? DecorationImage(
                image: NetworkImage(b.imageUrl!),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.35), BlendMode.darken,
                ),
              )
            : null,
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            b.title,
            style: const TextStyle(
              color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800,
              shadows: [Shadow(color: Colors.black38, blurRadius: 8)],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            b.subtitle,
            style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13),
          ),
        ],
      ),
    );
  }

  List<BannerModel> _defaultBanners() => [
    BannerModel(id: '1', title: 'Welcome to Edathara Samskarika Samithi',
        subtitle: 'Book your slot in seconds', colorHex: '#0D2B1F', sortOrder: 0),
    // BannerModel(id: '2', title: 'Annual Sports Meet 2025',
    //     subtitle: 'Register now — limited slots', colorHex: '#1A3A6C', sortOrder: 1),
  ];

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'morning';
    if (h < 17) return 'afternoon';
    return 'evening';
  }

  void _showProfile(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _ProfileSheet(ref: ref),
    );
  }
}

// ─── Quick Actions Grid ────────────────────────────────────────────────────────
class _QuickActions extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actions = [
      _QA(emoji: '🏅', label: 'Book Slot',    color: AppColors.mint,
          dest: const BookGroundScreen()),
      _QA(emoji: '💬', label: 'Feedback',     color: AppColors.info,
          dest: const FeedbackScreen()),
      _QA(emoji: '💰', label: 'Fund Raising', color: AppColors.gold,
          dest: const FundraiserScreen()),
      _QA(emoji: '📞', label: 'Contacts',     color: AppColors.slate,
          dest: const ContactScreen()),
    ];
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8, crossAxisSpacing: 8,
      children: actions.map((a) => _QuickActionTile(qa: a)).toList(),
    );
  }
}

class _QA {
  final String emoji, label;
  final Color color;
  final Widget dest;
  const _QA({required this.emoji, required this.label,
      required this.color, required this.dest});
}

class _QuickActionTile extends StatelessWidget {
  final _QA qa;
  const _QuickActionTile({required this.qa});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => qa.dest)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: qa.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: qa.color.withOpacity(0.3)),
            ),
            alignment: Alignment.center,
            child: Text(qa.emoji, style: const TextStyle(fontSize: 24)),
          ),
          const SizedBox(height: 6),
          Text(qa.label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                  color: AppColors.slate),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ─── Booking Card ─────────────────────────────────────────────────────────────
class _BookingCard extends StatelessWidget {
  final Booking booking;
  const _BookingCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04),
              blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 4, height: 70,
            decoration: BoxDecoration(
              color: AppColors.mint,
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Text(booking.groundIcon, style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(booking.groundName,
                            style: const TextStyle(fontWeight: FontWeight.w700,
                                fontSize: 14, color: AppColors.ink)),
                        const SizedBox(height: 2),
                        Text(
                          '${DateFormat('EEE, d MMM').format(booking.date)} · ${booking.slot}',
                          style: const TextStyle(fontSize: 12, color: AppColors.slate),
                        ),
                      ],
                    ),
                  ),
                  const StatusPill(label: 'Confirmed', color: AppColors.mint),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── News Card ────────────────────────────────────────────────────────────────
class _NewsCard extends ConsumerWidget {
  final NewsPost post;
  final int index;
  const _NewsCard({required this.post, required this.index});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentAppUserProvider).valueOrNull;
    final isLiked = user != null && post.isLikedBy(user.uid);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (post.imageUrl != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              child: AppNetworkImage(url: post.imageUrl, height: 180, radius: 0),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Author row
                Row(
                  children: [
                    UserAvatar(name: post.authorName, size: 32),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(post.authorName,
                            style: const TextStyle(fontSize: 13,
                                fontWeight: FontWeight.w600, color: AppColors.ink)),
                        Text(
                          DateFormat('d MMM · h:mm a').format(post.createdAt),
                          style: const TextStyle(fontSize: 11, color: AppColors.slate),
                        ),
                      ],
                    ),
                    const Spacer(),
                    if (user?.isAdmin == true)
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                        onPressed: () async {
                          await ref.read(firestoreServiceProvider).deleteNews(post.id);
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(post.title,
                    style: const TextStyle(fontSize: 15,
                        fontWeight: FontWeight.w700, color: AppColors.ink)),
                const SizedBox(height: 4),
                Text(post.body,
                    style: const TextStyle(fontSize: 13,
                        color: AppColors.slate, height: 1.5)),
                const SizedBox(height: 12),
                // Like button
                GestureDetector(
                  onTap: user == null ? null : () {
                    ref.read(firestoreServiceProvider).toggleLike(post.id, user.uid);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isLiked
                          ? AppColors.error.withOpacity(0.1)
                          : AppColors.mist,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isLiked
                            ? AppColors.error.withOpacity(0.4)
                            : AppColors.border,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isLiked ? Icons.favorite : Icons.favorite_border,
                          color: isLiked ? AppColors.error : AppColors.slate,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text('${post.likeCount}',
                            style: TextStyle(
                              color: isLiked ? AppColors.error : AppColors.slate,
                              fontWeight: FontWeight.w600, fontSize: 13,
                            )),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Profile Sheet ────────────────────────────────────────────────────────────
class _ProfileSheet extends StatelessWidget {
  final WidgetRef ref;
  const _ProfileSheet({required this.ref});

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentAppUserProvider).valueOrNull;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4,
              decoration: BoxDecoration(color: AppColors.border,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          UserAvatar(name: user?.name ?? '', size: 64),
          const SizedBox(height: 12),
          Text(user?.name ?? '', style: Theme.of(context).textTheme.headlineSmall),
          Text(user?.phone.isNotEmpty == true ? user!.phone : '',
              style: const TextStyle(color: AppColors.slate, fontSize: 13)),
          if (user?.isAdmin == true) ...[
            const SizedBox(height: 8),
            const StatusPill(label: 'ADMIN', color: AppColors.gold),
          ],
          const SizedBox(height: 24),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.error),
            title: const Text('Sign Out',
                style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600)),
            onTap: () async {
              Navigator.pop(context);
              await ref.read(authServiceProvider).signOut();
            },
          ),
        ],
      ),
    );
  }
}

// ─── Post News Screen ─────────────────────────────────────────────────────────
class PostNewsScreen extends ConsumerStatefulWidget {
  const PostNewsScreen({super.key});

  @override
  ConsumerState<PostNewsScreen> createState() => _PostNewsScreenState();
}

class _PostNewsScreenState extends ConsumerState<PostNewsScreen> {
  final _titleCtrl = TextEditingController();
  final _bodyCtrl  = TextEditingController();
  File? _image;
  bool _isLoading = false;

  @override
  void dispose() { _titleCtrl.dispose(); _bodyCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentAppUserProvider).valueOrNull;
    return Scaffold(
      appBar: AppBar(title: const Text('Post News')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: 'Headline'),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _bodyCtrl,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Content',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () async {
                final x = await ImagePicker().pickImage(
                    source: ImageSource.gallery, imageQuality: 75);
                if (x != null) setState(() => _image = File(x.path));
              },
              child: Container(
                height: _image != null ? 160 : 56,
                width: double.infinity,
                decoration: BoxDecoration(
                    color: AppColors.mist,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border)),
                clipBehavior: Clip.antiAlias,
                child: _image != null
                  ? Stack(fit: StackFit.expand, children: [
                      Image.file(_image!, fit: BoxFit.cover),
                      Positioned(top: 8, right: 8, child: GestureDetector(
                        onTap: () => setState(() => _image = null),
                        child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                                color: Colors.black54, shape: BoxShape.circle),
                            child: const Icon(Icons.close,
                                color: Colors.white, size: 14)),
                      )),
                    ])
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate_outlined,
                            color: AppColors.slate, size: 20),
                        SizedBox(width: 8),
                        Text('Attach image (optional)',
                            style: TextStyle(
                                color: AppColors.slate, fontSize: 13)),
                      ]),
              ),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Publish News',
              fullWidth: true,
              isLoading: _isLoading,
              icon: Icons.send_outlined,
              onPressed: () async {
                if (_titleCtrl.text.isEmpty || _bodyCtrl.text.isEmpty) return;
                setState(() => _isLoading = true);
                await ref.read(firestoreServiceProvider).addNews(
                  title: _titleCtrl.text.trim(),
                  body: _bodyCtrl.text.trim(),
                  authorId: user!.uid,
                  authorName: user.name,
                  imageFile: _image,
                );
                if (mounted) {
                  Navigator.pop(context);
                  showSuccess(context, 'News published!');
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
