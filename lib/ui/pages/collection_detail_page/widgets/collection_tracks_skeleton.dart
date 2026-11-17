import 'package:material_ui/material_ui.dart';

import '../../../widgets/loading_skeletons.dart';

final class CollectionTracksSkeleton extends StatelessWidget {
  const CollectionTracksSkeleton({super.key});

  @override
  Widget build(BuildContext context) =>
      const FlMoeSkeletonScope(child: SkeletonSongList());
}
