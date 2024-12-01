import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:carousel_slider/carousel_slider.dart' as carousel;
import 'package:hbbh/models/review_model.dart';
import 'package:hbbh/services/review_service.dart';
import 'package:hbbh/widgets/review_dialog.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:hbbh/services/bookmark_service.dart';

class SpotDetailsPage extends StatefulWidget {
  final Map<String, dynamic> spot;

  const SpotDetailsPage({super.key, required this.spot});

  @override
  _SpotDetailsPageState createState() => _SpotDetailsPageState();
}

class _SpotDetailsPageState extends State<SpotDetailsPage> {
  final BookmarkService _bookmarkService = BookmarkService();
  final ReviewService _reviewService = ReviewService();
  bool _isBookmarked = false;

  @override
  void initState() {
    super.initState();
    _checkBookmarkStatus();
  }

  Future<void> _checkBookmarkStatus() async {
    final isBookmarked = await _bookmarkService.isBookmarked(widget.spot['id']);
    setState(() {
      _isBookmarked = isBookmarked;
    });
  }

  void _toggleBookmark(BuildContext context) async {
    await _bookmarkService.toggleBookmark(widget.spot['id']);
    setState(() {
      _isBookmarked = !_isBookmarked;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isBookmarked ? 'Spot bookmarked' : 'Bookmark removed'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSpotInfo(context),
                const SizedBox(height: 16),
                _buildActionButtons(context),
                _buildSection(
                  title: 'About',
                  content: _buildDescription(),
                ),
                _buildSection(
                  title: 'Tags',
                  content: _buildTags(context),
                ),
                _buildSection(
                  title: 'Recent Check-ins',
                  content: _buildRecentCheckIns(context),
                ),
                _buildSection(
                  title: 'Reviews',
                  content: _buildReviews(context),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: MediaQuery.of(context).size.height * 0.3,
      pinned: true,
      backgroundColor: Theme.of(context).primaryColor,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            carousel.CarouselSlider(
              options: carousel.CarouselOptions(
                height: MediaQuery.of(context).size.height * 0.4,
                viewportFraction: 1.0,
                enlargeCenterPage: false,
                autoPlay: true,
                autoPlayInterval: const Duration(seconds: 4),
              ),
              items: (widget.spot['carousel_images'] as List<dynamic>)
                  .map((image) {
                return Builder(
                  builder: (BuildContext context) {
                    return Image.asset(
                      image,
                      fit: BoxFit.cover,
                      width: MediaQuery.of(context).size.width,
                    );
                  },
                );
              }).toList(),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.5),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      leading: _buildCircularButton(
        icon: Icons.arrow_back,
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        _buildCircularButton(
          icon: Icons.share,
          onPressed: () => _shareSpot(context),
        ),
        _buildCircularButton(
          icon: _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
          onPressed: () => _toggleBookmark(context),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildCircularButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IconButton(
          icon: Icon(icon, color: Colors.black87, size: 20),
          onPressed: onPressed,
        ),
      ),
    );
  }

  Widget _buildSpotInfo(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.spot['name'],
            style: GoogleFonts.ibmPlexSans(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Icon(Icons.star,
                    color: Theme.of(context).primaryColor, size: 20),
                const SizedBox(width: 4),
                Text(
                  widget.spot['rating'].toString(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '•',
                  style: TextStyle(color: Colors.grey[400], fontSize: 16),
                ),
                const SizedBox(width: 16),
                Text(
                  widget.spot['priceRange'],
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '•',
                  style: TextStyle(color: Colors.grey[400], fontSize: 16),
                ),
                const SizedBox(width: 16),
                Text(
                  widget.spot['type'],
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildActionButton(
            icon: Icons.directions,
            label: 'Directions',
            onTap: () {
              // Implement directions functionality
            },
          ),
          _buildActionButton(
            icon: Icons.phone,
            label: 'Call',
            onTap: () {
              // Implement call functionality
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            Icon(icon, size: 24, color: Colors.black87),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required Widget content,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            title,
            style: GoogleFonts.ibmPlexSans(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(height: 16),
        content,
      ],
    );
  }

  Widget _buildDescription() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        widget.spot['description'],
        style: TextStyle(
          fontSize: 16,
          height: 1.5,
          color: Colors.grey[800],
        ),
      ),
    );
  }

  Widget _buildTags(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: (widget.spot['tags'] as List<dynamic>).map((tag) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              tag,
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontSize: 14,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRecentCheckIns(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: (widget.spot['recentCheckIns'] as List).length,
      itemBuilder: (context, index) {
        final checkIn = widget.spot['recentCheckIns'][index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor:
                    Theme.of(context).primaryColor.withOpacity(0.2),
                child: Text(
                  checkIn['name'][0],
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      checkIn['name'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatTimestamp(checkIn['timestamp']),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
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

  Widget _buildReviews(BuildContext context) {
    return StreamBuilder<List<ReviewModel>>(
      stream: _reviewService.getSpotReviews(widget.spot['id']),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Center(
              child: Text(
                'Error loading reviews: ${snapshot.error}',
                style: TextStyle(color: Colors.red[400]),
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final reviews = snapshot.data ?? [];

        if (reviews.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Center(
              child: Text(
                'No reviews yet. Be the first to review!',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: reviews.length,
          itemBuilder: (context, index) {
            final review = reviews[index];
            return _buildReviewCard(review);
          },
        );
      },
    );
  }

  Widget _buildReviewCard(ReviewModel review) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor:
                    Theme.of(context).primaryColor.withOpacity(0.2),
                child: Text(
                  review.userName[0].toUpperCase(),
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Row(
                          children: List.generate(5, (index) {
                            return Icon(
                              index < review.rating
                                  ? Icons.star
                                  : Icons.star_border,
                              color: Theme.of(context).primaryColor,
                              size: 16,
                            );
                          }),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat.yMMMd().add_jm().format(review.createdAt),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            review.text,
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 16, 16, MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () => _checkIn(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Check In',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton(
              onPressed: () => _writeReview(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).primaryColor,
                side: BorderSide(color: Theme.of(context).primaryColor),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Write a Review',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _writeReview(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please sign in to write a review'),
          action: SnackBarAction(
            label: 'SIGN IN',
            onPressed: () => context.push('/signin'),
          ),
        ),
      );
      return;
    }

    // Check if user has already reviewed
    final hasReviewed = await _reviewService.hasUserReviewed(widget.spot['id']);

    if (hasReviewed) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You have already reviewed this spot'),
          ),
        );
      }
      return;
    }

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => ReviewDialog(
          spotId: widget.spot['id'],
          spotName: widget.spot['name'],
          onReviewAdded: () {
            // Refresh the spot details to show the new review
            setState(() {});
          },
        ),
      );
    }
  }

  String _formatTimestamp(String timestamp) {
    final dateTime = DateTime.parse(timestamp);
    final formatter = DateFormat.yMMMd().add_jm();
    return formatter.format(dateTime);
  }

  void _shareSpot(BuildContext context) {
    Share.share(
        'Check out ${widget.spot['name']} on HBBH! ${widget.spot['description']}');
  }

  void _checkIn(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Checked in at ${widget.spot['name']}!')),
    );
  }
}
