import 'dart:convert';
import 'dart:io';
import 'package:cowsense/models/animal.dart';
import 'package:cowsense/widgets/loader_animation_widget.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../providers/animal_provider.dart';
import 'disease_history_screen.dart';

class DiseaseDetectionScreen extends StatefulWidget {
  final Animal animal;
  const DiseaseDetectionScreen({Key? key, required this.animal})
      : super(key: key);

  @override
  State<DiseaseDetectionScreen> createState() => _DiseaseDetectionScreenState();
}

class _DiseaseDetectionScreenState extends State<DiseaseDetectionScreen>
    with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  String? _annotatedImageUrl;
  List<PredictionResult> _predictions = [];
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';

  // Animation controller for results display
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;

  // Hugging Face API endpoint for cowsense-disease-detector
  final String apiBaseUrl =
      'https://maliktayab-cowsense-disease-detector.hf.space';
  final String apiPredictEndpoint = '/gradio_api/call/predict';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeInAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
        _annotatedImageUrl = null;
        _predictions = [];
        _hasError = false;
      });

      _processImage();
    }
  }

  Future<void> _takePicture() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);

    if (photo != null) {
      setState(() {
        _selectedImage = File(photo.path);
        _annotatedImageUrl = null;
        _predictions = [];
        _hasError = false;
      });

      _processImage();
    }
  }

  Future<String> _uploadImageToTempUrl(File imageFile) async {
    const String imgbbApiKey = '684ae5862d9aa7adc8633960abc13ece';

    try {
      List<int> imageBytes = await imageFile.readAsBytes();
      String base64Image = base64Encode(imageBytes);

      var response = await http.post(
        Uri.parse('https://api.imgbb.com/1/upload'),
        body: {
          'key': imgbbApiKey,
          'image': base64Image,
        },
      );

      if (response.statusCode == 200) {
        var jsonResponse = json.decode(response.body);
        debugPrint(
            "Image uploaded successfully. URL: ${jsonResponse['data']['url']}");
        return jsonResponse['data']['url'];
      } else {
        throw Exception('Failed to upload image: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error uploading image: $e');
    }
  }

  Future<void> _processImage() async {
    if (_selectedImage == null) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      String imageUrl = await _uploadImageToTempUrl(_selectedImage!);
      var requestUrl = Uri.parse('$apiBaseUrl$apiPredictEndpoint');
      var requestBody = jsonEncode({
        "data": [
          {
            "path": imageUrl,
            "meta": {"_type": "gradio.FileData"}
          }
        ]
      });

      // Add headers
      var headers = {
        'Content-Type': 'application/json',
      };
      // Send POST request
      var postResponse = await http.post(
        requestUrl,
        headers: headers,
        body: requestBody,
      );

      if (postResponse.statusCode != 200) {
        throw Exception(
            'Failed to initiate prediction: ${postResponse.statusCode} - ${postResponse.body}');
      }

      // Parse the response
      var postResponseData = json.decode(postResponse.body);
      String eventId = postResponseData['event_id'] ?? '';

      if (eventId.isEmpty) {
        throw Exception(
            'No event ID received in response: ${postResponse.body}');
      }
      var getUrl = Uri.parse('$apiBaseUrl$apiPredictEndpoint/$eventId');
      // Create a new client for streaming
      var client = http.Client();
      var request = http.Request('GET', getUrl);
      request.headers.addAll(headers);

      var streamedResponse = await client.send(request);
      var responseStream = streamedResponse.stream.transform(utf8.decoder);

      String currentEvent = '';
      String currentData = '';
      bool isComplete = false;

      await for (var chunk in responseStream) {
        // Split the chunk into lines
        var lines = chunk.split('\n');

        for (var line in lines) {
          if (line.startsWith('event: ')) {
            currentEvent = line.substring(7).trim();
          } else if (line.startsWith('data: ')) {
            currentData = line.substring(6).trim();

            if (currentEvent == 'complete') {
              isComplete = true;
              try {
                var data = json.decode(currentData);
                if (data is List && data.length >= 2) {
                  var annotatedImageData = data[0];
                  var predictionText = data[1];
                  if (annotatedImageData == null) {
                    throw Exception(
                        'Received null annotated image data from API');
                  }

                  // Extract the URL from the annotated image data
                  String annotatedImageUrl = annotatedImageData['url'] ?? '';
                  if (annotatedImageUrl.isEmpty) {
                    throw Exception('No URL found in annotated image data');
                  }

                  final predictions = _parsePredictionText(predictionText);
                  setState(() {
                    _isLoading = false;
                    _annotatedImageUrl = annotatedImageUrl;
                    _predictions = predictions;
                  });

                  _animationController.reset();
                  _animationController.forward();

                  // Get prediction results
                  if (predictions.isNotEmpty) {
                    final prediction = predictions.first;

                    // If disease is detected, store the results
                    if (prediction.label.isNotEmpty) {
                      final animalProvider =
                          Provider.of<AnimalProvider>(context, listen: false);

                      // Store the annotated image in Firebase Storage
                      final storedImageUrl = await animalProvider
                          .storeAnnotatedImage(annotatedImageUrl);

                      // Store the disease detection results
                      animalProvider.storeDiseaseDetection(
                        animalId: widget.animal.id!,
                        animalTagNumber: widget.animal.tagNumber,
                        diseaseName: prediction.label,
                        confidence: prediction.confidence,
                        annotatedImageUrl: storedImageUrl,
                      );
                    }
                  }
                }
              } catch (e) {
                debugPrint("Error parsing complete event data: $e");
                throw Exception('Invalid data in complete event: $e');
              }
            } else if (currentEvent == 'error') {
              throw Exception('API returned error: $currentData');
            }
          }
        }
      }

      if (!isComplete) {
        throw Exception('Stream ended without receiving complete event');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Error: $e';
      });
    } finally {
      _isLoading = false;
    }
  }

  // Helper method to parse prediction text into structured data
  List<PredictionResult> _parsePredictionText(String predictionText) {
    List<PredictionResult> results = [];
    final RegExp diseasePattern = RegExp(r'Disease:\s*(\w+)');
    final RegExp confidencePattern = RegExp(r'Confidence:\s*([\d.]+)');

    String disease = diseasePattern.firstMatch(predictionText)?.group(1) ?? '';
    String confidenceStr =
        confidencePattern.firstMatch(predictionText)?.group(1) ?? '0';

    double confidence = double.tryParse(confidenceStr) ?? 0;

    if (disease.isNotEmpty) {
      results.add(PredictionResult(
        label: disease,
        confidence: confidence,
      ));
    }

    return results;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Disease Detection'),
        elevation: 2,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'View Disease History',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      DiseaseHistoryScreen(animal: widget.animal),
                ),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[900]!
                  : Colors.blue[50]!,
              Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[800]!
                  : Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Upload button area
              Container(
                padding: const EdgeInsets.all(16),
                child: _selectedImage == null
                    ? _buildUploadArea()
                    : _buildImagePreview(),
              ),

              // Results area
              Expanded(
                child: _isLoading
                    ? LoaderAnimationWidget()
                    : _hasError
                        ? _buildErrorWidget()
                        : _annotatedImageUrl != null
                            ? _buildResults()
                            : _buildInstructions(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUploadArea() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_upload_outlined,
              size: 64,
              color: Colors.blue,
            ),
            const SizedBox(height: 16),
            const Text(
              'Select or capture an image to analyze',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Gallery'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _takePicture,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Camera'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            _selectedImage!,
            width: double.infinity,
            height: 200,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          bottom: 8,
          right: 8,
          child: CircleAvatar(
            backgroundColor: Colors.black54,
            child: IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: () {
                setState(() {
                  _selectedImage = null;
                  _annotatedImageUrl = null;
                  _predictions = [];
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  // Widget _buildLoadingIndicator() {
  //   return Center(
  //     child: Column(
  //       mainAxisAlignment: MainAxisAlignment.center,
  //       children: [
  //         const CircularProgressIndicator(),
  //         const SizedBox(height: 24),
  //         const Text(
  //           'Processing image...',
  //           style: TextStyle(
  //             fontSize: 18,
  //             fontWeight: FontWeight.w500,
  //           ),
  //         ),
  //         const SizedBox(height: 8),
  //         const Text(
  //           'This may take a moment',
  //           style: TextStyle(
  //             fontSize: 14,
  //             color: Colors.grey,
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Color(0xFFCB2213),
            ),
            const SizedBox(height: 16),
            const Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              style: const TextStyle(
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _selectedImage != null ? _processImage : _pickImage,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    return FadeTransition(
      opacity: _fadeInAnimation,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Annotated image
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Annotated Result',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: _annotatedImageUrl!,
                        placeholder: (context, url) => const Center(
                          child: CircularProgressIndicator(),
                        ),
                        errorWidget: (context, url, error) => const Center(
                          child: Icon(Icons.error, color: Color(0xFFCB2213)),
                        ),
                        fit: BoxFit.contain,
                        width: double.infinity,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Predictions
            if (_predictions.isNotEmpty) ...[
              Text(
                'Detection Results (${_predictions.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _predictions.length,
                itemBuilder: (context, index) {
                  final prediction = _predictions[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue.withOpacity(0.2),
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        prediction.label,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        'Confidence: ${(prediction.confidence * 100).toStringAsFixed(1)}%',
                      ),
                      trailing:
                          _buildConfidenceIndicator(prediction.confidence),
                    ),
                  );
                },
              ),
            ],

            const SizedBox(height: 24),

            // Analyze another image button
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedImage = null;
                    _annotatedImageUrl = null;
                    _predictions = [];
                  });
                },
                icon: const Icon(Icons.add_photo_alternate),
                label: const Text('Analyze Another Image'),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfidenceIndicator(double confidence) {
    Color indicatorColor;
    if (confidence >= 0.8) {
      indicatorColor = Colors.green;
    } else if (confidence >= 0.5) {
      indicatorColor = Colors.orange;
    } else {
      indicatorColor = Color(0xFFCB2213);
    }

    return Container(
      width: 60,
      height: 24,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: indicatorColor.withOpacity(0.2),
      ),
      child: Center(
        child: Text(
          '${(confidence * 100).toStringAsFixed(0)}%',
          style: TextStyle(
            color: indicatorColor,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildInstructions() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_search,
              size: 80,
              color: Colors.grey.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            const Text(
              'Select an image to start',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'We\'ll analyze your image and show predictions with detailed results',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// Model for prediction results
class PredictionResult {
  final String label;
  final double confidence;
  final Map<String, dynamic>? boundingBox; // Optional, depending on your model

  PredictionResult({
    required this.label,
    required this.confidence,
    this.boundingBox,
  });

  factory PredictionResult.fromJson(Map<String, dynamic> json) {
    return PredictionResult(
      label: json['label'] ?? '',
      confidence: json['confidence'] ?? 0.0,
      boundingBox: json['bounding_box'],
    );
  }
}
