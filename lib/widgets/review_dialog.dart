// lib/widgets/review_dialog.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/review_service.dart';
import '../services/auth_service.dart';

class ReviewDialog extends StatefulWidget {
  final String spotId;
  final String spotName;
  final Function() onReviewAdded;

  const ReviewDialog({
    Key? key,
    required this.spotId,
    required this.spotName,
    required this.onReviewAdded,
  }) : super(key: key);

  @override
  _ReviewDialogState createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<ReviewDialog> {
  final _reviewController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _reviewService = ReviewService();
  final _authService = AuthService();

  double _rating = 0;
  bool _isLoading = false;

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (!_formKey.currentState!.validate()) return;
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a rating')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userData = await _authService.getUserData();
      final userName = userData['name'] ?? 'Anonymous';

      await _reviewService.addReview(
        spotId: widget.spotId,
        text: _reviewController.text.trim(),
        rating: _rating,
        userName: userName,
      );

      if (mounted) {
        widget.onReviewAdded();
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Review added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding review: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Review ${widget.spotName}',
                  style: GoogleFonts.ibmPlexSans(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      icon: Icon(
                        index < _rating ? Icons.star : Icons.star_border,
                        color: Theme.of(context).primaryColor,
                        size: 32,
                      ),
                      onPressed: () {
                        setState(() => _rating = index + 1);
                      },
                    );
                  }),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _reviewController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'Your Review',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your review';
                    }
                    if (value.length < 10) {
                      return 'Review must be at least 10 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submitReview,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Submit Review'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
