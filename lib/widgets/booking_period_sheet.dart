import 'package:flutter/material.dart';

class BookingPeriodSheet extends StatefulWidget {
  final String title;
  final bool showCategorySelector;
  final String initialRentalType;
  final String initialCategory;
  final int initialCount;
  final DateTime initialDate;
  final String initialTime;
  final String buttonText;
  final Function(
    String rentalType,
    String category,
    int count,
    DateTime date,
    String time,
  ) onApply;

  const BookingPeriodSheet({
    super.key,
    this.title = 'Confirm Booking Period',
    this.showCategorySelector = false,
    required this.initialRentalType,
    required this.initialCategory,
    required this.initialCount,
    required this.initialDate,
    required this.initialTime,
    this.buttonText = 'Confirm Booking Period',
    required this.onApply,
  });

  @override
  State<BookingPeriodSheet> createState() => _BookingPeriodSheetState();
}

class _BookingPeriodSheetState extends State<BookingPeriodSheet> {
  late String _rentalType;
  late String _category;
  late int _count;
  late DateTime _date;
  late String _time;

  final List<String> _timeSlots = [
    '09:00', '10:00', '11:00', '12:00', '13:00', '14:00', '15:00', '16:00',
  ];

  final List<int> _quickHours = [2, 3, 4, 6, 8];
  final List<int> _quickDays = [1, 2, 3, 5, 7];

  late List<DateTime> _days;

  @override
  void initState() {
    super.initState();
    _rentalType = widget.initialRentalType;
    _category = widget.initialCategory;
    _count = widget.initialCount;
    _date = widget.initialDate;
    _time = widget.initialTime;

    _generateDays();
  }

  void _generateDays([DateTime? start]) {
    _days = [];
    DateTime d = start ?? DateTime.now();
    for (int i = 0; i < 30; i++) {
      _days.add(d);
      d = d.add(const Duration(days: 1));
    }
  }

  String _fmt(DateTime dt) {
    final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final wd = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'][dt.weekday - 1];
    return '$wd, ${dt.day} ${months[dt.month - 1]}';
  }

  String _fmtTime(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m ${dt.hour < 12 ? "AM" : "PM"}';
  }

  Widget _stepperBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }

  Widget _summaryTile(IconData icon, String title, String value) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF9C27B0), size: 16),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 1)),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final dayNames = ['SUN','MON','TUE','WED','THU','FRI','SAT'];
    final months   = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];

    final startHour = int.tryParse(_time.split(':')[0]) ?? 10;
    final startMinute = int.tryParse(_time.split(':')[1]) ?? 0;
    final startDT = DateTime(_date.year, _date.month, _date.day, startHour, startMinute);
    final endDT = _rentalType == 'Hourly'
        ? startDT.add(Duration(hours: _count))
        : startDT.add(Duration(days: _count));

    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, color: Colors.white, size: 22),
                ),
                Text(widget.title,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const Icon(Icons.help_outline, color: Colors.white38, size: 22),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── Hourly / Daily toggle
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: ['Hourly', 'Daily'].map((tab) {
                        final sel = _rentalType == tab;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _rentalType = tab),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: sel ? const Color(0xFF9C27B0) : Colors.transparent,
                                borderRadius: BorderRadius.circular(11),
                              ),
                              child: Text(
                                tab,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: sel ? Colors.white : Colors.white38,
                                  fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── SELECT CATEGORY (Optional)
                  if (widget.showCategorySelector) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('SELECT CATEGORY',
                            style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                        const Text('Choose what you want to book',
                            style: TextStyle(color: Colors.white24, fontSize: 10)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: ['Studios', 'Equipment', 'Manpower'].map((cat) {
                        final sel = _category == cat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => setState(() => _category = cat),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                              decoration: BoxDecoration(
                                color: sel ? const Color(0xFF9C27B0) : const Color(0xFF2A2A2A),
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                  color: sel ? const Color(0xFF9C27B0) : Colors.white12,
                                ),
                              ),
                              child: Text(
                                cat,
                                style: TextStyle(
                                  color: sel ? Colors.white : Colors.white54,
                                  fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // ── NUMBER OF HOURS / DAYS
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _rentalType == 'Hourly' ? 'NUMBER OF HOURS' : 'NUMBER OF DAYS',
                        style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
                      ),
                      Text(
                        _rentalType == 'Hourly' ? 'Max 12 hours' : 'Max 30 days',
                        style: const TextStyle(color: Color(0xFF9C27B0), fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _stepperBtn(Icons.remove, () {
                        if (_count > 1) setState(() => _count--);
                      }),
                      const SizedBox(width: 32),
                      Column(
                        children: [
                          Text('$_count',
                              style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.bold)),
                          Text(
                            _rentalType == 'Hourly' ? 'SELECTED HOURS' : 'SELECTED DAYS',
                            style: const TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 1),
                          ),
                        ],
                      ),
                      const SizedBox(width: 32),
                      _stepperBtn(Icons.add, () {
                        final max = _rentalType == 'Hourly' ? 12 : 30;
                        if (_count < max) setState(() => _count++);
                      }),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Quick Select Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: (_rentalType == 'Hourly' ? _quickHours : _quickDays).map((val) {
                        final sel = _count == val;
                        final label = _rentalType == 'Hourly' ? '$val hrs' : '$val days';
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: GestureDetector(
                            onTap: () => setState(() => _count = val),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: sel ? const Color(0xFF9C27B0) : const Color(0xFF2A2A2A),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                label,
                                style: TextStyle(
                                  color: sel ? Colors.white : Colors.white54,
                                  fontSize: 12,
                                  fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── SELECT DATE
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _rentalType == 'Daily' ? 'SELECT START DATE' : 'SELECT DATE',
                        style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
                      ),
                      GestureDetector(
                        onTap: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: _date,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: const ColorScheme.dark(
                                    primary: Color(0xFFCA9AFF),
                                    onPrimary: Colors.white,
                                    surface: Color(0xFF1E1E1E),
                                    onSurface: Colors.white,
                                  ),
                                  dialogBackgroundColor: const Color(0xFF1E1E1E),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null) {
                            setState(() {
                              _date = picked;
                              // Regenerate horizontal list starting from the picked date
                              _generateDays(picked);
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2A2A2A),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF9C27B0).withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today_outlined, color: Color(0xFF9C27B0), size: 12),
                              const SizedBox(width: 6),
                              Text('${months[_date.month - 1]} ${_date.day}',
                                  style: const TextStyle(color: Color(0xFF9C27B0), fontSize: 11, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: _days.map((d) {
                        final sel = d.day == _date.day && d.month == _date.month && d.year == _date.year;
                        // For the dayNames array which is SUN..SAT, DateTime.weekday gives 1(Mon) to 7(Sun)
                        // So SUN is index 0, MON is 1. If dt.weekday is 7 (Sun), index should be 0.
                        final dayIndex = d.weekday == 7 ? 0 : d.weekday;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => setState(() => _date = d),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              width: 64,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: const Color(0xFF242424),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: sel ? Colors.white24 : Colors.transparent,
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    dayNames[dayIndex],
                                    style: TextStyle(
                                      color: sel ? Colors.white70 : Colors.white38,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${d.day}',
                                    style: TextStyle(
                                      color: sel ? Colors.white : Colors.white54,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── SELECT START TIME
                  Text(
                    _rentalType == 'Hourly'
                        ? (_category == 'Equipment' ? 'SELECT PICKUP TIME'
                            : _category == 'Manpower' ? 'SELECT SERVICE START TIME'
                            : 'SELECT START TIME')
                        : 'SELECT PICKUP TIME',
                    style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 10,
                      runSpacing: 10,
                      children: _timeSlots.map((slot) {
                        final sel = slot == _time;
                        return GestureDetector(
                          onTap: () => setState(() => _time = slot),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 76,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: sel ? const Color(0xFF9C27B0).withOpacity(0.15) : const Color(0xFF2A2A2A),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: sel ? const Color(0xFF9C27B0) : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              slot,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: sel ? const Color(0xFF9C27B0) : Colors.white54,
                                fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── BOOKING SUMMARY
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('BOOKING SUMMARY',
                          style: TextStyle(color: Color(0xFF9C27B0), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.green.withOpacity(0.3)),
                        ),
                        child: const Text('AVAILABLE',
                            style: TextStyle(color: Colors.green, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF242424),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(child: _summaryTile(Icons.category_outlined, 'CATEGORY', _category)),
                            Expanded(child: _summaryTile(Icons.calendar_today_outlined, 'DATE', _fmt(_date))),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(child: _summaryTile(Icons.access_time_rounded, 'PICKUP', _fmtTime(startDT))),
                            Expanded(child: _summaryTile(Icons.update_rounded,
                                _rentalType == 'Hourly' ? 'RETURN' : 'RETURN DATE',
                                _rentalType == 'Hourly' ? _fmtTime(endDT) : _fmt(_date))),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Policies
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF242424),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.shield_outlined, color: Colors.green, size: 16),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Policies Checked',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                              Text('Cancellation & Insurance verified',
                                  style: TextStyle(color: Colors.white38, fontSize: 11)),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.white24, size: 20),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // ── ACTION BUTTON
          Padding(
            padding: EdgeInsets.fromLTRB(20, 8, 20, MediaQuery.of(context).padding.bottom + 16),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () {
                  widget.onApply(_rentalType, _category, _count, _date, _time);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFCA9AFF),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  elevation: 0,
                ),
                child: Text(widget.buttonText,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
