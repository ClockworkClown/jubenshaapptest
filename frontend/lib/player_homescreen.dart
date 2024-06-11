import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:untitled1/genre_filter_chips.dart';
import 'package:untitled1/type_filter_chips.dart';
import 'package:untitled1/contentwarning_filter_chips.dart';
import 'package:untitled1/totalplayer_filter_chips.dart';
import 'package:untitled1/male_filter_chips.dart';
import 'package:untitled1/female_filter_chips.dart';
import 'package:untitled1/time_filter_chips.dart';
import 'package:untitled1/featured_filter_chips.dart';
import 'dart:convert';


class PlayerHomeScreen extends StatefulWidget {
  final String email;
  final String? username;

  PlayerHomeScreen({required this.email, this.username});

  @override
  _PlayerHomeScreenState createState() => _PlayerHomeScreenState();
}

class _PlayerHomeScreenState extends State<PlayerHomeScreen> {
  int _selectedIndex = 0; // Initial index is set to 0 (Script Booking)
  late String _username;

  @override
  void initState() {
    super.initState();
    _username = ''; // Initialize _username as an empty string
    _loadUserData(); // Call the function to load user data when the screen initializes
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Jubensha Booking'),
        leading: IconButton(
          icon: Icon(Icons.person),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => UserProfilePage(username: _username)),
            );
          },
        ),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          ScriptBookingPage(username: _username), // Script Booking Page
          PublicBookingPage(username: _username),
          PlayerBookingPage(username: _username),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: bottomNavItems,
      ),
    );
  }

  List<BottomNavigationBarItem> bottomNavItems = [
    BottomNavigationBarItem(
      icon: Icon(Icons.book),
      label: 'Script Booking',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.public),
      label: 'Public Bookings',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.event_note),
      label: 'My Bookings',
    ),
  ];

  _loadUserData() async {
    // Fetch email
    String email = await fetchLoginDetails();

    // Fetch username using the fetched email
    String? username = await fetchUsername(email);

    // Set the username in the state
    setState(() {
      _username = username ?? '';
    });
  }
}

class Script {
  final int id;
  final String name;
  final String playercount;
  final Duration time;
  final int playermax;
  final int malemax;
  final int femalemax;
  final String genre;
  final String type;
  final List<String>? contentwarnings;
  final bool featured;

  Script({
    required this.id,
    required this.name,
    required this.playercount,
    required this.time,
    required this.playermax,
    required this.malemax,
    required this.femalemax,
    required this.genre,
    required this.type,
    required this.contentwarnings,
    required this.featured
  });

  factory Script.fromJson(Map<String, dynamic> json) {

    final timeMap = json['time'] as Map<String, dynamic>;
    final hours = timeMap['hours'] ?? 0;
    final minutes = timeMap['minutes'] ?? 0;
    final seconds = timeMap['seconds'] ?? 0;

    return Script(
      id: json['id'],
      name: json['name'],
      playercount: json['playercount'],
      time: Duration(
        hours: hours,
        minutes: minutes,
        seconds: seconds,
      ),
      playermax: json['playermax'],
      malemax: json['malemax'],
      femalemax: json['femalemax'],
      genre: json['genre'],
      type: json['type'],
      contentwarnings: json['contentwarnings'] is List
          ? List<String>.from(json['contentwarnings'])
          : null,
      featured: json['featured']
    );
  }
}

class Review {
  final int reviewId;
  final String reviewOwner;
  final int reviewRating;
  final String reviewContents;
  final int scriptId;

  Review({
    required this.reviewId,
    required this.reviewOwner,
    required this.reviewRating,
    required this.reviewContents,
    required this.scriptId,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      reviewId: json['review_id'],
      reviewOwner: json['review_owner'],
      reviewRating: json['review_rating'],
      reviewContents: json['review_contents'],
      scriptId: json['script_id'],
    );
  }
}

class PublicBooking {
  final int booking_id;
  final String scriptName;
  final String playerName;
  final DateTime date;
  final TimeOfDay start;
  final TimeOfDay end;
  final int experience;
  final String gender;
  final int playercount;
  final int malecount;
  final int femalecount;
  final int playermax;
  final int malemax;
  final int femalemax;

  PublicBooking({
    required this.booking_id,
    required this.scriptName,
    required this.playerName,
    required this.date,
    required this.start,
    required this.end,
    required this.experience,
    required this.gender,
    required this.playercount,
    required this.malecount,
    required this.femalecount,
    required this.playermax,
    required this.malemax,
    required this.femalemax,
  });

  factory PublicBooking.fromJson(Map<String, dynamic> json) {

    final startTime = json['start'].split(':');
    final endTime = json['end'].split(':');

    final date = DateTime.parse(json['date']).toLocal();

    return PublicBooking(
      booking_id: json['booking_id'],
      scriptName: json['script_name'],
      playerName: json['player_name'],
      date: date,
      start: TimeOfDay(hour: int.parse(startTime[0]), minute: int.parse(startTime[1])),
      end: TimeOfDay(hour: int.parse(endTime[0]), minute: int.parse(endTime[1])),
      experience: json['experience'],
      gender: json['gender'],
      playercount: json['playercount'],
      malecount: json['malecount'],
      femalecount: json['femalecount'],
      playermax: json['playermax'],
      malemax: json['malemax'],
      femalemax: json['femalemax'],
    );
  }
}

class PlayerBooking {
  final int booking_id;
  final String scriptName;
  final String playerName;
  final DateTime date;
  final Duration time;
  final TimeOfDay start;
  final TimeOfDay end;
  final int? experience;
  final String? gender;
  final int playercount;
  final int malecount;
  final int femalecount;
  final int playermax;
  final int malemax;
  final int femalemax;
  final String bookingstatus;
  final String playerowner;
  final bool reviewed;

  PlayerBooking({
    required this.booking_id,
    required this.scriptName,
    required this.playerName,
    required this.date,
    required this.time,
    required this.start,
    required this.end,
    this.experience,
    this.gender,
    required this.playercount,
    required this.malecount,
    required this.femalecount,
    required this.playermax,
    required this.malemax,
    required this.femalemax,
    required this.bookingstatus,
    required this.playerowner,
    required this.reviewed
  });

  factory PlayerBooking.fromJson(Map<String, dynamic> json) {

    final startTime = json['start'].split(':');
    final endTime = json['end'].split(':');

    final date = DateTime.parse(json['date']).toLocal();

    final timeMap = json['time'] as Map<String, dynamic>;
    final hours = timeMap['hours'] ?? 0;
    final minutes = timeMap['minutes'] ?? 0;
    final seconds = timeMap['seconds'] ?? 0;

    return PlayerBooking(
      booking_id: json['booking_id'],
      scriptName: json['script_name'],
      playerName: json['player_name'],
      date: date,
        time: Duration(
          hours: hours,
          minutes: minutes,
          seconds: seconds,
        ),
      start: TimeOfDay(hour: int.parse(startTime[0]), minute: int.parse(startTime[1])),
      end: TimeOfDay(hour: int.parse(endTime[0]), minute: int.parse(endTime[1])),
      experience: json['experience'],
      gender: json['gender'],
      playercount: json['playercount'],
      malecount: json['malecount'],
      femalecount: json['femalecount'],
      playermax: json['playermax'],
      malemax: json['malemax'],
      femalemax: json['femalemax'],
      bookingstatus: json['bookingstatus'],
      playerowner: json['playerowner'],
      reviewed: json['reviewed']
    );
  }
}

Future<String> fetchLoginDetails() async {
  final prefs = await SharedPreferences.getInstance();
  final email = prefs.getString('email') ?? '';
  print('Fetched email: $email');
  return email;
}

Future<String?> fetchUsername(String email) async {
  final response = await http.get(Uri.parse('http://localhost:3000/user?email=$email'));
  if (response.statusCode == 200) {
    Map<String, dynamic> data = json.decode(response.body);
    String username = data['username'].toString();
    print('username: $username');
    return username; // Convert the username to a string directly
  } else if (response.statusCode == 404) {
    // User not found
    return null;
  } else {
    throw Exception('Failed to fetch username');
  }
}

class ScriptBookingPage extends StatefulWidget {
  final String username;

  ScriptBookingPage({required this.username});

  @override
  _ScriptBookingPageState createState() => _ScriptBookingPageState();
}

class PublicBookingPage extends StatefulWidget {
  final String username;

  PublicBookingPage({required this.username});

  @override
  _PublicBookingPageState createState() => _PublicBookingPageState();
}

class PlayerBookingPage extends StatefulWidget {
  final String username;

  PlayerBookingPage({required this.username});

  @override
  _PlayerBookingPageState createState() => _PlayerBookingPageState();
}

class BookingPopup extends StatefulWidget {
  final int scriptId;
  final String scriptName;
  final String username;
  final Duration scriptTime;

  BookingPopup({required this.scriptId, required this.username, required this.scriptName, required this.scriptTime});

  @override
  _BookingPopupState createState() => _BookingPopupState();
}

class _BookingPopupState extends State<BookingPopup> {
  late DateTime _selectedDate;
  late TimeOfDay? _selectedTime;
  late bool _isPublic;
  late bool _isGenderAdherence;
  late int _numberOfScriptsPlayed;
  late bool _dateSelected = false;
  late List<dynamic> timeslotdata = [];
  late List<dynamic> roomdata = [];
  late int roomnumber = 0;

  bool isTimeUnavailable(TimeOfDay time, List<dynamic>? timeslotdata, List<dynamic>? roomdata, Duration scriptlength) {
    if ((timeslotdata == null || timeslotdata.isEmpty) && (roomdata == null || roomdata.isEmpty)) {
      return false; // Consider all times as available if there is no data
    }
    final timeInMinutes = time.hour * 60 + time.minute;

    // Track if the time is found in any range
    bool isUnavailable = false;

    // Iterate over each time range
    for (var range in timeslotdata?.cast<Map<String, dynamic>>() ?? []) {
      final startTime = DateTime.parse(range['startTime']);
      final endTime = DateTime.parse(range['endTime']);
      final startMinutes = startTime.hour * 60 + startTime.minute;
      final endMinutes = endTime.hour * 60 + endTime.minute;
      // Check if the time falls within the current range
      if (timeInMinutes >= startMinutes && timeInMinutes < endMinutes) {
        // Time found in a range, set flag and break loop
        isUnavailable = true;
        break;
      }
    }

    int totalDurationInMinutes = scriptlength.inHours * 60 + (scriptlength.inMinutes - scriptlength.inHours * 60);
    int intervals = totalDurationInMinutes ~/ 15; //calculate number of 15 minutes intervals

    for (int i = 0; i < intervals; i++) { //15 minutes is added for each interval, if there's overlap for any of the time, the original time is set as unavailable.
      int currentMinutes = (timeInMinutes + (i * 15)) % (24 * 60);
      int roomcount = 0;
      for (var range in roomdata?.cast<Map<String, dynamic>>() ?? []) {
        final startTime = DateTime.parse(range['startTime']);
        final endTime = DateTime.parse(range['endTime']);
        final startMinutes = startTime.hour * 60 + startTime.minute;
        final endMinutes = endTime.hour * 60 + endTime.minute;

        if (currentMinutes >= startMinutes && currentMinutes < endMinutes) {
          roomcount++;
          if (roomcount == roomnumber) {
            isUnavailable = true;
            break;
          }
        }
      }

      if (isUnavailable) {
        break;
      }
    }

    print('timeslot: ${timeInMinutes}');
    print('timeslotcheck: ${isUnavailable}');
    return isUnavailable;
  }

  List<DropdownMenuItem<TimeOfDay>> _generateDropdownItems(List<dynamic>? timeslotdata, Duration scriptlength) {
    final List<DropdownMenuItem<TimeOfDay>> items = [];
    final List<TimeOfDay> unavailableTimes = [];

    for (int index = 0; index < (12 * 4); index++) {
      final hour = (index ~/ 4) + 12;
      final minute = (index % 4) * 15;
      final timeOfDay = TimeOfDay(hour: hour % 24, minute: minute);

      final isUnavailable = isTimeUnavailable(timeOfDay, timeslotdata, roomdata, scriptlength);
      if (isUnavailable) {
        unavailableTimes.add(timeOfDay);
        items.add(
          DropdownMenuItem<TimeOfDay>(
            value: timeOfDay,
            enabled: false,
            child: Text(
              'Unavailable',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ),
        );
      } else {
        items.add(
          DropdownMenuItem<TimeOfDay>(
            value: timeOfDay,
            child: Text(
              '${timeOfDay.hour == 0 ? 12 : (timeOfDay.hour > 12 ? timeOfDay.hour - 12 : timeOfDay.hour)}:${timeOfDay.minute.toString().padLeft(2, '0')} ${timeOfDay.hour >= 12 ? 'PM' : 'AM'}',
            ),
          ),
        );
      }
    }
    return items;
  }

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _selectedTime = null;
    _isPublic = true;
    _isGenderAdherence = false;
    _numberOfScriptsPlayed = 1;
    timeslotdata = [];
    roomdata = [];
    _loadRoomCount();
  }

  Future<void> _loadRoomCount() async {
    try {
      int count = await fetchAvailableRoomCount();
      setState(() {
        roomnumber = count;
      });
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Unique Hero tag for each Hero widget
    final String heroTag = '${widget.scriptName}_${widget.scriptId}';

    return AlertDialog(
      title: Text('Booking Details'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Script Name: ${widget.scriptName}'),
            Text('Date: ${_selectedDate.toString().split(' ')[0]}'),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: () async {
                final pickedDate = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(Duration(days: 720)),
                );
                if (pickedDate != null) {
                  setState(() {
                    _selectedDate = pickedDate;
                    _dateSelected = true;
                    _selectedTime = TimeOfDay(hour: 12, minute: 0);
                    timeslotdata = [];
                    roomdata = [];
                  });

                  // Format the selected date as "YYYY-MM-DD"
                  final formattedDate = '${_selectedDate.toString().split(' ')[0]}';

                  // Send API request to check times
                  final response = await http.get(
                    Uri.parse('http://localhost:3000/checktimes?scriptId=${widget.scriptId}&date=$formattedDate&username=${widget.username}'),
                  );
                  if (response.statusCode == 200) {
                    setState(() {
                      // Parse the received data
                      timeslotdata = json.decode(response.body);
                      print('timeslotdata: $timeslotdata');
                    });
                  } else {
                    // Handle API error
                    print('Failed to fetch time ranges: ${response.statusCode}');
                  }

                  // Send API request to check room availability
                  final roomresponse = await http.get(
                    Uri.parse('http://localhost:3000/checkrooms?date=$formattedDate'),
                  );
                  if (roomresponse.statusCode == 200) {
                    setState(() {
                      // Parse the received data
                      roomdata = json.decode(roomresponse.body);
                      print('roomdata: $roomdata');
                    });
                  } else {
                    // Handle API error
                    print('Failed to fetch room availability: ${roomresponse.statusCode}');
                  }
                }
              },
              child: Text('Select Date'),
            ),
            if (_dateSelected) ...[
              SizedBox(height: 16),
              Text('Time: ${_selectedTime?.format(context) ?? ''}'),
              SizedBox(height: 8),
              DropdownButtonFormField<TimeOfDay>(
                key: UniqueKey(),
                value: _selectedTime,
                items: _generateDropdownItems(timeslotdata, widget.scriptTime),
                onChanged: (value) {
                  setState(() {
                    _selectedTime = value;
                  });
                },
              ),
            ],
            SizedBox(height: 16),
            Row(
              children: [
                Text('Public/Private: '),
                SizedBox(width: 8),
                DropdownButton<bool>(
                  value: _isPublic,
                  items: [
                    DropdownMenuItem(
                      value: true,
                      child: Text('Public'),
                    ),
                    DropdownMenuItem(
                      value: false,
                      child: Text('Private'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _isPublic = value!;
                    });
                  },
                ),
              ],
            ),
            if (_isPublic) ...[
              SizedBox(height: 16),
              Row(
                children: [
                  Text('Gender Adherence: '),
                  SizedBox(width: 8),
                  DropdownButton<bool>(
                    value: _isGenderAdherence,
                    items: [
                      DropdownMenuItem(
                        value: true,
                        child: Text('Yes'),
                      ),
                      DropdownMenuItem(
                        value: false,
                        child: Text('No'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _isGenderAdherence = value!;
                      });
                    },
                  ),
                ],
              ),
            ],
            if (_isPublic) ...[
              SizedBox(height: 16),
              Row(
                children: [
                  Text('Minimum Scripts Played: '),
                  SizedBox(width: 8),
                  Slider(
                    value: _numberOfScriptsPlayed.toDouble(),
                    min: 0,
                    max: 5,
                    divisions: 5,
                    label: _numberOfScriptsPlayed.round().toString(),
                    onChanged: (double value) {
                      setState(() {
                        _numberOfScriptsPlayed = value.toInt();
                      });
                    },
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: <Widget>[
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            // Perform booking or any other action here
            print('Booking Details:');
            print('Script ID: ${widget.scriptId}');
            print('Script Name: ${widget.scriptName}');
            print('Username: ${widget.username}');
            print('Date: $_selectedDate');
            print('Time: $_selectedTime');
            print('Public/Private: $_isPublic');
            print('Gender Adherence: $_isGenderAdherence');
            print('Minimum Scripts Played: $_numberOfScriptsPlayed');

            makeBooking(
              widget.username,
              widget.scriptId,
              _selectedTime?.format(context) ?? '',
              _selectedDate.toString().split(' ')[0],
              _isPublic ? 'public' : 'private',
              _isPublic ? 0 : _numberOfScriptsPlayed,
              _isPublic && _isGenderAdherence ? 'gender_adherence' : '',
              context,
            );

            // Once booking is successful, close the dialog
            Navigator.of(context).pop();
          },
          child: Text('Book'),
        ),
      ],
    );
  }
}

class _ScriptBookingPageState extends State<ScriptBookingPage> {
  late Future<List<Script>> _scriptsFuture;
  List<Script> _scripts = [];
  List<Script> _filteredScripts = [];

  Set<String> _selectedGenres = {};
  Set<String> _selectedTypes = {};
  Set<String> _selectedContentWarnings = {};
  Set<int> _selectedTotalPlayers = {};
  Set<int> _selectedMalePlayers = {};
  Set<int> _selectedFemalePlayers = {};
  Set<Duration> _selectedTime = {};
  Set<bool> _selectedFeatured = {};
  int _sortBy = 0; // 0 = genre, 1 = type, 2 = content warning

  @override
  void initState() {
    super.initState();
    _scriptsFuture = fetchScriptsFromDatabase().then((scripts) {
      _scripts = scripts;
      _filteredScripts = scripts;
      return scripts;
    });
  }

  @override
  Widget build(BuildContext context) {
    final String username = widget.username;

    return Scaffold(
      appBar: AppBar(
        title: Text('Scripts'),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: () {
              _showFilterDialog();
            },
          ),
          PopupMenuButton<int>(
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 0,
                child: Text('Sort by Genre'),
              ),
              PopupMenuItem(
                value: 1,
                child: Text('Sort by Type'),
              ),
              PopupMenuItem(
                value: 2,
                child: Text('Sort by Content Warning'),
              ),
            ],
            onSelected: (value) {
              setState(() {
                _sortBy = value;
                _sortScripts();
              });
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Script>>(
        future: _scriptsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            return ListView.builder(
              itemCount: _filteredScripts.length,
              itemBuilder: (context, index) {
                final script = _filteredScripts[index];
                return ListTile(
                  title: Text(script.name),
                  subtitle: Text('Players: ${script.playercount} - Time: ${formatDuration(script.time)}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.info),
                        tooltip: 'More Details',
                        onPressed: () {
                          // Show more info popup
                          showDialog(
                            context: context,
                            builder: (context) {
                              return FutureBuilder<List<Review>>(
                                future: fetchReviewsFromDatabase(script.id),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return AlertDialog(
                                      title: Text('More Details'),
                                      content: CircularProgressIndicator(),
                                    );
                                  } else if (snapshot.hasError) {
                                    return AlertDialog(
                                      title: Text('More Details'),
                                      content: Text('Error: ${snapshot.error}'),
                                    );
                                  } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                                    double totalRating = 0;
                                    snapshot.data!.forEach((review) {
                                      totalRating += review.reviewRating;
                                    });
                                    double averageRating = totalRating / snapshot.data!.length;
                                    String averageRatingString = averageRating.toStringAsFixed(1);

                                    return AlertDialog(
                                      title: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('More Details'),
                                          Row(
                                            children: [
                                              Text('Average Rating: '),
                                              // Display average rating using filled stars
                                              Row(
                                                children: [
                                                  for (int i = 0; i < averageRating.floor(); i++)
                                                    Icon(Icons.star, color: Colors.yellow[600]),
                                                  if (averageRating - averageRating.floor() >= 0.5)
                                                    Icon(Icons.star_half, color: Colors.yellow[600]),
                                                ],
                                              ),
                                              SizedBox(width: 8),
                                              Text('$averageRatingString'), // Display the rounded average rating string
                                            ],
                                          ),
                                        ],
                                      ),
                                      content: SizedBox(
                                        width: 280, // Constrain the width here
                                        child: ListView.builder(
                                          shrinkWrap: true,
                                          itemCount: snapshot.data!.length,
                                          itemBuilder: (context, index) {
                                            final review = snapshot.data![index];
                                            return ListTile(
                                              title: Row(
                                                children: [
                                                  // Display rating using filled stars
                                                  Row(
                                                    children: List.generate(
                                                      review.reviewRating,
                                                          (index) => Icon(Icons.star, color: Colors.yellow[600]),
                                                    ),
                                                  ),
                                                  SizedBox(width: 8),
                                                  Text('Rating: ${review.reviewRating}'),
                                                ],
                                              ),
                                              subtitle: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text('Owner: ${review.reviewOwner}'),
                                                  Text('Contents: ${review.reviewContents}'),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(context).pop(),
                                          child: Text('Close'),
                                        ),
                                      ],
                                    );
                                  } else {
                                    return AlertDialog(
                                      title: Text('More Details'),
                                      content: Text('No reviews found.'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(context).pop(),
                                          child: Text('Close'),
                                        ),
                                      ],
                                    );
                                  }
                                },
                              );
                            },
                          );
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.book),
                        tooltip: 'Book',
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => BookingPopup(username: widget.username, scriptId: script.id, scriptName: script.name, scriptTime: script.time),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          } else {
            return Center(child: Text('No scripts found.'));
          }
        },
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Filter Scripts'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GenreFilterChips(
                selectedGenres: _selectedGenres,
                onGenresChanged: (selectedGenres) {
                  setState(() {
                    _selectedGenres = selectedGenres;
                  });
                },
              ),
              TypeFilterChips(
                selectedTypes: _selectedTypes,
                onTypesChanged: (selectedTypes) {
                  setState(() {
                    _selectedTypes = selectedTypes;
                  });
                },
              ),
              ContentWarningFilterChips(
                selectedContentWarnings: _selectedContentWarnings,
                onContentWarningsChanged: (selectedContentWarnings) {
                  setState(() {
                    _selectedContentWarnings = selectedContentWarnings;
                  });
                },
              ),
              TotalPlayersFilterChips(
                selectedTotalPlayers: _selectedTotalPlayers,
                onTotalPlayersChanged: (selectedTotalPlayers) {
                  setState(() {
                    _selectedTotalPlayers = selectedTotalPlayers;
                  });
                },
              ),
              MalePlayersFilterChips(
                selectedMalePlayers: _selectedMalePlayers,
                onMalePlayersChanged: (selectedMalePlayers) {
                  setState(() {
                    _selectedMalePlayers = selectedMalePlayers;
                  });
                },
              ),
              FemalePlayersFilterChips(
                selectedFemalePlayers: _selectedFemalePlayers,
                onFemalePlayersChanged: (selectedFemalePlayers) {
                  setState(() {
                    _selectedFemalePlayers = selectedFemalePlayers;
                  });
                },
              ),
              TimeFilterChips(
                selectedTimes: _selectedTime,
                onTimesChanged: (selectedTimes) {
                  setState(() {
                    _selectedTime = selectedTimes;
                  });
                },
              ),
              FeaturedFilterChips(
                selectedFeatured: _selectedFeatured,
                onFeaturedChanged: (selectedFeatured) {
                  setState(() {
                    _selectedFeatured = selectedFeatured;
                  });
                },
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              _applyRecommendedFilters();
              Navigator.of(context).pop();
            },
            child: Text('Apply Prior Preferred'),
          ),
          ElevatedButton(
            onPressed: () {
              _applyFilters();
              Navigator.of(context).pop();
            },
            child: Text('Apply Filters'),
          ),
        ],
      ),
    );
  }

  void _applyFilters() {
    setState(() {
      _filteredScripts = List.from(_scripts);

      // Genre filter
      if (_selectedGenres.isNotEmpty) {
        _filteredScripts = _filteredScripts.where((script) => _selectedGenres.contains(script.genre)).toList();
      }

      // Type filter
      if (_selectedTypes.isNotEmpty) {
        _filteredScripts = _filteredScripts.where((script) => _selectedTypes.contains(script.type)).toList();
      }

      // Content Warning filter
      if (_selectedContentWarnings.isNotEmpty) {
        _filteredScripts = _filteredScripts.where((script) {
          if (script.contentwarnings == null) {
            return true;
          }
          return script.contentwarnings!.every((warning) => !_selectedContentWarnings.contains(warning));
        }).toList();
      }

      // Total Player filter
      if (_selectedTotalPlayers.isNotEmpty) {
        _filteredScripts = _filteredScripts.where((script) => _selectedTotalPlayers.contains(script.playermax)).toList();
      }

      // Male Player filter
      if (_selectedMalePlayers.isNotEmpty) {
        _filteredScripts = _filteredScripts.where((script) => _selectedMalePlayers.contains(script.malemax)).toList();
      }

      // Female Player filter
      if (_selectedFemalePlayers.isNotEmpty) {
        _filteredScripts = _filteredScripts.where((script) => _selectedFemalePlayers.contains(script.femalemax)).toList();
      }

      // Time filter
      if (_selectedTime.isNotEmpty) {
        _filteredScripts = _filteredScripts.where((script) => _selectedTime.contains(script.time)).toList();
      }

      // Featured filter
      if (_selectedFeatured.isNotEmpty) {
        _filteredScripts = _filteredScripts.where((script) => _selectedFeatured.contains(script.featured)).toList();
      }
    });
  }

  void _applyRecommendedFilters() async {
    try {
      final playerPreferences = await fetchPlayerPreferences(widget.username);
      setState(() {
        // Apply recommended filters based on player preferences
        _selectedGenres.add(playerPreferences['mostCommonGenre']);
        _selectedTypes.add(playerPreferences['mostCommonType']);
        _selectedTotalPlayers.add(playerPreferences['mostCommonPlayermax']);
        // You can add more filters based on other preferences
        _applyFilters();
      });
    } catch (e) {
      print('Error applying recommended filters: $e');
      // Handle error
    }
  }

  void _sortScripts() {
    switch (_sortBy) {
      case 0:
        _scripts.sort((a, b) => (a.genre ?? '').compareTo(b.genre ?? ''));
        break;
      case 1:
        _scripts.sort((a, b) => (a.type ?? '').compareTo(b.type ?? ''));
        break;
      case 2:
        _scripts.sort((a, b) => (a.contentwarnings?.length ?? 0).compareTo(b.contentwarnings?.length ?? 0));
        break;
    }
  }
}

class _PublicBookingPageState extends State<PublicBookingPage> {
  late Future<List<PublicBooking>> _publicBookingsFuture;

  @override
  void initState() {
    super.initState();
    _refreshPublicBookings(widget.username);
  }

  void _refreshPublicBookings(String username) {
    setState(() {
      _publicBookingsFuture = fetchPublicBookingsFromDatabase(username);
    });
  }

  @override
  Widget build(BuildContext context) {
    final String username = widget.username;
    _refreshPublicBookings(widget.username);

    return Scaffold(
      appBar: AppBar(
        title: Text('Public Bookings'),
      ),
      body: FutureBuilder<List<PublicBooking>>(
        future: _publicBookingsFuture,
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
                          Text('Booking Owner: ${booking.playerName}'),
                          SizedBox(height: 8),
                          Text('Date: ${booking.date.toIso8601String().substring(0, 10)}'),
                          SizedBox(height: 8),
                          Text('Time: ${booking.start.format(context)} - ${booking.end.format(context)}'),
                          SizedBox(height: 8),
                          Text('Number of Played Games needed to join: ${booking.experience}'),
                          SizedBox(height: 8),
                          Text('Gender Adherence: ${booking.gender}'),
                          SizedBox(height: 8),
                          if (booking.gender == 'NO')
                            Text('Players: ${booking.playercount} of ${booking.playermax} joined'),
                          if (booking.gender == 'YES')
                            Text('Male players: ${booking.malecount} of ${booking.malemax} joined, Female players: ${booking.femalecount} of ${booking.femalemax} joined'),
                          SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              _joinPublicBooking(booking.booking_id, username, context);
                            },
                            child: Text('Join'),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          } else {
            return Center(child: Text('No public bookings found.'));
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _refreshPublicBookings(username);
        },
        tooltip: 'Refresh',
        child: Icon(Icons.refresh),
      ),
    );
  }
}

class AlterBookingPopup extends StatefulWidget {
  final int bookingId;
  final String username;
  final Duration scriptTime;

  AlterBookingPopup({required this.bookingId, required this.username, required this.scriptTime});

  @override
  _AlterBookingPopupState createState() => _AlterBookingPopupState();
}

class _AlterBookingPopupState extends State<AlterBookingPopup> {
  late DateTime _selectedDate;
  late TimeOfDay? _selectedTime;
  late bool _isPublic;
  late bool _isGenderAdherence;
  late int _numberOfScriptsPlayed;
  late bool _dateSelected = false;
  late List<dynamic> timeslotdata = [];
  late List<dynamic> roomdata = [];
  late int roomnumber = 0;

  bool isTimeUnavailable(TimeOfDay time, List<dynamic>? timeslotdata, List<dynamic>? roomdata, Duration scriptlength) {
    if ((timeslotdata == null || timeslotdata.isEmpty) && (roomdata == null || roomdata.isEmpty)) {
      return false; // Consider all times as available if there is no data
    }
    final timeInMinutes = time.hour * 60 + time.minute;

    // Track if the time is found in any range
    bool isUnavailable = false;

    // Iterate over each time range
    for (var range in timeslotdata?.cast<Map<String, dynamic>>() ?? []) {
      final startTime = DateTime.parse(range['startTime']);
      final endTime = DateTime.parse(range['endTime']);
      final startMinutes = startTime.hour * 60 + startTime.minute;
      final endMinutes = endTime.hour * 60 + endTime.minute;
      // Check if the time falls within the current range
      if (timeInMinutes >= startMinutes && timeInMinutes < endMinutes) {
        // Time found in a range, set flag and break loop
        isUnavailable = true;
        break;
      }
    }

    int totalDurationInMinutes = scriptlength.inHours * 60 + (scriptlength.inMinutes - scriptlength.inHours * 60);
    int intervals = totalDurationInMinutes ~/ 15; //calculate number of 15 minutes intervals

    for (int i = 0; i < intervals; i++) { //15 minutes is added for each interval, if there's overlap for any of the time, the original time is set as unavailable.
      int currentMinutes = (timeInMinutes + (i * 15)) % (24 * 60);
      int roomcount = 0;
      for (var range in roomdata?.cast<Map<String, dynamic>>() ?? []) {
        final startTime = DateTime.parse(range['startTime']);
        final endTime = DateTime.parse(range['endTime']);
        final startMinutes = startTime.hour * 60 + startTime.minute;
        final endMinutes = endTime.hour * 60 + endTime.minute;

        if (currentMinutes >= startMinutes && currentMinutes < endMinutes) {
          roomcount++;
          if (roomcount == roomnumber) {
            isUnavailable = true;
            break;
          }
        }
      }

      if (isUnavailable) {
        break;
      }
    }

    print('timeslot: ${timeInMinutes}');
    print('timeslotcheck: ${isUnavailable}');
    return isUnavailable;
  }

  List<DropdownMenuItem<TimeOfDay>> _generateDropdownItems(List<dynamic>? timeslotdata, Duration scriptlength) {
    final List<DropdownMenuItem<TimeOfDay>> items = [];
    final List<TimeOfDay> unavailableTimes = [];

    for (int index = 0; index < (12 * 4); index++) {
      final hour = (index ~/ 4) + 12;
      final minute = (index % 4) * 15;
      final timeOfDay = TimeOfDay(hour: hour % 24, minute: minute);

      final isUnavailable = isTimeUnavailable(timeOfDay, timeslotdata, roomdata, scriptlength);
      if (isUnavailable) {
        unavailableTimes.add(timeOfDay);
        items.add(
          DropdownMenuItem<TimeOfDay>(
            value: timeOfDay,
            enabled: false,
            child: Text(
              'Unavailable',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ),
        );
      } else {
        items.add(
          DropdownMenuItem<TimeOfDay>(
            value: timeOfDay,
            child: Text(
              '${timeOfDay.hour == 0 ? 12 : (timeOfDay.hour > 12 ? timeOfDay.hour - 12 : timeOfDay.hour)}:${timeOfDay.minute.toString().padLeft(2, '0')} ${timeOfDay.hour >= 12 ? 'PM' : 'AM'}',
            ),
          ),
        );
      }
    }
    return items;
  }

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _selectedTime = null;
    _isPublic = true;
    _isGenderAdherence = false;
    _numberOfScriptsPlayed = 1;
    timeslotdata = [];
    roomdata = [];
    _loadRoomCount();
  }

  Future<void> _loadRoomCount() async {
    try {
      int count = await fetchAvailableRoomCount();
      setState(() {
        roomnumber = count;
      });
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Unique Hero tag for each Hero widget
    final String heroTag = '${widget.bookingId}';

    return AlertDialog(
      title: Text('Alter Booking Details'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Date: ${_selectedDate.toString().split(' ')[0]}'),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: () async {
                final pickedDate = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(Duration(days: 720)),
                );
                if (pickedDate != null) {
                  setState(() {
                    _selectedDate = pickedDate;
                    _dateSelected = true;
                    _selectedTime = TimeOfDay(hour: 12, minute: 0);
                    timeslotdata = [];
                    roomdata = [];
                  });

                  // Format the selected date as "YYYY-MM-DD"
                  final formattedDate = '${_selectedDate.toString().split(' ')[0]}';

                  // Send API request to check times
                  final response = await http.get(
                    Uri.parse('http://localhost:3000/checktimesalter?bookingId=${widget.bookingId}&date=$formattedDate&username=${widget.username}'),
                  );
                  if (response.statusCode == 200) {
                    setState(() {
                      // Parse the received data
                      timeslotdata = json.decode(response.body);
                      print('timeslotdata: $timeslotdata');
                    });
                  } else {
                    // Handle API error
                    print('Failed to fetch time ranges: ${response.statusCode}');
                  }

                  // Send API request to check room availability
                  final roomresponse = await http.get(
                    Uri.parse('http://localhost:3000/checkrooms?date=$formattedDate'),
                  );
                  if (roomresponse.statusCode == 200) {
                    setState(() {
                      // Parse the received data
                      roomdata = json.decode(roomresponse.body);
                      print('roomdata: $roomdata');
                    });
                  } else {
                    // Handle API error
                    print('Failed to fetch room availability: ${roomresponse.statusCode}');
                  }
                }
              },
              child: Text('Select New Date'),
            ),
            if (_dateSelected) ...[
              SizedBox(height: 16),
              Text('New Time: ${_selectedTime?.format(context) ?? ''}'),
              SizedBox(height: 8),
              DropdownButtonFormField<TimeOfDay>(
                key: UniqueKey(),
                value: _selectedTime,
                items: _generateDropdownItems(timeslotdata, widget.scriptTime),
                onChanged: (value) {
                  setState(() {
                    _selectedTime = value;
                  });
                },
              ),
            ],
            SizedBox(height: 8),
            Text(
              'Note: Only private bookings, or public bookings with no other players can be altered.'
                  'Attempting to alter the date of time of a public booking with other players will have no effect.',
              style: TextStyle(
                color: Colors.red,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            // Perform altering booking or any other action here
            print('Alter Booking Details:');
            print('Booking ID: ${widget.bookingId}');
            print('Username: ${widget.username}');
            print('Date: $_selectedDate');
            print('Time: $_selectedTime');

            alterBooking(
              widget.username,
              widget.bookingId,
              _selectedTime?.format(context) ?? '',
              _selectedDate.toString().split(' ')[0],
            );

            // Once altering booking is successful, close the dialog
            Navigator.of(context).pop();
          },
          child: Text('Alter Booking'),
        ),
      ],
    );
  }
}

class _PlayerBookingPageState extends State<PlayerBookingPage> with TickerProviderStateMixin {
  late Future<List<PlayerBooking>> _playerBookingsFuture;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  void _refreshPlayerBookings(String username) {
    print('_refreshPlayerBookings check: $username');
    setState(() {
      _playerBookingsFuture = fetchPlayerBookingsFromDatabase(username);
    });
  }

  @override
  Widget build(BuildContext context) {
    final String username = widget.username;
    _playerBookingsFuture = fetchPlayerBookingsFromDatabase(username);
    print('build check: $username');

    return FutureBuilder<List<PlayerBooking>>(
        future: _playerBookingsFuture,
        builder: (context, snapshot) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Your Bookings'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Pending/Searching'),
            Tab(text: 'Completed'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTabContent(username, 'pending_searching'),
          _buildTabContent(username, 'completed'),
          _buildTabContent(username, 'cancelled'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _refreshPlayerBookings(username);
        },
        child: Icon(Icons.refresh),
        heroTag: 'refreshPlayerBookingsButton$username',
      ),
    );
        },
    );
  }

  Widget _buildTabContent(String username, String status) {
    return FutureBuilder<List<PlayerBooking>>(
      future: _playerBookingsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (snapshot.hasData) {
          final filteredBookings = snapshot.data!.where((booking) {
            // Filter bookings based on the provided status
            if (status == 'pending_searching') {
              return booking.bookingstatus == 'pending' || booking.bookingstatus == 'searching';
            } else {
              return booking.bookingstatus == status;
            }
          }).toList();
          return ListView.builder(
            itemCount: filteredBookings.length,
            itemBuilder: (context, index) {
              final booking = filteredBookings[index];
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
                        Text('Booking Owner: ${booking.playerName}'),
                        SizedBox(height: 8),
                        Text('Date: ${booking.date.toIso8601String().substring(0, 10)}'),
                        SizedBox(height: 8),
                        Text('Time: ${booking.start.format(context)} - ${booking.end.format(context)}'),
                        SizedBox(height: 8),
                        if (booking.experience != null)
                          Text('Number of Played Games needed to join: ${booking.experience}'),
                        SizedBox(height: 8),
                        if (booking.gender != null)
                          Text('Gender Adherence: ${booking.gender}'),
                        SizedBox(height: 8),
                        if (booking.gender == 'NO')
                          Text('Players: ${booking.playercount} of ${booking.playermax} joined'),
                        if (booking.gender == 'YES')
                          Text('Male players: ${booking.malecount} of ${booking.malemax} joined, Female players: ${booking.femalecount} of ${booking.femalemax} joined'),
                        SizedBox(height: 16),
                        if (booking.bookingstatus == 'pending' || booking.bookingstatus == 'searching')
                          if (booking.playerowner == 'yes')
                            Row(
                              children: [
                                ElevatedButton(
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlterBookingPopup(bookingId: booking.booking_id, username: widget.username, scriptTime: booking.time),
                                    );
                                  },
                                  child: Text('Alter Details'),
                                ),
                                SizedBox(width: 8.0), // Add spacing between buttons
                                ElevatedButton(
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title: Text('Cancel Booking'),
                                          content: Text('Are you sure you want to cancel this booking?'),
                                          actions: <Widget>[
                                            TextButton(
                                              onPressed: () {
                                                Navigator.of(context).pop(); // Dismiss the popup
                                              },
                                              child: Text('No'),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                Navigator.of(context).pop(); // Dismiss the popup
                                                clearBooking(booking.booking_id); // Call the ClearBooking function
                                              },
                                              child: Text('Yes'),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                  child: Text('Cancel Booking'),
                                ),
                              ],
                            )
                          else
                            ElevatedButton(
                              onPressed: () {
                                _leavePublicBooking(booking.booking_id, username, context);
                              },
                              child: Text('Leave Booking'),
                            ),
                        if (booking.bookingstatus == 'completed' && !booking.reviewed)
                          ElevatedButton(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return ReviewPopup(username: widget.username, bookingId: booking.booking_id);
                                },
                              );
                            },
                            child: Text('Rate and Review'),
                          ),
                        if (booking.bookingstatus == 'completed' && booking.reviewed == true)
                          Text('Review submitted'),
                        if (booking.bookingstatus == 'cancelled')
                          SizedBox.shrink(), // No buttons for cancelled bookings
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        } else {
          return Center(child: Text('No user bookings found.'));
        }
      },
    );
  }
}

class ReviewPopup extends StatefulWidget {
  final int bookingId;
  final String username;

  ReviewPopup({required this.username, required this.bookingId});

  @override
  _ReviewPopupState createState() => _ReviewPopupState();
}

class _ReviewPopupState extends State<ReviewPopup> {
  int _rating = 1; // Default rating
  TextEditingController _reviewController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Rate and Review'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Rating: '),
              DropdownButton<int>(
                value: _rating,
                onChanged: (value) {
                  setState(() {
                    _rating = value!;
                  });
                },
                items: List.generate(5, (index) {
                  return DropdownMenuItem<int>(
                    value: index + 1,
                    child: Text('${index + 1}'),
                  );
                }),
              ),
            ],
          ),
          TextField(
            controller: _reviewController,
            decoration: InputDecoration(labelText: 'Write your review'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // Close the dialog
          },
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            // Validate and submit the review
            _submitReview();
          },
          child: Text('Submit'),
        ),
      ],
    );
  }

  void _submitReview() {
    // Validate and submit the review
    if (_reviewController.text.isNotEmpty) {
      // Show confirmation dialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Are you sure?'),
            content: Text('Once submitted, your review cannot be edited.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('No'),
              ),
              ElevatedButton(
                onPressed: () async {
                  // Close the confirmation dialog
                  Navigator.of(context).pop();
                  // Close the review dialog
                  Navigator.of(context).pop();
                  // Call the postReview function
                  await postReview(
                    widget.username, // Pass the username
                    widget.bookingId, // Pass the bookingId
                    _rating, // Pass the rating
                     _reviewController.text, // Pass the review contents
                    context // Pass the BuildContext
                  );
                },
                child: Text('Yes'),
              ),
            ],
          );
        },
      );
    } else {
      // Show error message if review is empty
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please write your review.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }
}

class UserProfilePage extends StatefulWidget {
  final String username;

  UserProfilePage({required this.username});

  @override
  _UserProfilePageState createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  Map<String, dynamic>? profileData;
  TextEditingController? usernameController;
  TextEditingController? emailController;

  @override
  void initState() {
    super.initState();
    fetchProfileData();
  }

  Future<void> fetchProfileData() async {
    try {
      final data = await fetchUserProfile(widget.username);
      setState(() {
        profileData = data;
        usernameController = TextEditingController(text: data['player_username']);
        emailController = TextEditingController(text: data['player_email']);
      });
    } catch (error) {
      print('Error: $error');
    }
  }

  Future<Map<String, dynamic>> fetchUserProfile(String username) async {
    final response = await http.get(Uri.parse('http://localhost:3000/getprofile?username=$username'));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fetch user profile');
    }
  }

  Future<void> showUpdateProfileDialog() async {
    usernameController = TextEditingController(text: profileData!['player_username']);
    emailController = TextEditingController(text: profileData!['player_email']);

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Update Profile'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                TextField(
                  controller: usernameController,
                  decoration: InputDecoration(labelText: 'Username'),
                ),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(labelText: 'Email'),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Update'),
              onPressed: () {
                final updatedUsername = usernameController?.text ?? '';
                final updatedEmail = emailController?.text ?? '';
                showConfirmationDialog(updatedUsername, updatedEmail);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> showConfirmationDialog(String updatedUsername, String updatedEmail) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Changes'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Username: $updatedUsername'),
                Text('Email: $updatedEmail'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Confirm'),
              onPressed: () {
                // Call updateProfile function
                updateProfile(widget.username, updatedUsername, updatedEmail, context);
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
      ),
      body: profileData == null
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome, ${profileData!['player_username']}',
              style: TextStyle(fontSize: 24.0),
            ),
            SizedBox(height: 16.0),
            Text('Player ID: ${profileData!['player_id']}'),
            Text('Email: ${profileData!['player_email']}'),
            Text('Gender: ${profileData!['player_gender']}'),
            Text('Played Cases: ${profileData!['player_playedcases']}'),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: showUpdateProfileDialog,
              child: Text('Update Profile'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    usernameController?.dispose();
    emailController?.dispose();
    super.dispose();
  }
}

Future<List<Script>> fetchScriptsFromDatabase() async {
  final response = await http.get(Uri.parse('http://localhost:3000/scripts'));

  if (response.statusCode == 200) {
    // Print the raw JSON data received from the backend
    print('Raw JSON data: ${response.body}');

    // Parse the JSON data into a list of Script objects
    List<dynamic> data = json.decode(response.body);
    List<Script> scripts = data.map((item) => Script.fromJson(item)).toList();
    return scripts;
  } else {
    throw Exception('Failed to load scripts');
  }
}

Future<List<Review>> fetchReviewsFromDatabase(int scriptId) async {
  final response = await http.get(Uri.parse('http://localhost:3000/getreviews?script_id=$scriptId'));

  if (response.statusCode == 200) {
    // Print the raw JSON data received from the backend
    print('Raw JSON data: ${response.body}');

    // Parse the JSON data into a list of Review objects
    List<dynamic> data = json.decode(response.body);
    List<Review> reviews = data.map((item) => Review.fromJson(item)).toList();
    return reviews;
  } else {
    throw Exception('Failed to load reviews');
  }
}

Future<List<PublicBooking>> fetchPublicBookingsFromDatabase(String username) async {
  final url = Uri.parse('http://localhost:3000/publicbooking?username=$username');
  print('URL: ${url}');
  final response = await http.get(url);

  if (response.statusCode == 200) {
    // Print the raw JSON data received from the backend
    print('Raw JSON data: ${response.body}');

    // Parse the JSON data into a list of Public Booking objects
    List<dynamic> data = json.decode(response.body);
    List<PublicBooking> publicbookings = data.map((item) => PublicBooking.fromJson(item)).toList();
    return publicbookings;
  } else {
    throw Exception('Failed to load public bookings');
  }
}

Future<List<PlayerBooking>> fetchPlayerBookingsFromDatabase(String username) async {
  final url = Uri.parse('http://localhost:3000/playerbooking?username=$username');
  print('URL: ${url}');
  final response = await http.get(url);

  if (response.statusCode == 200) {
    // Print the raw JSON data received from the backend
    print('Raw JSON data: ${response.body}');

    // Parse the JSON data into a list of Player Booking objects
    List<dynamic> data = json.decode(response.body);
    List<PlayerBooking> playerbookings = data.map((item) => PlayerBooking.fromJson(item)).toList();
    return playerbookings;
  } else {
    throw Exception('Failed to load user bookings');
  }
}

Future<Map<String, dynamic>> fetchPlayerPreferences(String username) async {
  final url = Uri.parse('http://localhost:3000/playerpref?username=$username');
  final response = await http.get(url);

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception('Failed to fetch player preferences');
  }
}

Future<Map<String, dynamic>> fetchUserProfile(String username) async {
  final response = await http.get(Uri.parse('http://localhost:3000/getprofile?username=$username'));

  if (response.statusCode == 200) {
    return json.decode(response.body);
  } else {
    throw Exception('Failed to fetch user profile');
  }
}

void makeBooking(
    String username,
    int scriptId,
    String time,
    String date,
    String publicPrivate,
    int numberOfScriptsPlayed,
    String genderAdherence,
    BuildContext context,
    ) async {
  // Make the API request to book the script
  final response = await http.post(
    Uri.parse('http://localhost:3000/book'),
    headers: {
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'username': username,
      'scriptId': scriptId.toString(),
      'time': time,
      'date': date,
      'publicPrivate': publicPrivate,
      'numberOfScriptsPlayed': numberOfScriptsPlayed.toString(),
      'genderAdherence': genderAdherence,
    }),
  );

  if (response.statusCode == 201) {
    // Booking successful
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Booking successful'),
        duration: Duration(seconds: 2),
      ),
    );
  } else {
    // Booking failed
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Booking failed: ${response.statusCode}'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

Future<void> _joinPublicBooking(int bookingID, String username, BuildContext context) async {
  final url = Uri.parse('http://localhost:3000/join?username=$username&bookingID=$bookingID');
  final response = await http.post(url);

  if (response.statusCode == 201) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Join successful. Refresh to see changes.'),
      ),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to join booking. ${response.reasonPhrase}'),
        ),
    );
    throw Exception('Failed to join booking: ${response.reasonPhrase}');
  }
}

Future<void> _leavePublicBooking(int bookingID, String username, BuildContext context) async {
  final url = Uri.parse('http://localhost:3000/leave?username=$username&bookingID=$bookingID');
  final response = await http.post(url);

  if (response.statusCode == 201) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Leave successful. Refresh to see changes.'),
      ),
    );
  } else {
    // Handle error
    throw Exception('Failed to leave booking: ${response.reasonPhrase}');
  }
}

Future<void> alterBooking(
    String username,
    int bookingId,
    String time,
    String date)
async {
  print('Raw JSON data: ${username}, ${bookingId}, ${time}, ${date}');
  final url = Uri.parse('http://localhost:3000/alter');
  final response = await http.post(
    url,
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(<String, dynamic>{
      'username': username,
      'bookingId': bookingId,
      'time': time,
      'date': date
    }),
  );

  if (response.statusCode == 201) {
    // Booking successful
    print('Booking successful');
  } else {
    // Handle error
    print('Error: ${response.body}');
  }
}

Future<void> clearBooking(int bookingId) async {
  final url = Uri.parse('http://localhost:3000/clear?bookingID=$bookingId');

  try {
    final response = await http.post(url);
    if (response.statusCode == 200) {
      print('Booking successfully deleted');
    } else {
      // Handle error
      print('Failed to delete booking: ${response.body}');
    }
  } catch (error) {
    print('Error: $error');
    // Handle error
  }
}

String formatDuration(Duration duration) {
  String twoDigits(int n) => n.toString().padLeft(2, '0');
  String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
  String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
  return '${duration.inHours}:$twoDigitMinutes:$twoDigitSeconds';
}

Future<int> fetchAvailableRoomCount() async {
  final url = Uri.parse('http://localhost:3000/fetchroomlength');

  try {
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final roomCount = data['roomCount'];
      return roomCount;
    } else {
      print('Failed to fetch available room count: ${response.body}');
      return 0;
    }
  } catch (error) {
    print('Error: $error');
    return 0;
  }
}

Future<void> postReview(
    String username,
    int bookingId,
    int rating,
    String contents,
    BuildContext context
    ) async {
  // Check if the required parameters are provided
  if (username.isEmpty || contents.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Username and review contents are required'),
        duration: Duration(seconds: 2),
      ),
    );
    return;
  }

  // Check if the rating is within the valid range (1-5)
  if (rating < 1 || rating > 5) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Invalid rating value. Rating should be between 1 and 5.'),
        duration: Duration(seconds: 2),
      ),
    );
    return;
  }

  final url = Uri.parse('http://localhost:3000/postreview');
  final requestBody = jsonEncode({
    'username': username,
    'booking_id': bookingId.toString(),
    'rating': rating.toString(),
    'contents': contents,
  });

  try {
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: requestBody,
    );

    if (response.statusCode == 201) {
      // Review successfully posted
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Review posted successfully'),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      // Failed to post review
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to post review: ${response.statusCode}'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  } catch (error) {
    // Error occurred
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: $error'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}


Future<void> updateProfile(String oldUsername, String newUsername, String newEmail, BuildContext context) async {
  final url = Uri.parse('http://localhost:3000/updateProfile');

  final response = await http.post(
    url,
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(<String, dynamic>{
      'oldUsername': oldUsername,
      'newUsername': newUsername,
      'newEmail': newEmail,
    }),
  );

  String message;

  if (response.statusCode == 200) {
    message = 'Profile updated successfully! Re-login to see changes.';
  } else if (response.statusCode == 400) {
    message = 'Empty field, or the username/email has already been taken!';
  } else {
    message = 'Server error, try again later!';
  }

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Update Profile'),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: Text('OK'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}