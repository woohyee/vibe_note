import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/firestore_service.dart';

class ProjectDetailScreen extends StatefulWidget {
  final String projectId;
  final String projectTitle;
  final String? initialType; // 'log', 'idea', 'todo' or null
  
  const ProjectDetailScreen({
    super.key, 
    required this.projectId, 
    required this.projectTitle,
    this.initialType,
  });

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _recordController = TextEditingController();
  
  late String _selectedType;
  String _filterType = 'all'; // 'all', 'log', 'idea', 'todo'
  
  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType ?? 'log';
    // 초기 필터도 선택된 타입에 맞출까요? 아니면 전체로 둘까요? 
    // 사용자가 '로그'를 눌러 들어왔다면 보통 로그만 보길 원할 수 있습니다.
    if (widget.initialType != null) {
      _filterType = widget.initialType!;
    }
  }

  Widget _buildFilterChip(String type, String label) {
    bool isSelected = _filterType == type;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _filterType = type;
          });
        }
      },
      selectedColor: const Color(0xFF667EEA).withValues(alpha: 0.2),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF667EEA) : Colors.grey.shade600,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 13,
      ),
      backgroundColor: Colors.white,
      side: BorderSide(
        color: isSelected ? const Color(0xFF667EEA) : Colors.grey.shade200,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }

  void _showEditRecordDialog(String docId, String currentContent) {
    final controller = TextEditingController(text: currentContent);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('기록 수정'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          minLines: 1,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                _firestoreService.updateRecord(widget.projectId, docId, {'content': controller.text.trim()});
                Navigator.pop(context);
              }
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }
  
  // 기록 추가
  void _addRecord() {
    if (_recordController.text.trim().isEmpty) return;
    
    _firestoreService.addRecord(
      widget.projectId, 
      _recordController.text.trim(), 
      _selectedType
    );
    
    _recordController.clear();
    // 키보드는 유지 (연속 입력을 위해)
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _firestoreService.getProject(widget.projectId),
      builder: (context, projectSnapshot) {
        if (!projectSnapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final projectData = projectSnapshot.data!.data() as Map<String, dynamic>? ?? {};
        final projectTitle = projectData['title'] ?? widget.projectTitle;

        return Scaffold(
          backgroundColor: const Color(0xFFF5F7FA),
          appBar: AppBar(
            title: InkWell(
              onTap: () => _showEditProjectDialog(context, widget.projectId, projectData),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      projectTitle,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.edit_rounded, size: 14, color: Colors.grey.shade400),
                  ],
                ),
              ),
            ),
            elevation: 0,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            iconTheme: const IconThemeData(color: Colors.black87),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () => _showEditProjectDialog(context, widget.projectId, projectData),
              ),
            ],
          ),
          body: Column(
            children: [
              // 1. 요약 섹션 (도메인, 치트시트)
              _buildSummarySection(projectData),
              
              // 2. 통합 기록 리스트 (Timeline)
              // 필터 탭
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    _buildFilterChip('all', '전체'),
                    const SizedBox(width: 8),
                    _buildFilterChip('log', 'Log'),
                    const SizedBox(width: 8),
                    _buildFilterChip('idea', 'Idea'),
                    const SizedBox(width: 8),
                    _buildFilterChip('todo', 'Todo'),
                  ],
                ),
              ),
              
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _firestoreService.getRecords(widget.projectId),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }
                    
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    
                    final allRecords = snapshot.data?.docs ?? [];
                    // 클라이언트 사이드 필터링
                    final records = _filterType == 'all' 
                        ? allRecords 
                        : allRecords.where((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            return data['type'] == _filterType;
                          }).toList();
                    
                    if (records.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.filter_list_off, size: 60, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            Text(
                              _filterType == 'all' 
                                  ? '아직 기록이 없습니다.\n오늘의 작업을 기록해보세요!' 
                                  : '${_filterType.toUpperCase()} 기록이 없습니다.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(
                                color: Colors.grey.shade500,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                      itemCount: records.length,
                      itemBuilder: (context, index) {
                        final data = records[index].data() as Map<String, dynamic>;
                        final docId = records[index].id;
                        return _buildRecordItem(docId, data);
                      },
                    );
                  },
                ),
              ),
              
              // 3. 통합 입력바
              _buildInputArea(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummarySection(Map<String, dynamic> projectData) {
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          '📂 프로젝트 정보 및 리소스',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
        subtitle: Text(
          '기술 스택, 도메인, 치트시트 관리',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
        ),
        initiallyExpanded: false, // 기본적으로 닫힘 상태
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          // 1. 기술 스택 및 설명
          _buildProjectMeta(projectData),
          const SizedBox(height: 20),
          
          // 2. 도메인 정보
          _buildDomainSection(projectData),
          const SizedBox(height: 20),
          
          // 3. 치트시트 & 참고자료
          _buildCheatsheetSection(),
        ],
      ),
    );
  }

  Widget _buildProjectMeta(Map<String, dynamic> projectData) {
    final String description = projectData['description'] ?? '';
    final List<dynamic> tags = projectData['tags'] ?? [];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('📌 프로젝트 개요', style: _sectionHeaderStyle),
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 16, color: Colors.grey),
              onPressed: () => _showEditProjectDialog(context, widget.projectId, projectData),
              constraints: const BoxConstraints(),
              padding: EdgeInsets.zero,
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (description.isNotEmpty)
          Text(description, style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.4))
        else
          Text('설명이 없습니다.', style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
          
        const SizedBox(height: 12),
        if (tags.isNotEmpty)
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: tags.map((tag) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                '#$tag',
                style: GoogleFonts.firaCode(fontSize: 12, color: Colors.grey.shade700),
              ),
            )).toList(),
          )
        else
          Text('등록된 기술 스택이 없습니다.', style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
      ],
    );
  }

  Widget _buildDomainSection(Map<String, dynamic> projectData) {
    final domainMap = projectData['domain'] as Map<String, dynamic>?;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('🌐 도메인 정보', style: _sectionHeaderStyle),
            if (domainMap == null)
              IconButton(
                icon: const Icon(Icons.add_circle_outline, size: 16, color: Color(0xFF667EEA)),
                onPressed: _showEditDomainDialog,
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (domainMap != null)
          _buildDomainCard(domainMap)
        else
          Text(
            '등록된 도메인 정보가 없습니다.',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
          ),
      ],
    );
  }

  Widget _buildCheatsheetSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestoreService.getCheatsheets(widget.projectId),
      builder: (context, snapshot) {
        final cheatsheets = snapshot.data?.docs ?? [];
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('💻 치트시트 / 참고자료', style: _sectionHeaderStyle),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, size: 16, color: Color(0xFF667EEA)),
                  onPressed: _showAddCheatsheetDialog,
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (cheatsheets.isEmpty)
              Text('자주 쓰는 명령어나 참고 링크를 등록하세요.', style: TextStyle(color: Colors.grey.shade400, fontSize: 13))
            else
              ...cheatsheets.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return _buildCheatsheetItem(doc.id, data);
              }).toList(),
          ],
        );
      },
    );
  }

  TextStyle get _sectionHeaderStyle => GoogleFonts.outfit(
    fontWeight: FontWeight.w600,
    fontSize: 13,
    color: Colors.grey.shade700,
  );

  Widget _buildDomainCard(Map<String, dynamic> domain) {
    final String name = domain['name'] ?? 'Unknown Domain';
    final String registrar = domain['registrar'] ?? '';
    final String expiryStr = domain['expiryDate'] ?? '';
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4FF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF667EEA).withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.public, color: Color(0xFF667EEA), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                if (expiryStr.isNotEmpty)
                  Text(
                    'Exp: $expiryStr${registrar.isNotEmpty ? ' | $registrar' : ''}',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.grey),
            onPressed: () => _showEditDomainDialog(initialData: domain),
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(8),
          ),
        ],
      ),
    );
  }

  Widget _buildCheatsheetItem(String docId, Map<String, dynamic> data) {
    final String command = data['command'] ?? '';
    final String desc = data['description'] ?? '';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  command,
                  style: GoogleFonts.firaCode(
                    fontSize: 13,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (desc.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    desc,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy_rounded, size: 16, color: Colors.grey),
            onPressed: () {
              // TODO: 클립보드 복사
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('명령어가 복사되었습니다 (구현 예정)')),
              );
            },
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(4),
          ),
        ],
      ),
    );
  }

  void _showAddCheatsheetDialog() {
    final cmdController = TextEditingController();
    final descController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('치트시트 추가'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: cmdController,
              decoration: const InputDecoration(labelText: '명령어 / 코드', hintText: 'git commit -m "..."'),
            ),
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: '설명', hintText: '커밋 메시지 작성'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
          TextButton(
            onPressed: () {
              if (cmdController.text.isNotEmpty) {
                _firestoreService.addCheatsheet(
                  widget.projectId, 
                  cmdController.text.trim(), 
                  descController.text.trim(),
                  [] 
                );
                Navigator.pop(context);
              }
            },
            child: const Text('추가'),
          ),
        ],
      ),
    );
  }

  void _showEditDomainDialog({Map<String, dynamic>? initialData}) {
    final nameController = TextEditingController(text: initialData?['name']);
    final registrarController = TextEditingController(text: initialData?['registrar']);
    final expiryController = TextEditingController(text: initialData?['expiryDate']);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('도메인 정보 수정'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: '도메인 이름', hintText: 'example.com'),
              ),
              TextField(
                controller: registrarController,
                decoration: const InputDecoration(labelText: '등록 대행업체 (Registrar)', hintText: 'GoDaddy, AWS...'),
              ),
              TextField(
                controller: expiryController,
                decoration: const InputDecoration(labelText: '만료 예정일', hintText: 'YYYY-MM-DD'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
          TextButton(
            onPressed: () {
              final domainData = {
                'name': nameController.text.trim(),
                'registrar': registrarController.text.trim(),
                'expiryDate': expiryController.text.trim(),
              };
              _firestoreService.updateProject(widget.projectId, {'domain': domainData});
              Navigator.pop(context);
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRecordItem(String docId, Map<String, dynamic> data) {
    String type = data['type'] ?? 'log';
    String content = data['content'] ?? '';
    Timestamp? ts = data['createdAt'] as Timestamp?;
    String timeStr = ts != null 
        ? DateFormat('MM/dd HH:mm').format(ts.toDate()) 
        : '';
    bool isCompleted = data['isCompleted'] ?? false;
    
    Color typeColor;
    IconData typeIcon;
    
    switch (type) {
      case 'idea':
        typeColor = const Color(0xFFEF5350);
        typeIcon = Icons.lightbulb_outline;
        break;
      case 'todo':
        typeColor = const Color(0xFF66BB6A);
        typeIcon = Icons.check_circle_outline;
        break;
      case 'log':
      default:
        typeColor = const Color(0xFF667EEA);
        typeIcon = Icons.edit_note;
        break;
    }

    return Dismissible(
      key: Key(docId),
      background: Container(
        color: Colors.red.withValues(alpha: 0.1),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline, color: Colors.red),
      ),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('기록 삭제'),
            content: const Text('이 기록을 삭제하시겠습니까?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
              TextButton(
                onPressed: () => Navigator.pop(context, true), 
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('삭제'),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        _firestoreService.deleteRecord(widget.projectId, docId);
      },
      child: InkWell(
        onTap: () => _showEditRecordDialog(docId, content),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 타입 아이콘
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: typeColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(typeIcon, size: 18, color: typeColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        type.toUpperCase(),
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: typeColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        timeStr,
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          color: Colors.grey.shade400,
                        ),
                      ),
                      const Spacer(),
                      // Todo 체크박스
                      if (type == 'todo')
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: isCompleted,
                            activeColor: typeColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            onChanged: (val) {
                              _firestoreService.updateRecord(
                                widget.projectId, 
                                docId, 
                                {'isCompleted': val}
                              );
                            },
                          ),
                        ),
                      // 더보기 메뉴 (타입 변경 등)
                      PopupMenuButton<String>(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Icon(Icons.more_horiz, size: 16, color: Colors.grey.shade400),
                        onSelected: (val) {
                          _firestoreService.updateRecord(
                            widget.projectId, 
                            docId, 
                            {'type': val}
                          );
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 'log', child: Text('To Log')),
                          const PopupMenuItem(value: 'idea', child: Text('To Idea')),
                          const PopupMenuItem(value: 'todo', child: Text('To Todo')),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    content,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.4,
                      color: Colors.black87,
                      decoration: (type == 'todo' && isCompleted) 
                          ? TextDecoration.lineThrough 
                          : null,
                      decorationColor: Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            Row(
              children: [
                // 타입 선택기
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      _buildTypeSelector('log', Icons.edit_note),
                      _buildTypeSelector('idea', Icons.lightbulb_outline),
                      _buildTypeSelector('todo', Icons.check_circle_outline),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TextField(
                      controller: _recordController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: _selectedType == 'log' 
                            ? '오늘의 작업 내용과 내일 할 일을 기록하세요.' 
                            : _selectedType == 'idea' 
                                ? '떠오르는 아이디어를 자유롭게 적어보세요.'
                                : '할 일을 입력하세요.',
                        hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      minLines: 1,
                      maxLines: 4,
                      onSubmitted: (_) => _addRecord(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _addRecord,
                  icon: const Icon(Icons.send_rounded),
                  color: const Color(0xFF667EEA),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF667EEA).withValues(alpha: 0.1),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTypeSelector(String type, IconData icon) {
    bool isSelected = _selectedType == type;
    Color color;
    switch (type) {
      case 'idea': color = const Color(0xFFEF5350); break;
      case 'todo': color = const Color(0xFF66BB6A); break;
      default: color = const Color(0xFF667EEA); break;
    }
    
    return InkWell(
      onTap: () {
        setState(() {
          _selectedType = type;
        });
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected 
              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 2)] 
              : null,
        ),
        child: Icon(
          icon, 
          size: 20, 
          color: isSelected ? color : Colors.grey.shade400
        ),
      ),
    );
  }

  void _showEditProjectDialog(BuildContext context, String projectId, Map<String, dynamic> currentData) {
    final titleController = TextEditingController(text: currentData['title']);
    final tags = (currentData['tags'] as List<dynamic>? ?? []).map((e) => e.toString()).toList();
    final tagsController = TextEditingController(text: tags.join(', '));
    final descController = TextEditingController(text: currentData['description'] ?? '');
    String? logoUrl = currentData['logoUrl'];
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('프로젝트 정보 수정'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 로고 편집
                  GestureDetector(
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
                          if (bytes != null) {
                            setState(() {
                              logoUrl = base64Encode(bytes);
                            });
                          }
                        }
                      } catch (e) {
                         debugPrint('Error picking file: $e');
                      }
                    },
                    child: Center(
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade300),
                          image: logoUrl != null 
                              ? DecorationImage(
                                  image: MemoryImage(base64Decode(logoUrl!)),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: logoUrl == null 
                            ? const Icon(Icons.add_a_photo_outlined, color: Colors.grey)
                            : null,
                      ),
                    ),
                  ),
                  if (logoUrl != null)
                    Center(
                      child: TextButton(
                        onPressed: () => setState(() => logoUrl = null),
                        child: const Text('로고 삭제', style: TextStyle(color: Colors.red, fontSize: 12)),
                      ),
                    ),
                  const SizedBox(height: 16),
                  
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: '프로젝트 이름', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: tagsController,
                    decoration: const InputDecoration(labelText: '태그 (쉼표로 구분)', border: OutlineInputBorder(), hintText: 'Flutter, Firebase'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descController,
                    decoration: const InputDecoration(labelText: '설명', border: OutlineInputBorder()),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
              ElevatedButton(
                onPressed: () {
                  if (titleController.text.trim().isNotEmpty) {
                    final newTags = tagsController.text
                        .split(',')
                        .map((e) => e.trim())
                        .where((e) => e.isNotEmpty)
                        .toList();
                        
                    _firestoreService.updateProject(projectId, {
                      'title': titleController.text.trim(),
                      'tags': newTags,
                      'description': descController.text.trim(),
                      'logoUrl': logoUrl,
                    });
                    
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF667EEA),
                  foregroundColor: Colors.white,
                ),
                child: const Text('저장'),
              ),
            ],
          );
        }
      ),
    );
  }
}
