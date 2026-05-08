class Device {
  final String id;
  final String title;
  final String description;
  final String category;
  final String imageUrl;
  final double pricePerDay;
  final String ownerId;
  final String city;
  final double lat;
  final double lng;
  final bool available;

  Device({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.imageUrl,
    required this.pricePerDay,
    required this.ownerId,
    this.city = '',
    required this.lat,
    required this.lng,
    required this.available,
  });

  factory Device.fromMap(Map<String, dynamic> map, String id) {
    return Device(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      pricePerDay: (map['pricePerDay'] ?? 0).toDouble(),
      ownerId: map['ownerId'] ?? '',
      city: map['city'] ?? '',
      lat: (map['lat'] ?? 0).toDouble(),
      lng: (map['lng'] ?? 0).toDouble(),
      available: map['available'] ?? true,
    );
  }

  Map<String, dynamic> toMap() => {
    'title': title,
    'description': description,
    'category': category,
    'imageUrl': imageUrl,
    'pricePerDay': pricePerDay,
    'ownerId': ownerId,
    'city': city,
    'lat': lat,
    'lng': lng,
    'available': available,
  };
}
