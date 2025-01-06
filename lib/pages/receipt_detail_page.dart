import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ReceiptDetailPage extends StatelessWidget {
  final Map<String, dynamic> receipt;
  final String? signedUrl;

  const ReceiptDetailPage({
    Key? key,
    required this.receipt,
    required this.signedUrl,
  }) : super(key: key);

  String _formatDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormat('yyyy-MM-dd HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(receipt['title'] ?? '收据详情'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // TODO: 实现编辑功能
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              // TODO: 实现删除功能
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: 'receipt_image_${receipt['id']}',
              child: signedUrl != null
                  ? Image.network(
                      signedUrl!,
                      width: double.infinity,
                      height: MediaQuery.of(context).size.width * 4 / 3,
                      fit: BoxFit.contain,
                      headers: const {
                        'Accept': '*/*',
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: double.infinity,
                          height: MediaQuery.of(context).size.width * 4 / 3,
                          color: Colors.grey[300],
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: Colors.red,
                                size: 48,
                              ),
                              SizedBox(height: 16),
                              Text('图片加载失败'),
                            ],
                          ),
                        );
                      },
                    )
                  : Container(
                      width: double.infinity,
                      height: MediaQuery.of(context).size.width * 4 / 3,
                      color: Colors.grey[200],
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (receipt['title'] != null) ...[
                    Text(
                      '标题',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      receipt['title'],
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (receipt['description'] != null) ...[
                    Text(
                      '描述',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      receipt['description'],
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 16),
                  ],
                  Text(
                    '创建时间',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(receipt['created_at']),
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
