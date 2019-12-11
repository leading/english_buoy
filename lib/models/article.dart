// 文章详情内容
import 'package:flutter/material.dart';
import 'dart:async';

import './word.dart';
import 'package:dio/dio.dart';
import '../store/store.dart';
import './sentence.dart';
import '../components/article_richtext.dart';

class Article {
  int unlearnedCount;
  int articleID;

  // 文章中的文字内容
  // List words = [];
  List<Sentence> sentences;
  List<List<Sentence>> splitSentences = [];

  // 标题
  String title;
  String youtube;
  String avatar;
  int wordCount;

  // 从 json 中设置
  setFromJSON(Map json) {
    this.articleID = json['id'];
    this.title = json['title'];
    this.youtube = json['Youtube'];
    // this.words = json['words'].map((d) => Word.fromJson(d)).toList();
    this.sentences = (json['Sentences'] as List).map((d) {
      // ignore: missing_return
      if (d['Words'] != null) {
        return Sentence.fromJson(d);
      }
      return Sentence("", []);
    }).toList();
    this.unlearnedCount = json['UnlearnedCount'];
    this.avatar = json['Avatar'];
    this.wordCount = json['WordCount'];
    split();
    // notifyListeners();
  }

  // 分割 大约 1000 个句子一组, 关闭这个功能看是否会慢->遇到没分段的文章, 卡死了->改不改这里都会卡死
  split() {
    var len = sentences.length;
    var size = 1000;
    var i = 0;

    while (i < len) {
      var end = i + size;
      while (end < len) {
        end++;
      }
      end = (i + size < len) ? end : len;
      splitSentences.add(sentences.sublist(i, end));
      i += end;
    }
  }

  clear() {
    this.youtube = '';
    this.title = '';
    this.sentences.clear();
    // notifyListeners();
  }

  // 从服务器获取
  Future getArticleByID(BuildContext context, int articleID) async {
    this.articleID = articleID;
    Dio dio = getDio(context);
    var response = await dio.get(Store.baseURL + "article/" + this.articleID.toString());

    this.setFromJSON(response.data);
    return response;
  }

  //计算已经学会百分比
  computeLearnedPercent() {}

  // 计算未掌握单词数并提交
  Future _putUnlearnedCount(BuildContext context) async {
    if (articleID == null) {
      return null;
    }
    RegExp regHasLetter = new RegExp(r"[a-zA-Z]+");
    // 重新计算未掌握单词数
    List<String> allWords = [];
    for (int i = 0; i < this.sentences.length; i++) {
      List<String> l = this.sentences[i].words.map((d) {
        if (!d.learned &&
            regHasLetter.hasMatch(d.text) &&
            !noNeedBlank.contains(d.text) &&
            d.text.length > 1) {
          return d.text.toLowerCase();
        }
        return "";
      }).toList();
      allWords = List.from(allWords)..addAll(l);
    }
    debugPrint("unleard words=" + allWords.toSet().toString());
    unlearnedCount = allWords.toSet().length;
    unlearnedCount--;
    // 设置本地的列表
    Dio dio = getDio(context);
    var response = await dio.put(Store.baseURL + "article/unlearned_count",
        data: {"article_id": articleID, "unlearned_count": unlearnedCount});
    return response;
  }

// 设置当前文章这个单词的学习状态
  _setWordIsLearned(String word, bool isLearned) {
    for (int i = 0; i < this.sentences.length; i++) {
      this.sentences[i].words.forEach((d) {
        if (d.text.toLowerCase() == word.toLowerCase()) {
          d.learned = isLearned;
        }
      });
    }
    // notifyListeners();
  }

// 增加学习次数
  increaseLearnCount(String word) {
    for (int i = 0; i < this.sentences.length; i++) {
      this.sentences[i].words.forEach((d) {
        if (d.text.toLowerCase() == word.toLowerCase()) {
          d.count++;
        }
      });
    }
  }

  // 记录学习状态
  Future putLearned(BuildContext context, Word word) async {
    // 标记所有单词为对应状态, 并通知
    this._setWordIsLearned(word.text, word.learned);
    return word.putLearned(context).then((d) => _putUnlearnedCount(context));
  }
}
