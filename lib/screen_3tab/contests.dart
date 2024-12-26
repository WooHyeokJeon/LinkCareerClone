import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:team_project/screen_3tab/contest_info.dart';

class Contests extends StatefulWidget {
  const Contests({Key? key}) : super(key: key);

  @override
  State<Contests> createState() => _ContestsState();
}

class _ContestsState extends State<Contests> {
  String searchQuery = ''; // 검색어 상태
  List<Map<String, dynamic>> contests = []; // 공모전 목록

  @override
  void initState() {
    super.initState();
    fetchContests(); // 초기 Firestore 데이터 가져오기
  }

  /// Firestore에서 공모전 데이터를 가져오는 함수
  Future<void> fetchContests() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('contests').get();
      setState(() {
        contests = snapshot.docs.map((doc) {
          return {
            "id": doc.id, // 문서 ID를 저장
            "title": doc['title'], // 제목
            "image": doc['image'] ?? "asset/img/default.jpg", // Firestore에서 가져온 이미지 경로 사용
            "company_type": doc['company_type'] ?? "정보 없음",
            "participants": doc['participants'] ?? "정보 없음",
            "award_scale": doc['award_scale'] ?? "정보 없음",
            "start_date": doc['start_date'] ?? "날짜 정보 없음",
            "end_date": doc['end_date'] ?? "날짜 정보 없음",
            "website": doc['website'] ?? "홈페이지 정보 없음",
            "benefits": doc['benefits'] ?? "활동 혜택 정보 없음",
            "details": doc['details'] ?? "활동 혜택 정보 없음",
            "visit": doc['visit'] ?? 0, // 방문자 수
          };
        }).toList();
      });
    } catch (e) {
      print('공모전 데이터를 가져오는 중 오류 발생: $e');
    }
  }

  /// 공모전 방문자 수 증가 함수
  Future<void> incrementVisit(String id) async {
    try {
      final docRef = FirebaseFirestore.instance.collection('contests').doc(id);
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (snapshot.exists) {
          final currentVisits = snapshot.data()?['visit'] ?? 0;
          transaction.update(docRef, {'visit': currentVisits + 1});
        } else {
          transaction.set(docRef, {'visit': 1}, SetOptions(merge: true));
        }
      });
    } catch (e) {
      print('방문자 수 증가 중 오류 발생: $e');
    }
  }

  /// 검색어에 따라 필터링된 공모전 목록
  List<Map<String, dynamic>> get filteredContests {
    if (searchQuery.isNotEmpty) {
      return contests.where((contest) {
        return contest["title"]!
            .replaceAll(" ", "")
            .contains(searchQuery.replaceAll(" ", ""));
      }).toList();
    }
    return contests;
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

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
              searchQuery = query; // 검색어 상태 업데이트
            });
          },
        ),
        backgroundColor: const Color(0xFF1876FB),
      ),
      body: contests.isEmpty
          ? const Center(child: CircularProgressIndicator()) // 데이터 로딩 중
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            children: [
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, // 가로에 3개씩 배치
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: filteredContests.length,
                itemBuilder: (context, index) {
                  final contest = filteredContests[index];
                  return GestureDetector(
                    onTap: () async {
                      // 방문자 수 증가
                      await incrementVisit(contest["id"]!);

                      // ContestInfo 페이지로 이동
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ContestInfo(
                            contestId: contest["id"]!,
                            title: contest["title"]!,
                            image: contest["image"]!,
                            company_type: contest["company_type"]!,
                            participants: contest["participants"]!,
                            award_scale: contest["award_scale"]!,
                            start_date: contest["start_date"]!,
                            end_date: contest["end_date"]!,
                            website: contest["website"]!,
                            benefits: contest["benefits"]!,
                            details: contest["details"]!,
                          ),
                        ),
                      );

                      // 공모전 누를 때마다 조회 수 업데이트
                      fetchContests();
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Center(
                            child: Image.asset(
                              contest["image"]!,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 5),
                          child: Text(
                            contest["title"]!,
                            style: const TextStyle(
                                color: Color(0xFF000000), fontSize: 12),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            "조회: ${contest["visit"]}회", // 방문자 수 표시
                            style: const TextStyle(
                                color: Colors.black, fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
