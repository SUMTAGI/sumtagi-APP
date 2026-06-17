import 'package:supabase_flutter/supabase_flutter.dart';

class IslandModel {
  final String id, name, description, ferryTime, bestSeason, image, popularityTrend, congestion;
  final List<String> features, ports;
  final int ferryPrice;

  const IslandModel({
    required this.id, required this.name, required this.description,
    required this.ferryTime, required this.bestSeason, required this.image,
    required this.popularityTrend, required this.congestion,
    required this.features, required this.ports, required this.ferryPrice,
  });

  factory IslandModel.fromMap(Map<String, dynamic> map) => IslandModel(
    id: map['id'] as String,
    name: map['name'] as String,
    description: map['description'] as String? ?? '',
    ferryTime: map['ferry_time'] as String? ?? '',
    ferryPrice: map['ferry_price'] as int? ?? 0,
    popularityTrend: map['popularity_trend'] as String? ?? 'stable',
    congestion: map['congestion'] as String? ?? 'low',
    bestSeason: map['best_season'] as String? ?? '',
    image: map['image'] as String? ?? '',
    features: List<String>.from(map['features'] as List? ?? []),
    ports: List<String>.from(map['ports'] as List? ?? []),
  );
}

class AttractionModel {
  final String id, name, category, description, image, duration;
  final double rating;

  const AttractionModel({
    required this.id, required this.name, required this.category,
    required this.description, required this.image, required this.duration,
    required this.rating,
  });

  factory AttractionModel.fromMap(Map<String, dynamic> map) => AttractionModel(
    id: map['id'] as String,
    name: map['name'] as String,
    category: map['category'] as String? ?? '',
    description: map['description'] as String? ?? '',
    image: map['image'] as String? ?? '',
    duration: map['duration'] as String? ?? '',
    rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
  );
}

class RestaurantModel {
  final String id, name, cuisine, priceLevel, specialty, image;
  final double rating;

  const RestaurantModel({
    required this.id, required this.name, required this.cuisine,
    required this.priceLevel, required this.specialty, required this.image,
    required this.rating,
  });

  factory RestaurantModel.fromMap(Map<String, dynamic> map) => RestaurantModel(
    id: map['id'] as String,
    name: map['name'] as String,
    cuisine: map['cuisine'] as String? ?? '',
    priceLevel: map['price_level'] as String? ?? '',
    specialty: map['specialty'] as String? ?? '',
    image: map['image'] as String? ?? '',
    rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
  );
}

class AccommodationModel {
  final String id, name, type, image;
  final int pricePerNight;
  final double rating;

  const AccommodationModel({
    required this.id, required this.name, required this.type,
    required this.image, required this.pricePerNight, required this.rating,
  });

  factory AccommodationModel.fromMap(Map<String, dynamic> map) => AccommodationModel(
    id: map['id'] as String,
    name: map['name'] as String,
    type: map['type'] as String? ?? '',
    image: map['image'] as String? ?? '',
    pricePerNight: map['price_per_night'] as int? ?? 0,
    rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
  );
}

class PhotoSpotModel {
  final String id, name, description, image, bestTime;

  const PhotoSpotModel({
    required this.id, required this.name, required this.description,
    required this.image, required this.bestTime,
  });

  factory PhotoSpotModel.fromMap(Map<String, dynamic> map) => PhotoSpotModel(
    id: map['id'] as String,
    name: map['name'] as String,
    description: map['description'] as String? ?? '',
    image: map['image'] as String? ?? '',
    bestTime: map['best_time'] as String? ?? '',
  );
}

class IslandDetailModel extends IslandModel {
  final List<AttractionModel> attractions;
  final List<RestaurantModel> restaurants;
  final List<AccommodationModel> accommodations;
  final List<PhotoSpotModel> photoSpots;

  const IslandDetailModel({
    required super.id, required super.name, required super.description,
    required super.ferryTime, required super.bestSeason, required super.image,
    required super.popularityTrend, required super.congestion,
    required super.features, required super.ports, required super.ferryPrice,
    required this.attractions, required this.restaurants,
    required this.accommodations, required this.photoSpots,
  });
}

class IslandService {
  static final _client = Supabase.instance.client;

  static Future<List<IslandModel>> getIslands() async {
    final data = await _client.from('islands').select().order('name');
    return (data as List).map((e) => IslandModel.fromMap(e)).toList();
  }

  static Future<IslandDetailModel?> getIslandById(String id) async {
    final data = await _client
        .from('islands')
        .select('*, attractions(*), restaurants(*), accommodations(*), photo_spots(*)')
        .eq('id', id)
        .single();

    return IslandDetailModel(
      id: data['id'] as String,
      name: data['name'] as String,
      description: data['description'] as String? ?? '',
      ferryTime: data['ferry_time'] as String? ?? '',
      ferryPrice: data['ferry_price'] as int? ?? 0,
      popularityTrend: data['popularity_trend'] as String? ?? 'stable',
      congestion: data['congestion'] as String? ?? 'low',
      bestSeason: data['best_season'] as String? ?? '',
      image: data['image'] as String? ?? '',
      features: List<String>.from(data['features'] as List? ?? []),
      ports: List<String>.from(data['ports'] as List? ?? []),
      attractions: ((data['attractions'] as List?) ?? [])
          .map((e) => AttractionModel.fromMap(e))
          .toList()
        ..sort((a, b) => 0),
      restaurants: ((data['restaurants'] as List?) ?? [])
          .map((e) => RestaurantModel.fromMap(e))
          .toList(),
      accommodations: ((data['accommodations'] as List?) ?? [])
          .map((e) => AccommodationModel.fromMap(e))
          .toList(),
      photoSpots: ((data['photo_spots'] as List?) ?? [])
          .map((e) => PhotoSpotModel.fromMap(e))
          .toList(),
    );
  }
}
