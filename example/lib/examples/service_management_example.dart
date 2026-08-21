// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';
import 'package:cesium/cesium.dart';

final gitHubStatsServiceProvider = ServiceProvider(() => GitHubStatsService());
final analyticsServiceProvider = ServiceProvider(() => AnalyticsService());

// Cesium service has this implementation
// abstract class CesiumService extends ChangeNotifier {
//  void reset();
// }

class AnalyticsService extends CesiumService {
  @override
  void reset() {
    // Do nothing
  }

  void logStatsLoaded(RepoStats stats) {}
}

class GitHubStatsService extends CesiumService {
  RepoStats? _cachedStats;
  final AnalyticsService _analyticsService = analyticsServiceProvider.inject();
  bool _tracked = false;

  Future<RepoStats> getRepoStats({bool forceRefresh = false}) async {
    // Return in-memory cache if available and refresh isn't forced
    if (!forceRefresh && _cachedStats != null) {
      return _cachedStats!;
    }

    try {
      // Simulate network request
      final stats = await _fetchFromApi();
      _cachedStats = stats;
      return stats;
    } catch (e) {
      // Fallback to cache if network fails, otherwise rethrow
      if (_cachedStats != null) {
        return _cachedStats!;
      }
      rethrow;
    }
  }

  Future<RepoStats> _fetchFromApi() async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate network lag
    const stats = RepoStats(stars: 1420, forks: 310);

    if (!_tracked) {
      _tracked = true;
      _analyticsService.logStatsLoaded(stats);
    }
    return stats;
  }

  @override
  void reset() {
    _cachedStats = null;
    _tracked = false;
  }
}

class RepoStats {
  final int stars;
  final int forks;
  const RepoStats({required this.stars, required this.forks});
}

class ServiceManagementExample extends StatefulWidget {
  const ServiceManagementExample({super.key});

  @override
  State<ServiceManagementExample> createState() =>
      _ServiceManagementExampleState();
}

class _ServiceManagementExampleState extends State<ServiceManagementExample>
    with ManagedListenerMixin {
  final githubService = gitHubStatsServiceProvider.inject();
  late final FutureResource<RepoStats> githubResource = manage(
    FutureResource(future: githubService.getRepoStats),
  );

  @override
  Widget build(BuildContext context) {
    return Center(
      child: githubResource.pipe(
        loading: (context) => CircularProgressIndicator(),
        error: (context, error) => Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Error: $error"),
            ElevatedButton(
              onPressed: () {
                githubResource.runNewFuture(githubService.getRepoStats);
              },
              child: Text("Retry"),
            ),
          ],
        ),
        value: (context, value) => Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 28),
                        const SizedBox(width: 12),
                        Text(
                          "Stars: ${value.stars}",
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.fork_right,
                          color: Colors.blue,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          "Forks: ${value.forks}",
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                githubResource.runNewFuture(
                  () => githubService.getRepoStats(forceRefresh: true),
                );
              },
              label: const Text("Force Refresh"),
            ),
          ],
        ),
      ),
    );
  }
}
