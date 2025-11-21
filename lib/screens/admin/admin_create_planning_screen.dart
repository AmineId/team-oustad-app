import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/theme.dart';
import '../../core/utils/user_utils.dart';

class AdminCreatePlanningScreen extends StatefulWidget {
  final int? preselectedMemberId;
  final VoidCallback? onBack;
  final VoidCallback? onSuccess;
  
  const AdminCreatePlanningScreen({
    super.key,
    this.preselectedMemberId,
    this.onBack,
    this.onSuccess,
  });

  @override
  State<AdminCreatePlanningScreen> createState() => _AdminCreatePlanningScreenState();
}

class _AdminCreatePlanningScreenState extends State<AdminCreatePlanningScreen> {
  final ApiService _apiService = ApiService.fromEnv();
  final AuthService _authService = AuthService(ApiService.fromEnv());
  
  int _currentStep = 0;
  bool _isLoading = false;
  
  // Étape 1: Informations générales
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  int? _selectedMemberId;
  List<Map<String, dynamic>> _members = [];
  final List<int> _selectedDays = []; // 0 = dimanche, 1 = lundi, etc.
  
  // Étape 2: Sélection des exercices
  List<Map<String, dynamic>> _allExercises = [];
  final Map<int, List<int>> _selectedExercisesByDay = {}; // dayOfWeek -> List<exerciseId>
  
  // Étape 3: Détails des exercices par jour
  final Map<String, Map<String, dynamic>> _exerciseDetails = {}; // "dayOfWeek_exerciseId" -> details

  @override
  void initState() {
    super.initState();
    // Pré-sélectionner le membre si fourni
    if (widget.preselectedMemberId != null) {
      _selectedMemberId = widget.preselectedMemberId;
    }
    _loadMembers();
    _loadExercises();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadMembers() async {
    try {
      final token = await _authService.loadToken();
      if (token == null) return;

      // Récupérer le profil de l'admin pour obtenir son gymId
      final adminProfile = await _authService.getCachedUserProfile();
      final adminGymId = adminProfile?['gymId'] as int?;

      final users = await _apiService.getUsers(token);
      if (users != null) {
        setState(() {
          // Filtrer uniquement les membres de la même salle que l'admin
          _members = users
              .where((user) {
                final isRoleMember = user['role'] == 'member';
                final userGymId = user['gymId'] as int?;
                final isSameGym = adminGymId == null || userGymId == adminGymId;
                return isRoleMember && isSameGym;
              })
              .map((user) => user as Map<String, dynamic>)
              .toList();
        });
      }
    } catch (e) {
      // ignore: avoid_print
      debugPrint('Error loading members: $e');
    }
  }

  Future<void> _loadExercises() async {
    try {
      final token = await _authService.loadToken();
      if (token == null) return;

      final exercises = await _apiService.getExercises(token);
      if (exercises != null) {
        setState(() {
          _allExercises = exercises.map((e) => e as Map<String, dynamic>).toList();
        });
      }
    } catch (e) {
      // ignore: avoid_print
      debugPrint('Error loading exercises: $e');
    }
  }

  Future<void> _createPlanning() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final token = await _authService.loadToken();
      if (token == null) {
        _showError('Token non disponible');
        return;
      }

      // Créer le planning
      final planning = await _apiService.createPlanning(
        _selectedMemberId!,
        _titleController.text,
        _startDate!.toIso8601String().split('T')[0],
        _endDate!.toIso8601String().split('T')[0],
        token,
        description: _descriptionController.text.isNotEmpty ? _descriptionController.text : null,
      );

      if (planning == null) {
        _showError('Erreur lors de la création du planning');
        return;
      }

      final planningId = planning['planning']['id'] as int;

      // Ajouter les exercices pour chaque jour sélectionné
      for (final dayOfWeek in _selectedDays) {
        final exerciseIds = _selectedExercisesByDay[dayOfWeek] ?? [];
        
        for (int i = 0; i < exerciseIds.length; i++) {
          final exerciseId = exerciseIds[i];
          final detailsKey = '${dayOfWeek}_$exerciseId';
          final details = _exerciseDetails[detailsKey] ?? {};
          
          await _apiService.addExerciseToPlanningDay(
            planningId,
            dayOfWeek,
            exerciseId,
            token,
            sets: details['sets'] as int?,
            reps: details['reps'] as int?,
            duration: details['duration'] as int?,
            weight: details['weight'] as double?,
            restTime: details['restTime'] as int?,
            notes: details['notes'] as String?,
            order: i + 1,
          );
        }
      }

      if (!mounted) return;
      
      // Afficher un message de succès
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Theme.of(context).cardTheme.color,
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: AppColors.success),
              SizedBox(width: 8),
              Text(
                'Succès',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          content: const Text(
            'Le planning a été créé avec succès',
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text(
                'OK',
                style: TextStyle(color: AppColors.primary),
              ),
            ),
          ],
        ),
      );
      
      if (!mounted) return;
      if (widget.onSuccess != null) {
        widget.onSuccess!();
      } else {
        Navigator.pop(context, true);
      }
    } catch (e) {
      _showError('Erreur: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color,
        title: const Row(
          children: [
            Icon(Icons.error, color: AppColors.error),
            SizedBox(width: 8),
            Text(
              'Erreur',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text(
              'OK',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  bool _canContinueStep0() {
    return _titleController.text.isNotEmpty &&
           _startDate != null &&
           _endDate != null &&
           _selectedMemberId != null &&
           _selectedDays.isNotEmpty;
  }

  bool _canContinueStep1() {
    // Vérifier que chaque jour sélectionné a au moins un exercice
    for (final day in _selectedDays) {
      final exercises = _selectedExercisesByDay[day] ?? [];
      if (exercises.isEmpty) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (widget.onBack != null) {
              widget.onBack!();
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: const Text(
          'Nouveau planning',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).scaffoldBackgroundColor, Theme.of(context).cardTheme.color!,
            ],
          ),
        ),
        child: Stepper(
          currentStep: _currentStep,
          onStepContinue: () {
            if (_currentStep == 0 && !_canContinueStep0()) {
              _showError('Veuillez remplir tous les champs requis');
              return;
            }
            
            if (_currentStep == 1 && !_canContinueStep1()) {
              _showError('Veuillez sélectionner au moins un exercice pour chaque jour');
              return;
            }
            
            if (_currentStep < 2) {
              setState(() {
                _currentStep++;
              });
            } else {
              // Étape finale - créer le planning
              _createPlanning();
            }
          },
          onStepCancel: () {
            if (_currentStep > 0) {
              setState(() {
                _currentStep--;
              });
            } else {
              Navigator.pop(context);
            }
          },
          onStepTapped: (step) {
            setState(() {
              _currentStep = step;
            });
          },
          controlsBuilder: (context, details) {
            return Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                children: [
                  ElevatedButton(
                    onPressed: _isLoading ? null : details.onStepContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading && _currentStep == 2
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(_currentStep == 2 ? 'Créer' : 'Suivant'),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: details.onStepCancel,
                    child: Text(
                      _currentStep == 0 ? 'Annuler' : 'Retour',
                      style: const TextStyle(color: Colors.white60),
                    ),
                  ),
                ],
              ),
            );
          },
          steps: [
            Step(
              title: const Text(
                'Informations générales',
                style: TextStyle(color: Colors.white),
              ),
              content: _buildStep1(),
              isActive: _currentStep >= 0,
              state: _currentStep > 0 ? StepState.complete : StepState.indexed,
            ),
            Step(
              title: const Text(
                'Sélection des exercices',
                style: TextStyle(color: Colors.white),
              ),
              content: _buildStep2(),
              isActive: _currentStep >= 1,
              state: _currentStep > 1 ? StepState.complete : StepState.indexed,
            ),
            Step(
              title: const Text(
                'Détails des exercices',
                style: TextStyle(color: Colors.white),
              ),
              content: _buildStep3(),
              isActive: _currentStep >= 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Titre
        TextField(
          controller: _titleController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Titre du planning *',
            labelStyle: TextStyle(color: Colors.white60),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white24),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.primary),
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Description
        TextField(
          controller: _descriptionController,
          style: const TextStyle(color: Colors.white),
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Description (optionnel)',
            labelStyle: TextStyle(color: Colors.white60),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white24),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.primary),
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Sélection du membre
        const Text(
          'Membre *',
          style: TextStyle(
            color: Colors.white60,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          initialValue: _selectedMemberId,
          dropdownColor: Theme.of(context).cardTheme.color,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: Theme.of(context).cardTheme.color,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
          items: _members.map((member) {
            return DropdownMenuItem<int>(
              value: member['id'] as int,
              child: Text(getUserFullName(member)),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedMemberId = value;
            });
          },
        ),
        
        const SizedBox(height: 16),
        
        // Date de début
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text(
            'Date de début *',
            style: TextStyle(color: Colors.white60, fontSize: 12),
          ),
          subtitle: Text(
            _startDate != null 
                ? '${_startDate!.day.toString().padLeft(2, '0')}/${_startDate!.month.toString().padLeft(2, '0')}/${_startDate!.year}'
                : 'Sélectionner une date',
            style: const TextStyle(color: Colors.white),
          ),
          trailing: const Icon(Icons.calendar_today, color: AppColors.primary),
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _startDate ?? DateTime.now(),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
              builder: (context, child) {
                return Theme(
                  data: ThemeData.dark().copyWith(
                    colorScheme: ColorScheme.dark(primary: AppColors.primary, surface: Theme.of(context).cardTheme.color ?? Colors.grey[900]!,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (date != null) {
              setState(() {
                _startDate = date;
                // S'assurer que la date de fin est après la date de début
                if (_endDate != null && _endDate!.isBefore(_startDate!)) {
                  _endDate = null;
                }
              });
            }
          },
        ),
        
        // Date de fin
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text(
            'Date de fin *',
            style: TextStyle(color: Colors.white60, fontSize: 12),
          ),
          subtitle: Text(
            _endDate != null 
                ? '${_endDate!.day.toString().padLeft(2, '0')}/${_endDate!.month.toString().padLeft(2, '0')}/${_endDate!.year}'
                : 'Sélectionner une date',
            style: const TextStyle(color: Colors.white),
          ),
          trailing: const Icon(Icons.calendar_today, color: AppColors.primary),
          onTap: () async {
            if (_startDate == null) {
              _showError('Veuillez d\'abord sélectionner une date de début');
              return;
            }
            
            final date = await showDatePicker(
              context: context,
              initialDate: _endDate ?? _startDate!.add(const Duration(days: 30)),
              firstDate: _startDate!,
              lastDate: _startDate!.add(const Duration(days: 365)),
              builder: (context, child) {
                return Theme(
                  data: ThemeData.dark().copyWith(
                    colorScheme: ColorScheme.dark(primary: AppColors.primary, surface: Theme.of(context).cardTheme.color ?? Colors.grey[900]!,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (date != null) {
              setState(() {
                _endDate = date;
              });
            }
          },
        ),
        
        const SizedBox(height: 16),
        
        // Sélection des jours de la semaine
        const Text(
          'Jours de la semaine *',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(7, (index) {
            // Ajuster pour que 0 = dimanche
            final dayOfWeek = (index + 1) % 7;
            final dayNames = ['Dim', 'Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam'];
            final isSelected = _selectedDays.contains(dayOfWeek);
            
            return FilterChip(
              label: Text(dayNames[dayOfWeek]),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedDays.add(dayOfWeek);
                    _selectedDays.sort();
                  } else {
                    _selectedDays.remove(dayOfWeek);
                    _selectedExercisesByDay.remove(dayOfWeek);
                  }
                });
              },
              selectedColor: AppColors.primary.withValues(alpha: 0.3),
              checkmarkColor: AppColors.primary,
              labelStyle: TextStyle(
                color: isSelected ? AppColors.primary : Colors.white60,
              ),
              side: BorderSide(
                color: isSelected ? AppColors.primary : Colors.white24,
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sélectionnez les exercices pour chaque jour',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 16),
        
        // Pour chaque jour sélectionné
        ..._selectedDays.map((dayOfWeek) {
          final dayNames = ['Dimanche', 'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi'];
          final selectedExercises = _selectedExercisesByDay[dayOfWeek] ?? [];
          
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            color: Theme.of(context).cardTheme.color,
            child: ExpansionTile(
              title: Text(
                dayNames[dayOfWeek],
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                '${selectedExercises.length} exercice(s) sélectionné(s)',
                style: const TextStyle(color: Colors.white60),
              ),
              iconColor: AppColors.primary,
              collapsedIconColor: Colors.white60,
              children: _allExercises.map((exercise) {
                final exerciseId = exercise['id'] as int;
                final isSelected = selectedExercises.contains(exerciseId);
                
                return CheckboxListTile(
                  value: isSelected,
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        _selectedExercisesByDay.putIfAbsent(dayOfWeek, () => []).add(exerciseId);
                      } else {
                        _selectedExercisesByDay[dayOfWeek]?.remove(exerciseId);
                        // Supprimer aussi les détails
                        _exerciseDetails.remove('${dayOfWeek}_$exerciseId');
                      }
                    });
                  },
                  title: Text(
                    exercise['name'] as String? ?? 'Exercice sans nom',
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    exercise['category'] as String? ?? '',
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                  fillColor: WidgetStateProperty.all(AppColors.primary),
                  checkColor: Colors.white,
                );
              }).toList(),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Configurez les détails de chaque exercice',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 16),
        
        // Pour chaque jour et chaque exercice sélectionné
        ..._selectedDays.expand((dayOfWeek) {
          final dayNames = ['Dimanche', 'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi'];
          final selectedExercises = _selectedExercisesByDay[dayOfWeek] ?? [];
          
          return [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                dayNames[dayOfWeek],
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ...selectedExercises.map((exerciseId) {
              final exercise = _allExercises.firstWhere((e) => e['id'] == exerciseId);
              final detailsKey = '${dayOfWeek}_$exerciseId';
              
              return _buildExerciseDetailsCard(exercise, detailsKey);
            }),
          ];
        }),
      ],
    );
  }

  Widget _buildExerciseDetailsCard(Map<String, dynamic> exercise, String detailsKey) {
    final details = _exerciseDetails.putIfAbsent(detailsKey, () => {});
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Theme.of(context).cardTheme.color,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              exercise['name'] as String? ?? 'Exercice sans nom',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: TextField(
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Séries',
                      labelStyle: TextStyle(color: Colors.white60, fontSize: 12),
                      isDense: true,
                    ),
                    onChanged: (value) {
                      details['sets'] = int.tryParse(value);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Répétitions',
                      labelStyle: TextStyle(color: Colors.white60, fontSize: 12),
                      isDense: true,
                    ),
                    onChanged: (value) {
                      details['reps'] = int.tryParse(value);
                    },
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: TextField(
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Poids (kg)',
                      labelStyle: TextStyle(color: Colors.white60, fontSize: 12),
                      isDense: true,
                    ),
                    onChanged: (value) {
                      details['weight'] = double.tryParse(value);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Repos (sec)',
                      labelStyle: TextStyle(color: Colors.white60, fontSize: 12),
                      isDense: true,
                    ),
                    onChanged: (value) {
                      details['restTime'] = int.tryParse(value);
                    },
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            TextField(
              style: const TextStyle(color: Colors.white),
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Notes',
                labelStyle: TextStyle(color: Colors.white60, fontSize: 12),
                isDense: true,
              ),
              onChanged: (value) {
                details['notes'] = value.isNotEmpty ? value : null;
              },
            ),
          ],
        ),
      ),
    );
  }
}





