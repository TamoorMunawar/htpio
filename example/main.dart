import 'package:flutter/material.dart';
import 'package:htpio/htpio.dart';

// Define the Product model
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
      price: json['price'] as double,
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

  // Fetch dynamic data from the API using GET request
  Future<void> _fetchData() async {
    try {
      final response = await client.get<List<Product>>(
          'https://dummyjson.com/products',  // URL as a string
              (json) => (json['products'] as List)  // fromJson logic
              .map((item) => Product.fromJson(item))
              .toList(),
          headers: {}  // Headers, if any
      );

      setState(() {
        products = response.data;  // Store the fetched data
        result = 'Fetched ${response.data.length} products';  // Show number of products fetched
      });
    } catch (e) {
      setState(() => result = 'Error: $e');  // Handle any error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Htpio Example')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(result),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _fetchData,
            child: const Text('Fetch Products'),
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
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Text(product.title),
                          // Add other product details here
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
