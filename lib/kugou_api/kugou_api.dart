import 'src/config.dart';
import 'src/crypto.dart';
import 'src/endpoint.dart';
import 'src/endpoints/cloud_endpoints.dart';
import 'src/endpoints/core_endpoints.dart';
import 'src/endpoints/generated_endpoints.dart';
import 'src/endpoints/grade_endpoints.dart';
import 'src/endpoints/login_endpoints.dart';
import 'src/endpoints/manual_endpoints.dart';
import 'src/endpoints/misc_endpoints.dart';
import 'src/endpoints/ssa_endpoints.dart';
import 'src/models.dart';
import 'src/request_executor.dart';
import 'src/session.dart';
import 'src/transport.dart';

/// The single application-facing entry point for the embedded KuGou backend.
final class KugouApi {
  KugouApi({
    KugouApiConfig config = const KugouApiConfig(),
    KugouSession? session,
    KugouHttpTransport? transport,
    Map<String, KugouEndpointHandler>? additionalEndpoints,
  }) : config = config,
       session = session ?? KugouSession(variant: config.variant),
       _transport =
           transport ?? DioKugouTransport(timeout: config.requestTimeout) {
    _executor = KugouRequestExecutor(
      config: config,
      session: this.session,
      transport: _transport,
    );
    _context = KugouEndpointContext(
      config: config,
      session: this.session,
      executor: _executor,
      crypto: KugouCrypto(config),
    );
    _endpoints = <String, KugouEndpointHandler>{
      ...createGeneratedEndpointHandlers(),
      ...createCoreEndpointHandlers(),
      ...createManualEndpointHandlers(),
      ...createLoginEndpointHandlers(),
      ...createMiscEndpointHandlers(),
      ...createSsaEndpointHandlers(),
      ...createCloudEndpointHandlers(),
      ...createGradeEndpointHandlers(),
      ...?additionalEndpoints,
    };
  }

  final KugouApiConfig config;
  final KugouSession session;
  final KugouHttpTransport _transport;
  late final KugouRequestExecutor _executor;
  late final KugouEndpointContext _context;
  late final Map<String, KugouEndpointHandler> _endpoints;

  Iterable<String> get routes => _endpoints.keys;

  Future<KugouResponse<Object?>> call(
    String route, {
    Map<String, Object?> parameters = const <String, Object?>{},
  }) {
    final normalized = _normalizeRoute(route);
    final handler = _endpoints[normalized];
    if (handler == null) {
      throw ArgumentError.value(route, 'route', 'Unknown KuGou API endpoint');
    }
    return handler(_context, Map<String, Object?>.from(parameters));
  }

  /// Low-level escape hatch for new endpoints while keeping transport private.
  Future<KugouResponse<Object?>> request(KugouRequest request) =>
      _executor.execute(request);

  void close() => _transport.close();

  String _normalizeRoute(String route) {
    var value = route.trim();
    if (value.endsWith('.js')) value = value.substring(0, value.length - 3);
    if (!value.startsWith('/')) value = '/$value';
    if (_endpoints.containsKey(value)) return value;
    return value.replaceAll('_', '/');
  }
}
