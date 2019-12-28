import 'dart:async';

import 'package:ebuoy/components/article_sentences.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../components/article_top_bar.dart';
import '../components/not_mastered_vocabularies.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import '../models/article_titles.dart';
import '../models/article.dart';
import '../models/article_status.dart';
import '../models/articles.dart';
import '../models/setting.dart';
import '../themes/bright.dart';

@immutable
class ArticlePage extends StatefulWidget {
  ArticlePage({Key key, this.id}) : super(key: key);

  final int id;

  @override
  _ArticlePageState createState() => _ArticlePageState();
}

class _ArticlePageState extends State<ArticlePage> {
  // 后台返回的文章结构
  Article _article;
  Article articleTmp = Article();
  ScrollController _controller;
  ArticleStatus articleStatus;
  Setting setting;

  @override
  void initState() {
    super.initState();
    _controller = ScrollController();
    Future.delayed(Duration.zero, () {
      articleStatus = Provider.of<ArticleStatus>(context, listen: false);
      setting = Provider.of<Setting>(context, listen: false);
      loadArticleByID();
    });
  }

  @override
  void deactivate() {
    // This pauses video while navigating to next page.
    articleStatus.youtubeController.pause();
    super.deactivate();
  }

  @override
  void dispose() {
    //为了避免内存泄露，需要调用_controller.dispose
    _controller.dispose();
    super.dispose();
  }

  Future loadFromServer() async {
    return articleTmp.getArticleByID(context, widget.id).then((d) {
      setState(() {
        _article = articleTmp;
      });
      // 更新本地未学单词数
      var articleTitles = Provider.of<ArticleTitles>(context, listen: false);
      articleTitles.setUnlearnedCountByArticleID(_article.unlearnedCount, _article.articleID);
      return d;
    });
  }

  Future loadArticleByID() async {
    // from mem cache
    var articles = Provider.of<Articles>(context, listen: false);
    setState(() {
      _article = articles.articles[widget.id];
    });
    // from local cache
    articleTmp.getFromLocal(widget.id).then((hasLocal) {
      if (hasLocal)
        setState(() {
          _article = articleTmp;
        });
    });

    // always update from server
    return await loadFromServer();
  }

  Widget getRefresh() {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: articleBody(),
      color: mainColor,
    );
  }

  Widget getWrapLoading() {
    return ModalProgressHUD(
        child: Column(children: [getYouTube(), Expanded(child: getRefresh())]),
        inAsyncCall: _article == null);
  }

  Widget articleBody() {
    return _article != null
        ? SingleChildScrollView(
            controller: _controller,
            child: Column(children: [
              ArticleTopBar(article: _article),
              Padding(
                  padding: EdgeInsets.only(top: 0, left: 0, bottom: 0, right: 0),
                  child: NotMasteredVocabulary(article: _article)),
              Padding(
                  padding: EdgeInsets.only(top: 5.0, left: 5.0, bottom: 5, right: 5),
                  child: ArticleSentences(article: _article, sentences: _article.sentences)),
              Padding(
                  padding: EdgeInsets.only(top: 0, left: 0, bottom: 0, right: 0),
                  child: NotMasteredVocabulary(article: _article)),
            ]))
        : Container();
  }

  Widget getYouTube() {
    /* new
    YoutubePlayerController youtubeController = YoutubePlayerController(
      initialVideoId: YoutubePlayer.convertUrlToId(_article.youtube),
      flags: YoutubePlayerFlags(
        hideControls: false,
        controlsVisibleAtStart: false,
        //自动播放
        autoPlay: setting.isAutoplay,
        mute: false,
        isLive: false,
        forceHideAnnotation: false,
        hideThumbnail: false,
        disableDragSeek: false,
        enableCaption: true,
        captionLanguage: 'en',
        loop: false,
      ),
    );
    articleStatus.setYouTube(youtubeController);
     */
    return _article == null || _article.youtube == ''
        ? Container()
        : Container(
            color: Colors.black,
            padding: EdgeInsets.only(top: 24),
            child:

                /* new
            YoutubePlayer(
                controller: youtubeController,
                showVideoProgressIndicator: true,
                progressIndicatorColor: Colors.teal,
                liveUIColor: Colors.teal,
                progressColors: ProgressBarColors(
                  playedColor: Colors.teal,
                  handleColor: Colors.tealAccent,
                ))
                 */
                YoutubePlayer(
              onPlayerInitialized: (controller) => articleStatus.setYouTube(controller),
              context: context,
              videoId: YoutubePlayer.convertUrlToId(_article.youtube),
              flags: YoutubePlayerFlags(
                //自动播放
                autoPlay: setting.isAutoplay,
                // 下半部分小小的进度条
                showVideoProgressIndicator: true,
                // 允许全屏
                hideFullScreenButton: false,
                // 不可能是 live 的视频
                isLive: false,
                forceHideAnnotation: false,
              ),
              videoProgressIndicatorColor: Colors.teal,
              liveUIColor: Colors.teal,
              progressColors: ProgressColors(
                playedColor: Colors.teal,
                handleColor: Colors.tealAccent,
              ),
            ));
  }

  Future _refresh() async {
    await loadFromServer();
    return;
  }

  @override
  Widget build(BuildContext context) {
    print("build article");
    return Scaffold(
      body: getWrapLoading(),
      /*
        floatingActionButton: LaunchYoutubeButton(
          youtubeURL: _article == null ? '' : _article.youtube,
        )
        */
    );
  }
}
