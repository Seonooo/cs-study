# Week 8. 파일 시스템과 I/O

> **발표자**: (미정) | **날짜**: YYYY-MM-DD

---

## 이번 주 목표

- 동기/비동기와 blocking/non-blocking을 구분해서 설명할 수 있다
- select / poll / epoll / io_uring의 차이와 진화 방향을 안다
- epoll의 ET / LT 차이를 알고 적절한 모드를 선택할 수 있다
- Node.js 이벤트 루프 동작을 설명하고 CPU 무거운 작업 처리 전략을 안다
- inode와 파일 디스크립터의 관계를 이해한다

---

## 학습 체크리스트

- [ ] `ls -li` 로 inode 번호 확인, hard link / soft link 차이 실험
- [ ] `lsof -p <pid>` 로 프로세스가 연 파일 디스크립터 확인
- [ ] 간단한 epoll 기반 echo 서버 1개 구현 (C 또는 Python)
- [ ] Node.js의 `setImmediate` / `setTimeout` / `process.nextTick` 실행 순서 분석
- [ ] `strace -e epoll_wait nginx` 등으로 실제 epoll 호출 추적

---

## 꼬리 질문 (최소 5개)

> 답을 모르겠는 질문이 있으면, **본인이 만든 꼬리 질문 1개 이상**을 정리본 끝에 추가하세요.
> 힌트는 `▶ 힌트 보기`를 눌러야 펼쳐집니다 — 먼저 스스로 답해본 후 확인하세요.

### 1. 동기/비동기와 blocking/non-blocking은 어떻게 다른가? 4가지 조합은 각각 어떤 사례에 해당하나?

> 🎯 **면접 단골 — 가장 자주 헷갈리는 개념**

<details><summary>▶ 힌트 보기</summary>

**두 개념은 직교 (orthogonal):**

- **동기/비동기 (Sync/Async)** — **결과를 누가 통보하는가**
  - 동기: 호출자가 직접 결과를 확인 (return 값 또는 polling)
  - 비동기: 피호출자가 callback / signal / future 로 통보
- **Blocking/Non-blocking** — **호출이 즉시 리턴하는가**
  - Blocking: 호출이 끝날 때까지 대기 (스레드 멈춤)
  - Non-blocking: 즉시 리턴 (결과는 다른 방법으로 확인)

**4가지 조합:**

| 조합 | 설명 | 예시 |
|------|------|------|
| **Sync + Blocking** | 결과 받을 때까지 대기 | 일반 `read()`, JDBC 쿼리 |
| **Sync + Non-blocking** | 즉시 리턴, 호출자가 polling | `read()` with `O_NONBLOCK` + `EAGAIN` 처리 |
| **Async + Blocking** | 거의 안 씀 (모순적) | `select()` 자체는 blocking이지만 비동기 알림 |
| **Async + Non-blocking** | 즉시 리턴 + 콜백·이벤트로 통보 | epoll + 이벤트 핸들러, io_uring, Node.js |

**핵심 통찰:**

- 일반적으로 "비동기 I/O"라고 부르는 것은 대부분 **Async + Non-blocking**
- "epoll은 비동기 I/O인가?" — 엄밀히는 **non-blocking I/O 다중화**. 진짜 비동기는 io_uring 부터
- Node.js의 "single-threaded async" 는 4번 조합 + 이벤트 루프

**실무 예시:**

```python
# Sync + Blocking
data = file.read()  # 끝날 때까지 대기

# Sync + Non-blocking (직접 polling)
while True:
    data = file.read_nowait()
    if data: break

# Async + Non-blocking (Node.js)
fs.readFile('a.txt', (err, data) => { ... })
```

</details>

### 2. select / poll / epoll은 어떻게 다르며, 왜 epoll이 효율적인가?

> 🎯 **면접 단골 + 백엔드 실무**

<details><summary>▶ 힌트 보기</summary>

**핵심 비교:**

| 항목 | select | poll | epoll |
|------|--------|------|-------|
| 시간 복잡도 | O(n) | O(n) | **O(1)** |
| fd 수 제한 | 1024 (FD_SETSIZE) | 무제한 | 무제한 |
| fd 전달 방식 | 매 호출마다 fd_set 복사 | array 복사 | **커널에 한번 등록** |
| 결과 통보 | 모든 fd 순회 | 모든 fd 순회 | **이벤트만 반환** |
| 플랫폼 | POSIX 표준 | POSIX 표준 | **Linux 전용** |
| Trigger 모드 | LT만 | LT만 | LT + **ET** |

**select / poll의 한계:**

- 매 호출마다 모든 fd를 커널에 전달 → 대량 fd에서 비효율
- 커널이 모든 fd 상태를 검사 → O(n) 시간
- C10K 문제: 1만 connection 처리 시 매 이벤트 루프마다 1만 개 검사

**epoll의 효율 비결:**

1. **`epoll_create`** — 커널에 epoll 인스턴스 생성
2. **`epoll_ctl(EPOLL_CTL_ADD)`** — 관심 fd를 한 번만 등록 (커널이 트리 구조로 관리)
3. **`epoll_wait`** — **준비된 이벤트 목록만** 받아옴 (수동 순회 X)

→ 1만 connection 중 100개만 활동해도 100개만 반환

**결과:**

- nginx, Redis, Netty, Node.js, Envoy 모두 epoll 기반
- 단일 서버에서 **수십만 connection** 처리 가능

**다른 OS 대응:**

- BSD/macOS: `kqueue` (epoll과 유사한 철학)
- Solaris: event ports
- Windows: IOCP (Async + Non-blocking 모델)

</details>

### 3. epoll의 edge-triggered와 level-triggered는 어떻게 다른가? 언제 무엇을 쓰나?

> 🎯 **면접 깊이 — Netty / Tokio / nginx의 선택**

<details><summary>▶ 힌트 보기</summary>

**Level-Triggered (LT, 기본):**

- 조건이 성립하는 동안 **계속 알림**
- 예: 소켓에 데이터가 남아있는 한 매번 `epoll_wait` 가 알림
- 한 번에 다 안 읽어도 다음 호출에서 다시 알림 → **안전**
- select/poll 도 LT만 지원

**Edge-Triggered (ET):**

- 조건이 **변화한 순간 한 번만** 알림
- 예: 소켓에 데이터가 새로 도착한 순간 1번 알림
- 알림 받으면 **EAGAIN 나올 때까지 모두 읽어야** 함
- 모든 데이터를 다 안 읽으면 다음 알림이 안 옴 → 데이터 누락

**ET 사용 패턴:**

```c
while (true) {
    n = read(fd, buf, sizeof(buf));
    if (n == 0) break;          // 연결 종료
    if (n < 0) {
        if (errno == EAGAIN) break;  // 더 이상 데이터 없음
        // 에러 처리
    }
    // process buf
}
```

**비교:**

| 항목 | LT | ET |
|------|-----|-----|
| 알림 횟수 | 많음 (조건 유지되는 동안) | 적음 (변화 순간만) |
| 시스템 콜 횟수 | 많음 | 적음 |
| 구현 난이도 | 쉬움 | 어려움 (반드시 non-blocking + EAGAIN 루프) |
| 성능 | 좋음 | 더 좋음 (시스템 콜↓) |
| 데이터 누락 위험 | 없음 | 있음 (잘못 짜면) |

**언제 무엇을:**

- 일반 애플리케이션 — LT (기본, 안전)
- 고성능 서버 (nginx, Netty epoll) — ET (시스템 콜 줄여 throughput↑)
- 학습용 echo 서버 — LT 부터 시작

**Netty 사례:**

- `EpollEventLoopGroup` — ET 사용 (성능 최적)
- `NioEventLoopGroup` — Java NIO Selector 기반 (LT, 크로스 플랫폼)

</details>

### 4. io_uring은 epoll과 무엇이 다른가? 왜 등장했고 백엔드는 언제 써야 하나?

> 🎯 **2026 트렌드 — Linux 진영의 차세대 I/O**

<details><summary>▶ 힌트 보기</summary>

**왜 epoll로 부족한가:**

- epoll은 "**언제 I/O가 가능한지**" 알려줌. 실제 read/write는 별도 시스템 콜 필요
- 매 I/O마다 syscall → 컨텍스트 스위치 비용
- meltdown/spectre 패치 이후 syscall 비용 증가
- 진짜 비동기 disk I/O는 epoll로 표현 불가 (epoll은 socket·pipe 위주)

**io_uring의 혁신 (Linux 5.1, 2019):**

- 커널-유저스페이스 간 **공유 ring buffer 2개** (Submission Queue, Completion Queue)
- 유저가 SQE(submission queue entry)에 작업 기술 → 커널이 처리 후 CQE 작성
- 시스템 콜 없이 통신 가능 (`SQ_POLL` 모드)
- **진짜 비동기** — disk I/O, 네트워크, 파일 메타데이터 등 모두 비동기로

**epoll vs io_uring:**

| 항목 | epoll | io_uring |
|------|-------|---------|
| 모델 | I/O readiness 통보 | I/O 작업 자체 비동기 실행 |
| Disk I/O 지원 | 어려움 | 진정한 비동기 |
| Syscall 횟수 | 매 I/O마다 | 0회 가능 (SQ_POLL) |
| zero-copy | 제한적 | 다양한 방식 지원 |
| API 복잡도 | 단순 | 복잡 |
| Linux 버전 | 2.6+ | 5.1+ |

**백엔드 도입 사례:**

- ScyllaDB, RocksDB — disk I/O 가속
- Tokio (Rust) — 옵션으로 지원
- **Node.js 20.3+** — 일부 파일 I/O에 io_uring 사용
- Netty — 실험적 지원
- Linux Kernel TLS와 결합 시 더 큰 이점

**언제 써야 하나:**

- **Disk I/O가 병목** — DB 엔진, 로그 처리, 파일 서버
- **수백만 IOPS 필요** — 고성능 NVMe 활용
- **소켓만 다루면** epoll 으로 충분 (구현 복잡도 vs 이득 trade-off)

**주의사항:**

- API가 자주 바뀜 (커널 5.1 ~ 6.x 사이 진화)
- 일부 기능은 보안 이유로 비활성화 (Google이 Chrome OS에서 비활성화한 사례)
- 모든 시스템에서 가용하지 않음 → epoll fallback 필요

**핵심 통찰:** epoll → io_uring 진화는 Week 1 Q5 (HTTP/3 = TCP → QUIC 진화)와 같은 패턴 — "기존 추상이 한계에 다다르면 더 낮은 계층에서 새로 짓는다."

</details>

### 5. Node.js의 이벤트 루프는 어떻게 동작하며, 단일 스레드로 높은 처리량을 달성하는가? CPU 무거운 작업이 들어오면 어떻게 처리하나?

> 🎯 **백엔드 실무 — Node.js 사용 시 매일 영향**

<details><summary>▶ 힌트 보기</summary>

**Node.js 구조:**

```
┌──────────────────────────┐
│   JavaScript (V8)        │  ← 단일 스레드, 콜백 실행
├──────────────────────────┤
│   libuv 이벤트 루프       │  ← 비동기 I/O 통보
├──────────────────────────┤
│   epoll / kqueue / IOCP  │  ← OS 비동기 I/O
│   + 워커 스레드 풀         │  ← 파일 I/O, DNS 등
└──────────────────────────┘
```

**이벤트 루프 단계 (단순화):**

1. **Timers** — `setTimeout` / `setInterval` 콜백
2. **Pending callbacks** — 일부 시스템 콜 콜백
3. **Idle, prepare** — 내부용
4. **Poll** — 새 I/O 이벤트 받음, 콜백 실행 (**대부분 시간 여기**)
5. **Check** — `setImmediate` 콜백
6. **Close callbacks** — `socket.on('close')` 등

**우선순위 (높음 → 낮음):**

1. `process.nextTick` — 마이크로태스크, 즉시
2. Promise microtasks (`.then`)
3. Timer phase (timeout)
4. Poll phase (I/O)
5. Check phase (`setImmediate`)

**왜 단일 스레드로 높은 처리량?**

- 일반 백엔드는 대부분 I/O bound (DB, HTTP 등) → 대기 시간 90%+
- 한 요청이 I/O 대기 중일 때 다른 요청 처리 → CPU 100% 활용
- 컨텍스트 스위칭 없음 → 오버헤드 없음
- 락 불필요 → 동시성 버그 없음

**한계 — CPU 무거운 작업:**

- 한 콜백이 100ms CPU 점유하면 → **모든 요청이 100ms 대기**
- 특히 영상 처리, 암호화, ML 추론, 큰 JSON 파싱 등

**CPU 작업 처리 전략:**

1. **Worker Threads** (`worker_threads` 모듈) — 같은 프로세스 내 별도 스레드
   - 메시지로 통신 (구조화 복제)
   - CPU 코어 활용 가능

2. **Cluster** — 여러 Node.js 프로세스 + 로드밸런서
   - 코어 수만큼 프로세스 띄움
   - PM2, cluster 모듈 활용

3. **외부 서비스 분리** — Python/Go/Rust 워커로 ML 추론 등 분리

4. **스트리밍 처리** — 큰 데이터를 chunk로 나눠 처리 (스택 안 막힘)

**디버깅 팁:**

- `node --inspect` + Chrome DevTools 로 이벤트 루프 lag 확인
- `setImmediate` 와 `setTimeout(fn, 0)` 의 미묘한 차이 (이벤트 루프 단계 차이)
- `process.nextTick` 남용 시 I/O 단계 진입 못함 → starvation

**실무 패턴:**

- API 서버: Node.js 단독 (I/O bound)
- 이미지 처리 / ML: 별도 워커 또는 다른 언어
- WebSocket 채팅: Node.js (단일 스레드 + epoll 의 정점)

</details>

### 내가 만든 꼬리 질문

<!-- 위 5개를 풀어보고 새로 떠오른 의문을 1개 이상 적어주세요 -->

---

## 핵심 개념

- inode 구조와 디렉토리 구조
- 저널링 (Journaling) 파일 시스템
- 블록 I/O vs 스트림 I/O
- 동기/비동기 I/O, Blocking/Non-blocking I/O

---

## 동작 원리 / 구조

<!-- 다이어그램 또는 의사코드를 여기에 작성 -->
<!-- 예: I/O 모델 비교 표, epoll 이벤트 루프 구조 -->

---

## 트레이드오프

- 장점:
- 단점:
- 대안:

---

## 실무/면접 포인트

1. **Q. 동기/비동기 I/O와 blocking/non-blocking I/O의 차이는?**
   A.

2. **Q. select, poll, epoll의 차이는? epoll이 왜 더 효율적인가?**
   A.

3. **Q. Node.js의 이벤트 루프는 어떻게 단일 스레드로 높은 처리량을 달성하는가?**
   A.

---

## 딥다이브

- `select` / `poll` / `epoll` / `kqueue` 비교 (복잡도, fd 제한)
- `io_uring` — 리눅스 최신 비동기 I/O 인터페이스
- Node.js 이벤트 루프와 libuv
- 리눅스 파일 디스크립터 (fd)와 open file table

---

## 토론 주제

- 백엔드 서버에서 I/O 모델 선택이 처리량(throughput)과 지연(latency)에 미치는 영향

---

## 내가 새로 알게 된 것

<!-- 자기 언어로 자유롭게 -->

---

## 참고 자료

- OSTEP Ch.36-43
- "The C10K problem" (Dan Kegel)
