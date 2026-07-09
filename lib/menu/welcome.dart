import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../ServiceResponse/post.dart';
import '../controllers/RegisController.dart';
import '../Screens/Validations.dart';
import '../ServiceResponse/get.dart';

class FirstTimeLoginScreen extends StatefulWidget {
  final RegistrationController registrationController;

  FirstTimeLoginScreen({required this.registrationController});

  @override
  State<FirstTimeLoginScreen> createState() => _FirstTimeLoginScreenState();
}

class _FirstTimeLoginScreenState extends State<FirstTimeLoginScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;
  late Animation<double> _scaleBtn;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeIn = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.2, 0.8, curve: Curves.easeOut),
    ));
    _scaleBtn = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.6, 1.0, curve: Curves.elasticOut),
      ),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // ── Sección Superior: Hero roja ──────────────────────────
          Expanded(
            flex: 10,
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF4A0609),
                    Color(0xFF830A09),
                    Color(0xFFA81215),
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(36),
                  bottomRight: Radius.circular(36),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    // AppBar
                    Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: 20.w, vertical: 12.h),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          FadeTransition(
                            opacity: _fadeIn,
                            child: Text(
                              'ManitoXpress',
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: 'Xpress',
                                fontWeight: FontWeight.w700,
                                fontStyle: FontStyle.italic,
                                fontSize: 20.sp,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          FadeTransition(
                            opacity: _fadeIn,
                            child: Container(
                              padding: EdgeInsets.all(8.w),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Image.asset(
                                'assets/images/LOGO1_Blanco.png',
                                width: 0.12.sw,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Imagen hero
                    Expanded(
                      child: FadeTransition(
                        opacity: _fadeIn,
                        child: SlideTransition(
                          position: _slideUp,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 0.60.sw,
                                height: 0.60.sw,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.07),
                                ),
                              ),
                              Container(
                                width: 0.46.sw,
                                height: 0.46.sw,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.10),
                                ),
                              ),
                              Image.asset(
                                'assets/images/manito.png',
                                width: 0.46.sw,
                                fit: BoxFit.contain,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Sección Inferior: Card blanca ────────────────────────
          Expanded(
            flex: 9,
            child: SlideTransition(
              position: _slideUp,
              child: FadeTransition(
                opacity: _fadeIn,
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding:
                      EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Chip de bienvenida
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFF830A09).withOpacity(0.09),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '¡Hola, profesional! 👋',
                          style: TextStyle(
                            color: const Color(0xFF830A09),
                            fontFamily: 'Xpress',
                            fontWeight: FontWeight.w700,
                            fontSize: 12.sp,
                          ),
                        ),
                      ),
                      SizedBox(height: 12.h),

                      // Título
                      Text(
                        '¡Bienvenido\na ManitoXpress!',
                        style: TextStyle(
                          color: const Color(0xFF1A1A1A),
                          fontFamily: 'Xpress',
                          fontWeight: FontWeight.w700,
                          fontStyle: FontStyle.italic,
                          fontSize: 28.sp,
                          height: 1.2,
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(height: 8.h),

                      // Subtítulo
                      Text(
                        'Únete a nuestra red de profesionales y\ncomienza a ofrecer tus servicios hoy.',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontFamily: 'Xpress',
                          fontWeight: FontWeight.w400,
                          fontSize: 13.sp,
                          height: 1.5,
                        ),
                      ),
                      SizedBox(height: 20.h),

                      // Badges informativos
                      Row(
                        children: [
                          _buildBadge(Icons.list_alt_outlined, '7 pasos'),
                          SizedBox(width: 10.w),
                          _buildBadge(Icons.timer_outlined, '5 min'),
                          SizedBox(width: 10.w),
                          _buildBadge(Icons.verified_outlined, 'Gratis'),
                        ],
                      ),
                      SizedBox(height: 24.h),

                      // CTA Button
                      ScaleTransition(
                        scale: _scaleBtn,
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              widget.registrationController.nextStep();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => RegistrationScreen(
                                    registrationController:
                                        widget.registrationController,
                                    completeRegistrationCallback: () {},
                                    apiService2: ApiService2(),
                                    apiService: ApiService(),
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF830A09),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 3,
                                shadowColor: const Color(0xFF830A09)
                                  .withOpacity(0.4),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Comenzar registro',
                                  style: TextStyle(
                                    fontFamily: 'Xpress',
                                    fontWeight: FontWeight.w700,
                                    fontStyle: FontStyle.italic,
                                    fontSize: 16.sp,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(IconData icon, String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFF830A09), size: 14),
          SizedBox(width: 5.w),
          Text(
            label,
            style: TextStyle(
              color: const Color(0xFF1A1A1A),
              fontFamily: 'Xpress',
              fontWeight: FontWeight.w600,
              fontSize: 12.sp,
            ),
          ),
        ],
      ),
    );
  }
}
