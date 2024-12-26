import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:team_project/const/colors.dart';
import 'package:team_project/login_logic/login.dart';
import 'package:google_sign_in/google_sign_in.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController chatPageController = PageController();
  final PageController topContestsPageController = PageController();
  List<Map<String, dynamic>> myChatRooms = [];
  List<Map<String, dynamic>> topVisitedContests = [];
  String searchQuery = '';
  final Map<String, List<Map<String, String>>> chatMessages = {}; // 각 채팅방의 메시지 저장

  @override
  void initState() {
    super.initState();
    loadUserChatRooms();
    fetchTopVisitedContests();
  }

  /// Firebase Realtime Database에서 사용자가 참여한 채팅방 로드
  Future<void> loadUserChatRooms() async {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? 'unknown';
    final chatRef = FirebaseDatabase.instance.ref('chatRooms');
    List<Map<String, dynamic>> chatRooms = [];

    try {
      final snapshot = await chatRef.get();
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;

        for (var contestId in data.keys) {
          final messages = data[contestId];
          if (messages is! Map<dynamic, dynamic>) continue;

          final hasUserMessage = messages.values.any((message) {
            if (message is! Map<dynamic, dynamic>) return false;
            final messageData = Map<String, dynamic>.from(message);
            return messageData['userId'] == userId;
          });

          if (hasUserMessage) {
            final contestSnapshot = await FirebaseFirestore.instance
                .collection('contests')
                .doc(contestId)
                .get();

            if (contestSnapshot.exists) {
              final contestData = contestSnapshot.data()!;
              chatRooms.add({
                "contestId": contestId,
                "title": contestData['title'] ?? '제목 없음',
              });

              // 채팅 메시지 로드
              final chatRoomMessages = messages.entries.map((entry) {
                final value = Map<String, String>.from(entry.value as Map);
                return {
                  'user': value['user'] ?? '익명',
                  'message': value['message'] ?? '',
                };
              }).toList();

              chatMessages[contestId] = chatRoomMessages;
            }
          }
        }

        setState(() {
          myChatRooms = chatRooms;
        });
      }
    } catch (e) {
      print('채팅방 데이터를 로드하는 중 오류 발생: $e');
    }
  }

  /// Firestore에서 방문자 수 기준 상위 3개 공모전 로드
  Future<void> fetchTopVisitedContests() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('contests')
          .orderBy('visit', descending: true)
          .limit(3)
          .get();

      setState(() {
        topVisitedContests = snapshot.docs.map((doc) {
          return {
            "id": doc.id,
            "title": doc['title'],
            "image": doc['image'] ?? 'assets/img/default.jpg',
            "visit": doc['visit'] ?? 0,
          };
        }).toList();
      });
    } catch (e) {
      print('방문자 수 기준 상위 공모전 데이터를 로드하는 중 오류 발생: $e');
    }
  }

  Future<void> _logout(BuildContext context) async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();

      if (await googleSignIn.isSignedIn()) {
        await googleSignIn.signOut();
      }

      await FirebaseAuth.instance.signOut();

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const Login()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("로그아웃 중 오류가 발생했습니다: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            hintText: '검색어를 입력하세요',
            prefixIcon: Icon(Icons.search),
            filled: true,
            fillColor: Color(0xFFF8F8FF),
          ),
          onChanged: (query) {
            setState(() {
              searchQuery = query;
            });
          },
        ),
        backgroundColor: const Color(0xFF1876FB),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "[내가 참여한 채팅방]",
                          style: TextStyle(color: Color(0xFF1876FB),
                              fontSize: 18,
                            fontWeight: FontWeight.bold,),
                        ),

                        const SizedBox(height: 10),
                        SizedBox(
                          height: 200, // 높이를 줄임
                          child: myChatRooms.isEmpty
                              ? const Center(
                            child: Text(
                              "참여한 채팅방이 없습니다.",
                              style: TextStyle(color: Colors.white),
                            ),
                          )
                              : PageView.builder(
                            controller: chatPageController,
                            scrollDirection: Axis.horizontal,
                            itemCount: myChatRooms.length,
                            itemBuilder: (context, index) {
                              final chatRoom = myChatRooms[index];
                              final messages = chatMessages[chatRoom['contestId']] ?? [];
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    chatRoom['title'] ?? '제목 없음',
                                    style: const TextStyle(
                                      color: Color(0xFF020715),
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 5), // 여백을 줄임
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF8F8FF),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all( // 테두리 추가
                                          color: Color(0xFF1876FB), // 테두리 색상
                                          width: 2.0, // 테두리 두께
                                        ),
                                      ),
                                      padding: const EdgeInsets.all(8.0), // 내부 패딩을 줄임
                                      child: messages.isEmpty
                                          ? const Center(
                                        child: Text(
                                          "메시지가 없습니다.",
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 14,
                                          ),
                                        ),
                                      )
                                          : ListView.builder(
                                        itemCount: messages.length,
                                        itemBuilder: (context, messageIndex) {
                                          final message = messages[messageIndex];
                                          return ListTile(
                                            title: Text(
                                              message['user'] ?? '익명',
                                              style: const TextStyle(
                                                color: Colors.black,
                                                fontSize: 12,
                                                  fontWeight: FontWeight.bold
                                              ),
                                            ),
                                            subtitle: Container(
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                border: Border.all(
                                                  color: Colors.grey,
                                                  width: 1.0,
                                                ),
                                                borderRadius: BorderRadius.circular(5),
                                              ),
                                              padding: const EdgeInsets.all(8.0),
                                              margin: const EdgeInsets.only(top:4.0),
                                              child: Text(
                                                message['message'] ?? '',
                                                style: const TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 15,
                                                ),
                                                )
                                              ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),

                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "[방문자가 많은 공모전]",
                          style: TextStyle(
                            color: Color(0xFF1876FB),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 200,
                          child: topVisitedContests.isEmpty
                              ? const Center(
                            child: Text(
                              "공모전 데이터가 없습니다.",
                              style: TextStyle(color: Colors.white),
                            ),
                          )
                              : PageView.builder(
                            controller: topContestsPageController,
                            scrollDirection: Axis.horizontal,
                            itemCount: topVisitedContests.length,
                            itemBuilder: (context, index) {
                              final contest = topVisitedContests[index];
                              return Column(
                                children: [
                                  Image.asset(
                                    contest['image'],
                                    width: 120,
                                    height: 150,
                                    fit: BoxFit.cover,
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    contest['title'],
                                    style: const TextStyle(
                                      color: Color(0xFF020715),
                                      fontSize: 10,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  Text(
                                    "조회수: ${contest['visit']}회",
                                    style: const TextStyle(
                                      color: Color(0xFF020715),
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                "[상명대학교 SW중심대학사업단 - 공지사항]",
                style: TextStyle(
                  color: Color(0xFF1876FB),
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('homescreen')
                    .orderBy('date', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final docs = snapshot.data!.docs;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '제목: ${data['title'] ?? '제목 없음'}',
                            style: const TextStyle(
                              color: Color(0xFF020715),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '날짜: ${data['date'] ?? '날짜 없음'}',
                            style: const TextStyle(
                              color: Color(0xFF020715),
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '조회수: ${data['view'] ?? '조회수 없음'}',
                            style: const TextStyle(
                              color: Color(0xFF020715),
                              fontSize: 14,
                            ),
                          ),
                          const Divider(color: Colors.grey),
                        ],
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

