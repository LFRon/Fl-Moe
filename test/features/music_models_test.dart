import 'package:fl_moe/features/music/music_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses a KuGou song into an immutable UI model', () {
    final track = MusicTrack.fromKugou(<String, Object?>{
      'MixSongID': 7788,
      'FileHash': 'ABCDEF1234',
      'OriSongName': '星空',
      'SingerName': 'Moe',
      'AlbumName': '夜航',
      'Image': '//img.example/{size}/cover.jpg',
      'timeLength': 215000,
      'AlbumID': '42',
    });

    expect(track.id, '7788');
    expect(track.hash, 'ABCDEF1234');
    expect(track.title, '星空');
    expect(track.artist, 'Moe');
    expect(track.coverUrl, 'https://img.example/480/cover.jpg');
    expect(track.duration, const Duration(seconds: 215));
    expect(track.albumId, 42);
    expect(track.albumAudioId, 7788);
    expect(track.canPlay, isTrue);
  });

  test('finds nested object lists without leaking untyped values', () {
    final response = <String, Object?>{
      'status': 1,
      'data': <String, Object?>{
        'lists': <Object?>[
          <String, Object?>{'name': 'one'},
          <String, Object?>{'name': 'two'},
        ],
      },
    };

    final result = findObjectList(response, const <String>['lists']);

    expect(result, hasLength(2));
    expect(readString(result.first, const <String>['name']), 'one');
  });

  test('parses filename-only rows returned by user playlists', () {
    final track = MusicTrack.fromKugou(<String, Object?>{
      'filename': '测试歌手 - 收藏歌曲',
      'singername': '测试歌手',
      'hash': 'FAVORITE-HASH',
      'timelen': 188,
      'album_audio_id': 9988,
    });

    expect(track.title, '收藏歌曲');
    expect(track.artist, '测试歌手');
    expect(track.hash, 'FAVORITE-HASH');
    expect(track.duration, const Duration(seconds: 188));
    expect(track.albumAudioId, 9988);
  });

  test('recent-track JSON round-trips through typed models', () {
    const track = MusicTrack(
      id: '1',
      hash: 'HASH',
      title: 'Song',
      artist: 'Singer',
      duration: Duration(minutes: 3),
    );

    final restored = MusicTrack.fromJson(track.toJson());

    expect(restored.hash, track.hash);
    expect(restored.title, track.title);
    expect(restored.duration, track.duration);
  });
}
