import 'package:cached_network_image/cached_network_image.dart';
import 'package:cowsense/screens/disease_detection_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../models/animal.dart';
import '../providers/animal_provider.dart';
import '../providers/auth_provider.dart';
import 'add_animal_screen.dart';
import 'edit_animal_screen.dart';
import 'animal_dashboard_screen.dart';
import 'hire_doctor_screen.dart';

class AnimalsScreen extends StatefulWidget {
  const AnimalsScreen({Key? key}) : super(key: key);

  @override
  State<AnimalsScreen> createState() => _AnimalsScreenState();
}

class _AnimalsScreenState extends State<AnimalsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortBy = 'name'; // Default sort
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Schedule the loading of animals for after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAnimals();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAnimals() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.isAuthenticated) {
      await Provider.of<AnimalProvider>(context, listen: false)
          .loadUserAnimals(authProvider.user!.uid);
    }
  }

  List<Animal> get filteredCows {
    final animalProvider = Provider.of<AnimalProvider>(context);
    var animals = animalProvider.animals;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      animals = animals.where((animal) {
        final searchLower = _searchQuery.toLowerCase();
        return animal.name.toLowerCase().contains(searchLower) ||
            animal.tagNumber.toLowerCase().contains(searchLower) ||
            animal.species.toLowerCase().contains(searchLower);
      }).toList();
    }

    // Apply sorting
    animals.sort((a, b) {
      int comparison;
      switch (_sortBy) {
        case 'name':
          comparison = a.name.compareTo(b.name);
          break;
        case 'tag':
          comparison = a.tagNumber.compareTo(b.tagNumber);
          break;
        case 'weight':
          comparison = a.weight.compareTo(b.weight);
          break;
        case 'age':
          comparison = a.age.compareTo(b.age);
          break;
        default:
          comparison = 0;
      }
      return _sortAscending ? comparison : -comparison;
    });

    return animals;
  }

  void _setSort(String sortBy) {
    setState(() {
      if (_sortBy == sortBy) {
        _sortAscending = !_sortAscending;
      } else {
        _sortBy = sortBy;
        _sortAscending = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
        title: const Text(
          'My Animals',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: () => _showSortOptions(context),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search animals...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      body: Consumer<AnimalProvider>(
        builder: (context, animalProvider, child) {
          if (animalProvider.isLoading) {
            return _buildLoadingShimmer();
          }

          if (animalProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 60,
                    color: Color(0xFFCB2213),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${animalProvider.error}',
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadAnimals,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final animals = filteredCows;

          if (animals.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_off,
                    size: 80,
                    color: Color(0xFFCB2213).withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _searchQuery.isEmpty
                        ? 'No animals registered yet'
                        : 'No animals match your search',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_searchQuery.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFCB2213),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 12),
                        ),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const AddAnimalScreen()),
                        ),
                        child: const Text('Add Your First Animal'),
                      ),
                    ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: Color(0xFFCB2213),
            onRefresh: _loadAnimals,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: ListView.builder(
                itemCount: animals.length,
                itemBuilder: (context, index) {
                  final animal = animals[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: _buildAnimalCard(animal),
                  );
                },
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color(0xFFCB2213),
        child: const Icon(Icons.add),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AddAnimalScreen()),
        ),
      ),
    );
  }

  Widget _buildAnimalCard(Animal animal) {
    final healthStatus = animal.healthStatus ?? 'Unknown';
    final Color statusColor = healthStatus == 'Healthy'
        ? Colors.green
        : healthStatus == 'Diseased'
            ? Color(0xFFCB2213)
            : Colors.orange;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AnimalDashboardScreen(animal: animal),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image and basic info
            Row(
              children: [
                // Animal image
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                  child: animal.imageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: animal.imageUrl!,
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                          errorWidget: (context, error, stackTrace) =>
                              Container(
                                width: 120,
                                height: 120,
                                color: Colors.grey[200],
                                child: const Icon(
                                  Icons.pets,
                                  size: 40,
                                  color: Colors.grey,
                                ),
                              ))
                      : Container(
                          width: 120,
                          height: 120,
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.pets,
                            size: 40,
                            color: Colors.grey,
                          ),
                        ),
                ),
                const SizedBox(width: 16),
                // Basic info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              animal.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              healthStatus,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'ID: ${animal.tagNumber}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Species: ${animal.species}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Divider
            const Divider(height: 1),
            // Action buttons
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildActionButton(
                      icon: Icons.medical_services,
                      label: "Hire Doctor",
                      color: Colors.blue,
                      onTap: () => _navigateToHireDoctorScreen(animal)),
                  _buildActionButton(
                      icon: Icons.image_search,
                      label: 'Disease Detection',
                      color: Colors.blue,
                      onTap: () => _navigateToDiseaseDetectionScreen(animal)),
                  _buildActionButton(
                    icon: Icons.edit_outlined,
                    label: 'Edit',
                    color: Colors.orange,
                    onTap: () => _navigateToEditScreen(animal),
                  ),
                  _buildActionButton(
                    icon: Icons.delete_outline,
                    label: 'Delete',
                    color: Color(0xFFCB2213),
                    onTap: () => _showDeleteConfirmation(animal),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToEditScreen(Animal animal) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditAnimalScreen(animal: animal),
      ),
    );
  }

  void _navigateToDiseaseDetectionScreen(Animal animal) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => DiseaseDetectionScreen(animal: animal)),
    );
  }

  void _navigateToHireDoctorScreen(Animal animal) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => HireDoctorScreen(animal: animal)),
    );
  }

  Future<void> _showDeleteConfirmation(Animal animal) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Animal'),
        content: Text('Are you sure you want to delete ${animal.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Color(0xFFCB2213)),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final animalProvider =
          Provider.of<AnimalProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      try {
        await animalProvider.deleteAnimal(animal.id!, authProvider.user!.uid);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Animal deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete animal: $e'),
              backgroundColor: Color(0xFFCB2213),
            ),
          );
        }
      }
    }
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: ListView.builder(
          itemCount: 3,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Container(
                height: 300,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showSortOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Sort By',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              ListTile(
                leading:
                    const Icon(Icons.sort_by_alpha, color: Color(0xFFCB2213)),
                title: const Text('Name'),
                onTap: () {
                  Navigator.pop(context);
                  _setSort('name');
                },
              ),
              ListTile(
                leading: const Icon(Icons.tag, color: Color(0xFFCB2213)),
                title: const Text('Tag Number'),
                onTap: () {
                  Navigator.pop(context);
                  _setSort('tag');
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.monitor_weight, color: Color(0xFFCB2213)),
                title: const Text('Weight'),
                onTap: () {
                  Navigator.pop(context);
                  _setSort('weight');
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.calendar_today, color: Color(0xFFCB2213)),
                title: const Text('Age'),
                onTap: () {
                  Navigator.pop(context);
                  _setSort('age');
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
