import 'package:flutter/material.dart';
import 'package:amikiyo/src/screens/home/widgets/app_bar.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: customAppBar(context, title: 'Notifications'),
      body: const Center(child: Text('Notifications Screen - Work in Progress')),
    );
  }
}