class WeatherInfo {
  final double temp;
  final double tempMin;
  final double tempMax;
  final String weather;
  final String description;
  final String icon;
  final int humidity;
  final String? cityName;

  WeatherInfo({
    required this.temp,
    required this.tempMin,
    required this.tempMax,
    required this.weather,
    required this.description,
    required this.icon,
    required this.humidity,
    this.cityName,
  });

  factory WeatherInfo.fromJson(Map<String, dynamic> json) {
    return WeatherInfo(
      temp: (json['temp'] as num).toDouble(),
      tempMin: (json['tempMin'] as num).toDouble(),
      tempMax: (json['tempMax'] as num).toDouble(),
      weather: json['weather'] as String,
      description: json['description'] as String,
      icon: json['icon'] as String,
      humidity: (json['humidity'] as num).toInt(),
      cityName: json['cityName'] as String?,
    );
  }
}

class WeatherForecastItem {
  final String date;
  final double temp;
  final double tempMin;
  final double tempMax;
  final String weather;
  final String description;
  final String icon;
  final int humidity;

  WeatherForecastItem({
    required this.date,
    required this.temp,
    required this.tempMin,
    required this.tempMax,
    required this.weather,
    required this.description,
    required this.icon,
    required this.humidity,
  });

  factory WeatherForecastItem.fromJson(Map<String, dynamic> json) {
    return WeatherForecastItem(
      date: json['date'] as String,
      temp: (json['temp'] as num).toDouble(),
      tempMin: (json['tempMin'] as num).toDouble(),
      tempMax: (json['tempMax'] as num).toDouble(),
      weather: json['weather'] as String,
      description: json['description'] as String,
      icon: json['icon'] as String,
      humidity: (json['humidity'] as num).toInt(),
    );
  }
}

class WeatherData {
  final WeatherInfo current;
  final List<WeatherForecastItem> forecast;

  WeatherData({required this.current, required this.forecast});

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      current: WeatherInfo.fromJson(json['current']),
      forecast: (json['forecast'] as List)
          .map((item) => WeatherForecastItem.fromJson(item))
          .toList(),
    );
  }
}
