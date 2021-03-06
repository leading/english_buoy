import 'package:flutter/cupertino.dart';

import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import '../models/article_titles.dart';

class ConfigHideFullMastered extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    ArticleTitles articleTitles =
        Provider.of<ArticleTitles>(context, listen: false);
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text('Hide Mastered'),
      Switch(
        value: articleTitles.settings.isHideFullMastered,
        onChanged: articleTitles.filterHideMastered,
      )
    ]);
  }
}
