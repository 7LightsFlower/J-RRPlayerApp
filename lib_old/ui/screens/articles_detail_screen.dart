// lib/ui/screens/articles_detail_screen.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:jrrplayerapp/constants/app_colors.dart';
import 'package:jrrplayerapp/constants/app_text_styles.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:jrrplayerapp/widgets/custom_app_bar.dart';

class ArticleDetailScreen extends StatefulWidget {
  final String articleUrl;
  final String title;

  const ArticleDetailScreen({
    super.key,
    required this.articleUrl,
    this.title = 'Статья',
  });

  @override
  State<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen> {
  late final WebViewController? _controller;
  bool _isLoading = true;
  double _loadingProgress = 0.0;

  @override
  void initState() {
    super.initState();

    if (!kIsWeb) {
      _initializeWebView();
    } else {
      Future.delayed(const Duration(milliseconds: 100), () {
        _openInBrowser();
      });
    }
  }

  void _initializeWebView() {
    late final PlatformWebViewControllerCreationParams params;

    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    final WebViewController controller =
        WebViewController.fromPlatformCreationParams(params);

    controller.setJavaScriptMode(JavaScriptMode.unrestricted);

    controller.addJavaScriptChannel(
      'disableMic',
      onMessageReceived: (JavaScriptMessage message) {},
    );

    controller.setNavigationDelegate(
      NavigationDelegate(
        onPageStarted: (String url) {
          controller.runJavaScript('''
            (function() {
              if (navigator.mediaDevices) {
                navigator.mediaDevices.getUserMedia = function(constraints) {
                  return Promise.reject(new Error("Microphone not available"));
                };
              }
              if (navigator.getUserMedia) {
                navigator.getUserMedia = null;
              }
              console.log('Microphone access disabled by app');
            })();
          ''');
          setState(() => _isLoading = true);
        },
        onProgress: (progress) {
          setState(() {
            _loadingProgress = progress / 100;
          });
        },
        onPageFinished: (_) => setState(() => _isLoading = false),
        onWebResourceError: (_) => setState(() => _isLoading = false),
      ),
    );

    if (controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
      (controller.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }

    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppColors.customBackgr)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            setState(() {
              _loadingProgress = progress / 100;
            });
          },
          onPageStarted: (_) => setState(() => _isLoading = true),
          onPageFinished: (_) => setState(() => _isLoading = false),
          onWebResourceError: (_) => setState(() => _isLoading = false),
        ),
      )
      ..loadRequest(Uri.parse(widget.articleUrl));

    _controller = controller;
  }

  Future<void> _openInBrowser() async {
    final uri = Uri.parse(widget.articleUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    // ==================== ВЕБ-ВЕРСИЯ ====================
    if (kIsWeb) {
      return Scaffold(
        backgroundColor: AppColors.customBackgr,
        body: SafeArea(
          child: Column(
            children: [
              CustomAppBar(
                leadingIcon: Icons.arrow_back,
                onLeadingTap: () => Navigator.pop(context),
              ),
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.open_in_browser,
                        size: 80,
                        color: AppColors.customWhite,
                      ),
                      SizedBox(height: 24),
                      Text(
                        'Открываем статью в новой вкладке...',
                        style: AppTextStyles.large,
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 16),
                      CircularProgressIndicator(color: AppColors.customStyle),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ==================== МОБИЛЬНАЯ ВЕРСИЯ ====================
    return Scaffold(
      backgroundColor: AppColors.customBackgr,
      body: SafeArea(
        child: Column(
          children: [
            CustomAppBar(
              leadingIcon: Icons.arrow_back,
              onLeadingTap: () => Navigator.pop(context),
            ),
            if (_isLoading && _loadingProgress < 1.0)
              LinearProgressIndicator(
                value: _loadingProgress,
                backgroundColor: AppColors.customBackgr,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.customStyle,
                ),
              ),
            Expanded(child: WebViewWidget(controller: _controller!)),
          ],
        ),
      ),
    );
  }
}