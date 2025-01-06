import 'package:flutter/material.dart';
import '../models/receipt.dart';
import '../services/database_helper.dart';
import 'package:intl/intl.dart';
import 'camera_page.dart';

class ReceiptListPage extends StatefulWidget {
  const ReceiptListPage({super.key});

  @override
  State<ReceiptListPage> createState() => _ReceiptListPageState();
}

class _ReceiptListPageState extends State<ReceiptListPage> {
  final List<Receipt> _receipts = [];
  bool _isLoading = false;
  final _dateFormat = DateFormat('yyyy-MM-dd');
  final _currencyFormat = NumberFormat.currency(locale: 'zh_CN', symbol: '¥');

  @override
  void initState() {
    super.initState();
    _loadReceipts();
  }

  Future<void> _loadReceipts() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: 替换为实际的用户ID
      final receipts = await DatabaseHelper.instance.getReceipts('test_user');
      setState(() {
        _receipts.clear();
        _receipts.addAll(receipts);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load receipts: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的票据'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // TODO: 实现筛选功能
            },
            tooltip: '筛选',
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: 实现搜索功能
            },
            tooltip: '搜索',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadReceipts,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _receipts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long,
                          size: 64,
                          color: Theme.of(context).disabledColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '没有票据',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '点击下方按钮添加票据',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _receipts.length,
                    itemBuilder: (context, index) {
                      final receipt = _receipts[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: InkWell(
                          onTap: () {
                            // TODO: 导航到票据详情页
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        receipt.merchantName,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      _currencyFormat
                                          .format(receipt.totalAmount),
                                      style:
                                          Theme.of(context).textTheme.titleLarge,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _dateFormat.format(receipt.receiptDate),
                                      style:
                                          Theme.of(context).textTheme.bodyMedium,
                                    ),
                                    Text(
                                      receipt.currency,
                                      style:
                                          Theme.of(context).textTheme.bodyMedium,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CameraPage(),
            ),
          ).then((value) {
            if (value == true) {
              // 如果拍照成功，刷新票据列表
              _loadReceipts();
            }
          });
        },
        tooltip: '添加票据',
        child: const Icon(Icons.add_a_photo),
      ),
    );
  }
}
