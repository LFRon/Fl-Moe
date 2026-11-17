import 'package:material_ui/material_ui.dart';
import 'package:page_transition/page_transition.dart';

import '../features/navigation/app_navigation_controller.dart';

const Duration flMoePageTransitionDuration = Duration(milliseconds: 310);

/// Applies page_transition effects without changing Fl-Moe's lazy page
/// construction. Only the selected page and short-lived outgoing pages remain
/// in the widget tree.
final class FlMoePageTransition extends StatefulWidget {
  const FlMoePageTransition({
    required this.section,
    required this.child,
    super.key,
  });

  final AppSection section;
  final Widget child;

  @override
  State<FlMoePageTransition> createState() => _FlMoePageTransitionState();
}

final class _FlMoePageTransitionState extends State<FlMoePageTransition> {
  bool _useCollectionTransition = false;

  @override
  void didUpdateWidget(covariant FlMoePageTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.section == widget.section) {
      return;
    }

    final bool enteringCollection = widget.section == AppSection.collection;
    final bool leavingCollection = oldWidget.section == AppSection.collection;
    _useCollectionTransition = enteringCollection || leavingCollection;
  }

  @override
  Widget build(BuildContext context) {
    final Widget page = KeyedSubtree(
      key: ValueKey<AppSection>(widget.section),
      child: RepaintBoundary(child: widget.child),
    );

    if (MediaQuery.disableAnimationsOf(context)) {
      return page;
    }

    return AnimatedSwitcher(
      duration: flMoePageTransitionDuration,
      reverseDuration: flMoePageTransitionDuration,
      transitionBuilder: _useCollectionTransition
          ? _buildCollectionTransition
          : _buildTopLevelTransition,
      layoutBuilder: _buildExpandedLayout,
      child: page,
    );
  }
}

Widget _buildTopLevelTransition(Widget child, Animation<double> animation) =>
    _PageTransitionEffect(
      type: PageTransitionType.fade,
      animation: animation,
      child: child,
    );

Widget _buildCollectionTransition(Widget child, Animation<double> animation) =>
    _PageTransitionEffect(
      type: PageTransitionType.sharedAxisScale,
      animation: animation,
      child: child,
    );

Widget _buildExpandedLayout(
  Widget? currentChild,
  List<Widget> previousChildren,
) => Stack(
  alignment: Alignment.center,
  fit: StackFit.expand,
  children: <Widget>[...previousChildren, ?currentChild],
);

final class _PageTransitionEffect extends StatelessWidget {
  const _PageTransitionEffect({
    required this.type,
    required this.animation,
    required this.child,
  });

  final PageTransitionType type;
  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final route = PageTransition<void>(
      type: type,
      duration: flMoePageTransitionDuration,
      reverseDuration: flMoePageTransitionDuration,
      curve: Curves.easeInOutCubic,
      opaque: true,
      child: child,
    );
    return route.buildTransitions(
      context,
      animation,
      kAlwaysDismissedAnimation,
      child,
    );
  }
}
