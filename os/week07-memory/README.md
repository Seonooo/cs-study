# Week 7. 메모리 관리

> **발표자**: (미정) | **날짜**: YYYY-MM-DD

---

## 이번 주 목표

- 가상 메모리의 목적과 페이징 동작을 설명할 수 있다
- TLB miss와 Page Fault의 차이, 메모리 접근 비용 계층 (cache → TLB → RAM → disk)을 안다
- 캐시 친화적 코드와 그렇지 않은 코드의 성능 차이를 설명할 수 있다
- `mmap` 의 동작 원리와 실무 적용 사례를 이해한다
- GC 언어와 수동 메모리 관리 언어의 트레이드오프를 비교할 수 있다

---

## 학습 체크리스트

- [ ] `cat /proc/<pid>/maps` 로 프로세스의 가상 주소 공간 분석
- [ ] `ps -o rss,vsz <pid>` 로 RSS vs VSZ 차이 이해
- [ ] 행렬 곱 두 가지(row-major vs column-major) 구현 후 실행 시간 비교
- [ ] `mmap` 과 `read` 를 사용한 파일 처리 코드 비교 (Python `mmap` 모듈 등)
- [ ] 본인이 사용하는 GC 알고리즘(G1 / ZGC / Go runtime 등) 동작 원리 1개 분석

---

## 꼬리 질문 (최소 5개)

> 답을 모르겠는 질문이 있으면, **본인이 만든 꼬리 질문 1개 이상**을 정리본 끝에 추가하세요.
> 힌트는 `▶ 힌트 보기`를 눌러야 펼쳐집니다 — 먼저 스스로 답해본 후 확인하세요.

### 1. 가상 메모리는 무엇이고 왜 필요한가? 페이징은 어떻게 동작하며 세그멘테이션과 어떻게 다른가?

> 🎯 **OS 기본 — 모든 면접 출발점**

<details><summary>▶ 힌트 보기</summary>

**가상 메모리가 필요한 이유:**

- **격리** — 각 프로세스가 자신만의 주소 공간을 가짐. 다른 프로세스 메모리 접근 불가
- **물리 메모리 추상화** — 물리 RAM보다 큰 주소 공간 제공 가능 (스왑 영역 활용)
- **fragmentation 해결** — 물리적으로 흩어진 페이지를 가상으로는 연속처럼 보이게
- **공유** — 같은 라이브러리 코드를 여러 프로세스가 한 물리 페이지로 공유 (예: libc)
- **보안** — 페이지마다 read/write/execute 권한 부여

**페이징(Paging) 동작:**

1. 가상 주소 공간을 고정 크기 **page** 로 나눔 (보통 4KB)
2. 물리 메모리도 같은 크기 **frame** 으로 나눔
3. **Page Table** 이 가상 페이지 → 물리 프레임 매핑 저장
4. CPU의 MMU(Memory Management Unit)가 매 접근마다 자동 변환

**가상 주소 변환:**

```
[가상 주소] → MMU
              → TLB 확인 (hit이면 즉시 변환)
              → miss면 페이지 테이블 walk (64bit 시스템에서 4단계)
              → 물리 주소
```

**페이징 vs 세그멘테이션:**

| 항목 | 페이징 | 세그멘테이션 |
|------|--------|-------------|
| 크기 | 고정 (4KB) | 가변 (논리적 단위 — 코드, 데이터, 스택 등) |
| 외부 fragmentation | 없음 | 있음 |
| 내부 fragmentation | 있음 (마지막 페이지) | 없음 |
| 보호 단위 | 페이지 | 세그먼트 (의미 단위) |
| 현대 OS | 주류 | 거의 사라짐 (x86은 형식적으로 남음) |

**현대 시스템:** 대부분 **페이징 위주**. 세그멘테이션은 x86 호환을 위해 형식적으로 존재하나 OS는 flat segment로 무력화.

</details>

### 2. TLB miss와 Page Fault는 무엇이며 어떤 비용 계층이 있나? cache miss · TLB miss · page fault 중 무엇이 가장 비싼가?

> 🎯 **면접 깊이 + 실무 latency 분석**

<details><summary>▶ 힌트 보기</summary>

**메모리 접근 비용 계층:**

| 단계 | 비용 (대략) | 처리 |
|------|-----------|------|
| L1 cache hit | ~1 cycle (~0.5ns) | CPU 내부 |
| L2 cache hit | ~5 cycles | CPU 내부 |
| L3 cache hit | ~30 cycles | CPU 내부 (공유) |
| **TLB hit** | ~1 cycle (병렬) | MMU |
| **L1 cache miss → RAM** | ~100 cycles (~100ns) | 메모리 컨트롤러 |
| **TLB miss → page table walk** | ~수십~수백 cycles | MMU + 메모리 |
| **Minor page fault** | μs 단위 | OS 처리, 디스크 X |
| **Major page fault** | ms 단위 | OS + 디스크 I/O |

**가장 비싼 순서:** Major page fault (ms) >> Minor page fault (μs) >> TLB miss (~100ns) > Cache miss (~100ns) > Cache hit (~1ns)

**TLB miss:**

- 가상 주소를 TLB에서 못 찾음 → 페이지 테이블 walk
- x86_64는 4단계 페이지 테이블 → 최악 4번의 메모리 접근
- 해결: 페이지 크기 키우기 (Huge Pages 2MB / 1GB) → TLB 한 entry가 커버하는 영역↑

**Page Fault:**

- 페이지가 물리 메모리에 없음 → OS 인터럽트
- **Minor** — 페이지가 RAM에 있긴 한데 (다른 프로세스 또는 디스크 캐시) 매핑이 없음. 매핑만 추가
- **Major** — 페이지가 진짜 디스크에 있음. 디스크 I/O 후 매핑

**실무 함의:**

- API latency가 종종 100ms 단위로 튀는 원인 → major fault 가능성 (스왑 활성화 시 특히)
- DB 서버는 보통 swap 비활성화 (`vm.swappiness=0` 또는 swap off)
- 컨테이너 환경에서는 cgroup 메모리 제한 초과 시 OOM 또는 fault 폭증

**모니터링:**

- `vmstat 1` 의 `si` / `so` 컬럼 — 스왑 in/out
- `pidstat -r` — 프로세스별 minor/major fault 수
- `perf stat -e dTLB-load-misses` — TLB miss 측정

</details>

### 3. 캐시 친화적 코드는 어떻게 작성하는가? 같은 알고리즘이라도 메모리 접근 패턴에 따라 성능이 어떻게 달라지나?

> 🎯 **백엔드 실무 — 성능 최적화의 본질**

<details><summary>▶ 힌트 보기</summary>

**핵심 원칙:**

- **시간 지역성(Temporal locality)** — 한 번 접근한 데이터는 곧 또 접근됨 → 캐시에 보관
- **공간 지역성(Spatial locality)** — 인접한 메모리도 곧 접근됨 → 캐시는 한 라인(보통 64바이트)을 통째로 읽음

**대표 사례 — 행렬 순회:**

```c
// row-major (C 언어 기본)
for (i = 0; i < N; i++)
    for (j = 0; j < N; j++)
        sum += a[i][j];   // 캐시 친화적 — 인접 메모리 순차 접근

// column-major
for (j = 0; j < N; j++)
    for (i = 0; i < N; i++)
        sum += a[i][j];   // 캐시 비친화 — 매번 다른 행, 캐시 라인 낭비
```

같은 알고리즘이지만 **N=2000 기준 5–10배 차이**가 흔함.

**친화적 코드 작성 팁:**

1. **데이터 구조 선택**
   - Array > Linked list (포인터 따라가기 = cache miss 폭증)
   - Struct of Arrays > Array of Structs (필드별로 접근하는 워크로드에서)

2. **메모리 정렬(Alignment)**
   - 캐시 라인(64바이트) 경계에 맞춰 데이터 배치
   - false sharing 방지: 다른 스레드가 쓰는 변수들을 같은 캐시 라인에 두지 않기

3. **순회 순서**
   - 다차원 배열은 메모리 레이아웃에 맞춰 순회

4. **데이터 크기**
   - hot path 데이터를 작게 유지 → 더 많은 데이터가 캐시에 들어감
   - 큰 객체는 자주 접근되는 필드와 그렇지 않은 필드 분리

**언어별 함의:**

- C/C++/Rust — 직접 제어 가능
- Java — 객체가 힙에 흩어짐 + 헤더 12–16바이트 → 캐시 효율 낮음. **Project Valhalla(value type)** 가 이 문제 해결 중
- Go — struct는 연속 배치되어 친화적

**측정:**

- `perf stat -e cache-misses,cache-references ./program`
- cache-miss rate 5% 이하가 일반적 목표

**실무 통찰:** "알고리즘 복잡도가 같아도 캐시 효율로 10배 차이" — DB 인덱스(B+Tree가 hash index 대비 캐시 친화적), 게임 엔진(ECS 패턴) 등이 모두 이 원리 활용.

</details>

### 4. mmap은 어떻게 동작하며 일반 read/write 대비 어떤 이점이 있나? 어떤 경우 mmap이 부적합한가?

> 🎯 **백엔드 실무 — DB 엔진 / 대용량 파일 처리**

<details><summary>▶ 힌트 보기</summary>

**mmap이란:**

- 파일을 **프로세스의 가상 주소 공간에 매핑**
- 파일 내용에 일반 메모리처럼 접근 가능 (`ptr[i] = ...`)
- 호출 시점에 디스크를 읽지 않음 — 접근 시점에 page fault → demand paging으로 로드

**일반 read/write 대비 이점:**

| 항목 | read/write | mmap |
|------|-----------|------|
| 시스템 콜 횟수 | 매 I/O마다 호출 | 매핑 시 1번 |
| 사용자/커널 간 복사 | 항상 발생 | 페이지 캐시 직접 매핑 → **0 copy** |
| 큰 파일 처리 | 버퍼 단위 반복 | 단일 포인터 |
| 랜덤 액세스 | 매번 lseek | 그냥 인덱싱 |

**적합한 경우:**

- **대용량 파일의 랜덤 액세스** (DB 엔진, 검색 인덱스)
- **여러 프로세스가 같은 파일 공유** (페이지 캐시 공유)
- **read-heavy 워크로드**
- 사례: SQLite, LMDB, 일부 LevelDB 변형, Elasticsearch / Lucene 인덱스 일부

**부적합한 경우:**

- **순차 스트리밍** — 한 번 읽고 버리는 패턴은 read 가 단순·효율적
- **작은 파일** — 매핑 오버헤드가 더 큼
- **네트워크 파일 시스템(NFS) 위 파일** — 일관성 보장 어려움
- **쓰기 빈도 매우 높은 파일** — 매번 dirty page 추적 비용
- **MongoDB의 결정** — 초기엔 mmap 기반 엔진 사용했으나 fragmentation·동시성 문제로 WiredTiger 로 교체 (mmapv1은 deprecate)

**Go의 mmap 사례:**

- 25× 속도 향상 보고 (Varnish, 일부 캐시 시스템)
- 단, 디스크 I/O가 page fault로 위장되어 latency spike 분석이 어려움

**주의:**

- 매핑된 파일을 다른 프로세스가 truncate 하면 SIGBUS
- mmap 영역 크기는 프로세스 가상 주소 공간 한계 (64bit는 사실상 무한)
- **major page fault**가 빈번하면 오히려 read보다 느림

**실무 결정 기준:** "랜덤 액세스 + 큰 파일 + 메모리 캐시 활용 가능" 이면 mmap, "순차 스트리밍" 이면 read/write.

</details>

### 5. GC 언어와 수동 메모리 관리 언어의 트레이드오프는? Java GC는 어떻게 진화해왔나?

> 🎯 **백엔드 핵심 + 2026 트렌드**

<details><summary>▶ 힌트 보기</summary>

**GC 언어 (Java, Go, Python, JS):**

- 장점:
  - 메모리 안전성 (use-after-free, double-free 거의 불가능)
  - 개발 생산성 (수명 관리 신경 X)
  - 메모리 누수 가능성↓ (참조 끊으면 GC가 회수)
- 단점:
  - **GC pause** — STW(Stop-The-World) 동안 latency spike
  - 메모리 사용량↑ (헤더, GC 메타데이터)
  - 예측 어려움 (GC 시점)

**수동 메모리 관리 (C, C++):**

- 장점: 완전한 제어, 예측 가능한 latency, 최소 메모리
- 단점: 메모리 누수, 댕글링 포인터, 보안 취약점(buffer overflow 등)

**Rust (제3의 길):**

- 컴파일 타임 ownership 검사 → GC 없이도 메모리 안전
- 단점: 학습 곡선, 컴파일 시간

**Java GC 진화:**

| GC | 등장 | 특징 | Pause |
|----|------|------|-------|
| Serial | 초기 | 단일 스레드 | 큰 힙에서 초 단위 |
| Parallel | 1.5 | 멀티 스레드 (throughput 우선) | 수백 ms |
| CMS | 1.5 | concurrent mark + sweep | 수십 ms (deprecated, JDK 14에서 제거) |
| **G1** | 1.7 (기본 9+) | 힙을 region으로 나눠 점진적 회수 | 수십 ms |
| **ZGC** | 11 (production 15+) | colored pointers + load barrier | **<1ms** |
| **Shenandoah** | 12+ | concurrent compaction | **<1ms** |

**ZGC의 비밀:**

- 대부분의 작업을 **애플리케이션과 동시(concurrent)** 진행
- pause는 단지 GC root scan만 — 힙 크기와 무관하게 ms 이하
- 16TB 힙도 sub-ms pause 가능
- 기본 옵션: `-XX:+UseZGC`

**Go GC:**

- concurrent tri-color mark-and-sweep
- pause time 1ms 이하 목표
- 단점: 메모리 사용량이 다소 큼 (RSS가 heap의 2배 정도)

**실무 함의:**

- 일반 백엔드 API: G1 또는 ZGC 권장 (JDK 21+ ZGC가 안정화)
- latency 민감(거래·게임): ZGC, Shenandoah, 또는 Rust/C++
- batch 작업: Parallel GC (throughput 우선)
- 메모리 제약 환경: G1, Serial

**모니터링:**

- `-Xlog:gc*` 로 GC 로그 활성화
- JFR (Java Flight Recorder) 로 GC pause 분석
- p99 latency가 GC 시간과 일치하면 GC 튜닝 필요

</details>

### 내가 만든 꼬리 질문

<!-- 위 5개를 풀어보고 새로 떠오른 의문을 1개 이상 적어주세요 -->

---

## 핵심 개념

- 가상 메모리 개념과 목적
- 페이징 (Paging) vs 세그멘테이션 (Segmentation)
- TLB (Translation Lookaside Buffer) 역할
- 페이지 교체 알고리즘: LRU, Clock (Second Chance)
- 메모리 계층 구조 (레지스터 → 캐시 → 메인 메모리 → 디스크)

---

## 동작 원리 / 구조

<!-- 다이어그램 또는 의사코드를 여기에 작성 -->
<!-- 예: 가상 주소 → 물리 주소 변환 과정 (페이지 테이블 + TLB) -->

---

## 트레이드오프

- 장점:
- 단점:
- 대안:

---

## 실무/면접 포인트

1. **Q. 페이지 폴트가 발생하면 OS는 어떤 일을 하는가?**
   A.

2. **Q. TLB란 무엇이며 왜 필요한가?**
   A.

3. **Q. LRU 페이지 교체 알고리즘을 실제로 구현하기 어려운 이유는?**
   A.

---

## 딥다이브

- 페이지 폴트 발생 시 OS 처리 흐름 (minor fault vs major fault)
- 캐시 친화적 코드 작성법 (공간 지역성, 시간 지역성)
- `mmap`의 동작 원리와 활용 사례

---

## 토론 주제

- GC 언어(Java, Go)와 수동 메모리 관리 언어(C, Rust)의 트레이드오프 — 어떤 상황에 무엇을 선택할 것인가?

---

## 내가 새로 알게 된 것

<!-- 자기 언어로 자유롭게 -->

---

## 참고 자료

- OSTEP Ch.13-23
