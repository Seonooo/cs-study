# CS 스터디 커리큘럼 (12주)

> 네트워크 → 운영체제 → 데이터베이스
> 기초 개념부터 면접·실무 딥다이브까지

자료구조/알고리즘은 별도 코딩 테스트 학습으로 대체합니다.

---

## 운영 방식

- **매주 1주제**, 각자 조사하고 마크다운으로 정리해서 공유
- 매주 발표자 1명을 로테이션으로 정함. 나머지는 질문/보완 자료 가져오기
- 정리본은 GitHub repo에 PR 형태로 업로드 (서로 리뷰)
- Discord 채널 구조 예시:
  - `#📢-주간-공지` (webhook 알림 채널)
  - `#📚-자료-공유`
  - `#💬-토론`
  - `#🙋-질문`

### 주간 사이클

| 요일 | 활동 |
|------|------|
| 토 | Discord webhook 자동 공지 (이번 주 주제, 키워드, 발표자) |
| 토~수 | 각자 학습 및 정리 |
| 목 | 정리본 PR 업로드 (23:59 마감), 서로 리뷰/코멘트 |
| 금 | 1시간 화상 토론 (21:00), 다음 주 발표자 확정 |

---

## Phase 1. 네트워크 (Week 1–4)

### Week 1. 네트워크 계층 모델
- **핵심 개념**: OSI 7계층, TCP/IP 4계층, 각 계층의 PDU와 책임
- **딥다이브**: 패킷이 브라우저에서 서버까지 가는 동안 각 계층에서 일어나는 일을 차근차근 추적
- **토론**: OSI 모델은 실무에서 정말 의미가 있는가? TCP/IP 모델로 충분하지 않나?
- **자료**: "컴퓨터 네트워킹 하향식 접근" Ch.1

### Week 2. TCP, UDP
- **핵심 개념**: 3-way handshake, 4-way handshake, 흐름 제어, 혼잡 제어, TCP 상태 다이어그램
- **딥다이브**: TIME_WAIT가 왜 필요한가? Nagle 알고리즘, TCP fast open, QUIC가 UDP 위에 만들어진 이유
- **토론**: 실시간성이 중요한 게임/영상에서 TCP vs UDP 선택 기준
- **자료**: "TCP/IP Illustrated Vol.1", `tcpdump`/`wireshark` 실습

### Week 3. HTTP / HTTPS
- **핵심 개념**: HTTP 메서드, 상태 코드, 헤더, 캐싱, REST 원칙 / TLS 핸드셰이크, 인증서, HTTP/1.1 vs 2 vs 3
- **딥다이브**: HTTP/2 멀티플렉싱과 HoL blocking, HTTP/3 (QUIC), TLS 1.3에서 줄어든 RTT, CORS와 preflight
- **토론**: REST와 GraphQL, gRPC의 트레이드오프
- **자료**: MDN Web Docs HTTP 섹션, "HTTP 완벽 가이드"

### Week 4. DNS, 로드밸런싱, CDN
- **핵심 개념**: DNS 계층 구조, 레코드 타입, recursive vs iterative 쿼리, L4 vs L7 로드밸런싱, CDN 캐싱 전략
- **딥다이브**: DNS 캐싱과 TTL, CDN의 origin shield, sticky session vs stateless, anycast 라우팅
- **토론**: 글로벌 서비스라면 어떤 순서로 인프라를 배치해야 하는가?
- **자료**: "Site Reliability Engineering" 관련 챕터, 클라우드 공급사(AWS/GCP) 아키텍처 레퍼런스

---

## Phase 2. 운영체제 (Week 5–8)

### Week 5. 프로세스와 스레드
- **핵심 개념**: 프로세스 vs 스레드, PCB, 컨텍스트 스위칭, 스케줄링 알고리즘 (FCFS, SJF, RR, MLFQ)
- **딥다이브**: 컨텍스트 스위칭 비용, 리눅스 CFS 스케줄러, 그린 스레드/코루틴 (Go goroutine, Kotlin coroutine)
- **토론**: 멀티프로세스 vs 멀티스레드 vs 비동기 I/O — 언제 무엇을 쓸 것인가?
- **자료**: OSTEP Ch.4-9 (무료 PDF), "운영체제와 정보기술의 원리" (반효경)

### Week 6. 동기화와 데드락
- **핵심 개념**: 임계 구역, 뮤텍스/세마포어/모니터, 데드락 4가지 조건, 기아/라이브락
- **딥다이브**: Java `synchronized` vs `ReentrantLock`, CAS 기반 lock-free 자료구조, 식사하는 철학자 문제
- **토론**: 락 없이 동시성을 다루는 방법들 (immutable, actor model, MVCC)
- **자료**: OSTEP Ch.26-32, "Java Concurrency in Practice"

### Week 7. 메모리 관리
- **핵심 개념**: 가상 메모리, 페이징, 세그멘테이션, TLB, 페이지 교체 알고리즘 (LRU/Clock), 메모리 계층 구조
- **딥다이브**: 페이지 폴트가 일어났을 때 OS가 하는 일, 캐시 친화적 코드 작성법, mmap의 동작 원리
- **토론**: GC 언어와 수동 메모리 관리 언어의 트레이드오프
- **자료**: OSTEP Ch.13-23

### Week 8. 파일 시스템과 I/O
- **핵심 개념**: inode, 디렉토리 구조, 저널링, 블록/스트림 I/O, 동기/비동기 I/O, blocking/non-blocking
- **딥다이브**: select/poll/epoll/kqueue, io_uring, Node.js 이벤트 루프, 리눅스 파일 디스크립터
- **토론**: 백엔드 서버에서 I/O 모델 선택이 처리량에 미치는 영향
- **자료**: OSTEP Ch.36-43, "The C10K problem"

---

## Phase 3. 데이터베이스 (Week 9–12)

### Week 9. 관계형 모델과 정규화
- **핵심 개념**: 릴레이션, 키 종류, 함수 종속성, 1NF~BCNF, 반정규화
- **딥다이브**: 정규화의 비용 (조인 성능), OLTP vs OLAP에서의 정규화 정책, ER 모델링
- **토론**: 실무에서 3NF까지만 가는 이유, 언제 반정규화를 할 것인가?
- **자료**: "데이터베이스 시스템" (Silberschatz) Ch.7-8

### Week 10. 인덱스와 쿼리 최적화
- **핵심 개념**: B-Tree, B+Tree, 해시 인덱스, 클러스터드 vs 논클러스터드, 커버링 인덱스, 실행 계획
- **딥다이브**: MySQL InnoDB의 클러스터드 인덱스 구조, EXPLAIN 읽는 법, 인덱스가 안 타는 케이스, 복합 인덱스 컬럼 순서
- **토론**: 인덱스를 추가했는데 오히려 느려진 사례
- **자료**: "Real MySQL 8.0", PostgreSQL 공식 문서 인덱스 섹션

### Week 11. 트랜잭션과 격리 수준
- **핵심 개념**: ACID, 트랜잭션 상태, 격리 수준 4단계, 동시성 이상 현상 (dirty/non-repeatable/phantom)
- **딥다이브**: MVCC 동작 원리, 락 기반 vs MVCC, MySQL Repeatable Read에서 phantom이 안 보이는 이유, Serializable Snapshot Isolation
- **토론**: 실무에서 격리 수준을 어떻게 선택하는가? Read Committed가 사실상 표준이 된 이유
- **자료**: "Designing Data-Intensive Applications" Ch.7

### Week 12. NoSQL, 분산 데이터베이스
- **핵심 개념**: CAP / PACELC, NoSQL 종류 (KV, document, column-family, graph), 샤딩, 복제 (단일 리더/다중 리더/리더리스)
- **딥다이브**: Eventual consistency, quorum, vector clock, Raft/Paxos 개요, 분산 트랜잭션과 saga 패턴
- **토론**: 마이크로서비스에서 데이터 일관성을 어떻게 보장할 것인가?
- **자료**: "Designing Data-Intensive Applications" Ch.5-9

---

## 정리 노트 템플릿

각자 정리할 때 이런 구조를 쓰면 비교/리뷰가 편합니다.

```markdown
# Week N. [주제]

## 핵심 개념
- 한 문장 요약
- 주요 용어 정리

## 동작 원리 / 구조
(다이어그램 또는 의사코드)

## 트레이드오프
- 장점:
- 단점:
- 대안:

## 실무/면접 포인트
- 자주 묻는 질문 3개와 모범 답안

## 내가 새로 알게 된 것
(자기 언어로)

## 참고 자료
- [링크 또는 책 페이지]
```

---

## 추천 도서 / 자료

**필수**
- "OSTEP" (Operating Systems: Three Easy Pieces) — 무료 PDF, OS 표준 교재
- "컴퓨터 네트워킹 하향식 접근" (Kurose) — 네트워크 표준 교재
- "Designing Data-Intensive Applications" (Kleppmann) — DB/분산 시스템

**참고**
- "Real MySQL 8.0"
- "Java Concurrency in Practice"
- "TCP/IP Illustrated Vol.1"
- gyoogle/tech-interview-for-developer (GitHub)
- JaeYeopHan/Interview_Question_for_Beginner (GitHub)

**실습**
- Wireshark, tcpdump (네트워크 주차)
- `strace`, `htop`, `iostat`, `perf` (OS 주차)
- 로컬 MySQL/PostgreSQL + EXPLAIN 실습 (DB 주차)

---

## 진도 조절 팁

- **너무 빠르면**: 각 주제를 2주로 늘려 첫 주는 개념, 둘째 주는 실습/직접 검증으로 분리 → 24주 버전
- **딥다이브 강화**: 각 Phase 끝에 "통합 회고/미니 프로젝트 주차"를 1주씩 추가 (예: 간단한 TCP 서버 구현, 직접 만든 인덱스 자료구조 벤치마크)
- **추가 주제**: 보안 기초(인증/인가, OWASP Top 10), 컴퓨터 구조(CPU 파이프라인, 캐시), 메시지 큐/스트리밍 등을 끝에 붙이는 것도 추천
