import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:easy_alert/easy_alert.dart';
import 'package:provider/provider.dart';
import './models/oauth_info.dart';
import './models/article.dart';
import './models/loading.dart';
import './models/article_titles.dart';
import './models/settings.dart';

import './pages/waiting.dart';
import './pages/article_titles.dart';
import './pages/article.dart';
import './pages/sign.dart';
import './pages/add_article.dart';
import './pages/guid.dart';
import './pages/article_page_view.dart';

import './themes/dark.dart';
import './themes/bright.dart';
import 'dart:async';

void main() {
  runApp(AlertProvider(
    child: Ebuoy(),
    config: new AlertConfig(ok: "OK", cancel: "CANCEL"),
  ));
  // runApp(MyApp());
}

class Ebuoy extends StatefulWidget {
  @override
  _EbuoyState createState() => _EbuoyState();
}

class _EbuoyState extends State<Ebuoy> {
  StreamSubscription _intentDataStreamSubscription;
  OauthInfo oauthInfo;
  ArticleTitles articleTitles;
  Settings settings;
  @override
  void initState() {
    super.initState();
    oauthInfo = OauthInfo();
    articleTitles = ArticleTitles();
    settings = Settings();
    // 绑定 setting 迸去
    articleTitles.settings = settings;
    //绑定获取列表的函数到oauthInfo里, 为了在登录完成后执行重新获取数据的操作
    oauthInfo.setAccessTokenCallBack = articleTitles.syncArticleTitles;
    initReceiveShare();
  }

  receiveShare(String sharedText) {
    if (sharedText == null) return;
    // 收到分享, 设置
    articleTitles.newYouTube(sharedText);
  }

  void initReceiveShare() {
    // For sharing or opening urls/text coming from outside the app while the app is in the memory
    _intentDataStreamSubscription =
        ReceiveSharingIntent.getTextStream().listen((String value) {
      print("shared to run app");
      receiveShare(value);
    }, onError: (err) {
      print("getLinkStream error: $err");
    });

    // For sharing or opening urls/text coming from outside the app while the app is closed
    ReceiveSharingIntent.getInitialText().then((String value) {
      print("shared to closed app");
      receiveShare(value);
    });
  }

  @override
  void dispose() {
    _intentDataStreamSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => Article()),
          ChangeNotifierProvider(create: (_) => Loading()),
          ChangeNotifierProvider(create: (_) => oauthInfo),
          ChangeNotifierProvider(create: (_) => articleTitles),
          ChangeNotifierProvider(create: (_) => settings),
        ],
        child: Consumer<Settings>(builder: (context, settings, child) {
          return MaterialApp(
            title: 'English Buoy',
            theme: settings.isDark ? darkTheme : brightTheme,
            home: ArticleTitlesPage(),
            onGenerateRoute: getRoute,
          );
        }));
  }

  Route getRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/ArticlePageView':
        //return _buildRoute(settings, ArticlePageViewPage(settings.arguments));
        return PageTransition(
          duration: Duration(milliseconds: 500),
          type: PageTransitionType.rightToLeft,
          child: ArticlePageViewPage(settings.arguments),
          settings: settings,
        );
      case '/Guid':
        //return _buildRoute(settings, GuidPage());
        return PageTransition(
          duration: Duration(milliseconds: 500),
          type: PageTransitionType.rightToLeft,
          child: GuidPage(),
          settings: settings,
        );
      case '/Waiting':
        return _buildRoute(settings, WaitingPage());
      case '/ArticleTitles':
        return _buildRoute(settings, ArticleTitlesPage());
      case '/AddArticle':
        return _buildRoute(settings, AddArticlePage());
      case '/Article':
        // return _buildRoute(settings, ArticlePage(initID: settings.arguments));
        return PageTransition(
          duration: Duration(milliseconds: 500),
          type: PageTransitionType.rightToLeft,
          child: ArticlePage(initID: settings.arguments),
          settings: settings,
        );
      case '/Sign':
        return _buildRoute(settings, SignInPage());
      default:
        return null;
    }
  }

  MaterialPageRoute _buildRoute(RouteSettings settings, Widget builder) {
    return new MaterialPageRoute(
      settings: settings,
      builder: (BuildContext context) => builder,
    );
  }
}
