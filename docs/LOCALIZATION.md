# Localization

Iron Covenant currently supports `en` and `ru`. Source strings live in
[`localization/strings.csv`](../localization/strings.csv); Godot imports it into
`strings.en.translation` and `strings.ru.translation`, both registered in
`project.godot`.

## Runtime locale

`LocalizationManager` is the single presentation/settings service for language.
At launch it restores `user://iron_covenant_settings.cfg`; without a saved value,
it uses the system language when it is `en` or `ru`, otherwise English. Calling
`LocalizationManager.set_locale("en")` or `set_locale("ru")` immediately updates
the Godot `TranslationServer`, persists the choice, and emits `locale_changed`.

The `ARCHIVE FILES` section of the BattleTable contains the runtime language
selector. BattleTable rebuilds only its presentation tree on a locale change and
re-renders its cached display snapshot and localized log messages. Battle state is
never stored or changed by the localization service.

## Adding a string

1. Add one uppercase key to the first column of `localization/strings.csv`.
2. Fill both `en` and `ru` columns in the same row.
3. Use `LocalizationManager.translate(&"KEY", {"argument": value})` in
   presentation code. Arguments use Godot `String.format` syntax, for example
   `{amount}`.
4. Do not put translated prose or large string dictionaries in GDScript.
5. Run the localization and UI tests after editing the CSV so Godot reimports it.

Use prefixes by owner: `UI_` for interface, `BATTLE_` for battle terminology,
`CARD_` for card presentation/content, `EFFECT_` for effect descriptions,
`COMBO_` for combinations, `WEAKNESS_` for Vices, `LOG_` for battle-log entries,
and `DEBUG_` only for deterministic developer scenes.

## Data-driven content

`CardData` and `WeaknessData` retain their legacy `title`/`description` fields as
a migration fallback and now provide `title_key` and `description_key`. New
content must provide translation keys instead of locale-specific duplicate
resources. Stable IDs, costs, ranks, tags, and effects do not depend on language.

## Terminology

| English | Russian | Key family |
| --- | --- | --- |
| Doom | Рок | `UI_DOOM_*`, `EFFECT_GAIN_DOOM` |
| Pressure | Давление | `UI_PRESSURE` |
| Vice | Порок | `UI_VICE_*`, `WEAKNESS_*` |
| Ritual | Ритуал | `UI_RITUAL_*`, `COMBO_*` |
| Inspector | Инспектор | `UI_INSPECTOR_*` |
| Integrity | Целостность | `BATTLE_INTEGRITY` |
| Directive | Директива | reserved `BATTLE_DIRECTIVE_*` |
| Relic | Реликвия | reserved `RELIC_*` |
| Draw Stack | Колода | `UI_DRAW` |
| Discard | Сброс | `UI_DISCARD` |
| Committed | В ритуале | `UI_COMMITTED` |

## Fonts

BattleTable uses a system-font preference chain (`Segoe UI`, `Noto Sans`, then
`Arial`) with Godot's fallback font. These fonts include Cyrillic on supported
desktop systems. Any future custom display font must include both Latin and
Cyrillic glyphs before it replaces this fallback chain.

## Adding a locale

Add a new column to `strings.csv`, ensure Godot imports the new `.translation`
resource, register it in `project.godot`, add it to `SUPPORTED_LOCALES`, expose it
in the language selector, and add a deterministic locale test and responsive
manual check.
