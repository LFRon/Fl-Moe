import 'package:silky_scroll/silky_scroll.dart';

export 'package:silky_scroll/silky_scroll.dart'
    show SilkyCustomScrollView, SilkyListView;

/// Shared desktop scroll tuning for every independently scrollable Fl-Moe
/// region.
///
/// `silky_scroll` uses exponential convergence. Duration controls how quickly
/// the target is approached, while speed controls each wheel step's distance.
const SilkyScrollConfig flMoeSmoothScrollConfig = SilkyScrollConfig(
  silkyScrollDuration: Duration(milliseconds: 350),
  scrollSpeed: 0.4,
);
