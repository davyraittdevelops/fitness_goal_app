import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Garmin Goal Tracker',
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        textTheme: GoogleFonts.assistantTextTheme(
          Theme.of(context).textTheme.apply(
                bodyColor: Colors.black87,
              ),
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        textTheme: GoogleFonts.assistantTextTheme(
          Theme.of(context).textTheme.apply(
                bodyColor: Colors.white70,
              ),
        ),
        scaffoldBackgroundColor: Colors.grey[900],
      ),
      themeMode: ThemeMode.system,
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late Future<List<KmData>> futureData;
  late Future<double> futureTotalKmThisYear;
  late Future<double> futureTotalKmThisWeek;
  late Future<void> futureInitialSetup;
  static const double goalKmYear = 1000.0;
  double goalKmWeek = 15.0;
  int streak = 0;

  @override
  void initState() {
    super.initState();
    futureInitialSetup = _initialSetup();
    futureData = fetchKmData();
    futureTotalKmThisYear = fetchTotalKmThisYear();
    futureTotalKmThisWeek = fetchTotalKmThisWeek();
  }

  Future<void> _initialSetup() async {
    final prefs = await SharedPreferences.getInstance();
    goalKmWeek = prefs.getDouble('goalKmWeek') ?? 15.0;
    streak = prefs.getInt('streak') ?? 0;
  }

  Future<void> _updateGoalAndStreak(double totalKmThisWeek) async {
    final prefs = await SharedPreferences.getInstance();
    if (totalKmThisWeek >= goalKmWeek) {
      streak++;
      goalKmWeek *= 1.1; // Increase goal by 10%
    } else {
      streak = 0;
      goalKmWeek = 15.0; // Reset to initial goal
    }
    await prefs.setDouble('goalKmWeek', goalKmWeek);
    await prefs.setInt('streak', streak);
  }

  Future<List<KmData>> fetchKmData() async {
    final apiKey = dotenv.env['API_KEY'];
    if (apiKey == null) {
      print("Error: API Key is not defined in .env file.");
      throw Exception("API Key is not defined in .env file");
    }

    DateTime now = DateTime.now();
    List<KmData> kmDataList = [];
    for (int i = 0; i < 12; i++) {
      DateTime month = DateTime(now.year, now.month - i, 1);
      if (month.month == 0) {
        month = DateTime(month.year - 1, 12, 1);
      }
      String monthStr =
          "${month.month.toString().padLeft(2, '0')}-${month.year}";
      Uri uri = Uri.parse(
          'https://1inkf1xm8i.execute-api.eu-central-1.amazonaws.com/prod/personalgarmindata?range=$monthStr');
      final response = await http.get(uri, headers: {'x-api-key': apiKey});
      if (response.statusCode == 200) {
        Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        double totalKm = (jsonResponse['totalKm'] as num).toDouble();
        kmDataList.add(KmData(monthStr, totalKm));
      } else {
        throw Exception('Failed to load kilometer data for one or more months');
      }
    }
    kmDataList = kmDataList.reversed
        .toList(); // Reverse the data for chronological order
    return kmDataList;
  }

  Future<double> fetchTotalKmThisYear() async {
    final apiKey = dotenv.env['API_KEY'];
    if (apiKey == null) {
      print("Error: API Key is not defined in .env file.");
      throw Exception("API Key is not defined in .env file");
    }

    Uri uri = Uri.parse(
        'https://1inkf1xm8i.execute-api.eu-central-1.amazonaws.com/prod/personalgarmindata?range=currentyear');
    final response = await http.get(uri, headers: {'x-api-key': apiKey});
    if (response.statusCode == 200) {
      Map<String, dynamic> jsonResponse = jsonDecode(response.body);
      double totalKm = (jsonResponse['totalKm'] as num).toDouble();
      return totalKm;
    } else {
      throw Exception('Failed to load total kilometers for the current year');
    }
  }

  Future<double> fetchTotalKmThisWeek() async {
    final apiKey = dotenv.env['API_KEY'];
    if (apiKey == null) {
      print("Error: API Key is not defined in .env file.");
      throw Exception("API Key is not defined in .env file");
    }

    Uri uri = Uri.parse(
        'https://1inkf1xm8i.execute-api.eu-central-1.amazonaws.com/prod/personalgarmindata?range=currentweek');
    final response = await http.get(uri, headers: {'x-api-key': apiKey});
    if (response.statusCode == 200) {
      Map<String, dynamic> jsonResponse = jsonDecode(response.body);
      double totalKm = (jsonResponse['totalKm'] as num).toDouble();
      await _updateGoalAndStreak(totalKm);
      return totalKm;
    } else {
      throw Exception('Failed to load total kilometers for the current week');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Garmin Goal Tracker'),
      ),
      body: FutureBuilder<void>(
        future: futureInitialSetup,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Center(
              child: FutureBuilder<double>(
                future: futureTotalKmThisYear,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    if (snapshot.hasError) {
                      return Text("Error: ${snapshot.error}");
                    }
                    if (snapshot.hasData) {
                      double totalKmThisYear = snapshot.data!;
                      double progressYear = totalKmThisYear / goalKmYear;
                      return FutureBuilder<double>(
                        future: futureTotalKmThisWeek,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.done) {
                            if (snapshot.hasError) {
                              return Text("Error: ${snapshot.error}");
                            }
                            if (snapshot.hasData) {
                              double totalKmThisWeek = snapshot.data!;
                              double progressWeek =
                                  totalKmThisWeek / goalKmWeek;
                              return Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Yearly Progress: ${totalKmThisYear.toStringAsFixed(1)} / $goalKmYear km',
                                          style: TextStyle(
                                            color: Theme.of(context)
                                                .textTheme
                                                .bodyLarge!
                                                .color,
                                          ),
                                        ),
                                        SizedBox(height: 8.0),
                                        LinearProgressIndicator(
                                          value: progressYear,
                                          backgroundColor: Colors.grey[300],
                                          color: Colors.blue,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Divider(thickness: 2),
                                  Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Weekly Progress: ${totalKmThisWeek.toStringAsFixed(1)} / ${goalKmWeek.toStringAsFixed(1)} km',
                                          style: TextStyle(
                                            color: Theme.of(context)
                                                .textTheme
                                                .bodyLarge!
                                                .color,
                                          ),
                                        ),
                                        SizedBox(height: 8.0),
                                        LinearProgressIndicator(
                                          value: progressWeek,
                                          backgroundColor: Colors.grey[300],
                                          color: progressWeek >= 1.0
                                              ? Colors.green
                                              : Colors.blue,
                                        ),
                                        SizedBox(height: 8.0),
                                        Text(
                                          'Current Streak: $streak week(s)',
                                          style: TextStyle(
                                            color: Theme.of(context)
                                                .textTheme
                                                .bodyLarge!
                                                .color,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Divider(thickness: 2),
                                  FutureBuilder<List<KmData>>(
                                    future: futureData,
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.done) {
                                        if (snapshot.hasError) {
                                          return Text(
                                              "Error: ${snapshot.error}");
                                        }
                                        if (snapshot.hasData) {
                                          return SizedBox(
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .height /
                                                3,
                                            child: SingleChildScrollView(
                                              scrollDirection: Axis.horizontal,
                                              child: Container(
                                                width: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    2,
                                                child: KilometersChart(
                                                    snapshot.data!),
                                              ),
                                            ),
                                          );
                                        } else {
                                          return const Text(
                                              "No data available");
                                        }
                                      } else {
                                        return const CircularProgressIndicator();
                                      }
                                    },
                                  ),
                                ],
                              );
                            } else {
                              return const Text("No data available");
                            }
                          } else {
                            return const CircularProgressIndicator();
                          }
                        },
                      );
                    } else {
                      return const Text("No data available");
                    }
                  } else {
                    return const CircularProgressIndicator();
                  }
                },
              ),
            );
          } else {
            return const CircularProgressIndicator();
          }
        },
      ),
    );
  }
}

class KilometersChart extends StatelessWidget {
  final List<KmData> data;

  const KilometersChart(this.data, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Reverse the data list
    final reversedData = data.reversed.toList();

    return AspectRatio(
      aspectRatio: 1.7,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: reversedData.map((e) => e.km).reduce((a, b) => a > b ? a : b) *
              1.2,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${reversedData[groupIndex].month}\n',
                  TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.bold),
                  children: <TextSpan>[
                    TextSpan(
                      text: '${rod.toY.toStringAsFixed(1)} km',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 &&
                      value.toInt() < reversedData.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        reversedData[value.toInt()].month,
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    );
                  }
                  return const Text('');
                },
                reservedSize: 40,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: TextStyle(
                        color: Theme.of(context).textTheme.bodyLarge?.color),
                  );
                },
              ),
            ),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 20,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Theme.of(context)
                    .textTheme
                    .bodyLarge!
                    .color!
                    .withOpacity(0.1),
                strokeWidth: 1,
              );
            },
          ),
          borderData: FlBorderData(
            show: false,
          ),
          barGroups: reversedData.asMap().entries.map((entry) {
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: entry.value.km,
                  color: Theme.of(context).colorScheme.primary,
                  width: 20,
                  borderRadius: BorderRadius.circular(4),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: reversedData
                            .map((e) => e.km)
                            .reduce((a, b) => a > b ? a : b) *
                        1.2,
                    color: Theme.of(context)
                        .textTheme
                        .bodyLarge!
                        .color!
                        .withOpacity(0.1),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class KmData {
  final String month;
  final double km;

  KmData(this.month, this.km);
}
