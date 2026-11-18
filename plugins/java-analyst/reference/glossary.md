# Glossary: terms we do not translate

The same file ships with every team plugin. The team's own terms go to `glossary.md` in the workspace root (next to `modules.md`); terms learned in a session go to the project's `.claude/glossary.md` (qa-docs: `qa-docs/glossary.md`). Commit those to share them.

- **Term**: the word as it appears in the code, Jira or Confluence.
- **We say**: how it is written in a Ukrainian text (empty = the term itself).
- **Avoid**: wrong translations, comma separated. The Stop hook blocks a report that contains one. `*` stands for any letters, so a stem catches every case form. Keep these narrow: a common Ukrainian word here blocks normal sentences.

| Term | We say | Avoid |
| --- | --- | --- |
| deploy | деплой, задеплоїти | розкат*, викоч*, викот* |
| release | реліз | |
| merge | мердж, змерджити | злит* гілк*, злиття гілок |
| pull request | PR, пул реквест | запит* на злиття, запит* на втягуван* |
| commit | коміт, закомітити | фіксаці* змін* |
| branch | бранч, гілка | |
| hotfix | хотфікс | гаряч* виправлен*, гаряч* фікс* |
| rollback | rollback, відкат | |
| build | білд | |
| pipeline | пайплайн | конвеєр* |
| endpoint | endpoint, ендпоінт | кінцев* точк* |
| payload | payload | корисн* навантаж* |
| feature flag | feature flag, фіча-флаг | прапор* функці* |
| mapping | mapping, маппінг | |
| job | job, джоба | |
| request / response | request / response, запит / відповідь | |
| nightly rate | nightly rate | нічн* цін*, нічн* прайс*, нічн* тариф* |
| unbundling | unbundling | розукомплект*, розв'язуванн* пакет* |
| channel manager | channel manager | менеджер* канал* |
