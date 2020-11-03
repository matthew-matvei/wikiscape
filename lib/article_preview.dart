import 'package:flutter/material.dart';

import 'article_result.dart';
import 'fetcher.dart' as fetcher;

class ArticlePreview extends StatefulWidget {

  final ArticleResult article;

  ArticlePreview({Key key, this.article}) : super(key: key);

  @override
  _ArticlePreviewState createState() => _ArticlePreviewState();
}

Future<String> _fetchIntroFor(ArticleResult article) async {
  final endpoint = Uri.https(
      'en.wikipedia.org',
      'w/api.php',
      {
        'action': 'query',
        'prop': 'extracts',
        'exintro': 'true',
        'titles': article.title,
        'format': 'json',
      });

  return (await fetcher.get(endpoint))
    .fold(
          (error) {
            print("${error.errorCode}: ${error.errorMessage}");
            return null;
          },
          (result) => result['query']['pages'][article.pageId.toString()]['extract']);
}

class _ArticlePreviewState extends State<ArticlePreview> {

  bool _fetchingIntro = true;
  String _intro;

  @override
  void initState() {
    super.initState();

    _intro = "Just a test";

    _fetchIntroFor(widget.article)
        .then((intro) {
          setState(() {
            _intro = intro;
            _fetchingIntro = false;
          });
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      builder: (context, scrollController) =>
          Column(
            children: [
              Text(widget.article.title),
              Expanded(
                  child: ListView(
                    children: [
                      _fetchingIntro
                          ? CircularProgressIndicator()
                          : Text(_intro)
                    ],
                    controller: scrollController)
                )
            ],
          ),
      initialChildSize: 0.3,
      maxChildSize: 0.3,
      expand: false,
    );
  }
}