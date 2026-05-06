# Phase 2. 운영체제 (Week 5–8)

> 백엔드 개발자가 알아야 할 운영체제 핵심을 4주에 걸쳐 다룹니다.
> 실행 단위(프로세스/스레드) → 동기화 → 메모리 → I/O 순으로 자원 관리와 동시성을 깊이 탐구합니다.

---

## 주차별 인덱스

| Week | 주제 | 핵심 키워드 |
|:----:|------|------------|
| [**5**](week05-process-thread/README.md) | 프로세스와 스레드 | PCB, 컨텍스트 스위칭, Goroutine, Java Virtual Thread |
| [**6**](week06-sync-deadlock/README.md) | 동기화와 데드락 | 4 조건, Mutex/Semaphore, ReentrantLock, CAS, MVCC |
| [**7**](week07-memory/README.md) | 메모리 관리 | 가상 메모리, TLB, Page Fault, mmap, ZGC |
| [**8**](week08-filesystem-io/README.md) | 파일 시스템과 I/O | epoll vs io_uring, ET/LT, Node.js Event Loop |

각 주차 README에 `이번 주 목표 / 학습 체크리스트 / 꼬리 질문 5개(접이식 힌트)` 가 포함되어 있습니다.

---

## 학습 흐름

1. **Week 5** — 실행 단위 이해 (프로세스 vs 스레드 vs 코루틴)
2. **Week 6** — 여러 실행 단위가 자원을 공유할 때 (동시성 문제)
3. **Week 7** — 자원 중 메모리는 어떻게 관리되나
4. **Week 8** — 자원 중 I/O 는 어떻게 처리하나 (백엔드 핵심)

---

## Phase 종료 시 다시 볼 면접 핵심

- 프로세스 vs 스레드 + 컨텍스트 스위칭 비용 → Week 5 Q1, Q2
- 멀티프로세스 vs 멀티스레드 vs 비동기 I/O 선택 기준 → Week 5 Q3
- 데드락 4 조건과 회피 (특히 Lock Ordering) → Week 6 Q1
- TLB miss vs Page Fault 비용 계층 → Week 7 Q2
- select / poll / epoll 차이 + io_uring 트렌드 → Week 8 Q2, Q4
- Node.js 이벤트 루프 vs 가상 스레드 → Week 5 Q4, Week 8 Q5

---

## 추천 자료

- [*OSTEP* (Three Easy Pieces)](https://pages.cs.wisc.edu/~remzi/OSTEP/) — 무료 PDF, 표준 교재
- *Java Concurrency in Practice* — JVM 동시성
- *운영체제와 정보기술의 원리* (반효경) — 한국어 정평
- `vmstat`, `pidstat`, `strace`, `perf` — 직접 실측
