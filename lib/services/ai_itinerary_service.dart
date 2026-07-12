import 'package:supabase_flutter/supabase_flutter.dart';
import 'itinerary_generator.dart';
import 'special_tour_service.dart' show isSpecialTravelStyle;

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
  final String generatedBy; // 'llm' | 'fallback' | 'quick'
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

/// 규칙 기반 일정 조립 (AI 미사용, fallback과 명시적 빠른 생성이 공유)
Future<AIItineraryResult> _buildScriptItinerary(AIItineraryRequest req, String generatedBy) async {
  final allAttractions = await fetchIslandAttractions();

  List<Attraction> extraAttractions = [];
  if (isSpecialTravelStyle(req.travelStyle)) {
    try {
      extraAttractions = await prefetchSpecialTourData(req.travelStyle, req.islands);
    } catch (_) {
      extraAttractions = [];
    }
  }

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

  // 특수 여행 관광지가 있으면 첫날에 삽입 (WEB aiItinerary.ts buildScriptItinerary 미러링)
  if (extraAttractions.isNotEmpty && itinerary.days.isNotEmpty) {
    final extra = extraAttractions.take(2).toList().asMap().entries.map((e) => {
          'id': 'special-fallback-${e.key}',
          'type': 'attraction',
          'time': '${15 + e.key}:30',
          'title': e.value.name,
          'location': e.value.island,
          'duration': e.value.duration,
          'description': e.value.description,
          'congestionLevel': 'low',
        });
    itinerary.days.first.activities.addAll(extra);
  }

  return AIItineraryResult(itinerary: itinerary, generatedBy: generatedBy);
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
    return _buildScriptItinerary(req, 'fallback');
  }
}

/// 규칙 기반으로만 즉시 생성 (AI 미사용, 사용자가 명시적으로 선택)
Future<AIItineraryResult> generateQuickItinerary(AIItineraryRequest req) {
  return _buildScriptItinerary(req, 'quick');
}
