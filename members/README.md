# Members

각 멤버는 자신의 폴더에 주차별 정리본을 작성하고 PR로 올립니다.

---

## 멤버 목록

- [seonho](seonho/)
- [wooseung](wooseung/)
- [wodud](wodud/)

---

## 작성 흐름

1. 주차 시작 → [`template.md`](template.md) 를 자기 폴더에 복사
2. 파일명 변경 → `week{N:02d}-{주제}.md` (예: `week01-osi-tcpip.md`)
3. 채우기 → 어느 정도 분량으로 어떻게 쓸지 모르겠으면 [`example.md`](example.md) 참고
4. PR 올리기 → 제목 형식: `[Week N] 주제명 - memberN`

---

## 파일명 규칙

```
week01-osi-tcpip.md
week05-process-thread.md
week11-transaction-isolation.md
```

`week` + 두 자리 숫자 + 하이픈 + kebab-case 주제. 폴더명과 일치시키면 정렬·매칭이 쉬움.

---

## PR 가이드

- **제목**: `[Week N] 주제명 - memberN`
- **리뷰어**: 나머지 멤버 전원 지정
- **머지 시점**: 해당 주차 금요일 토론 전까지

---

## 무엇을 어디에서 찾나

| 자료 | 위치 |
|------|------|
| 빈 템플릿 (복사 시작점) | [`template.md`](template.md) |
| 채워진 예시 (분량·스타일 기준) | [`example.md`](example.md) |
| 주차별 학습 목표·꼬리 질문 | `../network/`, `../os/`, `../database/` 의 각 주차 README |
| 전체 운영 방식·일정 | [`../README.md`](../README.md) |
