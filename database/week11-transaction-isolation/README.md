# Week 11. 트랜잭션과 격리 수준

> **발표자**: (미정) | **날짜**: YYYY-MM-DD

---

## 이번 주 목표

- ACID 각 속성을 설명할 수 있다
- 격리 수준 4단계와 각 단계의 이상 현상을 매핑할 수 있다
- MVCC의 동작 원리와 락 기반 동시성 제어와의 차이를 안다
- MySQL InnoDB와 PostgreSQL의 Repeatable Read 동작 차이를 설명할 수 있다
- Write Skew, SSI 등 깊은 동시성 이슈를 이해한다

---

## 학습 체크리스트

- [ ] dirty / non-repeatable / phantom read 시나리오를 두 개의 트랜잭션으로 직접 재현
- [ ] PostgreSQL과 MySQL 각각의 기본 격리 수준 확인 (`SHOW VARIABLES LIKE 'transaction_isolation'` 등)
- [ ] InnoDB의 gap lock 동작 실험 (`SELECT ... FOR UPDATE` 두 트랜잭션 동시 실행)
- [ ] PostgreSQL의 `pg_stat_activity` 로 트랜잭션 상태 모니터링
- [ ] *Designing Data-Intensive Applications* Ch.7 (Transactions) 정독

---

## 꼬리 질문 (최소 5개)

> 답을 모르겠는 질문이 있으면, **본인이 만든 꼬리 질문 1개 이상**을 정리본 끝에 추가하세요.
> 힌트는 `▶ 힌트 보기`를 눌러야 펼쳐집니다 — 먼저 스스로 답해본 후 확인하세요.

### 1. ACID 각각이 의미하는 것은? 그중 격리성(Isolation)이 가장 비용이 큰 이유는?

> 🎯 **면접 단골 — DB 가장 기본**

<details><summary>▶ 힌트 보기</summary>

**ACID:**

- **Atomicity (원자성)** — 트랜잭션은 모두 성공 또는 모두 실패. 부분 성공 없음
  - 구현: undo log, WAL(Write-Ahead Logging)
- **Consistency (일관성)** — 트랜잭션 전후로 DB 제약(무결성, 외래키, NOT NULL 등)이 유지됨
  - 애플리케이션 로직 + DB constraint 의 협업
- **Isolation (격리성)** — 동시 실행되는 트랜잭션이 서로 영향을 주지 않은 듯이 보임
  - 구현: 락 또는 MVCC
- **Durability (지속성)** — 커밋된 트랜잭션은 시스템 장애 후에도 살아남음
  - 구현: WAL을 디스크에 fsync, replication

**Atomicity vs Durability 차이:**

- Atomicity는 트랜잭션 도중 실패 처리 (rollback)
- Durability는 트랜잭션 commit 후의 영속성

**왜 Isolation이 가장 비싼가?**

1. **다른 트랜잭션을 기다려야** 함 — 락 또는 MVCC 버전 추적
2. **완전한 격리 = serial 실행** — throughput 폭락
3. **검증 비용** — SSI는 충돌 그래프 추적
4. 그래서 표준이 4단계의 trade-off 제공: 약한 격리는 빠르지만 anomaly 허용

**다른 속성과 비교:**

- Atomicity, Durability — 단일 트랜잭션 관점, 비교적 cheap (WAL 만으로 보장)
- Consistency — 거의 무료 (제약 검사만)
- Isolation — 동시성 자체와 직결 → 가장 큰 비용

**현실:**

- 대부분의 DB가 기본은 Read Committed 또는 Repeatable Read
- Serializable 까지 안 쓰는 이유 = throughput 손실
- 애플리케이션이 "충돌 가능성 있는 곳만" 격리 강화 (예: 명시적 락, optimistic locking)

</details>

### 2. 격리 수준 4단계와 각 단계에서 발생 가능한 이상 현상은?

> 🎯 **면접 단골 — 매트릭스 외우기**

<details><summary>▶ 힌트 보기</summary>

**3가지 이상 현상:**

1. **Dirty Read** — 다른 트랜잭션의 **커밋되지 않은** 변경을 읽음
2. **Non-repeatable Read** — 한 트랜잭션 안에서 같은 행을 두 번 읽었는데 값이 다름 (다른 트랜잭션이 commit 한 변경 반영)
3. **Phantom Read** — 같은 조건으로 두 번 읽었는데 행 개수가 다름 (다른 트랜잭션이 행을 insert/delete 후 commit)

**격리 수준 4단계 매트릭스:**

| 격리 수준 | Dirty | Non-repeatable | Phantom |
|----------|:-----:|:--------------:|:-------:|
| Read Uncommitted | ⚠️ 발생 | ⚠️ 발생 | ⚠️ 발생 |
| Read Committed | ✅ 차단 | ⚠️ 발생 | ⚠️ 발생 |
| Repeatable Read | ✅ 차단 | ✅ 차단 | ⚠️ 발생 (표준) |
| Serializable | ✅ 차단 | ✅ 차단 | ✅ 차단 |

**SQL 표준 vs 실제 구현:**

- 표준은 위 매트릭스를 정의
- 실제 구현은 더 강할 수도 있음
  - **MySQL InnoDB Repeatable Read** — gap lock으로 phantom도 차단 (표준보다 강함)
  - **PostgreSQL Repeatable Read** — snapshot isolation으로 phantom 자연 차단

**예시 시나리오 — Non-repeatable Read:**

```
T1: SELECT balance FROM accounts WHERE id=1   → 1000
T2: UPDATE accounts SET balance=2000 WHERE id=1
T2: COMMIT
T1: SELECT balance FROM accounts WHERE id=1   → 2000 (값이 바뀜!)
```

→ Read Committed 까지는 발생, Repeatable Read 부터 차단.

**예시 시나리오 — Phantom Read:**

```
T1: SELECT COUNT(*) FROM orders WHERE user_id=1   → 5
T2: INSERT INTO orders (user_id, ...) VALUES (1, ...)
T2: COMMIT
T1: SELECT COUNT(*) FROM orders WHERE user_id=1   → 6 (행이 늘어남!)
```

→ 표준 Repeatable Read 까지 발생, Serializable 부터 차단.

**다른 anomaly (표준 외):**

- **Lost Update** — 두 트랜잭션이 같은 행을 동시에 읽고 수정 (Read Committed에서 발생, Repeatable Read부터 차단)
- **Write Skew** — 두 트랜잭션이 서로의 결과 보지 못한 채 일관성 깨는 결정 (Q5에서 다룸)

**기본값 정리:**

- PostgreSQL: **Read Committed**
- MySQL InnoDB: **Repeatable Read**
- Oracle: **Read Committed**
- SQL Server: **Read Committed**

</details>

### 3. MVCC는 어떻게 동작하는가? 락 기반 동시성 제어와 비교해 어떤 장단점이 있나?

> 🎯 **백엔드 깊이 — PostgreSQL / InnoDB 의 핵심 메커니즘**

<details><summary>▶ 힌트 보기</summary>

**MVCC 핵심 아이디어:**

- 데이터의 **여러 버전**을 동시 유지
- 각 트랜잭션은 **시작 시점의 스냅샷**을 봄
- 쓰기는 **새 버전 생성**, 읽기는 락 없이 적절한 버전 선택

**"Readers don't block writers, writers don't block readers."**

**PostgreSQL MVCC:**

- 모든 행이 `xmin` (생성 트랜잭션 ID), `xmax` (삭제 트랜잭션 ID) 보유
- 트랜잭션이 시작 시 자신의 트랜잭션 ID + active 트랜잭션 set (snapshot) 기록
- 읽을 때: `xmin <= 내 ID AND (xmax IS NULL OR xmax > 내 ID) AND xmin이 active 아님`
- 쓰기는 새 행 추가 + 이전 행에 xmax 표시
- **VACUUM** 으로 더 이상 보일 필요 없는 옛 버전 정리

**InnoDB MVCC:**

- Undo log 에 이전 버전 보관
- Read view 가 어떤 버전을 볼지 결정
- 정리는 자동 (purge thread)

**락 기반 (Strict 2PL):**

- 읽기는 shared lock, 쓰기는 exclusive lock
- 읽기와 쓰기가 서로 차단
- 단순하나 동시성 낮음

**비교:**

| 항목 | 락 기반 | MVCC |
|------|---------|------|
| 읽기 vs 쓰기 차단 | 서로 차단 | 차단 안 함 |
| 읽기 vs 읽기 | 차단 안 함 | 차단 안 함 |
| 쓰기 vs 쓰기 | 차단 | 차단 (같은 행) |
| 처리량 | 낮음 (특히 read-heavy) | 높음 |
| 저장 공간 | 적음 | 많음 (이전 버전 유지) |
| 정리 비용 | 없음 | VACUUM (PG) / purge (InnoDB) |
| 격리 수준 구현 | 락 종류로 구현 | 스냅샷 + 추가 검증 |

**MVCC의 단점:**

- **이전 버전 누적** — 긴 트랜잭션이 살아있으면 VACUUM이 정리 못함
- **table bloat** — PostgreSQL에서 자주 발생하는 운영 이슈
- 디스크 I/O 증가 (이전 버전들도 같이 저장)

**MVCC + 락 결합:**

- MVCC만으로 안 되는 경우 (예: phantom 방지 in MySQL Repeatable Read) → gap lock 추가
- `SELECT ... FOR UPDATE` 는 명시적 락 (애플리케이션이 충돌 직접 방지)

**실무 통찰:**

- 거의 모든 현대 RDBMS가 MVCC (PostgreSQL, MySQL, Oracle, SQL Server, CockroachDB)
- MVCC 가 백엔드 동시성의 표준이 된 이유 = 읽기-쓰기 차단 없는 높은 처리량

</details>

### 4. MySQL InnoDB와 PostgreSQL의 Repeatable Read는 phantom read를 어떻게 다르게 방지하는가?

> 🎯 **깊이 — gap lock vs snapshot isolation**

<details><summary>▶ 힌트 보기</summary>

**SQL 표준:** Repeatable Read 에서 phantom 발생 허용. 두 DB 모두 표준보다 강하게 phantom 차단.

**MySQL InnoDB — Gap Lock + Next-Key Lock:**

- **Record Lock** — 인덱스 레코드 자체에 락
- **Gap Lock** — 인덱스 레코드 사이의 "빈 공간" 에 락
- **Next-Key Lock** — Record Lock + 그 이전 Gap Lock 결합

```sql
-- 트랜잭션 T1
SELECT * FROM users WHERE age BETWEEN 20 AND 30 FOR UPDATE;

-- T1이 [20, 30] 범위 + 그 사이 gap에 lock
-- T2: INSERT INTO users (age) VALUES (25); -- ❌ 차단 (gap lock)
-- T2: INSERT INTO users (age) VALUES (35); -- ✅ OK
```

**Gap Lock 의 비용:**

- 락 영역 확장 → 동시성 감소
- INSERT 가 의외로 차단되어 데드락 발생 가능
- `READ COMMITTED` 격리 수준에서는 gap lock 비활성화 (성능 우선)

**PostgreSQL — Pure Snapshot Isolation:**

- Repeatable Read 시 트랜잭션 시작 시점의 **스냅샷** 사용
- 다른 트랜잭션이 commit 한 새 행은 **스냅샷에 없으므로 안 보임**
- 자연스럽게 phantom 방지 — 락 불필요

```sql
-- 트랜잭션 T1 (PostgreSQL Repeatable Read)
BEGIN;
SELECT COUNT(*) FROM users WHERE age = 25;  -- 5

-- T2가 INSERT (age=25) 후 commit

SELECT COUNT(*) FROM users WHERE age = 25;  -- 여전히 5 (스냅샷)
COMMIT;
```

**비교:**

| 항목 | MySQL InnoDB | PostgreSQL |
|------|--------------|-----------|
| 메커니즘 | Gap Lock | Snapshot |
| 락 사용 | 광범위 | 거의 없음 (읽기는 lock-free) |
| 동시성 | gap lock으로 INSERT 차단 가능 | 매우 높음 |
| 단점 | 데드락, 차단 | bloat (오래된 버전 누적) |
| Write Skew 차단? | 불가 (Serializable에서만) | 불가 (SSI에서만) |

**Write Skew 함정:**

- 두 RR 격리 모두 phantom은 막아도 **write skew는 못 막음**
- 예: 두 의사가 동시에 "다른 사람이 당직이니 나는 빠짐" 결정 → 둘 다 빠져 당직 0명
- 해결: Serializable 격리 또는 명시적 `FOR UPDATE`

**언제 어떤 DB?**

- 읽기 비중 매우 높은 워크로드 → PostgreSQL (락 없는 읽기)
- 인덱스 범위 락이 필요한 케이스 → MySQL InnoDB
- 최근 트렌드: PostgreSQL 의 점유율 상승 (개발자 선호도 + 기능 풍부)

</details>

### 5. 실무에서 격리 수준을 어떻게 선택하나? Write Skew는 무엇이고 SSI는 어떻게 해결하나?

> 🎯 **실무 + 깊이 — DDIA의 고급 주제**

<details><summary>▶ 힌트 보기</summary>

**실무 격리 수준 선택:**

- 대부분의 백엔드 — **기본값 그대로 사용** (PG: RC, MySQL: RR)
  - 이유: 성능과 안전의 균형, 대부분의 anomaly는 발생 빈도 낮음
- 충돌이 가능한 특정 트랜잭션만 강화
  - `SELECT ... FOR UPDATE` (pessimistic lock)
  - optimistic lock (version 컬럼 + UPDATE WHERE version=?)
  - 명시적 advisory lock (Redis 분산 락 등)

**Read Committed가 사실상 표준이 된 이유:**

- 대부분의 anomaly가 도메인 레벨에서 처리 가능 (재시도, 명시적 락)
- Repeatable Read 는 락 또는 snapshot 비용 발생
- Serializable 은 처리량 큰 손실
- → "느슨하게 + 위험한 곳만 강화" 가 실무 패턴

**Write Skew란:**

두 트랜잭션이 동시에 실행되며 각자는 일관성 유지하지만, 결과적으로 일관성 깨지는 케이스.

**고전 예시 — 의사 당직:**

```
규칙: "한 명 이상의 의사가 항상 당직"

T1 (Alice): SELECT COUNT(*) FROM doctors WHERE on_call=true   → 2
T1: 2명이니 빠져도 됨. UPDATE doctors SET on_call=false WHERE id=Alice

T2 (Bob): SELECT COUNT(*) FROM doctors WHERE on_call=true     → 2 (T1 commit 전)
T2: 2명이니 빠져도 됨. UPDATE doctors SET on_call=false WHERE id=Bob

T1, T2 둘 다 commit → 당직 0명. 규칙 위반!
```

**왜 Repeatable Read 가 못 막나?**

- 각 트랜잭션이 본 데이터는 그대로 (snapshot) — 변경 안 일어남
- 둘 다 자기 행만 업데이트 — 동일 행 충돌 X
- 락도 안 걸림 (다른 행)
- **두 트랜잭션이 각자의 결정을 내릴 때 사용한 정보가 서로의 변경으로 무효화됨**

**SSI (Serializable Snapshot Isolation):**

- PostgreSQL 9.1+ Serializable 격리에서 사용
- 트랜잭션들 간 **read-write dependency graph** 추적
- 위험한 패턴 (사이클) 감지 시 한 트랜잭션 자동 abort
- 락 없이 직렬성 보장 + 락 기반보다 동시성 높음

**SSI 동작:**

```
T1 read X, write Y
T2 read Y, write X
→ 사이클 감지! 한 트랜잭션 abort
```

**SSI 의 비용:**

- 추가 메모리 (predicate 추적)
- abort 후 재시도 로직 필요 — 애플리케이션이 retry 처리
- 충돌 적은 워크로드에서는 거의 free, 충돌 많으면 abort 폭증

**실무 패턴:**

- PostgreSQL Serializable + retry — write skew 안전
- 또는 RR + `FOR UPDATE` 로 명시적 락
- 또는 도메인 레벨 검증 (`COUNT(*) >= 1` 보장하는 별도 트랜잭션)

**낙관적 vs 비관적 락:**

| 패턴 | 동작 | 적합 |
|------|------|------|
| Pessimistic (`FOR UPDATE`) | 미리 락 | 충돌 빈번 |
| Optimistic (version 검사) | 충돌 시 재시도 | 충돌 드묾 |
| SSI | DB가 자동 검증·abort | 복잡한 read-modify-write |

**핵심 통찰:** 격리 수준 = "DB 가 어디까지 막아주는가" + "내가 어디까지 직접 보장해야 하는가" 의 분담선.

</details>

### 내가 만든 꼬리 질문

<!-- 위 5개를 풀어보고 새로 떠오른 의문을 1개 이상 적어주세요 -->

---

## 핵심 개념

- ACID (원자성, 일관성, 격리성, 지속성)
- 트랜잭션 상태 (Active, Partially Committed, Committed, Failed, Aborted)
- 격리 수준 4단계: Read Uncommitted → Read Committed → Repeatable Read → Serializable
- 동시성 이상 현상: Dirty Read, Non-Repeatable Read, Phantom Read

---

## 동작 원리 / 구조

<!-- 다이어그램 또는 의사코드를 여기에 작성 -->
<!-- 예: 격리 수준별 이상 현상 발생 여부 표, MVCC 버전 체인 구조 -->

---

## 트레이드오프

- 장점:
- 단점:
- 대안:

---

## 실무/면접 포인트

1. **Q. ACID에서 Isolation(격리성)이란 무엇이며 왜 완전한 격리는 비용이 큰가?**
   A.

2. **Q. MySQL InnoDB의 Repeatable Read에서 Phantom Read가 발생하지 않는 이유는?**
   A.

3. **Q. 락 기반 동시성 제어와 MVCC의 차이는?**
   A.

---

## 딥다이브

- MVCC (Multi-Version Concurrency Control) 동작 원리
- 락 기반 vs MVCC 비교
- MySQL Repeatable Read + Next-Key Lock으로 Phantom 방지
- Serializable Snapshot Isolation (SSI)

---

## 토론 주제

- 실무에서 격리 수준을 어떻게 선택하는가? Read Committed가 사실상 표준이 된 이유는?

---

## 내가 새로 알게 된 것

<!-- 자기 언어로 자유롭게 -->

---

## 참고 자료

- "Designing Data-Intensive Applications" (Kleppmann) Ch.7
