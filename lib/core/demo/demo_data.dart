import '../../shared/models/app_models.dart';
import '../../shared/models/user_model.dart';

class DemoData {
  static const demoToken = 'demo-token-gitanalyzer';

  static const demoEmail = 'demo@gitanalyzer.vn';
  static const demoPassword = 'demo123';

  static final demoUser = UserModel(
    id: '1',
    email: demoEmail,
    name: 'Nguyễn Minh',
    avatar: 'https://api.dicebear.com/7.x/avataaars/svg?seed=Alex',
    githubConnected: true,
    githubUsername: 'alexjohnson',
    createdAt: '2024-01-15T10:00:00Z',
  );

  static final demoProfile = ProfileModel(
    fullName: 'Nguyễn Minh',
    university: 'Đại học Bách Khoa',
    major: 'Công nghệ thông tin',
    year: 3,
    targetCareer: 'Full-Stack Engineer',
    currentSkills: ['React', 'TypeScript', 'Node.js', 'PostgreSQL', 'Docker'],
    githubUsername: 'alexjohnson',
  );

  static final demoRepositories = <RepositoryModel>[
    const RepositoryModel(
      id: '1',
      name: 'ecommerce-platform',
      fullName: 'alexjohnson/ecommerce-platform',
      description: 'Nền tảng thương mại điện tử full-stack xây dựng bằng React, Node.js và PostgreSQL',
      language: 'TypeScript',
      stars: 127,
      forks: 23,
      updatedAt: '2024-05-20T14:30:00Z',
      hasReadme: true,
      analyzed: true,
      analysisId: 'analysis-1',
      url: 'https://github.com/alexjohnson/ecommerce-platform',
      private: false,
    ),
    const RepositoryModel(
      id: '2',
      name: 'task-manager-app',
      fullName: 'alexjohnson/task-manager-app',
      description: 'Ứng dụng quản lý công việc hiện đại có cộng tác thời gian thực',
      language: 'JavaScript',
      stars: 45,
      forks: 8,
      updatedAt: '2024-05-15T09:20:00Z',
      hasReadme: true,
      analyzed: true,
      analysisId: 'analysis-2',
      url: 'https://github.com/alexjohnson/task-manager-app',
      private: false,
    ),
    const RepositoryModel(
      id: '3',
      name: 'ml-image-classifier',
      fullName: 'alexjohnson/ml-image-classifier',
      description: 'Dự án machine learning phân loại hình ảnh bằng TensorFlow',
      language: 'Python',
      stars: 89,
      forks: 15,
      updatedAt: '2024-05-10T16:45:00Z',
      hasReadme: true,
      analyzed: false,
      url: 'https://github.com/alexjohnson/ml-image-classifier',
      private: false,
    ),
    const RepositoryModel(
      id: '4',
      name: 'weather-api',
      fullName: 'alexjohnson/weather-api',
      description: 'RESTful API dữ liệu thời tiết có caching và rate limiting',
      language: 'Go',
      stars: 34,
      forks: 6,
      updatedAt: '2024-04-28T11:15:00Z',
      hasReadme: true,
      analyzed: false,
      url: 'https://github.com/alexjohnson/weather-api',
      private: false,
    ),
    const RepositoryModel(
      id: '5',
      name: 'portfolio-website',
      fullName: 'alexjohnson/portfolio-website',
      description: 'Website portfolio cá nhân xây dựng bằng Next.js và Tailwind CSS',
      language: 'TypeScript',
      stars: 12,
      forks: 2,
      updatedAt: '2024-05-25T08:00:00Z',
      hasReadme: false,
      analyzed: false,
      url: 'https://github.com/alexjohnson/portfolio-website',
      private: false,
    ),
  ];

  static final demoAnalyses = <AnalysisModel>[
    AnalysisModel(
      id: 'analysis-1',
      repositoryId: '1',
      repositoryName: 'ecommerce-platform',
      createdAt: '2024-05-21T10:00:00Z',
      projectType: 'Ứng dụng web full-stack',
      techStack: ['React', 'TypeScript', 'Node.js', 'Express', 'PostgreSQL', 'Docker', 'Redis'],
      scores: const AnalysisScores(
        architecture: 85,
        completeness: 78,
        commitQuality: 82,
        documentation: 75,
        codeConvention: 88,
        overall: 82,
      ),
      strengths: const [
        'Monorepo có cấu trúc tốt và phân tách trách nhiệm rõ ràng',
        'Sử dụng TypeScript đầy đủ với định nghĩa kiểu hợp lý',
        'Độ phủ test tốt (78%) với unit test và integration test',
        'Đã container hóa bằng Docker để triển khai dễ hơn',
        'Commit message rõ ràng theo conventional commits',
        'Có tài liệu API bằng Swagger/OpenAPI',
      ],
      weaknesses: const [
        'Thiếu end-to-end test cho các luồng người dùng quan trọng',
        'Một số component nên được refactor để tái sử dụng tốt hơn',
        'Xử lý lỗi trong API cần nhất quán hơn',
        'Thiếu cấu hình monitoring và logging',
        'Chưa tìm thấy cấu hình CI/CD pipeline',
      ],
      recommendations: const [
        'Triển khai End-to-End Testing',
        'Thiết lập CI/CD Pipeline',
        'Bổ sung giải pháp monitoring',
        'Cải thiện khả năng tái sử dụng component',
        'Nâng cấp xử lý lỗi',
      ],
      careerDirection: 'Full-Stack Engineer',
    ),
    AnalysisModel(
      id: 'analysis-2',
      repositoryId: '2',
      repositoryName: 'task-manager-app',
      createdAt: '2024-05-16T14:30:00Z',
      projectType: 'Ứng dụng web frontend',
      techStack: ['React', 'JavaScript', 'Firebase', 'Material-UI', 'Socket.io'],
      scores: const AnalysisScores(
        architecture: 72,
        completeness: 68,
        commitQuality: 75,
        documentation: 65,
        codeConvention: 70,
        overall: 70,
      ),
      strengths: const [
        'Tính năng cộng tác thời gian thực hoạt động mượt',
        'Responsive design hiển thị tốt trên thiết bị di động',
        'Sử dụng React hooks tốt cho quản lý state',
        'Giao diện sạch và dễ sử dụng',
      ],
      weaknesses: const [
        'Chưa dùng TypeScript nên thiếu type safety',
        'Độ phủ test còn thấp (chỉ 35%)',
        'Một số chỗ bị prop-drilling trong cây component',
        'Thiếu error boundary phù hợp',
        'Form chưa có input validation',
      ],
      recommendations: const [
        'Chuyển sang TypeScript',
        'Cải thiện quản lý state',
        'Thêm form validation',
      ],
      careerDirection: 'Frontend Developer',
    ),
  ];

  static final demoChatSessions = <ChatSessionModel>[
    ChatSessionModel(
      id: 'chat-1',
      title: 'Cải thiện dự án thương mại điện tử như thế nào?',
      createdAt: '2024-05-22T09:00:00Z',
      repositoryContext: 'ecommerce-platform',
      messages: const [
        ChatMessageModel(
          id: 'msg-1',
          role: 'user',
          content: 'Tôi có thể cải thiện dự án thương mại điện tử như thế nào?',
          timestamp: '2024-05-22T09:00:00Z',
        ),
        ChatMessageModel(
          id: 'msg-2',
          role: 'assistant',
          content:
              'Dựa trên phân tích nền tảng thương mại điện tử của bạn, đây là các cải thiện nên ưu tiên:\n\n1. **Thêm End-to-End Tests**\n2. **Triển khai CI/CD**\n3. **Bổ sung Monitoring**\n\nBạn muốn tôi hướng dẫn chi tiết phần nào trước?',
          timestamp: '2024-05-22T09:00:30Z',
        ),
      ],
    ),
    ChatSessionModel(
      id: 'chat-2',
      title: 'Tư vấn nghề nghiệp cho full-stack developer',
      createdAt: '2024-05-20T15:30:00Z',
      messages: const [
        ChatMessageModel(
          id: 'msg-5',
          role: 'user',
          content: 'Tôi nên tập trung kỹ năng nào để trở thành senior full-stack developer?',
          timestamp: '2024-05-20T15:30:00Z',
        ),
        ChatMessageModel(
          id: 'msg-6',
          role: 'assistant',
          content:
              'Dựa trên phân tích portfolio hiện tại, bạn nên tập trung DevOps, System Design, Testing và Performance Optimization.',
          timestamp: '2024-05-20T15:30:45Z',
        ),
      ],
    ),
  ];

  static const demoChatReplies = [
    'Dựa trên phân tích repository của bạn, tôi khuyên ưu tiên bổ sung E2E test và CI/CD pipeline trước.',
    'Với mục tiêu Full-Stack Engineer, bạn nên tập trung Docker → GitHub Actions → monitoring trong 4–6 tuần tới.',
    'Repository ecommerce-platform có điểm mạnh về kiến trúc (85/100). Bước tiếp theo hợp lý là triển khai Playwright.',
    'Portfolio readiness hiện tại ~75%. Hoàn thiện demo live và video walkthrough sẽ giúp bạn nổi bật khi apply internship.',
  ];

  static final demoNotifications = <NotificationModel>[
    const NotificationModel(
      id: 'notif-1',
      title: 'Phân tích repository hoàn tất',
      message: 'Kết quả phân tích cho ecommerce-platform đã sẵn sàng. Điểm tổng: 82/100.',
      type: 'GITHUB_ANALYSIS_REMINDER',
      read: false,
      createdAt: '2024-05-21T10:05:00Z',
    ),
    const NotificationModel(
      id: 'notif-2',
      title: 'Nhắc học tuần này',
      message: 'Bạn còn 2 node chưa hoàn thành trong lộ trình Full-Stack Engineer.',
      type: 'ROADMAP_TASK_REMINDER',
      read: false,
      createdAt: '2024-05-20T08:00:00Z',
    ),
    const NotificationModel(
      id: 'notif-3',
      title: 'Gợi ý cải thiện portfolio',
      message: 'Thêm E2E test và CI/CD cho task-manager-app để tăng điểm portfolio readiness.',
      type: 'REPOSITORY_IMPROVEMENT',
      read: true,
      createdAt: '2024-05-18T14:20:00Z',
    ),
    const NotificationModel(
      id: 'notif-4',
      title: 'Chào mừng GitAnalyzer AI',
      message: 'Kết nối GitHub và phân tích repository đầu tiên để nhận roadmap cá nhân hóa.',
      type: 'SYSTEM',
      read: true,
      createdAt: '2024-05-15T09:00:00Z',
    ),
  ];

  static Map<String, dynamic> dashboardPayload() => {
        'user': {'name': demoUser.name, 'email': demoUser.email},
        'github': {'connected': true, 'username': 'alexjohnson'},
        'repositories': {'total': 5, 'analyzed': 2, 'unanalyzed': 3},
        'skills': {
          'strong': ['JavaScript', 'React', 'Node.js'],
          'missing': ['Testing', 'Docker'],
        },
        'suggestedCareerPath': 'Fullstack Developer',
        'roadmapProgress': 35,
        'totalRepositories': 5,
        'analyzedRepositories': 2,
        'githubConnected': true,
        'overallScore': 82,
      };
}
