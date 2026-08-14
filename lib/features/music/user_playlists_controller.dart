import 'package:get/get.dart';

import '../../core/backend/music_backend.dart';
import '../../kugou_api.dart';
import 'music_models.dart';

typedef _UserPlaylistAccountIdentity = ({
  KugouClientVariant variant,
  String userId,
});

enum UserPlaylistOwnership { created, collected }

/// Strongly typed projection of one entry returned by `/user/playlist`.
final class UserPlaylist {
  const UserPlaylist({
    required this.listId,
    required this.collectionId,
    required this.title,
    required this.coverUrl,
    required this.trackCount,
    required this.ownerUserId,
    required this.sortOrder,
    required this.ownership,
    required this.isFavorite,
  });

  final String listId;
  final String collectionId;
  final String title;
  final String coverUrl;
  final int trackCount;
  final String ownerUserId;
  final int sortOrder;
  final UserPlaylistOwnership ownership;
  final bool isFavorite;

  String get stableId =>
      listId.isNotEmpty ? 'list-$listId' : 'collection-$collectionId';

  MusicCollection get collection => MusicCollection(
    id: collectionId,
    accountListId: listId,
    title: title,
    subtitle: '$trackCount 首歌曲',
    coverUrl: coverUrl,
    kind: MusicCollectionKind.playlist,
  );
}

/// Lazily loads every playlist created or collected by the signed-in account.
///
/// This follows MoeKoe Music's library logic: request `/user/playlist` with a
/// large page, order entries by KuGou's `sort` value, keep “我喜欢” at the
/// beginning of created playlists, and classify non-owned entries carrying an
/// `authors` field as collected albums rather than playlists.
final class UserPlaylistsController extends GetxController {
  UserPlaylistsController(this._backend);

  static const int _pageSize = 500;
  static const int _maxPages = 100;

  final MusicBackend _backend;
  _UserPlaylistAccountIdentity? _identity;
  List<UserPlaylist> _created = const <UserPlaylist>[];
  List<UserPlaylist> _collected = const <UserPlaylist>[];
  List<UserPlaylist> _all = const <UserPlaylist>[];
  bool _loaded = false;
  bool _loading = false;
  String? _error;
  Future<void>? _request;
  int _revision = 0;

  bool get _isCurrentIdentity => _identity == _currentIdentity;

  List<UserPlaylist> get createdPlaylists =>
      _isCurrentIdentity ? _created : const <UserPlaylist>[];
  List<UserPlaylist> get collectedPlaylists =>
      _isCurrentIdentity ? _collected : const <UserPlaylist>[];
  List<UserPlaylist> get allPlaylists =>
      _isCurrentIdentity ? _all : const <UserPlaylist>[];
  bool get loaded => _isCurrentIdentity && _loaded;
  bool get loading => _isCurrentIdentity && _loading;
  String? get error => _isCurrentIdentity ? _error : null;
  int get totalCount => _isCurrentIdentity ? _all.length : 0;

  _UserPlaylistAccountIdentity? get _currentIdentity {
    final session = _backend.sessionState;
    if (!session.isLoggedIn ||
        session.userId.isEmpty ||
        session.userId == '0') {
      return null;
    }
    return (variant: _backend.clientVariant, userId: session.userId);
  }

  Future<void> load({bool force = false}) {
    final identity = _currentIdentity;
    if (identity == null) {
      _reset();
      return Future<void>.value();
    }
    if (_identity != identity) _reset(identity: identity);
    final inFlight = _request;
    if (inFlight != null) return inFlight;
    if (_loaded && !force) return Future<void>.value();

    final revision = ++_revision;
    _loading = true;
    _error = null;
    update();

    late final Future<void> operation;
    operation = _loadAll(identity, revision).whenComplete(() {
      if (identical(_request, operation)) _request = null;
    });
    _request = operation;
    return operation;
  }

  Future<void> _loadAll(
    _UserPlaylistAccountIdentity identity,
    int revision,
  ) async {
    try {
      final entries = <({JsonObject json, int sourceIndex})>[];
      final seenPages = <String>{};
      var reportedTotal = 0;
      var rawCount = 0;

      for (var page = 1; page <= _maxPages; page += 1) {
        final response = await _backend.userPlaylists(
          KugouUserPlaylistsQuery(page: page, pageSize: _pageSize),
        );
        final objects = findObjectList(response.body, const <String>['info']);
        final signature = objects
            .map(_playlistWireIdentity)
            .where((value) => value.isNotEmpty)
            .join('|');
        if (objects.isNotEmpty &&
            signature.isNotEmpty &&
            !seenPages.add(signature)) {
          break;
        }

        for (final object in objects) {
          entries.add((json: object, sourceIndex: entries.length));
        }
        rawCount += objects.length;
        final total = _readPlaylistTotal(response.body);
        if (total > reportedTotal) reportedTotal = total;
        if (objects.isEmpty ||
            (reportedTotal > 0
                ? rawCount >= reportedTotal
                : objects.length < _pageSize)) {
          break;
        }
      }

      final parsed = <({UserPlaylist playlist, int sourceIndex})>[];
      final seenPlaylists = <String>{};
      for (final entry in entries) {
        final playlist = _parsePlaylist(entry.json, identity.userId);
        if (playlist == null || !seenPlaylists.add(playlist.stableId)) continue;
        parsed.add((playlist: playlist, sourceIndex: entry.sourceIndex));
      }
      parsed.sort(_comparePlaylistEntries);

      final created = parsed
          .where(
            (entry) =>
                entry.playlist.ownership == UserPlaylistOwnership.created,
          )
          .map((entry) => entry.playlist)
          .toList();
      final favoriteIndex = created.indexWhere(
        (playlist) => playlist.isFavorite,
      );
      if (favoriteIndex > 0) {
        final favorite = created.removeAt(favoriteIndex);
        created.insert(0, favorite);
      }
      final collected = parsed
          .where(
            (entry) =>
                entry.playlist.ownership == UserPlaylistOwnership.collected,
          )
          .map((entry) => entry.playlist)
          .toList(growable: false);

      if (!_accepts(identity, revision)) return;
      _created = List<UserPlaylist>.unmodifiable(created);
      _collected = List<UserPlaylist>.unmodifiable(collected);
      _all = List<UserPlaylist>.unmodifiable(<UserPlaylist>[
        ..._created,
        ..._collected,
      ]);
      _loaded = true;
      _error = null;
    } on Object catch (error) {
      if (!_accepts(identity, revision)) return;
      _error = _userPlaylistError(error);
      _loaded = _created.isNotEmpty || _collected.isNotEmpty;
    } finally {
      if (_accepts(identity, revision)) {
        _loading = false;
        update();
      }
    }
  }

  bool _accepts(_UserPlaylistAccountIdentity identity, int revision) =>
      revision == _revision &&
      _identity == identity &&
      _currentIdentity == identity;

  void _reset({_UserPlaylistAccountIdentity? identity}) {
    final hadVisibleState =
        _identity != identity ||
        _created.isNotEmpty ||
        _collected.isNotEmpty ||
        _all.isNotEmpty ||
        _loaded ||
        _loading ||
        _error != null;
    _revision += 1;
    _identity = identity;
    _created = const <UserPlaylist>[];
    _collected = const <UserPlaylist>[];
    _all = const <UserPlaylist>[];
    _loaded = false;
    _loading = false;
    _error = null;
    _request = null;
    if (hadVisibleState) update();
  }
}

UserPlaylist? _parsePlaylist(JsonObject json, String currentUserId) {
  final title = readString(json, const <String>['name', 'list_name', 'title']);
  final listId = readString(json, const <String>['listid', 'list_id']);
  final collectionId = readString(json, const <String>[
    'list_create_gid',
    'global_collection_id',
  ]);
  if (title.isEmpty || (listId.isEmpty && collectionId.isEmpty)) return null;

  final ownerUserId = readString(json, const <String>[
    'list_create_userid',
    'userid',
    'user_id',
  ]);
  final isFavorite = _isFavoritePlaylistName(title);
  final isOwned = isFavorite || ownerUserId == currentUserId;
  if (!isOwned && _isCollectedAlbum(json['authors'])) return null;

  return UserPlaylist(
    listId: listId,
    collectionId: collectionId,
    title: title,
    coverUrl: normalizeImageUrl(
      readString(json, const <String>[
        'pic',
        'imgurl',
        'image',
        'cover',
        'sizable_cover',
      ]),
    ),
    trackCount: readInt(json, const <String>['count', 'song_count', 'total']),
    ownerUserId: ownerUserId,
    sortOrder: readInt(json, const <String>['sort', 'sort_order']),
    ownership: isOwned
        ? UserPlaylistOwnership.created
        : UserPlaylistOwnership.collected,
    isFavorite: isFavorite,
  );
}

bool _isCollectedAlbum(Object? authors) {
  if (authors == null || authors == false) return false;
  if (authors is String) return authors.isNotEmpty;
  if (authors is num) return authors != 0;
  // JavaScript treats arrays and objects as truthy even when empty; matching
  // that detail preserves MoeKoe Music's playlist/album classification.
  return true;
}

bool _isFavoritePlaylistName(String value) {
  final normalized = value.replaceAll(' ', '');
  return normalized == '我喜欢' || normalized == '我喜欢的音乐' || normalized == '喜欢的音乐';
}

String _playlistWireIdentity(JsonObject json) {
  final listId = readString(json, const <String>['listid', 'list_id']);
  if (listId.isNotEmpty) return 'list:$listId';
  final collectionId = readString(json, const <String>[
    'list_create_gid',
    'global_collection_id',
  ]);
  return collectionId.isEmpty ? '' : 'collection:$collectionId';
}

int _comparePlaylistEntries(
  ({UserPlaylist playlist, int sourceIndex}) left,
  ({UserPlaylist playlist, int sourceIndex}) right,
) {
  final order = left.playlist.sortOrder.compareTo(right.playlist.sortOrder);
  return order == 0 ? left.sourceIndex.compareTo(right.sourceIndex) : order;
}

int _readPlaylistTotal(KugouJsonObject body) {
  final data = asJsonObject(body['data']);
  if (data == null) return 0;
  return readInt(data, const <String>['total', 'count', 'total_count']);
}

String _userPlaylistError(Object error) {
  if (error is KugouApiException) {
    final body = asJsonObject(error.response.body);
    final message = body == null
        ? ''
        : readString(body, const <String>['error', 'msg', 'message']);
    return message.isEmpty ? '酷狗歌单服务暂时不可用，请稍后重试' : message;
  }
  if (error is KugouTransportException) return '网络连接失败，请检查网络后重试';
  return '歌单加载失败：$error';
}
