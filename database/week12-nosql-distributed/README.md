# Week 12. NoSQL, 분산 데이터베이스

> **발표자**: (미정) | **날짜**: YYYY-MM-DD

---

## 이번 주 목표

- CAP과 PACELC를 이해하고 본인이 쓰는 시스템을 분류할 수 있다
- NoSQL 4가지 종류와 각각의 적합한 사용 사례를 안다
- 복제 방식(단일 / 다중 / 리더리스) 별 트레이드오프를 안다
- Eventual consistency 와 Quorum (R + W > N)의 동작을 설명할 수 있다
- 마이크로서비스 분산 트랜잭션 패턴(Saga, Outbox)을 알고 적용할 수 있다

---

## 학습 체크리스트

- [ ] 본인이 사용하는 시스템의 CAP/PACELC 분류 (예: PostgreSQL = CP/EC, Cassandra = AP/EL)
- [ ] DynamoDB / Cassandra / MongoDB / Redis 중 1개의 데이터 모델 직접 분석
- [ ] Raft 알고리즘 시각화 ([raft.github.io](https://raft.github.io)) 1회 시청
- [ ] Saga vs 2PC 비교 정리 + Choreography vs Orchestration
- [ ] 본인 회사/프로젝트의 분산 트랜잭션 처리 방식 점검

---

## 꼬리 질문 (최소 5개)

> 답을 모르겠는 질문이 있으면, **본인이 만든 꼬리 질문 1개 이상**을 정리본 끝에 추가하세요.
> 힌트는 `▶ 힌트 보기`를 눌러야 펼쳐집니다 — 먼저 스스로 답해본 후 확인하세요.

### 1. CAP 정리는 무엇이고 어떤 한계가 있나? PACELC는 CAP을 어떻게 보완하는가?

> 🎯 **면접 단골 + 2026 트렌드 — PACELC 가 점점 중요**

<details><summary>▶ 힌트 보기</summary>

**CAP 정리 (Eric Brewer, 2000):**

분산 시스템은 다음 셋 중 **2가지만** 보장 가능:

- **C (Consistency)** — 모든 노드가 같은 시점에 같은 데이터를 봄 (linearizability)
- **A (Availability)** — 모든 요청이 응답을 받음 (성공/실패 무관)
- **P (Partition tolerance)** — 네트워크 분할이 일어나도 시스템 동작

**핵심 통찰:** 인터넷 환경에서 P는 항상 발생 가능 → **실질적으로는 CP vs AP 선택**

| 분류 | 의미 | 예시 |
|------|------|------|
| **CP** | Partition 시 가용성 포기 (응답 안 함) | HBase, MongoDB(기본), Etcd, ZooKeeper |
| **AP** | Partition 시 일관성 포기 (stale 응답 허용) | DynamoDB, Cassandra, Riak |
| **CA** | 분산 시스템 아님 (단일 노드) | 전통 RDBMS (분산 X 가정) |

**CAP의 한계:**

1. **너무 단순한 이분법** — 실제로는 일관성·가용성 모두 spectrum
2. **정상 상태(non-partition)를 안 다룸** — 실무는 99% 가 정상 상태
3. **현실에서는 partition 동안만 트레이드오프 발생하는 게 아님** — 정상 상태에서도 latency vs consistency 선택

**PACELC (2010, Daniel Abadi):**

CAP을 두 상황으로 분리:

- **P (Partition 시):** A vs C
- **E (Else, 정상 상태):** **L (Latency) vs C (Consistency)**

**예시 분류:**

| 시스템 | PACELC | 설명 |
|--------|--------|------|
| Cassandra, DynamoDB, ScyllaDB | **PA / EL** | partition 시 가용성 우선, 정상 시 latency 우선 |
| MongoDB (기본 설정) | **PC / EC** | partition 시 일관성 우선, 정상 시도 일관성 우선 |
| PostgreSQL | **(분산 X) / EC** | 단일 노드 |
| Spanner | **PC / EC** | 강한 일관성 (TrueTime API 활용) |

**왜 EL이 더 중요?**

- 정상 상태가 압도적으로 많음 (99.99% uptime)
- 일관성 강화 = 노드 간 동기화 비용 = latency↑
- 글로벌 서비스 → 동기 복제 시 RTT 누적 (대륙 간 100ms+)
- 따라서 "**EL** 시스템은 정상 상태에서도 약한 일관성 + 낮은 latency 선택"

**면접 답변 패턴:**

"CAP의 결정은 partition 발생 시 한정. 실무에서 더 중요한 결정은 PACELC의 Else 부분 — 정상 상태에서 latency vs consistency 트레이드오프입니다."

</details>

### 2. NoSQL의 4가지 종류는 각각 어떤 사용 사례에 적합한가? RDBMS와의 차이는?

> 🎯 **면접 단골 + 실무 결정**

<details><summary>▶ 힌트 보기</summary>

**4가지 NoSQL 종류:**

#### 1. Key-Value Store

- 단순한 key → value 매핑
- 매우 빠른 단일 키 조회
- 예: **Redis**, **DynamoDB**, **Memcached**, **etcd**
- 적합: 캐시, 세션 저장소, 분산 락, leaderboard

```
SET user:1234 "{...}"
GET user:1234
```

#### 2. Document Store

- JSON 같은 반구조화 문서 저장
- 스키마 유연 — 필드 추가·삭제 자유
- 예: **MongoDB**, **CouchDB**, **Firestore**
- 적합: CMS, 카탈로그, 사용자 프로필, 이벤트 로그

```json
db.users.insert({ name: "Alice", roles: ["admin", "user"], ... })
```

#### 3. Column-family (Wide Column)

- 행 단위로 다른 컬럼 가능
- column family 단위로 저장 → 분석 쿼리 효율
- 예: **Cassandra**, **HBase**, **ScyllaDB**, **BigTable**
- 적합: 시계열 데이터, IoT, 매우 큰 분산 환경 (수백 PB)

#### 4. Graph

- 노드 + 관계 중심
- 다단계 관계 탐색이 핵심
- 예: **Neo4j**, **Amazon Neptune**, **JanusGraph**
- 적합: 소셜 네트워크, 추천 시스템, 사기 탐지, 지식 그래프

```cypher
MATCH (a:Person)-[:FRIEND]-(b:Person)-[:FRIEND]-(c:Person) RETURN c
```

**RDBMS vs NoSQL:**

| 항목 | RDBMS | NoSQL |
|------|-------|-------|
| 스키마 | 강함 (DDL) | 유연 또는 없음 |
| 트랜잭션 | ACID 강함 | 보통 약함 (BASE) |
| 조인 | 강함 | 제한적 또는 X |
| 수평 확장 | 어려움 (sharding 복잡) | 자연스럽게 분산 |
| 일관성 | 강함 | tunable / eventual |
| 학습 곡선 | 표준 SQL | 시스템마다 다름 |

**언제 무엇?**

- 일반 비즈니스 데이터, 트랜잭션 중심 → **RDBMS** (PostgreSQL 권장)
- 캐시 / 세션 → **Redis**
- 로그·이벤트·시계열 → **Cassandra / ClickHouse**
- 유연 스키마 + 단일 도큐먼트 위주 → **MongoDB**
- 관계 탐색 → **Graph DB**

**Polyglot persistence:**

- 한 시스템에 여러 DB 조합 — 흔한 실무 패턴
- 예: PostgreSQL (트랜잭션) + Redis (캐시) + Elasticsearch (검색) + Cassandra (로그)

**최근 트렌드:**

- PostgreSQL 의 부상 — JSONB, full-text search, vector search 등으로 NoSQL 영역까지 흡수
- Vector DB (Pinecone, Weaviate, pgvector) — AI/RAG 시대 신규 카테고리

</details>

### 3. 단일 리더 / 다중 리더 / 리더리스 복제의 차이와 트레이드오프는? 각각의 대표 시스템은?

> 🎯 **백엔드 깊이 — 분산 DB 의 핵심 분류**

<details><summary>▶ 힌트 보기</summary>

**1. 단일 리더 (Single-leader, Master-Slave):**

- 모든 쓰기는 **리더에 보냄** → 리더가 팔로워에게 복제
- 읽기는 리더 또는 팔로워
- 동기 vs 비동기 복제 선택 가능

```
[Client] -- write --> [Leader] -- replicate --> [Followers]
[Client] -- read  --> [Leader or Follower]
```

**장점:**

- 단순, 일관성 보장 쉬움
- 충돌 없음

**단점:**

- 리더가 SPOF — failover 필요 (보통 자동)
- 쓰기 처리량은 단일 리더 한계
- 비동기 복제 시 follower stale read 가능

**예시:** PostgreSQL streaming replication, MySQL replication, MongoDB(기본), Redis Sentinel

#### 2. 다중 리더 (Multi-leader):

- 여러 리더가 각자 쓰기를 받음
- 리더들끼리 양방향 복제
- **충돌 해결** 필요 (last-write-wins, custom logic, CRDT 등)

**장점:**

- 지리적 분산 (각 지역에 리더) → 낮은 쓰기 latency
- 일부 노드 장애에도 쓰기 가능

**단점:**

- 충돌 해결 복잡
- 보통 강한 일관성 포기

**예시:** CouchDB, BDR for PostgreSQL, MySQL Group Replication, Tungsten

#### 3. 리더리스 (Leaderless):

- **모든 노드가 쓰기·읽기 받음**
- Quorum (R + W > N) 으로 일관성 확보
- Anti-entropy (gossip, read repair) 로 동기화

**장점:**

- 단일 SPOF 없음
- 부분 장애 환경에서도 동작
- 자연스러운 분산

**단점:**

- 일관성 약함 (eventual)
- 클라이언트가 quorum 직접 처리하거나 라이브러리 의존
- 충돌 해결 복잡 (vector clock, CRDT)

**예시:** **DynamoDB**, **Cassandra**, **Riak**, **ScyllaDB**

**비교 정리:**

| 항목 | 단일 리더 | 다중 리더 | 리더리스 |
|------|----------|----------|---------|
| 쓰기 가용성 | 리더 다운 시 짧은 중단 | 매우 높음 | 매우 높음 |
| 일관성 | 강 (리더에서 읽으면) | 약 | 약 (tunable) |
| 충돌 처리 | 없음 | 복잡 | 복잡 |
| 운영 난이도 | 쉬움 | 어려움 | 중간 |
| 적합 워크로드 | 일반 OLTP | 글로벌 분산 | 매우 큰 규모, 가용성 우선 |

**실무 통찰:**

- 대부분 백엔드 — **단일 리더 + 읽기 replica** (RDS, Aurora 등 매니지드 활용)
- 글로벌 서비스 — Cassandra/DynamoDB 또는 Spanner
- 강한 일관성 + 글로벌 — Spanner, CockroachDB (Paxos/Raft 합의)

</details>

### 4. Eventual Consistency 와 Quorum (R + W > N)은 어떻게 동작하나? Vector clock 이 필요한 이유는?

> 🎯 **깊이 — DDIA 핵심 / 분산 시스템 본질**

<details><summary>▶ 힌트 보기</summary>

**Eventual Consistency:**

- "**충분한 시간이 지나면** 모든 replica 가 같은 값으로 수렴"
- 즉시 일관성 X, 단기적으로 stale read 허용
- 가용성·latency 우선 시스템의 표준
- 예: DNS, S3 (이전), Cassandra, DynamoDB

**Quorum (R + W > N):**

- N: replica 총 수
- W: 쓰기가 성공으로 간주되기 위해 응답해야 하는 replica 수
- R: 읽기가 응답으로 받아야 하는 replica 수
- **R + W > N** 이면 읽기와 쓰기 quorum이 반드시 겹침 → 최신 값 보장

**예시 (N=3):**

| 설정 | 동작 |
|------|------|
| W=3, R=1 | 쓰기 느림(3개 다 기다림), 읽기 빠름 |
| W=1, R=3 | 쓰기 빠름, 읽기 느림 |
| W=2, R=2 | 균형, R+W > N (4 > 3) → 일관성 |
| W=1, R=1 | 빠르지만 stale read 가능 (R+W=2 < 3) |

**현실에서의 trade-off:**

- AWS DynamoDB 기본: W=quorum, R=quorum (eventually consistent reads)
- Strongly consistent read 옵션 제공 (별도 비용·latency)
- Cassandra: tunable per-query (`CONSISTENCY ONE / QUORUM / ALL`)

**Quorum 의 한계:**

- 동시 쓰기 시 어느 게 "마지막" 인지 결정 어려움
- 노드 시계가 다르면 last-write-wins 가 부정확

**Vector Clock:**

- 각 replica 마다 별도 카운터 보유
- 쓰기 시 자기 카운터 ++, 받은 vector clock 과 element-wise max
- 두 vector clock 이 비교 가능하면 인과 관계 결정, 비교 불가능하면 **concurrent (충돌)**

**예시:**

```
Initial: {A:0, B:0, C:0}

A에서 쓰기:           {A:1, B:0, C:0}
B에서 쓰기:           {A:0, B:1, C:0}
→ 비교 불가능 → 충돌, 둘 다 보관 후 애플리케이션이 해결

A의 쓰기를 본 후 B 쓰기: {A:1, B:1, C:0}
→ 두 번째가 첫 번째의 후속 → 인과관계 명확
```

**용도:**

- DynamoDB, Riak 의 충돌 감지
- Distributed databases 에서 인과관계 추적

**대안:**

- **Last-Write-Wins (LWW)** — timestamp 기반, 단순하나 시계 동기화 필요
- **CRDT (Conflict-free Replicated Data Type)** — 자동 병합 가능한 자료구조 (counter, set, map)
- **Application-level resolution** — 사용자에게 두 버전 보여주고 선택 (Git merge conflict 와 유사)

**실무 적용:**

- 대부분의 백엔드 — eventually consistent + 명시적 동기화 필요한 곳만 강한 일관성
- 카운터·좋아요 — CRDT 또는 atomic increment
- 사용자 데이터 — LWW + 클라이언트가 마지막 본 timestamp 동반

</details>

### 5. 마이크로서비스에서 분산 트랜잭션은 어떻게 처리하나? 2PC vs Saga, Choreography vs Orchestration 차이는?

> 🎯 **백엔드 실무 + 2026 트렌드 — Outbox 패턴 포함**

<details><summary>▶ 힌트 보기</summary>

**왜 분산 트랜잭션이 어려운가:**

- 마이크로서비스 = 각 서비스가 자체 DB 보유
- 한 비즈니스 작업이 여러 서비스 DB 변경 (예: 주문 = 주문 서비스 + 결제 서비스 + 재고 서비스)
- 단일 ACID 트랜잭션 불가능

#### 옵션 1: 2PC (Two-Phase Commit)

```
[Coordinator]
   1. PREPARE 모든 참여자에게
   2. 모두 OK 받으면 COMMIT
   3. 하나라도 ABORT 하면 ABORT
```

**문제:**

- **Blocking** — coordinator 다운 시 참여자들이 무한 대기
- **SPOF** — coordinator 가 장애점
- **확장성 낮음** — 모든 서비스 동기 대기
- 마이크로서비스에서는 거의 안 씀

#### 옵션 2: Saga 패턴 (사실상 표준)

- 긴 트랜잭션을 작은 **로컬 트랜잭션**들의 시퀀스로
- 각 단계마다 **compensating transaction** (롤백용 보상 작업) 정의
- 실패 시 이전 단계들의 보상 작업을 역순으로 실행

**예시 — 주문 처리 Saga:**

```
1. 주문 생성 (주문 서비스)        [보상: 주문 취소]
2. 결제 (결제 서비스)             [보상: 환불]
3. 재고 차감 (재고 서비스)         [보상: 재고 복구]
4. 배송 시작 (배송 서비스)         [보상: 배송 취소]

3에서 실패 시:
- 결제 환불 → 주문 취소 (역순 보상)
```

**Saga 의 두 가지 패턴:**

#### A. Choreography (안무):

- 각 서비스가 이벤트 발행 + 구독
- 중앙 조정자 없음
- 각자 알아서 다음 단계 실행

```
주문 서비스 → "OrderCreated" 이벤트 발행
결제 서비스 → 구독 → 결제 처리 → "PaymentCompleted" 발행
재고 서비스 → 구독 → 재고 차감 → ...
```

장점: 결합도 낮음, 단순
단점: 흐름 파악 어려움, 디버깅 힘듬, 로직이 분산됨

#### B. Orchestration (지휘):

- 중앙 **Orchestrator** 가 흐름 제어
- 각 서비스에 명령 → 응답 받으면 다음 단계

```
Orchestrator → 결제 서비스에 "결제하라"
결제 서비스 응답 → Orchestrator → 재고 서비스에 "차감하라"
실패 시 → Orchestrator 가 보상 트랜잭션 트리거
```

장점: 흐름 명확, 디버깅 쉬움, 로직 집중
단점: Orchestrator 가 결합점이 될 수 있음

**언제 무엇:**

- 흐름이 단순, 서비스 적음 → Choreography
- 흐름 복잡, 모니터링 중요 → Orchestration
- Camunda, Temporal 같은 워크플로우 엔진이 Orchestration 지원

#### Outbox Pattern (실무 필수):

- DB 변경 + 이벤트 발행을 atomic 하게 보장
- 트릭: 이벤트도 같은 DB의 **outbox 테이블에 INSERT**
- 별도 프로세스 (CDC, Debezium 등)가 outbox 를 읽어 메시지 큐로 발행

```sql
BEGIN;
  INSERT INTO orders ...
  INSERT INTO outbox (event_type, payload, ...) VALUES ('OrderCreated', ...)
COMMIT;
```

→ 트랜잭션 commit 되면 이벤트도 보장. commit 실패 시 이벤트 발행도 안 됨.

**핵심 통찰:**

- 분산 트랜잭션은 **eventual consistency + 보상 패턴** 으로 처리
- 진정한 ACID 분산 트랜잭션은 비싸고 어렵다 → 2PC 거의 안 씀
- Saga + Outbox + 메시지 큐 가 2026 마이크로서비스 표준 조합

**Idempotency 의 중요성:**

- 메시지가 중복 도달 가능 (at-least-once delivery)
- 모든 핸들러는 idempotent 해야 함 (Week 3 Q3 의 Idempotency Key 와 연결)

</details>

### 내가 만든 꼬리 질문

<!-- 위 5개를 풀어보고 새로 떠오른 의문을 1개 이상 적어주세요 -->

---

## 핵심 개념

- CAP 정리 (일관성, 가용성, 파티션 허용성)
- PACELC 모델 (CAP 확장)
- NoSQL 종류: Key-Value, Document, Column-family, Graph
- 샤딩 (수평 분할) 전략
- 복제 방식: 단일 리더 / 다중 리더 / 리더리스

---

## 동작 원리 / 구조

<!-- 다이어그램 또는 의사코드를 여기에 작성 -->
<!-- 예: 단일 리더 복제 구조, quorum 읽기/쓰기 다이어그램 -->

---

## 트레이드오프

- 장점:
- 단점:
- 대안:

---

## 실무/면접 포인트

1. **Q. CAP 정리에서 CP와 AP 시스템의 예시를 들고 차이를 설명하라.**
   A.

2. **Q. Eventual Consistency란 무엇이며 어떤 상황에서 허용 가능한가?**
   A.

3. **Q. 마이크로서비스에서 분산 트랜잭션을 어떻게 처리하는가?**
   A.

---

## 딥다이브

- Eventual Consistency와 Quorum (R + W > N)
- Vector Clock — 분산 시스템의 인과 관계 추적
- Raft / Paxos 합의 알고리즘 개요
- 분산 트랜잭션과 Saga 패턴 (Choreography vs Orchestration)

---

## 토론 주제

- 마이크로서비스 아키텍처에서 서비스 간 데이터 일관성을 어떻게 보장할 것인가?

---

## 내가 새로 알게 된 것

<!-- 자기 언어로 자유롭게 -->

---

## 참고 자료

- "Designing Data-Intensive Applications" (Kleppmann) Ch.5-9
