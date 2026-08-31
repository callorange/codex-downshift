# codex-downshift 기여 가이드 (Contributing)

`codex-downshift` 프로젝트에 관심을 가져주셔서 감사합니다!

본 프로젝트는 OpenAI Codex 환경에서 Sol 또는 Terra를 주력(부모) 모델로 유지하면서, 구체적으로 확정된 실행 작업만을 Luna (`gpt-5.6-luna`)에 위임하여 사용량을 절감하는 순수 마크다운 기반의 경량 스킬입니다.

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
- [`skills/codex-downshift/references/delegation-examples.md`](skills/codex-downshift/references/delegation-examples.md)에 실전 Good vs Bad 위임 시나리오를 추가하거나 개선합니다.
- 하위 워커가 상위 추론을 다시 수행하지 않아도 되는 완결된(Self-Contained) Task Capsule 작성법을 잘 보여주는지 확인합니다.

### 2) 스킬 규칙 및 지침 개선
- 실제 Codex 환경에서의 동작 경험을 바탕으로 [`skills/codex-downshift/SKILL.md`](skills/codex-downshift/SKILL.md)의 규칙 개선을 제안합니다 (Issue 또는 Pull Request).

---

## 📝 3. 커밋 메시지 규약 (Commit Convention)

본 프로젝트는 [Conventional Commits](https://www.conventionalcommits.org/ko/v1.0.0/) 규격을 준수합니다:

- `feat:` 새로운 기능 또는 새로운 참조 시나리오 추가
- `fix:` 프롬프트 규칙 버그 수정 또는 오류 정정
- `docs:` 문서 업데이트 (`README.md`, `docs/`, `CHANGELOG.md` 등)
- `refactor:` 동작 변화 없는 프롬프트 구조 정리 및 최적화

---

## 📄 4. 라이선스

본 프로젝트에 기여하는 모든 작업물은 [MIT License](LICENSE)에 따라 배포되는 데 동의하는 것으로 간주됩니다.

