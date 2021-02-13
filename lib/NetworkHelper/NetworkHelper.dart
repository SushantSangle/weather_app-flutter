import 'package:requests/requests.dart';

class NetworkHelper {
  static const url = 'https://api.openweathermap.org/data/2.5/weather/';
  static const key = '8b098de5bf12c5ef12d027611369273f';
  static Map<String,String> strings;

  static Future<Map<String,Map<String,dynamic>>> getWeatherFromLocation({String lon, String lat,String units = 'metric'}) async {
    var params = {
      'lon':lon,
      'lat':lat,
      'units': units,
      'appid':key,
    };

    Response response = await Requests.get(url,queryParameters: params);
    dynamic json = response.json();
    print(json.toString());
    strings = {
      'weather' : json['weather'][0]['main'],
      'weatherDescription':json['weather'][0]['description'],
      'weatherIcon':json['weather'][0]['icon'],
    };

    return {
      'double' : {
        'sunrise' : json['sys']['sunrise'],
        'sunset' : json['sys']['sunset'],
        'currTemp': json['main']['temp'],
        'tempMin': json['main']['temp_min'],
        'tempMax': json['main']['temp_max'],
        'visibility': json['visibility'],
        'windSpeed': json['wind']['speed'],
        'humidity': json['main']['humidity'],
        'pressure': json['main']['pressure'],
        'windDir' : json['wind']['deg'],
      },
    };
  }

}
