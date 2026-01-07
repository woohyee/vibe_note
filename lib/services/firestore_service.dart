import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  // Firestore 인스턴스 가져오기
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 프로젝트 컬렉션 이름 정의
  final String _collectionPath = 'projects';

  // 프로젝트 목록 실시간 스트림 가져오기
  // status가 'active'인 프로젝트만 가져옵니다. (기본값)
  Stream<QuerySnapshot> getProjects({String status = 'active'}) {
    return _db
        .collection(_collectionPath)
        .where('status', isEqualTo: status)
        .orderBy('lastUpdatedAt', descending: true)
        .snapshots();
  }

  Stream<DocumentSnapshot> getProject(String projectId) {
    return _db.collection(_collectionPath).doc(projectId).snapshots();
  }

  // 새 프로젝트 추가
  Future<void> addProject(String title) async {
    await addProjectWithIcon(title, null);
  }

  // 아이콘과 함께 프로젝트 추가 (메타데이터 포함)
  Future<void> addProjectWithIcon(String title, int? iconCodePoint, {
    String? logoUrl,
    List<String> tags = const [],
    Map<String, String> links = const {},
    String? description,
  }) async {
    final data = {
      'title': title,
      'status': 'active', // 기본 상태
      'tags': tags,
      'links': links,
      'description': description ?? '',
      'createdAt': FieldValue.serverTimestamp(),
      'lastUpdatedAt': FieldValue.serverTimestamp(),
    };
    
    if (logoUrl != null && logoUrl.isNotEmpty) {
      data['logoUrl'] = logoUrl;
    }
    
    if (iconCodePoint != null) {
      data['iconCodePoint'] = iconCodePoint;
    }
    
    await _db.collection(_collectionPath).add(data);
  }

  // 프로젝트 메타데이터 업데이트
  Future<void> updateProject(String projectId, Map<String, dynamic> data) async {
    data['lastUpdatedAt'] = FieldValue.serverTimestamp();
    await _db.collection(_collectionPath).doc(projectId).update(data);
  }

  // 프로젝트 상태 변경 (Archive/Unarchive)
  Future<void> updateProjectStatus(String projectId, String status) async {
    await updateProject(projectId, {'status': status});
  }

  // 프로젝트 삭제
  Future<void> deleteProject(String projectId) async {
    await _db.collection(_collectionPath).doc(projectId).delete();
  }

  // --- 통합 기록 (Records: Log, Idea, Todo) ---
  
  // 모든 기록 가져오기 (시간순)
  Stream<QuerySnapshot> getRecords(String projectId) {
    return _db
        .collection(_collectionPath)
        .doc(projectId)
        .collection('records')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // 기록 추가
  Future<void> addRecord(String projectId, String content, String type) async {
    // 1. 기록 추가
    await _db
        .collection(_collectionPath)
        .doc(projectId)
        .collection('records')
        .add({
      'content': content,
      'type': type, // 'log', 'idea', 'todo'
      'isCompleted': false, // todo인 경우 사용
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 2. 프로젝트의 lastUpdatedAt 업데이트
    await _db.collection(_collectionPath).doc(projectId).update({
      'lastUpdatedAt': FieldValue.serverTimestamp(),
    });
  }

  // 기록 수정
  Future<void> updateRecord(String projectId, String recordId, Map<String, dynamic> data) async {
    await _db
        .collection(_collectionPath)
        .doc(projectId)
        .collection('records')
        .doc(recordId)
        .update(data);
  }

  // 기록 삭제
  Future<void> deleteRecord(String projectId, String recordId) async {
    await _db
        .collection(_collectionPath)
        .doc(projectId)
        .collection('records')
        .doc(recordId)
        .delete();
  }

  // --- 치트시트 (Cheatsheets) ---
  Stream<QuerySnapshot> getCheatsheets(String projectId) {
    return _db
        .collection(_collectionPath)
        .doc(projectId)
        .collection('cheatsheets')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
  
  Future<void> addCheatsheet(String projectId, String command, String description, List<String> tags) async {
    await _db
        .collection(_collectionPath)
        .doc(projectId)
        .collection('cheatsheets')
        .add({
      'command': command,
      'description': description,
      'tags': tags,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // --- 검색 (Collection Group) ---
  Future<List<QueryDocumentSnapshot>> searchRecords(String query) async {
    // 간단한 접두사 검색
    final snapshot = await _db
        .collectionGroup('records')
        .where('content', isGreaterThanOrEqualTo: query)
        .where('content', isLessThan: query + '\uf8ff')
        .get();
    return snapshot.docs;
  }

  Future<List<QueryDocumentSnapshot>> searchCheatsheets(String query) async {
    final snapshot = await _db
        .collectionGroup('cheatsheets')
        .where('command', isGreaterThanOrEqualTo: query)
        .where('command', isLessThan: query + '\uf8ff')
        .get();
    return snapshot.docs;
  }
  // --- Legacy Collections (복구용) ---
  
  Stream<QuerySnapshot> getLogs(String projectId) {
    return _db
        .collection(_collectionPath)
        .doc(projectId)
        .collection('logs')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> getIdeas(String projectId) {
    return _db
        .collection(_collectionPath)
        .doc(projectId)
        .collection('ideas')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> addLog(String projectId, String content) async {
    await _db
        .collection(_collectionPath)
        .doc(projectId)
        .collection('logs')
        .add({
      'content': content,
      'createdAt': FieldValue.serverTimestamp(),
    });
    // 프로젝트 업데이트 시간 갱신
    await _db.collection(_collectionPath).doc(projectId).update({
      'lastUpdatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> addIdea(String projectId, String content) async {
    await _db
        .collection(_collectionPath)
        .doc(projectId)
        .collection('ideas')
        .add({
      'content': content,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await _db.collection(_collectionPath).doc(projectId).update({
      'lastUpdatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Legacy Update/Delete Methods
  Future<void> updateLog(String projectId, String logId, String content) async {
    await _db
        .collection(_collectionPath)
        .doc(projectId)
        .collection('logs')
        .doc(logId)
        .update({'content': content});
  }

  Future<void> deleteLog(String projectId, String logId) async {
    await _db
        .collection(_collectionPath)
        .doc(projectId)
        .collection('logs')
        .doc(logId)
        .delete();
  }

  Future<void> updateIdea(String projectId, String ideaId, String content) async {
    await _db
        .collection(_collectionPath)
        .doc(projectId)
        .collection('ideas')
        .doc(ideaId)
        .update({'content': content});
  }

  Future<void> deleteIdea(String projectId, String ideaId) async {
    await _db
        .collection(_collectionPath)
        .doc(projectId)
        .collection('ideas')
        .doc(ideaId)
        .delete();
  }
}
