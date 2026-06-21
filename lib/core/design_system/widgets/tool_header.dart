import 'package:flutter/material.dart';

import '../../theme/app_typography.dart';

/// Screen title block: a prominent headline plus an optional subtitle.
class ToolHeader extends StatelessWidget {
  const ToolHeader({
    required this.title,
    this.subtitle,
    super.key,
  });

  final String title;

  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(title, style: AppTypography.headline),
        if (subtitle != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              subtitle!,
              style: AppTypography.caption,
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }
}
