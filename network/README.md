# Phase 1. 네트워크 (Week 1–4)

> 백엔드 개발자가 알아야 할 네트워크 핵심을 4주에 걸쳐 다룹니다.
> 계층 모델 → 전송 계층 → 응용 계층 → 인프라 순으로 추상화를 올라갑니다.

---

## 주차별 인덱스

| Week | 주제 | 핵심 키워드 |
|:----:|------|------------|
| [**1**](week01-osi-tcpip/README.md) | OSI/TCP-IP 계층 모델 | 7계층 vs 4계층, 캡슐화, L4/L7 LB, HTTP/3 |
| [**2**](week02-tcp-udp/README.md) | TCP, UDP | 3·4-way handshake, TIME_WAIT, BBR, Connection Pool |
| [**3**](week03-http-https/README.md) | HTTP / HTTPS | HTTP/2·3, TLS 1.3, 멱등성, CORS, 캐싱 |
| [**4**](week04-dns-lb-cdn/README.md) | DNS, 로드밸런싱, CDN | recursive/iterative, TTL, Anycast, Origin Shield |

각 주차 README에 `이번 주 목표 / 학습 체크리스트 / 꼬리 질문 5개(접이식 힌트)` 가 포함되어 있습니다.

---

## 학습 흐름

1. **Week 1** — 계층 모델로 전체 그림 잡기
2. **Week 2** — L4(전송)에서 일어나는 일 깊이 탐구
3. **Week 3** — L7(응용) HTTP의 진화 추적
4. **Week 4** — 인프라 운영 관점 (DNS / LB / CDN)

---

## Phase 종료 시 다시 볼 면접 핵심

- **"URL을 입력하면 일어나는 일"** → Week 1 Q2
- TIME_WAIT 와 connection pool 흐름 → Week 2 Q2, Q5
- HTTP 진화 (1.1 → 2 → 3) → Week 3 Q1, Week 1 Q5
- L4 vs L7 로드밸런서 → Week 1 Q3, Week 4 Q3
- TLS 핸드셰이크 + TLS 1.3 개선 → Week 3 Q2

---

## 추천 자료

- *컴퓨터 네트워킹 하향식 접근* (Kurose) — 표준 교재
- *TCP/IP Illustrated Vol.1* (Stevens) — 깊이 있게
- [MDN HTTP 섹션](https://developer.mozilla.org/en-US/docs/Web/HTTP) — 실무 레퍼런스
- Wireshark / tcpdump — 패킷 직접 보기
