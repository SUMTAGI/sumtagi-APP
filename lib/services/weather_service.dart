import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class WeatherCurrent {
  final double temperature;
  final double apparentTemperature;
  final String condition;
  final double windSpeed;
  final double waveHeight;

  const WeatherCurrent({
    required this.temperature,
    required this.apparentTemperature,
    required this.condition,
    required this.windSpeed,
    required this.waveHeight,
  });

  factory WeatherCurrent.fromJson(Map<String, dynamic> j) => WeatherCurrent(
    temperature: (j['temperature'] as num).toDouble(),
    apparentTemperature: (j['apparentTemperature'] as num).toDouble(),
    condition: j['condition'] as String,
    windSpeed: (j['windSpeed'] as num).toDouble(),
    waveHeight: (j['waveHeight'] as num).toDouble(),
  );

  Map<String, dynamic> toJson() => {
    'temperature': temperature,
    'apparentTemperature': apparentTemperature,
    'condition': condition,
    'windSpeed': windSpeed,
    'waveHeight': waveHeight,
  };
}

class WeatherForecastDay {
  final String day;
  final String date;
  final String condition;
  final int high;
  final int low;
  final int rainChance;

  const WeatherForecastDay({
    required this.day,
    required this.date,
    required this.condition,
    required this.high,
    required this.low,
    required this.rainChance,
  });

  factory WeatherForecastDay.fromJson(Map<String, dynamic> j) => WeatherForecastDay(
    day: j['day'] as String,
    date: j['date'] as String,
    condition: j['condition'] as String,
    high: j['high'] as int,
    low: j['low'] as int,
    rainChance: j['rainChance'] as int,
  );

  Map<String, dynamic> toJson() => {
    'day': day,
    'date': date,
    'condition': condition,
    'high': high,
    'low': low,
    'rainChance': rainChance,
  };
}

class WeatherResult {
  final WeatherCurrent current;
  final List<WeatherForecastDay> forecast;
  final DateTime fetchedAt;

  const WeatherResult({
    required this.current,
    required this.forecast,
    required this.fetchedAt,
  });

  factory WeatherResult.fromJson(Map<String, dynamic> j) => WeatherResult(
    current: WeatherCurrent.fromJson(j['current']),
    forecast: (j['forecast'] as List).map((e) => WeatherForecastDay.fromJson(e)).toList(),
    fetchedAt: DateTime.parse(j['fetchedAt'] as String),
  );

  Map<String, dynamic> toJson() => {
    'current': current.toJson(),
    'forecast': forecast.map((e) => e.toJson()).toList(),
    'fetchedAt': fetchedAt.toIso8601String(),
  };
}

enum FerryRisk { safe, caution, danger }

extension FerryRiskExt on FerryRisk {
  String get label => switch (this) {
    FerryRisk.safe    => '운항 정상',
    FerryRisk.caution => '운항 주의',
    FerryRisk.danger  => '결항 위험',
  };
  String get description => switch (this) {
    FerryRisk.safe    => '현재 기상 조건이 양호합니다',
    FerryRisk.caution => '기상 악화로 일부 항로 지연 가능',
    FerryRisk.danger  => '강풍·높은 파고로 결항 가능성 있음',
  };
}

class WeatherService {
  static FerryRisk assessFerryRisk(double windSpeed, double waveHeight) {
    if (windSpeed >= 50 || waveHeight >= 2.5) return FerryRisk.danger;
    if (windSpeed >= 36 || waveHeight >= 1.5) return FerryRisk.caution;
    return FerryRisk.safe;
  }
  static const _cacheKey = 'incheon_weather_v1';
  static const _cacheDuration = Duration(minutes: 30);
  static const _lat = 37.4563;
  static const _lon = 126.7052;
  static const _weekdays = ['', '월', '화', '수', '목', '금', '토', '일'];

  static String _wmoToCondition(int code) {
    if (code == 0) return '맑음';
    if (code <= 2) return '구름조금';
    if (code <= 3) return '흐림';
    if (code <= 48) return '흐림';
    if (code <= 67) return '비';
    if (code <= 77) return '흐림';
    if (code <= 82) return '비';
    return '비';
  }

  static Future<WeatherResult?> getWeather() async {
    final prefs = await SharedPreferences.getInstance();

    // 캐시 유효하면 반환
    final cached = prefs.getString(_cacheKey);
    if (cached != null) {
      try {
        final result = WeatherResult.fromJson(jsonDecode(cached));
        if (DateTime.now().difference(result.fetchedAt) < _cacheDuration) {
          return result;
        }
      } catch (_) {}
    }

    try {
      final forecastUri = Uri.parse(
        'https://api.open-meteo.com/v1/forecast'
        '?latitude=$_lat&longitude=$_lon'
        '&current=temperature_2m,apparent_temperature,weather_code,wind_speed_10m'
        '&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max'
        '&timezone=Asia%2FSeoul&forecast_days=6',
      );
      final marineUri = Uri.parse(
        'https://marine-api.open-meteo.com/v1/marine'
        '?latitude=$_lat&longitude=$_lon'
        '&hourly=wave_height&timezone=Asia%2FSeoul&forecast_days=1',
      );

      final responses = await Future.wait([
        http.get(forecastUri).timeout(const Duration(seconds: 10)),
        http.get(marineUri).timeout(const Duration(seconds: 10)),
      ]);

      if (responses[0].statusCode != 200) return _cachedOrNull(prefs);

      final forecastJson = jsonDecode(responses[0].body) as Map<String, dynamic>;
      final currentJson = forecastJson['current'] as Map<String, dynamic>;
      final dailyJson = forecastJson['daily'] as Map<String, dynamic>;

      double waveHeight = 0.5;
      if (responses[1].statusCode == 200) {
        final marineJson = jsonDecode(responses[1].body) as Map<String, dynamic>;
        final waves = (marineJson['hourly']['wave_height'] as List);
        final hour = DateTime.now().hour;
        waveHeight = (waves[hour] as num?)?.toDouble() ?? 0.5;
      }

      final dates = (dailyJson['time'] as List).cast<String>();
      final forecast = List.generate(5, (i) {
        final idx = i + 1;
        final date = DateTime.parse(dates[idx]);
        return WeatherForecastDay(
          day: _weekdays[date.weekday],
          date: '${date.month}/${date.day}',
          condition: _wmoToCondition((dailyJson['weather_code'] as List)[idx] as int),
          high: ((dailyJson['temperature_2m_max'] as List)[idx] as num).round(),
          low: ((dailyJson['temperature_2m_min'] as List)[idx] as num).round(),
          rainChance: ((dailyJson['precipitation_probability_max'] as List)[idx] as num?)?.round() ?? 0,
        );
      });

      final result = WeatherResult(
        current: WeatherCurrent(
          temperature: (currentJson['temperature_2m'] as num).toDouble(),
          apparentTemperature: (currentJson['apparent_temperature'] as num).toDouble(),
          condition: _wmoToCondition(currentJson['weather_code'] as int),
          windSpeed: (currentJson['wind_speed_10m'] as num).toDouble(),
          waveHeight: waveHeight,
        ),
        forecast: forecast,
        fetchedAt: DateTime.now(),
      );

      await prefs.setString(_cacheKey, jsonEncode(result.toJson()));
      return result;
    } catch (_) {
      return _cachedOrNull(prefs);
    }
  }

  static WeatherResult? _cachedOrNull(SharedPreferences prefs) {
    final cached = prefs.getString(_cacheKey);
    if (cached == null) return null;
    try {
      return WeatherResult.fromJson(jsonDecode(cached));
    } catch (_) {
      return null;
    }
  }
}
