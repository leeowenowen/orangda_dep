import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_photo_share/common/constants/constants.dart';
import 'package:flutter_photo_share/themes/theme.dart';
import 'package:flutter_photo_share/ui/account/login_page.dart';

import 'common/utils/app_util.dart';
import 'common/utils/preferences.dart';
import 'routes/route.dart';
import 'localization/my_l10n_delegate.dart';
import 'models/user.dart';
import 'service/account_service.dart';
import 'ui/home/home_page.dart';

final ref = Firestore.instance.collection(Constants.COLLECTION_USER);

User currentUserModel;

Future<void> main() async {
  WidgetsFlutterBinding
      .ensureInitialized(); // after upgrading flutter this is now necessary
  await Prefs.init();
  await AppUtil.init();
  // enable timestamps in firebase
  Firestore.instance.settings().then((_) {
    print('[Main] Firestore timestamps in snapshots set');
  }, onError: (_) => print('[Main] Error setting timestamps in snapshots'));
  AccountService.init();
  runApp(Orangda());
}

class Orangda extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Orangda',
      initialRoute: LoginPage.ROUTE,
      routes: Routes.getRoute(),
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        MyLocalizationDelegate()
      ],
      supportedLocales: [
        const Locale('en', 'US'),
        const Locale('zh', 'CN'),
      ],
       // theme: AppTheme.theme,
       //  darkTheme: AppTheme.theme,
      // home: HomePage(title: 'Orangda'),
    );
  }
}
