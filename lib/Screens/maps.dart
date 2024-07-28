import 'package:flutter/material.dart';


class WalletScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: Text('Movimientos'),
          ),
          body: Center(
            child: Text(
              'MUY PRONTO',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}

void main() {
  runApp(WalletScreen());
}
