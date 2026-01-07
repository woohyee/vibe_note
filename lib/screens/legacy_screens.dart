import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/firestore_service.dart';

class LogListScreen extends StatefulWidget {
  final String projectId;
  final String projectTitle;

  const LogListScreen({super.key, required this.projectId, required this.projectTitle});

  @override
  State<LogListScreen> createState() => _LogListScreenState();
}

class _LogListScreenState extends State<LogListScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _controller = TextEditingController();

  void _addLog() {
    if (_controller.text.trim().isEmpty) return;
    _firestoreService.addLog(widget.projectId, _controller.text.trim());
    _controller.clear();
  }

  Future<void> _updateLog(String docId, String currentContent) async {
    final controller = TextEditingController(text: currentContent);
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('로그 수정'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                _firestoreService.updateLog(widget.projectId, docId, controller.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteLog(String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('로그 삭제'),
        content: const Text('이 로그를 정말 삭제하시겠습니까?'),
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

    if (confirm == true) {
      await _firestoreService.deleteLog(widget.projectId, docId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text('${widget.projectTitle} Logs', style: GoogleFonts.outfit(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: '오늘 완료한 작업과 내일 할 일 기록',
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _addLog(),
                    ),
                  ),
                  IconButton(onPressed: _addLog, icon: const Icon(Icons.send, color: Color(0xFF667EEA))),
                ],
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestoreService.getLogs(widget.projectId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return Center(child: Text('작업 로그가 없습니다.', style: GoogleFonts.outfit(color: Colors.grey)));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final docId = docs[index].id;
                    final date = (data['createdAt'] as Timestamp?)?.toDate();
                    final dateStr = date != null ? DateFormat('MM/dd HH:mm').format(date) : '';
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(dateStr, style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey)),
                                Row(
                                  children: [
                                    InkWell(
                                      onTap: () => _updateLog(docId, data['content'] ?? ''),
                                      child: const Padding(
                                        padding: EdgeInsets.all(4.0),
                                        child: Icon(Icons.edit, size: 16, color: Colors.grey),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    InkWell(
                                      onTap: () => _deleteLog(docId),
                                      child: const Padding(
                                        padding: EdgeInsets.all(4.0),
                                        child: Icon(Icons.delete, size: 16, color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(data['content'] ?? '', style: const TextStyle(fontSize: 15)),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class IdeaListScreen extends StatefulWidget {
  final String projectId;
  final String projectTitle;

  const IdeaListScreen({super.key, required this.projectId, required this.projectTitle});

  @override
  State<IdeaListScreen> createState() => _IdeaListScreenState();
}

class _IdeaListScreenState extends State<IdeaListScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _controller = TextEditingController();

  void _addIdea() {
    if (_controller.text.trim().isEmpty) return;
    _firestoreService.addIdea(widget.projectId, _controller.text.trim());
    _controller.clear();
  }

  Future<void> _updateIdea(String docId, String currentContent) async {
    final controller = TextEditingController(text: currentContent);
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('아이디어 수정'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                _firestoreService.updateIdea(widget.projectId, docId, controller.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteIdea(String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('아이디어 삭제'),
        content: const Text('이 아이디어를 정말 삭제하시겠습니까?'),
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

    if (confirm == true) {
      await _firestoreService.deleteIdea(widget.projectId, docId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text('${widget.projectTitle} Ideas', style: GoogleFonts.outfit(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: '번뜩이는 아이디어 기록',
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _addIdea(),
                    ),
                  ),
                  IconButton(onPressed: _addIdea, icon: const Icon(Icons.lightbulb, color: Color(0xFFEF5350))),
                ],
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestoreService.getIdeas(widget.projectId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return Center(child: Text('아이디어가 없습니다.', style: GoogleFonts.outfit(color: Colors.grey)));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final docId = docs[index].id;
                    final date = (data['createdAt'] as Timestamp?)?.toDate();
                    final dateStr = date != null ? DateFormat('MM/dd HH:mm').format(date) : '';
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(dateStr, style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey)),
                                Row(
                                  children: [
                                    InkWell(
                                      onTap: () => _updateIdea(docId, data['content'] ?? ''),
                                      child: const Padding(
                                        padding: EdgeInsets.all(4.0),
                                        child: Icon(Icons.edit, size: 16, color: Colors.grey),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    InkWell(
                                      onTap: () => _deleteIdea(docId),
                                      child: const Padding(
                                        padding: EdgeInsets.all(4.0),
                                        child: Icon(Icons.delete, size: 16, color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(data['content'] ?? '', style: const TextStyle(fontSize: 15)),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
