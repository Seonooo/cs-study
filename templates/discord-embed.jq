# Discord webhook 페이로드 빌더
#
# 사용:
#   jq -n -f templates/discord-embed.jq \
#     --arg week_num "01" \
#     --arg week_num_raw "1" \
#     --arg week_total "20" \
#     --arg topic "OSI/TCP-IP 계층 모델" \
#     --arg slug "osi-tcpip" \
#     --arg keywords "OSI 7계층, 캡슐화, ..." \
#     --arg goals "• 목표1\n• 목표2\n• 목표3" \
#     --arg presenter "@홍길동" \
#     --arg doc_url "https://{owner}.github.io/{repo}/weeks/week-01.html" \
#     --argjson color 5814783
#
# 출력: Discord webhook 으로 그대로 POST 가능한 JSON

{
  username: "CS Study Bot",
  embeds: [{
    title: ("📚 Week " + $week_num + ". " + $topic),
    description: ("이번 주 주제는 **" + $topic + "** 입니다.\n👉 [📖 HTML 문서 보기](" + $doc_url + ")"),
    color: $color,
    fields: [
      { name: "🎯 핵심 키워드", value: $keywords },
      { name: "💡 이번 주 목표", value: $goals },
      { name: "❓ 면접 단골 Q&A", value: ("3개 — [HTML 문서](" + $doc_url + ")의 «면접 단골 Q&A» 섹션 참고") },
      { name: "🎤 이번 주 발표자", value: $presenter },
      { name: "📁 정리 위치", value: ("`members/{본인폴더}/week" + $week_num + "-" + $slug + ".md`") },
      { name: "📅 일정", value: "정리본 PR: 목요일 23:59\n토론: 금요일 21:00" }
    ],
    footer: { text: ("CS Study · Week " + $week_num_raw + " of " + $week_total) }
  }]
}
