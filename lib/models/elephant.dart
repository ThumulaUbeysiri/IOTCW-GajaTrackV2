class Elephant {
  final String id;
  final double lat;
  final double lon;

  Elephant({required this.id, required this.lat, required this.lon});

  factory Elephant.fromMap(String id, Map<String, dynamic> map) {
    return Elephant(
      id: id,
      lat: (map['lat'] as num).toDouble(),
      lon: (map['lon'] as num).toDouble(),
    );
  }
}
