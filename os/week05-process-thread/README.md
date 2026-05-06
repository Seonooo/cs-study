# Week 5. 프로세스와 스레드

> **발표자**: (미정) | **날짜**: YYYY-MM-DD

---

## 이번 주 목표

- 프로세스와 스레드의 차이를 **자원 공유 관점**에서 설명할 수 있다
- 컨텍스트 스위칭이 발생하는 시점과 비용 구성 요소를 안다
- 멀티프로세스 / 멀티스레드 / 비동기 I/O / 코루틴 중 작업 특성에 맞는 모델을 선택할 수 있다
- 동시성(concurrency)과 병렬성(parallelism)의 차이를 설명할 수 있다
- 본인이 사용하는 언어의 동시성 모델(JVM 스레드, Node.js 이벤트 루프, Go goroutine, Java Virtual Thread 등)을 설명할 수 있다

---

## 학습 체크리스트

- [ ] `ps -eLf` 또는 `top -H` 로 스레드 확인, `cat /proc/<pid>/status` 분석
- [ ] `vmstat 1` 로 컨텍스트 스위치(`cs` 컬럼) 모니터링
- [ ] 본인이 가장 많이 쓰는 언어의 동시성 모델(GIL / Virtual Thread / goroutine / async-await) 1개 분석
- [ ] CPU bound vs I/O bound 작업 각각에 ThreadPool / coroutine 사용해 처리 시간 비교 실험
- [ ] Linux CFS의 `vruntime` 개념 이해 (선택)

---

## 꼬리 질문 (최소 5개)

> 답을 모르겠는 질문이 있으면, **본인이 만든 꼬리 질문 1개 이상**을 정리본 끝에 추가하세요.
> 힌트는 `▶ 힌트 보기`를 눌러야 펼쳐집니다 — 먼저 스스로 답해본 후 확인하세요.

### 1. 프로세스와 스레드의 차이는? 어떤 자원을 공유하고 어떤 자원을 독립적으로 가지나?

> 🎯 **면접 단골 — OS 가장 기본**

<details><summary>▶ 힌트 보기</summary>

**프로세스(Process):**

- OS가 실행 중인 프로그램에 할당하는 **독립된 자원 단위**
- 각 프로세스는 자체 가상 주소 공간 보유 → 다른 프로세스 메모리 접근 불가
- PCB(Process Control Block)에 상태·레지스터·페이지 테이블·열린 파일 디스크립터 등 저장

**스레드(Thread):**

- 프로세스 내부의 **실행 흐름 단위**
- 같은 프로세스 내 스레드끼리 **코드/데이터/힙/파일 디스크립터 공유**
- 각 스레드는 **자체 스택과 레지스터(특히 PC, SP)** 만 독립

**공유/독립 정리:**

| 자원 | 프로세스 간 | 스레드 간 (같은 프로세스) |
|------|:-----------:|:-------------------------:|
| 코드 / 전역 데이터 | 독립 | **공유** |
| 힙 | 독립 | **공유** |
| 파일 디스크립터 | 독립 | **공유** |
| 스택 | 독립 | 독립 |
| 레지스터 | 독립 | 독립 |
| 가상 주소 공간 | 독립 | **공유** |

**실무 함의:**

- 스레드는 메모리 공유 덕에 통신 비용 ↓, 그러나 동기화(락) 필요
- 프로세스는 격리되어 안전하나 IPC(파이프, 소켓 등)이 필요 → 비용 ↑
- 한 스레드에서 segfault 나면 같은 프로세스의 모든 스레드 다운, 프로세스 격리는 안전

</details>

### 2. 컨텍스트 스위칭은 정확히 무엇이며 왜 비용이 발생하나? 프로세스 간 vs 스레드 간 비용 차이는?

> 🎯 **면접 단골 — 레지스터 · TLB · 캐시 관점**

<details><summary>▶ 힌트 보기</summary>

**무엇이 일어나나:**

1. 현재 실행 중인 task의 **레지스터·PC·SP** 등을 PCB(또는 TCB)에 저장
2. 다음 task의 PCB에서 레지스터 상태 복원
3. **메모리 매핑 전환** (프로세스 간일 때만): 페이지 테이블 포인터(CR3) 변경
4. 실행 재개

**비용 구성 요소:**

- **직접 비용**: 레지스터 저장/복원 (수 μs)
- **간접 비용 (더 큼)**:
  - **TLB flush** — 가상→물리 주소 캐시가 비워짐. 이후 페이지 테이블 walk 필요
  - **CPU cache 냉각** — 새 task의 데이터가 들어오며 이전 task 캐시 라인 evict
  - 분기 예측기 / 프리페처 상태도 초기화

**프로세스 간 vs 스레드 간:**

- 스레드 간은 **같은 가상 주소 공간 공유** → CR3 변경 없음 → TLB flush 불필요 (또는 부분만)
- 같은 프로세스 내 스레드는 캐시 친화적 (heap·코드 공유)
- 결과: **스레드 간이 약 10% 빠름**. 단, 작업 특성에 따라 차이 더 클 수 있음 (캐시 워밍업)

**언제 발생하나:**

- 시간 할당량 만료 (preemption)
- I/O 대기로 blocking
- 더 우선순위 높은 task 등장
- 명시적 yield / sleep / mutex 대기

**모니터링:**

- `vmstat 1` 의 `cs` 컬럼 — 초당 컨텍스트 스위치 횟수
- 정상 서버: 수천~수만/초. 수십만 이상이면 thrashing 의심

</details>

### 3. 멀티프로세스 vs 멀티스레드 vs 비동기 I/O — 백엔드 서버에서 언제 무엇을 쓰나?

> 🎯 **백엔드 실무 핵심 — 언어/프레임워크 선택의 본질**

<details><summary>▶ 힌트 보기</summary>

**멀티프로세스:**

- 강한 격리 (한 프로세스 죽어도 다른 프로세스 살아있음)
- 메모리 공유 X → IPC 비용
- 적합: Python(GIL 우회), nginx worker, PostgreSQL 백엔드, 분리된 작업 단위

**멀티스레드:**

- 메모리 공유로 통신 효율
- 락·데드락 등 동기화 부담
- 적합: JVM 기반 백엔드(Spring), C++ 서버, CPU 중심 병렬 작업

**비동기 I/O (이벤트 루프):**

- 단일 스레드(또는 소수)로 수만 connection 처리
- I/O 대기 중 다른 작업 처리 (non-blocking)
- 적합: Node.js, Python asyncio, Netty, **I/O 비중이 큰 서버**
- 단점: CPU 무거운 작업이 들어오면 이벤트 루프 차단

**언어별 실제 모델:**

| 언어 | 기본 모델 | 비고 |
|------|-----------|------|
| Python | GIL로 인해 멀티스레드 효과 제한 | CPU 작업은 multiprocessing, I/O는 asyncio |
| Java | 멀티스레드 (platform thread) | 21+부터 Virtual Thread |
| Go | M:N (goroutine) | 가장 유연 |
| Node.js | 단일 스레드 이벤트 루프 + libuv 워커풀 | CPU 작업은 worker_threads 또는 cluster |
| Kotlin | JVM 스레드 + 코루틴 | suspend 기반 |

**선택 기준:**

- I/O 대기가 99% → 비동기 I/O 또는 코루틴
- CPU 계산이 많음 → 멀티프로세스 (CPU 코어 수만큼)
- 둘이 섞임 → 멀티스레드 + 워커 풀, 또는 Go의 M:N

**핵심 통찰:** "한 가지 모델이 다 잘하는 건 없다." 워크로드 분석이 먼저.

</details>

### 4. 그린 스레드 · 코루틴 · 가상 스레드는 OS 스레드보다 왜 효율적인가? Go goroutine과 Java Virtual Thread는 어떻게 수만 개를 돌리나?

> 🎯 **2026 트렌드 — Project Loom, Kotlin coroutine, Go runtime**

<details><summary>▶ 힌트 보기</summary>

**OS 스레드의 한계:**

- 스레드당 기본 스택 1MB → 1만 스레드 = 10GB 메모리 (현실 불가)
- 컨텍스트 스위칭이 커널 모드 진입 필요 → μs 단위 비용
- 스케줄링이 OS 권한이라 애플리케이션이 제어 불가

**그린/가상 스레드의 트릭:**

- **유저 스페이스 스케줄링** — 런타임이 직접 스케줄, 시스템 콜 없음
- **작은 stack** — 시작 시 작게, 필요 시 동적 증가 (Goroutine은 2KB 시작)
- **M:N 매핑** — M개의 가상 스레드를 N개(보통 CPU 코어 수)의 OS 스레드에 다중화
- **suspend/yield 지점에서만 전환** — 작업이 stuck되지 않도록 컴파일러가 yield 지점 삽입

**Go Goroutine:**

- runtime이 자체 스케줄러 보유 (G-M-P 모델: Goroutine, Machine=OS thread, Processor)
- I/O 호출 시 자동 yield → 다른 goroutine 실행
- 1ms 단위 preemption (1.14+)
- 수십만 goroutine 일상적

**Java Virtual Thread (Project Loom, JDK 21+):**

- 기존 platform thread 와 동일한 API (`Thread.startVirtualThread()` 등)
- JVM이 OS 스레드 1개에 수많은 가상 스레드를 multiplex
- blocking I/O 호출 시 자동으로 underlying carrier thread를 다른 가상 스레드에게 양보
- **Spring Boot 3.2+** 부터 `spring.threads.virtual.enabled=true` 한 줄로 활성화
- 기존 코드 수정 없이 throughput ↑ — 적용 사례 다수

**Kotlin coroutine:**

- 컴파일러가 suspend 함수를 state machine으로 변환
- yield 지점에서 continuation 저장
- JVM 스레드 풀 위에서 동작 (또는 단일 스레드 dispatcher)

**한계:**

- 가상 스레드도 **synchronized 블록 안에서 blocking 시 carrier thread를 잡고 있음** (pinning) → ReentrantLock 권장
- CPU 무거운 작업에는 여전히 OS 스레드가 답

</details>

### 5. 동시성과 병렬성의 차이는? CPU bound와 I/O bound 작업에는 각각 어떤 모델이 유리한가?

> 🎯 **면접 단골 + 실무 핵심 판단**

<details><summary>▶ 힌트 보기</summary>

**개념 구분:**

- **동시성(Concurrency)** — **여러 작업을 다루는 능력**. 시간상 겹쳐 보이지만 같은 순간엔 1개만 실행될 수 있음. 단일 코어에서도 가능
- **병렬성(Parallelism)** — **여러 작업을 동시에 실행하는 것**. 멀티코어 CPU 필요. 동시성의 부분집합

**Rob Pike의 정의:**

> "Concurrency is about *dealing with* lots of things at once. Parallelism is about *doing* lots of things at once."

**예시:**

- 단일 코어에서 OS가 100개 task를 빠르게 번갈아 실행 → **동시성 O, 병렬성 X**
- 4코어에서 4개 task가 진짜 동시 실행 → **둘 다 O**

**CPU bound 작업:**

- 특징: 계산이 주, I/O 적음 (이미지 처리, 암호화, ML 추론)
- 적합한 모델: **멀티프로세스 또는 멀티스레드 with 코어 수만큼 워커**
- 코루틴/이벤트 루프는 부적합 — 한 task가 CPU를 점유하면 다른 task starve
- Python은 multiprocessing 필수 (GIL)

**I/O bound 작업:**

- 특징: DB·HTTP·파일 I/O 대기가 대부분 (일반 백엔드 API)
- 적합한 모델: **비동기 I/O / 코루틴 / 가상 스레드**
- 한 작업이 I/O 대기 중일 때 다른 작업 처리 → 동시성 극대화
- 멀티스레드도 가능하지만 스레드 수에 한계

**판단 기준:**

```
CPU 사용률이 항상 100% 가까이 → CPU bound
스레드 / connection 대비 throughput이 안 늘어남 → I/O bound + 동시성 부족
```

**실무 패턴:** 일반 API 서버는 대부분 I/O bound → 비동기/코루틴/가상 스레드. 머신러닝 추론은 CPU bound → 별도 워커 프로세스로 분리.

</details>

### 내가 만든 꼬리 질문

<!-- 위 5개를 풀어보고 새로 떠오른 의문을 1개 이상 적어주세요 -->

---

## 핵심 개념

- 프로세스 vs 스레드 (독립 주소 공간 vs 공유 메모리)
- PCB (Process Control Block) 구성 요소
- 컨텍스트 스위칭 과정
- 스케줄링 알고리즘: FCFS, SJF, Round Robin, MLFQ

---

## 동작 원리 / 구조

<!-- 다이어그램 또는 의사코드를 여기에 작성 -->
<!-- 예: 프로세스 상태 다이어그램 (New → Ready → Running → Waiting → Terminated) -->

---

## 트레이드오프

- 장점:
- 단점:
- 대안:

---

## 실무/면접 포인트

1. **Q. 프로세스와 스레드의 차이점은? 어떤 자원을 공유하는가?**
   A.

2. **Q. 컨텍스트 스위칭 비용이 발생하는 이유는?**
   A.

3. **Q. MLFQ 스케줄러가 SJF보다 실용적인 이유는?**
   A.

---

## 딥다이브

- 컨텍스트 스위칭 비용 (레지스터 저장/복원, TLB flush, 캐시 냉각)
- 리눅스 CFS (Completely Fair Scheduler) 동작 원리
- 그린 스레드 / 코루틴 — Go goroutine, Kotlin coroutine과 OS 스레드의 차이

---

## 토론 주제

- 멀티프로세스 vs 멀티스레드 vs 비동기 I/O — 언제 무엇을 선택할 것인가?

---

## 내가 새로 알게 된 것

<!-- 자기 언어로 자유롭게 -->

---

## 참고 자료

- OSTEP Ch.4-9 (무료 PDF)
- "운영체제와 정보기술의 원리" (반효경)
