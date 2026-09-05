# Model Benchmarks

이 문서는 `codex-downshift`의 모델·추론 레벨 선택에 참고하는 외부 평가를
point-in-time snapshot으로 보존한다. 점수, token, 비용과 step은 각 출처의 평가 조건에
묶인 관측값이며, [Model Economics](model-economics.md)의 공식 요율이나 Estimated
Consumption Index를 재계산하지 않는다. 추천에 적용한 해석은
[Model Selection Guide](model-selection.md)를 따른다.

## External Evaluation Data

확인일: **2026-09-05**. 아래 관측 기록은 [Model Economics](model-economics.md)의 **2026-09-03 요율·추정 지수 snapshot**과 별도다.
기존 공식 Token-Credit Rate와 Estimated Consumption Index 수치를 재계산하거나 대체하지 않는다.

### Artificial Analysis: 추론 레벨별 성능

출처: [Luna release](https://artificialanalysis.ai/models/releases/gpt-5-6-luna),
[Terra release](https://artificialanalysis.ai/models/releases/gpt-5-6-terra),
[Sol release](https://artificialanalysis.ai/models/releases/gpt-5-6-sol),
[Codex Coding Agent 비교](https://artificialanalysis.ai/agents/coding-agents/comparisons/codex-vs-grok-build),
[Coding Agent Index 방법론](https://artificialanalysis.ai/methodology/coding-agents-benchmarking/).
사용자가 지정한 비교 화면을 **2026-09-05**에 확인한 point-in-time snapshot이다.

Artificial Analysis Intelligence Index v4.2는 지식·추론·코딩·도구 사용을 포함한 복합 지표다.
높을수록 좋으며, Codex 하네스의 구현 성능만을 뜻하지 않는다.

| 모델 | Light | Medium | High | XHigh | Max |
| --- | ---: | ---: | ---: | ---: | ---: |
| Luna | 34 | 39 | 47 | 50 | 52 |
| Terra | 41 | 47 | 50 | 53 | 57 |
| Sol | 51 | 56 | 57 | 59 | 61 |

Artificial Analysis Coding Agent Index v1.4는 Codex 하네스에서 DeepSWE,
Terminal-Bench v2.1, SWE-Atlas-QnA의 pass@1을 결합한다. 아래 셀은
`Coding Agent Index / task당 token`이며 점수는 높을수록 좋고 token은 낮을수록 경제적이다.

| 모델 | Light | Medium | High | XHigh | Max |
| --- | ---: | ---: | ---: | ---: | ---: |
| Luna | 25 / 1.4M | 42 / 4.3M | 52 / 9.6M | 53 / 12.8M | 57 / 16M |
| Terra | 39 / 1.7M | 48 / 3.2M | 55 / 5.6M | 56 / 6.6M | 60 / 9.6M |
| Sol | 55 / 3.2M | 62 / 5.8M | 64 / 8.0M | 63 / 9.9M | 65 / 13.2M |

Coding Agent task당 token은 입력·cached input·cache write·reasoning·output을 포함한
benchmark 평균이다. Codex 구독 allowance나 이 프로젝트의 Estimated Consumption Index와
단위·표본이 다르므로 서로 환산하지 않는다. 페이지는 일부 endpoint에서 평가 후 content safety
filtering 증가를 관측했다고 알리므로 작은 차이를 확정적 모델 순위로 해석하지 않는다.

### CursorBench 3.2

출처: [CursorBench 결과와 산정 방식](https://cursor.com/evals).
실제 Cursor 세션에서 가져온 모호한 다중 파일 작업 평가다.
원문의 Low는 이 프로젝트의 표시 명칭 Light로 표기한다.

| 설정 | Score | 비용/작업 | Tokens | Steps |
| --- | ---: | ---: | ---: | ---: |
| Sol Light | 52.6% | $1.01 | 5,104 | 19 |
| Sol Medium | 60.0% | $1.95 | 9,747 | 27 |
| Terra Light | 46.9% | $0.42 | 5,312 | 19 |
| Terra Medium | 50.3% | $0.49 | 6,222 | 20 |
| Luna Light | 37.6% | $0.03 | 3,209 | 17 |
| Luna Medium | 47.7% | $0.08 | 7,095 | 28 |
| Luna High | 56.8% | $0.16 | 15,141 | 40 |

비용은 사용 토큰에 공개 가격을 적용한 값이다. Tokens는 원문의 지표명이며 Codex 구독 사용량과 동일시하지 않는다.
작은 점수 차이는 통계적으로 유의하지 않을 수 있다.

**선택에 대한 해석**: Sol Light는 Medium보다 Tokens가 약 47.6% 적고 점수는 7.4%p 낮다.
이는 사용량 절충안을 지지하지만 동일 품질을 보장하지 않는다.
Luna High와 Terra Medium의 금전 비용·추정 지수상 순위가 다르므로, 비교 기준을 명시해야 한다.

### Instavar: Codex 모델·effort 실험

출처: [294 Codex Runs Explained](https://instavar.com/research/agents/gpt-5-6-codex-models-reasoning-levels-benchmark-2026), 게시일 **2026-08-01**.

294회 실행 기록 중 결함 있는 평가 조건에 해당하는 50개 기록을 제외했으며,
수정된 공통 정책 비교에는 210개 기록을 사용했다. 294개 전체를 유효 공통 비교로 취급하지 않는다.

| 공통 비교 설정 | 통과 | 통과 결과당 평균 시간 | 통과 결과당 입력 토큰 |
| --- | ---: | ---: | ---: |
| Medium | 42/42 | 35.61초 | 54,478 |
| High | 42/42 | 37.54초 | 58,591 |
| XHigh | 42/42 | 47.17초 | 66,298 |
| Max | 42/42 | 57.11초 | 72,143 |

위 값은 모델별 값이 아닌 공통 비교의 effort별 집계다.
연구자는 유효 과제들이 대체로 쉬워 모델 간 우열을 구분하지 못했다고 명시한다.
높은 effort를 일률적으로 선택할 근거가 부족하다는 참고는 되지만,
어려운 아키텍처·정합성 작업에서도 Medium이면 충분하다는 근거는 아니다.
입력 토큰만으로 전체 모델 비용을 계산하지 않는다.

### Sonar: 기능 통과율과 코드 품질

출처: [GPT-5.6 Sol & Terra 평가](https://www.sonarsource.com/blog/openai-gpt-5-6-sol-and-terra/).

4,444개 과제의 기능 통과율은 Sol 81.99%, Terra 79.96%였으며,
버그·취약점·복잡도 등도 별도로 평가했다.
기능 통과율만으로 검토·유지보수 부담을 판단하지 않아야 한다는 참고 자료다.
이 기록을 Light와 Medium의 직접 비교 근거로 사용하지 않는다.

### 적용 경계

외부 benchmark 관측, 프로젝트의 추정 지수, 운영 경험을 구분한다.
어느 자료도 이 프로젝트에서 사용자 재지시 비용을 포함한 동일 모델 Medium → Light Child 위임의 순절감을 측정하지 않았다.
따라서 외부 점수만으로 lower-model과 same-model lower-effort 경로의 우선순위나 권한을 결정하지 않는다. 같은 모델 effort 하향도 엄격한 구성 하향, 고정된 Parent 권한, Economic Gate를 모두 충족해야 한다.
