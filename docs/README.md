# Project Documentation (docs/)

이 디렉터리는 `codex-downshift`의 설계 명세와 문서 탐색 진입점을 보관합니다.
현재 문서는 **v0.1.4 릴리스 기준선에 Unreleased 변경을 반영한 상태**입니다.

## 핵심 문서와 기준

| 문서 | 기준으로 삼는 내용 | 상태 |
| --- | --- | --- |
| [README.md](../README.md) | 사용자 소개, 설치·업데이트, 사용 흐름 | Current |
| [SKILL.md](../skills/codex-downshift/SKILL.md) | 에이전트 실행 규칙과 라우팅 계약 | Execution SSOT |
| [codex-downshift-spec.md](codex-downshift-spec.md) | 설계 의도, 정책 근거, 성공 기준 | v0.1.4 baseline + Unreleased |
| [model-economics.md](../skills/codex-downshift/references/model-economics.md) | 공식 요율, 추정 지수, 외부 평가, 사용자 설정 추천 | Economics reference |
| [task-capsule-template.md](../skills/codex-downshift/references/task-capsule-template.md) | Task Capsule과 Terminal Return Protocol 서식 | Runtime reference |
| [delegation-examples.md](../skills/codex-downshift/references/delegation-examples.md) | Gate·권한·반환 동작의 시나리오 | Behavioral reference |

문서 간 설명이 다르면 위 표의 담당 문서를 먼저 확인합니다.
`AGENTS.md`의 Project Rules는 저장소 문서의 표기 규칙을 정의하며 스킬의 런타임 정책을 대신하지 않습니다.

## 유지보수 원칙

1. 작업과 직접 관련된 문서만 읽어 Minimum Sufficient Context를 유지합니다.
2. 정책 변경 시 Known targets와 제한된 검색으로 발견한 직접 관련 문서를 completion set으로 관리합니다.
3. 실행 정책, 비용 근거, 서식, 설치 안내는 각각의 기준 문서에서 수정하고 다른 문서에는 필요한 요약과 링크만 둡니다.
4. 공식 요율과 보존된 Estimated Consumption Index를 변경할 때는 출처·관측일·재현 가능 범위를 함께 검토합니다.