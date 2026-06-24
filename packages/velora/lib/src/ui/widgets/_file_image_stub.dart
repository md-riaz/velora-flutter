import 'package:flutter/material.dart';

import '../../media/velora_attachment.dart';

Widget buildFileImagePreview(VeloraAttachment a, ColorScheme scheme) =>
    SizedBox(
      width: 112,
      height: 72,
      child: Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          size: 30,
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
