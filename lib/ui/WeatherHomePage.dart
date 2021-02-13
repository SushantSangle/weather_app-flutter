import 'package:flutter/material.dart';
import 'package:weather_app/NetworkHelper/NetworkHelper.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class WeatherHomePage extends StatefulWidget {
  WeatherHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _WeatherHomePageState createState() => _WeatherHomePageState();
}

class _WeatherHomePageState extends State<WeatherHomePage> {
  TimeOfDay sunrise,sunset;
  double currentTemp,
      maxTemp,
      minTemp,
      visibility,
      windSpeed,
      windDirection;

  int humidity,
      pressure;

  String weather = '',
      weatherDescription = '',
      weatherIcon,
      updatedAt;
  bool dataFetched = false;
  bool loading = false;

  Color bgColor;
  Future networkFuture;

  final bgColorMap = {
    'Clear' : Colors.blue[300],
    'Clouds': Colors.cyan[800],
    'Mist'  : Colors.blueGrey[300],
    'Smoke' : Colors.blueGrey[400],
    'Haze' : Colors.grey,
    'Fog' : Colors.blueGrey[300],
    'Sand' : Colors.orange[300],
    'Dust' : Colors.brown[300],
    'Ash' : Colors.grey,
    'Squalls' : Colors.blueGrey,
    'tornado' : Colors.blueGrey,
  };

  String degree = "°";
  TextTheme textThemeDark = TextTheme(
    headline1: TextStyle(fontSize: 72.0, fontWeight: FontWeight.bold, color: Colors.grey[200]),
    headline2: TextStyle(fontSize: 32.0, fontWeight: FontWeight.bold, color: Colors.grey[200]),
    headline3: TextStyle(fontSize: 19.8, fontWeight: FontWeight.bold, color: Colors.grey[200]),
    headline4: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold, color: Colors.grey[200]),
    headline5: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[200]),
    headline6: TextStyle(fontWeight: FontWeight.bold, fontStyle: FontStyle.italic, color: Colors.grey[200]),
    subtitle1: TextStyle(inherit: true, color: Colors.grey[300]),
    subtitle2: TextStyle(inherit: true, color: Colors.grey[300]),
  );

  @override
  void initState() {
    super.initState();
    bgColor =  Colors.blue[300];
    updatedAt = "";
    networkFuture = pullData();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children:[
              Text(widget.title),
            ]
        ),
        actions: [
          FlatButton(
            onPressed: this.pullData,
            child: this.dataFetched ? loadingStatus() : Container(),
          )
        ],
        backgroundColor: bgColor,
        elevation: 0,
      ),
      body:  Container(
        color: bgColor,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(10),
              child: Text(
                '${this.updatedAt}',
                style: textThemeDark.headline6,
              ),
            ),
            Expanded(
              child: FutureBuilder(
                  future: networkFuture,
                  builder: (context,snapshot) {
                    switch(snapshot.connectionState){
                      case ConnectionState.none:
                      case ConnectionState.waiting:
                        return SpinKitChasingDots(color: textThemeDark.headline1.color, size: 50);
                      case ConnectionState.done: return topView();
                      default: return Container();
                    }
                  }
              )
            ),
            AnimatedContainer(
              duration: Duration(milliseconds: 1000),
              height: this.dataFetched ? 530 : 60,
              width: MediaQuery.of(context).size.width,
              alignment: Alignment.topLeft,
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.vertical(
                    top : Radius.circular(20),
                    bottom : Radius.zero,
                  )
              ),
              child: FutureBuilder(
                future: networkFuture,
                builder: (context,snapshot) {
                  switch(snapshot.connectionState){
                    case ConnectionState.none: return Container();
                    case ConnectionState.done: return currentDetails();
                    default: return Container();
                  }
                }
              )

            )
          ],
        ),
      ),
    );
  }

  Future<Position> getPositionOrPermission() async{

    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permantly denied, we cannot request permissions.');
    }

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        return Future.error(
            'Location permissions are denied (actual value: $permission).');
      }
    }

    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.low);
  }

  Future<int> pullData() async{
    this.setState(() {
      this.loading = true;
    });
    Position currentLocation = await this.getPositionOrPermission();
    dynamic response = await NetworkHelper.getWeatherFromLocation(
      lat: currentLocation.latitude.toString(),
      lon: currentLocation.longitude.toString(),
    );
    this.setState(()  {
      this.sunrise = TimeOfDay.fromDateTime(DateTime.fromMicrosecondsSinceEpoch(response['double']['sunrise']));
      this.sunset = TimeOfDay.fromDateTime(DateTime.fromMicrosecondsSinceEpoch(response['double']['sunset']));
      this.currentTemp = response['double']['currTemp'];
      this.maxTemp = response['double']['tempMax'];
      this.minTemp = response['double']['tempMin'];
      this.visibility = num.parse(response['double']['visibility']?.toString() ?? '10000')/ 1000;
      this.windSpeed = response['double']['windSpeed'];
      this.windDirection = num.parse(response['double']['windDir']?.toString() ?? '0') / 10 * 10;

      this.humidity = response['double']['humidity'];
      this.pressure = response['double']['pressure'];

      this.weatherIcon = NetworkHelper.strings['weatherIcon'];
      this.weather = NetworkHelper.strings['weather'];
      this.weatherDescription = NetworkHelper.strings['weatherDescription'];
      this.updatedAt = DateTime.now().toLocal().toString();
      this.updatedAt = 'updated at ${updatedAt.substring(0,updatedAt.lastIndexOf("."))}';
      this.loading = false;
      this.dataFetched = true;

      this.bgColor = bgColorMap[weather];
    });
    return 0;
  }

  Widget loadingStatus(){
    if(this.loading)
      return SpinKitRing(
        color: textThemeDark.headline1.color,
        size: textThemeDark.headline3.fontSize,
        lineWidth: 2,
      );
    return Icon(
      Icons.refresh,
      size: textThemeDark.subtitle1.fontSize,
      color: textThemeDark.subtitle1.color,
    );
  }
  Container topView() => Container(
    key: Key('mainWeatherContainer'),
    padding: EdgeInsets.all(10),
    alignment: Alignment.topCenter,
    child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Expanded(
            flex: 1,
            child : Image(
              image: AssetImage('assets/${this.weatherIcon ?? '01d'}@2x..png'),
              width: MediaQuery.of(context).size.width / (1.61 * 1.61),
            ),
          ),
          Expanded(
            flex : 3,
            child:
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.thermostat_rounded,
                      size: MediaQuery.of(context).size.width / 8,
                      color: textThemeDark.headline2.color,
                    ),
                    Text(
                      '${this.currentTemp ?? ''}${this.degree}C',
                      style: textThemeDark.headline2,
                    ),
                  ],
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.arrow_downward,
                      color: textThemeDark.headline2.color,
                    ),
                    Text(
                      '${this.minTemp ?? ''}${this.degree}C',
                      style: textThemeDark.headline5,
                    ),Icon(
                      Icons.arrow_upward,
                      color: textThemeDark.headline2.color,
                    ),
                    Text(
                      '${this.maxTemp ?? ''}${this.degree}C',
                      style: textThemeDark.headline5,
                    ),
                  ],
                ),
                Text(
                  '\n${this.weather}',
                  style: textThemeDark.headline3,
                ),
                Text(
                  '${this.weatherDescription}',
                  style: textThemeDark.headline4,
                ),
              ],
            ),
          )

        ]
    ),

  );
  SingleChildScrollView currentDetails() => SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:[
        Text(
          'Current Details\n',
          style: Theme.of(context).textTheme.headline4,
          textAlign: TextAlign.start,
        ),
        Table(
          children:[
            TableRow(
              children: [
                Text(
                  'Humidity',
                  style: Theme.of(context).textTheme.subtitle1,
                ),
                Text(
                  '${this.humidity ?? ''}%',
                  style: Theme.of(context).textTheme.bodyText1,
                )
              ],
            ),
            TableRow(
              children: [
                Text(
                  'Pressure',
                  style: Theme.of(context).textTheme.subtitle1,
                ),
                Text(
                  '${this.pressure ?? ''}mBar',
                  style: Theme.of(context).textTheme.bodyText1,
                )
              ],
            ),
            TableRow(
              children: [
                Text(
                  'Visibility',
                  style: Theme.of(context).textTheme.subtitle1,
                ),
                Text(
                  '${this.visibility ?? ''}km',
                  style: Theme.of(context).textTheme.bodyText1,
                )
              ],
            ),
          ],
        ),
        Text(
          '\nWind\n',
          style: Theme.of(context).textTheme.headline5,
          textAlign: TextAlign.start,
        ),
        Table(
          children:[
            TableRow(
              children: [
                Text(
                  'Wind speed',
                  style: Theme.of(context).textTheme.subtitle1,
                ),
                Text(
                  '${this.windSpeed ?? ''}km/h',
                  style: Theme.of(context).textTheme.bodyText1,
                )
              ],
            ),
            TableRow(
              children: [
                Text(
                  'Wind direction',
                  style: Theme.of(context).textTheme.subtitle1,
                ),
                Text(
                  '${this.windDirection ?? ''}${this.degree}',
                  style: Theme.of(context).textTheme.bodyText1,
                )
              ],
            ),
          ],
        ),
        Text(
          '\nSun\n',
          style: Theme.of(context).textTheme.headline5,
          textAlign: TextAlign.start,
        ),
        Table(
          children:[
            TableRow(
              children: [
                Text(
                  'Sunrise',
                  style: Theme.of(context).textTheme.subtitle1,
                ),
                Text(
                  '${this.sunrise?.hour ?? ''}:${this.sunrise?.minute ?? ''}',
                  style: Theme.of(context).textTheme.bodyText1,
                )
              ],
            ),
            TableRow(
              children: [
                Text(
                  'Sunset',
                  style: Theme.of(context).textTheme.subtitle1,
                ),
                Text(
                  '${this.sunset?.hour ?? ''}:${this.sunset?.minute ?? ''}',
                  style: Theme.of(context).textTheme.bodyText1,
                )
              ],
            ),
          ],
        ),
      ],
    ),
  );
}