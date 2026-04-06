#!/usr/bin/env bash
# annotate_clinvar.sh — Match your WGS variants against ClinVar
#
# Input:  variants.tsv  (chr, pos, ref, alt, genotype — tab-separated, with header)
#         Produce this file from your raw VCF with extract_variants.sh
# Output: clinvar_hits.tsv
#
# Dependencies: awk, curl, gunzip (standard Unix tools — no extra installs needed)

set -euo pipefail
cd "$(dirname "$0")"

CLINVAR_VCF="clinvar_GRCh37.vcf.gz"
CLINVAR_URL="https://ftp.ncbi.nlm.nih.gov/pub/clinvar/vcf_GRCh37/clinvar.vcf.gz"
VARIANTS="${1:-variants.tsv}"   # pass a custom path as first argument if needed
OUTPUT="clinvar_hits.tsv"

if [[ ! -f "$VARIANTS" ]]; then
  echo "Error: $VARIANTS not found. Run extract_variants.sh first." >&2
  exit 1
fi

# Download ClinVar if missing or older than 30 days
if [[ ! -f "$CLINVAR_VCF" ]] || [[ $(find "$CLINVAR_VCF" -mtime +30 2>/dev/null) ]]; then
  echo "Downloading latest ClinVar (GRCh37)..."
  curl -fSL "$CLINVAR_URL"      -o "$CLINVAR_VCF"
  curl -fSL "${CLINVAR_URL}.tbi" -o "${CLINVAR_VCF}.tbi"
  echo "Downloaded $(date -r "$CLINVAR_VCF" '+%Y-%m-%d')"
fi

# Build lookup: chr:pos:ref:alt -> clnsig|gene|rsid|condition
echo "Building ClinVar index..."
gunzip -c "$CLINVAR_VCF" | awk -F'\t' '!/^#/{
  chr=$1; pos=$2; ref=$4; alt=$5; info=$8
  clnsig=""; gene=""; rs=$3; name=""
  n=split(info,pairs,";")
  for(i=1;i<=n;i++){
    split(pairs[i],kv,"=")
    if(kv[1]=="CLNSIG")   clnsig=kv[2]
    if(kv[1]=="GENEINFO") gene=kv[2]
    if(kv[1]=="CLNDN")    name=kv[2]
  }
  gsub(/^chr/,"",chr)
  print chr":"pos":"ref":"alt"\t"clnsig"\t"gene"\t"rs"\t"name
}' > clinvar_lookup.tmp

echo "Matching variants..."
awk -F'\t' 'BEGIN{OFS="\t"}
  NR==FNR {lookup[$1]=$2"\t"$3"\t"$4"\t"$5; next}
  FNR==1  {print "chr","pos","ref","alt","genotype","clnsig","gene","rsid","condition"; next}
  {
    key=$1":"$2":"$3":"$4
    if(key in lookup) print $0, lookup[key]
  }
' clinvar_lookup.tmp "$VARIANTS" > "$OUTPUT"

rm -f clinvar_lookup.tmp

TOTAL=$(tail -n+2 "$OUTPUT" | wc -l | tr -d ' ')
echo ""
echo "Done — $TOTAL variants matched ClinVar → $OUTPUT"

echo ""
echo "=== Clinical significance breakdown ==="
tail -n+2 "$OUTPUT" | awk -F'\t' '{print $6}' | sort | uniq -c | sort -rn

echo ""
echo "=== Pathogenic / Likely pathogenic ==="
head -1 "$OUTPUT"
awk -F'\t' '$6 ~ /athogenic/' "$OUTPUT" | sort -t$'\t' -k6,6
