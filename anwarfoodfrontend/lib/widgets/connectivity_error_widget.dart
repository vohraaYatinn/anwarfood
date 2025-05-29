import 'package:flutter/material.dart';
import '../services/connectivity_service.dart';

class ConnectivityErrorWidget extends StatefulWidget {
  final String message;
  final VoidCallback? onRetry;

  const ConnectivityErrorWidget({
    Key? key,
    required this.message,
    this.onRetry,
  }) : super(key: key);

  @override
  State<ConnectivityErrorWidget> createState() => _ConnectivityErrorWidgetState();
}

class _ConnectivityErrorWidgetState extends State<ConnectivityErrorWidget> {
  bool _isChecking = false;

  Future<void> _checkConnectivity() async {
    setState(() {
      _isChecking = true;
    });

    try {
      final status = await ConnectivityService.checkConnectivity();
      
      if (status.isFullyConnected) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Connection restored!'),
            backgroundColor: Colors.green,
          ),
        );
        if (widget.onRetry != null) {
          widget.onRetry!();
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${status.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error checking connectivity: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.wifi_off,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'Connection Issue',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              widget.message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _isChecking ? null : _checkConnectivity,
              icon: _isChecking
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              label: Text(_isChecking ? 'Checking...' : 'Check Connection'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9B1B1B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Troubleshooting Tips:',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('• Check your internet connection'),
                    const Text('• Try switching between WiFi and mobile data'),
                    const Text('• Restart the app'),
                    const Text('• Check if other apps can access the internet'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 