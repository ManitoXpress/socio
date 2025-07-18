import '../controllers/RegisController.dart';
import '../ServiceResponse/requestUserData.dart';

class HomeData {
  final String displayName;
  final String email;
  final String phoneNumber;
  final String paymentType;
  final String verificationStatus;
  final List<String> expertises;
  final List<String> expLevel;
  final String imagePath;
  final UserData userData;
  final RegistrationData registrationData;
  final int points;

  HomeData({
    required this.displayName,
    required this.email,
    required this.phoneNumber,
    required this.paymentType,
    required this.verificationStatus,
    required this.expertises,
    required this.expLevel,
    required this.imagePath,
    required this.userData,
    required this.registrationData,
    required this.points,
  });
}
