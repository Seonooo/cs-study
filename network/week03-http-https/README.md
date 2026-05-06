# Week 3. HTTP / HTTPS

> **발표자**: (미정) | **날짜**: YYYY-MM-DD

---

## 이번 주 목표

- HTTP 진화 (1.1 → 2 → 3)에서 각 버전이 해결한 문제를 설명할 수 있다
- TLS 핸드셰이크 흐름을 그리고 TLS 1.3에서 RTT가 줄어든 이유를 설명할 수 있다
- HTTP 메서드의 안전성·멱등성을 분류하고 **멱등한 POST**를 설계할 수 있다
- CORS preflight가 언제·왜 발생하는지 설명할 수 있다
- `Cache-Control` / `ETag` / `Last-Modified` 의 역할 차이를 안다

---

## 학습 체크리스트

- [ ] HTTP/1.1, /2, /3 의 멀티플렉싱·HoL blocking 비교 표 작성
- [ ] 본인 framework(Spring/Express/FastAPI 등)에서 idempotency key 적용 사례 찾아 분석
- [ ] CORS preflight 트리거 조건 (Content-Type, custom header 등) 정리
- [ ] 브라우저 Network 탭에서 `Cache-Control` / `ETag` 헤더 직접 확인
- [ ] `openssl s_client -connect google.com:443` 로 TLS 핸드셰이크 캡처

---

## 꼬리 질문 (최소 5개)

> 답을 모르겠는 질문이 있으면, **본인이 만든 꼬리 질문 1개 이상**을 정리본 끝에 추가하세요.
> 힌트는 `▶ 힌트 보기`를 눌러야 펼쳐집니다 — 먼저 스스로 답해본 후 확인하세요.

### 1. HTTP/1.1 → HTTP/2 → HTTP/3 는 각각 어떤 문제를 해결했나?

> 🎯 **면접 단골 + 2026 트렌드**

<details><summary>▶ 힌트 보기</summary>

**HTTP/1.1 (1997)** — text 기반, 한 connection에서 한 번에 한 요청
- 문제: **HoL blocking (애플리케이션 레벨)** — 앞 요청이 끝나야 다음 요청 처리
- 우회책: 브라우저가 도메인당 6개 connection 동시 오픈 (낭비)

**HTTP/2 (2015)** — binary 프레임 + 멀티플렉싱
- 단일 TCP 연결에서 여러 요청·응답을 동시 전송 (스트림 ID로 구분)
- **HPACK 헤더 압축** (반복되는 헤더 인덱싱)
- Server Push (서버가 클라이언트 요청 전에 리소스 미리 전송) — 실제론 효과 미미해 **Chrome 2022년 deprecate**
- 새 문제: **TCP 레벨 HoL blocking** — TCP 패킷 1개 손실이 모든 스트림을 멈춤

**HTTP/3 (2022)** — QUIC(UDP) 위 동작
- TCP를 우회해 **유저 스페이스에서 QUIC 구현** → TCP의 HoL blocking 해소
- 스트림이 진정으로 독립적 (한 스트림 손실이 다른 스트림에 영향 X)
- 0-RTT 재연결, 모바일 네트워크 전환 시에도 connection 유지 (Connection Migration)
- TLS 1.3이 QUIC에 통합됨 → handshake 더 빠름

**핵심 통찰:** 각 버전은 **이전 버전의 HoL blocking을 다른 계층에서 해결**해온 진화. (Week 1 Q5와 연결)

</details>

### 2. HTTPS의 TLS 핸드셰이크는 어떻게 동작하며, TLS 1.3에서 무엇이 줄었나?

> 🎯 **면접 단골 — 인증서·세션 키 합의 과정 이해**

<details><summary>▶ 힌트 보기</summary>

**TLS 1.2 핸드셰이크 (2-RTT):**

1. ClientHello — 지원 cipher suite, random
2. ServerHello + Certificate + ServerKeyExchange — 서버 인증서, random
3. ClientKeyExchange — pre-master secret을 서버 공개키로 암호화 전송
4. ChangeCipherSpec + Finished — 양측이 master secret으로 세션 키 생성
- 즉 **TCP 3-way + TLS 2-RTT = 데이터 전송까지 약 3 RTT**

**TLS 1.3 핸드셰이크 (1-RTT):**

- Cipher suite 선택을 단순화 (안전한 것만 남김)
- ClientHello 시점에 **key share 후보**를 미리 전송 → 서버가 한 번에 응답하며 키 합의 완료
- 1-RTT 만에 암호화 데이터 전송 시작
- **0-RTT 재연결**: 이전 세션의 PSK(pre-shared key)로 첫 패킷부터 암호화 데이터 포함 가능 (단, replay 위험)

**인증서 검증 흐름:**

- 서버 인증서 → 중간 CA → Root CA 까지 체인 검증
- 브라우저는 OS 또는 자체 trust store의 Root CA를 신뢰
- 인증서 만료, 도메인 일치, 폐기(CRL/OCSP) 확인

**핵심 통찰:** TLS 1.3은 RTT를 줄였을 뿐 아니라 **취약한 알고리즘 (RC4, MD5, SHA-1, RSA key transport)을 모두 제거**해 보안도 강화.

</details>

### 3. HTTP 메서드의 안전성과 멱등성은 어떻게 다른가? POST를 멱등하게 만들려면 어떻게 하나?

> 🎯 **백엔드 실무 핵심 — 결제·주문 시스템에서 필수**

<details><summary>▶ 힌트 보기</summary>

**정의:**

- **Safe** (안전) — 서버 상태를 변경하지 않음. 캐시·prefetch 가능
- **Idempotent** (멱등) — 같은 요청을 여러 번 보내도 결과가 같음

**메서드 분류:**

| 메서드 | Safe | Idempotent |
|--------|:----:|:----------:|
| GET | ✅ | ✅ |
| HEAD | ✅ | ✅ |
| OPTIONS | ✅ | ✅ |
| PUT | ❌ | ✅ |
| DELETE | ❌ | ✅ |
| POST | ❌ | ❌ |
| PATCH | ❌ | ❌ |

**핵심 통찰:** 모든 safe는 idempotent이지만 **역은 성립 X** (DELETE는 멱등하지만 안전하지 않음 — 상태 변경).

**POST를 멱등하게 만드는 법 (Idempotency Key 패턴):**

1. 클라이언트가 요청마다 고유 키 생성 (UUID 등)
2. 헤더에 `Idempotency-Key: abc-123` 포함해 전송
3. 서버는 (키, 응답)을 일정 기간(보통 24h) 저장
4. 같은 키로 재요청 오면 → 이전 응답을 그대로 반환, 중복 처리 안 함

**실무 적용:**

- Stripe, Toss Payments 등 결제 API에 표준
- 주문 생성, 송금 등 "두 번 실행되면 안 되는" 작업에 필수
- 네트워크 timeout 시 클라이언트가 안전하게 재시도 가능

</details>

### 4. CORS는 무엇이고 왜 존재하며 preflight 요청은 언제 발생하나?

> 🎯 **백엔드 실무 — 프론트와 협업할 때 매주 마주치는 이슈**

<details><summary>▶ 힌트 보기</summary>

**왜 존재하나:**

- 브라우저는 기본적으로 **SOP(Same-Origin Policy)** — 같은 origin (scheme + host + port) 만 자유롭게 요청 가능
- SOP가 없으면 악성 사이트가 사용자 쿠키로 다른 사이트 API를 호출 가능 (CSRF 등)
- 하지만 실제로는 다른 origin 호출이 필요 (API 서버 분리, CDN 등) → CORS는 **서버가 명시적으로 허용**할 수 있게 해주는 메커니즘

**중요 사실:**

- CORS는 **브라우저만 강제** — 서버 간 통신, curl, postman은 CORS와 무관
- 서버 응답 헤더 `Access-Control-Allow-Origin` 등을 보고 브라우저가 차단 여부 결정

**Simple Request (preflight 없음):**

- 메서드: GET / HEAD / POST 만
- 헤더: 표준 헤더만 (custom 헤더 X)
- Content-Type: `application/x-www-form-urlencoded`, `multipart/form-data`, `text/plain` 만

**Preflight 발생 조건:**

- 위 simple request 조건을 하나라도 벗어나면 → `OPTIONS` 메서드로 사전 요청
- 예: `Content-Type: application/json`, `Authorization` 헤더, PUT/DELETE/PATCH
- 즉 실무에서 JSON API 쓰면 거의 항상 preflight 발생

**서버 응답 헤더:**

- `Access-Control-Allow-Origin: <origin or *>`
- `Access-Control-Allow-Methods: GET, POST, PUT, ...`
- `Access-Control-Allow-Headers: Authorization, Content-Type, ...`
- `Access-Control-Allow-Credentials: true` (쿠키 포함 시 — `*` 와 함께 사용 불가)

**실무 팁:** preflight 비용을 줄이려면 `Access-Control-Max-Age` 로 캐싱 시간 늘리기.

</details>

### 5. HTTP 캐싱은 어떻게 동작하나? `Cache-Control`, `ETag`, `Last-Modified` 의 역할 차이는?

> 🎯 **면접 + 실무 — CDN·브라우저 캐시 설계의 기본**

<details><summary>▶ 힌트 보기</summary>

**캐싱 두 단계:**

1. **Strong Cache (강력 캐시)** — 서버에 묻지 않고 로컬 캐시 사용
2. **Conditional Request (조건부 요청)** — 서버에 "변했는지만" 묻고, 안 변했으면 304 + 본문 없음

**`Cache-Control` (Strong Cache 제어):**

- `max-age=3600` — 3600초 동안 캐시 유효 (가장 일반적)
- `no-cache` — strong cache 안 함, 항상 conditional request 보냄
- `no-store` — 아예 저장 금지 (민감 정보)
- `public` / `private` — CDN 등 공유 캐시 사용 가능 여부
- `must-revalidate` — stale 상태일 때 반드시 revalidate

**`ETag` (Conditional Request — 콘텐츠 해시 기반):**

- 서버가 응답에 `ETag: "abc123"` 포함
- 다음 요청 시 클라이언트가 `If-None-Match: "abc123"` 전송
- 서버: 같으면 → `304 Not Modified` (본문 없음), 다르면 → `200 OK` + 새 본문
- 콘텐츠 정확한 비교 (해시 기반) → **권장**

**`Last-Modified` (Conditional Request — 시간 기반):**

- 서버가 `Last-Modified: Wed, 21 Oct 2025 07:28:00 GMT` 응답
- 클라이언트는 `If-Modified-Since` 로 재전송
- 1초 단위 비교 → **정확도 낮음**, 같은 초 안에 두 번 변경되면 캐시 오작동

**우선순위:** `ETag` 가 `Last-Modified` 보다 우선. 둘 다 있으면 ETag 사용.

**실무 패턴:**

- 정적 파일(JS/CSS): 파일명에 hash → `app.a3b2c1.js` + `Cache-Control: max-age=31536000, immutable` (1년)
- HTML: `Cache-Control: no-cache` + ETag
- API JSON: 보통 `Cache-Control: no-store` 또는 short max-age + ETag

**계층:** 브라우저 캐시 → CDN 캐시 → reverse proxy 캐시 → origin 서버. 각 단계에서 `Cache-Control` 정책 다르게 줄 수 있음.

</details>

### 내가 만든 꼬리 질문

<!-- 위 5개를 풀어보고 새로 떠오른 의문을 1개 이상 적어주세요 -->

---

## 핵심 개념

- HTTP 메서드 (GET, POST, PUT, PATCH, DELETE), 상태 코드, 주요 헤더
- 캐싱 (`Cache-Control`, `ETag`, `Last-Modified`)
- REST 원칙 (무상태, 균일 인터페이스, 계층화 등)
- TLS 핸드셰이크 과정, 인증서(CA, 체인)
- HTTP/1.1 vs HTTP/2 vs HTTP/3 주요 차이

---

## 동작 원리 / 구조

<!-- 다이어그램 또는 의사코드를 여기에 작성 -->
<!-- 예: TLS 핸드셰이크 순서도, HTTP/2 프레임 구조 -->

---

## 트레이드오프

- 장점:
- 단점:
- 대안:

---

## 실무/면접 포인트

1. **Q. HTTP/1.1과 HTTP/2의 가장 큰 차이는?**
   A.

2. **Q. HTTPS에서 TLS 핸드셰이크는 어떻게 이루어지는가?**
   A.

3. **Q. CORS가 무엇이고 preflight 요청은 왜 발생하는가?**
   A.

---

## 딥다이브

- HTTP/2 멀티플렉싱과 HoL (Head-of-Line) blocking
- HTTP/3 (QUIC 기반) — UDP를 선택한 이유
- TLS 1.3에서 줄어든 RTT (1-RTT, 0-RTT)
- CORS와 preflight 동작 원리

---

## 토론 주제

- REST, GraphQL, gRPC의 트레이드오프 — 어떤 상황에 무엇을 쓸 것인가?

---

## 내가 새로 알게 된 것

<!-- 자기 언어로 자유롭게 -->

---

## 참고 자료

- MDN Web Docs HTTP 섹션
- "HTTP 완벽 가이드"
