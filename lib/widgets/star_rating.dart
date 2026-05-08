import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StarRating extends StatelessWidget {
  final double rating;
  final int count;
  final double size;
  const StarRating({
    super.key,
    required this.rating,
    this.count = 0,
    this.size = 14,
  });

  @override
  Widget build(BuildContext context) {
    if (rating == 0) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(5, (i) {
          final filled = i < rating.floor();
          final half = !filled && i < rating;
          return Icon(
            filled
                ? Icons.star_rounded
                : half
                ? Icons.star_half_rounded
                : Icons.star_outline_rounded,
            color: AppTheme.amber,
            size: size,
          );
        }),
        if (count > 0) ...[
          const SizedBox(width: 4),
          Text(
            '($count)',
            style: TextStyle(color: AppTheme.textLight, fontSize: size - 2),
          ),
        ],
      ],
    );
  }
}

class InteractiveStarRating extends StatefulWidget {
  final double initial;
  final ValueChanged<double> onChanged;
  const InteractiveStarRating({
    super.key,
    this.initial = 0,
    required this.onChanged,
  });

  @override
  State<InteractiveStarRating> createState() => _InteractiveStarRatingState();
}

class _InteractiveStarRatingState extends State<InteractiveStarRating> {
  late double _rating;
  @override
  void initState() {
    super.initState();
    _rating = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (i) {
        return GestureDetector(
          onTap: () {
            setState(() => _rating = i + 1.0);
            widget.onChanged(_rating);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              i < _rating ? Icons.star_rounded : Icons.star_outline_rounded,
              color: AppTheme.amber,
              size: 36,
            ),
          ),
        );
      }),
    );
  }
}
