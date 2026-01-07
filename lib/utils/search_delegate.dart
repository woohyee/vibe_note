import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import '../screens/project_detail_screen.dart';

class GlobalSearchDelegate extends SearchDelegate {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  String? get searchFieldLabel => '프로젝트, 기록, 치트시트 검색';

  @override
  TextStyle? get searchFieldStyle => GoogleFonts.outfit(fontSize: 16);

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = '';
            showSuggestions(context);
          },
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    if (query.trim().isEmpty) {
      return const Center(child: Text('검색어를 입력하세요'));
    }

    // 여러 검색을 병렬로 수행
    return FutureBuilder(
      future: Future.wait([
        // 1. 프로젝트 검색 (제목)
        FirebaseFirestore.instance
            .collection('projects')
            .where('title', isGreaterThanOrEqualTo: query)
            .where('title', isLessThan: query + '\uf8ff')
            .get(),
        // 2. 기록 검색
        _firestoreService.searchRecords(query),
        // 3. 치트시트 검색
        _firestoreService.searchCheatsheets(query),
      ]),
      builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final projectDocs = (snapshot.data![0] as QuerySnapshot).docs;
        final recordDocs = snapshot.data![1] as List<QueryDocumentSnapshot>;
        final cheatsheetDocs = snapshot.data![2] as List<QueryDocumentSnapshot>;

        if (projectDocs.isEmpty && recordDocs.isEmpty && cheatsheetDocs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off_rounded, size: 60, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text(
                  '검색 결과가 없습니다.',
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

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (projectDocs.isNotEmpty) ...[
              _buildSectionHeader('Projects'),
              ...projectDocs.map((doc) => _buildProjectResult(context, doc)),
              const SizedBox(height: 20),
            ],
            if (cheatsheetDocs.isNotEmpty) ...[
              _buildSectionHeader('Cheatsheets'),
              ...cheatsheetDocs.map((doc) => _buildCheatsheetResult(context, doc)),
              const SizedBox(height: 20),
            ],
            if (recordDocs.isNotEmpty) ...[
              _buildSectionHeader('Records'),
              ...recordDocs.map((doc) => _buildRecordResult(context, doc)),
            ],
          ],
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    // 최근 검색어 보여주거나 비워둠
    return Container();
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildProjectResult(BuildContext context, DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ListTile(
      leading: const Icon(Icons.folder_outlined, color: Color(0xFF667EEA)),
      title: Text(data['title'] ?? '제목 없음', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
      subtitle: Text('프로젝트로 이동', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
      onTap: () {
        close(context, null);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProjectDetailScreen(
              projectId: doc.id,
              projectTitle: data['title'] ?? '',
            ),
          ),
        );
      },
    );
  }

  Widget _buildCheatsheetResult(BuildContext context, QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    // cheatsheet parent is project. Need projectId.
    // doc.reference.parent.parent?.id should give projectId for subcollection
    final projectId = doc.reference.parent.parent?.id;

    return ListTile(
      leading: const Icon(Icons.code, color: Colors.orange),
      title: Text(data['command'] ?? '', style: GoogleFonts.firaCode(fontWeight: FontWeight.w500)),
      subtitle: Text(data['description'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
      onTap: () {
        if (projectId != null) {
          close(context, null);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProjectDetailScreen(
                projectId: projectId,
                projectTitle: '프로젝트 이동...', // Title fetching is async, assume generic or fetch?
                // For now, placeholder. User can close back.
              ),
            ),
          );
        }
      },
    );
  }

  Widget _buildRecordResult(BuildContext context, QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final projectId = doc.reference.parent.parent?.id;
    final type = data['type'] ?? 'log';
    
    IconData icon;
    Color color;
    switch (type) {
      case 'idea': icon = Icons.lightbulb_outline; color = Colors.redAccent; break;
      case 'todo': icon = Icons.check_circle_outline; color = Colors.green; break;
      default: icon = Icons.edit_note; color = Colors.blue; break;
    }

    return ListTile(
      leading: Icon(icon, color: color, size: 20),
      title: Text(data['content'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis),
      onTap: () {
         if (projectId != null) {
          close(context, null);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProjectDetailScreen(
                projectId: projectId,
                projectTitle: '프로젝트 이동...',
              ),
            ),
          );
        }
      },
    );
  }
}
