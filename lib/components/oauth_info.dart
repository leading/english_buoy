import 'package:flutter/material.dart';
import 'package:provide/provide.dart';
import '../models/oauth_info.dart';

//登录后显示头像的组件
// loading 时候显示 loading
class OauthInfoWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Provide<OauthInfo>(builder: (context, child, oauthInfo) {
      if (oauthInfo.email == null) {
        return IconButton(
          icon: Icon(Icons.exit_to_app),
          tooltip: 'Sign',
          onPressed: () {
            Navigator.pushNamed(context, '/Sign');
          },
        );
      } else {
        return GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, '/Sign');
            },
            child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircleAvatar(
                  backgroundImage: NetworkImage(oauthInfo.avatarURL),
                )));
      }
    });
  }
}
