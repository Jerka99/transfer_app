import 'package:flutter/material.dart';

class PdfWidget extends StatelessWidget {
  const PdfWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        Icon(Icons.picture_as_pdf, size: 120),
        SizedBox(height: 16),
        Text('PDF preview not supported'),
      ],
    );
  }
}
