import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerWidget extends StatefulWidget {
  final String url;

  const VideoPlayerWidget({super.key, required this.url});

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  VideoPlayerController? _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.url)
      ..initialize().then((_) {
        if (mounted) setState(() => _initialized = true);
      });
    _controller!.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Center(child: CircularProgressIndicator());
    }

    final controller = _controller!;
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            AspectRatio(
              aspectRatio: controller.value.aspectRatio,
              child: VideoPlayer(controller),
            ),
            GestureDetector(
              onTap: () {
                controller.value.isPlaying
                    ? controller.pause()
                    : controller.play();
              },
              child: AnimatedOpacity(
                opacity: controller.value.isPlaying ? 0 : 1,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.5), // blue overlay
                    shape: BoxShape.circle,
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(12),
                    child: Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 60,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        _buildBottomControls(controller),
      ],
    );
  }

  Widget _buildBottomControls(VideoPlayerController controller) {
    final blueColor = Colors.blue;
    final hoverColor = Colors.blue[300];

    return Container(
      color: Colors.grey[100], // matching panel background
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.black,
            ),
            onPressed: () {
              setState(() {
                controller.value.isPlaying
                    ? controller.pause()
                    : controller.play();
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.stop, color: Colors.black),
            onPressed: () {
              controller.pause();
              controller.seekTo(Duration.zero);
            },
          ),
          Text(
            _formatDuration(controller.value.position),
            style: TextStyle(color: Colors.black),
          ),
          Expanded(
            child: Slider(
              value: controller.value.position.inMilliseconds.toDouble(),
              min: 0.0,
              max: controller.value.duration.inMilliseconds.toDouble(),
              onChanged: (value) {
                controller.seekTo(Duration(milliseconds: value.toInt()));
              },
              activeColor: Colors.black,
              inactiveColor: blueColor,
            ),
          ),
          Text(
            _formatDuration(controller.value.duration),
            style: TextStyle(color: Colors.black),
          ),
        ],
      ),
    );
  }
}
