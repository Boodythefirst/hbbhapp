import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hbbh/services/bookmark_service.dart';
import 'package:hbbh/screens/spot_details_page.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  _BookmarksScreenState createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  final BookmarkService _bookmarkService = BookmarkService();
  List<Map<String, dynamic>> _bookmarkedSpots = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadBookmarkedSpots();
  }

  Future<void> _loadBookmarkedSpots() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // First migrate any local bookmarks if needed
      await _bookmarkService.migrateLocalBookmarks();

      final String response =
          await rootBundle.loadString('assets/spots_data.json');
      final data = await json.decode(response);
      final allSpots = List<Map<String, dynamic>>.from(data['spots']);

      final bookmarkedSpots =
          await _bookmarkService.getBookmarkedSpots(allSpots);

      if (mounted) {
        setState(() {
          _bookmarkedSpots = bookmarkedSpots;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load bookmarks: ${e.toString()}'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'RETRY',
              textColor: Colors.white,
              onPressed: _loadBookmarkedSpots,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bookmarks', style: GoogleFonts.ibmPlexSans()),
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasError
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Failed to load bookmarks',
                        style: GoogleFonts.ibmPlexSans(fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadBookmarkedSpots,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _bookmarkedSpots.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.bookmark_border,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No bookmarked spots yet',
                            style: GoogleFonts.ibmPlexSans(fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Bookmark your favorite spots to see them here',
                            style: GoogleFonts.ibmPlexSans(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadBookmarkedSpots,
                      child: ListView.builder(
                        itemCount: _bookmarkedSpots.length,
                        padding: const EdgeInsets.all(16),
                        itemBuilder: (context, index) {
                          final spot = _bookmarkedSpots[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.grey[200]!),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        SpotDetailsPage(spot: spot),
                                  ),
                                ).then((_) => _loadBookmarkedSpots());
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.asset(
                                        spot['image'],
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            spot['name'],
                                            style: GoogleFonts.ibmPlexSans(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            spot['type'],
                                            style: GoogleFonts.ibmPlexSans(
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.star,
                                                size: 16,
                                                color: Theme.of(context)
                                                    .primaryColor,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                spot['rating'].toString(),
                                                style: const TextStyle(
                                                    fontSize: 14),
                                              ),
                                              const SizedBox(width: 16),
                                              Text(
                                                spot['priceRange'],
                                                style: const TextStyle(
                                                    fontSize: 14),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.bookmark),
                                      color: Theme.of(context).primaryColor,
                                      onPressed: () async {
                                        await _bookmarkService
                                            .toggleBookmark(spot['id']);
                                        _loadBookmarkedSpots();
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
