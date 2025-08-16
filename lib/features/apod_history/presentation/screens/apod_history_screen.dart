import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class ApodHistoryScreen extends StatelessWidget {
  const ApodHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('APOD History'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 10, // Example count
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: ListTile(
              leading: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                ),
                child: Icon(
                  PhosphorIcons.image(PhosphorIconsStyle.fill),
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              title: Text('APOD ${index + 1}'),
              subtitle: Text(
                  'Date: ${DateTime.now().subtract(Duration(days: index)).toString().split(' ')[0]}'),
              trailing: Icon(
                PhosphorIcons.arrowRight(PhosphorIconsStyle.fill),
                color: Theme.of(context).colorScheme.primary,
              ),
              onTap: () {
                // TODO: Navigate to APOD detail
              },
            ),
          );
        },
      ),
    );
  }
}
