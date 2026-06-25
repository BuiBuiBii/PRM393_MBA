import '../../../shared/models/app_models.dart';

const roadmapCategories = [
  'All',
  'Frontend',
  'Backend',
  'Fullstack',
  'DevOps',
  'Mobile',
  'AI/ML',
  'System Design',
  'Testing',
];

LearningNodeModel _node({
  required String id,
  required String title,
  required String description,
  required String status,
  required int hours,
  required int xp,
  bool bookmarked = false,
}) {
  return LearningNodeModel(
    id: id,
    title: title,
    description: description,
    estimatedHours: hours,
    difficulty: 'Intermediate',
    status: status,
    skills: const ['API', 'Backend'],
    xp: xp,
    bookmarked: bookmarked,
  );
}

final mockRoadmaps = <RoadmapModel>[
  RoadmapModel(
    id: 'roadmap-fullstack-production',
    slug: 'fullstack-production-engineer',
    title: 'Full-Stack Engineer hướng production',
    subtitle: 'Backend, testing, Docker, CI/CD cho developer mạnh frontend.',
    description: 'Lộ trình thực tế từ ứng dụng React tới hệ thống production đáng tin cậy.',
    category: 'Fullstack',
    difficulty: 'Intermediate',
    estimatedWeeks: 10,
    estimatedHours: 86,
    tags: const ['Node.js', 'PostgreSQL', 'Docker', 'GitHub Actions'],
    isFeatured: true,
    isAIRecommended: true,
    progress: 46,
    careerOutcome: 'Full-Stack Engineer',
    modules: [
      RoadmapModuleModel(
        id: 'module-api',
        title: 'Nen tang API',
        description: 'Xay dung service, validation va tai lieu API.',
        nodes: [
          _node(id: 'n1', title: 'Node.js Runtime', description: 'Hieu event loop va cau truc service.', status: 'completed', hours: 5, xp: 160),
          _node(id: 'n2', title: 'Thiet ke REST API', description: 'Mo hinh resource, status code, phan trang.', status: 'completed', hours: 7, xp: 220),
          _node(id: 'n3', title: 'Validation va error contract', description: 'Schema validation va phan hoi loi co kieu.', status: 'in-progress', hours: 4, xp: 180, bookmarked: true),
          _node(id: 'n4', title: 'Xac thuc va rate limit', description: 'Bao ve API bang token va throttling.', status: 'unlocked', hours: 6, xp: 260),
        ],
      ),
      RoadmapModuleModel(
        id: 'module-devops',
        title: 'DevOps & Delivery',
        description: 'Container, CI/CD va observability.',
        nodes: [
          _node(id: 'n5', title: 'Docker fundamentals', description: 'Containerize ung dung va compose stack.', status: 'locked', hours: 6, xp: 200),
          _node(id: 'n6', title: 'GitHub Actions', description: 'Pipeline build, test va deploy.', status: 'locked', hours: 5, xp: 190),
        ],
      ),
    ],
  ),
  RoadmapModel(
    id: 'roadmap-frontend-mastery',
    slug: 'frontend-mastery',
    title: 'Frontend Mastery',
    subtitle: 'React nang cao, performance va testing.',
    description: 'Nâng cao kỹ năng frontend để portfolio nổi bật hơn.',
    category: 'Frontend',
    difficulty: 'Advanced',
    estimatedWeeks: 8,
    estimatedHours: 64,
    tags: const ['React', 'TypeScript', 'Testing', 'Performance'],
    isFeatured: true,
    isAIRecommended: false,
    progress: 12,
    careerOutcome: 'Frontend Engineer',
    modules: [
      RoadmapModuleModel(
        id: 'module-react',
        title: 'React nang cao',
        description: 'Patterns, state management va performance.',
        nodes: [
          _node(id: 'f1', title: 'Advanced hooks', description: 'Custom hooks va composition patterns.', status: 'in-progress', hours: 4, xp: 150),
          _node(id: 'f2', title: 'Testing React', description: 'Unit va integration tests.', status: 'locked', hours: 5, xp: 170),
        ],
      ),
    ],
  ),
  RoadmapModel(
    id: 'roadmap-backend-api',
    slug: 'backend-api-design',
    title: 'Backend API Design',
    subtitle: 'Thiet ke API chuan cho portfolio.',
    description: 'REST, validation, auth va database modeling.',
    category: 'Backend',
    difficulty: 'Intermediate',
    estimatedWeeks: 6,
    estimatedHours: 48,
    tags: const ['Node.js', 'PostgreSQL', 'REST'],
    isFeatured: false,
    isAIRecommended: true,
    progress: 0,
    careerOutcome: 'Backend Engineer',
    modules: [
      RoadmapModuleModel(
        id: 'module-rest',
        title: 'REST & Database',
        description: 'API design va relational modeling.',
        nodes: [
          _node(id: 'b1', title: 'REST principles', description: 'Resource modeling va HTTP semantics.', status: 'unlocked', hours: 4, xp: 140),
        ],
      ),
    ],
  ),
];

final mockSkillProgress = [
  const SkillProgressModel(skill: 'React', category: 'Frontend', current: 85, target: 95),
  const SkillProgressModel(skill: 'Node.js', category: 'Backend', current: 58, target: 82),
  const SkillProgressModel(skill: 'Docker', category: 'DevOps', current: 34, target: 78),
  const SkillProgressModel(skill: 'Testing', category: 'Testing', current: 45, target: 80),
  const SkillProgressModel(skill: 'System Design', category: 'System Design', current: 40, target: 75),
];

final mockLearningStats = LearningStatsModel(
  activeRoadmapIds: [mockRoadmaps.first.id],
  completedNodes: 2,
  totalNodes: 8,
  totalXp: 580,
  level: 4,
  currentStreak: 5,
  weeklyGoalHours: 10,
  weeklyHoursCompleted: 6,
  bookmarkedNodeIds: ['n3'],
);

final mockAIRecommendation = AIRecommendationModel(
  summary: 'Repository của bạn cho thấy năng lực React tốt, nhưng CI/CD và testing còn hạn chế.',
  confidence: 89,
  strengths: const [
    'Cấu trúc component frontend tốt',
    'Sử dụng TypeScript ổn định',
    'Commit đều ở repository đang hoạt động',
  ],
  weaknesses: const [
    'Validation backend chưa nhất quán',
    'Độ phủ testing còn nông',
    'Chưa có CI/CD pipeline rõ ràng',
  ],
  missingSkills: const ['Node.js API', 'PostgreSQL', 'Docker', 'GitHub Actions', 'E2E testing'],
  careerSuggestion: 'Hướng phù hợp: Full-Stack Engineer với thế mạnh frontend.',
  estimatedCompletionWeeks: 10,
  roadmap: mockRoadmaps.first,
);
