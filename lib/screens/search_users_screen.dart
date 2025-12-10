import 'package:flutter/material.dart';
import 'package:subefit/screens/firebase_service.dart';
import 'package:subefit/screens/user_profile_model.dart';
import 'package:subefit/screens/progreso_screen.dart'; // Pantalla de perfil de usuario

class SearchUsersScreen extends StatefulWidget {
  const SearchUsersScreen({Key? key}) : super(key: key);

  @override
  _SearchUsersScreenState createState() => _SearchUsersScreenState();
}

class _SearchUsersScreenState extends State<SearchUsersScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final TextEditingController _searchController = TextEditingController();
  List<UserProfile> _searchResults = [];
  bool _isLoading = false;
  String _lastSearchQuery = '';

  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _lastSearchQuery = '';
      });
      return;
    }

    // Evita búsquedas repetidas si el texto no cambia
    if (query == _lastSearchQuery) return;

    setState(() {
      _isLoading = true;
      _lastSearchQuery = query;
    });

    final results = await _firebaseService.searchPublicUsers(query: query);

    if (mounted) {
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    // Listener para buscar mientras el usuario escribe (con un pequeño retraso)
    _searchController.addListener(() {
      // Implementar un "debounce" para no llamar a la API en cada letra
      // Por simplicidad, aquí buscamos directamente.
      _searchUsers(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Buscar atletas...',
            border: InputBorder.none,
          ),
          style: const TextStyle(color: Colors.white),
          cursorColor: Colors.white,
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _searchResults.isEmpty && _searchController.text.isNotEmpty
              ? const Center(child: Text('No se encontraron usuarios.'))
              : ListView.builder(
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final user = _searchResults[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: user.fotoUrl != null
                            ? NetworkImage(user.fotoUrl!)
                            : null,
                        child: user.fotoUrl == null
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      title: Text(user.nombre),
                      subtitle: Text(user.biografia ?? ''),
                      onTap: () {
                        // Navegar al perfil del usuario
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => ProgresoScreen(userId: user.id),
                        ));
                      },
                    );
                  },
                ),
    );
  }
}
