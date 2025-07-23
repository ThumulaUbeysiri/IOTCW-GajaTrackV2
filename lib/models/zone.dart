class Zone {
  final String id;
  final double centerLat;
  final double centerLon;
  final double radiusMeters;

  Zone({required this.id, required this.centerLat, required this.centerLon, required this.radiusMeters});

  factory Zone.fromMap(String id, Map<String, dynamic> map) {
    return Zone(
      id: id,
      centerLat: (map['centerLat'] as num).toDouble(),
      centerLon: (map['centerLon'] as num).toDouble(),
      radiusMeters: (map['radiusMeters'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'centerLat': centerLat,
      'centerLon': centerLon,
      'radiusMeters': radiusMeters,
    };
  }
}
