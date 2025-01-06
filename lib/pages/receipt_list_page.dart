import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../services/oss_upload_service.dart';
import '../widgets/signed_image.dart';
import 'image_upload_test_page.dart';
import 'receipt_detail_page.dart';

class ReceiptListPage extends StatefulWidget {
  const ReceiptListPage({super.key});

  @override
  State<ReceiptListPage> createState() => _ReceiptListPageState();
}

class _ReceiptListPageState extends State<ReceiptListPage> {
  final DatabaseService _db = DatabaseService.instance;
  final OssUploadService _ossService = OssUploadService();
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _receipts = [];
  bool _isLoading = true;
  Map<String, String> _signedUrls = {};

  @override
  void initState() {
    super.initState();
    _loadReceipts();
  }

  Future<void> _loadReceipts() async {
    setState(() => _isLoading = true);
    try {
      // 1. 加载收据列表
      final receipts = await _db.getAllReceipts();
      
      // 2. 提取所有objectKeys
      final objectKeys = receipts
          .map((r) => _getObjectKeyFromUrl(r['image_url']))
          .toList();
      
      // 3. 批量获取签名URLs
      final urls = await _ossService.getBatchSignedUrls(objectKeys);
      
      if (mounted) {
        setState(() {
          _receipts = receipts;
          _signedUrls = urls;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载失败: $e')),
        );
      }
    }
  }

  Future<void> _searchReceipts(String query) async {
    setState(() => _isLoading = true);
    try {
      // 1. 搜索收据
      final receipts = await _db.searchReceipts(query);
      
      // 2. 提取所有objectKeys
      final objectKeys = receipts
          .map((r) => _getObjectKeyFromUrl(r['image_url']))
          .toList();
      
      // 3. 批量获取签名URLs
      final urls = await _ossService.getBatchSignedUrls(objectKeys);
      
      if (mounted) {
        setState(() {
          _receipts = receipts;
          _signedUrls = urls;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('搜索失败: $e')),
        );
      }
    }
  }

  String _formatDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormat('yyyy-MM-dd HH:mm').format(date);
  }

  String _getObjectKeyFromUrl(String url) {
    final uri = Uri.parse(url);
    return uri.path.startsWith('/') ? uri.path.substring(1) : uri.path;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('收据列表'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_photo_alternate),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ImageUploadTestPage(),
                ),
              );
              if (result == true) {
                _loadReceipts();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '搜索收据...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _loadReceipts();
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (value) {
                if (value.isEmpty) {
                  _loadReceipts();
                } else {
                  _searchReceipts(value);
                }
              },
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _receipts.isEmpty
                    ? const Center(child: Text('暂无收据'))
                    : ListView.builder(
                        itemCount: _receipts.length,
                        itemBuilder: (context, index) {
                          final receipt = _receipts[index];
                          final objectKey = _getObjectKeyFromUrl(receipt['image_url']);
                          final signedUrl = _signedUrls[objectKey];
                          
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 8.0,
                              vertical: 4.0,
                            ),
                            child: ListTile(
                              leading: Hero(
                                tag: 'receipt_image_${receipt['id']}',
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: signedUrl != null
                                      ? Image.network(
                                          signedUrl,
                                          width: 60,
                                          height: 60,
                                          fit: BoxFit.cover,
                                          headers: const {
                                            'Accept': '*/*',
                                          },
                                          errorBuilder: (context, error, stackTrace) {
                                            return Container(
                                              width: 60,
                                              height: 60,
                                              color: Colors.grey[300],
                                              child: const Icon(
                                                Icons.error_outline,
                                                color: Colors.red,
                                              ),
                                            );
                                          },
                                        )
                                      : Container(
                                          width: 60,
                                          height: 60,
                                          color: Colors.grey[200],
                                          child: const Center(
                                            child: SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            ),
                                          ),
                                        ),
                                ),
                              ),
                              title: Text(
                                receipt['title'] ?? '未命名收据',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (receipt['description'] != null)
                                    Text(
                                      receipt['description'],
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  Text(
                                    _formatDate(receipt['created_at']),
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ReceiptDetailPage(
                                      receipt: receipt,
                                      signedUrl: signedUrl,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
