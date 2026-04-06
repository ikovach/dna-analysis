#!/usr/bin/env bash
# extract_variants.sh — Extract PASS-filtered variants from a raw WGS VCF
#
# Usage: ./extract_variants.sh [input.vcf]
# Output: variants.tsv (chr, pos, ref, alt, genotype)
#
# Supports plain .vcf and gzipped .vcf.gz

set -euo pipefail

INPUT="${1:-raw.vcf}"
OUTPUT="variants.tsv"

if [[ ! -f "$INPUT" ]]; then
  echo "Error: $INPUT not found." >&2
  echo "Usage: $0 <your_raw.vcf or your_raw.vcf.gz>" >&2
  exit 1
fi

echo "Extracting PASS variants from $INPUT..."

# Auto-detect gzip
if [[ "$INPUT" == *.gz ]]; then
  CAT="gunzip -c"
else
  CAT="cat"
fi

$CAT "$INPUT" | awk -F'\t' '
  /^#/ { next }
  $7 == "PASS" || $7 == "." {
    # genotype is the first field of the sample column (col 10), before ":"
    split($10, gt, ":")
    print $1"\t"$2"\t"$4"\t"$5"\t"gt[1]
  }
' | sort -k1,1V -k2,2n | awk 'BEGIN{print "chr\tpos\tref\talt\tgenotype"} {print}' > "$OUTPUT"

TOTAL=$(tail -n+2 "$OUTPUT" | wc -l | tr -d ' ')
echo "Done — $TOTAL variants written to $OUTPUT"
