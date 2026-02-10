import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdsService {
  AdsService._();

  static final AdsService instance = AdsService._();

  BannerAd? _banner;

  Future<void> initialize() async {
    await MobileAds.instance.initialize();
    _loadBanner();
  }

  void _loadBanner() {
    if (!(Platform.isAndroid || Platform.isIOS)) {
      return;
    }

    _banner?.dispose();
    _banner = BannerAd(
      adUnitId: _testBannerId(),
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
    )..load();
  }

  Widget bannerWidget() {
    final banner = _banner;
    if (banner == null) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: banner.size.width.toDouble(),
      height: banner.size.height.toDouble(),
      child: AdWidget(ad: banner),
    );
  }

  String _testBannerId() {
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/6300978111';
    }
    return 'ca-app-pub-3940256099942544/2934735716';
  }
}
