import 'package:flutter/material.dart';
import 'package:htpio/htpio.dart';

class Product {
  final int id;
  final String title;
  final String description;
  final double price;

  Product({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String,
      price: (json['price'] as num).toDouble(),
    );
  }
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Htpio Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final HtpioClient client = HtpioClient();
  String result = '';
  List<Product> products = [];
  bool isLoading = false;

  Future<void> _fetchData() async {
    setState(() {
      isLoading = true;
      result = 'Loading...';
    });

    try {
      final response = await client.getRequest<List<Product>>(
        endpoint: 'https://dummyjson.com/products',
        fromJson: (json) {
          if (json.containsKey('products')) {
            return (json['products'] as List)
                .map((item) => Product.fromJson(item as Map<String, dynamic>))
                .toList();
          } else if (json.containsKey('data') && json['data'] is List) {
            return (json['data'] as List)
                .map((item) => Product.fromJson(item as Map<String, dynamic>))
                .toList();
          } else {
            return <Product>[];
          }
        },
        authToken: null,
      );

      setState(() {
        products = response.data;
        result = 'Successfully fetched ${response.data.length} products!';
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        result = 'Error: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Htpio Example'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              result,
              style: TextStyle(
                fontSize: 16,
                color: result.startsWith('Error') ? Colors.red : Colors.green,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isLoading ? null : _fetchData,
              child: isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Fetch Products'),
            ),
            const SizedBox(height: 20),
            if (products.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return Card(
                      margin: const EdgeInsets.all(8),
                      elevation: 5,
                      child: ListTile(
                        title: Text(product.title),
                        subtitle: Text(product.description),
                        trailing: Text(
                          '\$${product.price}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}


