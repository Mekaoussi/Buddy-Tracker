import 'package:hive/hive.dart';

part 'work_entry.g.dart';

@HiveType(typeId: 0)
class WorkEntry {
  @HiveField(0)
  DateTime date;
  
  @HiveField(1)
  DateTime? morningEntry;
  
  @HiveField(2)
  DateTime? morningExit;
  
  @HiveField(3)
  DateTime? afternoonEntry;
  
  @HiveField(4)
  DateTime? afternoonExit;
  
  @HiveField(5)
  String notes;

  WorkEntry({
    required this.date,
    this.morningEntry,
    this.morningExit,
    this.afternoonEntry,
    this.afternoonExit,
    this.notes = '',
  });

  // Calculate total hours worked
  double get totalHours {
    double total = 0;
    if (morningEntry != null && morningExit != null) {
      total += morningExit!.difference(morningEntry!).inMinutes / 60;
    }
    if (afternoonEntry != null && afternoonExit != null) {
      total += afternoonExit!.difference(afternoonEntry!).inMinutes / 60;
    }
    return total;
  }
}