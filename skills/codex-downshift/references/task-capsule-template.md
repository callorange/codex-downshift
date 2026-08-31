# Task Capsule Template (Standard Markdown Format)

부모 모델(Sol/Terra)이 하위 워커(Luna 등)에 실행 작업을 위임할 때 복사하여 작성하는 표준 프롬프트 서식입니다.

---

```text
Role:
You are a leaf execution worker.

Goal:
[작업을 통해 완성해야 하는 명확한 단일 목표]

Target:
- Code: [수정할 파일 경로 및 심볼/함수/클래스]
- Test: [수정 또는 추가할 테스트 파일 경로]

Decisions already made:
- [부모 모델이 이미 확정한 아키텍처/로직/알고리즘 규칙 1]
- [부모 모델이 이미 확정한 세부 인터페이스 규칙 2]

Exact change:
[하위 워커가 즉시 반영할 수 있는 구체적인 코드 스니펫 또는 명확한 치환 지시]

Preserve:
- [반드시 유지해야 하는 기존 동작 및 호환성]
- [유지해야 하는 타입 힌트, 주석, 네이밍 규칙]

Do not touch:
- [작업 범위 밖의 파일 및 모듈]

Acceptance criteria:
- [ ] [완료 조건 1]
- [ ] [완료 조건 2]

Validation:
[실행할 정량 검증 명령어 (예: pytest tests/test_foo.py && ruff check foo.py)]

Escalation condition:
If the task requires a new semantic, behavioral, architectural,
or scope decision, stop immediately and return NEEDS_PARENT_DECISION.

Worker constraints:
- Do not spawn or delegate to other agents.
- Do not invoke a more capable model.
- Do not broaden the task.
- Stop when the acceptance criteria are satisfied.
```
