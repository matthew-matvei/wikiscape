import 'package:cached_network_image/cached_network_image.dart';
import 'package:either_option/either_option.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:url_launcher/url_launcher.dart';

import 'article_result.dart';
import 'fetcher.dart' as fetcher;

class ArticlePreview extends StatefulWidget {
  final ArticleResult article;
  final BuildContext context;

  const ArticlePreview({Key? key, required this.article, required this.context})
      : super(key: key);

  @override
  State<ArticlePreview> createState() => _ArticlePreviewState();
}

Future<Option<String>> _fetchThumbnailUrlFor(ArticleResult article) async {
  final endpoint = Uri.https('en.wikipedia.org', 'w/api.php', {
    'action': 'query',
    'prop': 'pageimages',
    'titles': article.title,
    'piprop': 'thumbnail',
    'pilicense': 'any',
    'format': 'json'
  });

  return (await fetcher.get(endpoint)).fold((error) {
    print("${error.errorCode}: ${error.errorMessage}");
    return None<String>();
  },
      (result) => Some(result['query']['pages'][article.pageId.toString()]
          ['thumbnail']['source']));
}

Future<String> _fetchIntroFor(ArticleResult article) async {
  final endpoint = Uri.https('en.wikipedia.org', 'w/api.php', {
    'action': 'query',
    'prop': 'extracts',
    'exintro': 'true',
    'titles': article.title,
    'format': 'json',
  });

  return (await fetcher.get(endpoint)).fold((error) {
    print("${error.errorCode}: ${error.errorMessage}");
    return '';
  },
      (result) =>
          result['query']['pages'][article.pageId.toString()]['extract']);
}

void _readArticle(ArticleResult article) async {
  final endpoint = Uri.https('en.wikipedia.org', 'w/api.php', {
    'action': 'query',
    'prop': 'info',
    'inprop': 'url',
    'titles': article.title,
    'format': 'json',
  });

  (await fetcher.get(endpoint)).fold((error) {
    print("${error.errorCode}: ${error.errorMessage}");
    return None<String>();
  },
      (result) => Some(_FetchPageInfoResult.fromJson(
              result['query']['pages'][article.pageId.toString()])
          .uri)).fold(
      () => print("Couldn't acquire url"),
      (urlString) async => {
            if (await canLaunchUrl(Uri.parse(urlString)))
              {await launchUrl(Uri.parse(urlString))}
            else
              {print("Couldn't launch url")}
          });
}

class _ArticlePreviewState extends State<ArticlePreview> {
  bool _fetchingIntro = true;
  late final String _intro;
  Option<String> _thumbnailUrl = None<String>();

  Widget get _header {
    return Row(
      children: [
        Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: _thumbnailUrl.fold(
                () => const Icon(Icons.image, size: 50),
                (url) => CachedNetworkImage(
                    imageUrl: url,
                    placeholder: (_, __) => const Icon(Icons.image, size: 50),
                    errorWidget: (_, __, ___) => const Icon(Icons.error),
                    width: 50))),
        Expanded(
            child: Text(widget.article.title,
                style: const TextStyle(fontSize: 20)))
      ],
    );
  }

  Widget get _actionsBar {
    return Positioned(
        child: Container(
            width: double.infinity,
            height: 40,
            color: const Color.fromARGB(200, 255, 255, 255),
            child: Center(
              child: TextButton(
                style: ButtonStyle(
                  foregroundColor: MaterialStateProperty.all(Colors.blueAccent),
                ),
                onPressed: () {
                  Navigator.pop(widget.context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content:
                        Text("Loading article...", textAlign: TextAlign.center),
                  ));
                  _readArticle(widget.article);
                },
                child: const Text("READ MORE"),
              ),
            )));
  }

  @override
  void initState() {
    super.initState();

    _fetchIntroFor(widget.article).then((intro) {
      if (mounted) {
        setState(() {
          _intro = intro;
          _fetchingIntro = false;
        });
      }
    });

    _fetchThumbnailUrlFor(widget.article).then((thumbnail) {
      if (mounted) {
        setState(() {
          _thumbnailUrl = thumbnail;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
        initialChildSize: 0.3,
        maxChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _header,
                        const Divider(),
                        Expanded(
                          child:
                              ListView(controller: scrollController, children: [
                            _fetchingIntro
                                ? const Center(
                                    heightFactor: 3,
                                    child: CircularProgressIndicator())
                                : HtmlWidget(_intro),
                            Container(height: 40)
                          ]),
                        )
                      ]),
                ),
                _actionsBar
              ],
            ));
  }
}

class _FetchPageInfoResult {
  final String uri;

  const _FetchPageInfoResult({required this.uri});

  factory _FetchPageInfoResult.fromJson(Map<String, dynamic> json) =>
      _FetchPageInfoResult(uri: json['canonicalurl']);
}
