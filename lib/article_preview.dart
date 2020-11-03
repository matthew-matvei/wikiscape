import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:either_option/either_option.dart';

import 'article_result.dart';
import 'fetcher.dart' as fetcher;

class ArticlePreview extends StatefulWidget {

  final ArticleResult article;

  ArticlePreview({Key key, this.article}) : super(key: key);

  @override
  _ArticlePreviewState createState() => _ArticlePreviewState();
}

Future<Option<String>> _fetchThumbnailUrlFor(ArticleResult article) async {
  final endpoint = Uri.https(
    'en.wikipedia.org',
    'w/api.php',
    {
      'action': 'query',
      'prop': 'pageimages',
      'titles': article.title,
      'piprop': 'thumbnail',
      'pilicense': 'any',
      'format': 'json'
    });

  return (await fetcher.get(endpoint))
      .fold(
          (error) {
            print("${error.errorCode}: ${error.errorMessage}");
            return None<String>();
          },
          (result) =>
            Some(result['query']['pages'][article.pageId.toString()]['thumbnail']['source']));
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
            return '';
          },
          (result) => result['query']['pages'][article.pageId.toString()]['extract']);
}

class _ArticlePreviewState extends State<ArticlePreview> {

  bool _fetchingIntro = true;
  String _intro;
  Option<String> _thumbnailUrl = None<String>();

  @override
  void initState() {
    super.initState();

    _fetchIntroFor(widget.article)
        .then((intro) {
          setState(() {
            _intro = intro;
            _fetchingIntro = false;
          });
    });

    _fetchThumbnailUrlFor(widget.article)
        .then((thumbnail) {
          setState(() {
            _thumbnailUrl = thumbnail;
          });
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      builder: (context, scrollController) =>
          Padding(
            padding: EdgeInsets.all(10),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    Row(
                      children: [
                        Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            child: _thumbnailUrl.fold(
                                    () => Icon(Icons.image, size: 50),
                                    (url) => CachedNetworkImage(
                                        imageUrl: url,
                                        placeholder: (_, __) => Icon(Icons.image, size: 50),
                                        errorWidget: (_, __, ___) => Icon(Icons.error),
                                        width: 50))
                        ),
                        Expanded(
                            child: Text(
                              widget.article.title,
                              style: TextStyle(fontSize: 20)
                          )
                        )
                      ],
                    ),
                  Divider(),
                  Expanded(
                      child: ListView(
                          controller: scrollController,
                          children: [
                              _fetchingIntro
                                  ? CircularProgressIndicator()
                                  : Html(data: _intro)
                          ])
                  )
                ]
            ),
          ),
      initialChildSize: 0.3,
      maxChildSize: 0.5,
      expand: false,
    );
  }
}