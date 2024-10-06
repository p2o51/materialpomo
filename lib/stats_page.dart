import 'package:flutter/material.dart';
import 'l10n/app_localizations.dart';

class StatsPage extends StatelessWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.stats),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              localizations.totalFocusTime,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Text('0h 0m'), // Replace with actual total focus time
            const SizedBox(height: 20),
            Text(
              localizations.completedTasks,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Text('0'), // Replace with actual completed tasks count
          ],
        ),
      ),
    );
  }
}
