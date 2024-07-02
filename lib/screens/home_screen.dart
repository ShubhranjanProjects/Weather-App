import 'dart:convert';
import 'package:countries_of_the_world/helper/getCityWeatherHelper.dart';
import 'package:countries_of_the_world/helper/getCountryCode.dart';
import 'package:countries_of_the_world/screens/login_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _countries = [];
  bool _showResults = false;
  late Position position;
  String? countryCode;

  @override
  void initState() {
    super.initState();
    _loadCountries();
  }

  Future<void> _logout() async {
    await _auth.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  Future<void> _loadCountries() async {
    final String data =
        await rootBundle.loadString('assets/config/config.json');
    setState(() {
      _countries = json.decode(data);
    });
  }

  void _onSearchChanged(String searchTerm) {
    searchTerm = searchTerm.trim().toLowerCase();
    if (searchTerm.isEmpty) {
      setState(() {
        _showResults = false;
      });
      return;
    }

    if (!isValidInput(searchTerm)) {
      setState(() {
        _countries = [];
        _showResults = true;
      });
      return;
    }

    setState(() {
      _showResults = true;
    });
  }

  bool isValidInput(String input) {
    final RegExp regex = RegExp(r'^[a-zA-Z\s]*$');
    return regex.hasMatch(input);
  }

  bool _countryMatchesSearch(Map<String, dynamic> country, String searchTerm) {
    final countryName = country['countryName'].toString().toLowerCase();
    final countryCapital = country['capital'].toString().toLowerCase();
    return countryName.contains(searchTerm) ||
        countryCapital.contains(searchTerm);
  }

  String getCurrencyCode(String countryCode) {
    for (var country in _countries) {
      if (country['countryCode'] == countryCode) {
        return country['currencyCode'];
      }
    }
    return 'USD'; // Default to USD if not found
  }

  Future<void> _showCountryDetails(Map<String, dynamic> country) async {
    var weather = await getCityWeather(country['capital']);

    try {
      String iconCode = weather['weather'][0]['icon'];
      String iconUrl = 'https://openweathermap.org/img/wn/$iconCode.png';
      Image image = Image.network(iconUrl);

      Map<String, dynamic> main = weather['main'];
      Map<String, dynamic> wind = weather['wind'];
      Map<String, dynamic> clouds = weather['clouds'];
      int visibility = weather['visibility'];
      String weatherDescription = weather['weather'][0]['description'];

      int sunriseTimestamp = weather['sys']['sunrise'] * 1000;
      int sunsetTimestamp = weather['sys']['sunset'] * 1000;
      DateTime sunriseDateTime =
          DateTime.fromMillisecondsSinceEpoch(sunriseTimestamp, isUtc: false);
      DateTime sunsetDateTime =
          DateTime.fromMillisecondsSinceEpoch(sunsetTimestamp, isUtc: false);

      String formattedSunriseTime = DateFormat('HH:mm').format(sunriseDateTime);
      String formattedSunsetTime = DateFormat('HH:mm').format(sunsetDateTime);

      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: const Color(0xFF50727B),
            title: Row(
              children: [
                const Text(
                  'Country Details',
                  style: TextStyle(color: Colors.white),
                ),
                image,
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Country: ',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      Flexible(
                        child: Text(
                          '${country['countryName']}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Text(
                        'Capital: ',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      Flexible(
                        child: Text(
                          '${country['capital']}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Text(
                        'Weather Description: ',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      Flexible(
                        child: Text(
                          weatherDescription,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Text(
                        'Temperature: ',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      Flexible(
                        child: Text(
                          '${main['temp']}°C',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Text(
                        'Feels Like: ',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      Flexible(
                        child: Text(
                          '${main['feels_like']}°C',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Text(
                        'Minimum Temperature: ',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      Flexible(
                        child: Text(
                          '${main['temp_min']}°C',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Text(
                        'Maximum Temperature: ',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      Flexible(
                        child: Text(
                          '${main['temp_max']}°C',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Text(
                        'Pressure: ',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      Flexible(
                        child: Text(
                          '${main['pressure']} hPa',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Text(
                        'Humidity: ',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      Flexible(
                        child: Text(
                          '${main['humidity']}%',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Text(
                        'Wind Speed: ',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      Flexible(
                        child: Text(
                          '${wind['speed']} m/s',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Text(
                        'Wind Direction: ',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      Flexible(
                        child: Text(
                          '${wind['deg']}°',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Text(
                        'Visibility: ',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      Flexible(
                        child: Text(
                          '$visibility meters',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Text(
                        'Cloudiness: ',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      Flexible(
                        child: Text(
                          '${clouds['all']}%',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Text(
                        'Sunrise: ',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      Flexible(
                        child: Text(
                          formattedSunriseTime,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Text(
                        'Sunset: ',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      Flexible(
                        child: Text(
                          formattedSunsetTime,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text(
                  'OK',
                  style: TextStyle(color: Colors.amber),
                ),
              ),
            ],
          );
        },
      );
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Center(
          child: Text(
            "Countries Around The World",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        backgroundColor: Colors.deepPurpleAccent,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      // appBar: AppBar(
      //   automaticallyImplyLeading: false,
      //   backgroundColor: Colors.black,
      //   toolbarHeight: MediaQuery.of(context).size.height * 0.1,
      //   title: const Center(
      //     child: Text(
      //       "Countries Around The World",
      //       style: TextStyle(
      //         color: Colors.white,
      //         fontWeight: FontWeight.bold,
      //       ),
      //     ),
      //   ),
      // ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Container(
            color: Colors.grey[200],
            child: Container(
              color: Colors.white,
              margin: EdgeInsets.all(constraints.maxWidth * 0.02),
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: constraints.maxHeight * 0.04),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                                left: constraints.maxWidth * 0.1),
                            child: const Text(
                              "Search Any Country:",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Padding(
                            padding: EdgeInsets.only(
                                right: constraints.maxWidth * 0.1),
                            child: SizedBox(
                              width: constraints.maxWidth * 0.5,
                              height: constraints.maxHeight * 0.08,
                              child: TextField(
                                controller: _searchController,
                                onChanged: _onSearchChanged,
                                decoration: InputDecoration(
                                  hintText: "Enter country name",
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                    borderSide:
                                        const BorderSide(color: Colors.grey),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                    borderSide:
                                        const BorderSide(color: Colors.black),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _showResults
                      ? Expanded(
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: constraints.maxWidth * 0.05),
                            child: ListView.builder(
                              itemCount: _countries.length,
                              itemBuilder: (context, index) {
                                final country = _countries[index];
                                final searchTerm =
                                    _searchController.text.trim().toLowerCase();

                                if (_countryMatchesSearch(
                                    country, searchTerm)) {
                                  return Container(
                                    margin: EdgeInsets.symmetric(
                                        vertical: constraints.maxHeight * 0.01),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey),
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    child: ListTile(
                                      title: Text(
                                        country['countryName'],
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      subtitle: Text(
                                        '${country['capital']}',
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      onTap: () => _showCountryDetails(country),
                                    ),
                                  );
                                }

                                bool anyMatchesFound = _countries.any(
                                    (country) => _countryMatchesSearch(
                                        country, searchTerm));
                                if (index == _countries.length - 1 &&
                                    !anyMatchesFound) {
                                  return Center(
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 50),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Image.asset(
                                            'assets/Images/no-records.png',
                                            width: 100,
                                            height: 100,
                                          ),
                                          const SizedBox(height: 10),
                                          const Text(
                                            "No Matches Found",
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }

                                return Container();
                              },
                            ),
                          ),
                        )
                      : Container(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
