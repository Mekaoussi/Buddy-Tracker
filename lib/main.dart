import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'models/work_entry.dart';

// Define TimeType enum
enum TimeType {
  morningEntry,
  morningExit,
  afternoonEntry,
  afternoonExit,
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final appDocumentDirectory =
      await path_provider.getApplicationDocumentsDirectory();
  Hive.init(appDocumentDirectory.path);
  await Hive.initFlutter();

  Hive.registerAdapter(WorkEntryAdapter());
  await Hive.openBox<WorkEntry>('entries');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Work Tracker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const DailyTrackerPage(),
    const MonthlyReportPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Work Tracker'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.today),
            label: 'Daily',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: 'Monthly',
          ),
        ],
      ),
    );
  }
}

class DailyTrackerPage extends StatefulWidget {
  const DailyTrackerPage({super.key});

  @override
  State<DailyTrackerPage> createState() => _DailyTrackerPageState();
}

class _DailyTrackerPageState extends State<DailyTrackerPage> {
  Box<WorkEntry>? _entriesBox;
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _openBox();
  }

  Future<void> _openBox() async {
    if (Hive.isBoxOpen('entries')) {
      _entriesBox = Hive.box<WorkEntry>('entries');
    } else {
      _entriesBox = await Hive.openBox<WorkEntry>('entries');
    }
    setState(() {}); // Refresh UI after box is opened
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  String _getDateKey(DateTime date) {
    return "${date.year}-${date.month}-${date.day}";
  }

  WorkEntry _getOrCreateEntry(DateTime date) {
    if (_entriesBox == null) {
      // Return a temporary entry if box isn't ready yet
      return WorkEntry(date: DateTime(date.year, date.month, date.day));
    }

    final key = _getDateKey(date);
    final normalizedDate = DateTime(date.year, date.month, date.day);

    if (!_entriesBox!.containsKey(key)) {
      final newEntry = WorkEntry(date: normalizedDate);
      _entriesBox!.put(key, newEntry);
    }

    return _entriesBox!.get(key)!;
  }

  void _recordTime(TimeType type) {
    if (_entriesBox == null) return;

    final now = DateTime.now();
    final entry = _getOrCreateEntry(_selectedDate);

    switch (type) {
      case TimeType.morningEntry:
        entry.morningEntry = now;
        break;
      case TimeType.morningExit:
        entry.morningExit = now;
        break;
      case TimeType.afternoonEntry:
        entry.afternoonEntry = now;
        break;
      case TimeType.afternoonExit:
        entry.afternoonExit = now;
        break;
    }

    _entriesBox!.put(_getDateKey(_selectedDate), entry);
    setState(() {});
  }

  Future<void> _selectCustomTime(TimeType type) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime != null && _entriesBox != null) {
      final customDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );

      final entry = _getOrCreateEntry(_selectedDate);

      switch (type) {
        case TimeType.morningEntry:
          entry.morningEntry = customDateTime;
          break;
        case TimeType.morningExit:
          entry.morningExit = customDateTime;
          break;
        case TimeType.afternoonEntry:
          entry.afternoonEntry = customDateTime;
          break;
        case TimeType.afternoonExit:
          entry.afternoonExit = customDateTime;
          break;
      }

      _entriesBox!.put(_getDateKey(_selectedDate), entry);
      setState(() {});
    }
  }

  void _saveNotes() {
    if (_entriesBox == null) return;

    final entry = _getOrCreateEntry(_selectedDate);
    entry.notes = _notesController.text;
    _entriesBox!.put(_getDateKey(_selectedDate), entry);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notes saved')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final entry = _getOrCreateEntry(_selectedDate);
    _notesController.text = entry.notes;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date selector
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    _selectedDate =
                        _selectedDate.subtract(const Duration(days: 1));
                  });
                },
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (date != null) {
                      setState(() {
                        _selectedDate = date;
                      });
                    }
                  },
                  child: Center(
                    child: Text(
                      DateFormat.yMMMMd().format(_selectedDate),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward),
                onPressed: () {
                  setState(() {
                    _selectedDate = _selectedDate.add(const Duration(days: 1));
                  });
                },
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Morning section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Morning Session',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Entry Time'),
                            const SizedBox(height: 8),
                            Text(
                              entry.morningEntry != null
                                  ? DateFormat.Hm().format(entry.morningEntry!)
                                  : 'Not recorded',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () =>
                                _selectCustomTime(TimeType.morningEntry),
                            tooltip: 'Set custom time',
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () => _recordTime(TimeType.morningEntry),
                            child: const Text('Record Now'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Exit Time'),
                            const SizedBox(height: 8),
                            Text(
                              entry.morningExit != null
                                  ? DateFormat.Hm().format(entry.morningExit!)
                                  : 'Not recorded',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () =>
                                _selectCustomTime(TimeType.morningExit),
                            tooltip: 'Set custom time',
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () => _recordTime(TimeType.morningExit),
                            child: const Text('Record Now'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Afternoon section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Afternoon Session',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Entry Time'),
                            const SizedBox(height: 8),
                            Text(
                              entry.afternoonEntry != null
                                  ? DateFormat.Hm()
                                      .format(entry.afternoonEntry!)
                                  : 'Not recorded',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () =>
                                _selectCustomTime(TimeType.afternoonEntry),
                            tooltip: 'Set custom time',
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () =>
                                _recordTime(TimeType.afternoonEntry),
                            child: const Text('Record Now'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Exit Time'),
                            const SizedBox(height: 8),
                            Text(
                              entry.afternoonExit != null
                                  ? DateFormat.Hm().format(entry.afternoonExit!)
                                  : 'Not recorded',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () =>
                                _selectCustomTime(TimeType.afternoonExit),
                            tooltip: 'Set custom time',
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () =>
                                _recordTime(TimeType.afternoonExit),
                            child: const Text('Record Now'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Notes section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Work Notes',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      hintText: 'Enter notes about work done today',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: _saveNotes,
                      child: const Text('Save Notes'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Summary
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Daily Summary',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 16),
                  Text(
                      'Total hours worked: ${entry.totalHours.toStringAsFixed(2)}'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MonthlyReportPage extends StatefulWidget {
  const MonthlyReportPage({super.key});

  @override
  State<MonthlyReportPage> createState() => _MonthlyReportPageState();
}

class _MonthlyReportPageState extends State<MonthlyReportPage> {
  DateTime _selectedMonth = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month selector
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    _selectedMonth = DateTime(
                      _selectedMonth.year,
                      _selectedMonth.month - 1,
                      1,
                    );
                  });
                },
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _selectedMonth,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (date != null) {
                      setState(() {
                        _selectedMonth = DateTime(date.year, date.month, 1);
                      });
                    }
                  },
                  child: Center(
                    child: Text(
                      DateFormat.yMMMM().format(_selectedMonth),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward),
                onPressed: () {
                  setState(() {
                    _selectedMonth = DateTime(
                      _selectedMonth.year,
                      _selectedMonth.month + 1,
                      1,
                    );
                  });
                },
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Monthly summary placeholder
          Expanded(
            child: Center(
              child: Text(
                'Monthly report will be displayed here.\nConnect to a database to store and retrieve work entries.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
