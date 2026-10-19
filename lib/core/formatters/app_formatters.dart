abstract final class AppFormatters {
  static String count(int value) => '$value'.replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (match) => '${match[1]}.',
  );
  static String price(num value) {
    final digits = value.round().abs().toString();
    final grouped = digits.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
    return '${value < 0 ? "-" : ""}$groupedđ';
  }

  static String priceRange(num min, num max) => '${price(min)} - ${price(max)}';
  static String distance(double meters) => meters < 1000
      ? '${meters.round()} m'
      : '${(meters / 1000).toStringAsFixed(1)} km';
}
