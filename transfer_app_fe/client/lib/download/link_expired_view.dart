import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class LinkExpiredView extends StatelessWidget {
  const LinkExpiredView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.link_off, size: 80, color: Colors.grey),
              SizedBox(height: 24),
              Text(
                'This link has expired',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text(
                'The download link is no longer valid.\nPlease request a new one.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
