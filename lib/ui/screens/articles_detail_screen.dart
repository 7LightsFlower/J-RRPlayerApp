// lib/ui/screens/articles_detail_screen.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:jrrplayerapp/constants/app_colors.dart';
import 'package:jrrplayerapp/constants/app_sizes.dart';
import 'package:jrrplayerapp/constants/app_strings.dart';
import 'package:jrrplayerapp/constants/app_text_styles.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:jrrplayerapp/widgets/custom_app_bar.dart';

/// JS, отключающий доступ страницы к микрофону.
const String _disableMicJs = '''
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
''';

class ArticleDetailScreen extends StatefulWidget {
  final String articleUrl;
  final String title;

  const ArticleDetailScreen({
    super.key,
    required this.articleUrl,
    this.title = AppStrings.articleDefaultTitle,
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

    // Один NavigationDelegate: раньше второй вызов setNavigationDelegate
    // затирал первый, и JS отключения микрофона не выполнялся.
    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppColors.customBackgr)
      ..addJavaScriptChannel(
        'disableMic',
        onMessageReceived: (JavaScriptMessage message) {},
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            controller.runJavaScript(_disableMicJs);
            if (mounted) setState(() => _isLoading = true);
          },
          onProgress: (progress) {
            if (mounted) setState(() => _loadingProgress = progress / 100);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _isLoading = false);
          },
          onWebResourceError: (_) {
            if (mounted) setState(() => _isLoading = false);
          },
        ),
      );

    if (controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(kDebugMode);
      (controller.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }

    controller.loadRequest(Uri.parse(widget.articleUrl));
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
                        size: AppIconSizes.emptyState,
                        color: AppColors.customWhite,
                      ),
                      SizedBox(height: AppSpacing.medium),
                      Text(
                        AppStrings.articleOpeningInBrowser,
                        style: AppTextStyles.large,
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: AppSpacing.small),
                      CircularProgressIndicator(),
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
              ),
            Expanded(child: WebViewWidget(controller: _controller!)),
          ],
        ),
      ),
    );
  }
}
