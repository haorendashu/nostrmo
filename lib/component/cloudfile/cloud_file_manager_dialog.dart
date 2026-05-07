import 'dart:convert';

import 'package:bot_toast/bot_toast.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nostr_sdk/blossom/blossom_util.dart';
import 'package:nostr_sdk/nip98/nip98_file_manager.dart';
import 'package:nostr_sdk/utils/string_util.dart';

import '../../consts/base.dart';
import '../../consts/base64.dart';
import '../../generated/l10n.dart';
import '../../main.dart';
import '../../provider/uploader.dart';
import '../../util/router_util.dart';
import '../../util/theme_util.dart';

enum CloudStorageType { blossom, nip98 }

class CloudFile {
  final String url;
  final String sha256;
  final int size;
  final String type;
  final int uploaded;

  CloudFile({
    required this.url,
    required this.sha256,
    required this.size,
    required this.type,
    required this.uploaded,
  });

  factory CloudFile.fromBlossom(BlossomBlobDescriptor blob) {
    return CloudFile(
      url: blob.url,
      sha256: blob.sha256,
      size: blob.size,
      type: blob.type,
      uploaded: blob.uploaded,
    );
  }
}

class CloudFileManagerDialog extends StatefulWidget {
  final String serverUrl;
  final CloudStorageType type;

  const CloudFileManagerDialog({
    super.key,
    required this.type,
    required this.serverUrl,
  });

  static Future<List<CloudFile>?> show(
    BuildContext context, {
    required CloudStorageType type,
    required String serverUrl,
  }) async {
    return await showDialog<List<CloudFile>>(
      context: context,
      useRootNavigator: false,
      builder: (_) => CloudFileManagerDialog(
        type: type,
        serverUrl: serverUrl,
      ),
    );
  }

  @override
  State<CloudFileManagerDialog> createState() => _CloudFileManagerDialogState();
}

class _CloudFileManagerDialogState extends State<CloudFileManagerDialog> {
  List<CloudFile> _files = [];
  final Set<String> _selected = {};
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchList();
  }

  String get _serverUrl => widget.serverUrl;

  String get _storageLabel {
    switch (widget.type) {
      case CloudStorageType.blossom:
        return 'Blossom Files';
      case CloudStorageType.nip98:
        return 'NIP-98 Files';
    }
  }

  Future<void> _fetchList() async {
    if (nostr == null) {
      setState(() => _error = 'Not logged in');
      return;
    }
    if (StringUtil.isBlank(_serverUrl)) {
      setState(() => _error = '$_storageLabel server not configured');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      List<CloudFile> files;
      if (widget.type == CloudStorageType.blossom) {
        final blobs = await BlossomUtil.listBlobs(
          nostr!,
          _serverUrl,
          nostr!.publicKey,
        );
        files = blobs.map(CloudFile.fromBlossom).toList();
      } else {
        final listUrl = _serverUrl.endsWith('/')
            ? _serverUrl.substring(0, _serverUrl.length - 1)
            : _serverUrl;
        final response = await NIP98FileManager.list(
          nostr!,
          '$listUrl/list',
        );
        files = _parseNIP98Files(response.rawData);
      }
      if (mounted) {
        setState(() {
          _files = files;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  List<CloudFile> _parseNIP98Files(dynamic data) {
    final files = <CloudFile>[];
    if (data is String) {
      try {
        data = jsonDecode(data);
      } catch (_) {
        return files;
      }
    }

    if (data is Map<String, dynamic>) {
      final filesList = data['files'] ?? [];
      if (filesList is List) {
        for (final item in filesList) {
          if (item is Map<String, dynamic>) {
            try {
              files.add(CloudFile(
                url: (item['url'] ?? '').toString(),
                sha256: (item['sha256'] ?? '').toString().toLowerCase(),
                size: _toInt(item['size']),
                type: (item['type'] ?? 'application/octet-stream').toString(),
                uploaded: _toInt(item['uploaded']),
              ));
            } catch (_) {}
          }
        }
      }
    } else if (data is List) {
      for (final item in data) {
        if (item is Map<String, dynamic>) {
          try {
            files.add(CloudFile(
              url: (item['url'] ?? '').toString(),
              sha256: (item['sha256'] ?? '').toString().toLowerCase(),
              size: _toInt(item['size']),
              type: (item['type'] ?? 'application/octet-stream').toString(),
              uploaded: _toInt(item['uploaded']),
            ));
          } catch (_) {}
        }
      }
    }

    return files;
  }

  static int _toInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  Future<void> _upload() async {
    if (nostr == null) return;

    final filePath = await Uploader.pick(context);
    if (StringUtil.isBlank(filePath)) return;

    final cancel = BotToast.showLoading();
    try {
      CloudFile? file;
      if (BASE64.check(filePath!)) {
        final bytes = BASE64.toData(filePath);
        if (widget.type == CloudStorageType.blossom) {
          final descriptor = await BlossomUtil.uploadBytes(
            nostr!,
            _serverUrl,
            bytes,
          );
          file = descriptor != null ? CloudFile.fromBlossom(descriptor) : null;
        } else {
          final uploadUrl = _serverUrl.endsWith('/')
              ? _serverUrl.substring(0, _serverUrl.length - 1)
              : _serverUrl;
          final response = await NIP98FileManager.uploadBinary(
            nostr!,
            '$uploadUrl/upload',
            bytes,
          );
          if (response.isSuccess && response.rawData is Map) {
            file = _parseNIP98FileItem(response.rawData);
          }
        }
      } else {
        if (widget.type == CloudStorageType.blossom) {
          final descriptor = await BlossomUtil.upload(
            nostr!,
            _serverUrl,
            filePath,
          );
          file = descriptor != null ? CloudFile.fromBlossom(descriptor) : null;
        } else {
          final uploadUrl = _serverUrl.endsWith('/')
              ? _serverUrl.substring(0, _serverUrl.length - 1)
              : _serverUrl;
          final response = await NIP98FileManager.uploadFile(
            nostr!,
            '$uploadUrl/upload',
            filePath,
          );
          if (response.isSuccess && response.rawData is Map) {
            file = _parseNIP98FileItem(response.rawData);
          }
        }
      }

      if (file != null) {
        await _fetchList();
      } else {
        if (mounted) {
          BotToast.showText(text: S.of(context).Upload_fail);
        }
      }
    } finally {
      cancel();
    }
  }

  CloudFile? _parseNIP98FileItem(Map<String, dynamic> data) {
    try {
      return CloudFile(
        url: (data['url'] ?? '').toString(),
        sha256: (data['sha256'] ?? '').toString().toLowerCase(),
        size: _toInt(data['size']),
        type: (data['type'] ?? 'application/octet-stream').toString(),
        uploaded: _toInt(data['uploaded']),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _deleteSingle(CloudFile file) async {
    if (nostr == null) return;
    final cancel = BotToast.showLoading();
    try {
      bool ok = false;
      if (widget.type == CloudStorageType.blossom) {
        ok = await BlossomUtil.deleteBlob(nostr!, _serverUrl, file.sha256);
      } else {
        final deleteUrl = _serverUrl.endsWith('/')
            ? _serverUrl.substring(0, _serverUrl.length - 1)
            : _serverUrl;
        ok = await NIP98FileManager.delete(
          nostr!,
          '$deleteUrl/${file.sha256}',
        );
      }
      if (ok) {
        setState(() {
          _files.removeWhere((f) => f.sha256 == file.sha256);
          _selected.remove(file.sha256);
        });
      } else {
        if (mounted) BotToast.showText(text: 'Delete failed');
      }
    } finally {
      cancel();
    }
  }

  Future<void> _deleteSelected() async {
    if (nostr == null || _selected.isEmpty) return;
    final cancel = BotToast.showLoading();
    try {
      final toDelete = List<String>.from(_selected);
      int failed = 0;
      for (final sha256 in toDelete) {
        bool ok = false;
        if (widget.type == CloudStorageType.blossom) {
          ok = await BlossomUtil.deleteBlob(nostr!, _serverUrl, sha256);
        } else {
          final deleteUrl = _serverUrl.endsWith('/')
              ? _serverUrl.substring(0, _serverUrl.length - 1)
              : _serverUrl;
          ok = await NIP98FileManager.delete(
            nostr!,
            '$deleteUrl/$sha256',
          );
        }
        if (ok) {
          setState(() {
            _files.removeWhere((f) => f.sha256 == sha256);
            _selected.remove(sha256);
          });
        } else {
          failed++;
        }
      }
      if (failed > 0 && mounted) {
        BotToast.showText(text: 'Failed to delete $failed item(s)');
      }
    } finally {
      cancel();
    }
  }

  void _toggleSelect(String sha256) {
    setState(() {
      if (_selected.contains(sha256)) {
        _selected.remove(sha256);
      } else {
        _selected.add(sha256);
      }
    });
  }

  void _confirmSelection() {
    final chosen = _files.where((f) => _selected.contains(f.sha256)).toList();
    RouterUtil.back(context, chosen);
  }

  static String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
    }
    return '${(bytes / 1024 / 1024 / 1024).toStringAsFixed(1)} GB';
  }

  static String _formatDate(int unix) {
    final dt = DateTime.fromMillisecondsSinceEpoch(unix * 1000);
    return '${dt.year}-'
        '${dt.month.toString().padLeft(2, '0')}-'
        '${dt.day.toString().padLeft(2, '0')}';
  }

  static bool _isImage(String type) => type.startsWith('image/');

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final cardColor = themeData.cardColor;
    final hintColor = themeData.hintColor;
    final mainColor = themeData.primaryColor;
    final s = S.of(context);
    final maxHeight = mediaDataCache.size.height * 0.85;

    Widget body;
    if (_loading) {
      body = const Padding(
        padding: EdgeInsets.all(40),
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (_error != null) {
      body = Padding(
        padding: const EdgeInsets.all(40),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: hintColor, size: 40),
              const SizedBox(height: 8),
              Text(_error!, style: TextStyle(color: hintColor)),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: _fetchList,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    } else if (_files.isEmpty) {
      body = Padding(
        padding: const EdgeInsets.all(40),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off, color: hintColor, size: 40),
              const SizedBox(height: 8),
              Text('No files', style: TextStyle(color: hintColor)),
            ],
          ),
        ),
      );
    } else {
      body = ListView.separated(
        shrinkWrap: true,
        physics: const ClampingScrollPhysics(),
        itemCount: _files.length,
        separatorBuilder: (_, __) =>
            Divider(height: 1, color: hintColor.withOpacity(0.15)),
        itemBuilder: (_, i) => _buildFileItem(_files[i], themeData),
      );
    }

    Widget? bottomBar;
    if (_selected.isNotEmpty) {
      bottomBar = Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Base.BASE_PADDING,
          vertical: Base.BASE_PADDING_HALF,
        ),
        decoration: BoxDecoration(
          color: cardColor,
          border: Border(
            top: BorderSide(color: hintColor.withOpacity(0.15)),
          ),
        ),
        child: Row(
          children: [
            Text(
              '${_selected.length} selected',
              style: TextStyle(color: hintColor),
            ),
            const Spacer(),
            TextButton.icon(
              icon: const Icon(Icons.delete_outline),
              label: Text(s.Delete),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: _deleteSelected,
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.check),
              label: Text(s.Confirm),
              style: ElevatedButton.styleFrom(backgroundColor: mainColor),
              onPressed: _confirmSelection,
            ),
          ],
        ),
      );
    }

    final content = Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(color: cardColor),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Base.BASE_PADDING,
              vertical: Base.BASE_PADDING_HALF,
            ),
            child: Row(
              children: [
                const Icon(Icons.cloud, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _storageLabel,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh',
                  onPressed: _fetchList,
                ),
                IconButton(
                  icon: const Icon(Icons.upload_file),
                  tooltip: 'Upload',
                  onPressed: _upload,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: s.close,
                  onPressed: () => RouterUtil.back(context),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: hintColor.withOpacity(0.2)),
          // List
          Flexible(child: SingleChildScrollView(child: body)),
          // Bottom action bar
          if (bottomBar != null) bottomBar,
        ],
      ),
    );

    return Scaffold(
      backgroundColor: ThemeUtil.getDialogCoverColor(themeData),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => RouterUtil.back(context),
        child: SizedBox.expand(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Base.BASE_PADDING),
            child: Center(
              child: GestureDetector(
                onTap: () {},
                child: content,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFileItem(CloudFile file, ThemeData themeData) {
    final hintColor = themeData.hintColor;
    final isSelected = _selected.contains(file.sha256);

    final sha256Short = file.sha256.length > 18
        ? '${file.sha256.substring(0, 12)}…${file.sha256.substring(file.sha256.length - 6)}'
        : file.sha256;

    final meta = [
      file.type.split('/').last,
      _formatSize(file.size),
      if (file.uploaded > 0) _formatDate(file.uploaded),
    ].join('  •  ');

    Widget thumbnail;
    if (_isImage(file.type)) {
      thumbnail = ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: CachedNetworkImage(
          imageUrl: file.url,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) => _fileIcon(file.type, hintColor),
        ),
      );
    } else {
      thumbnail = _fileIcon(file.type, hintColor);
    }

    return InkWell(
      onTap: () => _toggleSelect(file.sha256),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Base.BASE_PADDING,
          vertical: Base.BASE_PADDING_HALF,
        ),
        child: Row(
          children: [
            Checkbox(
              value: isSelected,
              onChanged: (_) => _toggleSelect(file.sha256),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            const SizedBox(width: 8),
            thumbnail,
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    sha256Short,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    meta,
                    style: TextStyle(fontSize: 11, color: hintColor),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.copy, size: 18),
              tooltip: 'Copy URL',
              onPressed: () {
                Clipboard.setData(ClipboardData(text: file.url));
                BotToast.showText(text: 'Copied');
              },
            ),
            IconButton(
              icon: Icon(Icons.delete_outline,
                  size: 18, color: Colors.red.shade300),
              tooltip: S.of(context).Delete,
              onPressed: () => _deleteSingle(file),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fileIcon(String mimeType, Color color) {
    IconData icon;
    if (mimeType.startsWith('video/')) {
      icon = Icons.videocam_outlined;
    } else if (mimeType.startsWith('audio/')) {
      icon = Icons.audiotrack_outlined;
    } else if (mimeType.contains('pdf')) {
      icon = Icons.picture_as_pdf_outlined;
    } else {
      icon = Icons.insert_drive_file_outlined;
    }
    return Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(icon, color: color, size: 26),
    );
  }
}
