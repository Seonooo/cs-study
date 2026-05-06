# Week 2. TCP, UDP

> **발표자**: (미정) | **날짜**: YYYY-MM-DD

---

## 이번 주 목표

- TCP 3-way / 4-way handshake를 그리고 **왜 3번·4번이어야 하는지** 설명할 수 있다
- TIME_WAIT의 존재 이유와 백엔드 서버에서 발생하는 문제·해결책을 설명할 수 있다
- TCP vs UDP의 차이를 알고 요구사항에 맞춰 선택할 수 있다
- 흐름 제어와 혼잡 제어의 책임 영역 차이를 한 문장으로 설명할 수 있다
- HTTP Keepalive / Connection Pool이 왜 필요한지, 풀 사이즈 결정 기준을 안다

---

## 학습 체크리스트

- [ ] TCP 상태 다이어그램 손으로 그려보기 (`LISTEN → SYN_SENT/RECV → ESTABLISHED → FIN_WAIT_1/2 → TIME_WAIT → CLOSED`)
- [ ] 3-way / 4-way handshake에서 시퀀스 번호(SEQ/ACK)가 어떻게 변하는지 추적
- [ ] `netstat -ant` 또는 `ss -ant` 로 로컬 TIME_WAIT 소켓 확인해보기
- [ ] `tcpdump` 또는 Wireshark 로 실제 handshake 패킷 캡처
- [ ] HTTP keepalive 설정 (nginx, Spring / Express 등) 코드 레벨에서 확인
- [ ] Connection pool 라이브러리 (HikariCP / axios pool 등) 1개 분석

---

## 꼬리 질문 (최소 5개)

> 답을 모르겠는 질문이 있으면, **본인이 만든 꼬리 질문 1개 이상**을 정리본 끝에 추가하세요.
> 힌트는 `▶ 힌트 보기`를 눌러야 펼쳐집니다 — 먼저 스스로 답해본 후 확인하세요.

### 1. TCP 3-way handshake는 왜 2번이 아닌 3번인가? 4-way close는 왜 4번인가?

> 🎯 **면접 단골 질문**

<details><summary>▶ 힌트 보기</summary>

**3-way가 필요한 이유:**

- 양방향 통신을 위해 **각 방향의 시퀀스 번호(ISN)** 를 합의해야 함
- 2-way로는 한쪽의 ISN만 전달 가능 → 반대 방향이 검증 안 됨
- SYN → SYN+ACK → ACK : 클라이언트가 "내 ISN 알지?"를 한번 더 확인 → 신뢰성 보장
- 2-way로 끝낼 경우, 지연된 SYN이 새 연결을 만들어버리는 위험도 있음 (delayed duplicate problem)

**4-way close가 필요한 이유:**

- TCP 연결은 **양방향(full-duplex)** — 각 방향을 독립적으로 닫아야 함
- A→B FIN, B→A ACK 까지 하면 A→B 방향만 닫힌 상태 (half-close)
- B는 아직 보낼 데이터가 남아있을 수 있음 → 다 보낸 뒤 B→A FIN, A→B ACK
- 합쳐서 4번. 만약 B가 보낼 데이터가 없으면 FIN+ACK가 합쳐져 3번이 되기도 함

</details>

### 2. TIME_WAIT는 왜 필요하고, 백엔드 서버에서 어떤 문제를 일으키며 어떻게 해결하는가?

> 🎯 **백엔드 실무 핵심 — 운영 중 자주 마주치는 이슈**

<details><summary>▶ 힌트 보기</summary>

**왜 필요한가 (2가지):**

1. **지연된 세그먼트의 오인 방지** — 같은 IP/Port 4-tuple로 새 연결이 즉시 만들어지면, 이전 연결의 지연 패킷이 새 연결의 데이터로 잘못 해석될 수 있음
2. **마지막 ACK 분실 대비** — 상대방이 FIN을 재전송할 수 있도록 일정 시간 대기 필요

**대기 시간:** 2 × MSL (Maximum Segment Lifetime). RFC상 240초이지만 **Linux 기본값은 60초** (MSL=30s).

**백엔드 서버 문제:**

- **Ephemeral port 고갈** — TIME_WAIT 소켓이 ephemeral 포트(보통 32768~60999, 약 28k개)를 점유 → 단시간 대량 요청 시 새 연결 불가
- 특히 **클라이언트 측에서 active close** 할 때 자주 발생 (예: API 서버가 외부 API를 짧은 연결로 자주 호출)
- 메모리도 약간씩 점유

**해결책:**

1. **HTTP keepalive** — connection 재사용으로 TIME_WAIT 자체를 줄임 (가장 추천)
2. **Connection pool** — DB/HTTP 클라이언트가 풀에서 재사용
3. `SO_REUSEADDR` / `SO_REUSEPORT` — 소켓 옵션으로 같은 포트 재사용 허용
4. `net.ipv4.tcp_tw_reuse=1` — Timestamp 옵션 기반으로 안전하게 재사용 (권장)
5. ⚠️ `tcp_tw_recycle` — Linux 4.12에서 제거됨 (NAT 환경에서 위험). 사용 금지

</details>

### 3. TCP와 UDP는 어떻게 다르며, 실시간 영상통화 / 금융 거래 / 멀티플레이 게임은 각각 무엇을 쓰는가?

> 🎯 **면접 단골 — 트레이드오프 판단력**

<details><summary>▶ 힌트 보기</summary>

**핵심 차이:**

| 항목 | TCP | UDP |
|------|-----|-----|
| 연결 | 연결 지향 (handshake) | 비연결 |
| 신뢰성 | 보장 (재전송, 순서, 중복 제거) | 무보장 |
| 흐름/혼잡 제어 | 있음 | 없음 |
| 헤더 | 20+바이트 | 8바이트 |
| 지연 | 상대적으로 큼 | 작음 |
| 사용 | HTTP, DB, SSH | DNS, 영상/음성, 게임 |

**선택 기준:**

- **금융 거래** → **TCP**. 한 건이라도 누락되면 안 됨. 지연보다 정확성 우선
- **실시간 영상통화** → **UDP** (RTP/SRTP 위에서). 손실된 패킷 재전송 받느라 지연되는 것보다 약간 깨진 영상이 나음. WebRTC도 UDP 기반
- **멀티플레이 게임** → **UDP**. 위치 패킷이 늦게 오면 의미 없음. 다음 패킷이 더 최신
- **HTTP/3** → UDP 기반 QUIC 위에서 동작 (Week 1 Q5와 연결)

**핵심 통찰:** "데이터를 못 받느니 늦게라도 받자" → TCP. "늦게 받느니 차라리 못 받자" → UDP.

</details>

### 4. 흐름 제어와 혼잡 제어는 어떻게 다른가? 혼잡 제어 알고리즘은 어떻게 진화해왔나?

> 🎯 **자주 혼동되는 개념 + 2026 트렌드 (BBR)**

<details><summary>▶ 힌트 보기</summary>

**책임 영역 구분:**

- **흐름 제어 (Flow Control)** — **송수신자 사이**의 문제. 수신자 버퍼 오버플로우 방지. 수신자가 `Receive Window (rwnd)` 광고
- **혼잡 제어 (Congestion Control)** — **네트워크 전체**의 문제. 라우터 큐 오버플로우 방지. 송신자가 `Congestion Window (cwnd)` 자체 추정

실제 송신량 = `min(rwnd, cwnd)` — 둘 다 동시에 동작.

**혼잡 제어 알고리즘 진화:**

1. **TCP Reno (1990)** — AIMD (Additive Increase, Multiplicative Decrease)
   - 패킷 손실을 혼잡 신호로 간주 → cwnd 절반으로
   - sawtooth 패턴, long-distance·고대역폭에서 비효율

2. **TCP Cubic (2008, Linux 기본값)** — cwnd가 cubic 함수로 증가
   - 손실 발생 지점을 기준으로 천천히 다가가다 빠르게 회복
   - 고대역폭·고지연(long fat network)에서 Reno보다 우수

3. **TCP BBR (2016, Google)** — Bottleneck Bandwidth + RTT 모델 기반
   - 손실이 아닌 **대역폭과 지연을 측정**해 최적 송신율 추정
   - 패킷 손실이 흔한 무선/모바일 환경에서 큰 성능 개선
   - YouTube/GCP 사용 → **2026 백엔드 면접 트렌드**

**핵심 통찰:** Reno/Cubic은 "loss-based"(손실 후 반응), BBR은 "model-based"(혼잡 발생 전 회피). bufferbloat 환경에서 BBR이 압도적.

</details>

### 5. HTTP Keepalive와 Connection Pool은 왜 필요한가? 풀 사이즈는 어떻게 결정하는가?

> 🎯 **백엔드 실무 핵심 — DB / HTTP 클라이언트 매일 다루는 주제**

<details><summary>▶ 힌트 보기</summary>

**왜 필요한가:**

- 매 요청마다 TCP 3-way handshake + TLS handshake 비용 발생 (각 1 RTT 이상)
- 연결을 재사용하면 → handshake 비용 0, TIME_WAIT 누적도 방지
- DB 연결은 더 비쌈 (인증, 세션 초기화 추가)

**Keepalive (HTTP/1.1):**

- `Connection: keep-alive` 헤더로 같은 TCP 연결에서 여러 요청 처리
- HTTP/1.1부터 기본값. HTTP/2는 단일 연결 위 멀티플렉싱
- nginx 예: `keepalive_timeout`, `keepalive_requests`

**Connection Pool (DB/HTTP 클라이언트):**

- 미리 N개 연결을 만들어두고 재사용
- HikariCP, pgBouncer, axios agent, requests Session 등

**풀 사이즈 결정 기준:**

- DB는 **(코어 수 × 2) + 디스크 스핀들 수** 가 클래식 공식 (PostgreSQL 권장 식)
- 일반적으로 **DB 풀 < 애플리케이션 스레드 수 < 클라이언트 동시 요청** 관계
- 너무 크면 → DB 자원 고갈 / context switching 비용
- 너무 작으면 → 요청이 풀 대기 큐에서 적체
- **모니터링 지표**: 풀 사용률, 대기 시간, DB CPU/연결 수

**실무 패턴:**

- 외부 HTTP API 호출 시 keepalive + pool 적용했더니 latency 50%↓, TIME_WAIT 99%↓ 같은 사례가 흔함

</details>

### 내가 만든 꼬리 질문

<!-- 위 5개를 풀어보고 새로 떠오른 의문을 1개 이상 적어주세요 -->

---

## 핵심 개념

- TCP vs UDP 특성 비교 (연결 지향, 신뢰성, 순서 보장)
- 3-way handshake (SYN → SYN-ACK → ACK)
- 4-way handshake (FIN → ACK → FIN → ACK)
- 흐름 제어 (슬라이딩 윈도우), 혼잡 제어 (AIMD, Slow Start)
- TCP 상태 다이어그램 (LISTEN, SYN_SENT, ESTABLISHED, TIME_WAIT 등)

---

## 동작 원리 / 구조

<!-- 다이어그램 또는 의사코드를 여기에 작성 -->
<!-- 예: 3-way / 4-way handshake 순서도, TCP 세그먼트 구조 -->

---

## 트레이드오프

- 장점:
- 단점:
- 대안:

---

## 실무/면접 포인트

1. **Q. TIME_WAIT 상태는 왜 필요한가?**
   A.

2. **Q. 흐름 제어와 혼잡 제어의 차이는?**
   A.

3. **Q. UDP를 사용하는 실제 사례와 그 이유는?**
   A.

---

## 딥다이브

- TIME_WAIT가 왜 필요한가? (2MSL)
- Nagle 알고리즘과 소켓 옵션 `TCP_NODELAY`
- TCP Fast Open — 재연결 시 RTT 절감 방법
- QUIC가 UDP 위에 만들어진 이유

---

## 토론 주제

- 실시간성이 중요한 게임/영상 스트리밍에서 TCP vs UDP 선택 기준

---

## 내가 새로 알게 된 것

<!-- 자기 언어로 자유롭게 -->

---

## 참고 자료

- "TCP/IP Illustrated Vol.1"
- `tcpdump` / `wireshark` 실습
