import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrService {
  Future<String> recogniseText(File imageFile) async {
    // Create an InputImage from the file
    final inputImage = InputImage.fromFile(imageFile);

    // Create a TextRecognizer instance
    final textRecognizer = TextRecognizer();

    // Process the image to get the recognized text
    final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);

    // Close the recognizer once done
    textRecognizer.close();

    // Join all text blocks into a single string for parsing
    return recognizedText.text;
  }
}
