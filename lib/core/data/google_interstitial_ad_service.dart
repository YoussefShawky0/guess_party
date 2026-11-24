import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:guess_party/core/services/interstitial_ad_service.dart';

class GoogleInterstitialAdService implements InterstitialAdService {
  GoogleInterstitialAdService({
    required String adUnitId,
    AdFrequencyPolicy policy = const AdFrequencyPolicy(),
    DateTime Function() now = DateTime.now,
  }) : _adUnitId = adUnitId,
       _policy = policy,
       _now = now;

  final String _adUnitId;
  final AdFrequencyPolicy _policy;
  final DateTime Function() _now;

  bool _sdkReady = false;
  bool _loading = false;
  InterstitialAd? _ad;
  DateTime? _lastShownAt;
  int _gamesSinceLastAd = 0;

  @override
  Future<void> initialize() async {
    try {
      await _gatherConsent();
      if (!await ConsentInformation.instance.canRequestAds()) return;
      await MobileAds.instance.initialize();
      _sdkReady = true;
      preload();
    } catch (error) {
      debugPrint('Ads disabled for this session: $error');
    }
  }

  Future<void> _gatherConsent() {
    final done = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () => ConsentForm.loadAndShowConsentFormIfRequired((_) {
        if (!done.isCompleted) done.complete();
      }),
      // Offline or misconfigured: canRequestAds() still reflects the
      // consent stored from an earlier session.
      (_) {
        if (!done.isCompleted) done.complete();
      },
    );
    return done.future;
  }

  @override
  void preload() {
    if (!_sdkReady || _loading || _ad != null) return;
    _loading = true;
    InterstitialAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _loading = false;
          _ad = ad;
        },
        onAdFailedToLoad: (error) {
          _loading = false;
          debugPrint('Interstitial failed to load: ${error.message}');
        },
      ),
    );
  }

  @override
  Future<void> showAfterGameIfReady() async {
    _gamesSinceLastAd++;
    final ad = _ad;
    if (ad == null) {
      preload();
      return;
    }
    final allowed = _policy.shouldShow(
      now: _now(),
      lastShownAt: _lastShownAt,
      gamesSinceLastAd: _gamesSinceLastAd,
    );
    if (!allowed) return;

    _ad = null;
    final closed = Completer<void>();
    void finish(InterstitialAd shown) {
      shown.dispose();
      if (!closed.isCompleted) closed.complete();
      preload();
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) {
        _lastShownAt = _now();
        _gamesSinceLastAd = 0;
      },
      onAdDismissedFullScreenContent: finish,
      onAdFailedToShowFullScreenContent: (shown, _) => finish(shown),
    );
    try {
      await ad.show();
    } catch (_) {
      finish(ad);
    }
    return closed.future;
  }
}
