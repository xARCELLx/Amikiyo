import 'package:flutter/material.dart';
import 'package:amikiyo/src/screens/home/widgets/app_bar.dart';
import 'package:amikiyo/src/screens/home/widgets/bottom_nav_bar.dart';
import 'package:amikiyo/src/screens/home/widgets/fab.dart';

class GroupsScreen extends StatelessWidget {
  const GroupsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: customAppBar(context, title: 'Groups'),
      body: const Center(child: Text('Groups Screen - Work in Progress')),
      floatingActionButton: customFAB(context),
      bottomNavigationBar: BottomNavBar(currentIndex: 1),
    );
  }
}