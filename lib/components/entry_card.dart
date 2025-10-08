import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/realm_models.dart';
import '../core/constants/app_colors.dart';

class EntryCard extends StatelessWidget {
  final JournalEntryRealm entry;
  final VoidCallback? onTap;

  const EntryCard({super.key, required this.entry, this.onTap});

  @override
  Widget build(BuildContext context) {
    // Format date as proper date (e.g., "Dec 15, 2024")
    final String formattedDate = DateFormat(
      'MMM d, yyyy',
    ).format(entry.createdAt.toLocal());

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Content preview card
          Container(
            width: double.infinity,
            height: 180,
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    entry.content.isNotEmpty
                        ? entry.content
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
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Title below card
          Text(
            entry.title.isNotEmpty ? entry.title : 'Untitled Entry',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge
                ?.copyWith(fontSize: 16, fontWeight: FontWeight.w600)
                .apply(color: AppColors.primary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          // Date below title
          Text(
            formattedDate,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(fontSize: 12, fontWeight: FontWeight.w500, height: 2)
                .apply(color: AppColors.secondary),
          ),
        ],
      ),
    );
  }
}
