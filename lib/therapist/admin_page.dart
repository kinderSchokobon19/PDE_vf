import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  bool _showForm = false;
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _selectedGenre;
  String _message = '';
  bool _success = false;
  List<dynamic> _activities = [];

  @override
  void initState() {
    super.initState();
    _fetchActivities();
  }

  void _toggleForm() {
    setState(() {
      _showForm = !_showForm;
      _message = '';
    });
  }

  Future<void> _fetchActivities() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null) return;

    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:5000/api/activities'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final allActivities = jsonDecode(response.body);

        final now = DateTime.now();
        final upcoming = allActivities.where((activity) {
          final date = DateTime.tryParse(activity['date'] ?? '');
          return date != null && date.isAfter(now);
        }).toList();

        setState(() {
          _activities = upcoming;
        });
      } else {
        setState(() {
          _message = 'Erreur lors du chargement des activités.';
        });
      }
    } catch (e) {
      setState(() {
        _message = 'Erreur de connexion.';
      });
    }
  }

  Future<void> _submitActivity() async {
    if (_titleController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _selectedDate == null ||
        _selectedTime == null ||
        _selectedGenre == null) {
      setState(() {
        _message = 'Veuillez remplir tous les champs';
        _success = false;
      });
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null) return;

    final dateStr = _selectedDate!.toIso8601String().split('T')[0];
    final timeStr = _selectedTime!.format(context);

    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:5000/api/activities'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'title': _titleController.text,
          'description': _descriptionController.text,
          'date': dateStr,
          'time': timeStr,
          'genre': _selectedGenre,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        setState(() {
          _message = 'Activité créée avec succès';
          _success = true;
          _showForm = false;
          _titleController.clear();
          _descriptionController.clear();
          _selectedDate = null;
          _selectedTime = null;
          _selectedGenre = null;
        });
        await _fetchActivities(); // ✅ refresh la liste après ajout
      } else {
        setState(() {
          _message = data['message'] ?? 'Erreur lors de la création';
          _success = false;
        });
      }
    } catch (e) {
      setState(() {
        _message = 'Erreur de connexion au serveur';
        _success = false;
      });
    }
  }

  Widget _buildActivityCard(Map<String, dynamic> activity) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        title: Text(activity['title'] ?? 'Sans titre'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📅 ${activity['date']} à ${activity['time']}'),
            Text('👤 Genre : ${activity['genre']}'),
            Text('📝 ${activity['description'] ?? ''}'),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false,
          title: const Text("Espace Admin")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            ElevatedButton(
              onPressed: _toggleForm,
              child: Text(_showForm ? 'Annuler' : 'Ajouter une activité'),
            ),
            const SizedBox(height: 10),
            if (_message.isNotEmpty)
              Text(
                _message,
                style: TextStyle(color: _success ? Colors.green : Colors.red),
              ),
            if (_showForm) ...[
              const SizedBox(height: 20),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Titre'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(_selectedDate == null
                        ? 'Date non sélectionnée'
                        : 'Date : ${_selectedDate!.toLocal().toString().split(' ')[0]}'),
                  ),
                  TextButton(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      );
                      if (date != null) setState(() => _selectedDate = date);
                    },
                    child: const Text('Choisir la date'),
                  )
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(_selectedTime == null
                        ? 'Heure non sélectionnée'
                        : 'Heure : ${_selectedTime!.format(context)}'),
                  ),
                  TextButton(
                    onPressed: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (time != null) setState(() => _selectedTime = time);
                    },
                    child: const Text('Choisir l\'heure'),
                  )
                ],
              ),
              DropdownButtonFormField<String>(
                value: _selectedGenre,
                decoration: const InputDecoration(labelText: 'Genre concerné'),
                items: const [
                  DropdownMenuItem(value: 'Femme', child: Text('Femme')),
                  DropdownMenuItem(value: 'Homme', child: Text('Homme')),
                  DropdownMenuItem(value: 'Autre', child: Text('Autre')),
                  DropdownMenuItem(value: 'Tous', child: Text('Tous')),
                ],
                onChanged: (val) => setState(() => _selectedGenre = val),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitActivity,
                child: const Text('Créer l\'activité'),
              )
            ],
            const SizedBox(height: 20),
            const Text('📋 Activités publiées :', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ..._activities.map((a) => _buildActivityCard(a)).toList(),
          ],
        ),
      ),
    );
  }
}
