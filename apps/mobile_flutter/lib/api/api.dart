/// Barrel + composition root for `lib/api/`. Other layers (Riverpod
/// providers, screens) should generally only need this one import:
///
/// ```dart
/// import 'package:lacasa_mobile/api/api.dart';
///
/// final api = LaCasaApi.create();
/// final ads = await api.ads.list();
/// ```
///
/// [LaCasaApi.create] wires the real, network-backed stack (dio +
/// flutter_secure_storage + [apiBaseUrl]). For tests, construct
/// [LaCasaApi] directly with a fake [Transport]/[TokenStorage] instead —
/// see `test/api/` for the pattern.
library;

import 'api_client.dart';
import 'env.dart';
import 'resources/ads_resource.dart';
import 'resources/agents_resource.dart';
import 'resources/auth_resource.dart';
import 'resources/contact_resource.dart';
import 'resources/saved_ads_resource.dart';
import 'resources/users_resource.dart';
import 'token_storage.dart';
import 'transport.dart';

export 'api_client.dart';
export 'api_exception.dart';
export 'env.dart';
export 'models/ad.dart';
export 'models/agent.dart';
export 'models/api_error_body.dart';
export 'models/auth_user.dart';
export 'models/enums.dart';
export 'models/saved_ad.dart';
export 'resources/ads_resource.dart';
export 'resources/agents_resource.dart';
export 'resources/auth_resource.dart';
export 'resources/contact_resource.dart';
export 'resources/saved_ads_resource.dart';
export 'resources/users_resource.dart';
export 'token_storage.dart';
export 'transport.dart';

class LaCasaApi {
  final ApiClient client;
  final AuthResource auth;
  final AdsResource ads;
  final SavedAdsResource savedAds;
  final AgentsResource agents;
  final ContactResource contact;
  final UsersResource users;

  LaCasaApi(this.client)
    : auth = AuthResource(client),
      ads = AdsResource(client),
      savedAds = SavedAdsResource(client),
      agents = AgentsResource(client),
      contact = ContactResource(client),
      users = UsersResource(client);

  /// Builds the real stack: dio over the network, tokens in the platform
  /// keystore/keychain, base URL from [apiBaseUrl] (or [baseUrl] to
  /// override it, e.g. for a staging build).
  factory LaCasaApi.create({String? baseUrl, TokenStorage? tokenStorage}) {
    return LaCasaApi(
      ApiClient(
        transport: DioTransport(),
        tokenStorage: tokenStorage ?? SecureTokenStorage(),
        baseUrl: baseUrl ?? apiBaseUrl,
      ),
    );
  }
}
