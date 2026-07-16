import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:vcare_admin/shared/utils/extension_functions.dart';
import 'package:vcare_admin/shared/widgets/vcare_cached_image.dart';

/// Image Type to decide How to load the image
///
enum ImageType { network, assets }

/// Image Viewer
///
class ImageViewer extends StatefulWidget {
  final String imagePathOrUrl;
  final ImageType imageType;
  final Color? background;
  final String? title;
  final void Function(bool status)? onZoomStatusChanged;
  final Widget? errorWidget;
  final double maxScale;

  const ImageViewer({
    super.key,
    required this.imagePathOrUrl,
    required this.imageType,
    this.background,
    this.title,
    this.onZoomStatusChanged,
    this.errorWidget,
    this.maxScale = 3.5,
  });

  @override
  State<ImageViewer> createState() => _ImageViewerState();
}

class _ImageViewerState extends State<ImageViewer>
    with SingleTickerProviderStateMixin {
  late TransformationController _transformationController;
  late TapDownDetails _doubleTapDetails;
  late AnimationController _animationController;
  late Animation<Matrix4> _matrixAnimation;

  /// Initializing the _transformationController and _animationController
  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 275),
    )..addListener(_animListener);

    _transformationController.addListener(_transformationListener);
  }

  /// Disposing the _transformationController and _animationController
  @override
  void dispose() {
    _animationController.removeListener(_animListener);
    _transformationController.removeListener(_transformationListener);
    _transformationController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  /// Transformation Status listener
  void _transformationListener() {
    widget.onZoomStatusChanged?.call(
      _transformationController.value != .identity() ||
          _transformationController.value.row0.r != 1.0,
    );
  }

  /// Function to listen animation
  void _animListener() {
    _transformationController.value = _matrixAnimation.value;
  }

  /// Function to handle double tap
  void _onDoubleTapDown(TapDownDetails details) {
    _doubleTapDetails = details;
  }

  /// Function to handle double tap
  void _onDoubleTap() {
    Matrix4 endMatrix;
    Offset position = _doubleTapDetails.localPosition;

    if (_transformationController.value != .identity()) {
      endMatrix = .identity();
    } else {
      final scale = (widget.maxScale - 0.5).isNegative
          ? widget.maxScale
          : widget.maxScale - 0.5;
      endMatrix = .identity()
        ..translateByDouble(
          -position.dx * (scale - 1),
          -position.dy * (scale - 1),
          0,
          1,
        )
        ..scaleByDouble(scale, scale, 1, 1);
    }

    widget.onZoomStatusChanged?.call(
      _transformationController.value == .identity(),
    );

    _matrixAnimation = Matrix4Tween(
      begin: _transformationController.value,
      end: endMatrix,
    ).animate(CurveTween(curve: Curves.easeOut).animate(_animationController));
    _animationController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: .light,
      ),
      child: Scaffold(
        backgroundColor: widget.background ?? Colors.white,
        extendBodyBehindAppBar: true,
        extendBody: true,
        appBar: widget.title != null && widget.title!.trim().isNotEmpty
            ? AppBar(
                title: Text(widget.title!),
                systemOverlayStyle: const SystemUiOverlayStyle(
                  statusBarIconBrightness: .light,
                  statusBarColor: Colors.transparent,
                ),
                backgroundColor: Colors.transparent,
                automaticallyImplyLeading: false,
                actions: [
                  Padding(
                    padding: const .only(right: 10.0),
                    child: IconButton(
                      onPressed: () {
                        context.pop();
                      },
                      icon: const Icon(Icons.close),
                    ),
                  ),
                ],
              )
            : null,
        body: _ui4Body(),
      ),
    );
  }

  /// Ui for body
  Widget _ui4Body() {
    return InteractiveViewer(
      transformationController: _transformationController,
      maxScale: widget.maxScale,
      clipBehavior: .none,
      child: GestureDetector(
        onDoubleTapDown: _onDoubleTapDown,
        onDoubleTap: _onDoubleTap,
        child: Hero(
          tag: widget.imagePathOrUrl.hashCode,
          child: widget.imageType == .assets
              ? Image.asset(
                  widget.imagePathOrUrl,
                  height: context.mediaQuery.size.height,
                  width: context.mediaQuery.size.width,
                  errorBuilder: (_, image, error) => SizedBox(
                    height: context.mediaQuery.size.height,
                    width: context.mediaQuery.size.width,
                    child:
                        widget.errorWidget ??
                        Center(
                          child: Icon(
                            Icons.image_not_supported_outlined,
                            color: context.theme.dividerColor,
                          ),
                        ),
                  ),
                )
              : VCareCachedImage(
                  imageUrl: widget.imagePathOrUrl,
                  height: context.mediaQuery.size.height,
                  width: context.mediaQuery.size.width,
                  fit: BoxFit.contain,
                  showLoadingIndicator: true,
                  errorWidget: SizedBox(
                    height: context.mediaQuery.size.height,
                    width: context.mediaQuery.size.width,
                    child:
                        widget.errorWidget ??
                        const Center(
                          child: Icon(
                            Icons.image_not_supported_outlined,
                            color: Colors.white,
                          ),
                        ),
                  ),
                ),
        ),
      ),
    );
  }
}
