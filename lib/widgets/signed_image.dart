import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/oss_upload_service.dart';

class SignedImage extends StatefulWidget {
  final String objectKey;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final Duration cacheDuration;

  const SignedImage({
    Key? key,
    required this.objectKey,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.cacheDuration = const Duration(hours: 1),
  }) : super(key: key);

  @override
  State<SignedImage> createState() => _SignedImageState();
}

class _SignedImageState extends State<SignedImage> {
  final OssUploadService _ossService = OssUploadService();
  String? _signedUrl;
  DateTime? _urlExpireTime;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSignedUrl();
  }

  @override
  void didUpdateWidget(SignedImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.objectKey != widget.objectKey) {
      _loadSignedUrl();
    }
  }

  Future<void> _loadSignedUrl() async {
    if (_isLoading) return;

    // 检查URL是否已存在且未过期
    if (_signedUrl != null && _urlExpireTime != null) {
      if (_urlExpireTime!.isAfter(DateTime.now())) {
        return; // URL still valid
      }
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final url = await _ossService.getSignedUrl(widget.objectKey);
      if (mounted) {
        setState(() {
          _signedUrl = url;
          _urlExpireTime = DateTime.now().add(widget.cacheDuration);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return widget.placeholder ?? 
             SizedBox(
               width: widget.width,
               height: widget.height,
               child: const Center(child: CircularProgressIndicator()),
             );
    }

    if (_error != null) {
      return widget.errorWidget ??
             SizedBox(
               width: widget.width,
               height: widget.height,
               child: Center(
                 child: Column(
                   mainAxisSize: MainAxisSize.min,
                   children: [
                     const Icon(Icons.error_outline, color: Colors.red),
                     const SizedBox(height: 8),
                     Text(
                       '加载失败',
                       style: Theme.of(context).textTheme.bodySmall,
                     ),
                     TextButton(
                       onPressed: _loadSignedUrl,
                       child: const Text('重试'),
                     ),
                   ],
                 ),
               ),
             );
    }

    if (_signedUrl == null) {
      return const SizedBox.shrink();
    }

    return CachedNetworkImage(
      imageUrl: _signedUrl!,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      httpHeaders: const {
        'Accept': '*/*',
      },
      placeholder: (context, url) => widget.placeholder ??
                                   const Center(child: CircularProgressIndicator()),
      errorWidget: (context, url, error) => widget.errorWidget ??
                                          const Icon(Icons.error_outline, color: Colors.red),
      cacheManager: DefaultCacheManager(),
    );
  }
}
