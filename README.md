# The Iron Covenant / «Железный Завет» — Godot scaffold

Рабочее название проекта. 2D single-player roguelike deckbuilder под Godot 4.7.x.

## Product vision

Игра сочетает:
- физичность и тревожную «настольную» подачу карточной игры;
- комбо-ориентированную реиграбельность и возможность собирать намеренно «сломанные» билды;
- стимпанк-антиутопию;
- чёрный юмор на теме бюрократии, индустриального контроля, труда, долгов, пропаганды и человеческих пороков;
- ключевой hook: **слабость, проклятие или порок сначала мешают игроку, а затем могут стать главным двигателем сильного билда**.

Не копировать конкретные карты, персонажей, интерфейс, сюжет, тексты или визуальные элементы существующих игр. Референсы используются только на уровне принципов дизайна.

## Tone & art direction

### Мир
Индустриальная антиутопия позднего стимпанка:
- медь, латунь, чугун, копоть, пар, манометры, трубки, шестерни;
- фабричные районы, башни, прожекторы, дымовые трубы, бюрократические ведомства;
- газовые лампы и тёплый локальный свет на фоне почти чёрного окружения;
- пропагандистские лозунги режима;
- ощущение, что карточный стол — часть реальной машины/кабинета внутри мира.

### Цвет и материал
Базовая палитра:
- угольный чёрный;
- тёмно-коричневый;
- старая латунь/медь;
- грязный пергамент;
- тусклый янтарный свет;
- ограниченные сигнальные акценты: красный для опасности, холодный бирюзовый/циан для выбора игрока.

Избегать:
- чистого sci-fi neon;
- гладкого fantasy UI;
- яркой мультяшности;
- чрезмерно чистых панелей.

### Юмор
Юмор сухой, мрачный и серьёзно поданный:
- абсурдная бюрократия;
- производственные нормы;
- штрафы после смерти;
- инструкции по эксплуатации человека;
- профсоюзы машин;
- «добровольное» подчинение;
- документы, справки, печати, квитанции.

Шутка не должна разрушать атмосферу. Персонажи относятся к абсурду как к норме.

## Camera / presentation

Основной бой — фиксированный или слегка параллаксный **фронтальный вид на механический карточный стол**.

Ключевые зоны:
- противник/Инспектор сверху;
- вражеский ряд;
- центральная зона ритуала/комбинации;
- карты игрока на столе;
- рука веером снизу;
- HP/давление/энергия слева;
- колода/сброс справа;
- множитель и кнопка завершения ритуала/хода справа снизу;
- relic/vice slots встроены в приборную панель.

Перспективные 3/4 кадры и окружение используются для событий, переходов, босса, заставок и редких интерактивных сцен, но не должны усложнять основной gameplay.

## Core gameplay pillars

1. **Build around failure**
   - слабость сначала создаёт реальный недостаток;
   - затем появляются синергии, которые делают недостаток полезным;
   - на позднем этапе билд может сознательно усиливать собственную слабость.

2. **Readable combo escalation**
   - игрок быстро понимает базовую формулу;
   - артефакты, пороки, существа и карты постепенно переписывают правила;
   - допускаются «сломанные» комбинации, если они требуют осмысленного билда.

3. **Physical table feeling**
   - hover, tilt, drag, snap, card fan;
   - звук бумаги/металла/механики;
   - карты и элементы UI ощущаются предметами;
   - важные действия дают короткие, ясные анимации.

4. **Deterministic runs**
   - каждый забег имеет seed;
   - вся влияющая на забег случайность идёт через `RunState.rng`;
   - одинаковый seed + одинаковые решения должны воспроизводить последовательность RNG.

5. **Fast replayability**
   - прототипный забег: 15–25 минут;
   - целевой забег: ~30–45 минут;
   - минимум длинных обязательных анимаций;
   - быстрый restart/rematch.

## Current scaffold

Уже реализовано:
- `RunState`: seed, отдельный RNG, состояние забега;
- `CardDatabase`: data-driven загрузка карт;
- `CardData`, `EffectData`;
- `EffectResolver`;
- `BattleController`;
- `ComboEvaluator` / `ComboResult`;
- `WeaknessData` / `WeaknessDatabase`;
- базовый headless smoke test;
- `CardView`, `HandView` и фронтальный `BattleTable` с механическими placeholder-материалами;
- headless UI-проверка таблицы.

### Current combo prototype

| Combo | Condition | Base Doom | Combo mult |
| --- | --- | ---: | ---: |
| Procession | ровно 5 карт одной масти | 8 | ×2 |
| Black Mass | >=1 карты и все имеют `curse` | 2 | ×2 |
| Triple | ровно 3 карты одного ранга | 4 | ×1 |
| Pair | ровно 2 карты одного ранга | 2 | ×1 |

Текущая формула:
`(stored_doom + base_doom) * persistent_multiplier * combo_multiplier`

Это прототип. Названия и математика могут измениться после первого игрового теста.

## New UI target: Vertical Slice

Текущий визуальный milestone — не «полный красивый интерфейс», а один законченный игровой стол:

### Implemented table slice

Первый игровой стол уже собран из трёх presentation-компонентов:

- `CardView` получает только `CardData`. В обычной руке он показывает стоимость, название, слот иллюстрации, масть, ранг и краткую строку data-driven эффектов; полный rules text доступен через inspect. Карта поднимается при hover, использует сдержанный cyan-контур для hover/selection и посылает intent-сигналы `play_requested` / `inspect_requested`.
- `HandView` получает готовую руку и доступность карт от UI-координатора, поднимает веер над краем стола и не изменяет колоду, руку или эффекты.
- `BattleTable` строит единую тёмную деревянно-латунную поверхность: компактный модуль Инспектора, вражеский ряд, ритуальный пресс, ряд модулей игрока и веер руки. Приборные стойки по краям занимают меньшую роль: слева находятся сосуд HP, pressure-лампы, Doom и пороки; справа — физические стопки колоды/сброса и кнопка хода.

Центральная поверхность занимает примерно 65–70% на 1600×900 и 1920×1080. Seed и журнал перенесены в сворачиваемый блок `ARCHIVE FILES`, поэтому не конкурируют с боем. У красного цвета только роль опасности и HP, cyan/teal остаётся цветом выбора игрока.

Управление: наведите курсор на карту, нажмите левую кнопку для розыгрыша, правую — для записи полного описания в журнале. Сыгранные карты сразу исчезают из руки и появляются в строке `Committed` ритуального пресса. Кнопка `SEAL RITUAL` применяет доступную комбинацию, `PROCESS ENEMY TURN` завершает ход. Стартовый seed `DEAD-BEEF-001` оставлен для воспроизводимой ручной проверки.

UI-сценарий можно запустить отдельно:

```powershell
& 'E:\SteamLibrary\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe' --headless --path . res://tests/battle_table_ui_test.tscn
```

Для ручной проверки композиции откройте `scenes/debug/battle_table_composition_debug.tscn` и запустите её при 1920×1080 и 1600×900. Сцена создаёт постоянную известную руку из пяти карт, placeholder-ряд врага, ряд модулей игрока и центр ритуала, не создавая и не изменяя игровой забег.

1. `CardView.tscn`
   - отображает данные, но не хранит gameplay state;
   - hover: подъём + лёгкий наклон/scale;
   - selection outline / cyan rim;
   - drag или click-to-play;
   - emits intent signals.

2. `BattleTable.tscn`
   - фиксированный фронтальный стол;
   - отдельные anchors для enemy row / player row / hand / HUD;
   - UI масштабируется под 16:9 и 16:10;
   - минимум one-screen scrolling.

3. `MechanicalHUD`
   - HP как стеклянная колба/манометр;
   - energy как паровое давление;
   - Doom/Score и multiplier визуально отделены;
   - deck/discard как физические стопки;
   - кнопки выглядят как латунные механические элементы.

4. Feedback
   - hit shake;
   - card impact;
   - combo pulse;
   - multiplier punch;
   - короткие particles/steam burst;
   - всё feedback-only: логика не зависит от tween/animation.

## Content vocabulary

Рабочая терминология мира:
- `Doom` / «Рок» — score/ритуальный ресурс;
- `Pressure` / «Давление» — энергия;
- `Vice` / «Порок» — постоянная weakness/build modifier;
- `Relic` / «Реликвия» — предмет/машинный модуль;
- `Inspector` / «Инспектор» — тип ведущего/противника;
- `Directive` / «Директива» — особое правило боя;
- `Compliance` / «Подчинение» — возможная механика/тематический ресурс, пока не закреплена.

Не добавлять новые глобальные термины без обновления документации.

## Engineering principles

- Gameplay remains data-driven.
- No card-specific logic in UI.
- Effects resolve centrally and stay composable.
- Presentation cannot own gameplay state.
- Every run-affecting random event uses `RunState.rng`.
- Stable string IDs for save compatibility.
- Prefer typed GDScript and small classes.
- Keep Web/Android portability; desktop is first target.
- Any rendering effect must have a graceful low-spec fallback.
- Avoid shader-heavy architecture until gameplay vertical slice proves fun.

## Test strategy

Minimum required after gameplay changes:
- parser/resource load;
- deterministic seed;
- smoke battle;
- combo scoring;
- weakness trigger;
- victory/death lock;
- no gameplay dependence on UI scene tree.

Later:
- headless run simulator;
- seeded golden runs;
- balance statistics;
- save/load replay tests.

## Codex workflow

For substantial work, use the `unlazy` skill:
```bash
npx skills add Leonxlnx/unlazy -g
```

In Codex, invoke:
```text
$unlazy tree 3 <task>
```

Before implementation:
1. write/update `GATES.md`;
2. make each gate observable;
3. prefer executable `CHECK` + `EXPECT`;
4. inspect inherited CHECK commands before approval;
5. implement;
6. run approved gates;
7. re-run with re-verification;
8. report only evidence-supported completion.

See `CODEX_WORKFLOW.md` and `GATES.example.md`.

## Near-term roadmap

### Milestone A — playable table
- reusable `CardView`;
- hand fan/layout;
- card selection/play feedback;
- battle table composition;
- Inspector frame;
- mechanical HUD.

### Milestone B — build identity
- 3 real Vices;
- 12–20 cards;
- 4–6 combos;
- 3 relics;
- 1 enemy archetype;
- combo rule modification.

### Milestone C — first 15-minute run
- encounter chain;
- reward selection;
- shop/event placeholder;
- 1 boss;
- seeded restart;
- simple run-end summary.

### Milestone D — production foundation
- save/load;
- content validation tool;
- localization keys;
- audio buses;
- headless balance simulation.

## Project structure

```text
assets/
  art/
  audio/
  fonts/
data/
  cards/
  weaknesses/
  relics/
  enemies/
scenes/
  battle/
  cards/
  ui/
  events/
scripts/
  autoload/
  battle/
  data/
  ui/
  run/
tests/
docs/
GATES.md
AGENTS.md
README.md
```

## Non-goals for the first vertical slice

Do NOT build yet:
- online PvP;
- accounts/server backend;
- procedural 3D room;
- complex dialogue framework;
- dozens of characters;
- hundreds of cards;
- live-service economy;
- mobile-specific UX;
- monetization SDKs.

First prove:
**the table feels good, combos are readable, and weaknesses create surprising builds.**

## Localization and current table presentation

The BattleTable is a presentation-only physical apparatus: the Inspector module
anchors the top of the table, enemy sockets sit below it, the layered Ritual
Machine occupies the center, player bays and the raised hand occupy the lower
field, and the compact instrument racks stay at the edges. The archive contains
the secondary seed, log, and language controls.

The table has three display profiles: `WIDE` at 1700px and above, `STANDARD`
from 1450px, and `COMPACT` below that threshold. The compact profile reduces
outer margins and apparatus widths, hides secondary Inspector designation text,
and keeps the battle surface at roughly 65–75% of the viewport. It is intended
to stay readable at 1366×768 as well as the 1600×900 and 1920×1080 targets.

Primary surfaces use local procedural SVG materials in `assets/ui/`: dark wood
for the table, iron for instrument cases, brass for the ritual machinery, and
parchment grain for card illustration areas. These are reusable placeholder
materials, not a dependency on final external art. The UI may animate only its
cached presentation snapshot: card hover, Inspector damage flash, Ritual pulse,
hand pulse, and the event readout do not modify gameplay state or RNG.

The same local asset kit supplies a distinct suit illustration for Bone, Blood,
Flesh, Spirit, and Gold, an Inspector mask, and the engraved Ritual emblem. It
is keyed by generic presentation data such as card suit, never by a card ID.

The reference scene for visual review is
`scenes/debug/style_kit_reference.tscn`. It deliberately contains the Inspector,
Ritual Machine, HP/Pressure instruments, deck apparatus, and a known five-card
hand. Review new presentation components against this scene and
[`docs/ART_DIRECTION.md`](docs/ART_DIRECTION.md).

The game currently supports English and Russian. Open `ARCHIVE FILES` and select
the language at runtime; the table, cards, Inspector, tooltips, and battle log
refresh immediately. The selection is saved in
`user://iron_covenant_settings.cfg`; the first launch uses a supported system
locale when possible and otherwise English.

Translation source is [`localization/strings.csv`](localization/strings.csv).
Cards and other content use presentation keys (`title_key`, `description_key`)
while keeping the same stable IDs and gameplay resources in every locale. See
[`docs/LOCALIZATION.md`](docs/LOCALIZATION.md) for key conventions, the RU/EN
terminology glossary, font requirements, and instructions for adding locales.

Run the deterministic locale check with:

```powershell
& 'E:\SteamLibrary\steamapps\common\Godot Engine\godot.windows.opt.tools.64.exe' --headless --path . res://tests/localization_test.tscn
```

## Art-direction vertical slice v1

## Battle-table visual rebuild

The live BattleTable now uses `assets/textures/ui/battle_table_apparatus_01.png`
as a language-neutral physical underlay. It supplies the pipework, lamp, lower
card rail, braces, and dark iron field; Inspector, integrity, intent, slots,
Ritual values, card text, draw/discard counters, and actions remain native UI
so EN/RU switching is unchanged. The main table is intentionally broad
(approximately 82–88% of the logical viewport) and the HP vessel, gauge,
card stacks, combo dial, and round enemy-turn control attach to its chassis.

`scenes/debug/style_kit_reference.tscn -- --art-empty-hand` renders the same
deterministic table without hand cards for material and empty-table inspection.

## Earlier art-direction notes

The live BattleTable now uses a layered visual composition: a subdued factory
ministry background behind the iron shell, modular wood/iron/brass/copper and
paper materials, scalable frame families, screen vignette, card-stack tray, and
a centered mechanical Ritual Machine. The Inspector has a generated portrait in
a dedicated housing; its intent and Integrity remain native localized UI. The
Ritual’s status lamp and native Doom/multiplier counter only reflect the existing
view state and do not calculate or alter combat.

Three validation cards use data-driven presentation art through
`CardData.art_path`: Grave Kick, Bone Guard, and Hangover. This field is optional
and never affects stable IDs, effects, seeded RNG, localization keys, or saves.
Cards without it retain the generic suit engraving. All generated textures are
language-neutral: card rules, counters, and labels remain Godot text.

Selected raw sources are retained in `assets/source/generated/`; runtime copies
are in `assets/textures/`. Reusable procedural UI material and frame assets stay
in `assets/ui/`. The complete visual rules are in
[`docs/ART_DIRECTION.md`](docs/ART_DIRECTION.md), and selected generation
provenance is in [`docs/ART_GENERATION.md`](docs/ART_GENERATION.md).

The deterministic visual reference remains
`scenes/debug/style_kit_reference.tscn`; it has the known five-card hand and
placeholder enemy/player rows. Review it manually at 1920x1080, 1600x900, and
1366x768 in English and Russian before accepting a release visual pass. See
[`GATES.md`](GATES.md) for the manual criteria.
