import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:dart_des/dart_des.dart';

String decryptSaavnUrl(String encryptedBase64) {
  final key = utf8.encode('38346591');
  final des = DES(key: key, mode: DESMode.ECB, paddingType: DESPaddingType.PKCS5);
  final encryptedBytes = base64.decode(encryptedBase64);
  final decryptedBytes = des.decrypt(encryptedBytes);
  final decrypted = utf8.decode(decryptedBytes);
  return decrypted.replaceAll(RegExp(r'_(96|160)\.mp4'), '_320.mp4');
}

void main() {
  test('dart_des decrypts Kesariya to valid 320kbps CDN URL', () {
    const encrypted = 'ID2ieOjCrwfgWvL5sXl4B1ImC5QfbsDyryhkSYK5IH2E7FCO52VR6yhNbcEbes5iCcja4+W8xhE0SwtCJToN4Bw7tS9a8Gtq';
    final url320 = decryptSaavnUrl(encrypted);
    expect(url320, 'https://aac.saavncdn.com/871/c2febd353f3a076a406fa37510f31f9f_320.mp4');
  });
}
