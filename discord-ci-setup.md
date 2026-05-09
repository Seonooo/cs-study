# Discord 주간 알림 + 노트 파일 자동 생성 가이드

> GitHub Actions cron으로 매주 정해진 시간에 다음 두 작업을 자동 실행:
> 1. Discord 채널에 이번 주 스터디 주제 공지 (주차 README 링크 포함)
> 2. 각 멤버 폴더(`members/memberN/`)에 빈 노트 파일 생성 후 커밋·푸시
>
> 멤버는 매주 `git pull` → 자기 노트 파일 작성 → PR 의 흐름으로만 움직이면 됩니다.

---

## 전체 구조

```
study-repo/
├── .github/
│   └── workflows/
│       └── weekly-reminder.yml      # cron + Discord + scaffold
├── curriculum.json                  # 12주 메타 (한 파일)
├── templates/
│   └── discord-embed.jq             # 페이로드 빌더 (jq 필터)
├── members.json                     # 멤버 ID/이름/GitHub 매핑
├── members/
│   ├── README.md
│   ├── template.md                  # 노트 템플릿 ({{}} placeholder)
│   ├── example.md
│   ├── member1/
│   │   └── week01-osi-tcpip.md      # ← CI가 만들고, 본인이 채움
│   ├── member2/
│   └── member3/
├── network/                         # ← 학습 콘텐츠 (사람이 작성, 봇이 안 건드림)
├── os/
└── database/
```

**핵심 원칙:**

- 봇은 `members/memberN/` 폴더에만 노트 파일 생성. 학습 콘텐츠(`network/`, `os/`, `database/`)는 절대 안 건드림
- 12주 메타는 **`curriculum.json` 한 파일**에 모음. 변동되는 4–5개 필드(`topic`, `slug`, `keywords`, `goals`, `phase`) 만 작성
- Phase별 색상, 발표자 로테이션, 정리 위치 등은 **워크플로우가 자동 산출**

---

## 1. Discord webhook 만들기

1. Discord 서버에서 알림 받을 채널 (예: `#📢-주간-공지`) 우클릭 → **채널 편집**
2. 좌측 메뉴 **연동** → **웹후크** → **새 웹후크**
3. 이름과 아이콘 설정 (예: "CS Study Bot")
4. **웹후크 URL 복사** — 메시지 전송 권한이 있으니 절대 공개 저장소에 커밋하지 말 것

---

## 2. GitHub 설정

### 2-1. Secrets 등록

study repo → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**

| Name | Value |
|------|-------|
| `DISCORD_WEBHOOK_URL` | 1단계에서 복사한 URL |
| `STUDY_START_DATE` | 스터디 시작 월요일 (예: `2026-05-11`) |

### 2-2. Workflow 권한 (필수!)

**Settings** → **Actions** → **General** → **Workflow permissions**:

- ✅ **Read and write permissions** 선택
- ✅ "Allow GitHub Actions to create and approve pull requests" 체크 (선택)

이걸 안 하면 봇이 푸시할 때 `403 Permission denied` 발생.

---

## 3. 멤버 정보 — `members.json`

```json
{
  "members": [
    { "id": "member1", "name": "홍길동", "github": "gildong" },
    { "id": "member2", "name": "김철수", "github": "cheolsu" },
    { "id": "member3", "name": "이영희", "github": "younghee" }
  ]
}
```

| 필드 | 용도 |
|------|------|
| `id` | 폴더명 (`members/member1/`). 영문/숫자만 권장 |
| `name` | 한글 이름. 노트 파일 헤더와 Discord 발표자 표시에 사용 |
| `github` | GitHub username. PR 멘션·로테이션 산출에 사용 |

---

## 4. 노트 템플릿 — `members/template.md`

이미 존재. 봇이 sed 로 placeholder 를 치환:

| Placeholder | 치환되는 값 |
|------------|-----------|
| `{{WEEK_NUM}}` | 주차 두 자리 (예: `01`) |
| `{{TOPIC}}` | 주제 (예: `OSI/TCP-IP 계층 모델`) |
| `{{MEMBER_ID}}` | 멤버 폴더 ID (예: `member1`) |
| `{{MEMBER_NAME}}` | 멤버 한글 이름 (예: `홍길동`) |

수동 복사 시도 같은 placeholder 직접 치환.

---

## 5. 커리큘럼 메타 — `curriculum.json`

**12주 모두 한 파일에**. 주차마다 변동되는 5개 필드만 작성하면 나머지는 워크플로우가 자동 산출.

```json
{
  "weeks": [
    {
      "week": 1,
      "slug": "osi-tcpip",
      "phase": "network",
      "topic": "OSI/TCP-IP 계층 모델",
      "keywords": [
        "OSI 7계층 vs TCP/IP 4계층",
        "캡슐화",
        "L4/L7 로드밸런서",
        "HTTP/3"
      ],
      "goals": [
        "두 모델이 왜 다르게 나뉘었는지 설명",
        "\"URL 입력 시 일어나는 일\" 7계층 관점",
        "L4/L7 로드밸런서 차이",
        "HTTP/3가 UDP 위인 이유"
      ]
    }
    // ... week 2 ~ 12 동일 구조
  ]
}
```

### 필드 설명

| 필드 | 의미 | 예시 |
|------|------|------|
| `week` | 주차 번호 (정수) | `1` |
| `slug` | 폴더 슬러그 (kebab-case) | `osi-tcpip` |
| `phase` | `network` / `os` / `database` | `network` |
| `topic` | 한글 주제명 | `OSI/TCP-IP 계층 모델` |
| `keywords` | 핵심 키워드 배열 (3–5개 권장) | `["OSI 7계층", ...]` |
| `goals` | 이번 주 목표 배열 (4개 권장) | `["...", "...", ...]` |

### 자동 산출되는 부분

| 항목 | 산출 로직 |
|------|---------|
| **Phase별 색상** | `network`=파랑(`5814783`), `os`=초록(`5763719`), `database`=보라(`10181046`) |
| **주차 README URL** | `https://github.com/{repo}/blob/main/{phase}/week{NN}-{slug}/README.md` |
| **발표자** | `members.json` 의 멤버 수로 나눈 나머지 (week 1 → member1, week 2 → member2, ...) |
| **정리 위치** | `members/{본인폴더}/week{NN}-{slug}.md` |
| **footer** | `CS Study · Week N of 12` |

---

## 6. 페이로드 빌더 — `templates/discord-embed.jq`

`curriculum.json` + 자동 산출 값을 받아 Discord webhook 페이로드를 조립하는 jq 필터:

```jq
# templates/discord-embed.jq

{
  username: "CS Study Bot",
  embeds: [{
    title: ("📚 Week " + $week_num + ". " + $topic),
    description: ("이번 주 주제는 **" + $topic + "** 입니다.\n👉 [주차 README 바로가기](" + $readme_url + ")"),
    color: $color,
    fields: [
      { name: "🎯 핵심 키워드", value: $keywords },
      { name: "💡 이번 주 목표", value: $goals },
      { name: "❓ 꼬리 질문", value: "5개 (각 주차 README 참고)" },
      { name: "🎤 이번 주 발표자", value: $presenter },
      { name: "📁 정리 위치", value: ("`members/{본인폴더}/week" + $week_num + "-" + $slug + ".md`") },
      { name: "📅 일정", value: "정리본 PR: 목요일 23:59\n토론: 금요일 21:00" }
    ],
    footer: { text: ("CS Study · Week " + $week_num_raw + " of 12") }
  }]
}
```

**메시지 형식을 바꾸고 싶으면 이 파일 1개만 수정**하면 12주 모두 반영됩니다.

---

## 7. GitHub Actions 워크플로우

`.github/workflows/weekly-reminder.yml`:

```yaml
name: Weekly CS Study Reminder

on:
  schedule:
    # 매주 월요일 09:00 KST = 일요일 00:00 UTC
    - cron: '0 0 * * 1'
  workflow_dispatch:
    inputs:
      week:
        description: '강제로 실행할 주차 번호 (비우면 자동 계산)'
        required: false

permissions:
  contents: write    # members/ 변경사항 push 에 필요

jobs:
  notify-and-scaffold:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      # 1) 이번 주차 계산
      - name: Calculate current week
        id: week
        run: |
          if [ -n "${{ github.event.inputs.week }}" ]; then
            WEEK_INT="${{ github.event.inputs.week }}"
          else
            START_TS=$(date -d "${{ secrets.STUDY_START_DATE }}" +%s)
            NOW_TS=$(date +%s)
            WEEK_INT=$(( (NOW_TS - START_TS) / 604800 + 1 ))
          fi
          WEEK_PADDED=$(printf "%02d" $WEEK_INT)
          echo "int=$WEEK_INT"     >> $GITHUB_OUTPUT
          echo "padded=$WEEK_PADDED" >> $GITHUB_OUTPUT
          echo "📅 Week $WEEK_PADDED"

      # 2) curriculum.json 에서 메타 추출
      - name: Load week metadata
        id: meta
        run: |
          WEEK_INT="${{ steps.week.outputs.int }}"
          DATA=$(jq --argjson w "$WEEK_INT" '.weeks[] | select(.week == $w)' curriculum.json)
          if [ -z "$DATA" ] || [ "$DATA" = "null" ]; then
            echo "❌ curriculum.json 에 Week $WEEK_INT 항목 없음"
            exit 1
          fi
          echo "slug=$(echo "$DATA"   | jq -r '.slug')"     >> $GITHUB_OUTPUT
          echo "topic=$(echo "$DATA"  | jq -r '.topic')"    >> $GITHUB_OUTPUT
          echo "phase=$(echo "$DATA"  | jq -r '.phase')"    >> $GITHUB_OUTPUT
          # keywords / goals 는 별도 계산 (개행 처리)
          echo "$DATA" | jq -r '.keywords | join(", ")' > /tmp/keywords.txt
          echo "$DATA" | jq -r '.goals | map("• " + .) | join("\n")' > /tmp/goals.txt
          echo "📌 $(echo "$DATA" | jq -r '.topic')"

      # 3) Discord 페이로드 조립 + 전송
      - name: Build & send Discord notification
        env:
          WEBHOOK: ${{ secrets.DISCORD_WEBHOOK_URL }}
        run: |
          WEEK_INT="${{ steps.week.outputs.int }}"
          WEEK_PAD="${{ steps.week.outputs.padded }}"
          SLUG="${{ steps.meta.outputs.slug }}"
          TOPIC="${{ steps.meta.outputs.topic }}"
          PHASE="${{ steps.meta.outputs.phase }}"
          KEYWORDS=$(cat /tmp/keywords.txt)
          GOALS=$(cat /tmp/goals.txt)

          # Phase별 색상
          case "$PHASE" in
            network)  COLOR=5814783 ;;
            os)       COLOR=5763719 ;;
            database) COLOR=10181046 ;;
            *)        COLOR=0 ;;
          esac

          # 발표자 자동 로테이션
          MEMBER_COUNT=$(jq '.members | length' members.json)
          PRESENTER_IDX=$(( (WEEK_INT - 1) % MEMBER_COUNT ))
          PRESENTER_NAME=$(jq -r ".members[$PRESENTER_IDX].name" members.json)

          # 주차 README URL
          README_URL="https://github.com/${{ github.repository }}/blob/main/$PHASE/week${WEEK_PAD}-${SLUG}/README.md"

          # 페이로드 빌드 (jq 필터 사용)
          jq -n -f templates/discord-embed.jq \
             --arg week_num "$WEEK_PAD" \
             --arg week_num_raw "$WEEK_INT" \
             --arg topic "$TOPIC" \
             --arg slug "$SLUG" \
             --arg keywords "$KEYWORDS" \
             --arg goals "$GOALS" \
             --arg presenter "@$PRESENTER_NAME" \
             --arg readme_url "$README_URL" \
             --argjson color $COLOR \
             > /tmp/payload.json

          echo "📤 Sending payload:"
          jq . /tmp/payload.json

          # Discord 전송
          curl -X POST -H "Content-Type: application/json" \
               -d @/tmp/payload.json \
               "$WEBHOOK"

      # 4) 멤버별 노트 파일 scaffold
      - name: Scaffold note files
        run: |
          WEEK_PAD="${{ steps.week.outputs.padded }}"
          SLUG="${{ steps.meta.outputs.slug }}"
          TOPIC="${{ steps.meta.outputs.topic }}"

          # 이미 존재하는 파일은 절대 덮어쓰지 않음 (멱등성)
          jq -r '.members[] | "\(.id)\t\(.name)"' members.json | \
          while IFS=$'\t' read -r MEMBER_ID MEMBER_NAME; do
            DIR="members/$MEMBER_ID"
            FILE="$DIR/week${WEEK_PAD}-${SLUG}.md"

            mkdir -p "$DIR"
            if [ -f "$FILE" ]; then
              echo "⏭️  $FILE 이미 존재, 스킵"
              continue
            fi

            sed -e "s|{{WEEK_NUM}}|$WEEK_PAD|g" \
                -e "s|{{TOPIC}}|$TOPIC|g" \
                -e "s|{{MEMBER_ID}}|$MEMBER_ID|g" \
                -e "s|{{MEMBER_NAME}}|$MEMBER_NAME|g" \
                members/template.md > "$FILE"
            echo "✅ Created $FILE"
          done

      # 5) 변경사항 커밋 + 푸시
      - name: Commit and push
        run: |
          git config user.name "github-actions[bot]"
          git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
          git add members/
          if git diff --cached --quiet; then
            echo "변경사항 없음"
          else
            git commit -m "chore: scaffold week ${{ steps.week.outputs.padded }} note files"
            git push
          fi
```

### 동작 흐름

```
월요일 09:00 KST (cron)
   │
   ├─ 1. 시작일 기준 주차 계산 (예: Week 03)
   ├─ 2. curriculum.json 에서 Week 3 메타 추출
   ├─ 3. Phase 매핑 + 발표자 로테이션 + URL 조립
   ├─ 4. templates/discord-embed.jq 로 페이로드 빌드 → Discord 전송
   ├─ 5. members/{member1,member2,member3}/week03-{slug}.md 생성
   └─ 6. github-actions[bot] 명의로 커밋 + push
            │
            ▼
   각 멤버: git pull → 자기 .md 파일 작성 → PR
```

---

## 8. 테스트하기

### 8-1. 페이로드 빌드 단독 테스트 (로컬)

```bash
# Week 1 메타 추출
DATA=$(jq '.weeks[] | select(.week == 1)' curriculum.json)
SLUG=$(echo "$DATA" | jq -r '.slug')
TOPIC=$(echo "$DATA" | jq -r '.topic')
KEYWORDS=$(echo "$DATA" | jq -r '.keywords | join(", ")')
GOALS=$(echo "$DATA" | jq -r '.goals | map("• " + .) | join("\n")')

# 페이로드 빌드
jq -n -f templates/discord-embed.jq \
   --arg week_num "01" \
   --arg week_num_raw "1" \
   --arg topic "$TOPIC" \
   --arg slug "$SLUG" \
   --arg keywords "$KEYWORDS" \
   --arg goals "$GOALS" \
   --arg presenter "@홍길동" \
   --arg readme_url "https://github.com/owner/repo/blob/main/network/week01-osi-tcpip/README.md" \
   --argjson color 5814783

# Discord 로 직접 전송
... | curl -X POST -H "Content-Type: application/json" -d @- "$DISCORD_WEBHOOK_URL"
```

### 8-2. 전체 워크플로우 수동 실행

1. GitHub repo → **Actions** 탭 → **Weekly CS Study Reminder**
2. **Run workflow** 클릭
3. `week` 입력란에 `1` 입력 → 실행
4. 확인:
   - Discord 채널에 메시지 도착했는가?
   - `members/member1/week01-osi-tcpip.md` 등 멤버별 파일이 생성되었는가?
   - github-actions[bot] 의 커밋이 main 에 푸시되었는가?

### 8-3. 멱등성 확인

같은 주차로 한 번 더 실행 → Discord 메시지는 다시 가지만 (의도된 동작), 노트 파일은 "이미 존재, 스킵" 으로 건드리지 않음.

> 알림이 두 번 가는 게 싫다면 `Build & send Discord notification` 스텝에 `if: github.event_name == 'schedule'` 조건 추가.

---

## 9. 추가 확장 아이디어

기본 동작이 안정되면:

- **PR 머지 시 알림**: 멤버가 정리본 PR 을 merge 하면 Discord 에 "@홍길동 님이 Week 1 정리본 업로드" 메시지 (`pull_request` 트리거 별도 워크플로우)
- **D-1 리마인더**: 토요일 저녁에 "내일 토론입니다, 미제출자 확인" 알림 (별도 cron, members.json 순회하며 빈 파일/짧은 파일 체크)
- **진도 대시보드**: 일요일 아침에 "이번 주 제출 현황: 홍길동 ✅, 김철수 ✅, 이영희 ❌" 자동 집계
- **꼬리 질문 답변 분량 검증**: PR 트리거에서 정리본의 "꼬리 질문 답변" 섹션이 일정 글자 수 이하면 경고 코멘트
- **체크리스트 → GitHub Issue**: 주차 README 의 학습 체크리스트를 멤버별 GitHub Issue 로 자동 생성하여 진도 트래킹

---

## 트러블슈팅

| 증상 | 원인 / 해결 |
|------|------------|
| `403 Permission denied` (push 시) | Settings → Actions → General → Workflow permissions 를 "Read and write" 로 변경 |
| `remote: Permission denied` | 워크플로우의 `permissions: contents: write` 누락 |
| Discord 는 오는데 파일이 안 생김 | jq 로그 확인. `slug` 가 비어있는지 점검 |
| Discord 가 400 에러 반환 | `/tmp/payload.json` 을 `jq .` 로 출력해 JSON 형식 확인 |
| Actions 성공인데 Discord 메시지 없음 | webhook URL 만료/회수. Secret 재등록 |
| `429 Too Many Requests` | webhook 은 채널당 분당 30회 제한. 짧게 여러 번 호출하지 말 것 |
| cron 이 정시에 안 도는 것 같음 | GitHub Actions cron 은 부하 따라 최대 ~15분 지연 가능 (정상 동작) |
| 노트 파일이 잘못된 폴더에 생성됨 | `members.json` 의 `id` 가 실제 폴더명과 일치하는지 확인 (대소문자 주의) |
| `{{WEEK_NUM}}` 등이 치환 안 됨 | `members/template.md` 가 사라졌거나 placeholder 가 변형되었는지 점검 |
| `curriculum.json 에 Week N 항목 없음` | 새 주차 추가 시 `curriculum.json` 의 weeks 배열에 항목 추가 필요 |

---

## 참고: 주차 추가 시 작업

새 주차를 추가하려면 **`curriculum.json` 한 파일만** 편집:

```json
{
  "weeks": [
    ...,
    {
      "week": 13,
      "slug": "new-topic",
      "phase": "network",
      "topic": "새 주제",
      "keywords": [...],
      "goals": [...]
    }
  ]
}
```

그리고 해당 phase 폴더에 `week13-new-topic/README.md` 만 만들면 됩니다. 봇은 다음 주에 자동으로 멤버별 노트 파일을 만들고 Discord 알림을 보냅니다.
