import 'package:flutter/material.dart';
import 'package:amikiyo/src/screens/home/widgets/app_bar.dart';
import '../../config/constants.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: customAppBar(context, title: 'Settings'),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [const Color(0xFF1E1E1E), const Color(0xFF1A237E).withOpacity(0.8)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Settings',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text(
                  'Account',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                  ),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, color: Color(0xFF00FF7F)),
                onTap: () {}, // TODO: Implement account settings
              ),
              ListTile(
                title: Text(
                  'Notifications',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                  ),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, color: Color(0xFF00FF7F)),
                onTap: () {}, // TODO: Implement notification settings
              ),
              ListTile(
                title: Text(
                  'Privacy',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                  ),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, color: Color(0xFF00FF7F)),
                onTap: () {}, // TODO: Implement privacy settings
              ),
            ],
          ),
        ),
      ),
    );
  }
}