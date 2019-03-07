// 文章详情内容
import 'dart:async';
import 'package:flutter/material.dart';
import './word.dart';
import 'package:dio/dio.dart';
import '../store/store.dart';

class Article with ChangeNotifier {
  int articleID;
  // 文章中的文字内容
  List words = [];
  // 标题
  String title;
  // 从 json 中设置
  setFromJSON(Map json) {
    this.title = json['title'];
    this.words = json['words'].map((d) => Word.fromJson(d)).toList();
    notifyListeners();
  }

  clear() {
    this.title = '';
    this.words.clear();
    notifyListeners();
  }

  // 从服务器获取
  Future getArticleByID(int articleID) async {
    this.articleID = articleID;
    Dio dio = getDio();
    var response =
        await dio.get(Store.baseURL + "article/" + this.articleID.toString());
    this.setFromJSON(response.data);
    // 获取以后, 就计算一遍未读数, 然后提交
    this._putUnlearnedCount();
    return response;
  }

  // 更新提交为学会单词数
  Future _putUnlearnedCount() async {
    if (articleID == null) {
      return null;
    }
    // 重新计算未掌握单词数
    int unlearnedCount = this
        .words
        .map((d) {
          if (d.level > 0 && !d.learned) {
            return d.text;
          }
        })
        .toSet()
        .length;
    unlearnedCount--;
    Dio dio = getDio();
    var response = await dio.put(Store.baseURL + "article/unlearned_count",
        data: {"article_id": articleID, "unlearned_count": unlearnedCount});
    return response;
  }

// 设置当前文章的所有该单词为需要的学习状态
  _setWordIsLearned(String word, bool isLearned) {
    this.words.forEach((d) {
      if (d.text.toLowerCase() == word) {
        d.learned = isLearned;
      }
    });
    notifyListeners();
  }

  // 记录学习状态
  putLearned(Word word) {
    // 标记所有单词为对应状态, 并通知
    this._setWordIsLearned(word.text, word.learned);
    word.putLearned().then((d) => _putUnlearnedCount());
  }
}