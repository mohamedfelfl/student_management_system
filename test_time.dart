// ignore_for_file: avoid_print
void main() {
  TimeOfDay? parseTime(String text) {
    if (text.isEmpty) return null;
    try {
      final RegExp re = RegExp(r'(\d{1,2}):(\d{2})\s*(AM|PM)?', caseSensitive: false);
      final match = re.firstMatch(text);
      if (match != null) {
        int hour = int.parse(match.group(1)!);
        final int minute = int.parse(match.group(2)!);
        final String? period = match.group(3);
        if (period != null) {
          if (period.toUpperCase() == 'PM' && hour < 12) hour += 12;
          if (period.toUpperCase() == 'AM' && hour == 12) hour = 0;
        }
        return TimeOfDay(hour, minute);
      }
    } catch (_) {}
    return null;
  }
  
  print(parseTime('2:00 PM'));
  print(parseTime('14:00'));
  print(parseTime('12:00 AM'));
  print(parseTime('12:00 PM'));
}

class TimeOfDay {
  final int hour, minute;
  TimeOfDay(this.hour, this.minute);
  @override
  String toString() => '$hour:$minute';
}
