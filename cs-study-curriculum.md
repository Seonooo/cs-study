# CS 스터디 커리큘럼 (20주)

> 네트워크 → 운영체제 → 데이터베이스 → 프레임워크 → 운영
> 2026 백엔드 면접 우선순위 기반, 한 주에 한 토픽씩 콕 집어 학습

자료구조/알고리즘은 별도 코딩 테스트 학습으로 대체합니다.

> **재구성 근거**: `cs-obsidian/wiki/topics/curriculum-redesign-2026.md` 참고. 기존 12주의 큰 묶음(예: process-thread + 가상스레드 + 스케줄러)을 분리하고, framework 슬롯(Spring/JPA) 4주와 운영 1주를 신설.

---

## 운영 방식

- **매주 1주제**, 각자 조사하고 마크다운으로 정리해서 공유
- 매주 발표자 1명을 로테이션으로 정함. 나머지는 질문/보완 자료 가져오기
- 정리본은 GitHub repo에 PR 형태로 업로드 (서로 리뷰)
- 각 주차는 **독립적**으로 학습 가능 — 결석한 인원도 다음 주 복귀가 쉽도록 의존성 최소화
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

### 시간 비동기 인원 대응 원칙
- 발표자가 빠질 가능성을 고려해 **2명 짝 발표** 또는 **녹화 공유** 백업
- 매 주차 끝에 **면접 단골 Q&A 3개**를 답안 형태로 PR에 포함 → 결석자가 따라잡을 때의 최소 학습 산출물
- 각 주차는 한 토픽만 콕 집어 1주에 무리 없이 소화

---

## Phase 1. 네트워크 (Week 1–5)

### Week 1. OSI/TCP-IP 계층 모델
- **핵심 개념**: OSI 7계층, TCP/IP 4계층, 각 계층의 PDU와 책임
- **딥다이브**: 패킷이 브라우저에서 서버까지 가는 동안 각 계층에서 일어나는 일을 차근차근 추적
- **토론**: OSI 모델은 실무에서 정말 의미가 있는가? TCP/IP 모델로 충분하지 않나?
- **면접 Q3**: L4/L7 LB 차이 · "URL 입력 시 일어나는 일" · HTTP/3가 UDP 위인 이유
- **자료**: "컴퓨터 네트워킹 하향식 접근" Ch.1

### Week 2. TCP, UDP
- **핵심 개념**: 3-way handshake, 4-way handshake, 흐름 제어, 혼잡 제어, TCP 상태 다이어그램
- **딥다이브**: TIME_WAIT가 왜 필요한가? Nagle 알고리즘, TCP fast open, QUIC가 UDP 위에 만들어진 이유
- **토론**: 실시간성이 중요한 게임/영상에서 TCP vs UDP 선택 기준
- **면접 Q3**: TCP vs UDP 차이 · 3-way handshake 횟수 이유 · Connection Pool 역할
- **자료**: "TCP/IP Illustrated Vol.1", `tcpdump`/`wireshark` 실습

### Week 3. HTTP / HTTPS
- **핵심 개념**: HTTP 메서드, 상태 코드, 헤더, 캐싱, REST 원칙 / TLS 핸드셰이크, 인증서, HTTP/1.1 vs 2 vs 3
- **딥다이브**: HTTP/2 멀티플렉싱과 HoL blocking, HTTP/3 (QUIC), TLS 1.3에서 줄어든 RTT, CORS와 preflight
- **토론**: REST와 GraphQL, gRPC의 트레이드오프
- **면접 Q3**: HTTP vs HTTPS · GET vs POST (안전성·멱등성) · CORS preflight 발생 조건
- **자료**: MDN Web Docs HTTP 섹션, "HTTP 완벽 가이드"

### Week 4. DNS, 로드밸런싱, CDN
- **핵심 개념**: DNS 계층 구조, 레코드 타입, recursive vs iterative 쿼리, L4 vs L7 로드밸런싱, CDN 캐싱 전략
- **딥다이브**: DNS 캐싱과 TTL, CDN의 origin shield, sticky session vs stateless, anycast 라우팅
- **토론**: 글로벌 서비스라면 어떤 순서로 인프라를 배치해야 하는가?
- **면접 Q3**: DNS 조회 흐름 · sticky vs stateless · CDN 캐시 무효화 전략
- **자료**: "Site Reliability Engineering" 관련 챕터, 클라우드 공급사(AWS/GCP) 아키텍처 레퍼런스

### Week 5. 웹 인증 — 세션·쿠키·JWT·OAuth2 ⭐신설
- **핵심 개념**: Session vs Cookie, JWT 구조 (header.payload.signature), OAuth2 4가지 grant, CSRF/XSS, SSO/OIDC
- **딥다이브**: JWT 탈취/만료/블랙리스트 처리, OAuth2 Authorization Code Flow with PKCE, Refresh Token 회전
- **토론**: 세션 vs JWT — 마이크로서비스에서 어느 쪽을 택할 것인가?
- **면접 Q3**: 세션과 쿠키의 차이 · JWT 구조와 위험 · CSRF/XSS 방어 패턴
- **자료**: RFC 6749 (OAuth 2.0), Auth0 가이드, "HTTP 완벽 가이드" 보안 챕터

---

## Phase 2. 운영체제 (Week 6–10)

### Week 6. 프로세스와 스레드, 스케줄링
- **핵심 개념**: 프로세스 vs 스레드, PCB/TCB, 컨텍스트 스위칭, 스케줄링 알고리즘 (FCFS, SJF, RR, MLFQ), IPC
- **딥다이브**: 컨텍스트 스위칭 비용 구성, 리눅스 CFS 스케줄러, IPC 방식별(파이프·소켓·공유메모리·시그널) 트레이드오프
- **토론**: 멀티프로세스 vs 멀티스레드 — 언제 무엇을 쓸 것인가?
- **면접 Q3**: 프로세스 vs 스레드 자원 공유 · 컨텍스트 스위칭 비용 · IPC 선택 기준
- **자료**: OSTEP Ch.4-10, "운영체제와 정보기술의 원리" (반효경)

### Week 7. 가상 스레드·코루틴·동시성 모델 ⭐신설
- **핵심 개념**: Java Virtual Thread (Project Loom), Goroutine M:N, Kotlin Coroutine, Reactive / async I/O
- **딥다이브**: Thread-per-request의 메모리·컨텍스트 스위칭 한계, Virtual Thread의 carrier thread 모델, Goroutine 스케줄러
- **토론**: Virtual Thread가 Reactive를 대체할 수 있는가?
- **면접 Q3**: Virtual Thread vs Coroutine vs 일반 스레드 · M:N 스케줄링 · Thread-per-request의 한계
- **자료**: JEP 444 (Virtual Threads), "Java Concurrency in Practice", Go 공식 블로그

### Week 8. 동기화와 데드락
- **핵심 개념**: 임계 구역, 뮤텍스/세마포어/모니터, 데드락 4가지 조건, 기아/라이브락
- **딥다이브**: Java `synchronized` vs `ReentrantLock`, CAS 기반 lock-free 자료구조, 식사하는 철학자 문제
- **토론**: 락 없이 동시성을 다루는 방법들 (immutable, actor model, MVCC)
- **면접 Q3**: 데드락 4 조건 · Mutex vs Semaphore · synchronized vs ReentrantLock
- **자료**: OSTEP Ch.26-32, "Java Concurrency in Practice"

### Week 9. 메모리 관리와 GC
- **핵심 개념**: 가상 메모리, 페이징, 세그멘테이션, TLB, 페이지 교체 알고리즘 (LRU/Clock), JVM 메모리 영역, GC 알고리즘
- **딥다이브**: 페이지 폴트 처리 과정, 캐시 친화적 코드 작성법, mmap, Serial→Parallel→CMS→G1→ZGC 진화와 STW 단축
- **토론**: GC 언어와 수동 메모리 관리 언어의 트레이드오프
- **면접 Q3**: 가상 메모리 목적 · 페이지 폴트 vs TLB miss · ZGC가 STW를 어떻게 줄였나
- **자료**: OSTEP Ch.13-23, Oracle JVM 문서, "Java Performance" (Scott Oaks)

### Week 10. 파일 시스템과 I/O 모델
- **핵심 개념**: inode, 디렉토리 구조, 저널링, 블록/스트림 I/O, 동기/비동기 I/O, blocking/non-blocking
- **딥다이브**: select/poll/epoll/kqueue, io_uring, Node.js 이벤트 루프, 리눅스 파일 디스크립터
- **토론**: 백엔드 서버에서 I/O 모델 선택이 처리량에 미치는 영향
- **면접 Q3**: sync/async vs blocking/non-blocking 4사분면 · epoll이 select보다 빠른 이유 · io_uring 등장 배경
- **자료**: OSTEP Ch.36-43, "The C10K problem"

---

## Phase 3. 데이터베이스 (Week 11–15)

### Week 11. 관계형 모델과 정규화
- **핵심 개념**: 릴레이션, 키 종류, 함수 종속성, 1NF~BCNF, 반정규화
- **딥다이브**: 정규화의 비용 (조인 성능), OLTP vs OLAP에서의 정규화 정책, ER 모델링, 분산 환경의 UUID v7/Snowflake
- **토론**: 실무에서 3NF까지만 가는 이유, 언제 반정규화를 할 것인가?
- **면접 Q3**: 정규화 단계와 이상 현상 · 반정규화 시점 · 분산 PK 전략
- **자료**: "데이터베이스 시스템" (Silberschatz) Ch.7-8

### Week 12. 인덱스와 B+Tree
- **핵심 개념**: B-Tree, B+Tree, 해시 인덱스, 클러스터드 vs 논클러스터드, 커버링 인덱스, 복합 인덱스
- **딥다이브**: MySQL InnoDB의 클러스터드 인덱스 구조, B+Tree와 해시 인덱스 차이, 복합 인덱스 컬럼 순서, 인덱스 추가 시 쓰기 비용
- **토론**: 인덱스를 추가했는데 오히려 느려진 사례
- **면접 Q3**: DB가 B+Tree를 쓰는 이유 · 클러스터드 vs 논클러스터드 · 복합 인덱스 컬럼 순서 결정
- **자료**: "Real MySQL 8.0", PostgreSQL 공식 문서 인덱스 섹션

### Week 13. 쿼리 최적화와 EXPLAIN ⭐신설
- **핵심 개념**: EXPLAIN / EXPLAIN ANALYZE, 옵티마이저 통계, 인덱스 미사용 케이스, Slow query, 조인 알고리즘 (NL/Hash/Merge)
- **딥다이브**: 옵티마이저가 풀스캔을 선택하는 이유, function index와 인덱스 무력화, Slow query log로 병목 진단, 쿼리 리라이팅
- **토론**: ORM이 만들어내는 쿼리를 어디까지 신뢰할 것인가?
- **면접 Q3**: EXPLAIN 결과 읽는 법 · 인덱스가 안 타는 케이스 · 조인 알고리즘별 적합 상황
- **자료**: "Real MySQL 8.0" 옵티마이저 챕터, Use The Index, Luke (uti.io)

### Week 14. 트랜잭션과 격리 수준
- **핵심 개념**: ACID, 트랜잭션 상태, 격리 수준 4단계, 동시성 이상 현상 (dirty/non-repeatable/phantom)
- **딥다이브**: MVCC 동작 원리, 락 기반 vs MVCC, MySQL Repeatable Read에서 phantom이 안 보이는 이유, Serializable Snapshot Isolation
- **토론**: 실무에서 격리 수준을 어떻게 선택하는가? Read Committed가 사실상 표준이 된 이유
- **면접 Q3**: ACID 각 속성 · 격리 수준과 이상 현상 매핑 · MVCC 동작 원리
- **자료**: "Designing Data-Intensive Applications" Ch.7

### Week 15. NoSQL, 분산 데이터베이스
- **핵심 개념**: CAP / PACELC, NoSQL 종류 (KV, document, column-family, graph), 샤딩, 복제 (단일 리더/다중 리더/리더리스)
- **딥다이브**: Eventual consistency, quorum, vector clock, Raft/Paxos 개요, 분산 트랜잭션과 saga 패턴, Outbox 패턴
- **토론**: 마이크로서비스에서 데이터 일관성을 어떻게 보장할 것인가?
- **면접 Q3**: CAP/PACELC 차이 · 리더리스 복제 트레이드오프 · Saga 패턴
- **자료**: "Designing Data-Intensive Applications" Ch.5-9

---

## Phase 4. 프레임워크 (Week 16–19) ⭐신설

### Week 16. Spring IoC·DI·Bean
- **핵심 개념**: IoC Container (BeanFactory, ApplicationContext), DI 3방식 (Constructor/Setter/Field), Bean 생명주기, Bean Scope, 순환 의존성
- **딥다이브**: 왜 생성자 주입이 권장되는지 (불변성·테스트·순환 의존성 조기 탐지), `@PostConstruct` / `@PreDestroy`, Singleton vs Prototype의 실제 차이
- **토론**: Spring의 IoC 컨테이너 없이 우리 손으로 만들 때 무엇이 어려운가?
- **면접 Q3**: IoC와 DI 차이 · 생성자 주입 권장 이유 · 순환 의존성 해결법
- **자료**: Spring 공식 docs (Core: Beans), "토비의 스프링 3.1" Vol.1

### Week 17. Spring MVC·AOP·Filter/Interceptor
- **핵심 개념**: DispatcherServlet (Front Controller 패턴), HandlerMapping/ViewResolver, AOP 5요소, Proxy (JDK vs CGLIB), Filter vs Interceptor vs AOP
- **딥다이브**: 요청이 DispatcherServlet에 도착한 뒤 응답이 나가기까지 전체 흐름, JDK Dynamic Proxy vs CGLIB 선택 기준, AOP가 `this.method()` 자기 호출에 안 먹는 이유
- **토론**: 횡단 관심사를 Filter / Interceptor / AOP 어디에 둘 것인가?
- **면접 Q3**: DispatcherServlet 처리 흐름 · AOP 핵심 용어 · Filter vs Interceptor 차이
- **자료**: Spring 공식 docs (Web MVC, AOP), "토비의 스프링 3.1" Vol.2

### Week 18. JPA — 영속성 컨텍스트와 N+1
- **핵심 개념**: 영속성 컨텍스트 5가지 이점 (1차 캐시, 동일성 보장, 쓰기 지연, 변경 감지, 지연 로딩), 엔티티 생명주기, 더티 체킹, N+1 문제
- **딥다이브**: N+1 발생 시점 (즉시·지연 로딩 양쪽), Fetch Join의 한계 (페이징·distinct), `@EntityGraph`·batch size 활용, LazyInitializationException
- **토론**: JPA를 쓰면서 SQL을 모르면 위험한가?
- **면접 Q3**: 영속성 컨텍스트 이점 · N+1 해결책 · 더티 체킹 동작 원리
- **자료**: "자바 ORM 표준 JPA 프로그래밍" (김영한), Hibernate User Guide

### Week 19. Spring Boot — Auto-config·@Transactional·Actuator
- **핵심 개념**: `@SpringBootApplication` 내부 (@Configuration + @EnableAutoConfiguration + @ComponentScan), Auto-configuration, `@Transactional` 프록시 함정, 전파 속성, Actuator
- **딥다이브**: Auto-config가 빈을 만들지 않는 이유 디버깅 (`--debug`, AutoConfigurationReport), `@Transactional`이 안 먹는 케이스 (self-invocation, private, checked exception), 트랜잭션 전파 시나리오, Actuator로 운영 가시성
- **토론**: Spring Boot가 가린 마법을 어디까지 이해해야 하는가?
- **면접 Q3**: `@SpringBootApplication` 분해 · `@Transactional` 실패 케이스 · Actuator 활용
- **자료**: Spring Boot 공식 docs, Baeldung Transactional series

---

## Phase 5. 운영·시스템디자인 (Week 20) ⭐신설

### Week 20. CI/CD·Docker·옵저버빌리티·시스템디자인 베이직
- **핵심 개념**: CI/CD 파이프라인, Docker 이미지/컨테이너, Logs/Metrics/Traces (옵저버빌리티 3 시그널), 캐싱·메시지 큐·수평 확장
- **딥다이브**: 커밋부터 프로덕션까지 흐름, Docker가 VM과 다른 이유와 이미지 레이어, OpenTelemetry·correlation ID·distributed tracing, 10배 트래픽을 흡수하는 패턴 (캐시·MQ·읽기 복제본)
- **토론**: 신입~주니어가 운영 경험 없이 옵저버빌리티 질문에 어떻게 답할 것인가?
- **면접 Q3**: CI/CD 흐름 · Docker vs VM · 10배 트래픽 설계
- **자료**: "Designing Data-Intensive Applications" Ch.1-2, "SRE Book" 일부, Docker docs

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
- "토비의 스프링 3.1" (이일민) — Spring IoC/AOP 표준
- "자바 ORM 표준 JPA 프로그래밍" (김영한) — JPA 표준

**참고**
- "Real MySQL 8.0"
- "Java Concurrency in Practice"
- "TCP/IP Illustrated Vol.1"
- "Java Performance" (Scott Oaks)
- gyoogle/tech-interview-for-developer (GitHub)
- JaeYeopHan/Interview_Question_for_Beginner (GitHub)
- ksundong/backend-interview-question (GitHub)

**실습**
- Wireshark, tcpdump (네트워크 주차)
- `strace`, `htop`, `iostat`, `perf` (OS 주차)
- 로컬 MySQL/PostgreSQL + EXPLAIN 실습 (DB 주차)
- Spring Boot + H2 + Hibernate SQL 로깅 (프레임워크 주차)
- Docker, GitHub Actions (운영 주차)

---

## 진도 조절 팁

- **너무 빠르면**: 각 주제를 2주로 늘려 첫 주는 개념, 둘째 주는 실습/직접 검증으로 분리
- **딥다이브 강화**: 각 Phase 끝에 "통합 회고/미니 프로젝트 주차"를 추가 (예: 직접 만든 TCP 서버, 인덱스 자료구조 벤치마크, Spring AOP 직접 구현)
- **추가 주제**: 보안 심화(OWASP Top 10 실습), 메시지 큐(Kafka), 컴퓨터 구조(CPU 파이프라인, 캐시) — 21주차+에 부착 가능

---

## 이전 12주 커리큘럼과의 차이

기존 12주 → 신규 20주 전환 시 변경 포인트:

| 변경 | 기존 | 신규 |
|------|------|------|
| 분리 | Week 5 (process-thread에 가상스레드 포함) | Week 6 (프로세스/스레드/스케줄링) + Week 7 (가상 스레드/코루틴) |
| 분리 | Week 10 (인덱스 + 쿼리 최적화 합본) | Week 12 (인덱스/B+Tree) + Week 13 (쿼리 최적화/EXPLAIN) |
| 추가 | — | Week 5 (웹 인증 — JWT/OAuth2/CSRF) |
| 추가 | framework 0개 | Week 16–19 (Spring IoC/MVC/JPA/Boot) |
| 추가 | — | Week 20 (CI/CD·Docker·옵저버빌리티) |

설계 근거 상세는 `cs-obsidian/wiki/topics/curriculum-redesign-2026.md` 참조.
