/// Display information only; the review app does not accept food orders.
class PlaceMenuItem {
  const PlaceMenuItem({
    required this.name,
    required this.description,
    required this.price,
    this.imageUrl,
    this.label,
  });

  final String name, description;
  final int price;
  final String? imageUrl, label;
}
