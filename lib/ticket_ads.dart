import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

const _testAds = bool.fromEnvironment('DOKOSHADO_TEST_ADS');
const _liveAds = bool.fromEnvironment('DOKOSHADO_LIVE_ADS');

bool get adsEnabled =>
    (_testAds || _liveAds) &&
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

enum TicketAdPlacement {
  home(
    'ca-app-pub-2142000020431433/1593242017',
    'ca-app-pub-2142000020431433/3943219550',
  ),
  history(
    'ca-app-pub-2142000020431433/7848318314',
    'ca-app-pub-2142000020431433/5310086209',
  ),
  completion(
    'ca-app-pub-2142000020431433/8254853288',
    'ca-app-pub-2142000020431433/4380322923',
  );

  const TicketAdPlacement(this.liveUnitId, this.iosLiveUnitId);
  final String liveUnitId;
  final String iosLiveUnitId;

  String get unitId => adUnitFor(defaultTargetPlatform, test: _testAds);

  String adUnitFor(TargetPlatform platform, {bool test = false}) => test
      ? (platform == TargetPlatform.iOS
            ? 'ca-app-pub-3940256099942544/2934735716'
            : 'ca-app-pub-3940256099942544/6300978111')
      : platform == TargetPlatform.iOS
      ? iosLiveUnitId
      : liveUnitId;
}

String rewardedTicketUnitFor(TargetPlatform platform, {bool test = false}) =>
    test
    ? (platform == TargetPlatform.iOS
          ? 'ca-app-pub-3940256099942544/1712485313'
          : 'ca-app-pub-3940256099942544/5224354917')
    : platform == TargetPlatform.iOS
    ? 'ca-app-pub-2142000020431433/5122558959'
    : 'ca-app-pub-2142000020431433/1723949004';

Future<InitializationStatus>? _initialization;
Future<void>? _consentUpdate;
Future<void>? _trackingRequest;
final _privacyRevision = ValueNotifier(0);

Future<void> _updateConsent() {
  final done = Completer<void>();
  void finish() {
    if (!done.isCompleted) done.complete();
  }

  ConsentInformation.instance.requestConsentInfoUpdate(
    ConsentRequestParameters(),
    () {
      unawaited(
        ConsentForm.loadAndShowConsentFormIfRequired((_) => finish())
            .catchError((Object _) => finish()),
      );
    },
    (_) => finish(),
  );
  return done.future.timeout(const Duration(seconds: 15), onTimeout: finish);
}

Future<bool> _prepareAds() async {
  if (!adsEnabled) return false;
  if (_liveAds && !_testAds) {
    await (_consentUpdate ??= _updateConsent());
    if (!await ConsentInformation.instance.canRequestAds()) return false;
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      try {
        await (_trackingRequest ??= const MethodChannel(
          'biz.wisemap.dokoshado/privacy',
        ).invokeMethod<void>('requestTracking'));
      } catch (_) {
        // Tracking permission is optional. The SDK respects the OS status.
      }
    }
  }
  await (_initialization ??= MobileAds.instance.initialize());
  return true;
}

Future<bool>? _privacyOptionsRequired;
Future<bool> _checkPrivacyOptions() async {
  try {
    await (_consentUpdate ??= _updateConsent());
    final status = await ConsentInformation.instance
        .getPrivacyOptionsRequirementStatus();
    return status == PrivacyOptionsRequirementStatus.required;
  } catch (_) {
    return false;
  }
}

class AdPrivacyOptions extends StatelessWidget {
  const AdPrivacyOptions({super.key});

  @override
  Widget build(BuildContext context) {
    if (!adsEnabled || !_liveAds || _testAds) return const SizedBox.shrink();
    return FutureBuilder<bool>(
      future: _privacyOptionsRequired ??= _checkPrivacyOptions(),
      builder: (context, snapshot) {
        if (snapshot.data != true) return const SizedBox.shrink();
        return TextButton(
          onPressed: () => ConsentForm.showPrivacyOptionsForm((error) {
            if (error == null) {
              _privacyRevision.value++;
            } else if (context.mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('広告の設定を開けませんでした。')));
            }
          }),
          child: const Text('広告のプライバシー設定'),
        );
      },
    );
  }
}

enum RewardedTicketResult { earned, closed, unavailable }

Future<RewardedTicketResult> showTicketAd() async {
  final result = Completer<RewardedTicketResult>();
  void finish(RewardedTicketResult value) {
    if (!result.isCompleted) result.complete(value);
  }

  try {
    if (!await _prepareAds()) return RewardedTicketResult.unavailable;
    await RewardedAd.load(
      adUnitId: rewardedTicketUnitFor(defaultTargetPlatform, test: _testAds),
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdFailedToLoad: (_) => finish(RewardedTicketResult.unavailable),
        onAdLoaded: (ad) {
          var earned = false;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              unawaited(ad.dispose());
              finish(
                earned
                    ? RewardedTicketResult.earned
                    : RewardedTicketResult.closed,
              );
            },
            onAdFailedToShowFullScreenContent: (ad, _) {
              unawaited(ad.dispose());
              finish(RewardedTicketResult.unavailable);
            },
          );
          unawaited(
            ad.show(onUserEarnedReward: (_, _) => earned = true).catchError((
              Object _,
            ) {
              unawaited(ad.dispose());
              finish(RewardedTicketResult.unavailable);
            }),
          );
        },
      ),
    );
  } catch (_) {
    finish(RewardedTicketResult.unavailable);
  }
  return result.future;
}

class TicketBanner extends StatelessWidget {
  const TicketBanner(this.placement, {super.key});

  final TicketAdPlacement placement;

  @override
  Widget build(BuildContext context) {
    if (!adsEnabled) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < AdSize.banner.width)
          return const SizedBox.shrink();
        return ValueListenableBuilder<int>(
          valueListenable: _privacyRevision,
          builder: (context, revision, child) => _BannerSlot(
            key: ValueKey((placement, revision)),
            unitId: placement.unitId,
          ),
        );
      },
    );
  }
}

class _BannerSlot extends StatefulWidget {
  const _BannerSlot({super.key, required this.unitId});

  final String unitId;

  @override
  State<_BannerSlot> createState() => _BannerSlotState();
}

class _BannerSlotState extends State<_BannerSlot> {
  BannerAd? ad;
  bool loaded = false;

  @override
  void initState() {
    super.initState();
    unawaited(load());
  }

  Future<void> load() async {
    try {
      if (!await _prepareAds() || !mounted) return;
      final banner = BannerAd(
        adUnitId: widget.unitId,
        size: AdSize.banner,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (_) {
            if (mounted) setState(() => loaded = true);
          },
          onAdFailedToLoad: (failed, _) {
            if (ad != failed) return;
            ad = null;
            unawaited(failed.dispose());
          },
        ),
      );
      ad = banner;
      await banner.load();
    } catch (_) {
      final failed = ad;
      ad = null;
      if (failed != null) unawaited(failed.dispose());
    }
  }

  @override
  void dispose() {
    final banner = ad;
    ad = null;
    if (banner != null) unawaited(banner.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final banner = ad;
    if (!loaded || banner == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Center(
        child: SizedBox(
          width: banner.size.width.toDouble(),
          height: banner.size.height.toDouble(),
          child: AdWidget(ad: banner),
        ),
      ),
    );
  }
}
