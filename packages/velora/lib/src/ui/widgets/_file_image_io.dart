import 'dart:io';

import 'package:flutter/material.dart';

import '../../media/velora_attachment.dart';

Widget buildFileImagePreview(VeloraAttachment a, ColorScheme scheme) =>
    Image.file(
      File(a.localPath!),
      width: 112,
      height: 72,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => SizedBox(
        width: 112,
        height: 72,
        child: Center(
          child: Icon(
            Icons.broken_image_outlined,
            size: 30,
            color: scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
