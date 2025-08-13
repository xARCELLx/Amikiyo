import 'package:flutter/material.dart';
import 'package:amikiyo/src/config/constants.dart';
import 'package:amikiyo/src/screens/search/search_screen.dart';
import 'package:amikiyo/src/screens/notifications/notifications_screen.dart';

AppBar customAppBar(BuildContext context, {required String title}) {
  return AppBar(
    title: Text(title, style: Theme.of(context).textTheme.titleLarge),
    leading: Padding(
      padding: const EdgeInsets.all(8.0),
      child: Image.asset(Constants.logoPath, fit: BoxFit.contain),
    ),
    actions: [
      IconButton(
        icon: const Icon(Icons.search),
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const SearchScreen()));
        },
      ),
      IconButton(
        icon: const Icon(Icons.notifications),
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationsScreen()));
        },
      ),
    ],
  );
}