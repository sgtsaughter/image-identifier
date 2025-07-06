// lib/services/scanned_pokemon_list_service.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; // For jsonDecode and jsonEncode

import '../models/scanned_pokemon.dart';
class ScannedPokemonListService extends ChangeNotifier {
  List<ScannedPokemon> _scannedPokemonList = [];
  static const String _keyScannedPokemon = 'scanned_pokemon_list';

  List<ScannedPokemon> get scannedPokemonList => _scannedPokemonList;

  ScannedPokemonListService() {
    _loadScannedPokemon();
  }

  Future<void> _loadScannedPokemon() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_keyScannedPokemon);
    if (jsonString != null) {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      _scannedPokemonList = jsonList.map((json) => ScannedPokemon.fromJson(json)).toList();
      notifyListeners(); // Notify listeners after loading
    }
  }

  Future<void> _saveScannedPokemon() async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> jsonList = _scannedPokemonList.map((pokemon) => pokemon.toJson()).toList();
    await prefs.setString(_keyScannedPokemon, jsonEncode(jsonList));
  }

  void addPokemon(ScannedPokemon pokemon) {
    // Check if the Pokémon already exists by name to avoid duplicates
    if (!_scannedPokemonList.any((p) => p.name.toLowerCase() == pokemon.name.toLowerCase())) {
      _scannedPokemonList.add(pokemon);
      _saveScannedPokemon(); // Save after adding
      notifyListeners(); // Notify listeners that the list has changed
    }
  }

  void clearList() {
    _scannedPokemonList.clear();
    _saveScannedPokemon();
    notifyListeners();
  }
}