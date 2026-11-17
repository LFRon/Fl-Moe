import 'package:material_ui/material_ui.dart';

import '../../../scrolling/fl_moe_smooth_scroll.dart';
import '../../../widgets/loading_skeletons.dart';

final class SearchResultsSkeleton extends StatelessWidget {
  const SearchResultsSkeleton({super.key});

  @override
  Widget build(BuildContext context) => FlMoeSkeletonScope(
    child: SilkyListView(
      silkyConfig: flMoeSmoothScrollConfig,
      key: const ValueKey<String>('search-results-skeleton'),
      children: const <Widget>[
        Row(
          children: <Widget>[
            FlMoeSkeletonLine(width: 190, height: 20),
            Spacer(),
            FlMoeSkeletonLine(width: 48),
          ],
        ),
        SizedBox(height: 16),
        SkeletonSongList(),
      ],
    ),
  );
}
