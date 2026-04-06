# 🧬 DNA Raw Data Analysis

Annotate your whole-genome sequencing (WGS) raw VCF against the latest [ClinVar](https://www.ncbi.nlm.nih.gov/clinvar/) database using only standard Unix tools — no Python, no installs.

---

## How it works

```
raw.vcf  →  analyze.sh  →  variants.tsv + clinvar_hits.tsv + clinvar_important.tsv
```

`analyze.sh` does everything in one run:
1. Extracts PASS variants from your raw VCF
2. Downloads the latest ClinVar (GRCh37), refreshes if older than 30 days
3. Matches your variants against ClinVar — outputs clinical significance, gene, rsID, and condition
4. Filters important findings (Pathogenic, Likely pathogenic, Uncertain, Conflicting)

Each step is skipped if already up-to-date. Previous results are backed up automatically.

---

## Requirements

Standard Unix tools only: `awk`, `curl`, `gunzip`. Available by default on macOS and Linux.

---

## Project structure

```
dna-analysis/
├── analyze.sh          # the script — only file tracked in git
├── clinvar/            # ClinVar database (auto-downloaded, git-ignored)
│   ├── clinvar_GRCh37.vcf.gz
│   └── clinvar_GRCh37.vcf.gz.tbi
└── data/               # your VCF, variants, results (git-ignored)
    ├── variants.tsv
    ├── clinvar_hits.tsv
    └── clinvar_important.tsv
```

---

## Usage

```bash
# First run — provide your raw VCF (plain or gzipped)
./analyze.sh raw.vcf

# Monthly re-run — same command, skips extraction if VCF unchanged
./analyze.sh raw.vcf

# Re-annotate only (if variants.tsv already exists)
./analyze.sh
```

---

## Output

`clinvar_hits.tsv` — tab-separated, one row per matched variant:

| chr | pos | ref | alt | genotype | clnsig | gene | rsid | condition |
|-----|-----|-----|-----|----------|--------|------|------|-----------|

---

## Interpreting results

| Genotype | Meaning |
|----------|---------|
| `0/1` | Heterozygous — one copy. For recessive conditions: carrier status, typically unaffected |
| `1/1` | Homozygous — two copies |

| Classification | What it means |
|----------------|---------------|
| Benign / Likely benign | No clinical concern |
| Uncertain significance (VUS) | Not enough evidence yet — worth monitoring, may be reclassified |
| Conflicting interpretations | Labs disagree — may resolve in future ClinVar updates |
| Pathogenic / Likely pathogenic | Associated with disease — check zygosity and inheritance pattern |

---

## Re-run monthly

ClinVar is updated monthly. Variants get reclassified over time (VUS → Pathogenic, etc.).

```bash
# Just re-run — previous results are backed up automatically
./analyze.sh raw.vcf

# See what changed
diff data/clinvar_hits_$(date +%Y%m%d).tsv data/clinvar_hits.tsv
```

---

## Other tools worth knowing

| Tool | Description |
|------|-------------|
| [ClinVar](https://www.ncbi.nlm.nih.gov/clinvar/) | NCBI variant-disease database (used by this project) |
| [OpenCRAVAT](https://opencravat.org/) | Free multi-database variant annotation |
| [Promethease](https://promethease.com/) | SNPedia-based health report (~$12) |
| [PharmGKB](https://www.pharmgkb.org/) | Pharmacogenomics — drug metabolism |
| [SNPedia](https://www.snpedia.com/) | SNP-health association wiki |

---

## Disclaimer

This is automated annotation of raw sequencing data — not a clinical diagnosis. Discuss any pathogenic findings with a genetic counselor who can interpret results in the context of zygosity, inheritance patterns, penetrance, and family history.

---
---

# 🧬 Анализ сырых данных ДНК

Аннотация вариантов из сырого VCF-файла (WGS) по актуальной базе [ClinVar](https://www.ncbi.nlm.nih.gov/clinvar/) — только стандартные Unix-инструменты, без Python и дополнительных установок.

---

## Как это работает

```
raw.vcf  →  analyze.sh  →  variants.tsv + clinvar_hits.tsv + clinvar_important.tsv
```

`analyze.sh` делает всё за один запуск:
1. Извлекает PASS-варианты из сырого VCF
2. Скачивает актуальный ClinVar (GRCh37), обновляет если старше 30 дней
3. Сопоставляет варианты с ClinVar — выдаёт клиническую значимость, ген, rsID и заболевание
4. Фильтрует важные находки (Pathogenic, Likely pathogenic, Uncertain, Conflicting)

Каждый шаг пропускается, если уже актуален. Предыдущие результаты сохраняются автоматически.

---

## Требования

Только стандартные Unix-инструменты: `awk`, `curl`, `gunzip`. Доступны по умолчанию на macOS и Linux.

---

## Структура проекта

```
dna-analysis/
├── analyze.sh          # скрипт — единственный файл в git
├── clinvar/            # база ClinVar (скачивается автоматически, в .gitignore)
│   ├── clinvar_GRCh37.vcf.gz
│   └── clinvar_GRCh37.vcf.gz.tbi
└── data/               # ваш VCF, варианты, результаты (в .gitignore)
    ├── variants.tsv
    ├── clinvar_hits.tsv
    └── clinvar_important.tsv
```

---

## Использование

```bash
# Первый запуск — указать сырой VCF (обычный или gzip)
./analyze.sh raw.vcf

# Ежемесячный перезапуск — та же команда, извлечение пропускается если VCF не изменился
./analyze.sh raw.vcf

# Только переаннотация (если variants.tsv уже есть)
./analyze.sh
```

---

## Результат

`clinvar_hits.tsv` — таблица с разделителем табуляции, одна строка на вариант:

| chr | pos | ref | alt | genotype | clnsig | gene | rsid | condition |
|-----|-----|-----|-----|----------|--------|------|------|-----------|

---

## Как читать результаты

| Генотип | Значение |
|---------|----------|
| `0/1` | Гетерозигота — одна копия. Для рецессивных болезней: носительство, обычно без симптомов |
| `1/1` | Гомозигота — две копии |

| Классификация | Что значит |
|---------------|------------|
| Benign / Likely benign | Нет клинического значения |
| Uncertain significance (VUS) | Недостаточно данных — стоит мониторить, могут переклассифицировать |
| Conflicting interpretations | Лаборатории расходятся — может разрешиться в следующих обновлениях ClinVar |
| Pathogenic / Likely pathogenic | Связан с заболеванием — проверьте зиготность и тип наследования |

---

## Запускать раз в месяц

ClinVar обновляется ежемесячно. Варианты переклассифицируются (VUS → Pathogenic и т.д.).

```bash
# Просто перезапустить — предыдущие результаты сохраняются автоматически
./analyze.sh raw.vcf

# Посмотреть, что изменилось
diff data/clinvar_hits_$(date +%Y%m%d).tsv data/clinvar_hits.tsv
```

---

## Другие полезные инструменты

| Инструмент | Описание |
|------------|----------|
| [ClinVar](https://www.ncbi.nlm.nih.gov/clinvar/) | База NCBI — связь вариантов с заболеваниями (используется в этом проекте) |
| [OpenCRAVAT](https://opencravat.org/) | Бесплатная мульти-база аннотаций |
| [Promethease](https://promethease.com/) | Отчёт по SNPedia из VCF (~$12) |
| [PharmGKB](https://www.pharmgkb.org/) | Фармакогеномика — метаболизм лекарств |
| [SNPedia](https://www.snpedia.com/) | Вики ассоциаций SNP-здоровье |

---

## Дисклеймер

Это автоматическая аннотация сырых данных секвенирования — не клинический диагноз. Патогенные находки необходимо обсудить с генетиком-консультантом, который учтёт зиготность, паттерн наследования, пенетрантность и семейную историю.
