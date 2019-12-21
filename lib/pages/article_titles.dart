// 文章列表
import 'dart:async';

import 'package:ebuoy/components/article_titles_app_bar.dart';
import 'package:ebuoy/models/search.dart';
import 'package:ebuoy/models/youtube.dart';

import 'package:flutter_widgets/flutter_widgets.dart';

import '../components/article_youtube_avatar.dart';

import '../models/articles.dart';
import '../models/loading.dart';
import 'package:ebuoy/store/article.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/article_titles.dart';
import '../models/article_title.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class ArticleTitlesPage extends StatefulWidget {
  ArticleTitlesPage({Key key}) : super(key: key);

  @override
  ArticleTitlesPageState createState() => ArticleTitlesPageState();
}

class ArticleTitlesPageState extends State<ArticleTitlesPage> {
  int _selectedIndex = 0;

  StreamSubscription _receiveShareLiveSubscription;
  ArticleTitles articleTitles;
  List<ArticleTitle> filterTitles; // now show list
  final ItemScrollController itemScrollController = ItemScrollController();
  final ItemPositionsListener itemPositionListener = ItemPositionsListener.create();
  Loading loading;

  @override
  initState() {
    super.initState();
    Future.delayed(Duration.zero, () async {
      loading = Provider.of<Loading>(context);
      articleTitles = Provider.of<ArticleTitles>(context, listen: false);
      if (articleTitles.titles.length == 0) {
        await _syncArticleTitles();
      }

      String youtubeURL = ModalRoute.of(context).settings.arguments;
      if (youtubeURL != null) {
        print("youtubeURL=" + youtubeURL);
        syncFromServer(youtubeURL);
      }
    });
  }

  syncFromServer(url) {
    print("url=" + url);
    var articles = Provider.of<Articles>(context, listen: false);
    postYouTube(context, url, articleTitles, articles).then((d) {
      articleTitles.setSelectedArticleID(d.articleID);
      scrollToSharedItem(articleTitles.selectedArticleID);
    });
  }

  @override
  void dispose() {
    _receiveShareLiveSubscription.cancel();
    super.dispose();
  }

  void receiveShare(String sharedText) {
    if (sharedText == null) return;
    // 收到分享, 先跳转到 list 页面
    // 跳转到 list 页
    String youtubeURL = sharedText;
    Navigator.pushNamed(context, '/ArticleTitles', arguments: youtubeURL);
  }

  Future _syncArticleTitles() async {
    articleTitles.getFromLocal();
    return articleTitles.syncServer(context).catchError((e) {
      if (e.response.statusCode == 401) {
        print("must login");
        Navigator.pushNamed(context, '/Sign');
      }
    });
  }

  Widget getArticleTitles() {
    return Consumer<Search>(builder: (context, search, child) {
      return Consumer<ArticleTitles>(builder: (context, articleTitles, child) {
        // List<ArticleTitle> filterTitles;
        if (search.key != "") {
          filterTitles = articleTitles.titles
              .where((d) => d.title.toLowerCase().contains(search.key.toLowerCase()))
              .toList();
        } else {
          // filterTitles = articleTitles.titles.where((d) => d.unlearnedCount > 0).toList();
          filterTitles = articleTitles.titles;
        }
        return filterTitles.length > 0
            ? ScrollablePositionedList.builder(
                itemCount: filterTitles.length,
                itemBuilder: (context, index) {
                  var d = filterTitles[index];
                  return Slidable(
                    actionPane: SlidableDrawerActionPane(),
                    actionExtentRatio: 0.25,
                    child: Ink(
                        color: articleTitles.selectedArticleID == d.id
                            ? Theme.of(context).highlightColor
                            : Colors.transparent,
                        child: ListTile(
                          trailing: ArticleYoutubeAvatar(
                              youtubeURL: d.youtube, avatar: d.avatar, loading: d.deleting),
                          dense: false,
                          onTap: () {
                            articleTitles.setSelectedArticleID(d.id);
                            Navigator.pushNamed(context, '/Article', arguments: d.id);
                          },
                          leading: Text(
                              d.percent.toStringAsFixed(
                                      d.percent.truncateToDouble() == d.percent ? 0 : 1) +
                                  "%",
                              style: TextStyle(
                                color: Colors.blueGrey,
                              )),
                          title: Text(d.title), // 用的 TextTheme.subhead
                        )),
                    secondaryActions: <Widget>[
                      IconSlideAction(
                        caption: 'Delete',
                        color: Colors.red,
                        icon: Icons.delete,
                        onTap: () => _delete(d),
                      ),
                    ],
                  );
                },
                itemScrollController: itemScrollController,
                itemPositionsListener: itemPositionListener,
              )
            : Container();
      });
    });
  }

  // EnsureVisible 不支持 ListView 只有用 50 宽度估算的来 scroll 到分享过来的条目
  Future<void> scrollToSharedItem(int articleID) async {
    if (articleID == 0) return;
    //找到 id
    for (var i = 0; i < filterTitles.length; i++) {
      if (filterTitles[i].id == articleID) {
        _selectedIndex = i;
        break;
      }
    }
    // 稍微等等, 避免 build 时候滚动
    Future.delayed(Duration.zero, () {
      itemScrollController.scrollTo(
          index: _selectedIndex, duration: Duration(seconds: 2), curve: Curves.easeInOutCubic);
    });
  }

  @override
  Widget build(BuildContext context) {
    YouTube youtube = Provider.of<YouTube>(context, listen: true);
    if (youtube.newURL != "") {
      print("youtubeURL=" + youtube.newURL);
      syncFromServer(youtube.newURL);
      youtube.clean();
    }

    articleTitles = Provider.of<ArticleTitles>(context, listen: false);
    print("build article titles");
    Scaffold scaffold = Scaffold(
      appBar: ArticleListsAppBar(),
      body: ModalProgressHUD(
          child: RefreshIndicator(onRefresh: _refresh, child: getArticleTitles()),
          inAsyncCall: articleTitles.titles.length == 0),
      floatingActionButton: Visibility(
          visible: articleTitles.titles.length > 10 ? false : true,
          child: FloatingActionButton(
            onPressed: () {
              Navigator.pushNamed(context, '/Guid');
            },
            tooltip: 'need more',
            child: Icon(Icons.help_outline, color: Theme.of(context).primaryTextTheme.title.color),
          )),
    );
    return scaffold;
  }

  Future _refresh() async {
    await _syncArticleTitles();
    return;
  }

  _delete(ArticleTitle articleTitle) async {
    setState(() {
      articleTitle.deleting = true;
    });
    await articleTitle.deleteArticle(context);
    articleTitles.removeFromList(articleTitle);
  }
}
