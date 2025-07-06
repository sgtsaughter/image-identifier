// lib/services/scanned_pokemon_list_service.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../models/scanned_pokemon.dart';

class ScannedPokemonListService extends ChangeNotifier {
  List<ScannedPokemon> _scannedPokemonList = [];
  static const String _keyScannedPokemon = 'scanned_pokemon_list';

  List<ScannedPokemon> get scannedPokemonList => _scannedPokemonList;

  // New: Getter for the count of unique Pokémon
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
      _scannedPokemonList = jsonList.map((json) => ScannedPokemon.fromJson(json)).toList();
      notifyListeners();
    }
  }

  Future<void> _saveScannedPokemon() async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> jsonList = _scannedPokemonList.map((pokemon) => pokemon.toJson()).toList();
    await prefs.setString(_keyScannedPokemon, jsonEncode(jsonList));
  }

  void addPokemon(ScannedPokemon pokemon) {
    // Check if the Pokémon already exists by name to avoid duplicates
    // We're still adding to the list, but uniquePokemonCount handles distinctness
    if (!_scannedPokemonList.any((p) => p.name.toLowerCase() == pokemon.name.toLowerCase())) {
      _scannedPokemonList.add(pokemon); // Add only if not already in the list
      _saveScannedPokemon();
      notifyListeners();
    }
  }

  void clearList() {
    _scannedPokemonList.clear();
    _saveScannedPokemon();
    notifyListeners();
  }
}