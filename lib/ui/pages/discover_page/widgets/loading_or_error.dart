import 'package:flutter/material.dart';

import '../../../widgets/loading_skeletons.dart';

final class LoadingOrError extends StatelessWidget {
  const LoadingOrError({required this.loading, required this.error, super.key});

  final bool loading;
  final String? error;

  @override
  Widget build(BuildContext context) => loading
      ? const FlMoeSkeletonScope(child: SkeletonCollectionGrid(itemCount: 6))
      : SizedBox(height: 160, child: Center(child: Text(error ?? '暂时没有内容')));
}
