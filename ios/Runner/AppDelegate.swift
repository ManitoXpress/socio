import Flutter
import UIKit
import GoogleMaps
import FirebaseCore
import FirebaseFirestore
import CoreImage

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Inicializar Google Maps
    GMSServices.provideAPIKey("AIzaSyCSp5RbLBZKMLHT0RJH3Zk5JRXZ4LOrQYc")
    
    // Inicializar Firebase
    FirebaseApp.configure()
    
    // Acceder a Firestore
    do {
      let firestore = Firestore.firestore()
      print("Firestore inicializado: \(firestore)")
    } catch let error {
      print("Error al inicializar Firestore: \(error.localizedDescription)")
    }
    
    // Registrar los plugins generados
    GeneratedPluginRegistrant.register(with: self)
    
    // Registrar canal de detección de rostro
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let faceDetectionChannel = FlutterMethodChannel(name: "face_detection_channel",
                                              binaryMessenger: controller.binaryMessenger)
    faceDetectionChannel.setMethodCallHandler({
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      if call.method == "detectFace" {
        if let args = call.arguments as? [String: Any],
           let path = args["path"] as? String {
          let image = CIImage(contentsOf: URL(fileURLWithPath: path))
          let options: [String : Any] = [CIDetectorAccuracy: CIDetectorAccuracyHigh]
          let detector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: options)
          let features = detector?.features(in: image ?? CIImage())
          // Solo aceptamos si hay exactamente un rostro
          result((features?.count ?? 0) == 1)
        } else {
          result(false)
        }
      }
    })
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
