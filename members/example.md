# Week 1. OSI/TCP-IP 계층 모델

> **작성자**: memberX (예시) | **작성일**: 2026-05-04

> 이 문서는 **분량과 스타일의 기준점**입니다. 그대로 따라할 필요는 없고, "이 정도면 PR 올려도 된다"는 감만 잡으면 됩니다.

---

## 핵심 개념

- **OSI 7계층** — 1980년대 ISO 표준. 통신을 7개 추상 단계(물리·데이터링크·네트워크·전송·세션·표현·응용)로 나눈 **이상적·교육용** 참조 모델
- **TCP/IP 4계층** — 실제 인터넷이 동작하는 모델. 네트워크 접근 / 인터넷 / 전송 / 응용 4단계
- **PDU** — 각 계층이 다루는 데이터 단위. 비트 → 프레임 → 패킷 → 세그먼트 → 메시지
- **캡슐화/디캡슐화** — 송신 시 위에서 아래로 내려가며 헤더가 붙고, 수신 시 반대 순서로 헤더가 벗겨지는 과정
- **L4/L7 로드밸런서** — L4는 IP/포트만, L7은 HTTP 헤더·URL까지 보고 라우팅 결정

---

## 동작 원리 / 구조

OSI ↔ TCP/IP 매핑:

```
OSI 7계층            TCP/IP 4계층         대표 프로토콜
─────────────────    ──────────────────   ───────────────────
L7 응용 (Application) ┐
L6 표현 (Presentation)├ → 응용 (Application)  HTTP, DNS, FTP, TLS
L5 세션 (Session)     ┘
L4 전송 (Transport)    → 전송 (Transport)     TCP, UDP, QUIC
L3 네트워크 (Network)  → 인터넷 (Internet)    IP, ICMP, ARP
L2 데이터링크 (Data)   ┐
                      ├ → 네트워크 접근       Ethernet, WiFi
L1 물리 (Physical)    ┘
```

캡슐화 흐름 (HTTPS 요청 1건):

```
[HTTP message] ← 응용
      ↓ (TLS 암호화)
[Encrypted data]
      ↓ (TCP 헤더 부착)
[TCP segment: SrcPort | DstPort | SEQ | ACK | ... | data]
      ↓ (IP 헤더 부착)
[IP packet: SrcIP | DstIP | TTL | ... | TCP segment]
      ↓ (Ethernet 헤더 부착)
[Frame: SrcMAC | DstMAC | ... | IP packet | CRC]
      ↓
[Bits → 매체 전송]
```

---

## 트레이드오프

- **장점**: 계층화로 모듈성·재사용성 확보. TCP가 IPv4·IPv6 어디에도, HTTP가 TCP·QUIC 위 어느 쪽에도 동작 가능
- **단점**: 계층마다 헤더 오버헤드, 디버깅 시 어느 계층 문제인지 추적 부담
- **대안**: 단일 계층 통합 설계 — 이론적으로 가능하나 모든 변경에 전체 재설계 필요해서 현실성 X

---

## 실무/면접 포인트

### Q1. OSI 모델은 실무에서도 의미가 있나? TCP/IP만 알면 안 되나?

**A.** OSI는 **공통 어휘**로서 가치가 있다. "L4 로드밸런서"라고 말하면 모두가 IP/포트 기반이라는 걸 안다. 다만 실제 동작은 TCP/IP 4계층에 가까우니 둘 다 알되 매핑이 깔끔하지 않다는 점은 받아들여야 한다.

### Q2. 라우터·스위치·허브는 각각 어느 계층에서 동작하나?

**A.**
- **허브**: L1 (물리). 모든 포트로 비트를 그대로 broadcast
- **스위치**: L2 (데이터링크). MAC 주소 기반 forwarding
- **라우터**: L3 (네트워크). IP 주소 기반 routing

### Q3. HTTPS 요청은 어떤 계층들을 통과하나?

**A.** 응용에서 HTTP 메시지 → 표현/세션에서 TLS 암호화 + 세션 수립 → 전송에서 TCP segment → 네트워크에서 IP packet → 데이터링크에서 frame → 물리에서 비트로 전송. 서버에서는 역순.

---

## 꼬리 질문 답변

### 1. 왜 네트워크는 계층으로 나뉘어 있나? OSI 7계층과 TCP/IP 4계층은 왜 따로 존재하는가?

내가 이해한 핵심은 **separation of concerns**다. 한 계층이 자기 책임만 다하면 다른 계층은 자유롭게 교체 가능하다. 예를 들어 TCP는 자기 위가 HTTP인지 SMTP인지 신경 안 쓰고, IP는 자기 위가 TCP인지 UDP인지 신경 안 쓴다.

OSI는 1980년대 ISO에서 제안한 **이상적 참조 모델**이고, TCP/IP는 1970년대 실제 인터넷 구현에서 자라난 모델이라 둘이 다르다. OSI의 5/6/7 계층은 TCP/IP에서는 "응용 계층"으로 합쳐졌는데, 실제 프로토콜이 그 경계를 잘 안 지키기 때문이다 (예: HTTP는 응용+표현+세션 다 포함).

### 2. 브라우저에 `https://example.com` 입력 시 OSI 각 계층에서 무슨 일이 일어나나?

1. **DNS 조회** — `example.com`을 IP 주소로 변환. resolver에 recursive 질의
2. **TCP 연결** — 3-way handshake (SYN, SYN-ACK, ACK)로 L4 연결 수립
3. **TLS handshake** — 인증서 교환·검증 후 세션 키 합의 (TLS 1.3은 1-RTT)
4. **HTTP 요청 전송** — 응용 계층에서 GET / 같은 메시지 작성 → TLS로 암호화 → TCP segment → IP packet → frame → 비트
5. **서버 응답** — 역순으로 디캡슐화되어 브라우저에 도착
6. 렌더링 (TCP 연결 재사용 또는 종료)

### 3. L4 로드밸런서와 L7 로드밸런서는 무엇을 보고 라우팅하나?

- **L4 (예: AWS NLB)**: IP/포트만. 빠르고 프로토콜 무관하지만 **TLS 종료 불가**(passthrough만)
- **L7 (예: AWS ALB, nginx)**: HTTP 헤더·URL path·쿠키. 경로 기반 라우팅·sticky session·TLS 종료 가능

처리량이 우선이면 L4, 유연성·관찰성이 필요하면 L7. 실무에선 NLB(L4) → ALB(L7) → 앱 서버 다단 구성도 자주 본다.

### 4. TCP는 L4, HTTP는 L7. TLS는 어느 계층인가?

자료마다 다른 게 핵심이다. 일반적으로 **L6 (Presentation)** 으로 매핑되지만, TLS handshake가 세션을 수립하므로 **L5 (Session)** 으로 보는 시각도 있고, 실무에서는 그냥 "TCP 위·HTTP 아래"라고 설명하기도 한다.

면접에서는 "엄밀히는 모호하지만 일반적으로 L6, 실무적으로는 TCP와 HTTP 사이"라고 답하면 충분할 듯.

### 5. HTTP/3는 왜 TCP가 아닌 UDP 위에 만들어졌나?

가장 큰 이유는 **TCP 자체를 변경하기가 너무 어렵기 때문**이다. TCP는 OS 커널과 전 세계 라우터·방화벽에 박혀있어 수정 비용이 무한대에 가깝다. 그래서 UDP 위에 QUIC라는 새 프로토콜을 유저 스페이스에서 만들어, **신뢰성·순서 보장·혼잡 제어를 다시 구현**했다.

이로써 TCP의 HoL blocking을 우회할 수 있고, 0-RTT 재연결, 모바일 IP 변경 시에도 연결 유지(Connection Migration) 같은 새 기능이 가능해졌다.

이 패턴은 **"낮은 계층이 한계에 다다르면 우회해서 상위에서 다시 짓는다"**는 흐름인데, OS의 io_uring(epoll의 한계 우회)도 같은 사고방식 같다.

---

## 내가 만든 꼬리 질문

### Q. WebSocket은 OSI 7계층에서 어디에 위치하는가? HTTP/3 위에서도 동작하는가?

**내 생각:**
WebSocket은 HTTP Upgrade로 시작해 양방향 TCP 연결로 전환되니 응용 계층(L7)으로 분류된다. 전송 자체는 TCP 위라 사실상 HTTP/1.1 의존이고, HTTP/2의 멀티플렉싱과는 충돌이 있어 RFC 8441로 별도 정의됐다. HTTP/3 위에서 WebSocket은 RFC 9220으로 정의됐는데 아직 채택률이 낮아 보인다.

다음 토론 때 "왜 WebSocket이 HTTP/2 위에서는 잘 안 됐나"를 깊이 다뤄보고 싶다.

---

## 내가 새로 알게 된 것

- 계층화의 진짜 가치는 **변경 격리**라는 점. TCP를 못 바꿔서 QUIC가 나왔다는 게 가장 인상적
- OSI 7계층은 외워야 하는 게 아니라 **"공통 어휘"**라는 관점으로 보니 훨씬 자연스러움
- L4/L7 LB 차이는 안다고 생각했는데, "TLS 종료 가능 여부"가 중요한 결정 요소라는 걸 처음 깨달음
- HTTP/3가 UDP 위인 이유를 "성능"이 아니라 "**TCP를 바꿀 수 없는 정치적·인프라적 한계**" 관점에서 설명하는 게 와닿았다

---

## 참고 자료

- 컴퓨터 네트워킹 하향식 접근 (Kurose) Ch.1
- [Cloudflare — What is HTTP/3?](https://www.cloudflare.com/learning/performance/what-is-http3/)
- [MDN — Evolution of HTTP](https://developer.mozilla.org/en-US/docs/Web/HTTP/Evolution_of_HTTP)
- 주차 README: [../network/week01-osi-tcpip/README.md](../network/week01-osi-tcpip/README.md)
