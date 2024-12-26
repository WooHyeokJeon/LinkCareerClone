import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_database/firebase_database.dart';

class ContestInfo extends StatefulWidget {
  final String contestId;
  final String title;
  final String image;
  final String company_type;
  final String participants;
  final String award_scale;
  final String start_date;
  final String end_date;
  final String website;
  final String benefits;
  final String details;

  const ContestInfo({
    Key? key,
    required this.contestId,
    required this.title,
    required this.image,
    required this.company_type,
    required this.participants,
    required this.award_scale,
    required this.start_date,
    required this.end_date,
    required this.website,
    required this.benefits,
    required this.details,
  }) : super(key: key);

  @override
  State<ContestInfo> createState() => _ContestInfoState();
}

class _ContestInfoState extends State<ContestInfo> {
  final DatabaseReference _chatRef = FirebaseDatabase.instance.ref('chatRooms');
  final TextEditingController _messageController = TextEditingController();
  late DatabaseReference _contestChatRef;
  List<Map<String, String>> _messages = [];

  @override
  void initState() {
    super.initState();
    _contestChatRef = _chatRef.child(widget.contestId);
    _loadMessages();
  }

  void _loadMessages() {
    _contestChatRef.onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>? ?? {};
      print('로드된 메시지 데이터: $data'); // 데이터 로드 확인

      final List<Map<String, String>> messages = data.entries.map((entry) {
        final value = Map<String, String>.from(entry.value as Map);
        return {
          'user': value['user'] ?? '익명',
          'message': value['message'] ?? '',
        };
      }).toList();

      setState(() {
        _messages = messages;
        print('UI에 반영된 메시지: $_messages'); // UI 상태 확인
      });
    });
  }

  void _sendMessage(String message) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? 'unknown';
    final userName = FirebaseAuth.instance.currentUser?.displayName ?? '익명';

    final messageData = {
      'message': message,
      'user': userName,
      'userId': userId,
    };

    _contestChatRef.push().set(messageData); // contestId 경로에 저장
    print('메시지 저장: $messageData');
  }

  void _clearChatHistory() async {
    try {
      await _contestChatRef.remove(); // 해당 채팅방의 모든 메시지 삭제
      setState(() {
        _messages = []; // UI 갱신
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('채팅방 내역이 삭제되었습니다.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('채팅방 내역 삭제 실패: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    return Scaffold(
      appBar: AppBar(
        title: Text("공모전 들여다보기"),
        backgroundColor: Color(0xFF1876FB),
        actions: [
          IconButton(
            icon: Icon(Icons.delete, color: Colors.white),
            onPressed: _clearChatHistory,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                style: TextStyle(
                  color: Color(0xFF020715),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(right: 20.0),
                    child: Image.asset(
                      widget.image,
                      width: MediaQuery.of(context).size.width * 0.4,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '기업형태: ${widget.company_type}\n'
                          '참여대상: ${widget.participants}\n'
                          '시상규모: ${widget.award_scale}\n'
                          '시작일: ${widget.start_date}\n'
                          '마감일: ${widget.end_date}\n'
                          '홈페이지: ${widget.website}\n'
                          '활동혜택: ${widget.benefits}\n',
                      style: TextStyle(
                        color: Color(0xFF020715),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Divider(color: Colors.grey),
              Text(
                '채팅방',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1876FB),
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(
                            color: Colors.grey,
                            width: 1.0,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.all(8.0),
                        margin: const EdgeInsets.only(top:4.0),
                        child: _messages.isEmpty
                            ? Center(
                          child: Text(
                            '아직 메시지가 없습니다.',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        )
                            : ListView.builder(
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final message = _messages[index];
                            print('렌더링 중인 메시지: $message');
                            return ListTile(
                              title: Text(
                                message['user'] ?? '익명',
                                style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(
                                    color: Colors.grey, // 테두리 색상
                                    width: 1.0, // 테두리 두께
                                  ),
                                  borderRadius: BorderRadius.circular(5), // 둥근 테두리
                                ),
                                padding: const EdgeInsets.all(8.0), // 내부 여백
                                margin: const EdgeInsets.only(top: 4.0), // 외부 여백
                                child: Text(
                                  message['message'] ?? '',
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              decoration: InputDecoration(
                                hintText: '메시지를 입력하세요',
                                hintStyle: const TextStyle(color: Colors.black),
                                filled: true,
                                fillColor: Color(0xFFF8F8FF),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                   // 기본 테두리 제거
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(
                                    color: Colors.grey, // 비활성화 상태 테두리 색상
                                    width: 1.0,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF1876FB), // 포커스 상태 테두리 색상
                                    width: 2.0,
                                  ),
                                ),
                              ),
                              style: const TextStyle(color: Colors.black),
                            ),
                          ),

                          IconButton(
                            icon: Icon(Icons.send, color: Color(0xFF1876FB)),
                            onPressed: () {
                              final message = _messageController.text.trim();
                              if (message.isNotEmpty) {
                                _sendMessage(message);
                                _messageController.clear();
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              Text(
                '상세내용',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF020715),
                ),
              ),
              SizedBox(height: 5),
              Text(
                widget.details.isNotEmpty ? widget.details : '상세내용 없음',
                style: TextStyle(color: Color(0xFF020715)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
