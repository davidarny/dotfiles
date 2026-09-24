# Mostbet Review Comment Format

Apply [unslop](../../unslop/SKILL.md) to every human-facing review text. The rules below describe defect comments, not a mandatory template for all review outcomes.

## Outcome notes

For an authorized review summary with no findings, state the outcome and the concrete behavior or completed checks supporting it. Choose short prose, bullets, or [show-me](../../show-me/SKILL.md) when a visual helps. Explain the result in the reader's terms and use descriptive evidence links where useful. Keep the investigation ledger private. The defect headline and `Фикс:` sections do not apply to a clean review summary.

## Defect comments

Write one self-contained Russian comment per validated finding.

## Required structure

````markdown
**<Конкретный дефект и его последствие>**

<Где находится проблема: `path:line`, символ или ветка. Что именно делает текущий код.>

<Какой достижимый сценарий запускает проблему и к какому наблюдаемому эффекту приводит. При необходимости — почему существующий guard/test/fallback не помогает.>

Фикс: <минимальное направление исправления>.

```tsx
<короткий пример исправления>
```
````

Include the code block when it makes the correction clearer. A short, unambiguous prose fix needs no illustrative patch.

## Headline

Use a bold factual statement. Include the consequence when it improves precision.

Good:

- `**Колбэк читает устаревшую запись батча и запускает загрузку после выхода из viewport**`
- `**Под feature flags fallback становится null, поэтому блок снова схлопывается при гидрации**`
- `**Имя пропа уже фактической области применения и скрывает общий fallback**`

Avoid:

- `**Проблема с observer**`
- `**Возможный баг**`
- `**Можно улучшить**`
- severity prefixes such as `[P1]`;
- questions in the headline.

## Evidence narrative

Write a compact causal chain:

```text
changed code → reachable trigger → incorrect state/behavior → user or system impact
```

Use:

- exact paths and current line numbers;
- the exact Jira requirement or artifact when the defect is requirement-specific;
- backticked identifiers, flags, values, and component names;
- concrete state sequences such as `[enter, leave]`;
- actual row counts, defaults, and return values when relevant;
- the precise reason an existing guard or test is insufficient.

Do not:

- dump the private validation checklist;
- cite an artifact that was only listed but not inspected;
- speculate about unsupported future changes;
- cite a path without explaining the behavior;
- use vague impact language;
- repeat the same finding across multiple lines;
- mention that an AI generated or co-authored the comment.

## No service commentary

The published comment contains only the defect, evidence, impact, and fix. Never add prefaces, suffixes, or asides about the review process, comment placement, fallbacks, or tooling behavior.

Keep any operational context needed by the user in the completion report, never in the MR discussion.

## Fix section

Start with the literal prefix `Фикс:`.

The fix should be:

- minimal;
- consistent with repository patterns;
- directly tied to the proven cause;
- safe for the branches discussed in the evidence;
- concise enough to review inline.

Prefer a focused snippet over a large patch. Do not present a broad refactor as mandatory when a local correction solves the defect.

### Snippet quality

The author reads the snippet as the shape to copy, so write it the way the file would hold it.

- Establish the repository's convention by counting current usage rather than by recall. Naming of module constants, named types versus inline shapes, and file placement all vary per repo, and `code-style/` plus `eslint.config.mjs` frequently document none of them. Report the count when the user questions the choice.
- Give every object, array, or schema its own line per entry. A declaration collapsed onto one line hides the shape the comment is asking for.
- Name each nested literal the fix would extract, including the ones the defect did not mention. A snippet that extracts one nested block and leaves its siblings inline contradicts its own `Фикс:`.
- Run a snippet whose correctness depends on library behavior, then keep the result private unless the user asks. Extraction that silently changes a generated value turns the fix into a new defect.

## Full example

````markdown
**Колбэк читает только первую запись батча и запускает загрузку по устаревшему состоянию**

`IntersectionObserver` передаёт в callback массив записей, но `lazy-on-visible.tsx:33` разбирает только `entries[0]`. Если в одном батче приходит `[enter, leave]`, код видит только `enter`, ставит таймер и через 100 мс рендерит контент, хотя элемент уже вышел из viewport. Это сохраняет тот же сценарий ложной загрузки, который должна отфильтровать задержка.

Фикс: брать последнюю запись батча как актуальное состояние и сбрасывать pending timeout перед новой проверкой.

```tsx
const observer = createIntersectionObserver(entries => {
  const entry = entries[entries.length - 1];

  if (visibilityConfirmationTimeout !== undefined) {
    clearTimeout(visibilityConfirmationTimeout);
    visibilityConfirmationTimeout = undefined;
  }

  if (!entry?.isIntersecting) {
    return;
  }

  // ...
}, options);
```
````

## Concision rules

- Prefer two evidence paragraphs or fewer.
- Keep the title to one line.
- Keep the code example to the smallest meaningful hunk.
- Omit background the author already knows unless it proves causality.
- Do not add greetings, praise, summaries, or sign-offs.

## Plain Russian

The author reads the comment once, between other tasks. Write so one pass is enough.

- One idea per sentence. A sentence carrying a location, a mechanism, and a consequence at once splits into three.
- Put the subject and verb first, then the qualifiers. A clause chain before the main verb makes the reader hold everything in memory before learning what the sentence is about.
- Choose the plain verb: `проверяет` over `утверждает состояние`, `делает` over `осуществляет`, `нужен` over `используется потребителем`.
- State the point directly instead of contrasting it with something nobody claimed. `Замер идёт в раннере` beats `Замер идёт не в браузере, а в раннере`.
- Keep punctuation to periods, commas, and colons, matching [unslop](../../unslop/SKILL.md).
- Reach for [humanizer](../../humanizer/SKILL.md) when a drafted comment runs long or reads like a specification.

Compare:

> Из четырёх мест прежнее значение обязательно только у `mobileOpen`: строку `mobile-filter-button` читает существующий unit-тест, и переименование его сломает, а у `desktopRoot` и `banners.root` потребителей нет, поскольку прежний `data-testid` удалён из компонентов в этом же MR.

> Старое значение кому-то нужно только у `mobileOpen`: строку `mobile-filter-button` читает `mobile-filter.test.tsx:191,201`. У `desktopRoot` и `banners.root` потребителей нет вообще, старый `data-testid` удалён из компонентов здесь же.

## Pre-publication text check

Before posting, confirm:

- the headline states exactly one validated defect;
- every factual assertion is supported by the validation record;
- all paths and line numbers match the current head;
- the trigger and impact are explicit;
- `Фикс:` addresses the proven cause;
- the snippet compiles conceptually and does not contradict repository conventions;
- no hedging words hide missing evidence;
- no sentence contains service commentary unrelated to the finding itself;
- no AI attribution or internal reasoning appears.
