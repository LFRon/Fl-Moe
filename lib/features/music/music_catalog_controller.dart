import 'package:get/get.dart';

import '../../core/backend/music_backend.dart';
import '../../kugou_api.dart';
import 'music_models.dart';

final class MusicCatalogController extends GetxController {
  MusicCatalogController(this._api);

  final MusicBackend _api;
  bool _homeLoading = true;
  bool _homeRequestInFlight = false;
  bool _homeInitialLoadStarted = false;
  String? _homeError;
  List<String> _hotWords = const <String>[];
  List<MusicCollection> _homeCollections = const <MusicCollection>[];

  bool _discoverLoading = false;
  bool _discoverRequestInFlight = false;
  bool _discoverLoaded = false;
  String? _discoverError;
  List<MusicCollection> _discoverCollections = const <MusicCollection>[];
  List<MusicCollection> _rankings = const <MusicCollection>[];

  bool get homeLoading => _homeLoading;
  String? get homeError => _homeError;
  List<String> get hotWords => _hotWords;
  List<MusicCollection> get homeCollections => _homeCollections;

  bool get discoverLoading => _discoverLoading;
  bool get discoverLoaded => _discoverLoaded;
  String? get discoverError => _discoverError;
  List<MusicCollection> get discoverCollections => _discoverCollections;
  List<MusicCollection> get rankings => _rankings;

  Future<void> loadHomeCatalog() async {
    if (_homeInitialLoadStarted) return;
    _homeInitialLoadStarted = true;
    await _loadHomeCatalog();
  }

  Future<void> refreshHomeCatalog() => _loadHomeCatalog();

  Future<void> _loadHomeCatalog() async {
    if (_homeRequestInFlight) return;
    _homeRequestInFlight = true;
    _homeLoading = true;
    _homeError = null;
    update();
    try {
      final results = await Future.wait<KugouResponse<KugouJsonObject>>(
        <Future<KugouResponse<KugouJsonObject>>>[
          _api.hotSearch(),
          _api.callJson(
            '/top/playlist',
            parameters: const <String, Object?>{'page': 1, 'pagesize': 12},
          ),
        ],
      );
      _hotWords = _parseHotWords(results[0].body);
      _homeCollections = _parseCollections(
        results[1].body,
        MusicCollectionKind.playlist,
      );
    } on Object catch (error) {
      _homeError = _friendlyError(error);
    } finally {
      _homeRequestInFlight = false;
      _homeLoading = false;
      update();
    }
  }

  Future<void> loadDiscoverCatalog() async {
    if (_discoverLoaded || _discoverRequestInFlight) return;
    await _loadDiscoverCatalog();
  }

  Future<void> refreshDiscoverCatalog() => _loadDiscoverCatalog();

  Future<void> _loadDiscoverCatalog() async {
    if (_discoverRequestInFlight) return;
    _discoverRequestInFlight = true;
    _discoverLoading = true;
    _discoverError = null;
    update();
    try {
      final results = await Future.wait<KugouResponse<KugouJsonObject>>(
        <Future<KugouResponse<KugouJsonObject>>>[
          _api.callJson(
            '/top/playlist',
            parameters: const <String, Object?>{'page': 1, 'pagesize': 16},
          ),
          _api.callJson('/rank/list'),
        ],
      );
      _discoverCollections = _parseCollections(
        results[0].body,
        MusicCollectionKind.playlist,
      );
      _rankings = _parseCollections(
        results[1].body,
        MusicCollectionKind.ranking,
      );
      _discoverLoaded = true;
    } on Object catch (error) {
      _discoverError = _friendlyError(error);
    } finally {
      _discoverRequestInFlight = false;
      _discoverLoading = false;
      update();
    }
  }

  Future<void> refreshLoadedCatalogs() async {
    await Future.wait<void>(<Future<void>>[
      refreshHomeCatalog(),
      if (_discoverLoaded) refreshDiscoverCatalog(),
    ]);
  }
}

final class MusicCollectionDetailController extends GetxController {
  MusicCollectionDetailController(this._api);

  final MusicBackend _api;
  MusicCollection? _collection;
  bool _loading = false;
  String? _error;
  List<MusicTrack> _tracks = const <MusicTrack>[];

  MusicCollection? get collection => _collection;
  bool get loading => _loading;
  String? get error => _error;
  List<MusicTrack> get tracks => _tracks;

  /// Fetches a collection without changing the collection-detail page state.
  /// This keeps quick-play actions independent from navigation.
  Future<List<MusicTrack>> fetchTracks(MusicCollection collection) async {
    if (collection.id.isEmpty) {
      throw StateError('该内容缺少酷狗集合 ID');
    }
    final response = switch (collection.kind) {
      MusicCollectionKind.playlist => await _api.playlistTracks(
        KugouPlaylistTracksQuery(collectionId: collection.id, pageSize: 100),
      ),
      MusicCollectionKind.ranking => await _api.callJson(
        '/rank/audio',
        parameters: <String, Object?>{
          'rankid': collection.id,
          'page': 1,
          'pagesize': 100,
        },
      ),
    };
    final objects = findObjectList(response.body, const <String>[
      'songlist',
      'songs',
      'lists',
      'list',
      'info',
      'data',
    ]);
    return List<MusicTrack>.unmodifiable(
      objects.map(MusicTrack.fromKugou).where((track) => track.canPlay),
    );
  }

  Future<void> load(MusicCollection collection) async {
    _collection = collection;
    _loading = true;
    _error = null;
    _tracks = const <MusicTrack>[];
    update();
    try {
      _tracks = await fetchTracks(collection);
      if (_tracks.isEmpty) _error = '这个集合暂时没有可播放歌曲';
    } on Object catch (error) {
      _error = _friendlyError(error);
    } finally {
      _loading = false;
      update();
    }
  }
}

final class MusicSearchController extends GetxController {
  MusicSearchController(this._api);

  final MusicBackend _api;
  String _query = '';
  bool _loading = false;
  String? _error;
  List<MusicTrack> _results = const <MusicTrack>[];

  String get query => _query;
  bool get loading => _loading;
  String? get error => _error;
  List<MusicTrack> get results => _results;

  Future<void> search(String query) async {
    final normalized = query.trim();
    if (normalized.isEmpty) return;
    _query = normalized;
    _loading = true;
    _error = null;
    update();
    try {
      final response = await _api.search(
        KugouSearchQuery(keywords: normalized, pageSize: 40),
      );
      final rawTracks = findObjectList(response.body, const <String>[
        'lists',
        'list',
        'songs',
        'data',
      ]);
      _results = rawTracks
          .map(MusicTrack.fromKugou)
          .where((track) => track.canPlay)
          .toList(growable: false);
      if (_results.isEmpty) _error = '没有找到可播放的歌曲';
    } on Object catch (error) {
      _results = const <MusicTrack>[];
      _error = _friendlyError(error);
    } finally {
      _loading = false;
      update();
    }
  }
}

List<String> _parseHotWords(KugouJsonObject body) {
  final objects = findObjectList(body, const <String>[
    'info',
    'list',
    'hot',
    'data',
  ]);
  final words = <String>[];
  for (final object in objects) {
    final word = readString(object, const <String>[
      'keyword',
      'key_word',
      'name',
      'title',
    ]);
    if (word.isNotEmpty && !words.contains(word)) words.add(word);
    if (words.length == 12) break;
  }
  return List<String>.unmodifiable(words);
}

List<MusicCollection> _parseCollections(
  KugouJsonObject body,
  MusicCollectionKind kind,
) {
  final objects = findObjectList(body, const <String>[
    'special_list',
    'list',
    'info',
    'rank_list',
    'data',
  ]);
  final collections = <MusicCollection>[];
  for (final object in objects) {
    final collection = MusicCollection.fromKugou(object, kind: kind);
    if (collection.title.isNotEmpty) collections.add(collection);
    if (collections.length == 16) break;
  }
  return List<MusicCollection>.unmodifiable(collections);
}

String _friendlyError(Object error) {
  if (error is KugouApiException) {
    final body = asJsonObject(error.response.body);
    final message = body == null
        ? ''
        : readString(body, const <String>['error', 'msg', 'message']);
    return message.isEmpty ? '酷狗服务暂时不可用，请稍后重试' : message;
  }
  if (error is KugouTransportException) return '网络连接失败，请检查网络后重试';
  return '加载失败：$error';
}

String describeMusicError(Object error) => _friendlyError(error);
