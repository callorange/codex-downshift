# Model Selection Guide

이 문서는 공식 요율과 추정 소모 지수, 외부 benchmark, 실제 작업 비용을 함께 고려해
Parent 설정과 기존 downshift 후보의 reasoning effort를 선택하는 운영 지침이다.
공식·추정 비용 수치는 [Model Economics](model-economics.md), 원시 관측과 한계는
[Model Benchmarks](model-benchmarks.md)를 기준으로 한다.

Parent 설정 추천은 모델 자동 전환 기능을 정의하지 않는다. Child 후보와 권한은 이 문서의
`Downshift Child 선택 보완`을 참고하되, 실행 계약의 SSOT인 [SKILL.md](../SKILL.md)를 따른다.

## Recommendation Heuristics

### 비용 근거와 모델 추천의 역할

현재 같은 하네스의 비용·성능 비교는 [Benchmark Costs](benchmark-costs.md)의 공개 API USD/task와 비용 지수를 우선한다.
공식 크레딧 단가는 모델별 가격이고, API 비용은 해당 하네스의 사용량을 반영한 평균이며, 기존 ECI는 산출 재현 미확인 snapshot이다.
세 값을 같은 단위로 취급하지 않는다. 모델·effort가 높아져도 성능과 비용은 비례하지 않는다.

| 비교 | 동일 Codex 하네스 관측 | 선택에 미치는 영향 |
| --- | --- | --- |
| Luna Light → Medium | Index 25 → 42, API USD/task 0.04 → 0.09 | 고정 실행은 Light 우선; 탐색·복구·좁은 구현 선택에는 Medium의 품질 여유를 비교 |
| Luna High vs Terra Medium | Index 52 vs 48, API USD/task 0.18 vs 0.67 | 기존 ECI의 비용 순서와 다름. 승인된 High 예외의 유력 비교 후보지만 개별 작업 동급 품질을 보장하지 않음 |
| Terra Light → Medium | Index 39 → 48, API USD/task 0.39 → 0.67 | 일반 구현은 Medium을 출발점으로 유지; Light의 감소한 품질 여유와 재작업 비용 비교 |
| Terra High vs Sol Light | Index 55 vs 55, API USD/task 1.14 vs 1.29 | 같은 종합 점수가 같은 작업 적합성을 의미하지 않음; High Child는 승인 예외 |
| Sol Medium → High → XHigh | Index 62 → 64 → 63, API USD/task 2.19 → 3.00 → 3.74 | effort 증가가 단조로운 품질 향상을 보장하지 않음 |
| Astra Max vs Sol Max | Index 67 vs 65, API USD/task 4.72 vs 5.00 | Astra의 높은 단가가 반드시 높은 task 비용을 뜻하지 않음; 긴 실행 시간도 함께 비교 |

Intelligence Index와 Coding Agent Index는 다른 평가다. Astra의 Intelligence는 Light 49, Medium 52, High 53, XHigh 54, Max 55지만,
Coding Agent 비용은 Max만 확보되어 있어 effort별 비용 최적점을 추정하지 않는다.
점수를 성공확률로 환산하거나 비용으로 나눠 보편적인 효율 순위를 만들지 않는다.

### Downshift Child 선택 보완

권한은 먼저 Predetermined execution 또는 Implementation-local choice로 정한다.
아래는 능력·비용의 출발점이며 모델별 독점 권한이나 강제 경로가 아니다.
같은 권한을 더 저렴한 구성으로 충분히 수행할 근거가 있으면 그 후보를 비교한다.

| 작업 조건 | 우선 비교할 후보 | 판단 근거와 적용 경계 |
| --- | --- | --- |
| 구현 방법·target이 고정된 반복 실행 | Luna Light | 준비·검증 비용을 상쇄할 실행량이 있어야 함 |
| 고정 Rule의 bounded search·복구 | Luna Medium | Light보다 추가 추론이 누락·재작업을 줄일 근거 필요; 권한 확대 없음 |
| 고정 외부 계약 안에서 기존 패턴으로 좁혀지고 결정적으로 검증되는 구현 선택 | 선택이 남으면 Terra Light; Parent가 선택 규칙을 고정하면 Luna Medium | Luna Medium의 benchmark는 capability·비용의 보조 신호다. 현재 운영 권한은 Implementation Closed로 유지하며, Parent가 선택을 닫은 뒤 Luna 후보로 전환할 수 있음 |
| 일반 implementation-local 구현 | Terra Medium | 일반 구현의 비용/품질 균형 출발점; 충분한 다른 후보와 비교 |
| 여러 문서·계약·독립 요구사항의 정합성 실행 | Sol Light/Medium | 낮은 tier보다 검증·재작업 부담을 줄일 작업 근거 필요; 모든 상위 결정은 Parent 소유 |
| 여러 영역·도구·산출물의 장기 관계 실행 | Sol Light/Medium; Astra는 실험 후보 | Astra Light/Medium은 적격인 Astra Parent의 effort 하향만 가능하며, effort별 Coding Agent 비용·성능 근거가 부족함 |
| 사용자 승인 아래 높은 effort의 이점이 필요한 작업 | 해당 모델 High 이상 예외 | 모든 안전·권한·엄격한 하향 조건 유지; benchmark 우위만으로 자동 선택하지 않음 |

어떤 모델도 지시 준수·성공을 보장하지 않는다. Luna를 Active Parent로 사용하는 방식은 현재 지원 범위 밖이다.
Luna Medium의 일반 benchmark는 좁은 implementation-local 작업을 향후 통제 평가할 이유가 되지만, 그 평가 없이 운영 권한을 넓히는 직접 근거는 아니다.

### 같은 모델의 effort 하향

Astra·Sol·Terra 모두 특정 업무 분야에 한정하지 않고 다음 공통 조건을 적용한다.

1. runtime에서 실제 Parent model/effort를 확인하고 target이 엄격히 낮다.
2. Capsule의 작업 권한·acceptance를 낮은 effort가 충분히 수행할 근거가 있다.
3. 다른 적격 lower-model 후보 및 Parent Direct와 준비·실행·검증·재작업 비용을 비교해 위임 이점이 있다.

| 확인한 Parent effort | 자동 same-model 후보 |
| --- | --- |
| Light | 없음 |
| Medium | Light |
| High / XHigh / Max | Light 또는 Medium; 작업에 충분한 설정 비교 |
| 확인 불가 | 없음; 확인한 모델의 lower-model 후보만 평가 |

일반 구현도 이 조건을 충족하면 같은 모델 하향 후보가 될 수 있다. 모델 유지 자체는 근거가 아니다.
모든 후보에 Gate A와 Economic Gate를 적용하며, 공개 독립 실행 비용 차이를 위임 전체 절감률로 해석하지 않는다.

### 사용자 설정 추천

일반적인 구현 작업의 비용/품질 균형 기본 추천은 **Terra Medium**이다.
상위 판단과 정합성 유지가 중요한 아래 조건에서는 **Sol Medium을 우선 고려**하고,
Sol의 사용량 부담을 줄이려는 경우에는 **Sol Light를 절충안으로 고려**한다.
여러 영역·도구·산출물의 장기 관계를 다루는 가장 어려운 end-to-end 작업에서
Sol의 반복 실패나 높은 수동 개입 비용이 실제로 관측되면 **Astra Medium을 근거 제한적인 실험 후보로 고려**한다.
이는 사용자가 Parent 설정을 선택할 때의 조언이며, 현재 세션의 모델을 자동 전환하는 규칙이 아니다.

| 작업 조건 | Parent 추천 | 판단 근거와 적용 경계 |
| --- | --- | --- |
| 요구사항과 외부 계약이 명확하고 기존 패턴으로 진행하는 일반적인 구현 | **Terra Medium 기본** | Light보다 Coding Agent Index가 39에서 48로 높고 공개 API 비용은 task당 $0.39에서 $0.67로 증가한다. 일반 구현까지 Sol Medium을 기본 추천하지 않는다. |
| Terra를 사용하며 작업이 정형적이고 사용량 절감이 품질 여유보다 중요 | **Terra Light 고려** | Light의 점수와 재작업 가능성을 감수할 수 있을 때만 선택한다. 선택 폭과 검증 부담이 큰 구현에는 Medium을 출발점으로 삼는다. |
| 외부 계약은 고정됐지만 내부 설계·다중 파일 구현 난도가 실제로 높음 | **Terra High 고려** | Coding Agent Index가 Medium 48에서 High 55로 상승했다. 높은 effort의 추가 사용량보다 재작업 비용이 클 때 선택한다. |
| Sol의 판단 능력이 필요하지만 계약이 명확하고 사용량 부담을 줄여야 함 | **Sol Light 고려** | Intelligence 41·Coding Agent Index 55로 단순 구현에는 충분할 수 있다. Medium과 같은 정합성·재작업 비용을 전제하지 않는다. |
| 규칙·하네스·아키텍처 또는 여러 문서·계약의 정합성을 유지 | **Sol Medium 우선 고려** | Coding Agent Index 62로 High 64·Max 65에 가깝다. 독립 요구사항과 completion set을 추적할 판단 부담을 기준으로 삼는다. |
| Sol Medium에서 난도가 확인됐고 오류·재작업 비용이 추가 사용량보다 큼 | **Sol High 고려** | Coding Agent Index 상승은 62에서 64로 제한적이다. 어려운 구현·검증에서 추가 여유가 필요한 경우에만 선택하며 지시 준수를 보장하지 않는다. |
| Astra의 end-to-end 능력을 시험하며 effort 사용량을 낮추고 결정적 검증이 가능 | **Astra Light 실험 후보** | Intelligence는 49지만 동일 Codex 하네스의 비용·코딩 성능은 미확보다. Astra tier를 유지할 작업 근거가 있을 때만 제한적으로 시험한다. |
| 여러 영역·도구·산출물의 장기 관계를 추적하고 Sol의 재지시·재작업·검증 부담이 실제로 큼 | **Astra Medium 실험 후보** | `experimental / evidence-limited`. Medium의 동일 Codex 하네스 비용·성능 자료가 없으며 Astra Max의 token-efficiency를 일반화하지 않는다. |
| Medium에서 실제 난도나 실패가 확인되고 추가 사용량보다 실패 비용이 큼 | **High 고려** | 모델별 benchmark의 상승 폭과 작업 실패 증거를 함께 본다. 자동 Child target으로 사용하지 않는다. |
| XHigh·Max가 필요한 장기 추론이나 실패가 반복해서 관측됨 | **XHigh·Max 예외 고려** | 높은 effort의 한계효용이 작을 수 있다. Medium·High가 부족하다는 작업 근거 없이 기본값으로 사용하지 않는다. |

Sol Medium의 조건부 우선 고려는 이번 프로젝트의 실제 사용 경험을 반영한 **정성적 운영 휴리스틱**이다.
Astra Light/Medium은 `experimental / evidence-limited` 후보이며 기본 추천이 아니다.
Astra Max의 Coding Agent 성능·token-efficiency 관측을 Light나 Medium에 일반화하지 않는다.
위 비교표의 모든 모델·effort를 이번 작업에서 직접 비교 평가했다는 뜻은 아니다.
통제된 모델 비교나 측정된 재작업 감소율을 뜻하지 않으며, Sol Medium도 지시 준수를 보장하지 않는다.
추천 설정을 사용해도 요구사항·completion set과 결과를 대조하고, 완료 주장에 맞는 검증을 수행해야 한다.

### 실제 작업 비용

모델 사용량 외에 작업을 완료하는 데 드는 다음 부담을 함께 비교한다.

| 비용 요소 | 비교할 관찰 근거 |
| --- | --- |
| Model usage | Parent와 Child의 준비·실행·검증 및 재시도에 사용한 토큰·reasoning·tool/agent steps |
| Human steering | 사용자가 누락을 지적하고 의도·조건을 재설명하는 횟수와 소요 시간 |
| Rework | 누락·오해·계약 불일치로 다시 분석·수정해야 하는 범위와 반복 실행 |
| Verification | 결과를 요구사항 및 문서·계약과 대조하고 검사·재검사하는 노력 |

이는 크레딧과 사람의 시간을 동일 단위로 더하는 공식이 아니다.
[Model Economics의 비용 분해](model-economics.md#6-effective-downshift-economics-non-official-heuristics)에 사용자 부담과 반복 작업을 함께 고려하는 관점이며,
이미 실행·검증 비용에 포함된 재작업을 별도 비용으로 중복 합산하지 않는다.
추가 모델 사용량보다 재지시·재작업·검증 부담을 줄일 가치가 있다고 판단되면
Sol Medium을 고려할 수 있다. Astra Medium은 Sol의 부담이 실제로 관측되고 통제된 검증이 가능한 경우의 근거 제한적 실험 후보이며, 절감 효과를 보장하거나 Max 관측을 고정 배율로 환산하지 않는다.
실제 기록이 없으면 예상으로 구분하고, 관찰된 사용량과 사용자 개입·재작업을 바탕으로 추천을 재평가한다.

### Downshift 정책과의 관계

Parent 설정 추천 이후에도 실제 runtime에서 확인한 Active Parent를 기준으로
Gate A → Gate B → Economic Gate를 적용한다. 안전성·권한·검증 요건이 비용 판단보다 우선한다.

- Astra Parent는 Luna, Terra 또는 Sol로 model downshift하거나, 확인된 Parent effort보다 낮은 Astra Light/Medium으로 effort downshift할 수 있다.
- Sol Parent는 기존 조건에 따라 Luna 또는 Terra로 model downshift하거나, 확인된 Parent effort보다 낮은 Sol Light/Medium으로 effort downshift할 수 있다.
- Terra Parent는 Luna로 model downshift하거나, 확인된 Parent effort보다 낮은 Terra Light/Medium으로 effort downshift할 수 있다.
- 같은 모델의 동일·상위 effort와 상위 모델 호출은 허용하지 않는다. 자동 Child target은 Light 또는 Medium이며 High 이상은 사용자 승인 예외다.
- 같은 모델 경로는 위 공통 조건으로 판단하며 특정 작업 종류를 필수 조건으로 삼지 않는다. 모델·effort 선택은 이미 명시한 권한을 바꾸지 않는다.
- 실제 위임은 Delegation Preparation Test 네 조건을 모두 통과하고, 위임의 추가 부담이 실행 절감분을 상쇄하지 않을 때만 수행한다.

상위 판단은 Parent가 맡고, 그 판단으로 닫힌 bounded execution만 구성 기준으로 downshift하는 방식으로
Parent 설정과 위임 경제성을 함께 판단한다.
