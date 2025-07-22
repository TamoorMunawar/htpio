// File: example/main.dart
import 'package:flutter/material.dart';
import 'package:htpio/htpio.dart';

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

  @override
  void initState() {
    super.initState();
    client.use(OfflineMode());
    client.addInterceptor(AuthTokenInterceptor()..token = '123token');
    client.addInterceptor(RetryInterceptor());
  }

  Future<void> _fetchData() async {
    try {
      final response = await client.send(HtpioRequest<String>(
        url: 'https://api.mock.com/data',
        cacheEnabled: true,
      ));
      setState(() => result = response.data);
    } catch (e) {
      setState(() => result = 'Error: $e');
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
            child: const Text('Send Request'),
          )
        ],
      ),
    );
  }
}
