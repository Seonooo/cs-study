# CS 스터디

네트워크 → 운영체제 → 데이터베이스 → 프레임워크 → 운영 순서로 진행하는 **20주 백엔드 CS 스터디**.

2026 백엔드 면접 우선순위에 맞춰 한 주에 한 토픽만 콕 집어 학습합니다. 인원 일정이 비동기여도 결석한 사람이 따라잡기 쉽도록 각 주차는 독립적으로 설계되어 있습니다.

각 주차마다 **이번 주 목표 / 학습 체크리스트 / 면접 단골 Q&A 3개**가 준비되어 있습니다.

---

## 커리큘럼 인덱스

### 📡 Phase 1. 네트워크 (Week 1–5)

- Week 1. OSI/TCP-IP 계층 모델
- Week 2. TCP, UDP
- Week 3. HTTP / HTTPS
- Week 4. DNS, 로드밸런싱, CDN
- Week 5. 웹 인증 — 세션·쿠키·JWT·OAuth2 ⭐신설

### 🖥 Phase 2. 운영체제 (Week 6–10)

- Week 6. 프로세스와 스레드, 스케줄링
- Week 7. 가상 스레드·코루틴·동시성 모델 ⭐신설
- Week 8. 동기화와 데드락
- Week 9. 메모리 관리와 GC
- Week 10. 파일 시스템과 I/O 모델

### 🗄 Phase 3. 데이터베이스 (Week 11–15)

- Week 11. 관계형 모델과 정규화
- Week 12. 인덱스와 B+Tree
- Week 13. 쿼리 최적화와 EXPLAIN ⭐신설
- Week 14. 트랜잭션과 격리 수준
- Week 15. NoSQL, 분산 데이터베이스

### 🌱 Phase 4. 프레임워크 (Week 16–19) ⭐신설

- Week 16. Spring IoC·DI·Bean
- Week 17. Spring MVC·AOP·Filter/Interceptor
- Week 18. JPA — 영속성 컨텍스트와 N+1
- Week 19. Spring Boot — Auto-config·@Transactional·Actuator

### 🚀 Phase 5. 운영·시스템디자인 (Week 20) ⭐신설

- Week 20. CI/CD·Docker·옵저버빌리티·시스템디자인 베이직

> 전체 커리큘럼 상세 — [cs-study-curriculum.md](cs-study-curriculum.md)
> 재구성 근거 — `cs-obsidian/wiki/topics/curriculum-redesign-2026.md`

### 📖 HTML 문서 (사람용)

`.md` 파일은 AI/리뷰용, **HTML 문서는 사람이 보기 좋게** 정리한 버전입니다.

- 진입점: [`docs/html/index.html`](docs/html/index.html) — 20주 카드 인덱스
- 주차별: [`docs/html/weeks/`](docs/html/weeks/) — week-01 ~ week-20
- 로컬에서 열기: `docs/html/index.html`을 브라우저로 더블클릭 (별도 빌드 불필요)
- GitHub Pages 배포 시: Settings → Pages → `/docs` 또는 `main` 브랜치 `/docs/html` 지정

---

## 진도 트래킹

진도가 끝난 주차의 체크박스를 채워주세요.

### Phase 1. 네트워크
- [x] Week 1 — OSI/TCP-IP 계층 모델
- [x] Week 2 — TCP, UDP
- [x] Week 3 — HTTP / HTTPS
- [ ] Week 4 — DNS, 로드밸런싱, CDN
- [ ] Week 5 — 웹 인증 (세션·쿠키·JWT·OAuth2)

### Phase 2. 운영체제
- [ ] Week 6 — 프로세스와 스레드, 스케줄링
- [ ] Week 7 — 가상 스레드·코루틴·동시성 모델
- [ ] Week 8 — 동기화와 데드락
- [ ] Week 9 — 메모리 관리와 GC
- [ ] Week 10 — 파일 시스템과 I/O 모델

### Phase 3. 데이터베이스
- [ ] Week 11 — 관계형 모델과 정규화
- [ ] Week 12 — 인덱스와 B+Tree
- [ ] Week 13 — 쿼리 최적화와 EXPLAIN
- [ ] Week 14 — 트랜잭션과 격리 수준
- [ ] Week 15 — NoSQL, 분산 데이터베이스

### Phase 4. 프레임워크
- [ ] Week 16 — Spring IoC·DI·Bean
- [ ] Week 17 — Spring MVC·AOP·Filter/Interceptor
- [ ] Week 18 — JPA (영속성 컨텍스트·N+1)
- [ ] Week 19 — Spring Boot (Auto-config·@Transactional·Actuator)

### Phase 5. 운영·시스템디자인
- [ ] Week 20 — CI/CD·Docker·옵저버빌리티·시스템디자인

---

## 멤버별 정리 노트

[`members/`](members/README.md) — 각 멤버가 주차별 정리본을 작성하는 공간.

- 빈 템플릿: [`members/template.md`](members/template.md)
- 채워진 예시: [`members/example.md`](members/example.md)
- 멤버 폴더: [seonho](members/seonho/), [wooseung](members/wooseung/), [wodud](members/wodud/)

---

## 운영 방식

### 역할

- **발표자**: 해당 주차 주제를 조사·정리하여 발표 (매주 1명, 로테이션)
- **나머지 멤버**: 질문 준비 및 보완 자료 가져오기

### 주간 사이클

| 요일 | 활동 |
|:----:|------|
| 토 | Discord webhook 자동 공지 (이번 주 주제·키워드·발표자) |
| 토–수 | 각자 학습 및 정리 |
| 목 | 정리본 PR 업로드 (23:59 마감) → 서로 리뷰 / 코멘트 |
| 금 | 1시간 화상 토론 (21:00) + 다음 주 발표자 확정 |

### 시간 비동기 인원 대응 원칙

- 각 주차는 **독립적**으로 학습 가능 — 결석해도 다음 주 복귀가 쉬움
- 발표자가 빠질 가능성을 고려해 **2명 짝 발표** 또는 **녹화 공유** 백업
- 매 주차 끝에 **면접 단골 Q&A 3개**를 답안 형태로 PR에 포함 → 결석자가 따라잡을 때의 최소 학습 산출물

### PR 가이드

1. 본인 멤버 폴더에 [`members/template.md`](members/template.md) 복사 → `week{NN}-{주제}.md` 로 이름 변경 후 채우기
2. PR 제목: `[Week N] 주제명 - memberN`
3. 리뷰어: 나머지 멤버 전원 지정
4. 금요일 토론 전 머지

---

## Discord 채널 구조

| 채널 | 용도 |
|------|------|
| `#📢-주간-공지` | webhook 알림 (매주 토요일 자동 발송) |
| `#📚-자료-공유` | 참고 자료·링크 공유 |
| `#💬-토론` | 주간 토론 주제 논의 |
| `#🙋-질문` | 학습 중 생긴 질문 |

---

## 추천 도서 / 자료

**필수**

- *OSTEP* (Operating Systems: Three Easy Pieces) — 무료 PDF
- *컴퓨터 네트워킹 하향식 접근* (Kurose)
- *Designing Data-Intensive Applications* (Kleppmann)
- *토비의 스프링 3.1* (이일민)
- *자바 ORM 표준 JPA 프로그래밍* (김영한)

**참고**

- *Real MySQL 8.0*
- *Java Concurrency in Practice*
- *TCP/IP Illustrated Vol.1*
- *Java Performance* (Scott Oaks)
- [gyoogle/tech-interview-for-developer](https://github.com/gyoogle/tech-interview-for-developer)
- [JaeYeopHan/Interview_Question_for_Beginner](https://github.com/JaeYeopHan/Interview_Question_for_Beginner)
- [ksundong/backend-interview-question](https://github.com/ksundong/backend-interview-question)

**실습 도구**

- Wireshark / tcpdump (네트워크 주차)
- `strace`, `htop`, `iostat`, `perf`, `vmstat` (OS 주차)
- 로컬 MySQL / PostgreSQL + EXPLAIN (DB 주차)
- Spring Boot + H2 + Hibernate SQL 로깅 (프레임워크 주차)
- Docker, GitHub Actions (운영 주차)
