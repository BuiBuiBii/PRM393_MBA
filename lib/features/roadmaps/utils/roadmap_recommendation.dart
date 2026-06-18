import '../../../core/config/app_config.dart';
import '../../../shared/models/app_models.dart';

class RoadmapRoleRecommendation {
  const RoadmapRoleRecommendation({
    required this.role,
    required this.title,
    required this.reason,
    required this.focus,
  });

  final String role;
  final String title;
  final String reason;
  final String focus;
}

bool _includesAny(String text, List<String> keywords) =>
    keywords.any((keyword) => text.contains(keyword));

String _collectAnalysisText(List<AnalysisModel> analyses) {
  return analyses
      .expand((analysis) => [
            analysis.projectType,
            analysis.careerDirection ?? '',
            ...analysis.techStack,
            ...analysis.strengths,
            ...analysis.weaknesses,
            ...analysis.recommendations,
          ])
      .join(' ')
      .toLowerCase();
}

const _reasonByRole = {
  'Frontend Developer':
      'AI thấy nhiều tín hiệu về giao diện, React hoặc trải nghiệm người dùng trong các repository đã phân tích.',
  'Backend Developer':
      'AI thấy nhiều tín hiệu về API, Node.js, Express, MongoDB hoặc xác thực trong các repository đã phân tích.',
  'Fullstack Developer':
      'AI thấy bạn có cả tín hiệu frontend và backend, nên hướng Fullstack giúp tận dụng tốt nền tảng hiện có.',
  'Mobile Developer':
      'AI thấy tín hiệu liên quan đến mobile hoặc framework mobile trong dữ liệu phân tích.',
  'Tester / QA Engineer':
      'AI thấy testing là kỹ năng cần bổ sung hoặc có tín hiệu QA trong repository.',
  'DevOps Beginner':
      'AI thấy Docker, triển khai hoặc CI/CD là phần nên ưu tiên để dự án sẵn sàng hơn.',
  'Data Analyst':
      'AI thấy tín hiệu về dữ liệu, dashboard, analytics hoặc SQL trong repository.',
  'AI / Machine Learning Beginner':
      'AI thấy tín hiệu liên quan đến AI, machine learning, model hoặc LLM.',
};

RoadmapRoleRecommendation? recommendRoadmapRole(List<AnalysisModel> analyses) {
  if (analyses.isEmpty) return null;

  final text = _collectAnalysisText(analyses);
  final scores = {for (final role in AppConfig.targetRoles) role: 0};
  void add(String role, int value) => scores[role] = (scores[role] ?? 0) + value;

  if (_includesAny(text, ['react', 'vue', 'frontend', 'css', 'html', 'ui', 'web-vitals'])) {
    add('Frontend Developer', 4);
  }
  if (_includesAny(text, ['node', 'express', 'mongodb', 'mongoose', 'jwt', 'api', 'backend', 'server'])) {
    add('Backend Developer', 4);
  }
  if (_includesAny(text, ['react', 'frontend']) && _includesAny(text, ['node', 'express', 'mongodb', 'api', 'backend'])) {
    add('Fullstack Developer', 6);
  }
  if (_includesAny(text, ['docker', 'ci/cd', 'deployment', 'github actions', 'devops'])) {
    add('DevOps Beginner', 4);
  }
  if (_includesAny(text, ['testing', 'test', 'qa', 'playwright', 'jest'])) {
    add('Tester / QA Engineer', 4);
  }
  if (_includesAny(text, ['mobile', 'react native', 'flutter', 'android', 'ios'])) {
    add('Mobile Developer', 5);
  }
  if (_includesAny(text, ['data', 'dashboard', 'analytics', 'python', 'pandas', 'sql'])) {
    add('Data Analyst', 4);
  }
  if (_includesAny(text, ['ai', 'machine learning', 'ml', 'model', 'gemini', 'llm'])) {
    add('AI / Machine Learning Beginner', 4);
  }

  for (final analysis in analyses) {
    final missing = '${analysis.weaknesses.join(' ')} ${analysis.recommendations.join(' ')}'.toLowerCase();
    if (_includesAny(missing, ['docker', 'deployment', 'ci/cd'])) add('DevOps Beginner', 2);
    if (_includesAny(missing, ['testing', 'test'])) add('Tester / QA Engineer', 2);
    if (_includesAny(missing, ['backend', 'api', 'node'])) add('Backend Developer', 2);
  }

  final sorted = scores.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  final top = sorted.first;

  if (top.value <= 0) {
    return const RoadmapRoleRecommendation(
      role: 'Backend Developer',
      title: 'Đề xuất chính theo repository',
      reason:
          'AI chưa thấy tín hiệu đủ rõ, nên chọn Backend Developer làm hướng nền tảng để củng cố API, dữ liệu và cấu trúc hệ thống.',
      focus: 'Nền tảng API, database, xác thực và cấu trúc backend.',
    );
  }

  return RoadmapRoleRecommendation(
    role: top.key,
    title: 'Đề xuất chính theo repository',
    reason: _reasonByRole[top.key] ?? 'Hướng nghề nghiệp phù hợp nhất từ các repository đã phân tích.',
    focus: 'Tập trung vào hướng nghề nghiệp nổi bật nhất từ các repository đã phân tích.',
  );
}

List<RoadmapRoleRecommendation> recommendJobReadinessRoadmaps(List<AnalysisModel> analyses) {
  if (analyses.isEmpty) return [];

  final text = _collectAnalysisText(analyses);
  final suggestions = <RoadmapRoleRecommendation>[];

  if (_includesAny(text, ['testing', 'test', 'automated testing', 'jest', 'vitest', 'playwright', 'cypress'])) {
    suggestions.add(const RoadmapRoleRecommendation(
      role: 'Tester / QA Engineer',
      title: 'Tăng độ tin cậy dự án',
      reason:
          'Nhiều repository còn thiếu kiểm thử tự động. Bổ sung testing giúp portfolio đáng tin hơn khi ứng tuyển.',
      focus: 'Unit test, integration test, E2E test và coverage trong README.',
    ));
  }

  if (_includesAny(text, ['docker', 'deployment', 'ci/cd', 'github actions', 'environment configuration', '.env'])) {
    suggestions.add(const RoadmapRoleRecommendation(
      role: 'DevOps Beginner',
      title: 'Sẵn sàng triển khai',
      reason:
          'Docker, CI/CD hoặc cấu hình môi trường là điểm nên cải thiện để dự án dễ chạy và dễ demo.',
      focus: 'Dockerfile, docker-compose, GitHub Actions và biến môi trường.',
    ));
  }

  if (suggestions.length < 2 && _includesAny(text, ['react', 'frontend', 'express', 'backend', 'api'])) {
    suggestions.add(const RoadmapRoleRecommendation(
      role: 'Fullstack Developer',
      title: 'Hoàn thiện sản phẩm demo',
      reason:
          'Bạn có tín hiệu cả frontend hoặc backend. Roadmap Fullstack phụ giúp biến repo thành demo hoàn chỉnh hơn.',
      focus: 'Kết nối frontend-backend, auth flow, CRUD và deploy demo.',
    ));
  }

  if (suggestions.length < 2) {
    suggestions.add(const RoadmapRoleRecommendation(
      role: 'Backend Developer',
      title: 'Củng cố nền tảng kỹ thuật',
      reason:
          'Backend là nền tảng tốt để chứng minh năng lực API, dữ liệu, xác thực và cấu trúc hệ thống.',
      focus: 'REST API, database, validation, authentication và tài liệu kỹ thuật.',
    ));
  }

  return suggestions.take(2).toList();
}

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
    strong.addAll(analysis.techStack.take(4));
    missing.addAll(analysis.weaknesses);
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
