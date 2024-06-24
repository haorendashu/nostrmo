import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:bot_toast/bot_toast.dart';
import 'package:easy_image_viewer/easy_image_viewer.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:nostrmo/util/image_tool.dart';
import 'package:nostrmo/util/store_util.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

import '../generated/l10n.dart';

const _defaultBackgroundColor = Colors.black;
const _defaultCloseButtonColor = Colors.white;
const _defaultCloseButtonTooltip = 'Close';

class ImagePreviewDialog extends StatefulWidget {
  final EasyImageProvider imageProvider;
  final bool immersive;
  final void Function(int)? onPageChanged;
  final void Function(int)? onViewerDismissed;
  final bool useSafeArea;
  final bool swipeDismissible;
  final bool doubleTapZoomable;
  final Color backgroundColor;
  final String closeButtonTooltip;
  final Color closeButtonColor;

  const ImagePreviewDialog(this.imageProvider,
      {Key? key,
      this.immersive = true,
      this.onPageChanged,
      this.onViewerDismissed,
      this.useSafeArea = false,
      this.swipeDismissible = false,
      this.doubleTapZoomable = false,
      required this.backgroundColor,
      required this.closeButtonTooltip,
      required this.closeButtonColor})
      : super(key: key);

  /// Shows the given [imageProvider] in a full-screen [Dialog].
  /// Setting [immersive] to false will prevent the top and bottom bars from being hidden.
  /// The optional [onViewerDismissed] callback function is called when the dialog is closed.
  /// The optional [useSafeArea] boolean defaults to false and is passed to [showDialog].
  /// The optional [swipeDismissible] boolean defaults to false and allows swipe-down-to-dismiss.
  /// The optional [doubleTapZoomable] boolean defaults to false and allows double tap to zoom.
  /// The [backgroundColor] defaults to black, but can be set to any other color.
  /// The [closeButtonTooltip] text is displayed when the user long-presses on the
  /// close button and is used for accessibility.
  /// The [closeButtonColor] defaults to white, but can be set to any other color.
  static Future<void> show(
      BuildContext context, EasyImageProvider imageProvider,
      {bool immersive = true,
      void Function(int)? onPageChanged,
      void Function(int)? onViewerDismissed,
      bool useSafeArea = false,
      bool swipeDismissible = false,
      bool doubleTapZoomable = false,
      Color backgroundColor = _defaultBackgroundColor,
      String closeButtonTooltip = _defaultCloseButtonTooltip,
      Color closeButtonColor = _defaultCloseButtonColor}) {
    // if (immersive) {
    //   // Hide top and bottom bars
    //   SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    // }

    return showDialog(
        context: context,
        useSafeArea: useSafeArea,
        builder: (context) {
          return ImagePreviewDialog(imageProvider,
              immersive: immersive,
              onPageChanged: onPageChanged,
              onViewerDismissed: onViewerDismissed,
              useSafeArea: useSafeArea,
              swipeDismissible: swipeDismissible,
              doubleTapZoomable: doubleTapZoomable,
              backgroundColor: backgroundColor,
              closeButtonColor: closeButtonColor,
              closeButtonTooltip: closeButtonTooltip);
        });
  }

  @override
  State<StatefulWidget> createState() {
    return _ImagePreviewDialog();
  }
}

class _ImagePreviewDialog extends State<ImagePreviewDialog> {
  /// This is used to either activate or deactivate the ability to swipe-to-dismissed, based on
  /// whether the current image is zoomed in (scale > 0) or not.
  DismissDirection _dismissDirection = DismissDirection.down;
  void Function()? _internalPageChangeListener;
  late final PageController _pageController;

  /// This is needed because of https://github.com/thesmythgroup/easy_image_viewer/issues/27
  /// When no global key was used, the state was re-created on the initial zoom, which
  /// caused the new state to have _pagingEnabled set to true, which in turn broke
  /// paning on the zoomed-in image.
  final _popScopeKey = GlobalKey();

  // focus node to capture keyboard events
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _pageController =
        PageController(initialPage: widget.imageProvider.initialIndex);
    if (widget.onPageChanged != null) {
      _internalPageChangeListener = () {
        widget.onPageChanged!(_pageController.page?.round() ?? 0);
      };
      _pageController.addListener(_internalPageChangeListener!);
    }
  }

  @override
  void dispose() {
    if (_internalPageChangeListener != null) {
      _pageController.removeListener(_internalPageChangeListener!);
    }
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var s = S.of(context);

    var main = Scaffold(
      backgroundColor: widget.backgroundColor.withOpacity(0.5),
      body: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: <Widget>[
            EasyImageViewPager(
                easyImageProvider: widget.imageProvider,
                pageController: _pageController,
                doubleTapZoomable: widget.doubleTapZoomable,
                onScaleChanged: (scale) {
                  setState(() {
                    _dismissDirection = scale <= 1.0
                        ? DismissDirection.down
                        : DismissDirection.none;
                  });
                }),
            Positioned(
                top: 5,
                right: 5,
                child: IconButton(
                  icon: const Icon(Icons.close),
                  color: widget.closeButtonColor,
                  tooltip: widget.closeButtonTooltip,
                  onPressed: close,
                )),
            Positioned(
                bottom: 5,
                left: 5,
                child: IconButton(
                  icon: const Icon(Icons.download),
                  color: widget.closeButtonColor,
                  tooltip: s.Download,
                  onPressed: saveImage,
                )),
          ]),
    );

    final popScopeAwareDialog = WillPopScope(
      onWillPop: () async {
        _handleDismissal();
        return true;
      },
      key: _popScopeKey,
      child: KeyboardListener(
        focusNode: _focusNode,
        onKeyEvent: (ke) {
          var duration = const Duration(seconds: 1);
          if (ke.logicalKey.keyLabel == 'Arrow Left') {
            _pageController.previousPage(
                duration: duration, curve: Curves.ease);
          } else if (ke.logicalKey.keyLabel == 'Arrow Right') {
            _pageController.nextPage(duration: duration, curve: Curves.ease);
          } else if (ke.logicalKey.keyLabel == 'Arrow Down') {
            close();
          }
        },
        child: main,
      ),
    );

    if (widget.swipeDismissible) {
      return Dismissible(
          direction: _dismissDirection,
          resizeDuration: null,
          confirmDismiss: (dir) async {
            return true;
          },
          onDismissed: (_) {
            Navigator.of(context).pop();

            _handleDismissal();
          },
          key: const Key('dismissible_easy_image_viewer_dialog'),
          child: popScopeAwareDialog);
    } else {
      return popScopeAwareDialog;
    }
  }

  Future<void> saveImage() async {
    if (Platform.isIOS) {
      _doSaveImage();
    } else if (Platform.isAndroid) {
      PermissionStatus permission = await Permission.storage.request();
      if (permission == PermissionStatus.granted) {
        _doSaveImage();
      } else {
        print("Permission not found");
      }
    } else {
      _doSaveImage(isPc: true);
    }
  }

  Future<void> _doSaveImage({bool isPc = false}) async {
    var index = _pageController.page!.toInt();
    var imageProvider = widget.imageProvider.imageBuilder(context, index);
    var imageAsBytes =
        await imageProvider.getBytes(context, format: ImageByteFormat.png);
    if (imageAsBytes != null) {
      if (!isPc) {
        var result =
            await ImageGallerySaver.saveImage(imageAsBytes, quality: 100);
        if (result != null && result is Map && result["isSuccess"]) {
          BotToast.showText(text: S.of(context).Image_save_success);
        }
      } else {
        var result = await FileSaver.instance.saveFile(
          name: DateTime.now().millisecondsSinceEpoch.toString(),
          bytes: imageAsBytes,
          ext: ".png",
        );
        BotToast.showText(text: "${S.of(context).Image_save_success} $result");
      }
    }
  }

  // Internal function to be called whenever the dialog
  // is dismissed, whether through the Android back button,
  // through the "x" close button, or through swipe-to-dismiss.
  void _handleDismissal() {
    if (widget.onViewerDismissed != null) {
      widget.onViewerDismissed!(_pageController.page?.round() ?? 0);
    }

    // if (widget.immersive) {
    //   SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    // }
    if (_internalPageChangeListener != null) {
      _pageController.removeListener(_internalPageChangeListener!);
    }
  }

  void close() {
    Navigator.of(context).pop();
    _handleDismissal();
  }
}
