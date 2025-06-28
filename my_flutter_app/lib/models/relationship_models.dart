import 'package:flutter/material.dart';

class RelationshipProfile {
  final String id;
  final String partnerName;
  final String personalityMatch;
  final String explanation;
  final int compatibilityScore;
  final DateTime lastUpdated;
  final List<String> insights;
  final List<String> riskFactors;

  RelationshipProfile({
    required this.id,
    required this.partnerName,
    required this.personalityMatch,
    required this.explanation,
    required this.compatibilityScore,
    required this.lastUpdated,
    required this.insights,
    required this.riskFactors,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'partnerName': partnerName,
      'personalityMatch': personalityMatch,
      'explanation': explanation,
      'compatibilityScore': compatibilityScore,
      'lastUpdated': lastUpdated.toIso8601String(),
      'insights': insights,
      'riskFactors': riskFactors,
    };
  }

  factory RelationshipProfile.fromJson(Map<String, dynamic> json) {
    return RelationshipProfile(
      id: json['id'],
      partnerName: json['partnerName'],
      personalityMatch: json['personalityMatch'],
      explanation: json['explanation'],
      compatibilityScore: json['compatibilityScore'],
      lastUpdated: DateTime.parse(json['lastUpdated']),
      insights: List<String>.from(json['insights']),
      riskFactors: List<String>.from(json['riskFactors']),
    );
  }
}

class ToneOption {
  final String name;
  final IconData icon;
  final Color color;

  ToneOption(this.name, this.icon, this.color);
}

class MessageAnalysis {
  final String emotionalTone;
  final String communicationStyle;
  final String attachmentStyle; // <-- Add this line
  final String potentialImpact;
  final List<String> suggestions;
  final double confidenceScore;
  final DateTime analyzedAt;

  MessageAnalysis({
    required this.emotionalTone,
    required this.communicationStyle,
    required this.attachmentStyle, // <-- Add this line
    required this.potentialImpact,
    required this.suggestions,
    required this.confidenceScore,
    required this.analyzedAt,
  });
}

final profile = RelationshipProfile(
  id: '1',
  partnerName: 'Alex',
  personalityMatch: 'Secure + Assertive', // <-- Use both styles here
  explanation:
      'You and Alex both communicate openly and resolve conflict constructively.',
  compatibilityScore: 92,
  lastUpdated: DateTime.now(),
  insights: ['Practice active listening.', 'Maintain open dialogue.'],
  riskFactors: ['Watch for stress during major life changes.'],
);
