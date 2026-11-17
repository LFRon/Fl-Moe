import 'package:material_ui/material_ui.dart';
import 'package:skeleton_shimmer/skeleton_shimmer.dart';

/// Gives every bone below it one synchronized shimmer sweep and paint layer.
final class FlMoeSkeletonScope extends StatelessWidget {
  const FlMoeSkeletonScope({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      container: true,
      liveRegion: true,
      label: '正在加载内容',
      child: RepaintBoundary(
        child: Shimmer.fromColors(
          period: const Duration(milliseconds: 1450),
          baseColor: scheme.surfaceContainerHighest,
          highlightColor: scheme.surfaceContainerLowest,
          child: child,
        ),
      ),
    );
  }
}

final class FlMoeSkeletonBox extends StatelessWidget {
  const FlMoeSkeletonBox({
    this.width,
    this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
    super.key,
  });

  final double? width;
  final double? height;
  final BorderRadiusGeometry borderRadius;

  @override
  Widget build(BuildContext context) =>
      SkeletonBox(width: width, height: height, borderRadius: borderRadius);
}

final class FlMoeSkeletonLine extends StatelessWidget {
  const FlMoeSkeletonLine({this.width, this.height = 14, super.key});

  final double? width;
  final double height;

  @override
  Widget build(BuildContext context) =>
      SkeletonLine(width: width, height: height);
}

final class FlMoeSkeletonCircle extends StatelessWidget {
  const FlMoeSkeletonCircle({required this.size, super.key});

  final double size;

  @override
  Widget build(BuildContext context) => SkeletonCircle(size: size);
}

final class SkeletonCollectionGrid extends StatelessWidget {
  const SkeletonCollectionGrid({this.itemCount = 12, super.key});

  final int itemCount;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final count = (constraints.maxWidth / 190).floor().clamp(2, 6);
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: count,
          mainAxisSpacing: 18,
          crossAxisSpacing: 18,
          childAspectRatio: 0.84,
        ),
        itemCount: itemCount,
        itemBuilder: (context, index) => const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: FlMoeSkeletonBox(
                borderRadius: BorderRadius.all(Radius.circular(17)),
              ),
            ),
            SizedBox(height: 10),
            FlMoeSkeletonLine(),
            SizedBox(height: 6),
            FlMoeSkeletonLine(width: 110, height: 11),
          ],
        ),
      );
    },
  );
}

final class SkeletonSongList extends StatelessWidget {
  const SkeletonSongList({this.itemCount = 7, super.key});

  final int itemCount;

  @override
  Widget build(BuildContext context) => Column(
    children: List<Widget>.generate(
      itemCount,
      (index) => const Padding(
        padding: EdgeInsets.only(bottom: 8),
        child: SizedBox(
          height: 58,
          child: Row(
            children: <Widget>[
              FlMoeSkeletonLine(width: 24, height: 12),
              SizedBox(width: 18),
              FlMoeSkeletonBox(
                width: 48,
                height: 48,
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
              SizedBox(width: 14),
              Expanded(
                flex: 5,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    FlMoeSkeletonLine(width: 210),
                    SizedBox(height: 8),
                    FlMoeSkeletonLine(width: 130, height: 11),
                  ],
                ),
              ),
              Expanded(flex: 3, child: FlMoeSkeletonLine(width: 150)),
              SizedBox(width: 24),
              FlMoeSkeletonLine(width: 42),
              SizedBox(width: 22),
            ],
          ),
        ),
      ),
      growable: false,
    ),
  );
}
