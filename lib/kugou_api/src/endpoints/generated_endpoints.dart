// GENERATED CODE - DO NOT EDIT BY HAND.
// Generated from KuGouMusicApi/module by tool/generate_kugou_endpoints.py.
// ignore_for_file: non_constant_identifier_names, prefer_interpolation_to_compose_strings, unused_local_variable, equal_keys_in_map

import '../config.dart';
import '../endpoint.dart';
import '../js_compat.dart';
import '../models.dart';
import '../signatures.dart';
import '../utilities.dart';

Map<String, KugouEndpointHandler> createGeneratedEndpointHandlers() =>
    <String, KugouEndpointHandler>{
      "/ai/recommend": _generatedAiRecommend,
      "/ai/recommend/song": _generatedAiRecommendSong,
      "/album": _generatedAlbum,
      "/album/detail": _generatedAlbumDetail,
      "/album/shop": _generatedAlbumShop,
      "/album/songs": _generatedAlbumSongs,
      "/artist/albums": _generatedArtistAlbums,
      "/artist/audios": _generatedArtistAudios,
      "/artist/audios/new": _generatedArtistAudiosNew,
      "/artist/detail": _generatedArtistDetail,
      "/artist/follow": _generatedArtistFollow,
      "/artist/follow/newsongs": _generatedArtistFollowNewsongs,
      "/artist/honour": _generatedArtistHonour,
      "/artist/lists": _generatedArtistLists,
      "/artist/unfollow": _generatedArtistUnfollow,
      "/artist/videos": _generatedArtistVideos,
      "/audio": _generatedAudio,
      "/audio/match": _generatedAudioMatch,
      "/brush": _generatedBrush,
      "/captcha/sent": _generatedCaptchaSent,
      "/comment/album": _generatedCommentAlbum,
      "/comment/music": _generatedCommentMusic,
      "/comment/music/classify": _generatedCommentMusicClassify,
      "/comment/music/hotword": _generatedCommentMusicHotword,
      "/comment/playlist": _generatedCommentPlaylist,
      "/effects/artist": _generatedEffectsArtist,
      "/effects/brand": _generatedEffectsBrand,
      "/effects/brand/detail": _generatedEffectsBrandDetail,
      "/effects/car/brand": _generatedEffectsCarBrand,
      "/effects/car/brand/lists": _generatedEffectsCarBrandLists,
      "/effects/match": _generatedEffectsMatch,
      "/everyday/friend": _generatedEverydayFriend,
      "/everyday/history": _generatedEverydayHistory,
      "/everyday/recommend": _generatedEverydayRecommend,
      "/everyday/style/recommend": _generatedEverydayStyleRecommend,
      "/favorite/count": _generatedFavoriteCount,
      "/fm/class": _generatedFmClass,
      "/fm/image": _generatedFmImage,
      "/fm/recommend": _generatedFmRecommend,
      "/get/mode/info": _generatedGetModeInfo,
      "/get/model": _generatedGetModel,
      "/get/verify/info": _generatedGetVerifyInfo,
      "/home/discover": _generatedHomeDiscover,
      "/ip": _generatedIp,
      "/ip/dateil": _generatedIpDateil,
      "/ip/playlist": _generatedIpPlaylist,
      "/ip/zone/home": _generatedIpZoneHome,
      "/kmr/audio/mv": _generatedKmrAudioMv,
      "/krm/audio": _generatedKrmAudio,
      "/lastest/songs/listen": _generatedLastestSongsListen,
      "/login/device": _generatedLoginDevice,
      "/login/qr/key": _generatedLoginQrKey,
      "/longaudio/album/audios": _generatedLongaudioAlbumAudios,
      "/longaudio/album/detail": _generatedLongaudioAlbumDetail,
      "/longaudio/album/list": _generatedLongaudioAlbumList,
      "/longaudio/daily/recommend": _generatedLongaudioDailyRecommend,
      "/longaudio/rank/recommend": _generatedLongaudioRankRecommend,
      "/longaudio/search": _generatedLongaudioSearch,
      "/longaudio/tag/list": _generatedLongaudioTagList,
      "/longaudio/vip/recommend": _generatedLongaudioVipRecommend,
      "/longaudio/week/recommend": _generatedLongaudioWeekRecommend,
      "/pc/diantai": _generatedPcDiantai,
      "/personal/fm": _generatedPersonalFm,
      "/playhistory/upload": _generatedPlayhistoryUpload,
      "/playlist/add": _generatedPlaylistAdd,
      "/playlist/detail": _generatedPlaylistDetail,
      "/playlist/effect": _generatedPlaylistEffect,
      "/playlist/similar": _generatedPlaylistSimilar,
      "/playlist/tags": _generatedPlaylistTags,
      "/playlist/track/all/new": _generatedPlaylistTrackAllNew,
      "/playlist/tracks/del": _generatedPlaylistTracksDel,
      "/rank/audio": _generatedRankAudio,
      "/rank/info": _generatedRankInfo,
      "/rank/list": _generatedRankList,
      "/rank/top": _generatedRankTop,
      "/rank/vol": _generatedRankVol,
      "/recommend/songs": _generatedRecommendSongs,
      "/scene/audio/list": _generatedSceneAudioList,
      "/scene/collection/list": _generatedSceneCollectionList,
      "/scene/lists": _generatedSceneLists,
      "/scene/lists/v2": _generatedSceneListsV2,
      "/scene/module": _generatedSceneModule,
      "/scene/module/info": _generatedSceneModuleInfo,
      "/scene/music": _generatedSceneMusic,
      "/scene/video/list": _generatedSceneVideoList,
      "/search/complex": _generatedSearchComplex,
      "/search/default": _generatedSearchDefault,
      "/search/hot": _generatedSearchHot,
      "/search/lyric": _generatedSearchLyric,
      "/search/mixed": _generatedSearchMixed,
      "/search/suggest": _generatedSearchSuggest,
      "/server/now": _generatedServerNow,
      "/sheet/collection": _generatedSheetCollection,
      "/sheet/detail": _generatedSheetDetail,
      "/sheet/explore": _generatedSheetExplore,
      "/sheet/rank": _generatedSheetRank,
      "/sheet/song": _generatedSheetSong,
      "/sheet/tags": _generatedSheetTags,
      "/singer/list": _generatedSingerList,
      "/song/auth": _generatedSongAuth,
      "/song/climax": _generatedSongClimax,
      "/song/ranking": _generatedSongRanking,
      "/song/ranking/filter": _generatedSongRankingFilter,
      "/song/url/auth": _generatedSongUrlAuth,
      "/song/url/new": _generatedSongUrlNew,
      "/theme/music": _generatedThemeMusic,
      "/theme/music/detail": _generatedThemeMusicDetail,
      "/theme/playlist": _generatedThemePlaylist,
      "/theme/playlist/track": _generatedThemePlaylistTrack,
      "/top/album": _generatedTopAlbum,
      "/top/card": _generatedTopCard,
      "/top/card/youth": _generatedTopCardYouth,
      "/top/playlist": _generatedTopPlaylist,
      "/top/song": _generatedTopSong,
      "/user/cloud/url": _generatedUserCloudUrl,
      "/user/detail": _generatedUserDetail,
      "/user/fans": _generatedUserFans,
      "/user/follow": _generatedUserFollow,
      "/user/friends": _generatedUserFriends,
      "/user/history": _generatedUserHistory,
      "/user/info": _generatedUserInfo,
      "/user/listen": _generatedUserListen,
      "/user/playlist": _generatedUserPlaylist,
      "/user/purchased/albums": _generatedUserPurchasedAlbums,
      "/user/purchased/songs": _generatedUserPurchasedSongs,
      "/user/video/collect": _generatedUserVideoCollect,
      "/user/video/love": _generatedUserVideoLove,
      "/user/vip/detail": _generatedUserVipDetail,
      "/verify/user/info": _generatedVerifyUserInfo,
      "/video/detail": _generatedVideoDetail,
      "/video/privilege": _generatedVideoPrivilege,
      "/video/url": _generatedVideoUrl,
      "/youth/channel/all": _generatedYouthChannelAll,
      "/youth/channel/amway": _generatedYouthChannelAmway,
      "/youth/channel/detail": _generatedYouthChannelDetail,
      "/youth/channel/similar": _generatedYouthChannelSimilar,
      "/youth/channel/song": _generatedYouthChannelSong,
      "/youth/channel/song/detail": _generatedYouthChannelSongDetail,
      "/youth/channel/song/list": _generatedYouthChannelSongList,
      "/youth/channel/sub": _generatedYouthChannelSub,
      "/youth/day/vip": _generatedYouthDayVip,
      "/youth/day/vip/upgrade": _generatedYouthDayVipUpgrade,
      "/youth/dynamic": _generatedYouthDynamic,
      "/youth/dynamic/recent": _generatedYouthDynamicRecent,
      "/youth/listen/song": _generatedYouthListenSong,
      "/youth/month/vip/record": _generatedYouthMonthVipRecord,
      "/youth/union/vip": _generatedYouthUnionVip,
      "/youth/user/song": _generatedYouthUserSong,
      "/youth/vip": _generatedYouthVip,
      "/yueku": _generatedYueku,
      "/yueku/banner": _generatedYuekuBanner,
      "/yueku/fm": _generatedYuekuFm,
    };

Future<KugouResponse<Object?>> _generatedAiRecommend(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final userid = jsOr(
    jsOr(input["userid"], endpointCookie(context, input, "userid")),
    0,
  );
  final mid = endpointCookie(context, input, "KUGOU_API_MID");
  final clienttime = context.nowMilliseconds;
  final recommend_source =
      (jsString((jsOr(input["album_audio_id"], ""))).split(jsString(",")))
          .map<Object?>((s) => (<String, Object?>{"ID": jsNumber(s)}))
          .toList(growable: false);
  final dataMap = <String, Object?>{
    "platform": "ios",
    "clientver": context.config.clientVersion,
    "clienttime": clienttime,
    "userid": userid,
    "client_playlist": <Object?>[],
    "source_type": 2,
    "playlist_ver": 2,
    "area_code": 1,
    "appid": context.config.appId,
    "key": context.signatures.parametersKey(jsString(clienttime)),
    "mid": mid,
    "recommend_source": recommend_source,
  };
  return context.request(
    KugouRequest(
      path: jsString("/recommend"),
      method: jsString("post"),
      data: dataMap,
      headers: stringObjectMap(<String, Object?>{
        "x-router": "songlistairec.kugou.com",
      }),
      cookies: stringStringMap(
        jsOr(context.session.cookies, <String, Object?>{}),
      ),
      clearDefaultParameters: jsTruthy(true),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedAiRecommendSong(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final dataMap = <String, Object?>{
    "apiver": 2,
    "source": 2,
    "pagesize": jsOr(input["pagesize"], 30),
    "page": jsOr(input["page"], 1),
  };
  return context.request(
    KugouRequest(
      path: jsString("/concepts/v1/ai/recommend_song"),
      method: jsString("post"),
      data: dataMap,
      cookies: stringStringMap(
        jsOr(context.session.cookies, <String, Object?>{}),
      ),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedAlbum(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final dateTime = context.nowMilliseconds;
  final data = (jsString((jsOr(input["album_id"], ""))).split(jsString(",")))
      .map<Object?>(
        (s) => (<String, Object?>{
          "album_id": s,
          "album_name": "",
          "author_name": "",
        }),
      )
      .toList(growable: false);
  final dfid = jsOr(
    jsOr(endpointCookie(context, input, "dfid"), input["dfid"]),
    "-",
  );
  final userid = jsOr(
    jsOr(endpointCookie(context, input, "userid"), input["userid"]),
    0,
  );
  final token = jsOr(
    jsOr(endpointCookie(context, input, "token"), input["token"]),
    0,
  );
  final dataMap = <String, Object?>{
    "appid": context.config.appId,
    "clienttime": dateTime,
    "clientver": context.config.clientVersion,
    "data": data,
    "dfid": dfid,
    "fields": jsOr(input["fields"], ""),
    "key": context.signatures.parametersKey(dateTime),
    "mid": endpointCookie(context, input, "KUGOU_API_MID"),
  };
  if (jsTruthy((token))) {
    dataMap[jsString("token")] = token;
  }
  if (jsTruthy((userid))) {
    dataMap[jsString("userid")] = userid;
  }
  return context.request(
    KugouRequest(
      path: jsString("/v1/album"),
      baseUri: Uri.parse(jsString("http://kmr.service.kugou.com")),
      method: jsString("POST"),
      data: dataMap,
      headers: stringObjectMap(<String, Object?>{
        "x-router": "kmr.service.kugou.com",
        "Content-Type": "application/json",
      }),
      cookies: stringStringMap(
        jsOr(context.session.cookies, <String, Object?>{}),
      ),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedAlbumDetail(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final data = <String, Object?>{
    "data": <Object?>[
      <String, Object?>{"album_id": input["id"]},
    ],
    "is_buy": jsOr(input["is_buy"], 0),
    "fields":
        "album_id,album_name,publish_date,sizable_cover,intro,language,is_publish,heat,type,quality,authors,exclusive,author_name,trans_param",
  };
  return context.request(
    KugouRequest(
      path: jsString("/kmr/v2/albums"),
      method: jsString("POST"),
      data: data,
      headers: stringObjectMap(<String, Object?>{
        "x-router": "openapi.kugou.com",
        "kg-tid": "255",
      }),
      cookies: stringStringMap(
        jsOr(context.session.cookies, <String, Object?>{}),
      ),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedAlbumShop(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  return context.request(
    KugouRequest(
      path: jsString("/zhuanjidata/v3/album_shop_v2/get_classify_data"),
      method: jsString("GET"),
      cookies: stringStringMap(
        jsOr(context.session.cookies, <String, Object?>{}),
      ),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedAlbumSongs(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final dataMap = <String, Object?>{
    "album_id": input["id"],
    "is_buy": jsOr(input["is_buy"], ""),
    "page": jsOr(input["page"], 1),
    "pagesize": jsOr(input["pagesize"], 30),
  };
  return context.request(
    KugouRequest(
      path: jsString("/v1/album_audio/lite"),
      method: jsString("POST"),
      data: dataMap,
      headers: stringObjectMap(<String, Object?>{
        "x-router": "openapi.kugou.com",
        "kg-tid": "255",
      }),
      cookies: stringStringMap(
        jsOr(context.session.cookies, <String, Object?>{}),
      ),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedArtistAlbums(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final dataMap = <String, Object?>{
    "author_id": input["id"],
    "pagesize": jsOr(input["pagesize"], 30),
    "page": jsOr(input["page"], 1),
    "sort": (jsTruthy((input["sort"] == "hot")) ? 3 : 1),
    "category": 1,
    "area_code": "all",
  };
  return context.request(
    KugouRequest(
      path: jsString("/kmr/v1/author/albums"),
      method: jsString("POST"),
      data: dataMap,
      headers: stringObjectMap(<String, Object?>{
        "x-router": "openapi.kugou.com",
        "kg-tid": 36,
      }),
      cookies: stringStringMap(
        jsOr(context.session.cookies, <String, Object?>{}),
      ),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedArtistAudios(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final clienttime = jsNumber(
    (jsNumber(context.nowMilliseconds) / jsNumber(1000)),
  ).floor();
  final mid = endpointCookie(context, input, "KUGOU_API_MID");
  final dataMap = <String, Object?>{
    "appid": context.config.appId,
    "clientver": context.config.clientVersion,
    "mid": mid,
    "clienttime": clienttime,
    "key": context.signatures.parametersKey(clienttime),
    "author_id": input["id"],
    "pagesize": jsOr(input["pagesize"], 30),
    "page": jsOr(input["page"], 1),
    "sort": (jsTruthy((input["sort"] == "hot")) ? 1 : 2),
    "area_code": "all",
  };
  return context.request(
    KugouRequest(
      path: jsString("/kmr/v1/audio_group/author"),
      baseUri: Uri.parse(jsString("https://openapi.kugou.com")),
      method: jsString("POST"),
      data: dataMap,
      headers: stringObjectMap(<String, Object?>{
        "x-router": "openapi.kugou.com",
        "kg-tid": 220,
      }),
      cookies: stringStringMap(
        jsOr(context.session.cookies, <String, Object?>{}),
      ),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedArtistAudiosNew(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  return context.request(
    KugouRequest(
      path: jsString("/openapi/kmr/v2/audio_group/author"),
      baseUri: Uri.parse(jsString("https://gateway.kugou.com")),
      method: jsString("GET"),
      parameters: stringObjectMap(<String, Object?>{
        "author_id": input["id"],
        "area_code": "all",
        "sort": (jsTruthy((input["sort"] == "hot")) ? 1 : 2),
        "page": jsOr(input["page"], 1),
        "pagesize": jsOr(input["pagesize"], 30),
        "replace_api_version": 1,
        "mvdata_need": 1,
        "show_audio_honor": 1,
        "show_audio_tag": 1,
        "replace_need": 1,
      }),
      headers: stringObjectMap(<String, Object?>{"kg-tid": 36}),
      cookies: stringStringMap(
        jsOr(context.session.cookies, <String, Object?>{}),
      ),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedArtistDetail(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  return context.request(
    KugouRequest(
      path: jsString("/kmr/v3/author"),
      method: jsString("POST"),
      data: <String, Object?>{"author_id": input["id"]},
      headers: stringObjectMap(<String, Object?>{
        "x-router": "openapi.kugou.com",
        "kg-tid": 36,
      }),
      cookies: stringStringMap(
        jsOr(context.session.cookies, <String, Object?>{}),
      ),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedArtistFollow(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final singerid = jsNumber(input["id"]);
  final token = jsOr(
    jsOr(input["token"], endpointCookie(context, input, "token")),
    "",
  );
  final userid = jsNumber(
    jsOr(jsOr(input["userid"], endpointCookie(context, input, "userid")), 0),
  );
  final clienttime = jsNumber(
    (jsNumber(context.nowMilliseconds) / jsNumber(1000)),
  ).floor();
  final encrypt = context.crypto.aesEncrypt(<String, Object?>{
    "singerid": singerid,
    "token": token,
  });
  final paramsMap = <String, Object?>{
    "plat": 0,
    "userid": userid,
    "singerid": singerid,
    "source": 7,
    "p": context.crypto.rsaPkcs1Encrypt(<String, Object?>{
      "clienttime": clienttime,
      "key": (encrypt).key,
    }),
    "params": (encrypt).ciphertext,
  };
  return context.request(
    KugouRequest(
      path: jsString("/followservice/v3/follow_singer"),
      method: jsString("post"),
      parameters: stringObjectMap(<String, Object?>{"clienttime": clienttime}),
      data: paramsMap,
      cookies: stringStringMap(
        jsOr(context.session.cookies, <String, Object?>{}),
      ),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedArtistFollowNewsongs(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final last_album_id = jsOr(input["last_album_id"], 0);
  final page_size = jsOr(input["pagesize"], 30);
  final opt_sort = (jsTruthy((input["opt_sort"] == 2)) ? 2 : 1);
  final paramsMap = <String, Object?>{
    "last_album_id": last_album_id,
    "page_size": page_size,
    "opt_sort": opt_sort,
  };
  return context.request(
    KugouRequest(
      path: jsString("/feed/v1/follow/newsong_album_list"),
      method: jsString("post"),
      parameters: stringObjectMap(paramsMap),
      data: <String, Object?>{"last_album_id": last_album_id},
      cookies: stringStringMap(
        jsOr(context.session.cookies, <String, Object?>{}),
      ),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedArtistHonour(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  return context.request(
    KugouRequest(
      path: jsString("/v1/query_singer_honour_detail"),
      baseUri: Uri.parse(jsString("http://h5activity.kugou.com")),
      method: jsString("POST"),
      parameters: stringObjectMap(<String, Object?>{
        "singer_id": input["id"],
        "pagesize": jsOr(input["pagesize"], 30),
        "page": jsOr(input["page"], 1),
      }),
      cookies: stringStringMap(
        jsOr(context.session.cookies, <String, Object?>{}),
      ),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedArtistLists(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final paramsMap = <String, Object?>{
    "musician": jsNumber(jsOr(input["musician"], 0)),
    "sextype": jsOr(input["sextypes"], 0),
    "showtype": 2,
    "type": jsOr(input["type"], 0),
    "hotsize": jsNumber(jsOr(input["hotsize"], 30)),
  };
  return context.request(
    KugouRequest(
      path: jsString("/ocean/v6/singer/list"),
      method: jsString("GET"),
      parameters: stringObjectMap(paramsMap),
      cookies: stringStringMap(
        jsOr(context.session.cookies, <String, Object?>{}),
      ),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedArtistUnfollow(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final singerid = input["id"];
  final token = jsOr(
    jsOr(input["token"], endpointCookie(context, input, "token")),
    "",
  );
  final userid = jsOr(
    jsOr(input["userid"], endpointCookie(context, input, "userid")),
    0,
  );
  final clienttime = jsNumber(
    (jsNumber(context.nowMilliseconds) / jsNumber(1000)),
  ).floor();
  final encrypt = context.crypto.aesEncrypt(<String, Object?>{
    "singerid": singerid,
    "token": token,
  });
  final paramsMap = <String, Object?>{
    "plat": 0,
    "userid": userid,
    "singerid": singerid,
    "source": 7,
    "p": context.crypto.rsaPkcs1Encrypt(<String, Object?>{
      "clienttime": clienttime,
      "key": (encrypt).key,
    }),
    "params": (encrypt).ciphertext,
  };
  return context.request(
    KugouRequest(
      path: jsString("/followservice/v3/unfollow_singer"),
      method: jsString("post"),
      data: paramsMap,
      cookies: stringStringMap(
        jsOr(context.session.cookies, <String, Object?>{}),
      ),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedArtistVideos(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final tag_idx = <String, Object?>{
    "official": 18,
    "live": 20,
    "fan": 23,
    "artist": 42419,
    "all": "",
  };
  final paramsMap = <String, Object?>{
    "author_id": input["id"],
    "is_fanmade": "",
    "tag_idx": jsOr(mapValue(tag_idx, jsOr(input["tag"], "all")), ""),
    "pagesize": jsOr(input["pagesize"], 30),
    "page": jsOr(input["page"], 1),
  };
  return context.request(
    KugouRequest(
      path: jsString("/kmr/v1/author/videos"),
      baseUri: Uri.parse(jsString("https://openapicdn.kugou.com")),
      method: jsString("GET"),
      parameters: stringObjectMap(paramsMap),
      cookies: stringStringMap(
        jsOr(context.session.cookies, <String, Object?>{}),
      ),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedAudio(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final dateTime = context.nowMilliseconds;
  final data = (jsString((jsOr(input["hash"], ""))).split(jsString(",")))
      .map<Object?>((s) => (<String, Object?>{"hash": s, "audio_id": 0}))
      .toList(growable: false);
  final dfid = jsOr(
    jsOr(endpointCookie(context, input, "dfid"), input["dfid"]),
    "-",
  );
  final userid = jsOr(
    jsOr(endpointCookie(context, input, "userid"), input["userid"]),
    0,
  );
  final token = jsOr(
    jsOr(endpointCookie(context, input, "token"), input["token"]),
    0,
  );
  final dataMap = <String, Object?>{
    "appid": context.config.appId,
    "clienttime": dateTime,
    "clientver": context.config.clientVersion,
    "data": data,
    "dfid": dfid,
    "key": context.signatures.parametersKey(dateTime),
    "mid": endpointCookie(context, input, "KUGOU_API_MID"),
  };
  if (jsTruthy((token))) {
    dataMap[jsString("token")] = token;
  }
  if (jsTruthy((userid))) {
    dataMap[jsString("userid")] = userid;
  }
  return context.request(
    KugouRequest(
      path: jsString("/v1/audio/audio"),
      baseUri: Uri.parse(jsString("http://kmr.service.kugou.com")),
      method: jsString("POST"),
      data: dataMap,
      headers: stringObjectMap(<String, Object?>{
        "x-router": "kmr.service.kugou.com",
        "Content-Type": "application/json",
      }),
      cookies: stringStringMap(
        jsOr(context.session.cookies, <String, Object?>{}),
      ),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedAudioMatch(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final paramsMap = <String, Object?>{
    "fpid": context.nowMilliseconds,
    "area_code": 1,
    "include_unpublish": 1,
    "useid": jsOr(
      jsOr(input["userid"], endpointCookie(context, input, "userid")),
      0,
    ),
    "multi_result": 1,
  };
  return context.request(
    KugouRequest(
      path: jsString("/fingerprint.service/v1/music_trackid_mulit"),
      method: jsString("POST"),
      parameters: stringObjectMap(paramsMap),
      data: input["data"],
      headers: stringObjectMap(<String, Object?>{
        "content-type": "application/octet-stream",
        "user-agent": "KuGou/11490 (Android)",
      }),
      cookies: stringStringMap(
        jsOr(context.session.cookies, <String, Object?>{}),
      ),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedBrush(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final userid = jsOr(
    jsOr(endpointCookie(context, input, "userid"), input["userid"]),
    0,
  );
  final vip_type = jsOr(
    jsOr(endpointCookie(context, input, "vip_type"), input["vipType"]),
    0,
  );
  final dateTime = context.nowMilliseconds;
  final personal_recommend = <String, Object?>{
    "userid": userid,
    "appid": context.config.appId,
    "playlist_ver": 2,
    "clienttime": dateTime,
    "mid": endpointCookie(context, input, "KUGOU_API_MID"),
    "new_sync_point": dateTime,
    "module_id": 1,
    "action": "login",
    "vip_type": vip_type,
    "vip_flags": 3,
    "recommend_source_locked": 0,
    "song_pool_id": jsNumber(jsOr(input["song_pool_id"], 0)),
    "callerid": 0,
    "m_type": 1,
    "kguid": userid,
    "platform": "ios",
    "area_code": 1,
    "fakem": "ca981cfc583a4c37f28d2d49000013c16a0a",
    "clientver": 11850,
    "mode": jsOr(input["mode"], "normal"),
    "active_swtich": "on",
    "key": context.signatures.parametersKey(dateTime),
  };
  final dataMap = <String, Object?>{
    "behaviors": <Object?>[],
    "abtest": <String, Object?>{
      "abtest": <String, Object?>{
        "shuashua": <String, Object?>{"commentcard": 2},
      },
    },
    "personal_recommend_params": personal_recommend,
  };
  return context.request(
    KugouRequest(
      path: jsString("/genesisapi/v1/newepoch_song_rec/feed"),
      method: jsString("post"),
      parameters: stringObjectMap(<String, Object?>{
        "sort_type": 1,
        "platform": "ios",
        "page": 1,
        "content_ver": 4,
        "clientver": 11850,
      }),
      data: dataMap,
      cookies: stringStringMap(
        jsOr(context.session.cookies, <String, Object?>{}),
      ),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedCaptchaSent(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final dataMap = <String, Object?>{
    "businessid": 5,
    "mobile": jsString(input["mobile"]),
    "plat": 3,
  };
  return context.request(
    KugouRequest(
      path: jsString("/v7/send_mobile_code"),
      baseUri: Uri.parse(jsString("http://login.user.kugou.com")),
      method: jsString("POST"),
      data: dataMap,
      cookies: stringStringMap(<String, Object?>{
        "mid": endpointCookie(context, input, "KUGOU_API_MID"),
      }),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedCommentAlbum(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final paramsMap = <String, Object?>{
    "childrenid": input["id"],
    "need_show_image": 1,
    "p": jsOr(input["page"], 1),
    "pagesize": jsOr(input["pagesize"], 30),
    "show_classify": jsOr(input["show_classify"], 1),
    "show_hotword_list": jsOr(input["show_hotword_list"], 1),
    "code": "94f1792ced1df89aa68a7939eaf2efca",
  };
  return context.request(
    KugouRequest(
      path: jsString("/m.comment.service/v1/cmtlist"),
      method: jsString("POST"),
      parameters: stringObjectMap(paramsMap),
      cookies: stringStringMap(
        jsOr(context.session.cookies, <String, Object?>{}),
      ),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedCommentMusic(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final paramsMap = <String, Object?>{
    "ver": jsNumber(jsOr(6, 6)),
    "mixsongid": input["mixsongid"],
    "need_show_image": 1,
    "p": jsOr(input["page"], 1),
    "pagesize": jsOr(input["pagesize"], 30),
    "show_classify": jsOr(input["show_classify"], 1),
    "show_hotword_list": jsOr(input["show_hotword_list"], 1),
    "extdata": "0",
    "code": "fc4be23b4e972707f36b8a828a93ba8a",
  };
  return context.request(
    KugouRequest(
      path: jsString("/mcomment/v1/cmtlist"),
      method: jsString("POST"),
      parameters: stringObjectMap(paramsMap),
      cookies: stringStringMap(
        jsOr(context.session.cookies, <String, Object?>{}),
      ),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedCommentMusicClassify(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final paramsMap = <String, Object?>{
    "mixsongid": input["mixsongid"],
    "need_show_image": 1,
    "page": jsOr(input["page"], 1),
    "pagesize": jsOr(input["pagesize"], 30),
    "type_id": input["type_id"],
    "extdata": "0",
    "code": "fc4be23b4e972707f36b8a828a93ba8a",
    "sort_method": (jsTruthy((jsNumber(input["sort"]) == 2))
        ? input["sort"]
        : 1),
  };
  return context.request(
    KugouRequest(
      path: jsString("/mcomment/v1/cmt_classify_list"),
      method: jsString("POST"),
      parameters: stringObjectMap(paramsMap),
      cookies: stringStringMap(
        jsOr(context.session.cookies, <String, Object?>{}),
      ),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedCommentMusicHotword(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final paramsMap = <String, Object?>{
    "mixsongid": input["mixsongid"],
    "need_show_image": 1,
    "p": jsOr(input["page"], 1),
    "pagesize": jsOr(input["pagesize"], 30),
    "hot_word": input["hot_word"],
    "extdata": "0",
    "code": "fc4be23b4e972707f36b8a828a93ba8a",
  };
  return context.request(
    KugouRequest(
      path: jsString("/mcomment/v1/get_hot_word"),
      method: jsString("POST"),
      parameters: stringObjectMap(paramsMap),
      cookies: stringStringMap(
        jsOr(context.session.cookies, <String, Object?>{}),
      ),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedCommentPlaylist(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final paramsMap = <String, Object?>{
    "childrenid": input["id"],
    "need_show_image": 1,
    "p": jsOr(input["page"], 1),
    "pagesize": jsOr(input["pagesize"], 30),
    "show_classify": jsOr(input["show_classify"], 1),
    "show_hotword_list": jsOr(input["show_hotword_list"], 1),
    "code": "ca53b96fe5a1d9c22d71c8f522ef7c4f",
    "content_type": 0,
    "tag": 5,
  };
  return context.request(
    KugouRequest(
      path: jsString("/m.comment.service/v1/cmtlist"),
      method: jsString("POST"),
      parameters: stringObjectMap(paramsMap),
      cookies: stringStringMap(
        jsOr(context.session.cookies, <String, Object?>{}),
      ),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedEffectsArtist(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final paramsMap = <String, Object?>{
    "plat": 2,
    "version": 12460,
    "apiver": 2,
    "sort": 1,
    "pagesize": jsOr(input["pagesize"], 30),
    "page": jsOr(input["page"], 1),
    "classify": 1,
  };
  return context.request(
    KugouRequest(
      path: jsString("/api/v3/sound/list"),
      baseUri: Uri.parse(jsString("http://mobilecdngz.kugou.com")),
      method: jsString("GET"),
      parameters: stringObjectMap(paramsMap),
      cookies: stringStringMap(
        jsOr(context.session.cookies, <String, Object?>{}),
      ),
      clearDefaultParameters: jsTruthy(true),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedEffectsBrand(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final paramsMap = <String, Object?>{
    "sort": 1,
    "pagesize": jsOr(input["pagesize"], 30),
    "page": jsOr(input["page"], 1),
  };
  return context.request(
    KugouRequest(
      path: jsString("/api/v5/earphone/get_brand"),
      baseUri: Uri.parse(jsString("http://mobilecdngz.kugou.com")),
      method: jsString("GET"),
      parameters: stringObjectMap(paramsMap),
      cookies: stringStringMap(
        jsOr(context.session.cookies, <String, Object?>{}),
      ),
      clearDefaultParameters: jsTruthy(true),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedEffectsBrandDetail(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final paramsMap = <String, Object?>{
    "brand_id": jsOr(input["brand_id"], 0),
    "pagesize": jsOr(input["pagesize"], 30),
    "page": jsOr(input["page"], 1),
  };
  return context.request(
    KugouRequest(
      path: jsString("/api/v5/earphone/get_model"),
      baseUri: Uri.parse(jsString("http://mobilecdngz.kugou.com")),
      method: jsString("GET"),
      parameters: stringObjectMap(paramsMap),
      cookies: stringStringMap(
        jsOr(context.session.cookies, <String, Object?>{}),
      ),
      clearDefaultParameters: jsTruthy(true),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedEffectsCarBrand(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  return context.request(
    KugouRequest(
      path: jsString("/api/v5/car_sound/get_brand"),
      baseUri: Uri.parse(jsString("http://mobilecdngz.kugou.com")),
      method: jsString("GET"),
      cookies: stringStringMap(
        jsOr(context.session.cookies, <String, Object?>{}),
      ),
      clearDefaultParameters: jsTruthy(true),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedEffectsCarBrandLists(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final paramsMap = <String, Object?>{
    "plat": 2,
    "version": 12460,
    "apiver": 2,
    "sort": 1,
    "pagesize": jsOr(input["pagesize"], 30),
    "page": jsOr(input["page"], 1),
    "classify": 5,
    "rel_id": jsOr(input["rel_id"], 0),
  };
  return context.request(
    KugouRequest(
      path: jsString("/api/v3/sound/list"),
      baseUri: Uri.parse(jsString("http://mobilecdngz.kugou.com")),
      method: jsString("GET"),
      parameters: stringObjectMap(paramsMap),
      cookies: stringStringMap(
        jsOr(context.session.cookies, <String, Object?>{}),
      ),
      clearDefaultParameters: jsTruthy(true),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedEffectsMatch(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final paramsMap = <String, Object?>{"plat": 2, "version": 12460};
  return context.request(
    KugouRequest(
      path: jsString("/api/v5/earphone/match"),
      baseUri: Uri.parse(jsString("http://mobilecdngz.kugou.com")),
      method: jsString("GET"),
      parameters: stringObjectMap(paramsMap),
      cookies: stringStringMap(
        jsOr(context.session.cookies, <String, Object?>{}),
      ),
      clearDefaultParameters: jsTruthy(true),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedEverydayFriend(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  return context.request(
    KugouRequest(
      path: jsString("/sing7/relation/json/v3/friend_rec_by_using_song_list"),
      baseUri: Uri.parse(jsString("https://acsing.service.kugou.com")),
      method: jsString("POST"),
      parameters: stringObjectMap(<String, Object?>{
        "channel": 130,
        "isteen": 0,
        "platform": 2,
        "usemkv": 1,
      }),
      data: <String, Object?>{
        "list": <Object?>[
          <String, Object?>{
            "user_id": 853927886,
            "mixsong_ids": <Object?>[
              290083753,
              251724346,
              571554587,
              250126644,
              208831644,
              40328518,
              250504076,
              581706850,
              318347675,
              585258401,
              288481998,
              407414475,
              28239430,
              280584633,
              291957521,
              64556644,
              243149863,
              488725103,
              32114153,
              39951172,
              29019580,
              40397606,
              327507651,
              32029382,
              32218359,
              340353127,
              276448762,
              177071956,
              100031397,
              249251602,
            ],
          },
        ],
      },
      headers: stringObjectMap(<String, Object?>{"pid": 126556797}),
      cookies: stringStringMap(
        jsOr(context.session.cookies, <String, Object?>{}),
      ),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedEverydayHistory(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final paramsMap = <String, Object?>{
    "mode": jsOr(input["mode"], "list"),
    "platform": jsOr(input["platform"], "ios"),
  };
  if (jsTruthy((input["history_name"]))) {
    paramsMap[jsString("history_name")] = input["history_name"];
  }
  if (jsTruthy((input["date"]))) {
    paramsMap[jsString("date")] = input["date"];
  }
  return context.request(
    KugouRequest(
      path: jsString("/everyday/api/v1/get_history"),
      method: jsString("POST"),
      parameters: stringObjectMap(paramsMap),
      headers: stringObjectMap(<String, Object?>{
        "x-router": "everydayrec.service.kugou.com",
      }),
      cookies: stringStringMap(
        jsOr(context.session.cookies, <String, Object?>{}),
      ),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedEverydayRecommend(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  return context.request(
    KugouRequest(
      path: jsString("/everyday_song_recommend"),
      method: jsString("POST"),
      parameters: stringObjectMap(<String, Object?>{
        "platform": jsOr(input["platform"], "ios"),
      }),
      headers: stringObjectMap(<String, Object?>{
        "x-router": "everydayrec.service.kugou.com",
      }),
      cookies: stringStringMap(
        jsOr(context.session.cookies, <String, Object?>{}),
      ),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedEverydayStyleRecommend(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final dataMap = <String, Object?>{"platform": jsOr(input["platform"], "ios")};
  return context.request(
    KugouRequest(
      path: jsString("/everydayrec.service/everyday_style_recommend"),
      method: jsString("POST"),
      parameters: stringObjectMap(<String, Object?>{
        "tagids": (input["tagids"] ?? ""),
      }),
      data: <String, Object?>{},
      cookies: stringStringMap(
        jsOr(context.session.cookies, <String, Object?>{}),
      ),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedFavoriteCount(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  return context.request(
    KugouRequest(
      path: jsString("/count/v1/audio/mget_collect"),
      method: jsString("GET"),
      parameters: stringObjectMap(<String, Object?>{
        "mixsongids": input["mixsongids"],
      }),
      cookies: stringStringMap(
        jsOr(context.session.cookies, <String, Object?>{}),
      ),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedFmClass(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final dateTime = context.nowMilliseconds;
  final userid = jsOr(
    jsOr(endpointCookie(context, input, "userid"), input["userid"]),
    0,
  );
  final dataMap = <String, Object?>{
    "kguid": userid,
    "clienttime": dateTime,
    "mid": endpointCookie(context, input, "KUGOU_API_MID"),
    "platform": "android",
    "clientver": context.config.clientVersion,
    "uid": userid,
    "get_tracker": 1,
    "key": context.signatures.parametersKey(dateTime),
    "appid": context.config.appId,
  };
  return context.request(
    KugouRequest(
      path: jsString("/v1/class_fm_song"),
      method: jsString("POST"),
      data: dataMap,
      headers: stringObjectMap(<String, Object?>{
        "x-router": "fm.service.kugou.com",
      }),
      cookies: stringStringMap(
        jsOr(context.session.cookies, <String, Object?>{}),
      ),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedFmImage(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final dateTime = context.nowMilliseconds;
  final dfid = jsOr(
    jsOr(endpointCookie(context, input, "dfid"), input["dfid"]),
    "-",
  );
  final userid = jsOr(
    endpointCookie(context, input, "userid"),
    input["userid"],
  );
  final token = jsOr(endpointCookie(context, input, "token"), input["token"]);
  final fmData = (jsString((jsOr(input["fmid"], ""))).split(jsString(",")))
      .map<Object?>(
        (s) => (<String, Object?>{
          "fields": "imgUrl100,imgUrl50",
          "fmid": s,
          "fmtype": 2,
        }),
      )
      .toList(growable: false);
  final dataMap = <String, Object?>{
    "appid": context.config.appId,
    "clienttime": dateTime,
    "clientver": context.config.clientVersion,
    "data": fmData,
    "dfid": dfid,
    "key": context.signatures.parametersKey(dateTime),
    "mid": endpointCookie(context, input, "KUGOU_API_MID"),
  };
  if (jsTruthy((userid))) {
    dataMap[jsString("userid")] = userid;
  }
  if (jsTruthy((token))) {
    dataMap[jsString("token")] = token;
  }
  return context.request(
    KugouRequest(
      path: jsString("/v1/fm_info"),
      method: jsString("POST"),
      data: dataMap,
      headers: stringObjectMap(<String, Object?>{
        "x-router": "fm.service.kugou.com",
        "Content-Type": "application/json",
      }),
      cookies: stringStringMap(
        jsOr(context.session.cookies, <String, Object?>{}),
      ),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedFmRecommend(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final dateTime = context.nowMilliseconds;
  final dfid = jsOr(
    jsOr(endpointCookie(context, input, "dfid"), input["dfid"]),
    "-",
  );
  final dataMap = <String, Object?>{
    "appid": context.config.appId,
    "clientver": context.config.clientVersion,
    "clienttime": dateTime,
    "mid": endpointCookie(context, input, "KUGOU_API_MID"),
    "key": context.signatures.parametersKey(dateTime),
    "rcmdsongcount": 1,
    "level": 0,
    "area_code": 1,
    "get_tracker": 1,
    "uid": 0,
  };
  return context.request(
    KugouRequest(
      path: jsString("/v1/rcmd_list"),
      method: jsString("POST"),
      data: dataMap,
      headers: stringObjectMap(<String, Object?>{
        "x-router": "fm.service.kugou.com",
      }),
      cookies: stringStringMap(
        jsOr(context.session.cookies, <String, Object?>{}),
      ),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedGetModeInfo(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final dataMap = <String, Object?>{
    "model_id": jsNumber(jsOr(input["model_id"], 0)),
    "req_src": "collection",
    "earphone_vip": 1,
    "sound_ver": 2,
    "key": context.signatures.parametersKey(context.nowMilliseconds),
    "page": jsOr(input["page"], 1),
    "pagesize": jsOr(input["pagesize"], 30),
  };
  return context.request(
    KugouRequest(
      path: jsString("/api/v5/earphone/get_model_info"),
      baseUri: Uri.parse(jsString("http://mobileservice.kugou.com")),
      method: jsString("GET"),
      parameters: stringObjectMap(dataMap),
      cookies: stringStringMap(
        jsOr(context.session.cookies, <String, Object?>{}),
      ),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedGetModel(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final dataMap = <String, Object?>{
    "super_vip": 1,
    "sound_ver": 2,
    "page": jsOr(input["page"], 1),
    "pagesize": jsOr(input["pagesize"], 30),
    "apiver": 3,
    "classify": "2,3",
    "plat": 2,
    "privilege": 1,
    "sort": jsOr(input["sort"], 2),
  };
  return context.request(
    KugouRequest(
      path: jsString("/ocean/v6/sound/list"),
      method: jsString("GET"),
      parameters: stringObjectMap(dataMap),
      cookies: stringStringMap(
        jsOr(context.session.cookies, <String, Object?>{}),
      ),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedGetVerifyInfo(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final userid = jsNumber(
    jsOr(jsOr(input["userid"], endpointCookie(context, input, "userid")), "0"),
  );
  final dataMap = <String, Object?>{
    "eventid": input["eventid"],
    "userid": userid,
    "platid": jsOr(input["platid"], 2),
    "rtype": 1,
    "wasm": 1,
    "i": "",
    "sid": "",
    "edt": "",
  };
  return context.request(
    KugouRequest(
      path: jsString("/verifyservice/v3/get_verify_info"),
      method: jsString("POST"),
      data: dataMap,
      cookies: stringStringMap(
        jsOr(context.session.cookies, <String, Object?>{}),
      ),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedHomeDiscover(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final userid = jsOr(
    jsOr(input["userid"], endpointCookie(context, input, "userid")),
    0,
  );
  final goKyExtra = jsOr(input["go_ky_extra"], <Object?>[
    <String, Object?>{"key": "network", "val": "2"},
    <String, Object?>{"key": "play_mode", "val": "2"},
    <String, Object?>{"key": "no_mv_ret", "val": "1"},
  ]);
  final data = <String, Object?>{
    "support": jsOr(input["support"], "only_song"),
    "userid": userid,
    "recall_type": jsOr(input["recall_type"], "song"),
    "today_play_num": jsOr(input["today_play_num"], 0),
    "pagesize": jsOr(input["pagesize"], 4),
    "go_ky_extra": goKyExtra,
  };
  return context.request(
    KugouRequest(
      path: jsString("/homediscoverrec/v1/client/home_discover_rec"),
      method: jsString("POST"),
      parameters: stringObjectMap(<String, Object?>{
        "module_key": "home_discover_rec",
        "module_id": 1,
        "area_code": 1,
        "platform": "android",
        "userid": userid,
        "clientver": 20809,
      }),
      data: data,
      cookies: stringStringMap(
        jsOr(context.session.cookies, <String, Object?>{}),
      ),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedIp(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final dataMap = <String, Object?>{
    "is_publish": 1,
    "ip_id": input["id"],
    "sort": 3,
    "page": jsOr(input["page"], 1),
    "pagesize": jsOr(input["pagesize"], 30),
    "query": 1,
  };
  final type =
      (jsTruthy(
        (<Object?>[
          "audios",
          "albums",
          "videos",
          "author_list",
        ]).contains(input["type"]),
      )
      ? input["type"]
      : "audios");
  return context.request(
    KugouRequest(
      path: jsString("/openapi/v1/ip/" + jsString(type)),
      method: jsString("POST"),
      data: dataMap,
      cookies: stringStringMap(
        jsOr(context.session.cookies, <String, Object?>{}),
      ),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedIpDateil(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final data = (jsString((jsOr(input["id"], ""))).split(jsString(",")))
      .map<Object?>((s) => (<String, Object?>{"ip_id": s}))
      .toList(growable: false);
  final dataMap = <String, Object?>{"data": data, "is_publish": 1};
  return context.request(
    KugouRequest(
      path: jsString("/openapi/v1/ip"),
      method: jsString("POST"),
      data: dataMap,
      cookies: stringStringMap(
        jsOr(context.session.cookies, <String, Object?>{}),
      ),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedIpPlaylist(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final dataMap = <String, Object?>{
    "ip": input["id"],
    "page": jsOr(input["page"], 1),
    "pagesize": jsOr(input["pagesize"], 30),
  };
  return context.request(
    KugouRequest(
      path: jsString("/ocean/v6/pubsongs/list_info_for_ip"),
      method: jsString("POST"),
      parameters: stringObjectMap(dataMap),
      cookies: stringStringMap(
        jsOr(context.session.cookies, <String, Object?>{}),
      ),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedIpZoneHome(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final dataMap = <String, Object?>{"id": input["id"], "share": 0};
  return context.request(
    KugouRequest(
      path: jsString("/v1/zone/home"),
      method: jsString("GET"),
      parameters: stringObjectMap(dataMap),
      headers: stringObjectMap(<String, Object?>{
        "x-router": "yuekucategory.kugou.com",
      }),
      cookies: stringStringMap(
        jsOr(context.session.cookies, <String, Object?>{}),
      ),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedKmrAudioMv(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final resource =
      (jsString((jsOr(input["album_audio_id"], ""))).split(jsString(",")))
          .map<Object?>((s) => (<String, Object?>{"album_audio_id": s}))
          .toList(growable: false);
  final paramsMap = <String, Object?>{
    "data": resource,
    "fields": jsOr(input["fields"], ""),
  };
  return context.request(
    KugouRequest(
      path: jsString("/kmr/v1/audio/mv"),
      method: jsString("POST"),
      data: paramsMap,
      headers: stringObjectMap(<String, Object?>{
        "x-router": "openapi.kugou.com",
        "KG-TID": 38,
      }),
      cookies: stringStringMap(
        jsOr(context.session.cookies, <String, Object?>{}),
      ),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedKrmAudio(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final resource =
      (jsString((jsOr(input["album_audio_id"], ""))).split(jsString(",")))
          .map<Object?>((s) => (<String, Object?>{"entity_id": jsNumber(s)}))
          .toList(growable: false);
  final paramsMap = <String, Object?>{
    "data": resource,
    "fields": jsOr(input["fields"], "base"),
  };
  return context.request(
    KugouRequest(
      path: jsString("/kmr/v2/audio"),
      method: jsString("POST"),
      data: paramsMap,
      headers: stringObjectMap(<String, Object?>{
        "x-router": "openapi.kugou.com",
        "KG-TID": 238,
      }),
      cookies: stringStringMap(
        jsOr(context.session.cookies, <String, Object?>{}),
      ),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedLastestSongsListen(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final token = jsOr(
    jsOr(input["token"], endpointCookie(context, input, "token")),
    "",
  );
  final userid = jsNumber(
    jsOr(jsOr(input["userid"], endpointCookie(context, input, "userid")), 0),
  );
  final paramsMap = <String, Object?>{
    "area_code": "1",
    "sources": <Object?>["pc", "mobile", "tv", "car"],
    "userid": userid,
    "ret_info": 1,
    "token": token,
    "pagesize": jsNumber(jsOr(input["pagesize"], 30)),
  };
  return context.request(
    KugouRequest(
      path: jsString("/playque/devque/v1/get_latest_songs"),
      method: jsString("POST"),
      data: paramsMap,
      cookies: stringStringMap(
        jsOr(context.session.cookies, <String, Object?>{}),
      ),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedLoginDevice(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final clienttime_ms = jsNumber(context.nowMilliseconds).toInt();
  final encrypt = context.crypto.aesEncrypt(<String, Object?>{
    "token": jsOr(input["token"], endpointCookie(context, input, "token")),
  });
  final dataMap = <String, Object?>{
    "plat": 1,
    "userid": jsOr(
      jsOr(input["userid"], endpointCookie(context, input, "userid")),
      0,
    ),
    "clienttime_ms": clienttime_ms,
    "pk": jsString(
      context.crypto.rsaRawEncrypt(<String, Object?>{
        "clienttime_ms": clienttime_ms,
        "key": (encrypt).key,
      }),
    ).toUpperCase(),
    "params": (encrypt).ciphertext,
  };
  return context.request(
    KugouRequest(
      path: jsString("/v2/get_dev"),
      baseUri: Uri.parse(jsString("https://userinfoservice.kugou.com")),
      method: jsString("POST"),
      data: dataMap,
      cookies: stringStringMap(
        jsOr(context.session.cookies, <String, Object?>{}),
      ),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedLoginQrKey(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  return context.request(
    KugouRequest(
      path: jsString("/v2/qrcode"),
      baseUri: Uri.parse(jsString("https://login-user.kugou.com")),
      method: jsString("GET"),
      parameters: stringObjectMap(<String, Object?>{
        "appid": (jsTruthy((input["type"] == "web")) ? 1014 : 1001),
        "type": 1,
        "plat": 4,
        "qrcode_txt":
            "https://h5.kugou.com/apps/loginQRCode/html/index.html?appid=" +
            jsString(context.config.appId) +
            "&",
        "srcappid": KugouApiConfig.sourceAppId,
      }),
      cookies: stringStringMap(
        jsOr(context.session.cookies, <String, Object?>{}),
      ),
      signatureType: KugouSignatureType.web,
    ),
  );
}

Future<KugouResponse<Object?>> _generatedLongaudioAlbumAudios(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  return context.request(
    KugouRequest(
      path: jsString("/longaudio/v2/album_audios"),
      method: jsString("post"),
      data: <String, Object?>{
        "album_id": input["album_id"],
        "area_code": 1,
        "tagid": 0,
        "page": jsOr(input["page"], 1),
        "pagesize": jsOr(input["pagesize"], 30),
      },
      headers: stringObjectMap(<String, Object?>{
        "x-router": "openapi.kugou.com",
        "KG-TID": "78",
      }),
      cookies: stringStringMap(
        jsOr(context.session.cookies, <String, Object?>{}),
      ),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedLongaudioAlbumDetail(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final data = (jsString((jsOr(input["album_id"], ""))).split(jsString(",")))
      .map<Object?>((s) => (<String, Object?>{"album_id": s}))
      .toList(growable: false);
  return context.request(
    KugouRequest(
      path: jsString("/openapi/v2/broadcast"),
      method: jsString("post"),
      data: <String, Object?>{
        "data": data,
        "show_album_tag": 1,
        "fields":
            "album_name,album_id,category,authors,sizable_cover,intro,author_name,trans_param,album_tag,mix_intro,full_intro,is_publish",
      },
      headers: stringObjectMap(<String, Object?>{"KG-TID": "78"}),
      cookies: stringStringMap(
        jsOr(context.session.cookies, <String, Object?>{}),
      ),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedLongaudioAlbumList(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final dataMap = <String, Object?>{
    "api_ver": 2,
    "gender": jsMax(<Object?>[0, jsOr(jsNumber(input["gender"]).toInt(), 0)]),
    "sort": jsMax(<Object?>[0, jsOr(jsNumber(input["sort"]).toInt(), 0)]),
    "tag_id": jsMax(<Object?>[0, jsOr(jsNumber(input["tag_id"]).toInt(), 906)]),
    "free": 1,
    "status": jsMax(<Object?>[0, jsOr(jsNumber(input["status"]).toInt(), 0)]),
    "page": jsMax(<Object?>[1, jsOr(jsNumber(input["page"]).toInt(), 1)]),
    "page_size": jsMax(<Object?>[
      1,
      jsOr(jsNumber(input["page_size"]).toInt(), 20),
    ]),
    "clientver": 20789,
  };
  return context.request(
    KugouRequest(
      path: jsString("/longaudio/v1/album/list"),
      method: jsString("get"),
      parameters: stringObjectMap(dataMap),
      cookies: stringStringMap(
        jsOr(context.session.cookies, <String, Object?>{}),
      ),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedLongaudioDailyRecommend(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  return context.request(
    KugouRequest(
      path: jsString("/longaudio/v1/home_new/daily_recommend"),
      method: jsString("post"),
      parameters: stringObjectMap(<String, Object?>{
        "module_id": 1,
        "size": jsOr(input["pagesize"], 30),
        "page": jsOr(input["page"], 1),
      }),
      cookies: stringStringMap(
        jsOr(context.session.cookies, <String, Object?>{}),
      ),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedLongaudioRankRecommend(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  return context.request(
    KugouRequest(
      path: jsString("/longaudio/v1/home_new/rank_card_recommend"),
      method: jsString("get"),
      parameters: stringObjectMap(<String, Object?>{"platform": "ios"}),
      cookies: stringStringMap(
        jsOr(context.session.cookies, <String, Object?>{}),
      ),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedLongaudioSearch(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final dataMap = <String, Object?>{
    "area_code": 1,
    "albumhide": 1,
    "com_user_type": 0,
    "privilegefilter": 0,
    "dopicfull": 1,
    "filter": 12,
    "platform": "AndroidFilter",
    "tag": "em",
    "recver": 2,
    "iscorrection": 1,
    "search_ability": 223,
    "sec_aggre": 1,
    "sec_aggre_bitmap": 0,
    "mode_ability": 1,
    "nocollect": 1,
    "user_type": 0,
    "userid":
        ((input["userid"] ?? endpointCookie(context, input, "userid")) ?? "0"),
    "keyword": (input["keywords"] ?? input["keyword"]),
    "page": jsMax(<Object?>[1, jsOr(jsNumber(input["page"]).toInt(), 1)]),
    "pagesize": jsMax(<Object?>[
      1,
      jsOr(jsNumber(input["pagesize"]).toInt(), 30),
    ]),
    "clientver": 20789,
  };
  return context.request(
    KugouRequest(
      path: jsString("/complexsearch/v4/search/song"),
      method: jsString("get"),
      parameters: stringObjectMap(dataMap),
      cookies: stringStringMap(
        jsOr(context.session.cookies, <String, Object?>{}),
      ),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedLongaudioTagList(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  return context.request(
    KugouRequest(
      path: jsString("/v3/list_audiobook_tags"),
      method: jsString("get"),
      parameters: stringObjectMap(<String, Object?>{
        "platform": "android",
        "clientver": 20789,
      }),
      headers: stringObjectMap(<String, Object?>{
        "x-router": "longaudio.kugou.com",
      }),
      cookies: stringStringMap(
        jsOr(context.session.cookies, <String, Object?>{}),
      ),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedLongaudioVipRecommend(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  return context.request(
    KugouRequest(
      path: jsString("/longaudio/v1/home_new/vip_select_recommend"),
      method: jsString("post"),
      parameters: stringObjectMap(<String, Object?>{
        "position": "2",
        "clientver": 12329,
      }),
      data: <String, Object?>{"album_playlist": <Object?>[]},
      cookies: stringStringMap(
        jsOr(context.session.cookies, <String, Object?>{}),
      ),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedLongaudioWeekRecommend(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  return context.request(
    KugouRequest(
      path: jsString("/longaudio/v1/home_new/week_new_albums_recommend"),
      method: jsString("post"),
      parameters: stringObjectMap(<String, Object?>{"clientver": 12329}),
      data: <String, Object?>{"album_playlist": <Object?>[]},
      cookies: stringStringMap(
        jsOr(context.session.cookies, <String, Object?>{}),
      ),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedPcDiantai(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final userid = jsOr(
    jsOr(endpointCookie(context, input, "userid"), input["userid"]),
    0,
  );
  final dataMap = <String, Object?>{"isvip": 0, "userid": userid, "vipType": 0};
  return context.request(
    KugouRequest(
      path: jsString("/v3/pc_diantai"),
      baseUri: Uri.parse(jsString("https://adservice.kugou.com")),
      method: jsString("post"),
      data: dataMap,
      cookies: stringStringMap(
        jsOr(context.session.cookies, <String, Object?>{}),
      ),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedPersonalFm(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final userid = jsOr(
    jsOr(endpointCookie(context, input, "userid"), input["userid"]),
    0,
  );
  final token = jsOr(
    jsOr(endpointCookie(context, input, "token"), input["token"]),
    0,
  );
  final vip_type = jsOr(
    jsOr(endpointCookie(context, input, "vip_type"), input["vipType"]),
    0,
  );
  final dateTime = context.nowMilliseconds;
  final dataMap = <String, Object?>{
    "appid": context.config.appId,
    "clienttime": dateTime,
    "mid": endpointCookie(context, input, "KUGOU_API_MID"),
    "action": jsOr(input["action"], "play"),
    "recommend_source_locked": 0,
    "song_pool_id": jsNumber(jsOr(input["song_pool_id"], 0)),
    "callerid": 0,
    "m_type": 1,
    "platform": jsOr(input["platform"], "ios"),
    "area_code": 1,
    "remain_songcnt": jsNumber(jsOr(input["remain_songcnt"], 0)),
    "clientver": context.config.clientVersion,
    "is_overplay": (jsTruthy(input["is_overplay"]) ? 1 : 0),
    "mode": jsOr(input["mode"], "normal"),
    "fakem": "ca981cfc583a4c37f28d2d49000013c16a0a",
    "key": context.signatures.parametersKey(dateTime),
  };
  if (jsTruthy((userid))) {
    dataMap[jsString("userid")] = userid;
    dataMap[jsString("kguid")] = userid;
  }
  if (jsTruthy((token))) {
    dataMap[jsString("token")] = token;
  }
  if (jsTruthy((vip_type))) {
    dataMap[jsString("vip_type")] = vip_type;
  }
  if (jsTruthy((input["hash"]))) {
    dataMap[jsString("hash")] = input["hash"];
  }
  if (jsTruthy((input["songid"]))) {
    dataMap[jsString("songid")] = input["songid"];
  }
  if (jsTruthy((input["playtime"]))) {
    dataMap[jsString("playtime")] = input["playtime"];
  }
  if (jsTruthy((input["cur_mark"]))) {
    dataMap[jsString("cur_mark")] = input["cur_mark"];
  }
  return context.request(
    KugouRequest(
      path: jsString("/v2/personal_recommend"),
      method: jsString("post"),
      data: dataMap,
      headers: stringObjectMap(<String, Object?>{
        "x-router": "persnfm.service.kugou.com",
      }),
      cookies: stringStringMap(
        jsOr(context.session.cookies, <String, Object?>{}),
      ),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedPlayhistoryUpload(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final userid = jsOr(
    jsOr(input["userid"], endpointCookie(context, input, "userid")),
    0,
  );
  final token = jsOr(
    jsOr(input["token"], endpointCookie(context, input, "token")),
    "",
  );
  final songs = <Object?>[
    <String, Object?>{
      "mxid": jsNumber(input["mxid"]),
      "op": 1,
      "ot": jsNumber(
        jsOr(
          input["time"],
          jsNumber(
            (jsNumber(context.nowMilliseconds) / jsNumber(1000)),
          ).floor(),
        ),
      ),
      "pc": jsNumber(jsOr(input["pc"], 1)),
    },
  ];
  final dataMap = <String, Object?>{
    "songs": songs,
    "token": token,
    "userid": userid,
  };
  return context.request(
    KugouRequest(
      path: jsString("/playhistory/v1/upload_songs"),
      method: jsString("POST"),
      parameters: stringObjectMap(<String, Object?>{"plat": 3}),
      data: dataMap,
      cookies: stringStringMap(
        jsOr(context.session.cookies, <String, Object?>{}),
      ),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedPlaylistAdd(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final userid = jsOr(
    jsOr(input["userid"], endpointCookie(context, input, "userid")),
    0,
  );
  final token = jsOr(
    jsOr(input["token"], endpointCookie(context, input, "token")),
    "",
  );
  final clienttime = jsNumber(
    (jsNumber(context.nowMilliseconds) / jsNumber(1000)),
  ).floor();
  final dataMap = <String, Object?>{
    "userid": userid,
    "token": token,
    "total_ver": 0,
    "name": input["name"],
    "type": jsOr(input["type"], 0),
    "source": (jsTruthy((input["source"] == 0)) ? 0 : jsOr(input["source"], 1)),
    "is_pri": 0,
    "list_create_userid": input["list_create_userid"],
    "list_create_listid": input["list_create_listid"],
    "list_create_gid": jsOr(input["list_create_gid"], ""),
    "from_shupinmv": 0,
  };
  if (jsTruthy(((input["type"] == 0)))) {
    dataMap[jsString("is_pri")] = jsOr(input["is_pri"], 0);
  }
  return context.request(
    KugouRequest(
      path: jsString("/cloudlist.service/v5/add_list"),
      method: jsString("post"),
      parameters: stringObjectMap(
        (jsTruthy((input["type"] == 0))
            ? <String, Object?>{
                "last_time": clienttime,
                "last_area": "gztx",
                "userid": userid,
                "token": token,
              }
            : <String, Object?>{}),
      ),
      data: dataMap,
      cookies: stringStringMap(
        jsOr(context.session.cookies, <String, Object?>{}),
      ),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedPlaylistDetail(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final data = (jsString((jsOr(input["ids"], ""))).split(jsString(",")))
      .map<Object?>((s) => (<String, Object?>{"global_collection_id": s}))
      .toList(growable: false);
  final dataMap = <String, Object?>{
    "data": data,
    "userid": jsOr(
      jsOr(input["userid"], endpointCookie(context, input, "userid")),
      0,
    ),
    "token": jsOr(
      jsOr(input["token"], endpointCookie(context, input, "token")),
      "",
    ),
  };
  return context.request(
    KugouRequest(
      path: jsString("/v3/get_list_info"),
      method: jsString("POST"),
      data: dataMap,
      headers: stringObjectMap(<String, Object?>{
        "x-router": "pubsongs.kugou.com",
      }),
      cookies: stringStringMap(
        jsOr(context.session.cookies, <String, Object?>{}),
      ),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedPlaylistEffect(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final dataMap = <String, Object?>{
    "page": jsOr(input["page"], 1),
    "pagesize": jsOr(input["pagesize"], 30),
  };
  return context.request(
    KugouRequest(
      path: jsString("/pubsongs/v1/get_sound_effect_list"),
      method: jsString("POST"),
      data: dataMap,
      cookies: stringStringMap(
        jsOr(context.session.cookies, <String, Object?>{}),
      ),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedPlaylistSimilar(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final data = (jsString((jsOr(input["ids"], ""))).split(jsString(",")))
      .map<Object?>((s) => (<String, Object?>{"global_collection_id": s}))
      .toList(growable: false);
  final clienttime = context.nowMilliseconds;
  final dataMap = <String, Object?>{
    "appid": context.config.appId,
    "clientver": context.config.clientVersion,
    "clienttime": clienttime,
    "key": context.signatures.parametersKey(clienttime),
    "userid": jsOr(
      jsOr(input["userid"], endpointCookie(context, input, "userid")),
      0,
    ),
    "ugc": 1,
    "show_list": 1,
    "need_songs": 1,
    "data": data,
  };
  return context.request(
    KugouRequest(
      path: jsString("/pubsongs/v1/kmr_get_similar_lists"),
      method: jsString("POST"),
      data: dataMap,
      cookies: stringStringMap(
        jsOr(context.session.cookies, <String, Object?>{}),
      ),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedPlaylistTags(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final dataMap = <String, Object?>{
    "tag_type": "collection",
    "tag_id": 0,
    "source": 3,
  };
  return context.request(
    KugouRequest(
      path: jsString("/pubsongs/v1/get_tags_by_type"),
      method: jsString("POST"),
      data: dataMap,
      cookies: stringStringMap(
        jsOr(context.session.cookies, <String, Object?>{}),
      ),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedPlaylistTrackAllNew(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final userid = jsOr(
    jsOr(input["userid"], endpointCookie(context, input, "userid")),
    "0",
  );
  final token = jsOr(
    jsOr(input["token"], endpointCookie(context, input, "token")),
    "0",
  );
  final dataMap = <String, Object?>{
    "listid": input["listid"],
    "userid": userid,
    "type": jsNumber(jsOr(input["type"], 0)),
    "page": jsNumber(jsOr(input["page"], 1)),
    "pagesize": jsNumber(jsOr(input["pagesize"], 300)),
    "area_code": 1,
    "allplatform": 1,
    "show_cover": 1,
    "token": token,
  };
  return context.request(
    KugouRequest(
      path: jsString("/v4/get_list_all_file_v3"),
      method: jsString("post"),
      data: dataMap,
      headers: stringObjectMap(<String, Object?>{
        "x-router": "cloudlist.service.kugou.com",
      }),
      cookies: stringStringMap(
        jsOr(context.session.cookies, <String, Object?>{}),
      ),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedPlaylistTracksDel(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final userid = jsOr(
    jsOr(input["userid"], endpointCookie(context, input, "userid")),
    0,
  );
  final token = jsOr(
    jsOr(input["token"], endpointCookie(context, input, "token")),
    "",
  );
  final resource = (jsString((jsOr(input["fileids"], ""))).split(jsString(",")))
      .map<Object?>((s) => (<String, Object?>{"fileid": jsNumber(s)}))
      .toList(growable: false);
  final dataMap = <String, Object?>{
    "listid": input["listid"],
    "userid": userid,
    "data": resource,
    "type": 0,
    "token": token,
    "list_ver": 0,
  };
  return context.request(
    KugouRequest(
      path: jsString("/v4/delete_songs"),
      method: jsString("post"),
      data: dataMap,
      headers: stringObjectMap(<String, Object?>{
        "x-router": "cloudlist.service.kugou.com",
      }),
      cookies: stringStringMap(
        jsOr(context.session.cookies, <String, Object?>{}),
      ),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedRankAudio(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final dataMap = <String, Object?>{
    "show_portrait_mv": 1,
    "show_type_total": 1,
    "filter_original_remarks": 1,
    "area_code": 1,
    "pagesize": jsOr(input["pagesize"], 30),
    "rank_cid": jsOr(input["rank_cid"], 0),
    "type": 1,
    "page": jsOr(input["page"], 1),
    "rank_id": input["rankid"],
  };
  return context.request(
    KugouRequest(
      path: jsString("/openapi/kmr/v2/rank/audio"),
      method: jsString("post"),
      data: dataMap,
      headers: stringObjectMap(<String, Object?>{"kg-tid": "369"}),
      cookies: stringStringMap(
        jsOr(context.session.cookies, <String, Object?>{}),
      ),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedRankInfo(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final parmasMap = <String, Object?>{
    "rank_cid": jsOr(input["rank_cid"], 0),
    "rankid": input["rankid"],
    "with_album_img": jsOr(input["album_img"], 1),
    "zone": jsOr(input["zone"], ""),
  };
  return context.request(
    KugouRequest(
      path: jsString("/ocean/v6/rank/info"),
      method: jsString("get"),
      parameters: stringObjectMap(parmasMap),
      cookies: stringStringMap(
        jsOr(context.session.cookies, <String, Object?>{}),
      ),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedRankList(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final parmasMap = <String, Object?>{
    "plat": 2,
    "withsong": jsOr(input["withsong"], 1),
    "parentid": 0,
  };
  return context.request(
    KugouRequest(
      path: jsString("/ocean/v6/rank/list"),
      method: jsString("get"),
      parameters: stringObjectMap(parmasMap),
      cookies: stringStringMap(
        jsOr(context.session.cookies, <String, Object?>{}),
      ),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedRankTop(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  return context.request(
    KugouRequest(
      path: jsString("/mobileservice/api/v5/rank/rec_rank_list"),
      method: jsString("get"),
      cookies: stringStringMap(
        jsOr(context.session.cookies, <String, Object?>{}),
      ),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedRankVol(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final parmasMap = <String, Object?>{
    "rank_cid": jsOr(input["rank_cid"], 0),
    "rankid": input["rankid"],
    "ranktype": 1,
    "type": 0,
    "plat": 2,
  };
  return context.request(
    KugouRequest(
      path: jsString("/ocean/v6/rank/vol"),
      method: jsString("get"),
      parameters: stringObjectMap(parmasMap),
      cookies: stringStringMap(
        jsOr(context.session.cookies, <String, Object?>{}),
      ),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedRecommendSongs(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final dataMap = <String, Object?>{
    "platform": jsOr(input["platform"], "android"),
    "userid": jsOr(
      jsOr(input["userid"], endpointCookie(context, input, "userid")),
      "0",
    ),
  };
  return context.request(
    KugouRequest(
      path: jsString("/everyday_song_recommend"),
      method: jsString("POST"),
      data: dataMap,
      headers: stringObjectMap(<String, Object?>{
        "x-router": "everydayrec.service.kugou.com",
      }),
      cookies: stringStringMap(
        jsOr(context.session.cookies, <String, Object?>{}),
      ),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedSceneAudioList(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final userid = jsOr(
    jsOr(input["userid"], endpointCookie(context, input, "userid")),
    0,
  );
  final token = jsOr(
    jsOr(input["token"], endpointCookie(context, input, "token")),
    "",
  );
  final dataMap = <String, Object?>{
    "appid": context.config.appId,
    "clientver": context.config.clientVersion,
    "token": token,
    "userid": userid,
  };
  return context.request(
    KugouRequest(
      path: jsString("/scene/v1/scene/audio_list"),
      method: jsString("POST"),
      parameters: stringObjectMap(<String, Object?>{
        "scene_id": input["id"],
        "module_id": input["module_id"],
        "tag": input["tag"],
        "page": jsOr(input["page"], 1),
        "page_size": jsOr(input["pagesize"], 30),
      }),
      data: dataMap,
      cookies: stringStringMap(
        jsOr(context.session.cookies, <String, Object?>{}),
      ),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedSceneCollectionList(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final userid = jsOr(
    jsOr(input["userid"], endpointCookie(context, input, "userid")),
    0,
  );
  final token = jsOr(
    jsOr(input["token"], endpointCookie(context, input, "token")),
    "",
  );
  final dataMap = <String, Object?>{
    "appid": context.config.appId,
    "clientver": context.config.clientVersion,
    "token": token,
    "userid": userid,
    "tag_id": input["tag_id"],
    "page": jsOr(input["page"], 1),
    "page_size": jsOr(input["pagesize"], 30),
    "exposed_data": <Object?>[],
  };
  return context.request(
    KugouRequest(
      path: jsString("/scene/v1/distribution/collection_list"),
      method: jsString("POST"),
      data: dataMap,
      cookies: stringStringMap(
        jsOr(context.session.cookies, <String, Object?>{}),
      ),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedSceneLists(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  return context.request(
    KugouRequest(
      path: jsString("/scene/v1/scene/list"),
      method: jsString("GET"),
      cookies: stringStringMap(
        jsOr(context.session.cookies, <String, Object?>{}),
      ),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedSceneListsV2(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final userid = jsOr(
    jsOr(input["userid"], endpointCookie(context, input, "userid")),
    "0",
  );
  final sortType = <String, Object?>{"rec": 1, "hot": 2, "new": 3};
  return context.request(
    KugouRequest(
      path: jsString("/scene/v1/scene/list_v2"),
      method: jsString("POST"),
      parameters: stringObjectMap(<String, Object?>{
        "scene_id": input["id"],
        "page": jsOr(input["page"], 1),
        "pagesize": jsOr(input["pagesize"], 30),
        "sort_type": jsOr(mapValue(sortType, jsOr(input["sort"], "rec")), 1),
        "kugouid": userid,
      }),
      data: <String, Object?>{"exposure": <Object?>[]},
      cookies: stringStringMap(
        jsOr(context.session.cookies, <String, Object?>{}),
      ),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedSceneModule(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  return context.request(
    KugouRequest(
      path: jsString("/scene/v1/scene/module"),
      method: jsString("POST"),
      parameters: stringObjectMap(<String, Object?>{"scene_id": input["id"]}),
      cookies: stringStringMap(
        jsOr(context.session.cookies, <String, Object?>{}),
      ),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedSceneModuleInfo(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  return context.request(
    KugouRequest(
      path: jsString("/scene/v1/scene/module_info"),
      method: jsString("GET"),
      parameters: stringObjectMap(<String, Object?>{
        "scene_id": input["id"],
        "module_id": input["module_id"],
      }),
      cookies: stringStringMap(
        jsOr(context.session.cookies, <String, Object?>{}),
      ),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedSceneMusic(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  return context.request(
    KugouRequest(
      path: jsString("/genesisapi/v1/scene_music/rec_music"),
      method: jsString("POST"),
      parameters: stringObjectMap(<String, Object?>{
        "scene_id": input["id"],
        "page": jsOr(input["page"], 1),
        "pagesize": jsOr(input["pagesize"], 30),
      }),
      data: <String, Object?>{"exposure": <Object?>[]},
      cookies: stringStringMap(
        jsOr(context.session.cookies, <String, Object?>{}),
      ),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedSceneVideoList(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final userid = jsOr(
    jsOr(input["userid"], endpointCookie(context, input, "userid")),
    0,
  );
  final token = jsOr(
    jsOr(input["token"], endpointCookie(context, input, "token")),
    "",
  );
  final dataMap = <String, Object?>{
    "appid": context.config.appId,
    "clientver": context.config.clientVersion,
    "token": token,
    "userid": userid,
    "tag_id": input["tag_id"],
    "page": jsOr(input["page"], 1),
    "page_size": jsOr(input["pagesize"], 30),
    "exposed_data": <Object?>[],
  };
  return context.request(
    KugouRequest(
      path: jsString("/scene/v1/distribution/video_list"),
      method: jsString("POST"),
      data: dataMap,
      cookies: stringStringMap(
        jsOr(context.session.cookies, <String, Object?>{}),
      ),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedSearchComplex(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final dataMap = <String, Object?>{
    "platform": "AndroidFilter",
    "keyword": input["keywords"],
    "page": jsOr(input["page"], 1),
    "pagesize": jsOr(input["pagesize"], 30),
    "cursor": 0,
  };
  return context.request(
    KugouRequest(
      path: jsString("/v6/search/complex"),
      baseUri: Uri.parse(jsString("https://complexsearch.kugou.com")),
      method: jsString("GET"),
      parameters: stringObjectMap(dataMap),
      cookies: stringStringMap(
        jsOr(context.session.cookies, <String, Object?>{}),
      ),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedSearchDefault(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final userid = jsOr(
    jsOr(input["userid"], endpointCookie(context, input, "userid")),
    0,
  );
  final vip_type = jsOr(
    jsOr(input["vip_type"], endpointCookie(context, input, "vip_type")),
    65530,
  );
  final dataMap = <String, Object?>{
    "plat": 0,
    "userid": jsNumber(userid),
    "tags": "{}",
    "vip_type": vip_type,
    "m_type": 0,
    "own_ads": <String, Object?>{},
    "ability": "3",
    "sources": <Object?>[],
    "bitmap": 2,
    "mode": "normal",
  };
  return context.request(
    KugouRequest(
      path: jsString("/searchnofocus/v1/search_no_focus_word"),
      method: jsString("POST"),
      parameters: stringObjectMap(<String, Object?>{"clientver": 12329}),
      data: dataMap,
      cookies: stringStringMap(
        jsOr(context.session.cookies, <String, Object?>{}),
      ),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedSearchHot(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final dataMap = <String, Object?>{"navid": 1, "plat": 2};
  return context.request(
    KugouRequest(
      path: jsString("/api/v3/search/hot_tab"),
      method: jsString("GET"),
      parameters: stringObjectMap(dataMap),
      headers: stringObjectMap(<String, Object?>{
        "x-router": "msearch.kugou.com",
      }),
      cookies: stringStringMap(
        jsOr(context.session.cookies, <String, Object?>{}),
      ),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedSearchLyric(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final dataMap = <String, Object?>{
    "album_audio_id": jsOr(input["album_audio_id"], 0),
    "appid": context.config.appId,
    "clientver": context.config.clientVersion,
    "duration": jsOr(input["duration"], 0),
    "hash": jsOr(input["hash"], ""),
    "keyword": jsOr(input["keywords"], ""),
    "lrctxt": 1,
    "man": (input["man"] ?? "no"),
  };
  return context.request(
    KugouRequest(
      path: jsString("/v1/search"),
      baseUri: Uri.parse(jsString("https://lyrics.kugou.com")),
      method: jsString("GET"),
      parameters: stringObjectMap(dataMap),
      cookies: stringStringMap(
        jsOr(context.session.cookies, <String, Object?>{}),
      ),
      clearDefaultParameters: jsTruthy(true),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedSearchMixed(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final time = context.nowMilliseconds;
  final isLite = ((context.config.isLite ? "lite" : "") == "lite");
  final dataMap = (jsTruthy(context.config.isLite)
      ? <String, Object?>{
          "keyword": input["keyword"],
          "platform": "AndroidFilter",
          "tag": "em",
          "area_code": jsOr(input["area_code"], 1),
          "iscorrection": (input["iscorrection"] ?? 1),
          "cursor": jsOr(input["cursor"], 0),
          "apiver": 22,
          "osversion": "15",
          "ability": 1,
          "clientver": jsOr(input["clientver"], 201),
          "vip_status": jsOr(
            jsOr(
              input["vip_status"],
              endpointCookie(context, input, "vip_type"),
            ),
            0,
          ),
        }
      : <String, Object?>{
          "ab_tag": 0,
          "ability": 511,
          "albumhide": 0,
          "apiver": 22,
          "area_code": 1,
          "clientver": jsOr(input["clientver"], 20125),
          "cursor": 0,
          "is_gpay": 0,
          "iscorrection": 1,
          "keyword": input["keyword"],
          "nocollect": 0,
          "osversion": 16.5,
          "platform": "IOSFilter",
          "recver": 2,
          "req_ai": 1,
          "requestid":
              jsString(
                md5Hex("bdaa53d04e7475feb9024164a47032f9" + jsString(time)),
              ) +
              "_0",
          "search_ability": 3,
          "sec_aggre": 1,
          "sec_aggre_bitmap": 0,
          "style_type": 3,
          "tag": "em",
        });
  return context.request(
    KugouRequest(
      path: jsString("/v3/search/mixed"),
      method: jsString("GET"),
      parameters: stringObjectMap(dataMap),
      headers: stringObjectMap(<String, Object?>{
        "x-router": "complexsearch.kugou.com",
        "kg-clienttimems": jsString(time),
      }),
      cookies: stringStringMap(
        jsOr(context.session.cookies, <String, Object?>{}),
      ),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedSearchSuggest(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  return context.request(
    KugouRequest(
      path: jsString("/v2/getSearchTip"),
      method: jsString("GET"),
      parameters: stringObjectMap(<String, Object?>{
        "keyword": input["keywords"],
        "AlbumTipCount": jsOr(input["albumTipCount"], 10),
        "CorrectTipCount": jsOr(input["correctTipCount"], 10),
        "MVTipCount": jsOr(input["mvTipCount"], 10),
        "MusicTipCount": jsOr(input["musicTipCount"], 10),
        "radiotip": 1,
      }),
      headers: stringObjectMap(<String, Object?>{
        "x-router": "searchtip.kugou.com",
      }),
      cookies: stringStringMap(
        jsOr(context.session.cookies, <String, Object?>{}),
      ),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedServerNow(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final userid = jsOr(
    jsOr(input["userid"], endpointCookie(context, input, "userid")),
    0,
  );
  final token = jsOr(
    jsOr(input["token"], endpointCookie(context, input, "token")),
    "",
  );
  return context.request(
    KugouRequest(
      path: jsString("/v1/server_now"),
      method: jsString("POST"),
      parameters: stringObjectMap(<String, Object?>{"plat": 3}),
      data: <String, Object?>{"token": token, "userid": userid},
      headers: stringObjectMap(<String, Object?>{
        "x-router": "usercenter.kugou.com",
      }),
      cookies: stringStringMap(
        jsOr(context.session.cookies, <String, Object?>{}),
      ),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedSheetCollection(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final paramsMap = <String, Object?>{
    "srcappid": KugouApiConfig.sourceAppId,
    "position": (input["position"] ?? 2),
  };
  return context.request(
    KugouRequest(
      path: jsString("/miniyueku/v1/opern_square/get_home_module_config"),
      method: jsString("GET"),
      parameters: stringObjectMap(paramsMap),
      cookies: stringStringMap(
        jsOr(context.session.cookies, <String, Object?>{}),
      ),
      signatureType: KugouSignatureType.web,
    ),
  );
}

Future<KugouResponse<Object?>> _generatedSheetDetail(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final paramsMap = <String, Object?>{"opern_id": input["id"]};
  return context.request(
    KugouRequest(
      path: jsString("/opern/v1/detail/info"),
      method: jsString("GET"),
      parameters: stringObjectMap(paramsMap),
      cookies: stringStringMap(
        jsOr(context.session.cookies, <String, Object?>{}),
      ),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedSheetExplore(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  return context.request(
    KugouRequest(
      path: jsString("/opern/v1/home/get_rec_opern"),
      method: jsString("POST"),
      parameters: stringObjectMap(<String, Object?>{
        "pagesize": jsOr(input["pagesize"], 30),
        "page": jsOr(input["page"], 1),
        "opern_level": jsOr(input["level"], 0),
        "instruments": jsOr(input["instruments"], 1),
        "tagid": jsOr(input["tagid"], 0),
      }),
      data: <String, Object?>{"exposure_mixids": ""},
      cookies: stringStringMap(
        jsOr(context.session.cookies, <String, Object?>{}),
      ),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedSheetRank(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  return context.request(
    KugouRequest(
      path: jsString("/opern/v1/home/get_rank_opern"),
      method: jsString("POST"),
      parameters: stringObjectMap(<String, Object?>{
        "pagesize": jsOr(input["pagesize"], 30),
        "page": jsOr(input["page"], 1),
        "opern_level": jsOr(input["level"], 0),
        "instruments": jsOr(input["instruments"], 1),
        "tagid": jsOr(input["tagid"], 0),
      }),
      cookies: stringStringMap(
        jsOr(context.session.cookies, <String, Object?>{}),
      ),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedSheetSong(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final paramsMap = <String, Object?>{
    "mixsongid": input["album_audio_id"],
    "instruments": (input["instruments"] ?? 1),
    "opern_level": (input["level"] ?? 0),
  };
  return context.request(
    KugouRequest(
      path: jsString("/opern/v1/detail/song_info"),
      method: jsString("GET"),
      parameters: stringObjectMap(paramsMap),
      cookies: stringStringMap(
        jsOr(context.session.cookies, <String, Object?>{}),
      ),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedSheetTags(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  return context.request(
    KugouRequest(
      path: jsString("/opern/v1/home/get_tags"),
      method: jsString("GET"),
      cookies: stringStringMap(
        jsOr(context.session.cookies, <String, Object?>{}),
      ),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedSingerList(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  return context.request(
    KugouRequest(
      path: jsString("/ocean/v6/singer/list"),
      method: jsString("GET"),
      parameters: stringObjectMap(<String, Object?>{
        "hotsize": (input["hotsize"] ?? 200),
        "musician": 0,
        "sextype": (input["sextype"] ?? 0),
        "showtype": 2,
        "type": (input["type"] ?? 0),
      }),
      cookies: stringStringMap(
        jsOr(context.session.cookies, <String, Object?>{}),
      ),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedSongAuth(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final authorization = jsOr(
    jsOr(input["auth"], endpointCookie(context, input, "auth")),
    "",
  );
  final dataMap = <String, Object?>{
    "authorization": authorization,
    "module_id": 51,
    "album_audio_id": jsNumber((input["album_audio_id"] ?? 0)),
    "clientver": 11561,
    "hash": jsString((jsOr(input["hash"], ""))).toLowerCase(),
  };
  return context.request(
    KugouRequest(
      path: jsString("/v1/authorization"),
      baseUri: Uri.parse(jsString("http://gateway.kugou.com/")),
      method: jsString("GET"),
      parameters: stringObjectMap(dataMap),
      headers: stringObjectMap(<String, Object?>{
        "x-router": "trackercdngz.kugou.com",
      }),
      cookies: stringStringMap(<String, Object?>{
        ...stringObjectMap(<String, Object?>{}),
        ...stringObjectMap(context.session.cookies),
      }),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedSongClimax(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final data = (jsString((jsOr(input["hash"], ""))).split(jsString(",")))
      .map<Object?>((s) => (<String, Object?>{"hash": s}))
      .toList(growable: false);
  return context.request(
    KugouRequest(
      path: jsString("/v1/audio_climax/audio"),
      baseUri: Uri.parse(jsString("https://expendablekmrcdn.kugou.com")),
      method: jsString("GET"),
      parameters: stringObjectMap(<String, Object?>{
        "data": jsJsonEncode(data),
      }),
      cookies: stringStringMap(
        jsOr(context.session.cookies, <String, Object?>{}),
      ),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedSongRanking(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  return context.request(
    KugouRequest(
      path: jsString("/grow/v1/song_ranking/play_page/ranking_info"),
      method: jsString("GET"),
      parameters: stringObjectMap(<String, Object?>{
        "album_audio_id": input["album_audio_id"],
      }),
      cookies: stringStringMap(
        jsOr(context.session.cookies, <String, Object?>{}),
      ),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedSongRankingFilter(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  return context.request(
    KugouRequest(
      path: jsString("/grow/v1/song_ranking/unlock/v2/ranking_filter"),
      method: jsString("GET"),
      parameters: stringObjectMap(<String, Object?>{
        "album_audio_id": input["album_audio_id"],
        "page": jsOr(input["page"], 1),
        "pagesize": jsOr(input["pagesize"], 30),
      }),
      cookies: stringStringMap(
        jsOr(context.session.cookies, <String, Object?>{}),
      ),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedSongUrlAuth(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final quality =
      (jsTruthy(
        (<Object?>[
          "piano",
          "acappella",
          "subwoofer",
          "ancient",
          "dj",
          "surnay",
        ]).contains(input["quality"]),
      )
      ? "magic_" + jsString(input["quality"])
      : input["quality"]);
  final isLite = ((context.config.isLite ? "lite" : "") == "lite");
  final page_id = (jsTruthy(context.config.isLite) ? 967177915 : 151369488);
  final ppage_id = (jsTruthy(context.config.isLite)
      ? jsOr(input["ppage_id"], "356753938,823673182,967485191")
      : "463467626,350369493,788954147");
  final dataMap = <String, Object?>{
    "album_id": jsNumber((input["album_id"] ?? 0)),
    "area_code": 1,
    "module": "",
    "hash": jsString((jsOr(input["hash"], ""))).toLowerCase(),
    "need_m": 0,
    "ssa_flag": "is_fromtrack",
    "version": 11430,
    "open_time": jsOr(input["open_time"], 0),
    "ptype": 0,
    "need_ogg": 1,
    "page_id": page_id,
    "auth": jsOr(input["auth"], ""),
    "mtype": 0,
    "quality": jsOr(quality, 128),
    "album_audio_id": jsNumber((input["album_audio_id"] ?? 0)),
    "behavior": "play",
    "pid": (jsTruthy(context.config.isLite) ? 411 : 2),
    "module_id": 51,
    "cmd": 26,
    "ppage_id": ppage_id,
    "clientver": 11561,
    "pidversion": 3001,
    "cdnBackup": 1,
  };
  return context.request(
    KugouRequest(
      path: jsString("/tracker/v5/url"),
      method: jsString("GET"),
      parameters: stringObjectMap(dataMap),
      cookies: stringStringMap(<String, Object?>{
        ...stringObjectMap(<String, Object?>{}),
        ...stringObjectMap(<String, Object?>{"dfid": randomString(24)}),
        ...stringObjectMap(context.session.cookies),
      }),
      encryptKey: jsTruthy(true),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedSongUrlNew(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final vip_token = jsOr(
    jsOr(input["vip_token"], endpointCookie(context, input, "vip_token")),
    "",
  );
  final token = jsOr(
    jsOr(input["token"], endpointCookie(context, input, "token")),
    "",
  );
  final clienttime_ms = context.nowMilliseconds;
  final userid = jsNumber(
    jsOr(jsOr(input["userid"], endpointCookie(context, input, "userid")), "0"),
  );
  final dfid = jsOr(
    jsOr(input["dfid"], endpointCookie(context, input, "dfid")),
    randomString(24),
  );
  final vip_type = jsOr(
    jsOr(endpointCookie(context, input, "vip_type"), input["vipType"]),
    0,
  );
  final dataMap = <String, Object?>{
    "area_code": "1",
    "behavior": "play",
    "qualities": <Object?>[
      "128",
      "320",
      "flac",
      "high",
      "multitrack",
      "viper_atmos",
      "viper_tape",
      "viper_clear",
      "super",
    ],
    "resource": <String, Object?>{
      "album_audio_id": input["album_audio_id"],
      "collect_list_id": "3",
      "collect_time": clienttime_ms,
      "hash": input["hash"],
      "id": 0,
      "page_id": 1,
      "type": "audio",
    },
    "token": token,
    "tracker_param": <String, Object?>{
      "all_m": 1,
      "auth": "",
      "is_free_part": (jsTruthy(input["free_part"]) ? 1 : 0),
      "key": md5Hex(
        jsString(input["hash"]) +
            "185672dd44712f60bb1736df5a377e82" +
            jsString(context.config.appId) +
            jsString(endpointCookie(context, input, "KUGOU_API_MID")) +
            jsString(userid),
      ),
      "module_id": 0,
      "need_climax": 1,
      "need_xcdn": 1,
      "open_time": "",
      "pid": "411",
      "pidversion": "3001",
      "priv_vip_type": "6",
      "viptoken": vip_token,
    },
    "userid": jsString(userid),
    "vip": vip_type,
  };
  return context.request(
    KugouRequest(
      path: jsString("/v6/priv_url"),
      baseUri: Uri.parse(jsString("http://gateway.kugou.com")),
      method: jsString("POST"),
      data: dataMap,
      headers: stringObjectMap(<String, Object?>{
        "x-router": "tracker.kugou.com",
      }),
      cookies: stringStringMap(<String, Object?>{
        ...stringObjectMap(<String, Object?>{}),
        ...stringObjectMap(<String, Object?>{"dfid": dfid}),
        ...stringObjectMap(context.session.cookies),
      }),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedThemeMusic(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final dataMap = <String, Object?>{
    "platform": "android",
    "clienttime": jsNumber(
      (jsNumber(context.nowMilliseconds) / jsNumber(1000)),
    ).floor(),
    "show_theme_category_ids": input["ids"],
    "userid": jsOr(
      jsOr(input["userid"], endpointCookie(context, input, "userid")),
      0,
    ),
    "module_id": 508,
  };
  return context.request(
    KugouRequest(
      path: jsString("/everydayrec.service/v1/mul_theme_category_recommend"),
      method: jsString("POST"),
      data: dataMap,
      cookies: stringStringMap(
        jsOr(context.session.cookies, <String, Object?>{}),
      ),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedThemeMusicDetail(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final dataMap = <String, Object?>{
    "platform": "android",
    "clienttime": jsNumber(
      (jsNumber(context.nowMilliseconds) / jsNumber(1000)),
    ).floor(),
    "theme_category_id": input["id"],
    "show_theme_category_id": 0,
    "userid": jsOr(
      jsOr(input["userid"], endpointCookie(context, input, "userid")),
      0,
    ),
    "module_id": 508,
  };
  return context.request(
    KugouRequest(
      path: jsString("/everydayrec.service/v1/theme_category_recommend"),
      method: jsString("POST"),
      data: dataMap,
      cookies: stringStringMap(
        jsOr(context.session.cookies, <String, Object?>{}),
      ),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedThemePlaylist(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final dataMap = <String, Object?>{
    "platform": "android",
    "clientver": context.config.clientVersion,
    "clienttime": context.nowMilliseconds,
    "area_code": 1,
    "module_id": 1,
    "userid": jsOr(
      jsOr(input["userid"], endpointCookie(context, input, "userid")),
      0,
    ),
  };
  return context.request(
    KugouRequest(
      path: jsString("/v2/getthemelist"),
      method: jsString("POST"),
      data: dataMap,
      headers: stringObjectMap(<String, Object?>{
        "x-router": "everydayrec.service.kugou.com",
      }),
      cookies: stringStringMap(
        jsOr(context.session.cookies, <String, Object?>{}),
      ),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedThemePlaylistTrack(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final dataMap = <String, Object?>{
    "platform": "android",
    "clientver": context.config.clientVersion,
    "clienttime": context.nowMilliseconds,
    "area_code": 1,
    "module_id": 1,
    "userid": jsOr(
      jsOr(input["userid"], endpointCookie(context, input, "userid")),
      0,
    ),
    "theme_id": input["theme_id"],
  };
  return context.request(
    KugouRequest(
      path: jsString("/v2/gettheme_songidlist"),
      method: jsString("POST"),
      data: dataMap,
      headers: stringObjectMap(<String, Object?>{
        "x-router": "everydayrec.service.kugou.com",
      }),
      cookies: stringStringMap(
        jsOr(context.session.cookies, <String, Object?>{}),
      ),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedTopAlbum(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final dataMap = <String, Object?>{
    "apiver": KugouApiConfig.apiVersion,
    "token": jsOr(
      jsOr(input["token"], endpointCookie(context, input, "token")),
      "",
    ),
    "page": jsOr(input["page"], 1),
    "pagesize": jsOr(input["pagesize"], 30),
    "withpriv": 1,
  };
  return context.request(
    KugouRequest(
      path: jsString("/musicadservice/v1/mobile_newalbum_sp"),
      method: jsString("POST"),
      data: dataMap,
      cookies: stringStringMap(
        jsOr(context.session.cookies, <String, Object?>{}),
      ),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedTopCard(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final dfid = jsOr(
    jsOr(input["dfid"], endpointCookie(context, input, "dfid")),
    "-",
  );
  final fakem = "60f7ebf1f812edbac3c63a7310001701760f";
  final mid = endpointCookie(context, input, "KUGOU_API_MID");
  final dateTime = context.nowMilliseconds;
  final dataMap = <String, Object?>{
    "appid": context.config.appId,
    "clientver": context.config.clientVersion,
    "platform": "android",
    "clienttime": dateTime,
    "userid": jsOr(
      jsOr(input["userid"], endpointCookie(context, input, "userid")),
      0,
    ),
    "key": context.signatures.parametersKey(dateTime),
    "fakem": fakem,
    "area_code": 1,
    "mid": mid,
    "uuid": "-",
    "client_playlist": <Object?>[],
    "u_info": "a0c35cd40af564444b5584c2754dedec",
  };
  return context.request(
    KugouRequest(
      path: jsString("/singlecardrec.service/v1/single_card_recommend"),
      method: jsString("POST"),
      parameters: stringObjectMap(<String, Object?>{
        "card_id": jsOr(input["card_id"], 1),
        "fakem": fakem,
        "area_code": 1,
        "platform": "ios",
      }),
      data: dataMap,
      cookies: stringStringMap(
        jsOr(context.session.cookies, <String, Object?>{}),
      ),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedTopCardYouth(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final dataMap = <String, Object?>{
    "tagid": (input["tagid"] ?? ""),
    "u_info": "",
    "source_mixsong": "",
  };
  final reqUrl =
      (jsTruthy(
        (jsAnd(
          (jsNumber(input["card_id"]) == 3103),
          (jsTypeOf(input["tagid"]) == "undefined"),
        )),
      )
      ? "tag_card_recommend"
      : "single_card_recommend");
  return context.request(
    KugouRequest(
      path: jsString("youth/v1/song/" + jsString(reqUrl)),
      method: jsString("POST"),
      parameters: stringObjectMap(<String, Object?>{
        "card_id": jsOr(input["card_id"], 3005),
        "area_code": 1,
        "platform": "ios",
        "module_id": 1,
        "ver": "v2",
        "pagesize": (input["pagesize"] ?? 30),
        "module_id": 1,
        "clientver": 12500,
      }),
      data: dataMap,
      cookies: stringStringMap(
        jsOr(context.session.cookies, <String, Object?>{}),
      ),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedTopPlaylist(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final dateTime = jsNumber(
    ((jsNumber(context.nowMilliseconds) / jsNumber(1000))),
  ).toStringAsFixed(jsNumber(0).toInt());
  final specialRecommend = <String, Object?>{
    "withtag": jsOr(input["withtag"], 1),
    "withsong": jsOr(input["withsong"], 1),
    "sort": jsOr(input["sort"], 1),
    "ugc": 1,
    "is_selected": 0,
    "withrecommend": 1,
    "area_code": 1,
    "categoryid": jsOr(input["category_id"], 0),
  };
  final dataMap = <String, Object?>{
    "appid": context.config.appId,
    "mid": endpointCookie(context, input, "KUGOU_API_MID"),
    "clientver": context.config.clientVersion,
    "platform": "android",
    "clienttime": dateTime,
    "userid": jsOr(
      jsOr(input["userid"], endpointCookie(context, input, "userid")),
      0,
    ),
    "module_id": jsOr(input["module_id"], 1),
    "page": jsOr(input["page"], 1),
    "pagesize": jsOr(input["pagesize"], 30),
    "key": context.signatures.parametersKey(jsString(dateTime)),
    "special_recommend": specialRecommend,
    "req_multi": 1,
    "retrun_min": 5,
    "return_special_falg": 1,
  };
  return context.request(
    KugouRequest(
      path: jsString("/v2/special_recommend"),
      method: jsString("POST"),
      data: dataMap,
      headers: stringObjectMap(<String, Object?>{
        "x-router": "specialrec.service.kugou.com",
      }),
      cookies: stringStringMap(
        jsOr(context.session.cookies, <String, Object?>{}),
      ),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedTopSong(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final dataMap = <String, Object?>{
    "rank_id": jsOr(input["type"], 21608),
    "userid": jsOr(
      jsOr(input["userid"], endpointCookie(context, input, "userid")),
      0,
    ),
    "page": jsOr(input["page"], 1),
    "pagesize": jsOr(input["pagesize"], 30),
    "tags": <Object?>[],
  };
  return context.request(
    KugouRequest(
      path: jsString("/musicadservice/container/v1/newsong_publish"),
      method: jsString("POST"),
      data: dataMap,
      cookies: stringStringMap(
        jsOr(context.session.cookies, <String, Object?>{}),
      ),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedUserCloudUrl(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final hash = jsString(jsString(input["hash"])).toLowerCase();
  final paramsMap = <String, Object?>{
    "hash": hash,
    "ssa_flag": "is_fromtrack",
    "version": "20102",
    "ssl": 0,
    "album_audio_id": (input["album_audio_id"] ?? 0),
    "pid": 20026,
    "audio_id": (input["audio_id"] ?? 0),
    "kv_id": 2,
    "key": context.signatures.cloudKey(hash, 20026),
    "bucket": "musicclound",
    "name": (input["name"] ?? ""),
    "with_res_tag": 0,
  };
  return context.request(
    KugouRequest(
      path: jsString("/bsstrackercdngz/v2/query_musicclound_url"),
      method: jsString("get"),
      parameters: stringObjectMap(paramsMap),
      cookies: stringStringMap(context.session.cookies),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedUserDetail(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final token = jsOr(
    jsOr(input["token"], endpointCookie(context, input, "token")),
    "",
  );
  final userid = jsNumber(
    jsOr(jsOr(input["userid"], endpointCookie(context, input, "userid")), "0"),
  );
  final clienttime_ms = jsNumber(
    (jsNumber(context.nowMilliseconds) / jsNumber(1000)),
  ).floor();
  final pk = jsString(
    context.crypto.rsaRawEncrypt(<String, Object?>{
      "token": token,
      "clienttime": clienttime_ms,
    }),
  ).toUpperCase();
  final dataMap = <String, Object?>{
    "visit_time": clienttime_ms,
    "usertype": 1,
    "p": pk,
    "userid": userid,
  };
  return context.request(
    KugouRequest(
      path: jsString("/v3/get_my_info"),
      method: jsString("POST"),
      parameters: stringObjectMap(<String, Object?>{"plat": 1}),
      data: dataMap,
      headers: stringObjectMap(<String, Object?>{
        "x-router": "usercenter.kugou.com",
      }),
      cookies: stringStringMap(
        jsOr(context.session.cookies, <String, Object?>{}),
      ),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedUserFans(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final isLite = ((context.config.isLite ? "lite" : "") == "lite");
  final appidUsed = (jsTruthy(context.config.isLite)
      ? 3116
      : context.config.appId);
  final clientverUsed = (jsTruthy(context.config.isLite)
      ? 11440
      : context.config.clientVersion);
  final token = jsOr(
    jsOr(input["token"], endpointCookie(context, input, "token")),
    "",
  );
  final userid = jsNumber(
    jsOr(jsOr(input["userid"], endpointCookie(context, input, "userid")), 0),
  );
  final mid = jsString(
    jsOr(
      jsOr(input["mid"], endpointCookie(context, input, "KUGOU_API_MID")),
      "",
    ),
  );
  final dfid = jsOr(
    jsOr(input["dfid"], endpointCookie(context, input, "dfid")),
    "-",
  );
  final clienttime = jsNumber(
    (jsNumber(context.nowMilliseconds) / jsNumber(1000)),
  ).floor();
  final data = <String, Object?>{
    "userid": userid,
    "dfid": dfid,
    "plat": 1,
    "nickimg": 1,
    "appid": appidUsed,
    "clientver": clientverUsed,
    "mid": mid,
    "clienttime": clienttime,
    "key": context.signatures.parametersKey(
      jsString(clienttime),
      appidUsed,
      clientverUsed,
    ),
    "p": jsString(
      context.crypto.rsaRawEncrypt(<String, Object?>{
        "clienttime": clienttime,
        "token": token,
      }),
    ).toUpperCase(),
  };
  return context.request(
    KugouRequest(
      path: jsString("/v2/fans_list"),
      baseUri: Uri.parse(jsString("https://relationuser.kugou.com")),
      method: jsString("POST"),
      parameters: stringObjectMap(<String, Object?>{"dfid": dfid}),
      data: data,
      cookies: stringStringMap(
        jsOr(context.session.cookies, <String, Object?>{}),
      ),
      clearDefaultParameters: jsTruthy(true),
      skipSignature: jsTruthy(true),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedUserFollow(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final token = jsOr(
    jsOr(input["token"], endpointCookie(context, input, "token")),
    "",
  );
  final userid = jsOr(
    jsOr(input["userid"], endpointCookie(context, input, "userid")),
    "0",
  );
  final dateTime = jsNumber(
    (jsNumber(context.nowMilliseconds) / jsNumber(1000)),
  ).floor();
  final dataMap = <String, Object?>{
    "merge": 2,
    "need_iden_type": 1,
    "ext_params": "k_pic,jumptype,singerid,score",
    "userid": userid,
    "type": 0,
    "id_type": 0,
    "p": jsString(
      context.crypto.rsaRawEncrypt(<String, Object?>{
        "clienttime": dateTime,
        "token": token,
      }),
    ).toUpperCase(),
  };
  return context.request(
    KugouRequest(
      path: jsString("/v4/follow_list"),
      method: jsString("POST"),
      parameters: stringObjectMap(<String, Object?>{"plat": 1}),
      data: dataMap,
      headers: stringObjectMap(<String, Object?>{
        "x-router": "relationuser.kugou.com",
      }),
      cookies: stringStringMap(
        jsOr(context.session.cookies, <String, Object?>{}),
      ),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedUserFriends(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final isLite = ((context.config.isLite ? "lite" : "") == "lite");
  final appidUsed = (jsTruthy(context.config.isLite)
      ? 3116
      : context.config.appId);
  final clientverUsed = (jsTruthy(context.config.isLite)
      ? 11440
      : context.config.clientVersion);
  final token = jsOr(
    jsOr(input["token"], endpointCookie(context, input, "token")),
    "",
  );
  final userid = jsNumber(
    jsOr(jsOr(input["userid"], endpointCookie(context, input, "userid")), 0),
  );
  final mid = jsString(
    jsOr(
      jsOr(input["mid"], endpointCookie(context, input, "KUGOU_API_MID")),
      "",
    ),
  );
  final dfid = jsOr(
    jsOr(input["dfid"], endpointCookie(context, input, "dfid")),
    "-",
  );
  final clienttime = jsNumber(
    (jsNumber(context.nowMilliseconds) / jsNumber(1000)),
  ).floor();
  final data = <String, Object?>{
    "userid": userid,
    "dfid": dfid,
    "plat": 1,
    "nickimg": 1,
    "appid": appidUsed,
    "clientver": clientverUsed,
    "mid": mid,
    "clienttime": clienttime,
    "key": context.signatures.parametersKey(
      jsString(clienttime),
      appidUsed,
      clientverUsed,
    ),
    "p": jsString(
      context.crypto.rsaRawEncrypt(<String, Object?>{
        "clienttime": clienttime,
        "token": token,
      }),
    ).toUpperCase(),
  };
  return context.request(
    KugouRequest(
      path: jsString("/v1/friends_list"),
      baseUri: Uri.parse(jsString("https://relationuser.kugou.com")),
      method: jsString("POST"),
      parameters: stringObjectMap(<String, Object?>{"dfid": dfid}),
      data: data,
      cookies: stringStringMap(
        jsOr(context.session.cookies, <String, Object?>{}),
      ),
      clearDefaultParameters: jsTruthy(true),
      skipSignature: jsTruthy(true),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedUserHistory(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final userid = jsOr(
    jsOr(input["userid"], endpointCookie(context, input, "userid")),
    0,
  );
  final token = jsOr(
    jsOr(input["token"], endpointCookie(context, input, "token")),
    "",
  );
  final dataMap = <String, Object?>{
    "token": token,
    "userid": userid,
    "source_classify": "app",
    "to_subdivide_sr": 1,
  };
  if (jsTruthy((input["bp"]))) {
    dataMap[jsString("bp")] = input["bp"];
  }
  return context.request(
    KugouRequest(
      path: jsString("/playhistory/v1/get_songs"),
      method: jsString("POST"),
      data: dataMap,
      cookies: stringStringMap(
        jsOr(context.session.cookies, <String, Object?>{}),
      ),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedUserInfo(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final token = jsOr(
    jsOr(input["token"], endpointCookie(context, input, "token")),
    "",
  );
  final userid = jsNumber(
    jsOr(jsOr(input["userid"], endpointCookie(context, input, "userid")), "0"),
  );
  final clienttime = context.nowMilliseconds;
  final mid = jsOr(
    jsOr(
      jsOr(input["mid"], endpointCookie(context, input, "mid")),
      endpointCookie(context, input, "KUGOU_API_MID"),
    ),
    "",
  );
  final p = jsString(
    context.crypto.rsaRawEncrypt(<String, Object?>{
      "clienttime": clienttime,
      "token": token,
    }),
  ).toUpperCase();
  final dataMap = <String, Object?>{
    "p": p,
    "appid": context.config.appId,
    "mid": mid,
    "clientver": context.config.clientVersion,
    "source": 0,
    "clienttime": clienttime,
    "uuid": "-",
    "userid": userid,
    "key": context.signatures.parametersKey(clienttime),
  };
  return context.request(
    KugouRequest(
      path: jsString("/v1/get_my_userinfo"),
      baseUri: Uri.parse(jsString("http://relation.user.kugou.com")),
      method: jsString("POST"),
      data: dataMap,
      headers: stringObjectMap(<String, Object?>{
        "Host": "relation.user.kugou.com",
      }),
      cookies: stringStringMap(
        jsOr(context.session.cookies, <String, Object?>{}),
      ),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedUserListen(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final token = jsOr(
    jsOr(input["token"], endpointCookie(context, input, "token")),
    "",
  );
  final userid = jsOr(
    jsOr(input["userid"], endpointCookie(context, input, "userid")),
    "0",
  );
  final clienttime = jsNumber(
    (jsNumber(context.nowMilliseconds) / jsNumber(1000)),
  ).floor();
  final p = jsString(
    context.crypto.rsaRawEncrypt(<String, Object?>{
      "clienttime": clienttime,
      "token": token,
    }),
  ).toUpperCase();
  final dataMap = <String, Object?>{
    "t_userid": userid,
    "userid": userid,
    "list_type": jsOr(input["type"], 0),
    "area_code": 1,
    "cover": 2,
    "p": p,
  };
  return context.request(
    KugouRequest(
      path: jsString("/v2/get_list"),
      baseUri: Uri.parse(jsString("https://listenservice.kugou.com")),
      method: jsString("POST"),
      parameters: stringObjectMap(<String, Object?>{
        "clienttime": clienttime,
        "plat": 0,
      }),
      data: dataMap,
      cookies: stringStringMap(
        jsOr(context.session.cookies, <String, Object?>{}),
      ),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedUserPlaylist(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final userid = jsOr(
    jsOr(endpointCookie(context, input, "userid"), input["userid"]),
    0,
  );
  final token = jsOr(
    jsOr(endpointCookie(context, input, "token"), input["token"]),
    "",
  );
  final dataMap = <String, Object?>{
    "userid": userid,
    "token": token,
    "total_ver": 979,
    "type": 2,
    "page": jsOr(input["page"], 1),
    "pagesize": jsOr(input["pagesize"], 30),
  };
  return context.request(
    KugouRequest(
      path: jsString("/v7/get_all_list"),
      method: jsString("post"),
      parameters: stringObjectMap(<String, Object?>{
        "plat": 1,
        "userid": jsNumber(userid),
        "token": token,
      }),
      data: dataMap,
      headers: stringObjectMap(<String, Object?>{
        "x-router": "cloudlist.service.kugou.com",
      }),
      cookies: stringStringMap(context.session.cookies),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedUserPurchasedAlbums(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final dataMap = <String, Object?>{
    "appid": context.config.appId,
    "userid": jsOr(jsNumber(endpointCookie(context, input, "userid")), 0),
    "token": jsOr(endpointCookie(context, input, "token"), ""),
    "page": jsOr(jsNumber(input["page"]), 1),
    "pagesize": jsOr(jsNumber(input["pagesize"]), 15),
    "clientver": jsString(context.config.clientVersion),
    "deleted": 0,
  };
  return context.request(
    KugouRequest(
      path: jsString("/openapi/v1/copyright/get_album_goods"),
      method: jsString("POST"),
      data: dataMap,
      cookies: stringStringMap(
        jsOr(context.session.cookies, <String, Object?>{}),
      ),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedUserPurchasedSongs(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final dataMap = <String, Object?>{
    "appid": context.config.appId,
    "userid": jsOr(jsNumber(endpointCookie(context, input, "userid")), 0),
    "token": jsOr(endpointCookie(context, input, "token"), ""),
    "page": jsOr(jsNumber(input["page"]), 1),
    "pagesize": jsOr(jsNumber(input["pagesize"]), 50),
    "clientver": jsString(context.config.clientVersion),
    "deleted": 0,
    "need_audio_info": 1,
    "area_code": "1",
  };
  return context.request(
    KugouRequest(
      path: jsString("/openapi/copyright/v1/audio/get_goods"),
      method: jsString("POST"),
      data: dataMap,
      cookies: stringStringMap(
        jsOr(context.session.cookies, <String, Object?>{}),
      ),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedUserVideoCollect(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final token = jsOr(
    jsOr(input["token"], endpointCookie(context, input, "token")),
    "",
  );
  final userid = jsOr(
    jsOr(input["userid"], endpointCookie(context, input, "userid")),
    "0",
  );
  final dataMap = <String, Object?>{
    "userid": userid,
    "token": token,
    "page": (input["page"] ?? 1),
    "pagesize": (input["pagesize"] ?? 30),
  };
  return context.request(
    KugouRequest(
      path: jsString("/collectservice/v2/collect_list_mixvideo"),
      method: jsString("POST"),
      parameters: stringObjectMap(<String, Object?>{"plat": 1}),
      data: dataMap,
      cookies: stringStringMap(
        jsOr(context.session.cookies, <String, Object?>{}),
      ),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedUserVideoLove(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final userid = jsOr(
    jsOr(input["userid"], endpointCookie(context, input, "userid")),
    "0",
  );
  final paramsMap = <String, Object?>{
    "kugouid": userid,
    "pagesize": (input["pagesize"] ?? 30),
    "load_video_info": 1,
    "p": 1,
    "plat": 1,
  };
  return context.request(
    KugouRequest(
      path: jsString("/m.comment.service/v1/get_user_like_video"),
      method: jsString("get"),
      parameters: stringObjectMap(paramsMap),
      cookies: stringStringMap(
        jsOr(context.session.cookies, <String, Object?>{}),
      ),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedUserVipDetail(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  return context.request(
    KugouRequest(
      path: jsString("/v1/get_union_vip"),
      baseUri: Uri.parse(jsString("https://kugouvip.kugou.com")),
      method: jsString("GET"),
      parameters: stringObjectMap(<String, Object?>{"busi_type": "concept"}),
      cookies: stringStringMap(
        jsOr(context.session.cookies, <String, Object?>{}),
      ),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedVerifyUserInfo(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final clienttime = context.nowMilliseconds;
  final v_type = jsNumber(jsOr(input["v_type"], 23));
  final userid = jsNumber(
    jsOr(jsOr(input["userid"], endpointCookie(context, input, "userid")), "0"),
  );
  var dataMap = <String, Object?>{
    "eventid": input["eventid"],
    "userid": userid,
    "platid": jsOr(input["platid"], 2),
    "v_type": v_type,
    "wasm": 1,
    "i": "",
    "sid": Uri.decodeComponent(jsString(jsOr(input["sid"], ""))),
    "edt": Uri.decodeComponent(jsString(jsOr(input["edt"], ""))),
  };
  if (jsTruthy(((v_type == 23)))) {
    final encrypt = context.crypto.aesEncrypt(<String, Object?>{});
    dataMap = <String, Object?>{
      ...stringObjectMap(dataMap),
      "verifycode": Uri.decodeComponent(
        jsString(jsOr(input["verifycode"], "")),
      ),
      "pk": context.crypto.rsaRawEncrypt(<String, Object?>{
        "key": (encrypt).key,
      }),
      "params": (encrypt).ciphertext,
    };
  }
  if (jsTruthy(((v_type == 32)))) {
    final encrypt = context.crypto.aesEncrypt(<String, Object?>{
      "code": jsOr(input["verifycode"], ""),
    });
    dataMap = <String, Object?>{
      ...stringObjectMap(dataMap),
      "code": Uri.decodeComponent(jsString(jsOr(input["verifycode"], ""))),
      "pk": context.crypto.rsaRawEncrypt(<String, Object?>{
        "key": (encrypt).key,
      }),
      "params": (encrypt).ciphertext,
    };
  }
  return context.request(
    KugouRequest(
      path: jsString("/v4/verify_user_info"),
      baseUri: Uri.parse(jsString("https://verifyservice.kugou.com")),
      method: jsString("POST"),
      parameters: stringObjectMap(<String, Object?>{"clientver": 11510}),
      data: dataMap,
      cookies: stringStringMap(
        jsOr(context.session.cookies, <String, Object?>{}),
      ),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedVideoDetail(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final dfid = jsOr(endpointCookie(context, input, "dfid"), "-");
  final mid = endpointCookie(context, input, "KUGOU_API_MID");
  final uuid = md5Hex(jsString(dfid) + jsString(mid));
  final token = jsOr(
    jsOr(input["token"], endpointCookie(context, input, "token")),
    "",
  );
  final clienttime = jsNumber(
    (jsNumber(context.nowMilliseconds) / jsNumber(1000)),
  ).floor();
  final resource = (jsString((jsOr(input["id"], ""))).split(jsString(",")))
      .map<Object?>((s) => (<String, Object?>{"video_id": s}))
      .toList(growable: false);
  final dataMap = <String, Object?>{
    "appid": context.config.appId,
    "clientver": context.config.clientVersion,
    "clienttime": clienttime,
    "mid": mid,
    "uuid": uuid,
    "dfid": dfid,
    "token": jsOr(token, ""),
    "key": context.signatures.parametersKey(jsString(clienttime)),
    "show_resolution": 1,
    "data": resource,
  };
  return context.request(
    KugouRequest(
      path: jsString("/v1/video"),
      method: jsString("POST"),
      data: dataMap,
      headers: stringObjectMap(<String, Object?>{
        "x-router": "kmr.service.kugou.com",
      }),
      cookies: stringStringMap(
        jsOr(context.session.cookies, <String, Object?>{}),
      ),
      clearDefaultParameters: jsTruthy(true),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedVideoPrivilege(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final dfid = jsOr(endpointCookie(context, input, "dfid"), "-");
  final mid = endpointCookie(context, input, "KUGOU_API_MID");
  final resource = (jsString((jsOr(input["hash"], ""))).split(jsString(",")))
      .map<Object?>((s) => (<String, Object?>{"hash": s, "id": 0, "name": ""}))
      .toList(growable: false);
  final dataMap = <String, Object?>{
    "appid": context.config.appId,
    "area_code": 1,
    "behavior": "play",
    "clientver": context.config.clientVersion,
    "dfid": dfid,
    "mid": mid,
    "resource": resource,
    "token": jsOr(endpointCookie(context, input, "token"), ""),
    "userid": jsOr(endpointCookie(context, input, "userid"), 0),
    "vip": jsOr(endpointCookie(context, input, "vip_type"), 0),
  };
  return context.request(
    KugouRequest(
      path: jsString("/v1/get_video_privilege"),
      method: jsString("POST"),
      data: dataMap,
      headers: stringObjectMap(<String, Object?>{
        "x-router": "media.store.kugou.com",
      }),
      cookies: stringStringMap(
        jsOr(context.session.cookies, <String, Object?>{}),
      ),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedVideoUrl(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final paramsMap = <String, Object?>{
    "backupdomain": 1,
    "cmd": 123,
    "ext": "mp4",
    "ismp3": 0,
    "hash": input["hash"],
    "pid": 1,
    "type": 1,
  };
  return context.request(
    KugouRequest(
      path: jsString("/v2/interface/index"),
      method: jsString("GET"),
      parameters: stringObjectMap(paramsMap),
      headers: stringObjectMap(<String, Object?>{
        "x-router": "trackermv.kugou.com",
      }),
      encryptKey: jsTruthy(true),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedYouthChannelAll(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  return context.request(
    KugouRequest(
      path: jsString("/youth/v2/channel/channel_all_list"),
      method: jsString("get"),
      parameters: stringObjectMap(<String, Object?>{
        "page": jsOr(input["page"], 1),
        "pagesize": jsOr(input["pagesize"], 30),
        "type": 1,
      }),
      cookies: stringStringMap(context.session.cookies),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedYouthChannelAmway(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  return context.request(
    KugouRequest(
      path: jsString("/youth/api/amway/v2/index"),
      method: jsString("get"),
      parameters: stringObjectMap(<String, Object?>{
        "global_collection_id": input["global_collection_id"],
      }),
      cookies: stringStringMap(context.session.cookies),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedYouthChannelDetail(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final data =
      (jsString((jsOr(input["global_collection_id"], ""))).split(jsString(",")))
          .map<Object?>((s) => (<String, Object?>{"global_collection_id": s}))
          .toList(growable: false);
  return context.request(
    KugouRequest(
      path: jsString("/youth/api/channel/v1/channel_list_by_id"),
      method: jsString("post"),
      data: <String, Object?>{"data": data},
      cookies: stringStringMap(context.session.cookies),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedYouthChannelSimilar(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  return context.request(
    KugouRequest(
      path: jsString("/youth/v1/channel/get_friendly_channel"),
      method: jsString("post"),
      parameters: stringObjectMap(<String, Object?>{
        "channel_id": input["channel_id"],
      }),
      data: <String, Object?>{
        "area_code": 1,
        "playlist_ver": 2,
        "vip_type": jsOr(
          jsOr(input["vip_type"], endpointCookie(context, input, "vip_type")),
          0,
        ),
        "platform": "ios",
      },
      cookies: stringStringMap(context.session.cookies),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedYouthChannelSong(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final dataMap = <String, Object?>{
    "global_collection_id": input["global_collection_id"],
    "pagesize": jsOr(input["pagesize"], 30),
    "page": jsOr(input["page"], 1),
    "is_filter": 0,
  };
  return context.request(
    KugouRequest(
      path: jsString("/youth/api/channel/v1/channel_get_song_audit_passed"),
      method: jsString("get"),
      parameters: stringObjectMap(dataMap),
      cookies: stringStringMap(context.session.cookies),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedYouthChannelSongDetail(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final dataMap = <String, Object?>{
    "global_collection_id": input["global_collection_id"],
    "fileid": input["fileid"],
  };
  return context.request(
    KugouRequest(
      path: jsString("/youth/v2/post/get_song_detail"),
      method: jsString("get"),
      parameters: stringObjectMap(dataMap),
      cookies: stringStringMap(context.session.cookies),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedYouthChannelSongList(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final dataMap = <String, Object?>{
    "global_collection_id": input["global_collection_id"],
    "pagesize": jsOr(input["pagesize"], 20),
    "page": jsOr(input["page"], 1),
    "types": 2,
    "is_filter": 0,
    "apiver": 3,
  };
  return context.request(
    KugouRequest(
      path: jsString("/api/channel/v1/channel_get_song_list"),
      baseUri: Uri.parse(jsString("https://youth.kugou.com")),
      method: jsString("GET"),
      parameters: stringObjectMap(dataMap),
      cookies: stringStringMap(context.session.cookies),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedYouthChannelSub(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final t = (jsTruthy((jsNumber(input["t"]) == 0)) ? 0 : 1);
  return context.request(
    KugouRequest(
      path: jsString(
        "/youth/v1/channel" +
            jsString((jsTruthy((t == 0)) ? "_un" : "")) +
            "_subscribe",
      ),
      method: jsString((jsTruthy((t == 0)) ? "delete" : "post")),
      parameters: stringObjectMap(<String, Object?>{
        "global_collection_id": input["global_collection_id"],
        "source": 1,
      }),
      cookies: stringStringMap(context.session.cookies),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedYouthDayVip(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  return context.request(
    KugouRequest(
      path: jsString("/youth/v1/recharge/receive_vip_listen_song"),
      method: jsString("post"),
      parameters: stringObjectMap(<String, Object?>{
        "source_id": 90139,
        "receive_day": input["receive_day"],
      }),
      headers: stringObjectMap(<String, Object?>{
        "content-type": "application/x-www-form-urlencoded",
      }),
      cookies: stringStringMap(context.session.cookies),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedYouthDayVipUpgrade(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final paramsMap = <String, Object?>{
    "kugouid": jsNumber(
      jsOr(jsOr(input["userid"], endpointCookie(context, input, "userid")), 0),
    ),
    "ad_type": 1,
  };
  return context.request(
    KugouRequest(
      path: jsString("/youth/v1/listen_song/upgrade_vip_reward"),
      method: jsString("post"),
      parameters: stringObjectMap(paramsMap),
      cookies: stringStringMap(context.session.cookies),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedYouthDynamic(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  return context.request(
    KugouRequest(
      path: jsString("/youth/v3/user/get_dynamic"),
      method: jsString("get"),
      cookies: stringStringMap(context.session.cookies),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedYouthDynamicRecent(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  return context.request(
    KugouRequest(
      path: jsString("/youth/v3/user/recent_dynamic"),
      method: jsString("get"),
      cookies: stringStringMap(context.session.cookies),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedYouthListenSong(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final dataMap = <String, Object?>{
    "mixsongid": jsOr(input["mixsongid"], 666075191),
  };
  return context.request(
    KugouRequest(
      path: jsString("/youth/v2/report/listen_song"),
      method: jsString("POST"),
      parameters: stringObjectMap(<String, Object?>{"clientver": 10566}),
      data: dataMap,
      headers: stringObjectMap(<String, Object?>{
        "user-agent":
            "Android13-1070-10566-201-0-ReportPlaySongToServerProtocol-wifi",
        "content-type": "application/json; charset=utf-8",
      }),
      cookies: stringStringMap(context.session.cookies),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedYouthMonthVipRecord(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  return context.request(
    KugouRequest(
      path: jsString("/youth/v1/activity/get_month_vip_record"),
      method: jsString("get"),
      parameters: stringObjectMap(<String, Object?>{"latest_limit": 100}),
      cookies: stringStringMap(context.session.cookies),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedYouthUnionVip(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final paramsMap = <String, Object?>{
    "busi_type": "concept",
    "opt_product_types": "dvip,qvip",
    "product_type": "svip",
  };
  return context.request(
    KugouRequest(
      path: jsString("/v1/get_union_vip"),
      baseUri: Uri.parse(jsString("https://kugouvip.kugou.com")),
      method: jsString("get"),
      parameters: stringObjectMap(paramsMap),
      cookies: stringStringMap(context.session.cookies),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedYouthUserSong(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final dataMap = <String, Object?>{
    "filter_video": 0,
    "type": jsOr(input["type"], 0),
    "userid": input["userid"],
    "pagesize": jsOr(input["pagesize"], 30),
    "page": jsOr(input["page"], 1),
    "is_filter": 0,
  };
  return context.request(
    KugouRequest(
      path: jsString("/youth/v1/get_user_song_public"),
      method: jsString("get"),
      parameters: stringObjectMap(dataMap),
      cookies: stringStringMap(context.session.cookies),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedYouthVip(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final time = context.nowMilliseconds;
  final dataMap = <String, Object?>{
    "ad_id": 12307537187,
    "play_end": time,
    "play_start": (jsNumber(time) - jsNumber(30000)),
  };
  return context.request(
    KugouRequest(
      path: jsString("/youth/v1/ad/play_report"),
      method: jsString("post"),
      data: dataMap,
      cookies: stringStringMap(context.session.cookies),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedYueku(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  return context.request(
    KugouRequest(
      path: jsString("/v1/yueku/recommend_v2"),
      method: jsString("GET"),
      parameters: stringObjectMap(<String, Object?>{
        "operator": 7,
        "plat": 0,
        "type": 11,
        "area_code": 1,
        "req_multi": 1,
      }),
      headers: stringObjectMap(<String, Object?>{
        "x-router": "service.mobile.kugou.com",
      }),
      cookies: stringStringMap(
        jsOr(context.session.cookies, <String, Object?>{}),
      ),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedYuekuBanner(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  final dataMap = <String, Object?>{
    "plat": 0,
    "channel": 201,
    "operator": 7,
    "networktype": 2,
    "userid": jsOr(
      jsOr(input["userid"], endpointCookie(context, input, "userid")),
      0,
    ),
    "vip_type": 0,
    "m_type": 0,
    "tags": <Object?>[],
    "apiver": 5,
    "ability": 2,
    "mode": "normal",
  };
  return context.request(
    KugouRequest(
      path: jsString("/ads.gateway/v3/listen_banner"),
      method: jsString("POST"),
      data: dataMap,
      cookies: stringStringMap(
        jsOr(context.session.cookies, <String, Object?>{}),
      ),
    ),
  );
}

Future<KugouResponse<Object?>> _generatedYuekuFm(
  KugouEndpointContext context,
  Map<String, Object?> input,
) async {
  return context.request(
    KugouRequest(
      path: jsString("/v1/time_fm_info"),
      method: jsString("GET"),
      parameters: stringObjectMap(<String, Object?>{
        "operator": 7,
        "plat": 0,
        "type": 11,
        "area_code": 1,
        "req_multi": 1,
      }),
      headers: stringObjectMap(<String, Object?>{
        "x-router": "fm.service.kugou.com",
      }),
      cookies: stringStringMap(
        jsOr(context.session.cookies, <String, Object?>{}),
      ),
    ),
  );
}
