# Week 10. 인덱스와 쿼리 최적화

> **발표자**: (미정) | **날짜**: YYYY-MM-DD

---

## 이번 주 목표

- B-Tree와 B+Tree 차이를 알고 DB가 B+Tree를 사용하는 이유를 안다
- 클러스터드 / 논클러스터드 인덱스 차이를 설명하고 InnoDB PK를 설계할 수 있다
- 복합 인덱스의 컬럼 순서를 워크로드에 맞춰 결정할 수 있다
- 커버링 인덱스를 활용해 쿼리를 최적화할 수 있다
- EXPLAIN 결과를 읽고 인덱스가 안 타는 원인을 진단할 수 있다

---

## 학습 체크리스트

- [ ] EXPLAIN 결과의 `type`, `key`, `rows`, `Extra` 컬럼 의미 외우기
- [ ] 본인 운영/사용 서비스의 느린 쿼리 1개에 EXPLAIN 적용해 분석
- [ ] (a, b) 복합 인덱스를 만들고 a / b / (a,b) 검색 시 인덱스 사용 여부 비교
- [ ] 커버링 인덱스 적용 전후 쿼리 시간 비교 실험
- [ ] `LIKE 'prefix%'` 와 `LIKE '%suffix'` 의 인덱스 사용 차이 확인

---

## 꼬리 질문 (최소 5개)

> 답을 모르겠는 질문이 있으면, **본인이 만든 꼬리 질문 1개 이상**을 정리본 끝에 추가하세요.
> 힌트는 `▶ 힌트 보기`를 눌러야 펼쳐집니다 — 먼저 스스로 답해본 후 확인하세요.

### 1. B-Tree와 B+Tree의 차이는? DB가 B+Tree를 사용하는 이유는?

> 🎯 **면접 단골 — 인덱스 자료구조의 본질**

<details><summary>▶ 힌트 보기</summary>

**B-Tree:**

- 모든 노드(internal + leaf)에 **키 + 데이터** 저장
- 각 노드가 여러 자식 (M-ary tree, M=수십~수백)
- 균형 트리 → 검색·삽입·삭제 모두 O(log n)

**B+Tree:**

- **internal 노드는 키만**, leaf 노드만 데이터(또는 데이터 포인터) 보유
- **leaf 노드들이 linked list로 연결** → 범위 스캔 효율적
- DB / 파일 시스템에서 표준

**왜 DB가 B+Tree?**

1. **디스크 I/O 최소화**
   - 디스크 한 번 읽으면 한 페이지(보통 16KB) 통째로
   - B+Tree는 internal 노드에 키만 → 한 페이지에 더 많은 키 → fanout 큼 → 트리 높이↓
   - 1억 행도 트리 높이 3~4 정도

2. **범위 쿼리 효율**
   - leaf linked list 따라가면 됨 (예: `WHERE age BETWEEN 20 AND 30`)
   - B-Tree는 범위 스캔 시 재귀적으로 다시 트리를 타야 함

3. **순차 접근**
   - leaf 정렬 + linked list → ORDER BY 시 정렬 비용 0
   - 페이지 캐시 / OS prefetch 와 친화적

**Hash Index vs B+Tree:**

| 항목 | Hash | B+Tree |
|------|------|--------|
| 단일 키 검색 | O(1) | O(log n) |
| 범위 검색 | 불가 | 가능 |
| 정렬 검색 | 불가 | 가능 (ORDER BY 무료) |
| 부분 일치 (prefix) | 불가 | `LIKE 'abc%'` 가능 |

→ DB의 기본 인덱스는 B+Tree. Hash 는 메모리 DB(Redis) 또는 특수한 경우만.

**MySQL의 변형:**

- InnoDB: B+Tree (clustered + secondary 모두)
- MEMORY 엔진: Hash 가능
- 일부 NoSQL: LSM-Tree (Cassandra, RocksDB) — 쓰기 최적화

</details>

### 2. 클러스터드 인덱스와 논클러스터드 인덱스의 차이는? InnoDB에서 PK를 어떻게 설계해야 하나?

> 🎯 **백엔드 실무 — Week 9의 UUID PK 결정과 연결**

<details><summary>▶ 힌트 보기</summary>

**클러스터드 인덱스 (Clustered):**

- **leaf 노드에 실제 row 데이터** 보관
- 테이블 데이터가 인덱스 순서대로 물리적으로 정렬
- **테이블당 1개만** 가능 (실제 데이터 정렬은 한 가지)
- InnoDB: PK 가 자동으로 clustered 인덱스. PK 없으면 첫 unique not-null 사용, 없으면 hidden 6-byte ROWID

**논클러스터드 (Secondary) 인덱스:**

- leaf 노드에 **인덱스 컬럼 + PK 값** 만
- 실제 데이터는 PK로 다시 찾아야 함 → **double lookup**
- 테이블당 여러 개 가능

**예시:**

```
테이블: users (id PK, email, name)
secondary index on email

email 검색:
  1) email 인덱스 트리에서 email='a@x.com' 찾음 → id=1234 발견
  2) clustered 인덱스(PK)에서 id=1234 찾음 → 실제 row
```

**InnoDB PK 설계 가이드:**

1. **단조 증가 (monotonic) PK 가 좋다**
   - auto-increment 또는 UUID v7 (시간순)
   - 새 행이 인덱스 끝에 추가 → 페이지 분할 없음

2. **UUID v4 PK는 피한다**
   - 랜덤 → 인덱스 중간 곳곳에 삽입 → 페이지 분할 폭증
   - 디스크 I/O 폭증, 성능 급락 (Week 9 Q5)

3. **PK는 작게**
   - 모든 secondary index가 PK 값을 저장 → PK 크면 모든 인덱스가 커짐
   - INT (4B) > BIGINT (8B) > UUID (16B)

4. **자연 키 보다 대리 키**
   - email 을 PK 로 쓰면 변경 시 모든 secondary index 갱신 필요
   - auto-increment id + email unique 인덱스가 표준

**실무 패턴:**

```sql
-- 권장
CREATE TABLE users (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,    -- 작고 단조증가
  uuid CHAR(36) NOT NULL UNIQUE,           -- 외부 노출용 (UUID v7)
  email VARCHAR(255) NOT NULL UNIQUE,
  ...
);
```

</details>

### 3. 복합 인덱스(composite)에서 컬럼 순서가 왜 중요한가? `(user_id, created_at)` 인덱스로 어떤 쿼리들이 인덱스를 탈 수 있나?

> 🎯 **면접 단골 + 실무 결정**

<details><summary>▶ 힌트 보기</summary>

**Leftmost Prefix 규칙:**

`(a, b, c)` 복합 인덱스는 다음 조회만 인덱스 사용 가능:

- ✅ `WHERE a = ?`
- ✅ `WHERE a = ? AND b = ?`
- ✅ `WHERE a = ? AND b = ? AND c = ?`
- ❌ `WHERE b = ?` (a 없이 b만)
- ❌ `WHERE a = ? AND c = ?` (b 건너뛰면 c 활용 못 함)

**왜 이렇게 동작?**

- 복합 인덱스는 a 로 1차 정렬, 같은 a 안에서 b 로 정렬, 같은 (a,b) 안에서 c 로 정렬
- 전화번호부와 같음: 성으로 정렬되어 있으면 이름만으로는 찾을 수 없음

**`(user_id, created_at)` 인덱스 활용:**

- ✅ `WHERE user_id = 1` — 인덱스 사용
- ✅ `WHERE user_id = 1 ORDER BY created_at DESC` — 정렬도 무료
- ✅ `WHERE user_id = 1 AND created_at > '2024-01-01'` — 범위 검색
- ❌ `WHERE created_at > '2024-01-01'` — 인덱스 못 탐
- ⚠️ `WHERE user_id IN (1,2,3) ORDER BY created_at` — 정렬은 추가 비용 (각 user_id 별 정렬됨)

**컬럼 순서 결정 기준:**

1. **자주 쓰이는 등호(=) 조건을 먼저**
   - `WHERE a = ? AND b > ?` 면 (a, b)
   - 등호 → 범위 → 정렬 순서가 일반 규칙

2. **선택도(selectivity) 높은 컬럼을 먼저** (논쟁 있음)
   - 선택도 = unique 값 비율
   - 등호 조건이 같이 쓰일 때 효과적
   - 단, 범위 조건이 있으면 범위 컬럼 앞쪽에 두면 그 뒤 컬럼은 활용 못함

3. **WHERE + ORDER BY 모두 만족 가능한 순서**
   - `(user_id, created_at)` 면 user별 최신 글 조회 효율적

**범위 조건의 함정:**

```sql
-- 인덱스 (status, created_at)
WHERE status = 'active' AND created_at > '2024-01-01'  -- ✅ 둘 다 활용

-- 인덱스 (created_at, status)
WHERE status = 'active' AND created_at > '2024-01-01'  -- ⚠️ created_at 범위까지만, status는 풀 스캔
```

**실무 통찰:**

- 인덱스 1개에 컬럼 다 넣지 말고 패턴별로 여러 인덱스 + 커버링 고려
- 너무 많은 인덱스는 INSERT/UPDATE 비용↑ → 트레이드오프
- pt-index-usage 등으로 사용 안 하는 인덱스 찾아 정리

</details>

### 4. 커버링 인덱스(covering)는 무엇이며 어떻게 활용하나? EXPLAIN의 `Using index` 와 `Using where; Using index` 는 어떻게 다른가?

> 🎯 **실무 — 쿼리 최적화 핵심 패턴**

<details><summary>▶ 힌트 보기</summary>

**커버링 인덱스란:**

- 쿼리가 필요로 하는 **모든 컬럼이 인덱스에 포함**된 상태
- → secondary index 만으로 결과 반환, **테이블 접근(double lookup) 불필요**
- EXPLAIN Extra 에 `Using index` 표시

**예시:**

```sql
-- 인덱스: (user_id, status)
SELECT user_id, status FROM orders WHERE user_id = 1;
-- ✅ 커버링 — 인덱스에 user_id, status 모두 있음 → Using index

SELECT user_id, status, total FROM orders WHERE user_id = 1;
-- ❌ 커버링 아님 — total 컬럼이 인덱스에 없음 → 테이블 lookup
```

**EXPLAIN Extra 메시지 구분:**

| Extra | 의미 |
|-------|------|
| `Using index` | **커버링** — 인덱스만 읽고 끝. 매우 빠름 |
| `Using where; Using index` | 인덱스에서 추가 필터링 (필요 컬럼은 다 있음) → **여전히 커버링** |
| `Using where` | 인덱스 사용했지만 테이블에서 데이터 읽음 → 커버링 아님 |
| `Using index condition` | Index Condition Pushdown — 일부 조건을 스토리지 엔진으로 내림 |
| `Using filesort` | 정렬을 메모리/디스크에서 별도 수행 → **나쁨** |
| `Using temporary` | 임시 테이블 생성 → 나쁨 |

**커버링 인덱스 만들기:**

```sql
-- 자주 쓰는 쿼리:
SELECT id, name, status FROM users WHERE company_id = ? AND active = 1;

-- 커버링 인덱스:
CREATE INDEX idx_cover ON users (company_id, active, name, id);
-- 또는 INCLUDE 절 (PostgreSQL):
CREATE INDEX idx_cover ON users (company_id, active) INCLUDE (name, id);
```

**INCLUDE 절 (PostgreSQL):**

- 인덱스 키 정렬에는 영향 안 주고 leaf에만 포함
- 인덱스 크기는 늘지만 검색 트리 효율은 유지
- MySQL은 INCLUDE 없음 → 키에 직접 포함

**언제 커버링 적용?**

- 자주 실행되는 쿼리
- 작은 row만 필요한 쿼리 (전체 row 가 아닌 몇 컬럼만)
- 페이지네이션 쿼리

**커버링의 비용:**

- 인덱스 크기 증가 → INSERT/UPDATE 비용↑, 메모리 사용↑
- 모든 쿼리에 적용하면 인덱스가 표보다 커질 수 있음
- 핫 쿼리에만 선택적 적용

</details>

### 5. 인덱스가 있는데도 안 타는 경우는 어떤 것들이 있나? 어떻게 진단하고 해결하는가?

> 🎯 **면접 단골 + 실무 — 가장 많이 디버깅하는 주제**

<details><summary>▶ 힌트 보기</summary>

**대표 케이스:**

#### 1. 컬럼에 함수/연산 적용

```sql
WHERE YEAR(created_at) = 2024              -- ❌ 인덱스 못 탐
WHERE created_at >= '2024-01-01' AND created_at < '2025-01-01'  -- ✅ 인덱스 탐
```

#### 2. 암묵적 형변환 (Implicit Conversion)

```sql
-- email VARCHAR
WHERE email = 12345                        -- ❌ 숫자 → 문자열 변환, 인덱스 못 탐
WHERE email = '12345'                      -- ✅
```

```sql
-- phone VARCHAR
WHERE phone = 010_1234_5678                -- 숫자로 해석되어 변환 발생
WHERE phone = '01012345678'                -- ✅
```

#### 3. LIKE 와일드카드 시작

```sql
WHERE name LIKE 'kim%'                     -- ✅ prefix 검색, 인덱스 가능
WHERE name LIKE '%kim'                     -- ❌ suffix 검색, 풀 스캔
WHERE name LIKE '%kim%'                    -- ❌ 풀 스캔
```

→ suffix 검색이 필요하면 **reverse 컬럼 인덱스** 또는 풀텍스트 인덱스(InnoDB FULLTEXT, Elasticsearch 등)

#### 4. OR 조건

```sql
-- 인덱스: idx_status, idx_user_id
WHERE status = 'active' OR user_id = 1     -- ⚠️ 둘 다 활용 어려움 (index merge로 가능하나 비효율)
```

→ UNION 으로 분리하거나 복합 인덱스 고려.

#### 5. 부정 조건

```sql
WHERE status != 'active'                   -- ❌ 보통 풀 스캔
WHERE status NOT IN (...)                  -- ❌ 보통 풀 스캔
```

→ 가능한 양수 조건으로 재작성. `WHERE status IN ('inactive', 'pending', ...)`

#### 6. NULL 비교

```sql
WHERE col = NULL                           -- ❌ 항상 false (값 안 나옴)
WHERE col IS NULL                          -- ✅ 인덱스 사용 가능 (DB마다 다름)
```

#### 7. 옵티마이저가 풀 스캔이 빠르다고 판단

- 작은 테이블 (수백 행) → 인덱스 보다 풀 스캔이 빠름
- 인덱스 선택도가 낮아 (전체의 30% 이상 매칭) → 옵티마이저가 인덱스 무시

```sql
WHERE active = 1                           -- 90% 행이 active 면 인덱스 안 탐
```

**진단 방법:**

1. **EXPLAIN** 으로 `key`, `type`, `Extra` 확인
   - `type = ALL` → 풀 스캔
   - `type = index` → 인덱스 풀 스캔 (key 사용은 했지만 모두 훑음)
   - `type = range / ref / eq_ref / const` → 정상

2. **EXPLAIN ANALYZE** (MySQL 8+, PG) — 실제 실행 후 실측 정보

3. 통계 갱신: `ANALYZE TABLE users;` — 옵티마이저가 잘못된 통계로 판단 시

**해결 패턴:**

- 함수 적용 컬럼 → **함수 기반 인덱스** (PG, MySQL 8.0.13+)
  ```sql
  CREATE INDEX idx_year ON orders ((YEAR(created_at)));
  ```
- 형변환 → 컬럼 타입과 일치시키기
- LIKE %xxx → 풀텍스트 인덱스 또는 reverse trick
- OR → UNION 또는 IN
- 너무 큰 결과 → 페이지네이션 + 정렬 인덱스

**힌트 (Optimizer Hint):**

```sql
SELECT /*+ INDEX(orders idx_user_id) */ ... FROM orders ...
```

→ 옵티마이저가 잘못 선택할 때 강제. 실무 마지막 카드.

</details>

### 내가 만든 꼬리 질문

<!-- 위 5개를 풀어보고 새로 떠오른 의문을 1개 이상 적어주세요 -->

---

## 핵심 개념

- B-Tree vs B+Tree 구조 차이
- 해시 인덱스 특성과 한계
- 클러스터드 인덱스 vs 논클러스터드 인덱스
- 커버링 인덱스 (Covering Index)
- 실행 계획 (Execution Plan) 읽기

---

## 동작 원리 / 구조

<!-- 다이어그램 또는 의사코드를 여기에 작성 -->
<!-- 예: B+Tree 노드 구조, InnoDB 클러스터드 인덱스 구조 -->

---

## 트레이드오프

- 장점:
- 단점:
- 대안:

---

## 실무/면접 포인트

1. **Q. B-Tree와 B+Tree의 차이는? DB에서 B+Tree를 주로 사용하는 이유는?**
   A.

2. **Q. 복합 인덱스에서 컬럼 순서가 왜 중요한가?**
   A.

3. **Q. 인덱스가 있는데도 풀 스캔이 발생하는 경우는?**
   A.

---

## 딥다이브

- MySQL InnoDB의 클러스터드 인덱스 구조와 PK 선택의 중요성
- `EXPLAIN` / `EXPLAIN ANALYZE` 읽는 법 (type, key, rows, Extra 컬럼)
- 인덱스가 안 타는 케이스 (함수 적용, 암묵적 형변환, LIKE '%prefix')
- 복합 인덱스 컬럼 순서 결정 기준 (선택도, 쿼리 패턴)

---

## 토론 주제

- 인덱스를 추가했는데 오히려 쿼리가 느려진 사례 — 왜 그런 일이 발생하는가?

---

## 내가 새로 알게 된 것

<!-- 자기 언어로 자유롭게 -->

---

## 참고 자료

- "Real MySQL 8.0"
- PostgreSQL 공식 문서 인덱스 섹션
