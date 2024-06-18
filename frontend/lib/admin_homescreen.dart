import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Admin Homepage',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: AdminHomeScreen(username: ''), // Pass an empty string initially
    );
  }
}

class AdminHomeScreen extends StatefulWidget {
  final String username;

  AdminHomeScreen({required this.username});

  @override
  _AdminHomeScreenState createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _mainTabController;
  late String _username;

  @override
  void initState() {
    super.initState();
    _mainTabController = TabController(length: 2, vsync: this);
    _username = widget.username;
  }

  @override
  void dispose() {
    _mainTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Homepage (${widget.username})'), // Display the username
      ),
      body: TabBarView(
        controller: _mainTabController,
        children: [
          // Manage Bookings tab content
          ManageBookingsTab(username: _username),
          // View Play Data tab content
          ViewPlayDataPage(),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: TabBar(
          controller: _mainTabController,
          tabs: [
            Tab(text: 'Pending Bookings'),
            Tab(text: 'View Play Data'),
          ],
        ),
      ),
    );
  }
}

class ManageBookingsTab extends StatefulWidget {
  final String username;

  ManageBookingsTab({required this.username});

  @override
  _ManageBookingsTabState createState() => _ManageBookingsTabState();
}

class _ManageBookingsTabState extends State<ManageBookingsTab>
    with SingleTickerProviderStateMixin {
  late TabController _subTabController;

  @override
  void initState() {
    super.initState();
    _subTabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _subTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _subTabController,
          tabs: [
            Tab(text: 'Unassigned Bookings'),
            Tab(text: 'Assigned Bookings'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _subTabController,
            children: [
              UnassignedBookingsPage(username: widget.username),
              AssignedBookingsPage(username: widget.username),
            ],
          ),
        ),
      ],
    );
  }
}

class UnassignedBookingsPage extends StatefulWidget {
  final String username;
  UnassignedBookingsPage({required this.username});

  @override
  _UnassignedBookingsPageState createState() => _UnassignedBookingsPageState();
}

class _UnassignedBookingsPageState extends State<UnassignedBookingsPage> {
  late Future<List<Booking>> _unassignedBookingsFuture;

  @override
  void initState() {
    super.initState();
    _refreshUnassignedBookings();
  }

  void _refreshUnassignedBookings() {
    setState(() {
      _unassignedBookingsFuture = _fetchUnassignedBookings();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Unassigned Bookings'),
      ),
      body: FutureBuilder<List<Booking>>(
        future: _unassignedBookingsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final booking = snapshot.data![index];
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Script: ${booking.scriptName}'),
                          SizedBox(height: 8),
                          Text('Date: ${booking.date.toIso8601String().substring(0, 10)}'),
                          SizedBox(height: 8),
                          Text('Time: ${formatDateTime(booking.start)} - ${formatDateTime(booking.end)}'),
                          SizedBox(height: 8),
                          Text('Booking Type: ${booking.state}'),
                          SizedBox(height: 8),
                          Text('Players: ${booking.playerMax} players'),
                          SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              assignBooking(widget.username, booking.bookingId, context);
                            },
                            child: Text('Assign Self'),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          } else {
            return Center(child: Text('No unassigned bookings found.'));
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _refreshUnassignedBookings,
        tooltip: 'Refresh',
        child: Icon(Icons.refresh),
      ),
    );
  }

  Future<List<Booking>> _fetchUnassignedBookings() async {
    try {
      final response = await http.get(Uri.parse('http://localhost:3000/unassignedbooking'));
      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        return jsonData.map((json) => Booking.fromJson(json)).toList();
      } else {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Error'),
            content: Text('Error retrieving unassigned bookings: ${response.statusCode}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('OK'),
              ),
            ],
          ),
        );
        return [];
      }
    } catch (e) {
      // Handle error
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error'),
          content: Text('Error retrieving unassigned bookings: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        ),
      );
      return [];
    }
  }

  String formatDateTime(DateTime dateTime) {
    return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

class AssignedBookingsPage extends StatefulWidget {
  final String username;
  AssignedBookingsPage({required this.username});

  @override
  _AssignedBookingsPageState createState() => _AssignedBookingsPageState();
}

class _AssignedBookingsPageState extends State<AssignedBookingsPage> {
  late Future<List<Booking>> _assignedBookingsFuture;

  @override
  void initState() {
    super.initState();
    _refreshAssignedBookings();
  }

  void _refreshAssignedBookings() {
    setState(() {
      _assignedBookingsFuture = _fetchAssignedBookings();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Assigned Bookings'),
      ),
      body: FutureBuilder<List<Booking>>(
        future: _assignedBookingsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final booking = snapshot.data![index];
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Script: ${booking.scriptName}'),
                          SizedBox(height: 8),
                          Text('Date: ${booking.date.toIso8601String().substring(0, 10)}'),
                          SizedBox(height: 8),
                          Text('Time: ${formatDateTime(booking.start)} - ${formatDateTime(booking.end)}'),
                          SizedBox(height: 8),
                          Text('Booking Type: ${booking.state}'),
                          SizedBox(height: 8),
                          Text('Players: ${booking.playerMax} players'),
                          SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  // Show confirmation dialog for booking cancellation
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: Text("Confirmation"),
                                        content: Text("Are you sure you want to cancel this booking?"),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                            child: Text("Return"),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              print('Booking ID: ${booking.bookingId}');
                                              markBookingCancelled(booking.bookingId, context);
                                              Navigator.of(context).pop();
                                            },
                                            child: Text("Confirm"),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                ),
                                child: Text('Booking Cancelled'),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  // Show confirmation dialog for booking completion
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: Text("Confirmation"),
                                        content: Text("Are you sure you want to mark this booking as completed?"),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                            child: Text("Return"),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              print('Booking ID: ${booking.bookingId}');
                                              markBookingComplete(booking.bookingId, context);
                                              Navigator.of(context).pop();
                                            },
                                            child: Text("Confirm"),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                ),
                                child: Text('Booking Completed'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          } else {
            return Center(child: Text('No assigned bookings found.'));
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _refreshAssignedBookings,
        tooltip: 'Refresh',
        child: Icon(Icons.refresh),
      ),
    );
  }

  Future<List<Booking>> _fetchAssignedBookings() async {
    try {
      final response = await http.get(Uri.parse(
          'http://localhost:3000/assignedbooking?username=${widget.username}'));
      if (response.statusCode == 200) {
        final List jsonData = jsonDecode(response.body);
        return jsonData.map((json) => Booking.fromJson(json)).toList();
      } else {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Error'),
            content: Text(
                'Error retrieving assigned bookings: ${response.statusCode}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('OK'),
              ),
            ],
          ),
        );
        return []; // Return an empty list in case of an error
      }
    } catch (e) {
      // Handle error
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error'),
          content: Text('Error retrieving assigned bookings: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        ),
      );
      return []; // Return an empty list in case of an error
    }
  }

  String formatDateTime(DateTime dateTime) {
    return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

}

class ViewPlayDataPage extends StatefulWidget {
  @override
  _ViewPlayDataPageState createState() => _ViewPlayDataPageState();
}

class _ViewPlayDataPageState extends State<ViewPlayDataPage> {
  List<Data> _data = [];
  List<Data> _filteredData = [];

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    final response = await http.get(Uri.parse('http://localhost:3000/data'));
    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      setState(() {
        _data = jsonData.map((json) => Data.fromJson(json)).toList();
        _filteredData = _data;
      });
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error'),
          content: Text('Error in retrieving data'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  void _onDateRangeSelected(DateTime startDate, DateTime endDate) {
    setState(() {
      _filteredData = _data.where((data) {
        final bookingDate = DateTime.parse(data.bookingDate);
        return bookingDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
            bookingDate.isBefore(endDate.add(const Duration(days: 1)));
      }).toList();
    });
  }

  Map<String, int> _generateDateDataByMonth(List<Data> data) {
    Map<String, int> dateData = {};

    data.forEach((element) {
      final bookingDate = DateTime.parse(element.bookingDate);
      final formattedMonth = '${bookingDate.month}/${bookingDate.year.toString().substring(2)}'; // Format as "MM/yy" (e.g., "5/23")
      dateData[formattedMonth] = (dateData[formattedMonth] ?? 0) + 1;
    });

    return _sortMapByDate(dateData);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          DateRangeSelector(onDateRangeSelected: _onDateRangeSelected),
          _filteredData.isNotEmpty
              ? Column(
            children: [
              _buildBarChart(
                  'Genre Distribution', _generateGenreData(_filteredData)),
              _buildBarChart(
                  'Type Distribution', _generateTypeData(_filteredData)),
              _buildLineChart('Date Distribution (by Month)',
                  _generateDateDataByMonth(_filteredData)),
              _buildLineChart(
                  'Starting Time Distribution',
                  _generateStartingTimeData(_filteredData)), // Remove '_sortMapByKey' call
              _buildBarChart(
                  'Number of Players',
                  _generatePlayerCountData(_filteredData, scriptPlayerCount: true)),
            ],
          )
              : Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  Widget _buildBarChart(String title, Map<String, int> data) {
    final maxValue = _getMaxValue(data.values.toList());
    final extendedMaxValue = maxValue + (maxValue * 0.2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            title,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            child: AspectRatio(
              aspectRatio: 3.0,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: extendedMaxValue,
                  groupsSpace: 0.5,
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: SideTitles(
                      showTitles: true,
                      getTextStyles: (value) =>
                      const TextStyle(color: Color(0xff7589a2), fontWeight: FontWeight.bold, fontSize: 14),
                      margin: 20,
                      getTitles: (double value) {
                        return data.keys.elementAt(value.toInt());
                      },
                    ),
                  ),
                  barGroups: _createBarGroups(data),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLineChart(String title, Map<String, int> data) {
    final maxValue = _getMaxValue(data.values.toList());
    final extendedMaxValue = maxValue + (maxValue * 0.2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            title,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            child: AspectRatio(
              aspectRatio: 3.0,
              child: LineChart(
                LineChartData(
                  lineTouchData: LineTouchData(enabled: false),
                  maxY: extendedMaxValue,
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: SideTitles(
                      showTitles: true,
                      getTextStyles: (value) => const TextStyle(
                          color: Color(0xff7589a2),
                          fontWeight: FontWeight.bold,
                          fontSize: 14),
                      margin: 20,
                      getTitles: (double value) {
                        return data.keys.elementAt(value.toInt());
                      },
                      reservedSize: 50, // Add this line to reserve space for the long x-axis labels
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _createLineSpots(data),
                      isCurved: false, // Set to false for a straight line
                      barWidth: 2,
                      colors: [Colors.blue],
                      dotData: FlDotData(show: false), // Hide the dots
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<FlSpot> _createLineSpots(Map<String, int> data) {
    List<FlSpot> spots = [];
    int index = 0;

    data.forEach((key, value) {
      spots.add(FlSpot(index.toDouble(), value.toDouble()));
      index++;
    });

    return spots;
  }

  Map<String, int> _generateGenreData(List<Data> data) {
    Map<String, int> genreData = {};

    data.forEach((element) {
      genreData[element.scriptGenre] =
          (genreData[element.scriptGenre] ?? 0) + 1;
    });

    return genreData;
  }

  Map<String, int> _generateTypeData(List<Data> data) {
    Map<String, int> typeData = {};

    data.forEach((element) {
      typeData[element.scriptType] = (typeData[element.scriptType] ?? 0) + 1;
    });

    return typeData;
  }

  Map<String, int> _generateStartingTimeData(List<Data> data) {
    Map<String, int> startingTimeData = {};

    data.forEach((element) {
      String formattedTime = _formatTime(element.bookingStart);
      startingTimeData[formattedTime] = (startingTimeData[formattedTime] ?? 0) + 1;
    });

    // Sort the map by time
    final sortedStartingTimeData = Map.fromEntries(
      startingTimeData.entries.toList()
        ..sort((a, b) => _parseTime(a.key).compareTo(_parseTime(b.key))),
    );

    return sortedStartingTimeData;
  }

  String _formatTime(String time) {
    DateTime parsedTime = DateTime.parse('1970-01-01 ' + time);
    return DateFormat.Hms().format(parsedTime); // Format as "HH:mm:ss"
  }

  DateTime _parseTime(String time) {
    return DateTime.parse('1970-01-01 ' + time);
  }

  Map<String, int> _generatePlayerCountData(List<Data> data, {bool scriptPlayerCount = false}) {
    Map<String, int> playerCountData = {};

    data.forEach((element) {
      final playerCountKey = scriptPlayerCount ? element.scriptPlayerCount : element.bookingPlayerCount.toString();
      playerCountData[playerCountKey] = (playerCountData[playerCountKey] ?? 0) + 1;
    });

    // Sort the map by the first number in the keys
    final sortedPlayerCountData = Map.fromEntries(
      playerCountData.entries.toList()
        ..sort((a, b) {
          final int aCount = int.parse(a.key.split(' ')[0]);
          final int bCount = int.parse(b.key.split(' ')[0]);
          return aCount.compareTo(bCount);
        }),
    );

    return sortedPlayerCountData;
  }

  Map<String, int> _sortMapByDate(Map<String, int> data) {
    final sortedEntries = data.entries.toList()
      ..sort((a, b) {
        final aDate = DateTime(int.parse(a.key.split('/')[1]), int.parse(a.key.split('/')[0]));
        final bDate = DateTime(int.parse(b.key.split('/')[1]), int.parse(b.key.split('/')[0]));
        return aDate.compareTo(bDate);
      });

    return Map.fromEntries(sortedEntries);
  }

  List<BarChartGroupData> _createBarGroups(Map<String, int> data) {
    List<BarChartGroupData> barGroups = [];
    int index = 0;

    data.forEach((key, value) {
      barGroups.add(
        BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              y: value.toDouble(),
              colors: [Colors.blue],
              width: 20.0,
              rodStackItems: [
                BarChartRodStackItem(0, value.toDouble(), Colors.blue), // Use value.toString() instead
              ],
            )
          ],
        ),
      );
      index++;
    });

    return barGroups;
  }

  double _getMaxValue(List<int> values) {
    return values.isNotEmpty ? values.reduce((a, b) => a > b ? a : b).toDouble() : 0;
  }
}

class Data {
  final int bookingId;
  final String bookingDate;
  final String bookingStart;
  final String bookingEnd;
  final String bookingState;
  final int playerId;
  final int? bookingExperience;
  final String? bookingGender;
  final int bookingPlayerCount;
  final int bookingMaleCount;
  final int bookingFemaleCount;
  final int scriptId;
  final String scriptName;
  final String scriptPlayerCount;
  final Map<String, dynamic> scriptTime;
  final int scriptPlayerMax;
  final int scriptMaleMax;
  final int scriptFemaleMax;
  final String scriptGenre;
  final String scriptType;
  final List<dynamic>? scriptContentWarning;

  Data({
    required this.bookingId,
    required this.bookingDate,
    required this.bookingStart,
    required this.bookingEnd,
    required this.bookingState,
    required this.playerId,
    this.bookingExperience,
    this.bookingGender,
    required this.bookingPlayerCount,
    required this.bookingMaleCount,
    required this.bookingFemaleCount,
    required this.scriptId,
    required this.scriptName,
    required this.scriptPlayerCount,
    required this.scriptTime,
    required this.scriptPlayerMax,
    required this.scriptMaleMax,
    required this.scriptFemaleMax,
    required this.scriptGenre,
    required this.scriptType,
    this.scriptContentWarning,
  });

  factory Data.fromJson(Map<String, dynamic> json) {
    return Data(
      bookingId: json['bookingId'],
      bookingDate: json['bookingDate'],
      bookingStart: json['bookingStart'],
      bookingEnd: json['bookingEnd'],
      bookingState: json['bookingState'],
      playerId: json['playerId'],
      bookingExperience: json['bookingExperience'],
      bookingGender: json['bookingGender'],
      bookingPlayerCount: json['bookingPlayerCount'],
      bookingMaleCount: json['bookingMaleCount'],
      bookingFemaleCount: json['bookingFemaleCount'],
      scriptId: json['scriptId'],
      scriptName: json['scriptName'],
      scriptPlayerCount: json['scriptPlayerCount'],
      scriptTime: json['scriptTime'],
      scriptPlayerMax: json['scriptPlayerMax'],
      scriptMaleMax: json['scriptMaleMax'],
      scriptFemaleMax: json['scriptFemaleMax'],
      scriptGenre: json['scriptGenre'],
      scriptType: json['scriptType'],
      scriptContentWarning: json['scriptContentWarning'],
    );
  }
}

class DateRangeSelector extends StatefulWidget {
  final void Function(DateTime, DateTime) onDateRangeSelected;

  DateRangeSelector({required this.onDateRangeSelected});

  @override
  _DateRangeSelectorState createState() => _DateRangeSelectorState();
}

class _DateRangeSelectorState extends State<DateRangeSelector> {
  DateTime? _startDate;
  DateTime? _endDate;

  Future<void> _selectStartDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _endDate) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: () => _selectStartDate(context),
          child: Text(_startDate != null
              ? 'Start Date: ${_formatDate(_startDate!)}'
              : 'Select Start Date'),
        ),
        SizedBox(width: 16),
        ElevatedButton(
          onPressed: () => _selectEndDate(context),
          child: Text(_endDate != null
              ? 'End Date: ${_formatDate(_endDate!)}'
              : 'Select End Date'),
        ),
        SizedBox(width: 16),
        ElevatedButton(
          onPressed: _startDate != null && _endDate != null
              ? () => widget.onDateRangeSelected(_startDate!, _endDate!)
              : null,
          child: Text('Apply'),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class Booking {
  final int bookingId;
  final String scriptName;
  final String playerName;
  final DateTime date;
  final DateTime start;
  final DateTime end;
  final String state;
  final int? experience;
  final String? gender;
  final int playerCount;
  final int maleCount;
  final int femaleCount;
  final int playerMax;
  final int maleMax;
  final int femaleMax;
  final String? admin;

  Booking({
    required this.bookingId,
    required this.scriptName,
    required this.playerName,
    required this.date,
    required this.start,
    required this.end,
    required this.state,
    required this.experience,
    required this.gender,
    required this.playerCount,
    required this.maleCount,
    required this.femaleCount,
    required this.playerMax,
    required this.maleMax,
    required this.femaleMax,
    this.admin,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      bookingId: json['booking_id'],
      scriptName: json['script_name'],
      playerName: json['player_name'],
      date: DateTime.parse(json['date']),
      start: DateTime.parse('1970-01-01 ${json['start']}'),
      end: DateTime.parse('1970-01-01 ${json['end']}'),
      state: json['state'],
      experience: json['experience'],
      gender: json['gender'],
      playerCount: json['playercount'],
      maleCount: json['malecount'],
      femaleCount: json['femalecount'],
      playerMax: json['playermax'],
      maleMax: json['malemax'],
      femaleMax: json['femalemax'],
      admin: json['admin'],
    );
  }
}

Future<void> assignBooking(String username, int bookingID, BuildContext context) async {
  final url = Uri.parse('http://localhost:3000/assign?username=$username&bookingID=$bookingID');

  try {
    final response = await http.post(url);
    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Booking successfully assigned to admin! Refresh to see changes.'),
          duration: Duration(seconds: 2),
        ),
      );
    } else if (response.statusCode == 404) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Booking not found'),
          duration: Duration(seconds: 2),
        ),
      );
    } else if (response.statusCode == 409) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Booking time overlaps with an existing booking'),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to assign booking: ${response.body}'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  } catch (error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: $error'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

Future<void> markBookingComplete(int bookingID, BuildContext context) async {
  final url = Uri.parse('http://localhost:3000/markComplete?bookingID=$bookingID');

  try {
    final response = await http.post(url);
    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully marked booking as completed. Refresh to see changes.'),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to mark booking as completed: ${response.body}'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  } catch (error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error marking booking as completed: $error'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

Future<void> markBookingCancelled(int bookingID, BuildContext context) async {
  final url = Uri.parse('http://localhost:3000/markCancelled?bookingID=$bookingID');

  try {
    final response = await http.post(url);
    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully marked booking as cancelled. Refresh to see changes.'),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to mark booking as cancelled: ${response.body}'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  } catch (error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error marking booking as cancelled: $error'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
