import '../models/article.dart';
import './article_sentences.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../models/sentence.dart';
import '../models/word.dart';
import '../functions/article.dart';
import 'article_sentences.dart';
import '../models/article_inherited.dart';

class NotMasteredVocabulary extends StatefulWidget {
  @override
  NotMasteredVocabularyState createState() => NotMasteredVocabularyState();
}

class NotMasteredVocabularyState extends State<NotMasteredVocabulary> {
  Article _article;
  List<Word> _mustLearnWords = List(); // in NESL
  List<String> _mustLearnUnique = List();
  List<Word> _needLearnWords = List(); // not in NESL
  List<Word> _allWords;
  bool _hideSome = false;

  @override
  initState() {
    super.initState();
  }

  filterMustNeedWords() {
    _article.sentences.forEach((s) {
      s.words.forEach((w) {
        // not mastered words
        if (!w.learned && isNeedLearn(w)) {
          if (w.level != null &&
              w.level != 0 &&
              !_mustLearnUnique.contains(w.text.toLowerCase())) {
            w.belongSentence = s;
            _mustLearnWords.add(w);
            _mustLearnUnique.add(w.text.toLowerCase());
          } else if ((w.level == null || w.level == 0) &&
              !_mustLearnUnique.contains(w.text.toLowerCase())) {
            w.belongSentence = s;
            _mustLearnWords.add(w);
            _mustLearnUnique.add(w.text.toLowerCase());
          }
        }
      });
    });
    if (_allWords == null) {
      _allWords = _mustLearnWords + _needLearnWords;
    } else {
      _allWords = updateAllWords(_allWords, _mustLearnWords + _needLearnWords);
    }
    if (_allWords.length > 40) {
      _hideSome = true;
      _allWords = _allWords.sublist(0, 40);
    }
  }

  updateAllWords(List<Word> oldWords, List<Word> newWords) {
    //first update to learned then use new update back
    oldWords.forEach((d) {
      d.learned = false;
      return d;
    });

    oldWords.addAll(newWords);
    return oldWords;
  }

  TableRow getTableRow({Widget one, Widget two, Widget three}) {
    double p = 6;
    return TableRow(children: [
      Center(child: Padding(padding: EdgeInsets.all(p), child: one)),
      Center(child: Padding(padding: EdgeInsets.all(p), child: two)),
      Center(child: Padding(padding: EdgeInsets.all(p), child: three)),
    ]);
  }

  TableRow getTitleRow() {
    return getTableRow(
      one: Text("NGSL", style: bodyTextStyle),
      two: Text("words(" + _allWords.length.toString() + ")",
          style: bodyTextStyle),
      three: Text("find", style: bodyTextStyle),
    );
  }

  List<TableRow> getAllWordRows() {
    return _allWords.map((d) {
      Sentence sentence = Sentence('', [d]);
      return getTableRow(
        one: Text(
          d.level == 0 ? "-" : d.level.toString(), style: bodyTextStyle,
          //style: Theme.of(context).textTheme.display2,
        ),
        two: ArticleSentences(
            article: _article,
            sentences: [sentence],
            crossAxisAlignment: CrossAxisAlignment.baseline),
        three: GestureDetector(
            onTap: () {
              //跳转到文章中这一句
              Scrollable.ensureVisible(d.belongSentence.c);
              _article.setFindWord(d.text);
              _article.setNotMasteredWord(sentence);
            },
            child: Icon(
              Icons.find_in_page,
              color: Theme.of(context).primaryColorLight,
            )),
      );
    }).toList();
  }

  List<TableRow> getRenderWordRows() {
    TableRow titleRow = getTitleRow();
    List<TableRow> allWordRows = getAllWordRows();
    TableRow moreRow = getTableRow(
      one: Text("..."),
      two: Text("..."),
      three: Text("..."),
    );

    List<TableRow> renderWordRows =
        allWordRows.length != 0 ? [titleRow] + allWordRows : allWordRows;
    if (_hideSome) renderWordRows = renderWordRows + [moreRow];
    return renderWordRows;
  }

  @override
  Widget build(BuildContext context) {
    List<TableRow> renderWordRows = getRenderWordRows();
    return Table(
        border: TableBorder.all(
            color: Theme.of(context).primaryColorDark, width: 0.4),
        columnWidths: {
          0: IntrinsicColumnWidth(),
          1: FlexColumnWidth(8),
          2: IntrinsicColumnWidth(),
        },
        children: renderWordRows);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _article = ArticleInherited.of(context).article;
    filterMustNeedWords();
  }
}
