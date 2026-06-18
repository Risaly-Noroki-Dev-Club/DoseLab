import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// Reference-only disclaimer required by product policy on every
/// FDA-derived view. Render this anywhere we surface FDA label or
/// PK content so the "not medical advice" stance stays visible.
class DisclaimerBanner extends StatelessWidget {
  const DisclaimerBanner({super.key, this.dense = false});

  final bool dense;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: 12,
        vertical: dense ? 6 : 8,
      ),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Text(
        t.disclaimer,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: dense ? 11 : 12,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
