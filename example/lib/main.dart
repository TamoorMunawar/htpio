import 'package:flutter/material.dart';
import 'package:htpio/htpio.dart';

/// One client for the whole app.
final htpio = HtpioClient(
  baseUrl: 'https://dummyjson.com',
  timeout: const Duration(seconds: 15),
  interceptors: [
    RetryInterceptor(maxRetries: 2),
    HtpioLogInterceptor(),
  ],
);

class Product {
  Product({required this.id, required this.title, required this.price});

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id'] as int,
        title: json['title'] as String,
        price: (json['price'] as num).toDouble(),
      );

  final int id;
  final String title;
  final double price;
}

/// The API layer: one method per endpoint.
class ProductApi {
  Future<List<Product>> search(String query, {CancelToken? cancelToken}) async {
    final res = await htpio.get<List<Product>>(
      '/products/search',
      queryParameters: {'q': query, 'limit': 20},
      cancelToken: cancelToken,
      decoder: (data) => [
        for (final item in data['products'] as List)
          Product.fromJson(item as Map<String, dynamic>),
      ],
    );
    return res.data;
  }
}

void main() => runApp(const MaterialApp(home: ProductsPage()));

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  final _api = ProductApi();
  CancelToken? _pending;
  List<Product> _products = [];
  String? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _search('phone');
  }

  Future<void> _search(String query) async {
    _pending?.cancel(); // drop the previous search while typing
    final token = _pending = CancelToken();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final products = await _api.search(query, cancelToken: token);
      setState(() => _products = products);
    } on HtpioError catch (e) {
      if (e.type == HtpioErrorType.cancel) return;
      setState(() => _error = switch (e.type) {
            HtpioErrorType.timeout => 'The server is slow. Try again.',
            HtpioErrorType.connectionError => 'No internet connection.',
            HtpioErrorType.badResponse => 'Server error (${e.statusCode}).',
            _ => 'Something went wrong.',
          });
    } finally {
      if (identical(token, _pending)) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('htpio example')),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Search products',
                  ),
                  onChanged: _search,
                ),
              ),
              if (_loading) const LinearProgressIndicator(),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child:
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                ),
              Expanded(
                child: ListView.builder(
                  itemCount: _products.length,
                  itemBuilder: (context, i) => ListTile(
                    title: Text(_products[i].title),
                    trailing: Text('\$${_products[i].price}'),
                  ),
                ),
              ),
            ],
          ),
          DebugConsole().overlay(lines: 3),
        ],
      ),
    );
  }
}
