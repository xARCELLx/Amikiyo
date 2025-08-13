import 'package:flutter/material.dart';
import 'package:amikiyo/src/screens/home/widgets/app_bar.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: customAppBar(context, title: 'Search'),
      body: const Center(child: Text('Search Screen - Work in Progress')),
    );
  }
}