# 🧬 DNA Raw Data Analysis

Annotate your whole-genome sequencing (WGS) raw VCF against the latest [ClinVar](https://www.ncbi.nlm.nih.gov/clinvar/) database using only standard Unix tools — no Python, no installs.

---

## How it works

```
raw.vcf  →  extract_variants.sh  →  variants.tsv  →  annotate_clinvar.sh  →  clinvar_hits.tsv
```

1. `extract_variants.sh` — filters PASS variants from your raw VCF into a simple TSV
2. `annotate_clinvar.sh` — downloads the latest ClinVar, matches your variants, outputs annotated results with clinical significance, gene, rsID, and condition

---

## Requirements

Standard Unix tools only: `awk`, `curl`, `gunzip`. Available by default on macOS and Linux.

---

## Usage

```bash
# Step 1 — extract variants from your raw VCF (plain or gzipped)
./extract_variants.sh raw.vcf
# → produces variants.tsv

# Step 2 — annotate against ClinVar
./annotate_clinvar.sh
# → produces clinvar_hits.tsv
# → prints a breakdown by clinical significance
# → lists all Pathogenic / Likely pathogenic variants
```

ClinVar (~180 MB) is downloaded automatically on first run and refreshed if older than 30 days.

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
# Save a dated snapshot before re-running
cp clinvar_hits.tsv clinvar_hits_$(date +%Y%m%d).tsv

./annotate_clinvar.sh

# See what changed
diff clinvar_hits_$(date +%Y%m%d).tsv clinvar_hits.tsv
```

---

## Compatible VCF sources

Tested with Dante Labs WGS (DRAGEN pipeline, GRCh37/hg19). Should work with any standard VCF using GRCh37 coordinates and a PASS filter column.

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
raw.vcf  →  extract_variants.sh  →  variants.tsv  →  annotate_clinvar.sh  →  clinvar_hits.tsv
```

1. `extract_variants.sh` — фильтрует варианты с меткой PASS из сырого VCF в простой TSV
2. `annotate_clinvar.sh` — скачивает актуальный ClinVar, сопоставляет ваши варианты, выдаёт аннотированные результаты с клинической значимостью, геном, rsID и заболеванием

---

## Требования

Только стандартные Unix-инструменты: `awk`, `curl`, `gunzip`. Доступны по умолчанию на macOS и Linux.

---

## Использование

```bash
# Шаг 1 — извлечь варианты из сырого VCF (обычный или gzip)
./extract_variants.sh raw.vcf
# → создаёт variants.tsv

# Шаг 2 — аннотировать по ClinVar
./annotate_clinvar.sh
# → создаёт clinvar_hits.tsv
# → выводит сводку по клинической значимости
# → перечисляет все Pathogenic / Likely pathogenic варианты
```

ClinVar (~180 МБ) скачивается автоматически при первом запуске и обновляется, если файл старше 30 дней.

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
# Сохранить снимок перед повторным запуском
cp clinvar_hits.tsv clinvar_hits_$(date +%Y%m%d).tsv

./annotate_clinvar.sh

# Посмотреть, что изменилось
diff clinvar_hits_$(date +%Y%m%d).tsv clinvar_hits.tsv
```

---

## Совместимые источники VCF

Проверено на данных Dante Labs WGS (пайплайн DRAGEN, GRCh37/hg19). Должно работать с любым стандартным VCF на координатах GRCh37 с колонкой PASS-фильтра.

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
