import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import '../../core/constants/app_colors.dart';
import '../main_navigation.dart';
import '../../core/theme/typography.dart';

class WelcomeDisclaimerScreen extends StatelessWidget {
  const WelcomeDisclaimerScreen({super.key});

  void _handleAgree(BuildContext context) {
    // Navigate to main app
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const MainNavigation()),
      (route) => false,
    );
  }

  void _handleDecline(BuildContext context) {
    // Show confirmation dialog before exiting
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Exit App?',
          style: TextStyle(
            fontFamily: AppTypography.primaryFontFamily,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to exit Mirei?',
          style: TextStyle(fontFamily: AppTypography.primaryFontFamily),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontFamily: AppTypography.primaryFontFamily,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              exit(0); // Exit the app
            },
            child: Text(
              'Exit',
              style: TextStyle(
                fontFamily: AppTypography.primaryFontFamily,
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),

              // Heart icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(Icons.favorite, size: 30, color: AppColors.primary),
              ),

              const SizedBox(height: 24),

              // Subtitle
              Text(
                'Our community commitment',
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontSize: 16, fontWeight: FontWeight.w500)
                    .apply(color: AppColors.textSecondary),
              ),

              const SizedBox(height: 12),

              // Main title
              Text(
                'Mirei is more than a mental wellness app, it\'s a shared journey.',
                style: Theme.of(context).textTheme.headlineLarge
                    ?.copyWith(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    )
                    .apply(color: Colors.black),
              ),

              const SizedBox(height: 32),

              // Community guidelines text
              Text(
                'To keep this space safe, kind, and welcoming, we ask you to agree to the following:',
                style: Theme.of(context).textTheme.bodyLarge
                    ?.copyWith(fontSize: 16, height: 1.5)
                    .apply(color: AppColors.textSecondary),
              ),

              const SizedBox(height: 24),

              // Guidelines
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'I agree to use Mirei with respect — honoring different perspectives, experiences, and healing journeys. I will treat all fellow users and the community with kindness, without bias or judgment — regardless of background, beliefs, identity, or mental health status.',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(fontSize: 16, height: 1.6)
                              .apply(color: Colors.black87),
                        ),

                        const SizedBox(height: 20),

                        // Learn More link
                        GestureDetector(
                          onTap: () {
                            // Show more detailed community guidelines
                            _showDetailedGuidelines(context);
                          },
                          child: Text(
                            'Learn More',
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.underline,
                                )
                                .apply(color: AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Agree and Continue button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => _handleAgree(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(
                      0xFFFF6B35,
                    ), // Orange color from the image
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Agree and Continue',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Decline button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: () => _handleDecline(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: BorderSide(color: Colors.grey[300]!),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Decline',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetailedGuidelines(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Community Guidelines',
          style: TextStyle(
            fontFamily: AppTypography.primaryFontFamily,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildGuidelineItem(
                '🤝',
                'Be respectful and supportive of others\' mental health journeys',
                context,
              ),
              _buildGuidelineItem(
                '💬',
                'Share experiences constructively and avoid giving medical advice',
                context,
              ),
              _buildGuidelineItem(
                '🔒',
                'Respect privacy and confidentiality of personal stories',
                context,
              ),
              _buildGuidelineItem(
                '🌟',
                'Encourage positivity while acknowledging struggles',
                context,
              ),
              _buildGuidelineItem(
                '🚫',
                'No harassment, discrimination, or harmful content',
                context,
              ),
              _buildGuidelineItem(
                '💝',
                'Practice self-care and encourage others to do the same',
                context,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Got it',
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600)
                  .apply(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuidelineItem(String emoji, String text, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(fontSize: 14, height: 1.4)
                  .apply(color: Colors.black87),
            ),
          ),
        ],
      ),
    ); 
  }
}
