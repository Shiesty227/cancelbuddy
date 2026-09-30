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

  // Dark colours (navy, slate, brown) are hard
  // to read on a dark background, so lighten
  // them in dark mode.
  ServiceStyle forBrightness(
    Brightness brightness,
  ) {
    if (brightness == Brightness.light) {
      return this;
    }

    final hsl = HSLColor.fromColor(color);

    final readable = hsl.lightness < 0.7
        ? hsl.withLightness(0.7).toColor()
        : color;

    return ServiceStyle(
      icon: icon,
      color: readable,
      backgroundColor:
          readable.withValues(alpha: 0.16),
    );
  }
}

// Styles are picked by generic keywords in the name
// (household bills) or by the user's chosen category.
// No brand names are referenced on purpose.
ServiceStyle serviceStyle(
  String name,
  String category,
) {
  final billStyle =
      _billStyle(name.trim().toLowerCase());

  if (billStyle != null) {
    return billStyle;
  }

  switch (category.trim().toLowerCase()) {
    case 'entertainment':
      return const ServiceStyle(
        icon: Icons.movie_rounded,
        color: Color(0xFFE53935),
        backgroundColor: Color(0x1AE53935),
      );

    case 'music':
      return const ServiceStyle(
        icon: Icons.music_note_rounded,
        color: Color(0xFF43A047),
        backgroundColor: Color(0x1A43A047),
      );

    case 'ai':
      return const ServiceStyle(
        icon: Icons.auto_awesome_rounded,
        color: Color(0xFF8E24AA),
        backgroundColor: Color(0x1A8E24AA),
      );

    case 'software':
      return const ServiceStyle(
        icon: Icons.design_services_rounded,
        color: Color(0xFF3949AB),
        backgroundColor: Color(0x1A3949AB),
      );

    case 'cloud':
    case 'cloud storage':
      return const ServiceStyle(
        icon: Icons.cloud_rounded,
        color: Color(0xFF1E88E5),
        backgroundColor: Color(0x1A1E88E5),
      );

    case 'gaming':
      return const ServiceStyle(
        icon: Icons.sports_esports_rounded,
        color: Color(0xFF00897B),
        backgroundColor: Color(0x1A00897B),
      );

    case 'fitness':
      return const ServiceStyle(
        icon: Icons.fitness_center_rounded,
        color: Color(0xFFFF6F00),
        backgroundColor: Color(0x1AFF6F00),
      );

    case 'news & reading':
      return const ServiceStyle(
        icon: Icons.menu_book_rounded,
        color: Color(0xFF6D4C41),
        backgroundColor: Color(0x1A6D4C41),
      );

    case 'bills':
      return const ServiceStyle(
        icon: Icons.receipt_rounded,
        color: Color(0xFF546E7A),
        backgroundColor: Color(0x1A546E7A),
      );

    default:
      return const ServiceStyle(
        icon: Icons.receipt_long_rounded,
        color: Color(0xFF5E6AD2),
        backgroundColor: Color(0x1A5E6AD2),
      );
  }
}

ServiceStyle? _billStyle(String lower) {
  switch (lower) {
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
    case 'internet':
      return const ServiceStyle(
        icon: Icons.wifi_rounded,
        color: Color(0xFF00A896),
        backgroundColor: Color(0x1A00A896),
      );

    case 'mobile phone':
    case 'phone':
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
    case 'home insurance':
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
      return null;
  }
}
