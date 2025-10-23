import 'package:flutter/material.dart';
import 'package:motor/motor.dart';
import 'package:intl/intl.dart';
import '../models/realm_models.dart';
import '../core/constants/app_colors.dart';

class EntryCard extends StatefulWidget {
  final JournalEntryRealm entry;
  final VoidCallback? onTap;

  const EntryCard({super.key, required this.entry, this.onTap});

  @override
  State<EntryCard> createState() => _EntryCardState();
}

class _EntryCardState extends State<EntryCard>
    with SingleTickerProviderStateMixin {
  late SingleMotionController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = SingleMotionController(
      motion: CupertinoMotion.snappy(), // Snappy press feedback
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Format date as proper date (e.g., "Dec 15, 2024")
    final String formattedDate = DateFormat(
      'MMM d, yyyy',
    ).format(widget.entry.createdAt.toLocal());

    return GestureDetector(
      onTapDown: (_) => _scaleController.animateTo(1.0),
      onTapUp: (_) {
        _scaleController.animateTo(0.0);
        widget.onTap?.call();
      },
      onTapCancel: () => _scaleController.animateTo(0.0),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Content preview card - flexible height
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      widget.entry.content.isNotEmpty
                          ? widget.entry.content
                          : 'No content available',
                      style: Theme.of(context).textTheme.labelSmall
                          ?.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.w400,
                            height: 1.4,
                          )
                          .apply(color: Colors.black87),
                      maxLines: 8,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Title below card (separated from card)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    widget.entry.title.isNotEmpty
                        ? widget.entry.title
                        : 'Untitled Entry',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge
                        ?.copyWith(fontSize: 14, fontWeight: FontWeight.w600)
                        .apply(color: AppColors.primary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Date below title (separated from card)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    formattedDate,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(fontSize: 11, fontWeight: FontWeight.w500)
                        .apply(color: AppColors.secondary),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
