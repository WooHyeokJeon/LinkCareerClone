import 'package:flutter/material.dart';
import 'package:team_project/screen_3tab/home_screen.dart';
import 'package:team_project/screen_3tab/contests.dart';
import 'package:team_project/screen_3tab/contest_info.dart';
import 'package:team_project/screen_3tab/schedule.dart';

class PageControl extends StatefulWidget {
  const PageControl({Key? key}) : super(key: key);

  @override
  State<PageControl> createState() => _PageControlState();
}

class _PageControlState extends State<PageControl> with TickerProviderStateMixin {
  TabController? controller;

  @override
  void initState() {
    super.initState();
    controller = TabController(length: 3, vsync: this);
    controller!.addListener(tabListener);
  }

  void tabListener() {
    setState(() {});
  }

  void next() {
    if (controller != null && mounted) {
      int nextIndex = (controller!.index + 1) % controller!.length;
      controller!.animateTo(nextIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TabBarView(
        controller: controller,
        children: renderChildren(),
      ),
      bottomNavigationBar: tabBottomNavigation(),
    );
  }

  List<Widget> renderChildren() {
    return [
      HomeScreen(),
      Contests(),
      Schedule(),// "스케줄" 탭
    ];
  }

  @override
  void dispose() {
    controller!.removeListener(tabListener);
    controller!.dispose();
    super.dispose();
  }

  BottomNavigationBar tabBottomNavigation() {
    return BottomNavigationBar(
      currentIndex: controller!.index,
      onTap: (int index) {
        setState(() {
          controller!.animateTo(index);
        });
      },
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.bungalow),
          label: '홈',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.auto_awesome_motion_outlined),
          label: '공모전',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_month_sharp),
          label: '스케줄',
        ),
      ],
    );
  }
}

