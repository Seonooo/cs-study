# Week 4. DNS, 로드밸런싱, CDN

> **발표자**: (미정) | **날짜**: YYYY-MM-DD

---

## 이번 주 목표

- DNS 조회 흐름(recursive / iterative)을 그림으로 설명할 수 있다
- TTL 설정의 트레이드오프와 마이그레이션 시 TTL 활용 패턴을 안다
- Stateless 아키텍처의 장점을 이해하고 sticky session이 필요한 경우를 판단할 수 있다
- Anycast 라우팅 원리를 설명할 수 있다
- CDN의 origin shield · edge cache · `stale-while-revalidate` 등 캐시 전략을 안다

---

## 학습 체크리스트

- [ ] `dig +trace google.com` 으로 DNS 조회 단계 직접 추적
- [ ] 자주 쓰는 도메인의 TTL·레코드 타입 확인 (`dig <domain>`)
- [ ] 본인이 운영하거나 사용하는 서비스가 Anycast 사용 중인지 확인
- [ ] 브라우저 Network 탭에서 CDN 응답 헤더 (`X-Cache`, `Age`, `CF-Cache-Status` 등) 분석
- [ ] CDN(CloudFront / Cloudflare) 무료 플랜에서 캐시 동작 실습

---

## 꼬리 질문 (최소 5개)

> 답을 모르겠는 질문이 있으면, **본인이 만든 꼬리 질문 1개 이상**을 정리본 끝에 추가하세요.
> 힌트는 `▶ 힌트 보기`를 눌러야 펼쳐집니다 — 먼저 스스로 답해본 후 확인하세요.

### 1. DNS recursive와 iterative 쿼리는 어떻게 다른가? `google.com` 을 처음 조회할 때 실제로 어떤 흐름인가?

> 🎯 **면접 단골 — DNS hierarchy 이해**

<details><summary>▶ 힌트 보기</summary>

**Recursive vs Iterative:**

- **Recursive** — "최종 답을 가져와줘". 받은 서버가 모든 하위 조회를 대신 처리
- **Iterative** — "네가 모르면 누구한테 물어볼지만 알려줘". 클라이언트가 직접 다음 서버에 다시 질의

**실제 흐름 (`google.com` 첫 조회):**

1. 클라이언트 → **로컬 resolver** (예: ISP의 8.8.8.8): **Recursive 요청**
2. resolver → Root 서버(`.`): "google.com 알아?" → "`.com` TLD 서버 IP 알려줄게" (**Iterative 응답**)
3. resolver → `.com` TLD 서버: "google.com 알아?" → "google.com 권한 서버 IP 알려줄게"
4. resolver → google.com 권한 서버: "A 레코드 알려줘" → 실제 IP 반환
5. resolver → 클라이언트: 최종 IP 반환 + 캐싱

**핵심 통찰:**

- 클라이언트→resolver는 **recursive**, resolver→권한서버는 **iterative**. 두 가지가 한 흐름에 공존
- 13개의 root 서버 (A~M)는 anycast로 전 세계에 분산. 같은 IP를 여러 노드가 광고
- 캐싱 덕분에 실제로는 대부분의 조회가 root까지 안 감

</details>

### 2. DNS TTL을 너무 낮거나 너무 높게 잡으면 각각 어떤 문제가 발생하나? 서비스 마이그레이션 시 TTL을 어떻게 활용하나?

> 🎯 **실무 — 마이그레이션 / 장애 대응 시 결정적**

<details><summary>▶ 힌트 보기</summary>

**낮은 TTL (60–300초):**

- 장점: 변경이 빠르게 전파됨. IP 교체·장애 조치 빠름
- 단점: 권한 서버에 부하↑, resolver 캐시 효율↓, 약간의 지연
- 적합: 자주 바뀌는 레코드, 동적 라우팅(GeoDNS), 헬스체크 기반 자동 페일오버

**높은 TTL (3600–86400초):**

- 장점: 권한 서버 부하↓, 응답 빠름
- 단점: 변경이 TTL만큼 늦게 전파됨. 일부 resolver는 TTL을 무시하고 더 길게 캐싱
- 적합: 거의 안 바뀌는 정적 레코드 (MX, NS 등)

**마이그레이션 패턴 (실무 표준):**

1. 마이그레이션 1주일 전: TTL을 평소 값(예: 1시간)에서 **60초로 낮춤** → 평소 값의 캐시가 모두 만료될 때까지 대기
2. 마이그레이션 직전: 모든 캐시가 60초 단위로 갱신 중인 상태
3. 마이그레이션 실행: IP 변경 → 60초 안에 전 세계 전파
4. 안정화 후: 다시 평소 TTL로 복귀

**Negative caching (NXDOMAIN):**

- 존재하지 않는 도메인 응답도 캐싱됨 (SOA 레코드의 minimum TTL 기반)
- 새 서브도메인 추가했는데 한참 안 보이는 이유 — 이전 NXDOMAIN이 캐싱되어 있음

</details>

### 3. Sticky session vs Stateless 설계의 트레이드오프는? 어떤 경우 sticky session이 필요하고 어떤 경우 피해야 하나?

> 🎯 **백엔드 실무 핵심 — 세션 저장소 / 오토스케일링 설계**

<details><summary>▶ 힌트 보기</summary>

**Stateless (이상적):**

- 어느 서버가 받든 같은 응답 → 무한 horizontal scaling 가능
- 세션 데이터를 외부 저장소(Redis, DB)에 두거나 클라이언트가 보유(JWT, 쿠키)
- 장애 격리·롤링 배포·오토스케일링이 쉬움

**Sticky session (어쩔 수 없을 때):**

- 로드밸런서가 같은 클라이언트 → 같은 서버로 라우팅
- 구현: 쿠키 기반 (LB가 쿠키 발급) 또는 IP hash 기반
- 장점: 서버 로컬 메모리에 세션 캐시 가능 → Redis 호출 감소
- 단점:
  - **서버 다운 시 세션 소실**
  - 부하 분산 불균등 (long-running connection이 한 서버에 쏠림)
  - 오토스케일링 효과 반감 (새 인스턴스에 트래픽이 잘 안 옴)

**언제 sticky가 필요?**

- WebSocket / SSE 같은 long-lived connection (이건 LB 레벨에서 자연스럽게 sticky)
- 레거시 in-memory 세션을 가진 시스템 (마이그레이션 전 임시방편)
- 일부 stateful 게임 서버

**언제 피해야?**

- 일반 REST API — 무조건 stateless로
- 마이크로서비스 — 호출 흐름이 복잡해 sticky 유지가 어려움

**실무 패턴:** 세션은 Redis(외부 저장소), 인증은 JWT, sticky는 WebSocket에만 — 가장 흔한 조합.

</details>

### 4. Anycast 라우팅은 어떻게 동작하며 CDN과 public DNS는 왜 이걸 사용하나?

> 🎯 **면접 + 실무 — CDN의 핵심 기술**

<details><summary>▶ 힌트 보기</summary>

**Anycast 동작:**

- 같은 IP 주소를 **여러 PoP(Point of Presence)** 에서 **BGP로 광고**
- 인터넷 라우터들은 BGP 메트릭(보통 AS hop 수) 기준으로 가장 가까운 광고자에게 패킷 전달
- 클라이언트 입장에서는 같은 IP 한 개로 보이지만 실제로는 가장 가까운 노드와 통신

**왜 CDN이 사용?**

- DNS 조회 없이 **자동으로 가장 가까운 edge로 라우팅**
- DDoS 공격 분산 — 한 PoP가 공격받아도 다른 PoP가 살아있음
- 단일 PoP 장애 시 BGP가 자동으로 다음 가까운 PoP로 페일오버

**왜 public DNS(8.8.8.8, 1.1.1.1)가 사용?**

- 단일 IP로 전 세계 어디서든 가까운 데이터센터 조회
- 사용자별 DNS 설정 변경 불필요

**Anycast vs DNS GeoLB:**

- DNS GeoLB: 사용자 IP → 위치 추정 → 다른 IP 응답. 정확하지만 DNS 캐싱 의존
- Anycast: BGP 기반 자동 라우팅. 즉각적이지만 BGP 변동에 영향받음
- **실무에서는 둘을 조합** — DNS로 1차 라우팅 + Anycast로 미세 조정

**핵심 통찰:** Anycast는 **L3(IP) 레벨의 로드밸런싱**. L4/L7 LB와 다른 차원에서 작동.

</details>

### 5. CDN의 origin shield는 무엇이고 왜 필요한가? `stale-while-revalidate` 같은 캐시 전략은 언제 쓰나?

> 🎯 **실무 — 트래픽 폭증 / origin 보호**

<details><summary>▶ 힌트 보기</summary>

**계층 구조:**

```
클라이언트 → Edge PoP (L1: 메모리, L2: SSD) → Origin Shield (L3: 지역 캐시) → Origin 서버
```

**Origin shield란:**

- edge와 origin 사이에 **지역별 중간 캐시 계층**
- 같은 지역의 edge들이 모두 origin shield를 통해 origin에 접근
- 캐시 미스가 발생해도 같은 지역의 첫 미스만 origin에 도달, 나머지는 shield에서 처리

**왜 필요한가:**

- 글로벌 캐시 미스 시: edge 200개가 각각 origin에 요청 → **origin이 200× 부하**
- shield 사용 시: 지역별 1번씩만 → **약 3× 부하** (대륙당 1회)
- origin 부하를 100× 가까이 줄이는 효과 → DDoS·flash crowd 대응

**캐시 무효화·갱신 전략:**

1. **`stale-while-revalidate`** — TTL 만료 후에도 일정 시간 동안 stale 응답을 즉시 반환하면서, 백그라운드에서 origin에 갱신 요청
   - 사용자는 항상 빠른 응답, origin 갱신 비용은 별도
   - 사용처: 실시간 정확성보다 응답 속도가 중요한 콘텐츠 (뉴스 메인 등)

2. **`stale-if-error`** — origin 장애 시 만료된 캐시라도 응답 반환
   - origin 장애 격리

3. **Cache purge / invalidation** — 명시적 무효화 API
   - 콘텐츠 즉시 갱신이 필요할 때 (예: 가격 변경, 긴급 공지)

4. **Surrogate-Control 헤더** — `Cache-Control` 과 별도로 CDN에만 다른 캐시 정책 지정 가능
   - 예: 브라우저는 짧게, CDN은 길게

**실무 패턴:**

- 정적 자산: edge에서 1년 캐시 + 파일명 hash로 무효화
- API 응답: origin shield + 짧은 TTL + `stale-while-revalidate`
- 인증 필요 페이지: 캐시 안 함 (`Cache-Control: private, no-store`)

</details>

### 내가 만든 꼬리 질문

<!-- 위 5개를 풀어보고 새로 떠오른 의문을 1개 이상 적어주세요 -->

---

## 핵심 개념

- DNS 계층 구조 (루트 → TLD → 권한 네임서버)
- DNS 레코드 타입 (A, AAAA, CNAME, MX, NS, TXT)
- Recursive vs Iterative 쿼리
- L4 로드밸런싱 (IP/포트 기반) vs L7 로드밸런싱 (HTTP 헤더/URL 기반)
- CDN 캐싱 전략 (origin pull, push, edge cache)

---

## 동작 원리 / 구조

<!-- 다이어그램 또는 의사코드를 여기에 작성 -->
<!-- 예: DNS recursive 쿼리 흐름, CDN 요청 처리 흐름 -->

---

## 트레이드오프

- 장점:
- 단점:
- 대안:

---

## 실무/면접 포인트

1. **Q. DNS 캐싱 TTL이 너무 낮거나 높으면 어떤 문제가 생기는가?**
   A.

2. **Q. L4와 L7 로드밸런서의 차이와 선택 기준은?**
   A.

3. **Q. CDN을 사용하면 왜 응답 속도가 빨라지는가?**
   A.

---

## 딥다이브

- DNS 캐싱과 TTL, negative caching
- CDN의 origin shield (중간 캐시 계층)
- Sticky session vs Stateless 설계
- Anycast 라우팅 원리

---

## 토론 주제

- 글로벌 서비스를 구축한다면 DNS, CDN, 로드밸런서를 어떤 순서로 배치해야 하는가?

---

## 내가 새로 알게 된 것

<!-- 자기 언어로 자유롭게 -->

---

## 참고 자료

- "Site Reliability Engineering" 관련 챕터
- AWS / GCP 아키텍처 레퍼런스
