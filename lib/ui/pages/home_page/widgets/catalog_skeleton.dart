import 'package:flutter/material.dart';

import '../../../widgets/loading_skeletons.dart';

final class CatalogSkeleton extends StatelessWidget {
  const CatalogSkeleton({super.key});

  @override
  Widget build(BuildContext context) =>
      const FlMoeSkeletonScope(child: SkeletonCollectionGrid(itemCount: 6));
}

final class HotWordsSkeleton extends StatelessWidget {
  const HotWordsSkeleton({super.key});

  @override
  Widget build(BuildContext context) => FlMoeSkeletonScope(
    child: Wrap(
      key: const ValueKey<String>('hot-words-skeleton'),
      spacing: 10,
      runSpacing: 10,
      children: List<Widget>.generate(
        9,
        (index) => FlMoeSkeletonBox(
          width: 78 + (index % 4) * 16,
          height: 34,
          borderRadius: const BorderRadius.all(Radius.circular(18)),
        ),
        growable: false,
      ),
    ),
  );
}
