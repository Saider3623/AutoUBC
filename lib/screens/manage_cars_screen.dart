import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../providers/app_provider.dart';

class ManageCarsScreen extends StatefulWidget {
  const ManageCarsScreen({super.key});

  @override
  State<ManageCarsScreen> createState() => _ManageCarsScreenState();
}

class _ManageCarsScreenState extends State<ManageCarsScreen> {
  final TextEditingController _addCarController = TextEditingController();
  final TextEditingController _newFuelController = TextEditingController();
  List<String> _localFuelTypes = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadCurrentCarData();
  }

  void _loadCurrentCarData() {
    final provider = Provider.of<AppProvider>(context, listen: false);
    if (provider.selectedCar != null) {
      _localFuelTypes =
          List.from(provider.selectedCar!.fuelTypes ?? ['ГАЗ', '95']);
    }
  }

  @override
  void dispose() {
    _addCarController.dispose();
    _newFuelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final appProvider = Provider.of<AppProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.carSettings),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () async {
              if (appProvider.selectedCar != null) {
                if (_localFuelTypes.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(loc.atLeastOneFuelType)),
                  );
                  return;
                }
                final navigator = Navigator.of(context);
                final car = appProvider.selectedCar!;
                car.fuelTypes = _localFuelTypes;
                await appProvider.updateCar(car);
                if (mounted) {
                  navigator.pop();
                }
              }
            },
            tooltip: loc.saveTooltip,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Car selector with add and delete actions.
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      isExpanded: true,
                      value: appProvider.selectedCar?.id,
                      decoration: InputDecoration(
                        labelText: loc.selectCar,
                        border: const OutlineInputBorder(),
                      ),
                      items: appProvider.cars.map((car) {
                        return DropdownMenuItem<int>(
                          value: car.id,
                          child: Text(car.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          final car =
                              appProvider.cars.firstWhere((c) => c.id == value);
                          appProvider.selectCar(car);
                          _loadCurrentCarData();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Add-car action.
                  IconButton(
                    onPressed: () => _showAddCarDialog(appProvider, loc),
                    icon: const Icon(Icons.add_circle, color: Colors.green),
                    iconSize: 36,
                  ),
                  // Delete-car action.
                  if (appProvider.selectedCar != null) ...[
                    IconButton(
                      onPressed: () => _showDeleteCarDialog(appProvider, loc),
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      iconSize: 36,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 24),
              if (appProvider.selectedCar != null) ...[
                // Fuel types.
                Text(
                  loc.fuelTypesForCar(appProvider.selectedCar!.name),
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  loc.fuelTypesHint,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _newFuelController,
                        decoration: InputDecoration(
                          labelText: loc.newFuelTypeHint,
                          border: const OutlineInputBorder(),
                        ),
                        onSubmitted: (_) => _addFuelType(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.add_circle, color: Colors.blue),
                      iconSize: 36,
                      onPressed: _addFuelType,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Fuel type list.
                ..._localFuelTypes.map((fuelType) {
                  return Card(
                    child: ListTile(
                      title: Text(fuelType),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            _localFuelTypes.remove(fuelType);
                          });
                        },
                      ),
                    ),
                  );
                }),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Add a new fuel type.
  void _addFuelType() {
    if (_newFuelController.text.trim().isNotEmpty) {
      final newFuel = _newFuelController.text.trim();
      if (!_localFuelTypes.contains(newFuel)) {
        setState(() {
          _localFuelTypes.add(newFuel);
        });
      }
      _newFuelController.clear();
    }
  }

  // Show the add-car dialog.
  Future<void> _showAddCarDialog(
      AppProvider appProvider, AppLocalizations loc) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    _addCarController.clear();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.addCar),
        content: TextField(
          controller: _addCarController,
          decoration: InputDecoration(
            labelText: loc.enterCarName,
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(loc.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(loc.add),
          ),
        ],
      ),
    );

    if (confirmed == true &&
        _addCarController.text.trim().isNotEmpty &&
        mounted) {
      try {
        await appProvider.addCar(_addCarController.text.trim());
        _loadCurrentCarData();
        if (mounted) {
          scaffoldMessenger.showSnackBar(
            SnackBar(content: Text(loc.carAdded)),
          );
        }
      } catch (e) {
        if (mounted) {
          scaffoldMessenger.showSnackBar(
            SnackBar(content: Text(loc.saveError(e.toString()))),
          );
        }
      }
    }
  }

  // Show the delete-car confirmation dialog.
  Future<void> _showDeleteCarDialog(
      AppProvider appProvider, AppLocalizations loc) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final carName = appProvider.selectedCar!.name;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.confirm),
        content: Text(loc.deleteConfirmation(carName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(loc.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(loc.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await appProvider.deleteCar(appProvider.selectedCar!);
      } catch (e) {
        if (mounted) {
          scaffoldMessenger.showSnackBar(
            SnackBar(content: Text(loc.saveError(e.toString()))),
          );
        }
      }
    }
  }
}
