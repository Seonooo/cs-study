# Week 6. 동기화와 데드락

> **발표자**: (미정) | **날짜**: YYYY-MM-DD

---

## 이번 주 목표

- 데드락 4 조건을 외우고 각 조건을 깨는 방법으로 데드락을 방지할 수 있다
- Mutex / Semaphore / Monitor의 차이와 사용 시점을 설명할 수 있다
- Java `synchronized` 와 `ReentrantLock` 중 상황에 맞게 선택할 수 있다
- CAS의 동작 원리와 ABA 문제를 이해한다
- Immutable / Actor / MVCC 같은 **락 없는 동시성 패러다임**을 안다

---

## 학습 체크리스트

- [ ] 식사하는 철학자 문제를 코드로 직접 구현 (데드락 시연 + 해결)
- [ ] Java `AtomicInteger.incrementAndGet` 의 동작을 CAS 관점에서 이해
- [ ] 본인이 사용하는 프레임워크에서 락 사용 패턴 1개 분석 (Spring `@Transactional`, Redis 분산 락 등)
- [ ] PostgreSQL의 MVCC 동작을 트랜잭션 동시 실행으로 확인
- [ ] `jstack` 또는 `kill -3 <pid>` 로 JVM thread dump · 데드락 진단

---

## 꼬리 질문 (최소 5개)

> 답을 모르겠는 질문이 있으면, **본인이 만든 꼬리 질문 1개 이상**을 정리본 끝에 추가하세요.
> 힌트는 `▶ 힌트 보기`를 눌러야 펼쳐집니다 — 먼저 스스로 답해본 후 확인하세요.

### 1. 데드락의 4가지 조건은 무엇이며, 각각을 깨면 어떻게 데드락을 방지할 수 있나?

> 🎯 **면접 단골 — OS 가장 기본**

<details><summary>▶ 힌트 보기</summary>

**4가지 조건 (Coffman 조건):**

1. **Mutual Exclusion (상호 배제)** — 자원을 한 번에 하나의 프로세스만 사용
2. **Hold and Wait (점유 대기)** — 자원을 가진 채로 다른 자원을 대기
3. **No Preemption (비선점)** — 자원을 강제로 빼앗을 수 없음
4. **Circular Wait (순환 대기)** — 프로세스들이 원형으로 서로의 자원을 기다림

**4가지가 모두 성립해야** 데드락 발생. 하나라도 깨면 방지 가능.

**각 조건을 깨는 방법:**

| 조건 | 깨는 방법 | 한계 |
|------|-----------|------|
| Mutual Exclusion | 자원을 공유 가능하게 (read-only, immutable) | 본질적으로 공유 불가능한 자원 존재 |
| Hold and Wait | 시작 시 모든 자원을 한 번에 요청 | 자원 활용도↓, 기아 가능 |
| No Preemption | OS가 강제로 회수 | 대부분 자원에 적용 어려움 |
| Circular Wait | **자원에 전역 순서를 정해 항상 같은 순서로 획득** | **가장 실용적** |

**실무 적용 — Lock Ordering:**

```
모든 코드에서 락을 항상 (A → B → C) 순서로만 획득
한 곳이라도 (B → A) 순서로 획득하면 데드락 위험
```

**탐지·복구:**

- Banker's Algorithm — 회피 (이론적, 거의 안 씀)
- Wait-for graph — 탐지
- 실무: 타임아웃 기반 회수 (`tryLock(timeout)`), 로깅 후 재시도

</details>

### 2. Mutex / Semaphore / Monitor는 어떻게 다른가? 언제 무엇을 쓰나?

> 🎯 **면접 단골 — 자주 헷갈리는 개념**

<details><summary>▶ 힌트 보기</summary>

**Mutex (Mutual Exclusion):**

- **단일 소유자** 락. lock한 스레드만 unlock 가능
- 임계 구역 보호 (한 스레드만 진입)
- 보통 재진입 가능(reentrant) 또는 불가능 옵션

**Semaphore:**

- **카운터** 기반 신호. N개의 자원을 N개 스레드에 허용
- `acquire()` → counter--, 0이면 대기
- `release()` → counter++
- 소유자 개념 없음 — 다른 스레드가 release 가능
- **Binary Semaphore**(N=1)는 mutex와 비슷하나 소유 개념 없음
- **Java의 Semaphore는 비재진입** — 같은 스레드가 두 번 acquire하면 자기 자신과 데드락

**Monitor:**

- **객체 단위**의 자동 동기화 메커니즘
- 객체에 진입한 스레드는 자동으로 락 획득, 빠질 때 해제
- 조건 변수(`wait`/`notify`)와 결합된 고수준 추상화
- Java의 모든 객체는 모니터를 가짐 → `synchronized` 가 이걸 사용

**언제 무엇을:**

| 상황 | 선택 |
|------|------|
| 단순 임계 구역 | Mutex / `synchronized` |
| N개의 동일 자원 풀 (DB connection pool 등) | Semaphore |
| 객체 단위 자동 락 + 조건 대기 | Monitor / `synchronized` + `wait`/`notify` |
| 신호 전달 (이벤트 알림) | Semaphore |

**실무 패턴:**

- Connection pool — Semaphore로 최대 연결 수 제한
- Producer-Consumer — `BlockingQueue` (내부적으로 모니터 사용)
- 단순 카운터 보호 — Mutex 또는 atomic

</details>

### 3. Java의 `synchronized` 와 `ReentrantLock` 의 차이는? ReentrantLock이 제공하는 추가 기능은?

> 🎯 **백엔드 실무 — JVM 환경**

<details><summary>▶ 힌트 보기</summary>

**`synchronized`:**

- 키워드. 메서드/블록에 부착
- JVM이 모니터 락을 자동 획득·해제 (예외 발생해도 안전하게 해제)
- 단순, 가독성 좋음
- 한계: tryLock 불가, 인터럽트 불가, 공정성 옵션 없음, 단일 조건 변수

**`ReentrantLock` (java.util.concurrent.locks):**

- 클래스. 명시적으로 `lock()` / `unlock()` 호출 (반드시 `try-finally` 로 해제)
- 추가 기능:
  - **`tryLock()`** — 락 획득 시도, 실패 시 즉시 false. 데드락 회피에 유용
  - **`tryLock(timeout)`** — 일정 시간만 대기
  - **`lockInterruptibly()`** — 대기 중 인터럽트 가능
  - **공정성 옵션** — `new ReentrantLock(true)` 면 FIFO 순서로 락 획득 (기아 방지)
  - **다중 Condition** — `lock.newCondition()` 으로 여러 조건 변수 생성 (`synchronized` 는 객체당 1개)

**비교 예시:**

```java
// synchronized — 간단하지만 영원히 대기 가능
synchronized (resource) {
    // 임계 구역
}

// ReentrantLock — 데드락 회피 패턴
if (lock.tryLock(1, TimeUnit.SECONDS)) {
    try { /* 임계 구역 */ }
    finally { lock.unlock(); }
} else {
    // 락 획득 실패 처리
}
```

**선택 기준:**

- 단순 임계 구역 + 짧은 코드 → `synchronized` (가독성 우수)
- 타임아웃·tryLock·인터럽트가 필요 → `ReentrantLock`
- 공정성 보장 → `ReentrantLock(true)`
- 여러 조건 변수 → `ReentrantLock` + 여러 Condition

**JDK 진화:**

- JDK 6+ : `synchronized` 가 biased locking · lightweight lock 등으로 최적화 → 성능 차이 거의 없음
- JDK 21+ Virtual Thread: `synchronized` 안에서 blocking 시 carrier thread를 잡고 있는 **pinning** 발생 → 가상 스레드 환경에서는 **`ReentrantLock` 권장**

</details>

### 4. CAS(Compare-And-Swap)는 어떻게 동작하며 lock-free 자료구조를 어떻게 만드나? ABA 문제는 무엇이고 어떻게 해결하나?

> 🎯 **깊이 있는 질문 — Atomic 클래스 / non-blocking 큐의 기반**

<details><summary>▶ 힌트 보기</summary>

**CAS 동작:**

CPU가 제공하는 atomic 명령어. 의사 코드:

```
CAS(addr, expected, new):
    if (*addr == expected):
        *addr = new
        return true
    else:
        return false
```

- 메모리의 값이 `expected` 와 같으면 `new` 로 바꾸고 성공
- 다르면 실패. 다른 스레드가 이미 바꿨다는 뜻
- 모두 **하나의 원자적 명령** (인터럽트 불가)

**Lock-free 패턴:**

```
do {
    old = read(value)
    new = compute(old)
} while (!CAS(value, old, new))
```

- 락 없이 무한 재시도. 충돌 시에도 다른 스레드는 진행 가능 → **lock-free**
- Java `AtomicInteger`, `AtomicReference`, `ConcurrentLinkedQueue` 등이 내부적으로 사용

**ABA 문제:**

- 스레드 1: A를 읽음
- 스레드 2: A → B → A 로 변경
- 스레드 1: CAS(A, ...) — 값은 A이지만 실제로는 변경되었음! 잘못된 성공

**ABA 해결책:**

1. **Version 번호 동반** — `(value, version)` 페어. CAS 시 둘 다 비교. Java `AtomicStampedReference`
2. **Hazard pointers** — 메모리 재사용 방지
3. **Garbage collection** — JVM은 GC 덕에 ABA가 적게 발생 (재사용된 객체가 같은 주소 가지기 어려움)

**실무 함의:**

- 락보다 빠르지만 **경합이 심하면 CAS 재시도가 폭증** → 오히려 느려짐
- 적합: 짧은 임계 구역, 단순 업데이트 (counter 등)
- 부적합: 복잡한 트랜잭션, 긴 임계 구역

**Java AtomicInteger 예시:**

```java
AtomicInteger counter = new AtomicInteger(0);
counter.incrementAndGet();  // 내부적으로 CAS 루프
```

</details>

### 5. 락 없이 동시성을 다루는 방법은? Immutable / Actor model / MVCC 각각의 적용 사례는?

> 🎯 **패러다임 — Erlang/Akka, 함수형, DB**

<details><summary>▶ 힌트 보기</summary>

**Immutable (불변 객체):**

- 객체가 한 번 생성되면 변경 불가 → 동기화 필요 없음 (thread-safe by design)
- "공유하지만 수정하지 않는다"
- 적용:
  - Java `String`, `Integer`, `LocalDateTime`
  - 함수형 언어(Scala, Kotlin data class with `val`)
  - 상태 변경은 새 객체 생성 (`copy()`)
- 단점: 메모리 사용↑, 객체 생성 비용

**Actor Model:**

- 각 actor가 **자신의 상태를 독점** + **메시지 큐** 보유
- 외부에서 actor 상태 직접 접근 불가, 메시지로만 통신
- "공유하지 않고 메시지만 주고받는다"
- actor 내부는 한 번에 메시지 1개만 처리 → 동기화 불필요
- 적용:
  - **Erlang / Elixir** (BEAM VM 기반, 통신 시스템)
  - **Akka** (JVM, Scala/Java)
  - **Microsoft Orleans** (.NET)
  - 분산 시스템에 자연스럽게 확장
- 단점: 복잡한 상태 공유 표현이 어려움, 디버깅 까다로움

**MVCC (Multi-Version Concurrency Control):**

- 데이터의 **여러 버전**을 유지. 읽기는 락 없이 특정 시점의 스냅샷 조회
- 쓰기는 새 버전 생성, 이전 버전은 다른 트랜잭션이 보고 있을 수 있어 유지
- "읽기와 쓰기가 서로 막지 않는다"
- 적용:
  - **PostgreSQL, Oracle, MySQL InnoDB, SQL Server, CockroachDB** — 거의 모든 현대 RDBMS
  - 함수형 자료구조 (persistent data structure) 도 같은 원리
- 단점: 오래된 버전 정리(VACUUM) 필요, 디스크 사용↑

**비교 정리:**

| 패러다임 | 핵심 아이디어 | 대표 예시 |
|---------|-------------|---------|
| Immutable | 변경 불가 → 동기화 불필요 | Java String, 함수형 |
| Actor | 상태 격리 + 메시지 통신 | Erlang, Akka |
| MVCC | 다중 버전으로 read-write 분리 | PostgreSQL |

**실무 통찰:**

- "어떻게 락을 안 쓸 수 있을까"가 현대 동시성의 큰 화두 — 락은 디버깅·확장성에서 부담
- 마이크로서비스가 자연스럽게 actor model 비슷하게 동작 (서비스마다 자기 DB 보유)
- Week 11 트랜잭션 격리 수준에서 MVCC 더 깊이 다룸

</details>

### 내가 만든 꼬리 질문

<!-- 위 5개를 풀어보고 새로 떠오른 의문을 1개 이상 적어주세요 -->

---

## 핵심 개념

- 임계 구역 (Critical Section)과 상호 배제 조건
- 뮤텍스, 세마포어, 모니터 비교
- 데드락 4가지 조건 (상호 배제, 점유 대기, 비선점, 순환 대기)
- 기아 (Starvation)와 라이브락 (Livelock)

---

## 동작 원리 / 구조

<!-- 다이어그램 또는 의사코드를 여기에 작성 -->
<!-- 예: 식사하는 철학자 문제 다이어그램, 자원 할당 그래프 -->

---

## 트레이드오프

- 장점:
- 단점:
- 대안:

---

## 실무/면접 포인트

1. **Q. 데드락 발생 조건 4가지와 각각의 해결책은?**
   A.

2. **Q. 뮤텍스와 세마포어의 차이는?**
   A.

3. **Q. Java에서 `synchronized`와 `ReentrantLock`의 차이는?**
   A.

---

## 딥다이브

- Java `synchronized` vs `ReentrantLock` (공정성, tryLock, 인터럽트 가능)
- CAS (Compare-And-Swap) 기반 lock-free 자료구조
- 식사하는 철학자 문제 — 다양한 해결 전략

---

## 토론 주제

- 락 없이 동시성을 다루는 방법들: immutable 객체, Actor 모델, MVCC — 각각의 적용 시나리오는?

---

## 내가 새로 알게 된 것

<!-- 자기 언어로 자유롭게 -->

---

## 참고 자료

- OSTEP Ch.26-32
- "Java Concurrency in Practice"
