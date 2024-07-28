import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class LoadingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.white,
        child: Center( // Ajustar imagen centrada
          child: Image.asset(
              'assets/pantallaTrabajador.png',
            width: 1.sw, // Ajustar a 100% del ancho de la pantalla
            height: 3.sh, // Ajustar a 150% de la altura de la pantalla
            fit: BoxFit.fill,
          ),
        ),
      ),
    );
  }
}
