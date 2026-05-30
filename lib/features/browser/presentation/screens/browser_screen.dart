import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/services/share_service.dart';
import '../../../downloads/presentation/providers/downloads_providers.dart';
import '../../../favorites/presentation/providers/favorites_providers.dart';

/// شاشة عرض الموقع في WebView (مأخوذة من تصميم `home.dart` القديم).
///
/// مهم (طلب المستخدم):
/// - عند فشل تحميل الصفحة لا نعرض أي شاشة Flutter بديلة ولا overlay، فقط
///   نترك الـ WebView يعرض صفحة الخطأ الافتراضية للمتصفح.
/// - الروابط غير المتعلقة بـ mnhaji (واتساب/تلجرام/فيسبوك/متجر التطبيقات)
///   تفتح في المتصفح/التطبيق الخارجي.
class BrowserScreen extends ConsumerStatefulWidget {
  const BrowserScreen({super.key, required this.initialUrl});

  final String initialUrl;

  @override
  ConsumerState<BrowserScreen> createState() => _BrowserScreenState();
}

class _BrowserScreenState extends ConsumerState<BrowserScreen> {
  late final WebViewController _controller;
  String _currentUrl = '';
  String _currentTitle = '';
  bool _isLoading = true;
  bool _isFavorite = false;
  bool _canGoBack = false;
  bool _canGoForward = false;

  @override
  void initState() {
    super.initState();
    _currentUrl = widget.initialUrl;
    _controller = _buildController();
    _checkFavorite();
  }

  WebViewController _buildController() {
    final WebViewController controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            if (mounted) {
              setState(() {
                _currentUrl = url;
                _isLoading = true;
              });
            }
            _checkFavorite();
          },
          onPageFinished: (String url) {
            if (mounted) {
              setState(() {
                _currentUrl = url;
                _isLoading = false;
              });
            }
            _controller.getTitle().then((String? t) {
              if (!mounted) return;
              setState(() => _currentTitle = t ?? '');
            });
            _updateNavState();
          },
          onProgress: (int progress) {
            // لا نحتاج لإظهار شريط تقدم — نكتفي بمؤشر الدائري الذي يختفي عند 100%.
          },
          // مهم: نتجاهل أخطاء الموارد ونترك الـ WebView يعرض صفحة الخطأ الافتراضية
          // (طلب المستخدم: لا نعرض شاشة Flutter بديلة).
          onWebResourceError: (WebResourceError error) {
            /* تجاهل مقصود */
          },
          onNavigationRequest: _onNavigation,
        ),
      );

    // إعدادات Android: السماح بمحتوى مختلط وعرض الفيديو inline.
    if (controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(false);
      final AndroidWebViewController android =
          controller.platform as AndroidWebViewController;
      android.setMediaPlaybackRequiresUserGesture(false);
    }

    controller.loadRequest(Uri.parse(widget.initialUrl));
    return controller;
  }

  /// منطق فلترة الروابط (مأخوذ من الإصدار القديم في `home.dart`).
  Future<NavigationDecision> _onNavigation(NavigationRequest req) async {
    final String url = req.url;

    // intent://details → فتح Google Play
    if (url.contains('intent://details')) {
      const String startKey = 'id=';
      const String endKey = '&inline';
      final int startIdx = url.indexOf(startKey);
      final int endIdx = url.indexOf(endKey, startIdx + startKey.length);
      if (startIdx >= 0 && endIdx > startIdx) {
        final String appId = url.substring(startIdx + startKey.length, endIdx);
        final Uri play = Uri.parse(
          'https://play.google.com/store/apps/details?id=$appId',
        );
        if (await canLaunchUrl(play)) {
          await launchUrl(play, mode: LaunchMode.externalApplication);
        }
      }
      return NavigationDecision.prevent;
    }

    // روابط منصات خارجية: تُفتح في تطبيق خارجي.
    const List<String> externalKeywords = <String>[
      'whatsapp',
      'play.google.com',
      'telegram',
      't.me',
      'twitter',
      'snapchat',
      'mail',
      'facebook',
    ];
    if (externalKeywords.any(url.contains)) {
      final Uri u = Uri.parse(url);
      if (await canLaunchUrl(u)) {
        await launchUrl(u, mode: LaunchMode.externalApplication);
      }
      return NavigationDecision.prevent;
    }

    // أي scheme غير http/https/file/about → خارجي.
    final Uri uri = Uri.parse(url);
    const List<String> allowed = <String>[
      'http',
      'https',
      'file',
      'about',
      'data',
    ];
    if (!allowed.contains(uri.scheme)) {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return NavigationDecision.prevent;
    }

    // ملفات قابلة للتنزيل (PDF/DOC/...): نطلق التنزيل عبر Dio بدل فتحها في WebView.
    if (_looksDownloadable(url)) {
      _startDownload(url);
      return NavigationDecision.prevent;
    }

    return NavigationDecision.navigate;
  }

  bool _looksDownloadable(String url) {
    final String lower = url.toLowerCase();
    const List<String> exts = <String>[
      '.pdf',
      '.doc',
      '.docx',
      '.xls',
      '.xlsx',
      '.ppt',
      '.pptx',
      '.zip',
      '.rar',
      '.apk',
    ];
    return exts.any(lower.endsWith);
  }

  Future<void> _startDownload(String url) async {
    final messenger = ScaffoldMessenger.of(context);
    await ref
        .read(downloadsListProvider.notifier)
        .startDownload(
          url,
          onAlreadyExists: (_) {
            messenger.showSnackBar(
              const SnackBar(
                content: Text('الملف موجود بالفعل، تحقق من التنزيلات'),
              ),
            );
          },
        );
    if (!mounted) return;
    messenger.showSnackBar(
      const SnackBar(
        content: Text('بدأ تنزيل الملف، يمكنك متابعته من شاشة التنزيلات'),
      ),
    );
  }

  String _cleanedUrl(String url) {
    return url.replaceAll('#google_vignette', '');
  }

  Future<void> _checkFavorite() async {
    final bool fav = await ref
        .read(favoritesRepositoryProvider)
        .isFavorite(_cleanedUrl(_currentUrl));
    if (!mounted) return;
    setState(() => _isFavorite = fav);
  }

  Future<void> _toggleFavorite() async {
    final messenger = ScaffoldMessenger.of(context);
    final bool nowFav = await ref
        .read(favoritesRepositoryProvider)
        .toggle(
          url: _cleanedUrl(_currentUrl),
          title: _currentTitle.isEmpty ? AppStrings.appName : _currentTitle,
        );
    // إعادة بناء الـ count provider.
    ref.invalidate(favoritesCountProvider);
    if (!mounted) return;
    setState(() => _isFavorite = nowFav);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          nowFav ? 'تمت الإضافة إلى المفضلة' : 'تم الحذف من المفضلة',
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<bool> _onWillPop() async {
    if (await _controller.canGoBack()) {
      await _controller.goBack();
      return false;
    }
    return true;
  }

  /// تحديث حالة أزرار التراجع/التقدم بحسب سجل تصفّح الـWebView.
  Future<void> _updateNavState() async {
    final bool back = await _controller.canGoBack();
    final bool forward = await _controller.canGoForward();
    if (!mounted) return;
    setState(() {
      _canGoBack = back;
      _canGoForward = forward;
    });
  }

  /// التراجع عن تصفّح صفحات الويب (وليس الخروج من الشاشة).
  Future<void> _goBackWeb() async {
    if (await _controller.canGoBack()) {
      await _controller.goBack();
      await _updateNavState();
    }
  }

  /// التقدّم لصفحة الويب التالية في السجل.
  Future<void> _goForwardWeb() async {
    if (await _controller.canGoForward()) {
      await _controller.goForward();
      await _updateNavState();
    }
  }

  /// الخروج من شاشة الـWebView والعودة للصفحة السابقة في التطبيق.
  void _exitBrowser() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      context.go('/');
    }
  }

  /// تنفيذ عناصر قائمة الخيارات (popup menu).
  Future<void> _onMenuSelected(_BrowserMenu value) async {
    switch (value) {
      case _BrowserMenu.share:
        await ShareService.sharePage(
          title: _currentTitle.isEmpty ? AppStrings.appName : _currentTitle,
          url: _cleanedUrl(_currentUrl),
        );
      case _BrowserMenu.favorites:
        ref.read(favoritesListProvider.notifier).refresh();
        if (mounted) context.push('/favorites-view');
      case _BrowserMenu.downloads:
        ref.read(downloadsListProvider.notifier).refresh();
        if (mounted) context.push('/downloads-view');
      case _BrowserMenu.home:
        await _controller.loadRequest(Uri.parse(AppStrings.siteUrl));
      case _BrowserMenu.rate:
        final Uri store = Uri.parse(AppStrings.androidStoreUrl);
        if (await canLaunchUrl(store)) {
          await launchUrl(store, mode: LaunchMode.externalApplication);
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? _) async {
        if (didPop) return;
        final bool shouldPop = await _onWillPop();
        if (shouldPop && mounted) {
          // ignore: use_build_context_synchronously
          if (Navigator.of(context).canPop()) {
            // ignore: use_build_context_synchronously
            Navigator.of(context).pop();
          } else {
            // ignore: use_build_context_synchronously
            context.go('/');
          }
        }
      },
      child: SafeArea(
        top: false,
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: AppColors.primary,
            automaticallyImplyLeading: false,
            titleSpacing: 0,
            title: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Row(
                children: <Widget>[
                  // أقصى اليمين: زر الخروج من المتصفح + اسم التطبيق.
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: _exitBrowser,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 6,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const <Widget>[
                          // في RTL تُعرض أيقونة arrow_back كسهم يتّجه يميناً (→).
                          Icon(Icons.arrow_back, color: Colors.white, size: 24),
                          SizedBox(width: 8),
                          Text(
                            AppStrings.appName,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  _HeaderButton(
                    icon: Icons.chevron_left,
                    tooltip: 'رجوع',
                    enabled: _canGoBack,
                    onTap: _goBackWeb,
                  ),

                  _HeaderButton(
                    icon: _isFavorite ? Icons.favorite : Icons.favorite_border,
                    tooltip: _isFavorite
                        ? 'إزالة من المفضلة'
                        : 'إضافة إلى المفضلة',
                    onTap: _toggleFavorite,
                  ),
                  // الجهة اليسرى (ترتيب RTL): التقدّم، المفضلة، التراجع، التحديث، القائمة.
                  _HeaderButton(
                    icon: Icons.chevron_right,
                    tooltip: 'التالي',
                    enabled: _canGoForward,
                    onTap: _goForwardWeb,
                  ),

                  _HeaderButton(
                    icon: Icons.refresh,
                    tooltip: 'تحديث',
                    onTap: () => _controller.reload(),
                  ),
                  PopupMenuButton<_BrowserMenu>(
                    tooltip: 'المزيد',
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                    onSelected: _onMenuSelected,
                    itemBuilder: (BuildContext context) =>
                        <PopupMenuEntry<_BrowserMenu>>[
                          const PopupMenuItem<_BrowserMenu>(
                            value: _BrowserMenu.home,
                            child: ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(
                                Icons.home,
                                color: AppColors.primary,
                              ),
                              title: Text('الصفحة الرئيسية'),
                            ),
                          ),
                          const PopupMenuItem<_BrowserMenu>(
                            value: _BrowserMenu.favorites,
                            child: ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(
                                Icons.favorite,
                                color: AppColors.primary,
                              ),
                              title: Text('المفضلة'),
                            ),
                          ),
                          const PopupMenuItem<_BrowserMenu>(
                            value: _BrowserMenu.downloads,
                            child: ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(
                                Icons.download,
                                color: AppColors.primary,
                              ),
                              title: Text('التنزيلات'),
                            ),
                          ),
                          const PopupMenuItem<_BrowserMenu>(
                            value: _BrowserMenu.share,
                            child: ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(
                                Icons.share,
                                color: AppColors.primary,
                              ),
                              title: Text('مشاركة الصفحة'),
                            ),
                          ),
                          const PopupMenuItem<_BrowserMenu>(
                            value: _BrowserMenu.rate,
                            child: ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(
                                Icons.star,
                                color: AppColors.secondary,
                              ),
                              title: Text('ادعمنا بخمس نجوم'),
                            ),
                          ),
                        ],
                  ),
                ],
              ),
            ),
          ),
          body: Stack(
            children: <Widget>[
              RefreshIndicator(
                onRefresh: () async {
                  await _controller.reload();
                  // ننتظر قليلاً ليبدأ التحميل قبل أن يخفي المؤشر.
                  await Future<void>.delayed(const Duration(milliseconds: 600));
                },
                child: WebViewWidget(controller: _controller),
              ),
              if (_isLoading)
                Container(
                  color: Colors.white24,
                  child: const Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// عناصر قائمة الخيارات في رأس شاشة المتصفح.
enum _BrowserMenu { share, favorites, downloads, home, rate }

/// زر أيقونة داخل رأس شاشة المتصفح.
///
/// عند [enabled] = false تظهر الأيقونة باهتة ولا تستجيب للضغط
/// (تُستخدم لأزرار التراجع/التقدّم قبل توفّر سجل تصفّح).
class _HeaderButton extends StatelessWidget {
  const _HeaderButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: enabled ? onTap : null,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      icon: Icon(
        icon,
        color: enabled ? Colors.white : Colors.white.withValues(alpha: 0.4),
        size: 26,
      ),
    );
  }
}
