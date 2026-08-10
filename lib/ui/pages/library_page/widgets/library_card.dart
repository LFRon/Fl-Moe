import 'package:flutter/material.dart';

final class LibraryCard extends StatelessWidget {
  const LibraryCard({
    required this.title,
    required this.subtitle,
    required this.asset,
    required this.onPressed,
    super.key,
  });

  final String title;
  final String subtitle;
  final String asset;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      mouseCursor: WidgetStateMouseCursor.clickable,
      borderRadius: BorderRadius.circular(18),
      onTap: onPressed,
      child: SizedBox(
        height: 164,
        child: Row(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(18),
              child: Image.asset(asset, width: 118, height: 118),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: TextStyle(
                        height: 1.45,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
