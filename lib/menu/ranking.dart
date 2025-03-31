import 'package:flutter/material.dart';

import '../Utils/styles.dart';

class RankingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ubicación de la solicitud'),
      ),
      body: Center(
        child: Text(
          'Ranking',
          style: MyTextStyles.buttonTextStyle,
        ),
      ),
    );
  }
}
