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
import 'resources/agent_ads_resource.dart';
import 'resources/agents_resource.dart';
import 'resources/auth_resource.dart';
import 'resources/contact_resource.dart';
import 'resources/coworkers_resource.dart';
import 'resources/instagram_auth_resource.dart';
import 'resources/leads_resource.dart';
import 'resources/publish_resource.dart';
import 'resources/saved_ads_resource.dart';
import 'resources/statistics_resource.dart';
import 'resources/uploads_resource.dart';
import 'resources/users_resource.dart';
import 'token_storage.dart';
import 'transport.dart';

export 'api_client.dart';
export 'api_exception.dart';
export 'env.dart';
export 'models/ad.dart';
export 'models/ad_stage_counts.dart';
export 'models/ad_write_input.dart';
export 'models/agent.dart';
export 'models/api_error_body.dart';
export 'models/auth_user.dart';
export 'models/connected_account.dart';
export 'models/coworker.dart';
export 'models/enums.dart';
export 'models/lead.dart';
export 'models/lead_write_input.dart';
export 'models/optional_field.dart';
export 'models/publish.dart';
export 'models/saved_ad.dart';
export 'models/statistics.dart';
export 'models/upload.dart';
export 'resources/ads_resource.dart';
export 'resources/agent_ads_resource.dart';
export 'resources/agents_resource.dart';
export 'resources/auth_resource.dart';
export 'resources/contact_resource.dart';
export 'resources/coworkers_resource.dart';
export 'resources/instagram_auth_resource.dart';
export 'resources/leads_resource.dart';
export 'resources/publish_resource.dart';
export 'resources/saved_ads_resource.dart';
export 'resources/statistics_resource.dart';
export 'resources/uploads_resource.dart';
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

  /// The CRM/Work-tab surface (SCREENS.md §21–§38) — see each resource's
  /// own doc comment for the route(s) it wraps.
  final AgentAdsResource agentAds;
  final LeadsResource leads;
  final CoworkersResource coworkers;
  final StatisticsResource statistics;
  final PublishResource publish;
  final UploadsResource uploads;
  final InstagramAuthResource instagramAuth;

  LaCasaApi(this.client)
    : auth = AuthResource(client),
      ads = AdsResource(client),
      savedAds = SavedAdsResource(client),
      agents = AgentsResource(client),
      contact = ContactResource(client),
      users = UsersResource(client),
      agentAds = AgentAdsResource(client),
      leads = LeadsResource(client),
      coworkers = CoworkersResource(client),
      statistics = StatisticsResource(client),
      publish = PublishResource(client),
      uploads = UploadsResource(client),
      instagramAuth = InstagramAuthResource(client);

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
