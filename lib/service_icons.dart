import 'package:flutter/material.dart';

class ServiceStyle {
  final IconData icon;
  final Color color;
  final Color backgroundColor;

  const ServiceStyle({
    required this.icon,
    required this.color,
    required this.backgroundColor,
  });
}

ServiceStyle serviceStyle(String name) {
  final lower = name.trim().toLowerCase();

  switch (lower) {
    // ENTERTAINMENT

    case 'netflix':
      return const ServiceStyle(
        icon: Icons.movie_rounded,
        color: Color(0xFFE50914),
        backgroundColor: Color(0x1AE50914),
      );

    case 'disney+':
      return const ServiceStyle(
        icon: Icons.movie_filter_rounded,
        color: Color(0xFF113CCF),
        backgroundColor: Color(0x1A113CCF),
      );

    case 'amazon prime':
      return const ServiceStyle(
        icon: Icons.shopping_bag_rounded,
        color: Color(0xFF00A8E1),
        backgroundColor: Color(0x1A00A8E1),
      );

    case 'youtube premium':
      return const ServiceStyle(
        icon: Icons.play_circle_rounded,
        color: Color(0xFFFF0000),
        backgroundColor: Color(0x1AFF0000),
      );

    case 'apple tv+':
      return const ServiceStyle(
        icon: Icons.tv_rounded,
        color: Color(0xFF000000),
        backgroundColor: Color(0x14000000),
      );

    case 'paramount+':
      return const ServiceStyle(
        icon: Icons.live_tv_rounded,
        color: Color(0xFF0064FF),
        backgroundColor: Color(0x1A0064FF),
      );

    case 'hbo max':
      return const ServiceStyle(
        icon: Icons.theaters_rounded,
        color: Color(0xFF7B2CFF),
        backgroundColor: Color(0x1A7B2CFF),
      );

    case 'crunchyroll':
      return const ServiceStyle(
        icon: Icons.animation_rounded,
        color: Color(0xFFF47521),
        backgroundColor: Color(0x1AF47521),
      );

    // MUSIC

    case 'spotify':
      return const ServiceStyle(
        icon: Icons.music_note_rounded,
        color: Color(0xFF1DB954),
        backgroundColor: Color(0x1A1DB954),
      );

    case 'apple music':
      return const ServiceStyle(
        icon: Icons.library_music_rounded,
        color: Color(0xFFFA243C),
        backgroundColor: Color(0x1AFA243C),
      );

    case 'youtube music':
      return const ServiceStyle(
        icon: Icons.music_video_rounded,
        color: Color(0xFFFF0000),
        backgroundColor: Color(0x1AFF0000),
      );

    case 'amazon music':
      return const ServiceStyle(
        icon: Icons.headphones_rounded,
        color: Color(0xFF25D1DA),
        backgroundColor: Color(0x1A25D1DA),
      );

    case 'tidal':
      return const ServiceStyle(
        icon: Icons.graphic_eq_rounded,
        color: Color(0xFF000000),
        backgroundColor: Color(0x14000000),
      );

    // AI

    case 'chatgpt plus':
      return const ServiceStyle(
        icon: Icons.auto_awesome_rounded,
        color: Color(0xFF10A37F),
        backgroundColor: Color(0x1A10A37F),
      );

    case 'claude pro':
      return const ServiceStyle(
        icon: Icons.psychology_rounded,
        color: Color(0xFFD97757),
        backgroundColor: Color(0x1AD97757),
      );

    case 'google ai pro':
      return const ServiceStyle(
        icon: Icons.smart_toy_rounded,
        color: Color(0xFF4285F4),
        backgroundColor: Color(0x1A4285F4),
      );

    case 'perplexity pro':
      return const ServiceStyle(
        icon: Icons.search_rounded,
        color: Color(0xFF20B8CD),
        backgroundColor: Color(0x1A20B8CD),
      );

    // SOFTWARE

    case 'adobe':
      return const ServiceStyle(
        icon: Icons.design_services_rounded,
        color: Color(0xFFFF0000),
        backgroundColor: Color(0x1AFF0000),
      );

    case 'microsoft 365':
      return const ServiceStyle(
        icon: Icons.grid_view_rounded,
        color: Color(0xFF5E5CE6),
        backgroundColor: Color(0x1A5E5CE6),
      );

    case 'canva':
      return const ServiceStyle(
        icon: Icons.palette_rounded,
        color: Color(0xFF00A8A8),
        backgroundColor: Color(0x1A00A8A8),
      );

    case 'notion':
      return const ServiceStyle(
        icon: Icons.notes_rounded,
        color: Color(0xFF000000),
        backgroundColor: Color(0x14000000),
      );

    case 'dropbox':
      return const ServiceStyle(
        icon: Icons.folder_rounded,
        color: Color(0xFF0061FF),
        backgroundColor: Color(0x1A0061FF),
      );

    // CLOUD STORAGE

    case 'google one':
      return const ServiceStyle(
        icon: Icons.cloud_rounded,
        color: Color(0xFF4285F4),
        backgroundColor: Color(0x1A4285F4),
      );

    case 'icloud':
      return const ServiceStyle(
        icon: Icons.cloud_queue_rounded,
        color: Color(0xFF3693F3),
        backgroundColor: Color(0x1A3693F3),
      );

    case 'onedrive':
      return const ServiceStyle(
        icon: Icons.cloud_upload_rounded,
        color: Color(0xFF0078D4),
        backgroundColor: Color(0x1A0078D4),
      );

    // GAMING

    case 'xbox game pass':
      return const ServiceStyle(
        icon: Icons.sports_esports_rounded,
        color: Color(0xFF107C10),
        backgroundColor: Color(0x1A107C10),
      );

    case 'playstation plus':
      return const ServiceStyle(
        icon: Icons.gamepad_rounded,
        color: Color(0xFF0070CC),
        backgroundColor: Color(0x1A0070CC),
      );

    case 'nintendo switch online':
      return const ServiceStyle(
        icon: Icons.videogame_asset_rounded,
        color: Color(0xFFE60012),
        backgroundColor: Color(0x1AE60012),
      );

    // FITNESS

    case 'strava':
      return const ServiceStyle(
        icon: Icons.directions_run_rounded,
        color: Color(0xFFFC4C02),
        backgroundColor: Color(0x1AFC4C02),
      );

    case 'peloton':
      return const ServiceStyle(
        icon: Icons.fitness_center_rounded,
        color: Color(0xFF000000),
        backgroundColor: Color(0x14000000),
      );

    // NEWS & READING

    case 'the new york times':
      return const ServiceStyle(
        icon: Icons.newspaper_rounded,
        color: Color(0xFF000000),
        backgroundColor: Color(0x14000000),
      );

    case 'the guardian':
      return const ServiceStyle(
        icon: Icons.article_rounded,
        color: Color(0xFF052962),
        backgroundColor: Color(0x1A052962),
      );

    case 'linkedin premium':
      return const ServiceStyle(
        icon: Icons.work_rounded,
        color: Color(0xFF0A66C2),
        backgroundColor: Color(0x1A0A66C2),
      );

    case 'amazon kindle unlimited':
      return const ServiceStyle(
        icon: Icons.menu_book_rounded,
        color: Color(0xFFFF9900),
        backgroundColor: Color(0x1AFF9900),
      );

    // BILLS

    case 'electricity':
      return const ServiceStyle(
        icon: Icons.bolt_rounded,
        color: Color(0xFFFFB300),
        backgroundColor: Color(0x1AFFB300),
      );

    case 'gas':
      return const ServiceStyle(
        icon: Icons.local_fire_department_rounded,
        color: Color(0xFFFF7043),
        backgroundColor: Color(0x1AFF7043),
      );

    case 'water':
      return const ServiceStyle(
        icon: Icons.water_drop_rounded,
        color: Color(0xFF2196F3),
        backgroundColor: Color(0x1A2196F3),
      );

    case 'council tax':
      return const ServiceStyle(
        icon: Icons.account_balance_rounded,
        color: Color(0xFF5E6AD2),
        backgroundColor: Color(0x1A5E6AD2),
      );

    case 'broadband':
      return const ServiceStyle(
        icon: Icons.wifi_rounded,
        color: Color(0xFF00A896),
        backgroundColor: Color(0x1A00A896),
      );

    case 'mobile phone':
      return const ServiceStyle(
        icon: Icons.phone_iphone_rounded,
        color: Color(0xFF7E57C2),
        backgroundColor: Color(0x1A7E57C2),
      );

    case 'tv licence':
      return const ServiceStyle(
        icon: Icons.tv_rounded,
        color: Color(0xFFE91E63),
        backgroundColor: Color(0x1AE91E63),
      );

    case 'rent':
      return const ServiceStyle(
        icon: Icons.home_rounded,
        color: Color(0xFF00897B),
        backgroundColor: Color(0x1A00897B),
      );

    case 'mortgage':
      return const ServiceStyle(
        icon: Icons.home_work_rounded,
        color: Color(0xFF3949AB),
        backgroundColor: Color(0x1A3949AB),
      );

    case 'home insurance':
      return const ServiceStyle(
        icon: Icons.home_rounded,
        color: Color(0xFF00897B),
        backgroundColor: Color(0x1A00897B),
      );

    case 'car insurance':
      return const ServiceStyle(
        icon: Icons.directions_car_rounded,
        color: Color(0xFF546E7A),
        backgroundColor: Color(0x1A546E7A),
      );

    case 'life insurance':
      return const ServiceStyle(
        icon: Icons.favorite_rounded,
        color: Color(0xFFE53935),
        backgroundColor: Color(0x1AE53935),
      );

    case 'health insurance':
      return const ServiceStyle(
        icon: Icons.health_and_safety_rounded,
        color: Color(0xFF43A047),
        backgroundColor: Color(0x1A43A047),
      );

    case 'road tax':
      return const ServiceStyle(
        icon: Icons.directions_car_filled_rounded,
        color: Color(0xFF6D4C41),
        backgroundColor: Color(0x1A6D4C41),
      );

    case 'parking':
      return const ServiceStyle(
        icon: Icons.local_parking_rounded,
        color: Color(0xFF3949AB),
        backgroundColor: Color(0x1A3949AB),
      );

    case 'gym':
      return const ServiceStyle(
        icon: Icons.fitness_center_rounded,
        color: Color(0xFFFF6F00),
        backgroundColor: Color(0x1AFF6F00),
      );

    default:
      return const ServiceStyle(
        icon: Icons.receipt_long_rounded,
        color: Color(0xFF5E6AD2),
        backgroundColor: Color(0x1A5E6AD2),
      );
  }
}

IconData serviceIcon(String name) {
  return serviceStyle(name).icon;
}

Color serviceColor(String name) {
  return serviceStyle(name).color;
}