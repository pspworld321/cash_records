import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:cash_records/formPage.dart';
import 'package:cash_records/global.dart';
import 'package:cash_records/settings.dart';
import 'main.dart';

final banner1AdId = 'ca-app-pub-5704045408668888/1570439296';
final banner2AdId = 'ca-app-pub-5704045408668888/2964068557';
const interAdId = 'ca-app-pub-5704045408668888/6137026801';

class AdsUnits {
  static var settings = {};
  static bool admobInit = false;
  static bool interAdLoaded = false;
  static bool gAdClicked = false;

  static late final myBanner1;
  static late final adWidget1;
  static var myBanner2;
  static var adWidget2;
  static var myBanner3;
  static var adWidget3;
  static var interstitialAd;

  static loadInterAd() {
    InterstitialAd.load(
        adUnitId: interAdId,
        request: AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(onAdLoaded: (InterstitialAd ad) {
          // Keep a reference to the ad so you can show it later.
          interstitialAd = ad;
          interstitialAd.fullScreenContentCallback = FullScreenContentCallback(
            onAdShowedFullScreenContent: (InterstitialAd ad) => print('%ad onAdShowedFullScreenContent.'),
            onAdDismissedFullScreenContent: (InterstitialAd ad) {
              print('$ad onAdDismissedFullScreenContent.');
              ad.dispose();
            },
            onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
              print('$ad onAdFailedToShowFullScreenContent: $error');
              ad.dispose();
            },
            onAdImpression: (InterstitialAd ad) => print('$ad impression occurred.'),
          );

          interAdLoaded = true;
        }, onAdFailedToLoad: (LoadAdError error) {
          print('InterstitialAd failed to load: $error');
        }));
  }

  static showInterAd() {
    if (admobInit && !gAdClicked && interAdLoaded) {
      interstitialAd.show();
      loadInterAd();
    }
  }

  static loadAds() async {
    try {
      MobileAds.instance.initialize().then((d) async {
        AdsUnits adUnits = AdsUnits();
        myBanner1 = adUnits.myBannerAd1;
        adWidget1 = AdWidget(ad: myBanner1);
        await myBanner1.load();
        myBanner2 = adUnits.myBannerAd2;
        adWidget2 = AdWidget(ad: myBanner2);
        await myBanner2.load();
        myBanner3 = adUnits.myBannerAd3;
        adWidget3 = AdWidget(ad: myBanner3);
        await myBanner3.load();
        await loadInterAd();
        admobInit = true;
        MyHomePageState.bannerNotifier.value++;
        FormPageState.bannerNotifier.value++;
      });
    } catch (e) {
      admobInit = false;
    }
  }

  static googleBannerAd1() {
    return ValueListenableBuilder(
      valueListenable: MyHomePageState.bannerNotifier,
      builder: (BuildContext context, value, Widget? child) {
        return AdsUnits.admobInit
            ? Container(
                alignment: Alignment.center,
                child: adWidget1,
                width: MediaQuery.of(MyHomePageState.ctx).size.width,
                // height: 70,
                // width: myBanner1.size.width.toDouble(),
                height: myBanner1.size.height.toDouble(),
              )
            : Container(
                width: 0,
                height: 0,
                // width: 300,
              );
      },
    );
  }

  static googleBannerAd2() {
    return ValueListenableBuilder(
      valueListenable: FormPageState.bannerNotifier,
      builder: (BuildContext context, value, Widget? child) {
        return AdsUnits.admobInit
            ? Container(
                alignment: Alignment.center,
                child: adWidget2,
                width: MediaQuery.of(MyHomePageState.ctx).size.width,
                // height: 70,
                // width: myBanner2.size.width.toDouble(),
                height: myBanner2.size.height.toDouble(),
              )
            : Container(
                width: 0,
                height: 0,
                // width: 300,
              );
      },
    );
  }

  static googleBannerAd3() {
    return ValueListenableBuilder(
      valueListenable: DataState.bannerNotifier,
      builder: (BuildContext context, value, Widget? child) {
        return AdsUnits.admobInit
            ? Container(
                alignment: Alignment.center,
                child: adWidget3,
                width: MediaQuery.of(DataState.ctx).size.width,
                // height: 70,
                // width: myBanner2.size.width.toDouble(),
                height: myBanner3.size.height.toDouble(),
              )
            : Container(
                width: 0,
                height: 0,
                // width: 300,
              );
      },
    );
  }

  BannerAd myBannerAd1 = BannerAd(
    adUnitId: banner1AdId,
    size: AdSize.mediumRectangle,
    request: AdRequest(),
    listener: BannerAdListener(
      onAdFailedToLoad: (Ad, err) {
        print('Ad error.' + err.toString());
      },
      onAdOpened: (Ad ad) {
        print('Ad opened.');
        AdsUnits.gAdClicked = true;
        settings['gAdClickedTime'] = DateTime.now();
        // Global.saveSettings();
        print(AdsUnits.gAdClicked);
        MyHomePageState.bannerNotifier.value++;
        FormPageState.bannerNotifier.value++;
      },
    ),
  );

  BannerAd myBannerAd2 = BannerAd(
    adUnitId: banner2AdId,
    size: AdSize.mediumRectangle,
    request: AdRequest(),
    listener: BannerAdListener(
      onAdFailedToLoad: (Ad, err) {
        print('Ad error.' + err.toString());
      },
      onAdOpened: (Ad ad) {
        print('Ad opened.');
        AdsUnits.gAdClicked = true;
        settings['gAdClickedTime'] = DateTime.now();
        // Global.saveSettings();
        print(AdsUnits.gAdClicked);
        FormPageState.bannerNotifier.value++;
      },
    ),
  );

  BannerAd myBannerAd3 = BannerAd(
    adUnitId: banner1AdId,
    size: AdSize.banner,
    request: AdRequest(),
    listener: BannerAdListener(
      onAdFailedToLoad: (Ad, err) {
        print('Ad error.' + err.toString());
      },
      onAdOpened: (Ad ad) {
        print('Ad opened.');
        AdsUnits.gAdClicked = true;
        settings['gAdClickedTime'] = DateTime.now();
        // Global.saveSettings();
        print(AdsUnits.gAdClicked);
        DataState.bannerNotifier.value++;
      },
    ),
  );
}
