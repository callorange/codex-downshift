# Reproducible Benchmark Costs

비용 비교를 재계산할 때 읽는 참조 자료다. 기존 ECI를 덮어쓰지 않고 같은 하네스의 공개 비용으로
별도 지수를 계산한다. 공식 크레딧 요율과 기존 ECI는 [Model Economics](model-economics.md),
성능 해석은 [Model Benchmarks](model-benchmarks.md), 선택 기준은 [Model Selection](model-selection.md)이 원본이다.

## 공개 입력과 계산 결과

관측일: **2026-09-05**. 출처: [Artificial Analysis Codex Model Variants](https://artificialanalysis.ai/agents/coding-agents/comparisons/codex-vs-grok-build#model-variants).
동일 Codex 하네스의 Coding Agent Index v1.4이며 비용·토큰·시간은 task당 평균의 공개 반올림 값이다.
아래 비용 지수는 프로젝트 계산값으로 `API USD/task ÷ Luna Light의 0.04 USD/task`다.
성공한 작업당 비용이나 Codex 구독 차감 지수가 아니다.

| 설정 | Coding Agent Index | Total tokens/task (M) | API USD/task | API 비용 지수 | Active minutes/task |
| --- | ---: | ---: | ---: | ---: | ---: |
| Luna Light | 25 | 1.4 | 0.04 | 1.00 | 1.7 |
| Luna Medium | 42 | 4.3 | 0.09 | 2.25 | 3.2 |
| Luna High | 52 | 9.6 | 0.18 | 4.50 | 5.7 |
| Luna XHigh | 53 | 12.8 | 0.24 | 6.00 | 6.9 |
| Luna Max | 57 | 16.0 | 0.29 | 7.25 | 8.0 |
| Terra Light | 39 | 1.7 | 0.39 | 9.75 | 2.6 |
| Terra Medium | 48 | 3.2 | 0.67 | 16.75 | 4.0 |
| Terra High | 55 | 5.6 | 1.14 | 28.50 | 6.0 |
| Terra XHigh | 56 | 6.6 | 1.36 | 34.00 | 6.7 |
| Terra Max | 60 | 9.6 | 1.93 | 48.25 | 8.2 |
| Sol Light | 55 | 3.2 | 1.29 | 32.25 | 3.5 |
| Sol Medium | 62 | 5.8 | 2.19 | 54.75 | 5.0 |
| Sol High | 64 | 8.0 | 3.00 | 75.00 | 6.2 |
| Sol XHigh | 63 | 9.9 | 3.74 | 93.50 | 7.3 |
| Sol Max | 65 | 13.2 | 5.00 | 125.00 | 10.2 |
| Astra Max | 67 | 4.0 | 4.72 | 118.00 | 26.8 |

Astra Light〜XHigh의 같은 하네스 비용은 미확보다. Max에서 effort별 값을 외삽하지 않는다.
Total tokens는 입력·캐시·출력의 합계이며 표에서 종류별 개수는 확보하지 못했다.
Active time은 환경 시작·verifier/judge 등 하네스 오버헤드를 제외한다.
API 비용에는 적용 가능한 cache-write 요율이 포함되며, 구독 요금이나 운영 인건비는 포함되지 않는다.
공개 반올림 값을 기준으로 재계산할 수 있지만 평가자의 원시 실행 로그를 재현한 것은 아니다.
낮은 기준 비용의 반올림 오차도 지수에 전파되므로 절대 비용을 함께 읽는다.

## Codex 크레딧으로 계산할 수 있는 범위

토큰 종류별 계수가 확보되면 표준 크레딧 계산은 다음과 같다.

```text
credits = (uncached_input × input_rate
         + cached_input × cached_rate
         + output × output_rate) / 1_000_000
relative_credit_index = credits / same_harness_baseline_credits
```

입력 합계에 cached input이 포함되면 먼저 분리한다. reasoning이 output에 이미 포함되면 다시 더하지 않는다.
cache write도 입력과 중복 집계하지 않으며 해당 계정·모드의 과금 정의를 확인한다.
Codex 표준 크레딧에는 별도 cache-write 요금이 없지만
[API 요금표](https://developers.openai.com/api/docs/pricing)에는 cache-write와 장문 요율이 있다.
따라서 API 비용에 일정 배수를 곱해 정확한 Codex 크레딧이라고 보고하지 않는다.

종류별 개수가 없고 총 토큰 수만 있으면 정확한 단가 적용은 불가능하다.
표준 요율만 적용된다는 가정 아래 `total × 최소 단가 / 1M`부터 `total × 최대 단가 / 1M`까지의
수학적 범위는 만들 수 있지만, 너무 넓어 후보를 구별하지 못하면 라우팅 근거로 쓰지 않는다.
임의의 cache 비율이나 평균 단가를 넣어 단일 ECI를 생성하지 않는다.

## 추천에 적용하는 방법

- Luna Medium은 Terra Medium보다 API 비용이 낮지만 점수도 낮다. 이 관측은 Luna Medium의 capability·비용 위치와 통제 평가의 보조 근거다. 다만 implementation-local choice 수행이나 권한 경계 준수를 직접 측정하지 않았으므로, 이 benchmark만으로 운영 권한을 자동 확대하지 않는다.
- Luna High는 Terra Medium보다 점수가 높고 API 비용이 낮다. 과거 ECI의 비용 순서와 다르므로 과거 지수를 현재 측정값보다 우선하지 않는다. High는 여전히 사용자 승인 예외다.
- Sol Medium → Light는 공개 API 비용이 약 41.1%, Terra Medium → Light는 약 41.8% 낮다. 이는 독립 실행 평균 차이이며 위임 전체 절감률이 아니다.
- Astra Max는 Sol Max보다 API 비용이 약 5.6% 낮고 점수가 2점 높지만 active time은 훨씬 길다. 토큰 수·단가·품질·시간이 비례한다는 가정을 하지 않는다.
- Astra Max의 token-efficiency를 Astra Light/Medium에 일반화하지 않는다. 동일 하네스 자료가 없는 Astra effort는 `experimental / evidence-limited`로 취급한다.

종합 점수를 성공확률로 간주하거나 비용으로 나눈 값을 보편적인 품질 순위로 쓰지 않는다.
다른 하네스의 토큰·점수를 이 표와 합산하지 않는다.

## 프로젝트 실측으로 보완할 항목

스킬의 실제 절감 효과는 아직 측정하지 않았다. 동등한 시작 상태와 acceptance를 유지한 독립 실행에서
Parent Direct, lower-model delegation, same-model lower-effort delegation을 비교한다.
스킬 자체의 준비 오버헤드를 확인할 때는 스킬을 사용하지 않는 직접 실행도 비교한다.
한 경로의 답이나 수정 결과를 다른 경로에 전달하지 않는다.

| 기록 | 비교 목적 |
| --- | --- |
| 작업·시작 revision·acceptance·하네스·모델/effort·요율 날짜 | 비교 조건 재현 |
| Parent 준비·Child 실행·Parent 검증 및 재시도의 종류별 토큰 | 전체 모델 비용; 중복 집계 방지 |
| acceptance별 통과·실패·미검증, 권한 위반 | 품질과 안전성 유지 확인 |
| 완료까지 전체 시간, human steering 횟수·시간, rework | 사용자 부담과 실제 완료 비용 비교 |

실패·미완료 실행도 비용 집계에 포함한다. 크레딧과 사람 시간을 임의 환산해 합산하지 않고 별도로 보고한다.
단일 성공 사례를 전체 작업군에 일반화하지 않는다. 반복 비교가 있으면 표본 수와 변동도 함께 기록한다.
새 snapshot은 출처·관측일·하네스 버전·원시 입력·계산식을 함께 보존한다.
