// import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';

// class QrCodeFunctions {
//   static Future<String> scanQR() async {
//     try {
//       String code = await FlutterBarcodeScanner.scanBarcode(
//           '#003772', 'Cancel', true, ScanMode.QR);
//       if (code == '-1') {
//         // '-1' means the user canceled the scan
//         return '';
//       }
//       print('code Is $code');
//       // return the code in successful scan
//       return code;
//     } catch (e) {
//       print(e);
//       // Return an empty string on error
//       return '';
//     }
//   }
// }
