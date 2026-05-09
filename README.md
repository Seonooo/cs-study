# CS 스터디

네트워크 → 운영체제 → 데이터베이스 순서로 진행하는 12주 백엔드 CS 스터디.

각 주차마다 **이번 주 목표 / 학습 체크리스트 / 꼬리 질문 5개(접이식 힌트)** 가 준비되어 있습니다.

---

## 커리큘럼 인덱스

### 📡 [Phase 1. 네트워크 (Week 1–4)](network/README.md)

- [Week 1. OSI/TCP-IP 계층 모델](network/week01-osi-tcpip/README.md)
- [Week 2. TCP, UDP](network/week02-tcp-udp/README.md)
- [Week 3. HTTP / HTTPS](network/week03-http-https/README.md)
- [Week 4. DNS, 로드밸런싱, CDN](network/week04-dns-lb-cdn/README.md)

### 🖥 [Phase 2. 운영체제 (Week 5–8)](os/README.md)

- [Week 5. 프로세스와 스레드](os/week05-process-thread/README.md)
- [Week 6. 동기화와 데드락](os/week06-sync-deadlock/README.md)
- [Week 7. 메모리 관리](os/week07-memory/README.md)
- [Week 8. 파일 시스템과 I/O](os/week08-filesystem-io/README.md)

### 🗄 [Phase 3. 데이터베이스 (Week 9–12)](database/README.md)

- [Week 9. 관계형 모델과 정규화](database/week09-relational-normalization/README.md)
- [Week 10. 인덱스와 쿼리 최적화](database/week10-index-query/README.md)
- [Week 11. 트랜잭션과 격리 수준](database/week11-transaction-isolation/README.md)
- [Week 12. NoSQL, 분산 데이터베이스](database/week12-nosql-distributed/README.md)

> 전체 커리큘럼 상세 — [cs-study-curriculum.md](cs-study-curriculum.md)

---

## 진도 트래킹

진도가 끝난 주차의 체크박스를 채워주세요.

- [ ] Week 1 — OSI/TCP-IP 계층 모델
- [ ] Week 2 — TCP, UDP
- [ ] Week 3 — HTTP / HTTPS
- [ ] Week 4 — DNS, 로드밸런싱, CDN
- [ ] Week 5 — 프로세스와 스레드
- [ ] Week 6 — 동기화와 데드락
- [ ] Week 7 — 메모리 관리
- [ ] Week 8 — 파일 시스템과 I/O
- [ ] Week 9 — 관계형 모델과 정규화
- [ ] Week 10 — 인덱스와 쿼리 최적화
- [ ] Week 11 — 트랜잭션과 격리 수준
- [ ] Week 12 — NoSQL, 분산 데이터베이스

---

## 멤버별 정리 노트

[`members/`](members/README.md) — 각 멤버가 주차별 정리본을 작성하는 공간.

- 빈 템플릿: [`members/template.md`](members/template.md)
- 채워진 예시: [`members/example.md`](members/example.md)
- 멤버 폴더: [seonho](members/seonho/), [wooseung](members/wooseung/), [wodud](members/wodud/)

---

## 운영 방식

### 역할

- **발표자**: 해당 주차 주제를 조사·정리하여 발표 (매주 1명, 로테이션)
- **나머지 멤버**: 질문 준비 및 보완 자료 가져오기

### 주간 사이클

| 요일 | 활동 |
|:----:|------|
| 토 | Discord webhook 자동 공지 (이번 주 주제·키워드·발표자) |
| 토–수 | 각자 학습 및 정리 |
| 목 | 정리본 PR 업로드 (23:59 마감) → 서로 리뷰 / 코멘트 |
| 금 | 1시간 화상 토론 (21:00) + 다음 주 발표자 확정 |

### PR 가이드

1. 본인 멤버 폴더에 [`members/template.md`](members/template.md) 복사 → `week{NN}-{주제}.md` 로 이름 변경 후 채우기
2. PR 제목: `[Week N] 주제명 - memberN`
3. 리뷰어: 나머지 멤버 전원 지정
4. 금요일 토론 전 머지

---

## Discord 채널 구조

| 채널 | 용도 |
|------|------|
| `#📢-주간-공지` | webhook 알림 (매주 토요일 자동 발송) |
| `#📚-자료-공유` | 참고 자료·링크 공유 |
| `#💬-토론` | 주간 토론 주제 논의 |
| `#🙋-질문` | 학습 중 생긴 질문 |

---

## 추천 도서 / 자료

**필수**

- *OSTEP* (Operating Systems: Three Easy Pieces) — 무료 PDF
- *컴퓨터 네트워킹 하향식 접근* (Kurose)
- *Designing Data-Intensive Applications* (Kleppmann)

**참고**

- *Real MySQL 8.0*
- *Java Concurrency in Practice*
- *TCP/IP Illustrated Vol.1*
- [gyoogle/tech-interview-for-developer](https://github.com/gyoogle/tech-interview-for-developer)
- [JaeYeopHan/Interview_Question_for_Beginner](https://github.com/JaeYeopHan/Interview_Question_for_Beginner)

**실습 도구**

- Wireshark / tcpdump (네트워크 주차)
- `strace`, `htop`, `iostat`, `perf`, `vmstat` (OS 주차)
- 로컬 MySQL / PostgreSQL + EXPLAIN (DB 주차)
