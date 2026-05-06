# Phase 3. 데이터베이스 (Week 9–12)

> 백엔드 개발자가 알아야 할 데이터베이스 핵심을 4주에 걸쳐 다룹니다.
> 모델링 → 인덱싱 → 트랜잭션 → 분산 순으로 단일 DB에서 분산 환경까지 확장합니다.

---

## 주차별 인덱스

| Week | 주제 | 핵심 키워드 |
|:----:|------|------------|
| [**9**](week09-relational-normalization/README.md) | 관계형 모델과 정규화 | 1NF~BCNF, 함수 종속성, OLTP/OLAP, UUID v7 |
| [**10**](week10-index-query/README.md) | 인덱스와 쿼리 최적화 | B+Tree, Clustered Index, 복합 인덱스, EXPLAIN |
| [**11**](week11-transaction-isolation/README.md) | 트랜잭션과 격리 수준 | ACID, MVCC, Gap Lock, SSI, Write Skew |
| [**12**](week12-nosql-distributed/README.md) | NoSQL, 분산 데이터베이스 | CAP/PACELC, Quorum, Saga, Outbox |

각 주차 README에 `이번 주 목표 / 학습 체크리스트 / 꼬리 질문 5개(접이식 힌트)` 가 포함되어 있습니다.

---

## 학습 흐름

1. **Week 9** — 데이터를 어떻게 모델링할 것인가
2. **Week 10** — 모델링한 데이터를 어떻게 빠르게 검색할 것인가
3. **Week 11** — 동시 트랜잭션을 어떻게 다룰 것인가
4. **Week 12** — 단일 DB의 한계를 넘어 분산 환경에서는?

---

## Phase 종료 시 다시 볼 면접 핵심

- 정규화 단계 + 함수 종속성 → Week 9 Q1, Q2
- B+Tree + InnoDB Clustered Index 와 PK 설계 → Week 10 Q1, Q2 (Week 9 Q5와 연결)
- ACID와 격리 수준 매트릭스 → Week 11 Q1, Q2
- MVCC vs 락 기반 동시성 제어 → Week 11 Q3 (Week 6 Q5 와 연결)
- CAP / PACELC + Saga·Outbox 패턴 → Week 12 Q1, Q5

---

## 추천 자료

- *Designing Data-Intensive Applications* (Kleppmann) — 분산 DB의 정전
- *Real MySQL 8.0* — InnoDB 깊이 있는 한국어 자료
- *데이터베이스 시스템* (Silberschatz) — 정규화 이론
- 로컬 PostgreSQL / MySQL + EXPLAIN — 직접 실험
