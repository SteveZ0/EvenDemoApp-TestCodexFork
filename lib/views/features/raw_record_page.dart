import 'package:demo_ai_even/services/raw_audio_service.dart';
import 'package:flutter/material.dart';

class RawRecordPage extends StatefulWidget {
  const RawRecordPage({super.key});

  @override
  State<RawRecordPage> createState() => _RawRecordPageState();
}

class _RawRecordPageState extends State<RawRecordPage> {
  double _interval = RawAudioService.instance.touchInterval;

  @override
  void initState() {
    super.initState();
    RawAudioService.instance.start();
  }

  @override
  void dispose() {
    RawAudioService.instance.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Raw Audio Recording Test')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Touch interval: ${_interval.toStringAsFixed(2)}s'),
            Slider(
              value: _interval,
              min: 0.1,
              max: 1.0,
              divisions: 9,
              label: _interval.toStringAsFixed(2),
              onChanged: (v) {
                setState(() {
                  _interval = v;
                  RawAudioService.instance.touchInterval = v;
                });
              },
            ),
            const SizedBox(height: 20),
            const Text('Start by tapping both pads simultaneously.'),
            const SizedBox(height: 12),
            ValueListenableBuilder<String?>(
              valueListenable: RawAudioService.instance.lastSavedFile,
              builder: (context, path, _) {
                if (path == null) return const SizedBox.shrink();
                return Text('Saved file: $path');
              },
            ),
          ],
        ),
      ),
    );
  }
}
