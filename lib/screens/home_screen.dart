import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hbbh/screens/spot_details_page.dart';
import 'package:hbbh/services/bookmark_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> allSpots = [];
  List<dynamic> displayedSpots = [];
  bool isLoading = true;
  String selectedCategory = 'All';
  final TextEditingController _searchController = TextEditingController();
  final BookmarkService _bookmarkService = BookmarkService();

  // Constants for consistent spacing
  final double kPagePadding = 16.0;
  final double kSpacingSmall = 8.0;
  final double kSpacingMedium = 16.0;
  final double kSpacingLarge = 24.0;
  final double kBorderRadius = 12.0;

  @override
  void initState() {
    super.initState();
    loadSpots();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> loadSpots() async {
    try {
      final String response =
          await rootBundle.loadString('assets/spots_data.json');
      final data = await json.decode(response);
      setState(() {
        allSpots = data['spots'];
        displayedSpots = allSpots;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading spots: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _handleSearch(String searchTerm) {
    setState(() {
      if (searchTerm.trim().isEmpty) {
        // If search is empty, show all spots for the selected category
        if (selectedCategory == 'All') {
          displayedSpots = allSpots;
        } else {
          displayedSpots = allSpots
              .where((spot) => spot['type'] == selectedCategory)
              .toList();
        }
      } else {
        // Search through spots
        List<dynamic> searchResults = allSpots.where((spot) {
          // Convert all searchable fields to a single string for searching
          final String searchableText = '''
          ${spot['name']} 
          ${spot['type']} 
          ${spot['description']} 
          ${(spot['tags'] as List).join(' ')}
        '''
              .toLowerCase();

          // Split search term into words and check if all words are present
          final searchTerms = searchTerm.toLowerCase().split(' ');
          return searchTerms.every((term) => searchableText.contains(term));
        }).toList();

        // Apply category filter if needed
        if (selectedCategory != 'All') {
          searchResults = searchResults
              .where((spot) => spot['type'] == selectedCategory)
              .toList();
        }

        displayedSpots = searchResults;
      }
    });
  }

  void filterSpots(String category) {
    setState(() {
      selectedCategory = category;
      // Re-run the search with the current search term to apply both filters
      _handleSearch(_searchController.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            _buildSearchBar(),
            _buildCategoryFilters(),
            SizedBox(height: kSpacingMedium),
            Expanded(
              child: RefreshIndicator(
                onRefresh: loadSpots,
                child: CustomScrollView(
                  slivers: [
                    if (isLoading)
                      SliverFillRemaining(
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (displayedSpots.isEmpty)
                      SliverFillRemaining(
                        child: Center(child: Text('No spots found')),
                      )
                    else ...[
                      _buildFeaturedSpots(),
                      _buildForYouSpots(),
                      _buildCheapEatsSpots(),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: kPagePadding,
        vertical: kSpacingSmall,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Explore',
            style: GoogleFonts.ibmPlexSans(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: Icon(Icons.notifications_none),
            onPressed: () {},
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: kPagePadding,
        vertical: kSpacingSmall,
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          // This will trigger instantly when text changes
          _handleSearch(value);
        },
        decoration: InputDecoration(
          hintText: 'Search...',
          prefixIcon: Icon(Icons.search, size: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(kBorderRadius),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(kBorderRadius),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(kBorderRadius),
            borderSide: BorderSide(color: Theme.of(context).primaryColor),
          ),
          filled: true,
          fillColor: Colors.grey[50],
          contentPadding: EdgeInsets.symmetric(
            horizontal: kSpacingMedium,
            vertical: kSpacingSmall,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilters() {
    List<String> categories = [
      'All',
      'Cafe',
      'Restaurant',
      'Shopping',
      'Entertainment'
    ];
    return Container(
      height: 40,
      margin: EdgeInsets.only(top: kSpacingSmall),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: kPagePadding),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          bool isSelected = selectedCategory == categories[index];
          return GestureDetector(
            onTap: () => filterSpots(categories[index]),
            child: Container(
              margin: EdgeInsets.only(right: kSpacingSmall),
              padding: EdgeInsets.symmetric(
                horizontal: kSpacingMedium,
                vertical: kSpacingSmall,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(kBorderRadius),
                border: Border.all(
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : Colors.grey[300]!,
                  width: 1,
                ),
              ),
              child: Text(
                categories[index],
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeaturedSpots() {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(kPagePadding),
            child: Text(
              'Featured Spots',
              style: GoogleFonts.ibmPlexSans(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(
            height: 292,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: kPagePadding),
              itemCount: displayedSpots.length,
              itemBuilder: (context, index) {
                return _buildSpotCard(displayedSpots[index], large: true);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForYouSpots() {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(kPagePadding),
            child: Text(
              'For You',
              style: GoogleFonts.ibmPlexSans(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(
            height: 232,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: kPagePadding),
              itemCount: displayedSpots.length,
              itemBuilder: (context, index) {
                return _buildSpotCard(displayedSpots[index], large: false);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheapEatsSpots() {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(kPagePadding),
            child: Text(
              'Cheap Eats Near You',
              style: GoogleFonts.ibmPlexSans(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(
            height: 122,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: kPagePadding),
              itemCount: displayedSpots.length,
              itemBuilder: (context, index) {
                return _buildCircularSpotCard(displayedSpots[index]);
              },
            ),
          ),
          SizedBox(height: kSpacingLarge),
        ],
      ),
    );
  }

  Widget _buildSpotCard(dynamic spot, {bool large = false}) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SpotDetailsPage(spot: spot),
          ),
        ).then((_) => setState(
            () {})); // Refresh the state when returning from SpotDetailsPage
      },
      child: Container(
        width: large ? 280 : 180,
        margin: EdgeInsets.only(right: kSpacingMedium),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[200]!),
          borderRadius: BorderRadius.circular(kBorderRadius),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(kBorderRadius),
                topRight: Radius.circular(kBorderRadius),
              ),
              child: Stack(
                children: [
                  Image.asset(
                    spot['image'],
                    height: large ? 180 : 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: large ? 180 : 120,
                        width: double.infinity,
                        color: Colors.grey[200],
                        child: Icon(Icons.image, color: Colors.grey[400]),
                      );
                    },
                  ),
                  Positioned(
                    top: kSpacingSmall,
                    right: kSpacingSmall,
                    child: FutureBuilder<bool>(
                      future: _bookmarkService.isBookmarked(spot['id']),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Container(
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius:
                                  BorderRadius.circular(kBorderRadius),
                            ),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Theme.of(context).primaryColor),
                              ),
                            ),
                          );
                        }
                        final isBookmarked = snapshot.data ?? false;
                        return GestureDetector(
                          onTap: () async {
                            await _bookmarkService.toggleBookmark(spot['id']);
                            setState(() {});
                          },
                          child: Container(
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius:
                                  BorderRadius.circular(kBorderRadius),
                            ),
                            child: Icon(
                              isBookmarked
                                  ? Icons.bookmark
                                  : Icons.bookmark_border,
                              size: 20,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(kSpacingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    spot['name'],
                    style: GoogleFonts.ibmPlexSans(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: kSpacingSmall),
                  Row(
                    children: [
                      Icon(
                        Icons.star,
                        size: 16,
                        color: Theme.of(context).primaryColor,
                      ),
                      SizedBox(width: 4),
                      Text(
                        spot['rating'].toString(),
                        style: TextStyle(fontSize: 14),
                      ),
                      SizedBox(width: kSpacingSmall),
                      Text(
                        spot['priceRange'],
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    spot['type'],
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
      ),
    );
  }

  Widget _buildCircularSpotCard(dynamic spot) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SpotDetailsPage(spot: spot),
          ),
        );
      },
      child: Container(
        width: 80,
        margin: EdgeInsets.only(right: kSpacingMedium),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(40),
              child: Image.asset(
                spot['image'],
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: Icon(Icons.image, color: Colors.grey[400]),
                  );
                },
              ),
            ),
            SizedBox(height: kSpacingSmall),
            Text(
              spot['name'],
              style: GoogleFonts.ibmPlexSans(
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
