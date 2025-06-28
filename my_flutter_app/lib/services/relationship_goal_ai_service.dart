import 'dart:developer';
import 'separation_ai_service.dart';
import 'fix_marriage_ai_service.dart';

class RelationshipGoalAISuggester {
  /// Suggests relationship goals based on context and both partners' styles.
  /// Context should be one of: "marriage", "separation"
  static Future<List<String>> suggestGoals({
    required String yourAttachment,
    required String partnerAttachment,
    required String yourComm,
    required String partnerComm,
    required String context,
  }) async {
    try {
      final normalizedContext = context.trim().toLowerCase();
      switch (normalizedContext) {
        case "separation":
          return await SeparationAIService.suggestGoals(
            yourAttachment: yourAttachment,
            partnerAttachment: partnerAttachment,
            yourComm: yourComm,
            partnerComm: partnerComm,
          );
        case "marriage":
          return await FixMarriageAIService.suggestGoals(
            yourAttachment: yourAttachment,
            partnerAttachment: partnerAttachment,
            yourComm: yourComm,
            partnerComm: partnerComm,
          );
        default:
          return [
            "Express appreciation for your partner's efforts at least once a week.",
            "Schedule regular check-ins to discuss your relationship.",
          ];
      }
    } catch (e, stack) {
      log('RelationshipGoalAISuggester error: $e\n$stack');
      // Fallback in case of error
      return [
        "Unable to generate personalized goals at this time. Please try again later.",
      ];
    }
  }
}
