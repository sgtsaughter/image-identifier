// lib/services/scanned_pokemon_list_service.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../models/scanned_pokemon.dart';

class ScannedPokemonListService extends ChangeNotifier {
  List<ScannedPokemon> _scannedPokemonList = [];
  static const String _keyScannedPokemon = 'scanned_pokemon_list';

  List<ScannedPokemon> get scannedPokemonList => _scannedPokemonList;

  int get uniquePokemonCount {
    final Set<String> uniqueNames = _scannedPokemonList.map((p) => p.name.toLowerCase()).toSet();
    return uniqueNames.length;
  }

  ScannedPokemonListService() {
    _loadScannedPokemon();
  }

  Future<void> _loadScannedPokemon() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_keyScannedPokemon);
    if (jsonString != null) {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      _scannedPokemonList = jsonList.map((json) => ScannedPokemon.fromMap(json)).toList();
      notifyListeners();
    }
  }

  Future<void> _saveScannedPokemon() async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> jsonList = _scannedPokemonList.map((pokemon) => pokemon.toMap()).toList();
    await prefs.setString(_keyScannedPokemon, jsonEncode(jsonList));
  }

  void addPokemon(ScannedPokemon pokemon) {
    // Convert new pokemon name to lowercase for case-insensitive comparison
    final String newPokemonNameLower = pokemon.name.toLowerCase();
    bool foundAndUpdated = false;

    // Iterate through the list to find if the Pokémon already exists
    for (int i = 0; i < _scannedPokemonList.length; i++) {
      if (_scannedPokemonList[i].name.toLowerCase() == newPokemonNameLower) {
        // If found, replace the old entry with the new one
        _scannedPokemonList[i] = pokemon;
        foundAndUpdated = true;
        break; // Exit loop once updated
      }
    }

    // If not found (or updated), add the new Pokémon
    if (!foundAndUpdated) {
      _scannedPokemonList.add(pokemon);
    }

    _saveScannedPokemon(); // Save changes whether added or updated
    notifyListeners(); // Notify listeners of the change
  }

  void clearList() {
    _scannedPokemonList.clear();
    _saveScannedPokemon();
    notifyListeners();
  }
}