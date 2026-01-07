import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:file_picker/file_picker.dart';
import 'firebase_options.dart';
import 'services/firestore_service.dart';
import 'screens/project_detail_screen.dart';
import 'screens/legacy_screens.dart';
import 'utils/search_delegate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const VibeNoteApp());
}

class VibeNoteApp extends StatelessWidget {
  const VibeNoteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Vibe Note',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.deepPurple,
        textTheme: GoogleFonts.outfitTextTheme(Theme.of(context).textTheme),
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ko', 'KR'),
        Locale('en', 'US'),
      ],
      home: const ProjectListScreen(),
    );
  }
}

// 모던 그라데이션 컬러 팔레트
final List<List<Color>> modernGradients = [
  [const Color(0xFFFF6B9D), const Color(0xFFFFA06B)], // Sunset
  [const Color(0xFF4FACFE), const Color(0xFF00F2FE)], // Ocean
  [const Color(0xFFFA709A), const Color(0xFFFEE140)], // Peach
  [const Color(0xFF30CFD0), const Color(0xFF330867)], // Deep Sea
  [const Color(0xFFA8EDEA), const Color(0xFFFED6E3)], // Pastel Dream
  [const Color(0xFFFFD89B), const Color(0xFF19547B)], // Golden Hour
];

// 프로젝트 기본 아이콘 목록
final List<IconData> projectIcons = [
  Icons.folder_rounded,
  Icons.code_rounded,
  Icons.palette_rounded,
  Icons.science_rounded,
  Icons.rocket_launch_rounded,
  Icons.lightbulb_rounded,
  Icons.psychology_rounded,
  Icons.auto_awesome_rounded,
  Icons.star_rounded,
  Icons.favorite_rounded,
  Icons.emoji_events_rounded,
  Icons.workspace_premium_rounded,
];

// 프로젝트 ID를 기반으로 일관된 아이콘 반환
IconData getProjectIcon(String projectId, int? iconCodePoint) {
  // 커스텀 아이콘이 있으면 사용 (상수 아이콘 리스트에서 찾기)
  if (iconCodePoint != null) {
    // iconCodePoint가 projectIcons 리스트의 아이콘 중 하나인지 확인
    for (final icon in projectIcons) {
      if (icon.codePoint == iconCodePoint) {
        return icon; // 상수 아이콘 반환
      }
    }
    // 리스트에 없으면 동적 생성 (트리 쉐이킹 경고 발생)
    return IconData(iconCodePoint, fontFamily: 'MaterialIcons');
  }
  // 없으면 프로젝트 ID 해시값으로 일관된 아이콘 선택
  final hash = projectId.hashCode.abs();
  return projectIcons[hash % projectIcons.length];
}

class ProjectListScreen extends StatefulWidget {
  const ProjectListScreen({super.key});

  @override
  State<ProjectListScreen> createState() => _ProjectListScreenState();
}

class _ProjectListScreenState extends State<ProjectListScreen> {
  // Firestore 서비스 인스턴스
  final FirestoreService _firestoreService = FirestoreService();
  
  // 현재 조회 중인 프로젝트 상태 ('active' or 'archived')
  String _projectStatus = 'active';

  // 새 프로젝트 추가 함수
  void _addNewProject() {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController tagsController = TextEditingController(); // 태그 입력용
    final TextEditingController logoUrlController = TextEditingController();
    IconData? selectedIcon;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1E1E2E),
                  Color(0xFF2A2A3E),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 700, maxWidth: 500),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                TextField(
                  controller: titleController,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  decoration: InputDecoration(
                    labelText: '프로젝트 이름',
                    labelStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFF667EEA), width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                ),
                const SizedBox(height: 16),
                // 태그 입력 추가
                TextField(
                  controller: tagsController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: '기술 스택 / 태그 (쉼표로 구분)',
                    labelStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 14,
                    ),
                    hintText: 'Flutter, Firebase, PWA',
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFF667EEA), width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                ),
                const SizedBox(height: 16),
                // 로고 파일 선택
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '프로젝트 로고 (선택사항)',
                      style: GoogleFonts.outfit(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        try {
                          FilePickerResult? result = await FilePicker.platform.pickFiles(
                            type: FileType.image,
                            allowMultiple: false,
                            withData: true, 
                          );
                          
                          if (result != null && result.files.isNotEmpty) {
                            final file = result.files.first;
                            final bytes = file.bytes;
                            if (bytes != null && bytes.isNotEmpty) {
                              setState(() {
                                logoUrlController.text = base64Encode(bytes);
                                selectedIcon = null; // 로고 선택 시 아이콘 해제
                              });
                            }
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('파일 선택 오류: ${e.toString()}')),
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: logoUrlController.text.isNotEmpty
                                ? const Color(0xFF667EEA)
                                : Colors.white.withValues(alpha: 0.2),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF667EEA).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                logoUrlController.text.isNotEmpty
                                    ? Icons.check_circle_rounded
                                    : Icons.upload_file_rounded,
                                color: logoUrlController.text.isNotEmpty
                                    ? const Color(0xFF667EEA)
                                    : Colors.white.withValues(alpha: 0.6),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                logoUrlController.text.isNotEmpty
                                    ? '로고 선택됨 ✓'
                                    : '로고 이미지 선택하기',
                                style: GoogleFonts.outfit(
                                  color: logoUrlController.text.isNotEmpty
                                      ? const Color(0xFF667EEA)
                                      : Colors.white.withValues(alpha: 0.7),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (logoUrlController.text.isNotEmpty)
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.red, size: 18),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () {
                                  setState(() {
                                    logoUrlController.clear();
                                  });
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '또는',
                  style: GoogleFonts.outfit(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                // 아이콘 선택
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '아이콘 선택 (선택사항)',
                      style: GoogleFonts.outfit(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: projectIcons.map((icon) {
                          final isSelected = selectedIcon == icon;
                          return InkWell(
                            onTap: () {
                              setState(() {
                                selectedIcon = isSelected ? null : icon;
                                if (!isSelected) {
                                  logoUrlController.clear(); // 아이콘 선택 시 로고 URL 초기화
                                }
                              });
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isSelected 
                                    ? const Color(0xFF667EEA)
                                    : Colors.white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF667EEA)
                                      : Colors.white.withValues(alpha: 0.2),
                                  width: 1.5,
                                ),
                              ),
                              child: Icon(
                                icon,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          '취소',
                          style: GoogleFonts.outfit(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF667EEA).withValues(alpha: 0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            if (titleController.text.trim().isNotEmpty) {
                              // 태그 파싱
                              List<String> tags = tagsController.text
                                  .split(',')
                                  .map((e) => e.trim())
                                  .where((e) => e.isNotEmpty)
                                  .toList();

                              _firestoreService.addProjectWithIcon(
                                titleController.text.trim(),
                                selectedIcon?.codePoint,
                                logoUrl: logoUrlController.text.trim().isEmpty 
                                    ? null 
                                    : logoUrlController.text.trim(),
                                tags: tags,
                              );
                              Navigator.pop(context);
                            }
                          },
                          child: Text(
                            '생성하기',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
                  ),
                ),
              ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              child: Image.asset(
                'assets/images/logo.png',
                width: 28,
                height: 28,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Vibe Note',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w800,
                fontSize: 22,
                color: Colors.black87,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black87),
            onPressed: () {
              showSearch(context: context, delegate: GlobalSearchDelegate());
            },
          ),
          Container(
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF667EEA),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF667EEA).withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _addNewProject,
                borderRadius: BorderRadius.circular(10),
                child: const Padding(
                  padding: EdgeInsets.all(10),
                  child: Icon(Icons.add_rounded, color: Colors.white, size: 20),
                ),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                _buildFilterTab('진행중 (Active)', 'active'),
                _buildFilterTab('보관됨 (Archived)', 'archived'),
              ],
            ),
          ),
        ),
      ),
      body: Container(
        color: const Color(0xFFF5F7FA),
        child: StreamBuilder<QuerySnapshot>(
          stream: _firestoreService.getProjects(status: _projectStatus),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF667EEA).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        _projectStatus == 'active' 
                            ? Icons.rocket_launch_rounded 
                            : Icons.archive_rounded,
                        size: 56,
                        color: const Color(0xFF667EEA),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _projectStatus == 'active'
                          ? '새로운 프로젝트를 시작해보세요!'
                          : '보관된 프로젝트가 없습니다.',
                      style: GoogleFonts.outfit(
                        color: Colors.black87,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }

            final projects = snapshot.data!.docs;

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: projects.length,
              itemBuilder: (context, index) {
                var projectData = projects[index].data() as Map<String, dynamic>;
                String title = projectData['title'] ?? 'Untitled';
                String projectId = projects[index].id;
                int? iconCodePoint = projectData['iconCodePoint'] as int?;
                String? logoUrl = projectData['logoUrl'] as String?;
                List<String> tags = List<String>.from(projectData['tags'] ?? []);
                List<Color> gradientColors = modernGradients[index % modernGradients.length];

                return _buildProjectCard(context, projectId, title, gradientColors, iconCodePoint, logoUrl, tags);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildFilterTab(String label, String status) {
    final isSelected = _projectStatus == status;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _projectStatus = status;
          });
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.outfit(
                color: isSelected ? const Color(0xFF667EEA) : Colors.grey.shade600,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProjectCard(BuildContext context, String id, String title, List<Color> gradientColors, int? iconCodePoint, String? logoUrl, List<String> tags) {
    final projectIcon = getProjectIcon(id, iconCodePoint);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.12),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProjectDetailScreen(
                  projectId: id,
                  projectTitle: title,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 헤더: 아이콘 + 제목
                Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: logoUrl != null ? Colors.white : const Color(0xFF667EEA),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: logoUrl != null ? Colors.grey.shade300 : const Color(0xFF667EEA),
                          width: 2,
                        ),
                      ),
                      child: logoUrl != null && logoUrl.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.memory(
                                base64Decode(logoUrl),
                                width: 52,
                                height: 52,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  // 로고 로드 실패 시 기본 아이콘 표시
                                  return Icon(
                                    projectIcon,
                                    color: const Color(0xFF667EEA),
                                    size: 40,
                                  );
                                },
                              ),
                            )
                          : Icon(
                              projectIcon,
                              color: Colors.white,
                              size: 40,
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.outfit(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                              letterSpacing: -0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (tags.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              children: tags.take(3).map((tag) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF667EEA).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: const Color(0xFF667EEA).withValues(alpha: 0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  tag,
                                  style: GoogleFonts.outfit(
                                    fontSize: 10,
                                    color: const Color(0xFF667EEA),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              )).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // 구분선
                Container(
                  height: 1,
                  color: Colors.grey.shade200,
                ),
                const SizedBox(height: 10),
                // 액션 버튼들
                Row(
                  children: [
                    // 로그 버튼 (Classic View)
                    Expanded(
                      child: _buildCrispButton(
                        context,
                        icon: Icons.edit_note_rounded,
                        label: '로그',
                        color: const Color(0xFF667EEA),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LogListScreen(
                              projectId: id,
                              projectTitle: title,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // 아이디어 버튼 (Classic View)
                    Expanded(
                      child: _buildCrispButton(
                        context,
                        icon: Icons.lightbulb_rounded,
                        label: '아이디어',
                        color: const Color(0xFFEF5350),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => IdeaListScreen(
                              projectId: id,
                              projectTitle: title,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // 더보기 메뉴 (삭제/보관 등)
                    PopupMenuButton<String>(
                      onSelected: (value) async {
                        if (value == 'delete') {
                          _showDeleteConfirmDialog(context, id, title);
                        } else if (value == 'archive') {
                          await _firestoreService.updateProjectStatus(id, 'archived');
                        } else if (value == 'active') {
                          await _firestoreService.updateProjectStatus(id, 'active');
                        }
                      },
                      itemBuilder: (context) => [
                         _projectStatus == 'active' 
                         ? const PopupMenuItem(
                            value: 'archive',
                            child: Row(
                              children: [
                                Icon(Icons.archive_outlined, size: 20, color: Colors.blueGrey),
                                SizedBox(width: 8),
                                Text('보관함으로 이동'),
                              ],
                            ),
                          )
                         : const PopupMenuItem(
                            value: 'active',
                            child: Row(
                              children: [
                                Icon(Icons.unarchive_outlined, size: 20, color: Colors.blueGrey),
                                SizedBox(width: 8),
                                Text('활성화 (복구)'),
                              ],
                            ),
                          ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline, size: 20, color: Colors.red),
                              SizedBox(width: 8),
                              Text('삭제', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 1.5,
                          ),
                        ),
                        child: Icon(Icons.more_horiz_rounded, size: 20, color: Colors.grey.shade600),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCrispButton(BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool iconOnly = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: 10,
          horizontal: iconOnly ? 10 : 12,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.15),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: iconOnly
            ? Icon(icon, size: 20, color: color)
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 18, color: color),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: color,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, String projectId, String title) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1E1E2E),
                Color(0xFF2A2A3E),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.red.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.delete_rounded,
                  color: Colors.red,
                  size: 48,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '프로젝트 삭제',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "'$title' 프로젝트를 삭제하시겠습니까?",
                style: GoogleFonts.outfit(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '이 작업은 되돌릴 수 없습니다.',
                style: GoogleFonts.outfit(
                  color: Colors.red.withValues(alpha: 0.8),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        '취소',
                        style: GoogleFonts.outfit(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF6B6B), Color(0xFFEE5A6F)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          try {
                            await _firestoreService.deleteProject(projectId);
                            if (context.mounted) {
                              Navigator.pop(context);
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('삭제 실패: $e')),
                              );
                              Navigator.pop(context);
                            }
                          }
                        },
                        child: Text(
                          '삭제',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
