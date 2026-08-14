import 'package:get/get.dart';

import '../music/music_models.dart';

enum AppSection { home, discover, collection, search, library, cloud, settings }

final class AppNavigationController extends GetxController {
  AppSection _section = AppSection.home;
  AppSection _collectionOrigin = AppSection.discover;
  String _pendingSearch = '';
  MusicCollection? _selectedCollection;
  bool _nowPlayingVisible = false;

  AppSection get section => _section;
  String get pendingSearch => _pendingSearch;
  MusicCollection? get selectedCollection => _selectedCollection;
  bool get nowPlayingVisible => _nowPlayingVisible;

  void goTo(AppSection value) {
    if (_section == value) return;
    _section = value;
    update();
  }

  void openSearch(String query) {
    _pendingSearch = query.trim();
    _section = AppSection.search;
    update();
  }

  void openCollection(MusicCollection collection) {
    if (_section != AppSection.collection) _collectionOrigin = _section;
    _selectedCollection = collection;
    _section = AppSection.collection;
    update();
  }

  void closeCollection() {
    _section = _collectionOrigin == AppSection.collection
        ? AppSection.discover
        : _collectionOrigin;
    update();
  }

  void showNowPlaying() {
    if (_nowPlayingVisible) return;
    _nowPlayingVisible = true;
    update();
  }

  void hideNowPlaying() {
    if (!_nowPlayingVisible) return;
    _nowPlayingVisible = false;
    update();
  }
}
