import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:unsaid/main.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const UnsaidApp());
}

// Example: sign in
// await FirebaseAuth.instance.signInWithEmailAndPassword(email: 'your@email.com', password: 'yourPassword');

// Example: get Firestore instance
final db = FirebaseFirestore.instance;