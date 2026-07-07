import 'package:supabase_flutter/supabase_flutter.dart';
import 'itinerary_generator.dart';

class AIItineraryRequest {
  final String departurePort;
  final List<String> islands;
  final String startDate;
  final String endDate;
  final int travelers;
  final String travelStyle;
  final String budget;
  final String? specialRequests;
  final String provider;

  const AIItineraryRequest({
    required this.departurePort,
    required this.islands,
    required this.startDate,
    required this.endDate,
    required this.travelers,
    required this.travelStyle,
    required this.budget,
    this.specialRequests,
    this.provider = 'gemini',
  });

  Map<String, dynamic> toJson() => {
    'departurePort': departurePort,
    'islands': islands,
    'startDate': startDate,
    'endDate': endDate,
    'travelers': travelers,
    'travelStyle': travelStyle,
    'budget': budget,
    if (specialRequests != null && specialRequests!.isNotEmpty) 'specialRequests': specialRequests,
    'provider': provider,
  };
}

class AIItineraryResult {
  final GeneratedItinerary itinerary;
  final String generatedBy; // 'llm' | 'fallback'
  const AIItineraryResult({required this.itinerary, required this.generatedBy});
}

GeneratedItinerary _transformLLMResponse(Map<String, dynamic> aiData, AIItineraryRequest req) {
  final rawDays = (aiData['days'] as List?) ?? [];
  final days = rawDays.map((rawDay) {
    final day = rawDay as Map<String, dynamic>;
    final rawActivities = (day['activities'] as List?) ?? [];
    final activities = <Map<String, dynamic>>[];
    for (int idx = 0; idx < rawActivities.length; idx++) {
      final act = rawActivities[idx] as Map<String, dynamic>;
      activities.add({
        'id': 'ai-d${day['dayNumber']}-$idx',
        'type': act['type'] ?? 'attraction',
        'time': act['time'] ?? '09:00',
        'title': act['title'] ?? '',
        'location': act['location'] ?? (req.islands.isNotEmpty ? req.islands[0] : ''),
        'duration': act['duration'] ?? 60,
        'description': act['description'] ?? '',
        'price': act['estimatedCost'],
        'bookingStatus': act['type'] == 'ferry' ? 'available' : null,
      });
    }
    return ItineraryDay(date: day['date'] as String, dayNumber: day['dayNumber'] as int, activities: activities);
  }).toList();

  return GeneratedItinerary(
    title: aiData['title'] as String? ?? '${req.islands.join(", ")} 여행',
    departurePort: req.departurePort,
    startDate: req.startDate,
    endDate: req.endDate,
    travelers: req.travelers,
    islands: req.islands,
    totalCost: (aiData['estimatedTotalCost'] as num?)?.toInt() ?? 0,
    days: days,
  );
}

/// AI(Gemini 등) Edge Function 호출 → 실패 시 실제 Supabase 관광지 데이터 기반 규칙 생성으로 대체
Future<AIItineraryResult> generateAIItinerary(
  AIItineraryRequest req, {
  void Function(String reason)? onFallback,
}) async {
  try {
    final response = await Supabase.instance.client.functions.invoke(
      'generate-itinerary',
      body: req.toJson(),
    );
    final data = response.data;
    if (data is! Map || data['ok'] != true || data['itinerary'] == null) {
      throw Exception('LLM 응답 오류');
    }
    final itinerary = _transformLLMResponse(data['itinerary'] as Map<String, dynamic>, req);
    return AIItineraryResult(itinerary: itinerary, generatedBy: 'llm');
  } catch (e) {
    onFallback?.call(e.toString());

    final allAttractions = await fetchIslandAttractions();
    final formData = TripFormData(
      departurePort: req.departurePort,
      startDate: req.startDate,
      endDate: req.endDate,
      travelers: req.travelers,
      travelType: req.travelStyle,
      islands: req.islands,
      budget: req.budget,
    );
    final itinerary = generateItinerary(formData, allAttractions);
    return AIItineraryResult(itinerary: itinerary, generatedBy: 'fallback');
  }
}
