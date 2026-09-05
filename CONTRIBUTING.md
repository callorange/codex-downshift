# codex-downshift 기여 가이드 (Contributing)

`codex-downshift` 프로젝트에 관심을 가져주셔서 감사합니다!

본 프로젝트는 OpenAI Codex 환경에서 Sol 또는 Terra를 Active Parent로 유지하면서, Gate A → Gate B → Economic Gate와 Decision Authority에 따라 bounded execution 작업을 Terra (`gpt-5.6-terra`) 또는 Luna (`gpt-5.6-luna`) Child로 하향 위임하여 사용량과 비용을 절감하는 순수 마크다운 기반의 경량 스킬입니다. LOC·파일 수·단일 deterministic validation은 secondary signal이며, 준비·검증 오버헤드가 비슷하면 Parent Direct로 처리합니다.

---

## 🧭 1. 기여 시 준수해야 할 핵심 원칙

1. **경량 프롬프트 지향 (No Daemons / No Heavy Runtimes)**:
   - 핵심 동작을 위해 별도의 외부 런타임(Python/Node 데몬, 복잡한 설정 파일 등)을 추가하지 않습니다.
   - 모든 위임 로직은 프롬프트 주도적이며 Agent Skills 표준 형식을 유지합니다.
2. **부모 모델의 판단권 존중**:
   - 상위 수준의 추론, 사용자 의도 해석, 아키텍처 설계, 최종 결과 평가는 항상 부모 모델이 전담합니다.
3. **리프 워커 불변성 (Leaf Worker Invariant)**:
   - 하위 서브에이전트는 항상 리프 워커여야 하며, 추가 서브에이전트 생성이나 상위 모델로의 자동 에스컬레이션을 하지 않습니다.

---

## 🛠️ 2. 기여 방법

### 1) 위임 예시 추가 및 개선
- Gate·권한별 라우팅 사례는 [`delegation-examples.md`](skills/codex-downshift/references/delegation-examples.md), Child 반환·복구·예외 effort 사례는 [`terminal-scenarios.md`](skills/codex-downshift/references/terminal-scenarios.md)에 추가하거나 개선합니다.
- 하위 워커가 상위 추론을 다시 수행하지 않아도 되는 완결된(Self-Contained) Task Capsule 작성법을 잘 보여주는지 확인합니다.

### 2) 스킬 규칙 및 지침 개선
- 실제 Codex 환경에서의 동작 경험을 바탕으로 [`skills/codex-downshift/SKILL.md`](skills/codex-downshift/SKILL.md)의 규칙 개선을 제안합니다 (Issue 또는 Pull Request).

---

## 🔄 3. 핵심 문서 동기화

변경할 정책의 기준 문서를 먼저 확인합니다.

| 변경 대상 | 기준 문서 |
| --- | --- |
| 실행 규칙과 라우팅 계약 | [`SKILL.md`](skills/codex-downshift/SKILL.md) |
| 공식 요율·추정 지수·위임 비용 모델 | [`model-economics.md`](skills/codex-downshift/references/model-economics.md) |
| 외부 benchmark 관측 | [`model-benchmarks.md`](skills/codex-downshift/references/model-benchmarks.md) |
| 모델·effort 설정 추천 | [`model-selection.md`](skills/codex-downshift/references/model-selection.md) |
| Capsule·반환 서식 | [`task-capsule-template.md`](skills/codex-downshift/references/task-capsule-template.md) |
| 설치 절차 | [`README.md`](README.md) |

전체 관계는 [문서 인덱스](docs/README.md)를 참고합니다.

여러 문서에 영향을 주는 변경은 알려진 대상과 저장소 검색으로 발견한 직접 관련 대상을
completion set으로 관리합니다. 각 대상을 수정하거나 수정하지 않는 근거를 확인하고,
링크와 기존 계약이 유지되는지 재검색합니다.

모델·추론 레벨 표기는 `AGENTS.md`의 Project Rules를 따릅니다. 공식 요율과
Estimated Consumption Index의 기존 수치는 근거 없이 변경하지 않습니다.

---

## 📝 4. 커밋 메시지 규약 (Commit Convention)

본 프로젝트는 [Conventional Commits](https://www.conventionalcommits.org/ko/v1.0.0/) 규격을 준수합니다:

- `feat:` 새로운 기능 또는 새로운 참조 시나리오 추가
- `fix:` 프롬프트 규칙 버그 수정 또는 오류 정정
- `docs:` 문서 업데이트 (`README.md`, `docs/`, `CHANGELOG.md` 등)
- `refactor:` 동작 변화 없는 프롬프트 구조 정리 및 최적화

---

## 📄 5. 라이선스

본 프로젝트에 기여하는 모든 작업물은 [MIT License](LICENSE)에 따라 배포되는 데 동의하는 것으로 간주됩니다.

