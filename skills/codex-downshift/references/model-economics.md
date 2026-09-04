# Model Economics & Estimated Consumption Index

본 문서는 `codex-downshift` 스킬의 모델 라우팅, 추론 레벨 선택 및 비용 최적화 판단의 근거가 되는 공식 요율과 추정 소모 지수(Estimated Consumption Index)를 정리한 기술 참조 문서입니다.

---

## 1. OpenAI 공식 Token-Credit Rate

OpenAI가 공식 발표한 모델별 1M 토큰당 크레딧 단가입니다 ([OpenAI Help Center: credit-based usage](https://help.openai.com/en/articles/11481834) 기준).

| 모델 (Model) | Input (1M당) | Cached Input (1M당) | Output / Reasoning (1M당) |
| :--- | ---: | ---: | ---: |
| **Luna** (`gpt-5.6-luna`) | **5** | **0.5** | **30** |
| **Terra** (`gpt-5.6-terra`) | **50** (10×) | **5** (10×) | **300** (10×) |
| **Sol** (`gpt-5.6-sol`) | **100** (20×) | **10** (20×) | **500** (16.7×) |

---

## 2. Estimated Codex Consumption Index (예상 실질 소모 지수)

> [!IMPORTANT]
> 아래 값은 OpenAI가 공개한 Plus/Pro Codex allowance 공식 환산식이 아닙니다.
> OpenAI의 공식 token-credit rate와 Codex Radar / CursorBench의 공개 agent 사용량 관측치를 결합하여
> 설정 간 상대적인 비용 효율을 비교하기 위해 만든 **추정 상대 소모 지수(Estimated Consumption Index)**입니다.
> 실제 5시간/주간 allowance 감소율은 context 크기, cache 비율, output, reasoning,
> tool call, agent step, subagent 및 서버 측 metering 정책에 따라 달라질 수 있습니다.

### 모델별·추론레벨별 예상 상대 소모 지수 (기준: Luna Light = 1.00×)

| 모델 \ 추론 | Light (`low`) | Medium (`medium`) | High (`high`) | XHigh | Max |
| :--- | :---: | :---: | :---: | :---: | :---: |
| **Luna** | 🟢 **1.00×** | 🟢 **2.61×** | 🟢 **6.00×** | 🟡 **8.77×** | 🟠 **18.31×** |
| **Terra** | 🟢 **4.46×** | 🟢 **5.35×** | 🟡 **8.39×** | 🟠 **13.99×** | 🔴 **28.85×** |
| **Sol** | 🟡 **9.40×** | 🟠 **18.04×** | 🔴 **25.63×** | 🔴 **35.62×** | 🔴 **52.50×** |

---

## 3. 부모 기준선별 예상 상대 절감률 비교

절감률은 Active Parent의 reasoning effort 설정에 따라 달라집니다. Sol Medium을 단일 고정 baseline으로 삼지 않고, 실제 부모 모델 설정에 맞추어 비교합니다.

| 자식 설정 (Child Config) | 예상 소모 지수 | vs Sol Low (9.40×) 부모 | vs Sol Medium (18.04×) 부모 | 주요 적용 작업 |
| :--- | :---: | :---: | :---: | :--- |
| **Luna Low** | **1.00×** | **~89.4% lower** | **~94.5% lower** | 확정된 기계적 조립, 단위 테스트, 정형 린트/수정 |
| **Luna Medium** | **2.61×** | **~72.2% lower** | **~85.5% lower** | 구현 닫힘 + 경량 심볼/위치 로컬 탐색 |
| **Terra Medium** | **5.35×** | **~43.1% lower** | **~70.3% lower** | 로컬 알고리즘/클래스 내부 설계 (Sol Parent 전용) |

*(※ 모든 절감률은 Estimated Consumption Index 기준 추정치이며, 공식 allowance 보증치가 아닙니다.)*

---

## 4. Luna High vs Terra Medium 비교 및 Sol-Parent Golden Switch

### 1) CursorBench 3.2 관측 데이터
- **Luna High (`high`)**: Score **56.8%**, Agent Steps **40**, 예상 소모 지수 **6.00×**
- **Terra Medium (`medium`)**: Score **50.3%**, Agent Steps **20**, 예상 소모 지수 **5.35×**

### 2) 분석 및 라우팅 근거
- CursorBench 벤치마크 점수만 보면 Luna High가 Terra Medium보다 높게 나타날 수 있습니다.
- 그러나 Luna High는 예상 소모 지수가 Terra Medium보다 높고(6.00× vs 5.35×), 해결까지 요구하는 **Agent step이 2배(40 vs 20)**에 달합니다.
- 따라서 내부 알고리즘이나 클래스 구조 선택 등 Implementation-local decision이 필요한 작업에서는, Luna의 reasoning effort를 High로 올리는 것보다 **상위 티어 모델의 체급과 적은 step, 약간 더 낮은 예상 소모 지수를 갖춘 Terra Medium을 사용하는 것이 시간과 예상 allowance 효율 측면에서 훨씬 적합**합니다.

### 3) Golden Switching의 Parent별 적용 범위 (중요)
- **Sol Parent인 경우**:
  - `Implementation-Local Decision Remains` ➔ **Terra Medium Child**로 Golden Switch 적용 가능.
- **Terra Parent인 경우**:
  - Downshift Only 원칙(`Terra Parent ➔ Terra Child` 금지)에 따라 Terra Child를 생성할 수 없습니다.
  - 따라서 Terra Parent에서 구현 판단이 필요한 작업은 Golden Switch가 아니라 **Terra Parent Direct**로 직접 수행합니다.

---

## 5. 프롬프트 캐시 및 입력 토큰 단순 단가 비교

단순 공식 토큰 단가 기준의 캐시 읽기 예시입니다:

- **Sol 세션 (40,000 cached tokens)**:
  $$\frac{40,000}{1,000,000} \times 10 = \mathbf{0.4\text{ credits}}$$
- **Luna 독립 워커 (3,000 uncached input tokens)**:
  $$\frac{3,000}{1,000,000} \times 5 = \mathbf{0.015\text{ credits}}$$
- **비율**:
  $$\frac{0.4}{0.015} \approx \mathbf{26.67\times}$$

> [!NOTE]
> 해당 입력 부분만 단순 비교하면 약 26.7배 차이가 납니다.
> 단, 실제 작업 전체 비용은 output, reasoning, 추가 tool call 및 반복 agent step에 따라 달라지므로,
> "세션 전체가 항상 26배 저렴하다"고 해석해서는 안 됩니다.

---

## 6. Sources & Snapshot

Snapshot date: **2026-09-03**

### Official Codex credit-rate source
- OpenAI ChatGPT / Codex credit-based usage rate card
  - https://help.openai.com/en/articles/11481834
  - Codex의 모델별 Input / Cached Input / Output token-credit rate 확인에 사용

### API pricing reference
- OpenAI API Pricing
  - https://developers.openai.com/api/docs/pricing
  - API dollar pricing 참고용
  - Codex Plus/Pro 포함 allowance 차감 공식의 직접 근거가 아님

### Observed agent usage / benchmark sources
- Codex Radar
  - https://codexradar.com/
  - 모델 및 reasoning effort별 agent token usage / steps 관측치
- CursorBench 3.2
  - https://cursor.com/evals
  - 모델 및 reasoning effort별 score / token usage / agent steps 관측치

### Interpretation note
`Estimated Codex Consumption Index`는 위 공식 token-credit rate와 공개 benchmark / agent usage 관측치를 조합한 상대 비교용 추정치입니다.

OpenAI가 공개한 Plus/Pro의 5시간 또는 주간 allowance 공식 차감 배율이 아니며, benchmark 결과나 Codex metering 정책이 변경되면 지수를 다시 계산해야 합니다.

## 7. Effective Downshift Economics (Non-official Heuristics)

공식 token-credit 요율과 위 Estimated Consumption Index 표는 변경하지 않는다. 다음은 라우팅 판단을 위한 운영 모델이며 allowance 보장이 아니다.

**Effective Downshift Cost** = Parent Delegation Preparation + Child Execution + Parent Verification

**Parent Direct Cost** = Parent Analysis + Parent Implementation + Parent Validation

### 준비 비용과 위임 판단

**준비 비용**

Parent preparation의 output/reasoning이 child prompt 비용을 초과할 수도 있다.
과도하게 상세한 Capsule은 savings를 없앤다.

**위임 조건**

위임은 child가 대체하는 실행량이 부모의 준비·검증 오버헤드보다 materially 클 때만 경제적이다.
시키는 데 드는 일이 직접 하는 일과 비슷하면 위임하지 않는다.

### 저비용 Delegation Preparation Test

1. Parent가 goal, scope, fixed decisions, acceptance를 이미 알고 있는가?
2. Child task 준비에 direct execution과 비교 가능한 분석이 필요하지 않은가?
3. Child가 의미 있는 bounded search, 반복, 구현 또는 test/fix work를 대체하는가?
4. Parent preparation plus verification이 대체되는 execution보다 명확히 작은가?

네 질문 모두 예일 때만 위임한다. 하나라도 아니면 Parent Direct.

### 휴리스틱의 의미와 적용 우선순위

**비공식 잠정 운영 휴리스틱 (Provisional Operational Heuristic)**

- Luna가 고정 실행량 약 **2×** leverage를 낼 수 있다는 뜻일 뿐이다.
- Terra가 구현-local 분석+구현+검증량 약 **3×** leverage를 낼 수 있다는 뜻일 뿐이다.

**권한 판정 우선**

Luna/Terra 선택은 이 heuristic이 아니라 Gate A와 Gate B의 권한 판정이 우선이다.

**보조 신호**

LOC는 secondary reference이며, 단일 deterministic validation은 trigger가 아니고 예상되는 test/fix loop는 높은 위임 가치 신호다.

이는 공식 break-even 또는 token formula가 아니며, 실제 로그가 쌓이면 재검토한다.
