import 'package:get/get.dart';

import '../../core/backend/music_backend.dart';
import '../../kugou_api.dart';
import 'music_models.dart';

typedef _FavoriteAccountIdentity = ({
  KugouClientVariant variant,
  String userId,
});

/// Lazily exposes the signed-in account's “我喜欢” playlist.
///
/// Nothing is requested during application or library-page startup. The first
/// page is fetched only after the user opens the favorite entry, and remaining
/// pages are requested as the dedicated track list approaches its end.
final class FavoriteTracksController extends GetxController {
  FavoriteTracksController(this._backend);

  static const int _pageSize = 100;
  static const int _playlistPageSize = 100;
  static const int _maxPlaylistPages = 10;

  final MusicBackend _backend;
  _FavoriteAccountIdentity? _identity;
  List<MusicTrack> _tracks = const <MusicTrack>[];
  String _listId = '';
  String _collectionId = '';
  _FavoriteTrackSource? _trackSource;
  _FavoriteTrackPage? _cachedPrivateFirstPage;
  int _nextPage = 1;
  int _reportedTotal = 0;
  bool _loaded = false;
  bool _loading = false;
  bool _loadingMore = false;
  bool _hasMore = false;
  String? _error;
  Future<void>? _initialRequest;
  Future<void>? _moreRequest;
  int _revision = 0;

  bool get _isCurrentIdentity => _identity == _currentIdentity;

  List<MusicTrack> get tracks =>
      _isCurrentIdentity ? _tracks : const <MusicTrack>[];
  bool get loaded => _isCurrentIdentity && _loaded;
  bool get loading => _isCurrentIdentity && _loading;
  bool get loadingMore => _isCurrentIdentity && _loadingMore;
  bool get hasMore => _isCurrentIdentity && !_loading && _hasMore;
  String? get error => _isCurrentIdentity ? _error : null;
  int get totalCount {
    if (!_isCurrentIdentity) return 0;
    return _reportedTotal > _tracks.length ? _reportedTotal : _tracks.length;
  }

  _FavoriteAccountIdentity? get _currentIdentity {
    final session = _backend.sessionState;
    if (!session.isLoggedIn ||
        session.userId.isEmpty ||
        session.userId == '0') {
      return null;
    }
    return (variant: _backend.clientVariant, userId: session.userId);
  }

  /// Loads playlist metadata and the first track page. Concurrent callers for
  /// the same account share one operation.
  Future<void> load({bool force = false}) {
    final identity = _currentIdentity;
    if (identity == null) {
      _reset();
      return Future<void>.value();
    }
    if (_identity != identity) _reset(identity: identity);
    final inFlight = _initialRequest;
    if (inFlight != null) return inFlight;
    if (_loaded && !force) return Future<void>.value();

    final revision = ++_revision;
    _loading = true;
    _loadingMore = false;
    _error = null;
    update();

    late final Future<void> operation;
    operation = _loadFirstPage(identity, revision).whenComplete(() {
      if (identical(_initialRequest, operation)) _initialRequest = null;
    });
    _initialRequest = operation;
    return operation;
  }

  /// Loads the next favorite-song page while retaining all rendered tracks.
  Future<void> loadMore() {
    final identity = _currentIdentity;
    if (identity == null ||
        identity != _identity ||
        !_loaded ||
        _loading ||
        !_hasMore) {
      return Future<void>.value();
    }
    final inFlight = _moreRequest;
    if (inFlight != null) return inFlight;

    final revision = _revision;
    _loadingMore = true;
    _error = null;
    update();
    late final Future<void> operation;
    operation = _loadNextPage(identity, revision).whenComplete(() {
      if (identical(_moreRequest, operation)) _moreRequest = null;
    });
    _moreRequest = operation;
    return operation;
  }

  Future<void> _loadFirstPage(
    _FavoriteAccountIdentity identity,
    int revision,
  ) async {
    try {
      final playlist = await _findFavoritePlaylist();
      final initialPage = await _fetchInitialTrackPage(playlist);
      final page = initialPage.page;
      if (!_accepts(identity, revision)) return;

      _listId = playlist.listId;
      _collectionId = playlist.collectionId;
      _trackSource = initialPage.source;
      _cachedPrivateFirstPage = initialPage.cachedPrivateFirstPage;
      _tracks = _deduplicate(page.tracks);
      _reportedTotal = _largestInt(<int>[
        playlist.trackCount,
        page.reportedTotal,
        _tracks.length,
      ]);
      _nextPage = initialPage.nextPage;
      _hasMore =
          _sourceHasNextPage(initialPage.source, _nextPage) &&
          _pageHasMore(page, loadedCount: _tracks.length);
      _loaded = true;
      _error = null;
    } on Object catch (error) {
      if (!_accepts(identity, revision)) return;
      _error = _favoriteError(error);
      _loaded = _tracks.isNotEmpty;
      _hasMore = false;
    } finally {
      if (_accepts(identity, revision)) {
        _loading = false;
        update();
      }
    }
  }

  Future<void> _loadNextPage(
    _FavoriteAccountIdentity identity,
    int revision,
  ) async {
    try {
      final playlist = _FavoritePlaylist(
        listId: _listId,
        collectionId: _collectionId,
        trackCount: _reportedTotal,
      );
      final source = _trackSource;
      if (source == null) throw StateError('收藏歌单数据源未初始化');
      final pageNumber = _nextPage;
      final cachedFirstPage =
          source == _FavoriteTrackSource.privateListReversed && pageNumber == 1
          ? _cachedPrivateFirstPage
          : null;
      final page =
          cachedFirstPage ??
          await _fetchTrackPage(playlist, source, pageNumber);
      if (!_accepts(identity, revision)) return;
      if (identical(cachedFirstPage, _cachedPrivateFirstPage)) {
        _cachedPrivateFirstPage = null;
      }

      final existingHashes = _tracks
          .map((track) => track.hash.toUpperCase())
          .toSet();
      final additions = page.tracks
          .where((track) => existingHashes.add(track.hash.toUpperCase()))
          .toList(growable: false);
      if (additions.isNotEmpty) {
        _tracks = List<MusicTrack>.unmodifiable(<MusicTrack>[
          ..._tracks,
          ...additions,
        ]);
      }
      _reportedTotal = _largestInt(<int>[
        _reportedTotal,
        page.reportedTotal,
        _tracks.length,
      ]);
      _nextPage = switch (source) {
        _FavoriteTrackSource.globalCollection => pageNumber + 1,
        _FavoriteTrackSource.privateListReversed => pageNumber - 1,
      };
      _hasMore =
          additions.isNotEmpty &&
          _sourceHasNextPage(source, _nextPage) &&
          _pageHasMore(page, loadedCount: _tracks.length);
      _error = null;
    } on Object catch (error) {
      if (_accepts(identity, revision)) _error = _favoriteError(error);
    } finally {
      if (_accepts(identity, revision)) {
        _loadingMore = false;
        update();
      }
    }
  }

  Future<_FavoritePlaylist> _findFavoritePlaylist() async {
    for (var page = 1; page <= _maxPlaylistPages; page += 1) {
      final response = await _backend.userPlaylists(
        KugouUserPlaylistsQuery(page: page, pageSize: _playlistPageSize),
      );
      final playlists = findObjectList(response.body, const <String>['info']);
      for (final playlist in playlists) {
        final name = readString(playlist, const <String>['name', 'list_name']);
        if (!_isFavoritePlaylistName(name)) continue;
        final result = _FavoritePlaylist(
          listId: readString(playlist, const <String>['listid', 'list_id']),
          collectionId: readString(playlist, const <String>[
            'list_create_gid',
            'global_collection_id',
          ]),
          trackCount: readInt(playlist, const <String>[
            'count',
            'song_count',
            'total',
          ]),
        );
        if (result.listId.isEmpty && result.collectionId.isEmpty) {
          throw StateError('“我喜欢”歌单缺少酷狗列表 ID');
        }
        return result;
      }
      if (playlists.length < _playlistPageSize) break;
    }
    throw StateError('酷狗账号中没有找到“我喜欢”歌单');
  }

  Future<_FavoriteInitialTrackPage> _fetchInitialTrackPage(
    _FavoritePlaylist playlist,
  ) async {
    if (playlist.collectionId.isNotEmpty) {
      try {
        final globalPage = await _fetchTrackPage(
          playlist,
          _FavoriteTrackSource.globalCollection,
          1,
        );
        if (globalPage.rawCount > 0 ||
            playlist.trackCount == 0 ||
            playlist.listId.isEmpty) {
          return _FavoriteInitialTrackPage(
            page: globalPage,
            source: _FavoriteTrackSource.globalCollection,
            nextPage: 2,
          );
        }
      } on Object {
        if (playlist.listId.isEmpty) rethrow;
        // Match MoeKoe Music's global-collection route first. Some private or
        // newly-created lists do not expose a usable global collection yet.
      }
    }

    if (playlist.listId.isEmpty) {
      throw StateError('“我喜欢”歌单缺少可用的酷狗列表 ID');
    }
    return _fetchInitialPrivatePage(playlist);
  }

  Future<_FavoriteInitialTrackPage> _fetchInitialPrivatePage(
    _FavoritePlaylist playlist,
  ) async {
    // The private-list endpoint is ordered opposite to the public collection
    // endpoint. Probe page one for its authoritative total, then start at the
    // final page and walk backwards. This keeps the visible list stable and
    // avoids downloading the entire playlist before the first frame.
    final firstRawPage = await _requestPrivateTrackPage(playlist.listId, 1);
    final total = firstRawPage.reportedTotal > 0
        ? firstRawPage.reportedTotal
        : playlist.trackCount;
    final lastPage = total > 0 ? (total + _pageSize - 1) ~/ _pageSize : 1;
    final lastRawPage = lastPage == 1
        ? firstRawPage
        : await _requestPrivateTrackPage(playlist.listId, lastPage);
    final normalizedTotal = total > 0 ? total : lastRawPage.reportedTotal;

    return _FavoriteInitialTrackPage(
      page: _reversePrivatePage(lastRawPage, normalizedTotal),
      source: _FavoriteTrackSource.privateListReversed,
      nextPage: lastPage - 1,
      cachedPrivateFirstPage: lastPage > 1
          ? _reversePrivatePage(firstRawPage, normalizedTotal)
          : null,
    );
  }

  Future<_FavoriteTrackPage> _fetchTrackPage(
    _FavoritePlaylist playlist,
    _FavoriteTrackSource source,
    int page,
  ) async {
    if (source == _FavoriteTrackSource.globalCollection) {
      return _parseTrackPage(
        await _backend.playlistTracks(
          KugouPlaylistTracksQuery(
            collectionId: playlist.collectionId,
            page: page,
            pageSize: _pageSize,
          ),
        ),
      );
    }
    final result = await _requestPrivateTrackPage(playlist.listId, page);
    return _reversePrivatePage(result, result.reportedTotal);
  }

  Future<_FavoriteTrackPage> _requestPrivateTrackPage(
    String listId,
    int page,
  ) async => _parseTrackPage(
    await _backend.userPlaylistTracks(
      KugouUserPlaylistTracksQuery(
        listId: listId,
        page: page,
        pageSize: _pageSize,
      ),
    ),
  );

  _FavoriteTrackPage _parseTrackPage(KugouResponse<KugouJsonObject> response) {
    final objects = findObjectList(response.body, const <String>[
      'songs',
      'songlist',
      'lists',
      'info',
    ]);
    final tracks = objects
        .map(MusicTrack.fromKugou)
        .where((track) => track.canPlay)
        .toList(growable: false);
    return _FavoriteTrackPage(
      tracks: tracks,
      rawCount: objects.length,
      reportedTotal: _readTrackTotal(response.body),
    );
  }

  bool _pageHasMore(_FavoriteTrackPage page, {required int loadedCount}) {
    final knownTotal = _largestInt(<int>[_reportedTotal, page.reportedTotal]);
    if (knownTotal > 0) return loadedCount < knownTotal && page.rawCount > 0;
    return page.rawCount >= _pageSize;
  }

  bool _sourceHasNextPage(_FavoriteTrackSource source, int nextPage) =>
      source == _FavoriteTrackSource.globalCollection || nextPage > 0;

  bool _accepts(_FavoriteAccountIdentity identity, int revision) =>
      revision == _revision &&
      _identity == identity &&
      _currentIdentity == identity;

  void _reset({_FavoriteAccountIdentity? identity}) {
    final hadVisibleState =
        _identity != identity ||
        _tracks.isNotEmpty ||
        _loaded ||
        _loading ||
        _loadingMore ||
        _error != null;
    _revision += 1;
    _identity = identity;
    _tracks = const <MusicTrack>[];
    _listId = '';
    _collectionId = '';
    _trackSource = null;
    _cachedPrivateFirstPage = null;
    _nextPage = 1;
    _reportedTotal = 0;
    _loaded = false;
    _loading = false;
    _loadingMore = false;
    _hasMore = false;
    _error = null;
    _initialRequest = null;
    _moreRequest = null;
    if (hadVisibleState) update();
  }
}

final class _FavoritePlaylist {
  const _FavoritePlaylist({
    required this.listId,
    required this.collectionId,
    required this.trackCount,
  });

  final String listId;
  final String collectionId;
  final int trackCount;
}

enum _FavoriteTrackSource { globalCollection, privateListReversed }

final class _FavoriteInitialTrackPage {
  const _FavoriteInitialTrackPage({
    required this.page,
    required this.source,
    required this.nextPage,
    this.cachedPrivateFirstPage,
  });

  final _FavoriteTrackPage page;
  final _FavoriteTrackSource source;
  final int nextPage;
  final _FavoriteTrackPage? cachedPrivateFirstPage;
}

final class _FavoriteTrackPage {
  const _FavoriteTrackPage({
    required this.tracks,
    required this.rawCount,
    required this.reportedTotal,
  });

  final List<MusicTrack> tracks;
  final int rawCount;
  final int reportedTotal;
}

_FavoriteTrackPage _reversePrivatePage(
  _FavoriteTrackPage page,
  int reportedTotal,
) => _FavoriteTrackPage(
  tracks: List<MusicTrack>.unmodifiable(page.tracks.reversed),
  rawCount: page.rawCount,
  reportedTotal: reportedTotal,
);

bool _isFavoritePlaylistName(String value) {
  final normalized = value.replaceAll(' ', '');
  return normalized == '我喜欢' || normalized == '我喜欢的音乐' || normalized == '喜欢的音乐';
}

List<MusicTrack> _deduplicate(Iterable<MusicTrack> tracks) {
  final hashes = <String>{};
  return List<MusicTrack>.unmodifiable(
    tracks.where((track) => hashes.add(track.hash.toUpperCase())),
  );
}

int _readTrackTotal(KugouJsonObject body) {
  final data = asJsonObject(body['data']);
  if (data == null) return 0;
  final direct = readInt(data, const <String>['total', 'count', 'song_count']);
  if (direct > 0) return direct;
  final listInfo = asJsonObject(data['list_info']);
  return listInfo == null
      ? 0
      : readInt(listInfo, const <String>['count', 'total', 'song_count']);
}

int _largestInt(Iterable<int> values) {
  var result = 0;
  for (final value in values) {
    if (value > result) result = value;
  }
  return result;
}

String _favoriteError(Object error) {
  if (error is StateError) return error.message.toString();
  if (error is KugouApiException) {
    final body = asJsonObject(error.response.body);
    final message = body == null
        ? ''
        : readString(body, const <String>['error', 'msg', 'message']);
    return message.isEmpty ? '酷狗收藏服务暂时不可用，请稍后重试' : message;
  }
  if (error is KugouTransportException) return '网络连接失败，请检查网络后重试';
  return '收藏加载失败：$error';
}
