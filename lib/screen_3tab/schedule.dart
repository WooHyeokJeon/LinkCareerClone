import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Schedule extends StatefulWidget {
  const Schedule({Key? key}) : super(key: key);

  @override
  State<Schedule> createState() => _ScheduleState();
}

class _ScheduleState extends State<Schedule> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<Map<String, dynamic>> events = []; // 공모전 데이터 저장
  List<Map<String, dynamic>> selectedEvents = []; // 선택된 날짜의 데이터 저장

  @override
  void initState() {
    super.initState();
    fetchEvents(); // Firebase 데이터 가져오기
  }

  /// Firebase에서 데이터를 가져오는 함수
  /// Firebase에서 데이터를 가져오는 함수
  Future<void> fetchEvents() async {
    try {
      final snapshot =
      await FirebaseFirestore.instance.collection('contests').get();
      setState(() {
        events = snapshot.docs.map((doc) {
          final startDateString = doc['start_date'].toString();
          final endDateString = doc['end_date'].toString();

          // YYYYMMDD 문자열을 DateTime으로 변환
          final startDate = DateTime(
            int.parse(startDateString.substring(0, 4)), // 연도
            int.parse(startDateString.substring(4, 6)), // 월
            int.parse(startDateString.substring(6, 8)), // 일
          );
          final endDate = DateTime(
            int.parse(endDateString.substring(0, 4)), // 연도
            int.parse(endDateString.substring(4, 6)), // 월
            int.parse(endDateString.substring(6, 8)), // 일
          );

          return {
            "title": doc['title'],
            "startDate": startDate,
            "endDate": endDate,
          };
        }).toList();
      });
    } catch (e) {
      print('데이터를 가져오는 중 오류 발생: $e');
    }
  }


  /// 특정 날짜에 해당하는 이벤트 필터링
  void filterEvents(DateTime day) {
    setState(() {
      selectedEvents = events.where((event) {
        final startDate = event['startDate'] as DateTime;
        final endDate = event['endDate'] as DateTime;
        return isSameDay(day, startDate) || isSameDay(day, endDate);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    return Scaffold(
      appBar: AppBar(
        title: Text('스케줄'),
        backgroundColor: Color(0xFF1876FB),
      ),
      body: Column(
        children: [
          // 캘린더 위젯
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                  filterEvents(selectedDay); // 선택된 날짜에 맞는 이벤트 필터링
                });
              },
              calendarFormat: _calendarFormat,
              onFormatChanged: (format) {
                setState(() {
                  _calendarFormat = format;
                });
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
            ),
          ),

          // 선택된 날짜의 공모전 데이터 표시
          Expanded(
            child: selectedEvents.isEmpty
                ? Center(
              child: Text(
                '선택한 날짜에 해당하는 공모전이 없습니다.',
                style: TextStyle(color: Colors.black54, fontSize: 16),
              ),
            )
                : ListView.builder(
              itemCount: selectedEvents.length,
              itemBuilder: (context, index) {
                final event = selectedEvents[index];
                return ListTile(
                  title: Text(event['title']),
                  subtitle: Text(
                    '시작일: ${event['startDate'].toString().split(' ')[0]} | 마감일: ${event['endDate'].toString().split(' ')[0]}',
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}