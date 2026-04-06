#!/usr/bin/env bash
# analyze.sh — Annotate WGS variants against ClinVar
#
# Usage: ./analyze.sh <raw.vcf or raw.vcf.gz>
#
# Steps (each skipped if already up-to-date):
#   1. Extract PASS variants from VCF → variants.tsv
#   2. Download ClinVar GRCh37 (refreshed if >30 days old)
#   3. Match variants → clinvar_hits.tsv
#   4. Filter important findings → clinvar_important.tsv
#
# Dependencies: awk, curl, gunzip (standard Unix tools)

set -euo pipefail
cd "$(dirname "$0")"

INPUT="${1:-}"
CLINVAR_DIR="clinvar"
DATA_DIR="data"
CLINVAR_VCF="$CLINVAR_DIR/clinvar_GRCh37.vcf.gz"
CLINVAR_URL="https://ftp.ncbi.nlm.nih.gov/pub/clinvar/vcf_GRCh37/clinvar.vcf.gz"
VARIANTS="$DATA_DIR/variants.tsv"
OUTPUT="$DATA_DIR/clinvar_hits.tsv"
IMPORTANT="$DATA_DIR/clinvar_important.tsv"

mkdir -p "$CLINVAR_DIR" "$DATA_DIR"

# --- Step 0: Validate input ------------------------------------------------

if [[ -z "$INPUT" ]]; then
  if [[ -f "$VARIANTS" ]]; then
    echo "No VCF specified — using existing $VARIANTS"
  else
    echo "Usage: $0 <raw.vcf or raw.vcf.gz>" >&2
    exit 1
  fi
elif [[ ! -f "$INPUT" ]]; then
  echo "Error: $INPUT not found." >&2
  exit 1
fi

# --- Step 1: Extract variants ----------------------------------------------

if [[ -n "$INPUT" ]]; then
  if [[ -f "$VARIANTS" && "$VARIANTS" -nt "$INPUT" ]]; then
    echo "Step 1: $VARIANTS is up-to-date — skipping extraction"
  else
    echo "Step 1: Extracting PASS variants from $INPUT..."
    if [[ "$INPUT" == *.gz ]]; then CAT="gunzip -c"; else CAT="cat"; fi
    $CAT "$INPUT" | awk -F'\t' '
      /^#/ { next }
      $7 == "PASS" || $7 == "." {
        split($10, gt, ":")
        chr = $1; sub(/^chr/, "", chr)
        print chr"\t"$2"\t"$4"\t"$5"\t"gt[1]
      }
    ' | sort -k1,1V -k2,2n \
      | awk 'BEGIN{print "chr\tpos\tref\talt\tgenotype"} {print}' > "$VARIANTS"
    echo "  $(tail -n+2 "$VARIANTS" | wc -l | tr -d ' ') variants"
  fi
fi

# --- Step 2: Download ClinVar ----------------------------------------------

if [[ ! -f "$CLINVAR_VCF" ]] || [[ $(find "$CLINVAR_VCF" -mtime +30 2>/dev/null) ]]; then
  echo "Step 2: Downloading latest ClinVar (GRCh37)..."
  curl -fSL "$CLINVAR_URL"      -o "$CLINVAR_VCF"
  curl -fSL "${CLINVAR_URL}.tbi" -o "${CLINVAR_VCF}.tbi"
  echo "  Done"
else
  echo "Step 2: ClinVar is fresh — skipping download"
fi

# --- Step 3: Annotate ------------------------------------------------------

# Back up previous results if they exist
if [[ -f "$OUTPUT" ]]; then
  PREV="${OUTPUT%.tsv}_$(date +%Y%m%d).tsv"
  if [[ ! -f "$PREV" ]]; then
    cp "$OUTPUT" "$PREV"
    echo "Step 3: Backed up previous results → $PREV"
  fi
fi

echo "Step 3: Building ClinVar index..."
gunzip -c "$CLINVAR_VCF" | awk -F'\t' '!/^#/{
  chr=$1; pos=$2; ref=$4; alt=$5; info=$8
  clnsig=""; gene=""; rs=$3; name=""
  n=split(info,pairs,";")
  for(i=1;i<=n;i++){
    split(pairs[i],kv,"=")
    if(kv[1]=="CLNSIG")   clnsig=kv[2]
    if(kv[1]=="GENEINFO"){ gene=kv[2]; sub(/:.*/, "", gene) }
    if(kv[1]=="CLNDN")    name=kv[2]
  }
  sub(/^chr/,"",chr)
  print chr":"pos":"ref":"alt"\t"clnsig"\t"gene"\t"rs"\t"name
}' > "$CLINVAR_DIR/lookup.tmp"

echo "  Matching variants..."
awk -F'\t' 'BEGIN{OFS="\t"}
  NR==FNR {lookup[$1]=$2"\t"$3"\t"$4"\t"$5; next}
  FNR==1  {print "chr","pos","ref","alt","genotype","clnsig","gene","rsid","condition"; next}
  {
    key=$1":"$2":"$3":"$4
    if(key in lookup) print $0, lookup[key]
  }
' "$CLINVAR_DIR/lookup.tmp" "$VARIANTS" > "$OUTPUT"

rm -f "$CLINVAR_DIR/lookup.tmp"

TOTAL=$(tail -n+2 "$OUTPUT" | wc -l | tr -d ' ')
echo "  $TOTAL variants matched ClinVar → $OUTPUT"

# --- Step 4: Filter important findings -------------------------------------

awk -F'\t' 'NR==1 || $6 ~ /[Pp]athogenic|Uncertain|Conflicting/' "$OUTPUT" > "$IMPORTANT"
IMP=$(tail -n+2 "$IMPORTANT" | wc -l | tr -d ' ')
echo "Step 4: $IMP important variants → $IMPORTANT"

# --- Summary ----------------------------------------------------------------

echo ""
echo "=== Clinical significance breakdown ==="
tail -n+2 "$OUTPUT" | awk -F'\t' '{print $6}' | sort | uniq -c | sort -rn

echo ""
echo "=== Pathogenic / Likely pathogenic ==="
head -1 "$OUTPUT"
awk -F'\t' '$6 ~ /athogenic/ && $6 !~ /Conflicting/' "$OUTPUT" | sort -t$'\t' -k6,6
