import 'package:flutter/material.dart';
import 'package:hbbh/constants/app_constants.dart';

class BusinessHoursPicker extends StatefulWidget {
  final Map<String, Map<String, String>> initialHours;
  final Function(Map<String, Map<String, String>>) onChanged;

  const BusinessHoursPicker({
    Key? key,
    required this.initialHours,
    required this.onChanged,
  }) : super(key: key);

  @override
  _BusinessHoursPickerState createState() => _BusinessHoursPickerState();
}

class _BusinessHoursPickerState extends State<BusinessHoursPicker> {
  late Map<String, Map<String, String>> _hours;

  @override
  void initState() {
    super.initState();
    _hours = Map.from(widget.initialHours);
  }

  Future<TimeOfDay?> _selectTime(BuildContext context, TimeOfDay initialTime) {
    return showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Colors.white,
              hourMinuteTextColor: Theme.of(context).primaryColor,
              dialHandColor: Theme.of(context).primaryColor,
              dialBackgroundColor: Colors.grey[100],
            ),
          ),
          child: child!,
        );
      },
    );
  }

  TimeOfDay _parseTime(String time) {
    final parts = time.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _hours.entries.map((entry) {
        final day = entry.key;
        final hours = entry.value;

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            title: Text(day),
            subtitle: Text('${hours['open']} - ${hours['close']}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  child: const Text('Open'),
                  onPressed: () async {
                    final time = await _selectTime(
                      context,
                      _parseTime(hours['open']!),
                    );
                    if (time != null) {
                      setState(() {
                        _hours[day]!['open'] = _formatTime(time);
                      });
                      widget.onChanged(_hours);
                    }
                  },
                ),
                TextButton(
                  child: const Text('Close'),
                  onPressed: () async {
                    final time = await _selectTime(
                      context,
                      _parseTime(hours['close']!),
                    );
                    if (time != null) {
                      setState(() {
                        _hours[day]!['close'] = _formatTime(time);
                      });
                      widget.onChanged(_hours);
                    }
                  },
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
