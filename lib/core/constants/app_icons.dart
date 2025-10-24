import 'package:flutter/cupertino.dart';

/// App Icons Constants
/// Centralizes all icon definitions for consistent usage throughout the app
/// Uses Cupertino Icons as primary icon set for cross-platform consistency
class AppIcons {
  AppIcons._(); // Private constructor to prevent instantiation

  // Navigation icons
  static const IconData home = CupertinoIcons.house;
  static const IconData homeFilled = CupertinoIcons.house_fill;
  static const IconData explore = CupertinoIcons.rectangle_3_offgrid;
  static const IconData exploreFilled = CupertinoIcons.rectangle_3_offgrid_fill;
  static const IconData profile = CupertinoIcons.person;
  static const IconData profileFilled = CupertinoIcons.person_fill;
  static const IconData settings = CupertinoIcons.settings;
  static const IconData settingsFilled = CupertinoIcons.settings_solid;

  // Action icons
  static const IconData add = CupertinoIcons.add;
  static const IconData edit = CupertinoIcons.pencil;
  static const IconData delete = CupertinoIcons.delete;
  static const IconData deleteFilled = CupertinoIcons.delete_solid;
  static const IconData save = CupertinoIcons.checkmark_alt;
  static const IconData cancel = CupertinoIcons.xmark;
  static const IconData close = CupertinoIcons.xmark_circle;
  static const IconData closeFilled = CupertinoIcons.xmark_circle_fill;
  static const IconData share = CupertinoIcons.share;
  static const IconData search = CupertinoIcons.search;
  static const IconData filter = CupertinoIcons.slider_horizontal_3;
  static const IconData refresh = CupertinoIcons.refresh;
  static const IconData more = CupertinoIcons.ellipsis;
  static const IconData moreVertical = CupertinoIcons.ellipsis_vertical;

  // Journal/Writing icons
  static const IconData journal = CupertinoIcons.book;
  static const IconData journalFilled = CupertinoIcons.book_fill;
  static const IconData pen = CupertinoIcons.pencil_circle;
  static const IconData penFilled = CupertinoIcons.pencil_circle_fill;
  static const IconData note = CupertinoIcons.doc_text;
  static const IconData noteFilled = CupertinoIcons.doc_text_fill;

  // Media icons
  static const IconData camera = CupertinoIcons.camera;
  static const IconData cameraFilled = CupertinoIcons.camera_fill;
  static const IconData photo = CupertinoIcons.photo;
  static const IconData photoFilled = CupertinoIcons.photo_fill;
  static const IconData photoMultiple = CupertinoIcons.photo_on_rectangle;
  static const IconData microphone = CupertinoIcons.mic;
  static const IconData microphoneFilled = CupertinoIcons.mic_fill;
  static const IconData play = CupertinoIcons.play;
  static const IconData playFilled = CupertinoIcons.play_fill;
  static const IconData pause = CupertinoIcons.pause;
  static const IconData pauseFilled = CupertinoIcons.pause_fill;
  static const IconData stop = CupertinoIcons.stop;
  static const IconData stopFilled = CupertinoIcons.stop_fill;
  static const IconData music = CupertinoIcons.music_note;
  static const IconData musicFilled = CupertinoIcons.music_note_2;

  // Mood/Emotion icons (complementary to SVG emotion icons)
  static const IconData heart = CupertinoIcons.heart;
  static const IconData heartFilled = CupertinoIcons.heart_fill;
  static const IconData star = CupertinoIcons.star;
  static const IconData starFilled = CupertinoIcons.star_fill;
  static const IconData smiley = CupertinoIcons.smiley;
  static const IconData smileyFilled = CupertinoIcons.smiley_fill;

  // Calendar/Time icons
  static const IconData calendar = CupertinoIcons.calendar;
  static const IconData calendarFilled = CupertinoIcons.calendar_today;
  static const IconData clock = CupertinoIcons.clock;
  static const IconData clockFilled = CupertinoIcons.clock_fill;
  static const IconData time = CupertinoIcons.time;
  static const IconData timeFilled = CupertinoIcons.time_solid;

  // Navigation arrows
  static const IconData back = CupertinoIcons.back;
  static const IconData forward = CupertinoIcons.forward;
  static const IconData up = CupertinoIcons.up_arrow;
  static const IconData down = CupertinoIcons.down_arrow;
  static const IconData left = CupertinoIcons.left_chevron;
  static const IconData right = CupertinoIcons.right_chevron;

  // Status icons
  static const IconData checkmark = CupertinoIcons.checkmark;
  static const IconData checkmarkCircle = CupertinoIcons.checkmark_circle;
  static const IconData checkmarkCircleFilled =
      CupertinoIcons.checkmark_circle_fill;
  static const IconData info = CupertinoIcons.info;
  static const IconData infoFilled = CupertinoIcons.info_circle_fill;
  static const IconData warning = CupertinoIcons.exclamationmark_triangle;
  static const IconData warningFilled =
      CupertinoIcons.exclamationmark_triangle_fill;
  static const IconData error = CupertinoIcons.xmark_circle;
  static const IconData errorFilled = CupertinoIcons.xmark_circle_fill;

  // Authentication icons
  static const IconData lock = CupertinoIcons.lock;
  static const IconData lockFilled = CupertinoIcons.lock_fill;
  static const IconData unlock = CupertinoIcons.lock_open;
  static const IconData unlockFilled = CupertinoIcons.lock_open_fill;
  static const IconData eyeOn = CupertinoIcons.eye;
  static const IconData eyeOff = CupertinoIcons.eye_slash;
  static const IconData eyeOnFilled = CupertinoIcons.eye_fill;
  static const IconData eyeOffFilled = CupertinoIcons.eye_slash_fill;

  // Cloud/Sync icons
  static const IconData cloud = CupertinoIcons.cloud;
  static const IconData cloudFilled = CupertinoIcons.cloud_fill;
  static const IconData cloudUpload = CupertinoIcons.cloud_upload;
  static const IconData cloudUploadFilled = CupertinoIcons.cloud_upload_fill;
  static const IconData cloudDownload = CupertinoIcons.cloud_download;
  static const IconData cloudDownloadFilled =
      CupertinoIcons.cloud_download_fill;

  // Progress/Analytics icons
  static const IconData chart = CupertinoIcons.chart_bar;
  static const IconData chartFilled = CupertinoIcons.chart_bar_fill;
  static const IconData graph = CupertinoIcons.graph_circle;
  static const IconData graphFilled = CupertinoIcons.graph_circle_fill;

  // Meditation/Wellness icons
  static const IconData leaf = CupertinoIcons.tree;
  static const IconData sun = CupertinoIcons.sun_max;
  static const IconData sunFilled = CupertinoIcons.sun_max_fill;
  static const IconData moon = CupertinoIcons.moon;
  static const IconData moonFilled = CupertinoIcons.moon_fill;
  static const IconData sparkles = CupertinoIcons.sparkles;

  // Tag/Category icons
  static const IconData tag = CupertinoIcons.tag;
  static const IconData tagFilled = CupertinoIcons.tag_fill;
  static const IconData folder = CupertinoIcons.folder;
  static const IconData folderFilled = CupertinoIcons.folder_fill;

  // Standard icon sizes
  static const double sizeSmall = 16.0;
  static const double sizeMedium = 24.0;
  static const double sizeLarge = 32.0;
  static const double sizeExtraLarge = 48.0;

  // Semantic icon size aliases
  static const double buttonIconSize = sizeMedium; // 24
  static const double appBarIconSize = sizeMedium; // 24
  static const double listIconSize = sizeMedium; // 24
  static const double fabIconSize = sizeMedium; // 24
  static const double avatarIconSize = sizeExtraLarge; // 48
}

/// Asset paths for custom SVG icons and images
class AppAssets {
  AppAssets._(); // Private constructor to prevent instantiation

  // Emotion SVG icons
  static const String emotionAngry = 'assets/emotion-icons/angry.svg';
  static const String emotionHappy = 'assets/emotion-icons/happy.svg';
  static const String emotionNeutral = 'assets/emotion-icons/neutral.svg';
  static const String emotionSad = 'assets/emotion-icons/sad.svg';
  // Note: Add other emotion icons as they are added to assets

  // Custom icons
  static const String iconCircle = 'assets/icons/circle.svg';
  static const String iconEmphasis = 'assets/icons/emphasis.svg';
  static const String iconUnderline = 'assets/icons/underline.svg';
  static const String iconBCircle = 'assets/icons/b-circle.svg';
  static const String iconHeptagon = 'assets/icons/heptagon.svg';
  static const String iconMessage = 'assets/icons/message.svg';
  static const String iconOctagon = 'assets/icons/octagon.svg';
  static const String iconPieChart = 'assets/icons/pie-chart.svg';
  static const String iconStress = 'assets/icons/Stress.svg';

  // Images
  static const String tabbyJournal = 'assets/images/tabby_journal.png';
  static const String tabby = 'assets/images/tabby.svg';
  static const String heroClouds = 'assets/images/hero_clouds.svg';
  static const String profileHeaderLight =
      'assets/images/profile_header_light.webp';
  static const String footerNoBg = 'assets/images/footer_no_bg.webp';

  // Helper method to get emotion icon path by mood name
  static String getEmotionIconPath(String mood) {
    switch (mood.toLowerCase()) {
      case 'happy':
        return emotionHappy;
      case 'neutral':
        return emotionNeutral;
      case 'sad':
        return emotionSad;
      case 'angry':
        return emotionAngry;
      default:
        return emotionNeutral; // Default fallback
    }
  }
}
