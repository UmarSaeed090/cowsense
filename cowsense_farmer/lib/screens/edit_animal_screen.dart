import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/animal.dart';
import '../providers/animal_provider.dart';

class EditAnimalScreen extends StatefulWidget {
  final Animal animal;

  const EditAnimalScreen({
    super.key,
    required this.animal,
  });

  @override
  State<EditAnimalScreen> createState() => _EditAnimalScreenState();
}

class _EditAnimalScreenState extends State<EditAnimalScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _selectedSpecies;
  final List<String> _speciesList = [
    'Cattle',
    'Sheep',
    'Goat',
    'Horse',
    'Pig',
    'Poultry',
    'Other'
  ];

  // Form fields
  late final TextEditingController _idController;
  late final TextEditingController _nameController;
  late final TextEditingController _ageController;
  late final TextEditingController _weightController;
  late final TextEditingController _identificationMarkController;
  bool _isLoading = false;

  // Image picker
  final ImagePicker _picker = ImagePicker();
  File? _imageFile;
  String? _currentImageUrl;

  @override
  void initState() {
    super.initState();
    _selectedSpecies = widget.animal.species;
    _idController = TextEditingController(text: widget.animal.tagNumber);
    _nameController = TextEditingController(text: widget.animal.name);
    _ageController = TextEditingController(text: widget.animal.age.toString());
    _weightController =
        TextEditingController(text: widget.animal.weight.toString());
    _identificationMarkController =
        TextEditingController(text: widget.animal.identificationMark);
    _currentImageUrl = widget.animal.imageUrl;
  }

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _identificationMarkController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _imageFile = File(image.path);
          _currentImageUrl =
              null; // Clear the current URL when new image is selected
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final animalProvider = Provider.of<AnimalProvider>(context, listen: false);
    setState(() {
      _isLoading = true;
    });

    final updatedAnimal = widget.animal.copyWith(
      tagNumber: _idController.text,
      name: _nameController.text,
      species: _selectedSpecies,
      age: int.parse(_ageController.text),
      weight: double.parse(_weightController.text),
      identificationMark: _identificationMarkController.text,
    );

    try {
      await animalProvider.updateAnimal(updatedAnimal,
          newImageFile: _imageFile);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Animal updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update animal: $e'),
            backgroundColor: Color(0xFFCB2213),
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Animal'),
        backgroundColor: Color(0xFFCB2213),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Photo upload section
                Center(
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      children: [
                        Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            shape: BoxShape.circle,
                            border:
                                Border.all(color: Color(0xFFCB2213), width: 2),
                            image: _imageFile != null
                                ? DecorationImage(
                                    image: FileImage(_imageFile!),
                                    fit: BoxFit.cover,
                                  )
                                : _currentImageUrl != null
                                    ? DecorationImage(
                                        image: NetworkImage(_currentImageUrl!),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                          ),
                          child:
                              (_imageFile == null && _currentImageUrl == null)
                                  ? const Center(
                                      child: Icon(
                                        Icons.add_a_photo,
                                        size: 50,
                                        color: Color(0xFFCB2213),
                                      ),
                                    )
                                  : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              color: Color(0xFFCB2213),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.add,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                const Text(
                  "Animal Information",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Color(0xFFCB2213),
                  ),
                ),
                const SizedBox(height: 16),

                // Animal ID
                TextFormField(
                  controller: _idController,
                  decoration: _inputDecoration(
                    label: 'Animal ID',
                    icon: Icons.tag,
                    hint: 'Enter unique ID',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter animal ID';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Animal Name
                TextFormField(
                  controller: _nameController,
                  decoration: _inputDecoration(
                    label: 'Name',
                    icon: Icons.pets,
                    hint: 'Enter animal name',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter animal name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Species Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedSpecies,
                  decoration: _inputDecoration(
                    label: 'Species',
                    icon: Icons.category,
                    hint: 'Select species',
                  ),
                  items: _speciesList
                      .map((species) => DropdownMenuItem(
                            value: species,
                            child: Text(species),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedSpecies = value;
                      });
                    }
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select species';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Row for Age and Weight
                Row(
                  children: [
                    // Age Field
                    Expanded(
                      child: TextFormField(
                        controller: _ageController,
                        keyboardType: TextInputType.number,
                        decoration: _inputDecoration(
                          label: 'Age (months)',
                          icon: Icons.calendar_today,
                          hint: 'Age',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Required';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Enter valid number';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Weight Field
                    Expanded(
                      child: TextFormField(
                        controller: _weightController,
                        keyboardType: TextInputType.number,
                        decoration: _inputDecoration(
                          label: 'Weight (kg)',
                          icon: Icons.monitor_weight_outlined,
                          hint: 'Weight',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Required';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Enter valid number';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Identification Mark (Optional)
                TextFormField(
                  controller: _identificationMarkController,
                  maxLines: 2,
                  decoration: _inputDecoration(
                    label: 'Identification Mark (Optional)',
                    icon: Icons.fingerprint,
                    hint: 'Any distinctive features',
                  ),
                ),
                const SizedBox(height: 32),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFCB2213),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'UPDATE ANIMAL',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    required String hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: Color(0xFFCB2213)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFCB2213), width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade400),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
    );
  }
}
