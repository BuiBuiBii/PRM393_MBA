import '../../../shared/models/app_models.dart';

/// Insight kỹ năng từ phân tích — không tự tính role (Dev2Vec qua API).
class SkillInsightSummary {
  const SkillInsightSummary({required this.strongSignals, required this.missingSkills});

  final List<String> strongSignals;
  final List<String> missingSkills;
}

SkillInsightSummary? buildSkillInsight(List<AnalysisModel> analyses) {
  if (analyses.isEmpty) return null;

  final strong = <String>{};
  final missing = <String>{};
  for (final analysis in analyses) {
    strong.addAll(analysis.strengths);
    strong.addAll(analysis.topSkills);
    strong.addAll(analysis.techStack.take(4));
    missing.addAll(analysis.weaknesses);
    missing.addAll(analysis.missingSkills);
    if (analysis.scores.documentation < 60) missing.add('Documentation');
    if (analysis.scores.codeConvention < 60) missing.add('Code Quality');
    if (analysis.scores.completeness < 60) missing.add('Completeness');
  }

  if (strong.isEmpty && missing.isEmpty) return null;
  return SkillInsightSummary(
    strongSignals: strong.take(6).toList(),
    missingSkills: missing.take(6).toList(),
  );
}
