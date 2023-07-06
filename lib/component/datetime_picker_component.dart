import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:table_calendar/table_calendar.dart';

import '../consts/base.dart';
import '../generated/l10n.dart';
import '../util/router_util.dart';

class DatetimePickerComponent extends StatefulWidget {
  DateTime? dateTime;

  bool showDate;

  bool showHour;

  DatetimePickerComponent({
    this.dateTime,
    required this.showDate,
    required this.showHour,
  });

  static Future<DateTime?> show(
    BuildContext context, {
    DateTime? dateTime,
    bool showDate = true,
    bool showHour = true,
  }) async {
    return await showDialog(
      context: context,
      builder: (_context) {
        return DatetimePickerComponent(
          dateTime: dateTime,
          showDate: showDate,
          showHour: showHour,
        );
      },
    );
  }

  @override
  State<StatefulWidget> createState() {
    return _DatetimePickerComponent();
  }
}

class _DatetimePickerComponent extends State<DatetimePickerComponent> {
  final FocusScopeNode _focusScopeNode = FocusScopeNode();

  int hour = 12;

  int minute = 0;

  DateTime _selectedDay = DateTime.now();

  DateTime _currentDay = DateTime.now();

  @override
  void initState() {
    super.initState();

    if (widget.dateTime != null) {
      _selectedDay = widget.dateTime!;
      hour = widget.dateTime!.hour;
      minute = widget.dateTime!.minute;
    }
  }

  @override
  Widget build(BuildContext context) {
    var themeData = Theme.of(context);
    var scaffoldBackgroundColor = themeData.scaffoldBackgroundColor;
    var mainColor = themeData.appBarTheme.backgroundColor;
    var bigTextSize = themeData.textTheme.bodyLarge!.fontSize;
    var s = S.of(context);

    var now = DateTime.now();
    var calendarFirstDay = now.add(Duration(days: -3650));
    var calendarLastDay = now.add(Duration(days: 3650));

    var titleDateFormat = DateFormat("MMM yyyy");

    var datePicker = Container(
      margin: EdgeInsets.only(
        bottom: Base.BASE_PADDING,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: EdgeInsets.only(
              top: Base.BASE_PADDING,
              bottom: Base.BASE_PADDING + Base.BASE_PADDING_HALF,
            ),
            child: Text(
              titleDateFormat.format(_currentDay),
              style: TextStyle(
                fontSize: bigTextSize,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TableCalendar(
            firstDay: calendarFirstDay,
            lastDay: calendarLastDay,
            focusedDay: _selectedDay,
            headerVisible: false,
            selectedDayPredicate: (d) {
              return isSameDay(d, _selectedDay);
            },
            calendarStyle: CalendarStyle(
              rangeHighlightColor: mainColor!,
              selectedDecoration: BoxDecoration(
                color: mainColor.withOpacity(0.8),
                shape: BoxShape.circle,
              ),
              todayTextStyle: TextStyle(
                fontSize: 16.0,
              ),
              todayDecoration: BoxDecoration(
                color: null,
              ),
            ),
            onDaySelected: (DateTime selectedDay, DateTime focusedDay) {
              print(selectedDay);
              setState(() {
                _selectedDay = selectedDay;
              });
            },
            onPageChanged: (dateTime) {
              setState(() {
                _currentDay = dateTime;
                _selectedDay = dateTime;
              });
            },
            startingDayOfWeek: StartingDayOfWeek.monday,
          ),
        ],
      ),
    );

    var timeTitleTextStyle = TextStyle(
      fontSize: bigTextSize,
      fontWeight: FontWeight.bold,
    );
    var timePicker = Container(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          buildNumberPicker(s.Hour, 0, 23, hour, (value) {
            setState(() {
              hour = value;
            });
          }, timeTitleTextStyle),
          Text(
            ":",
            style: timeTitleTextStyle,
          ),
          buildNumberPicker(s.Minute, 0, 59, minute, (value) {
            setState(() {
              minute = value;
            });
          }, timeTitleTextStyle),
        ],
      ),
    );

    List<Widget> mainList = [
      // datePicker,
      // timePicker,
    ];
    if (widget.showDate) {
      mainList.add(datePicker);
    }
    if (widget.showHour) {
      mainList.add(timePicker);
    }

    mainList.add(InkWell(
      child: Container(
        height: 40,
        color: mainColor,
        child: Center(
          child: Text(
            s.Comfirm,
            style: TextStyle(
              color: Colors.white,
              fontSize: bigTextSize,
            ),
          ),
        ),
      ),
      onTap: comfirm,
    ));

    var main = Container(
      color: scaffoldBackgroundColor,
      padding: const EdgeInsets.all(Base.BASE_PADDING),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: mainList,
      ),
    );

    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.2),
      body: FocusScope(
        // Overlay 中 textField autoFocus 需要包一层 FocusScope
        node: _focusScopeNode,
        // autofocus: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: cancelFunc,
          child: Container(
            width: double.infinity,
            height: double.infinity,
            child: GestureDetector(
              // 防止误关闭了页面
              onTap: () {},
              child: main,
            ),
            alignment: Alignment.center,
          ),
        ),
      ),
    );
  }

  void cancelFunc() {
    RouterUtil.back(context);
  }

  Widget buildNumberPicker(String title, int min, int max, int value,
      Function(int) onChange, TextStyle textStyle) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: textStyle,
          ),
          NumberPicker(
            itemCount: 1,
            minValue: min,
            maxValue: max,
            value: value,
            onChanged: onChange,
          )
        ],
      ),
    );
  }

  void comfirm() {
    var dateTime = DateTime(
        _selectedDay.year, _selectedDay.month, _selectedDay.day, hour, minute);
    RouterUtil.back(context, dateTime);
  }
}
