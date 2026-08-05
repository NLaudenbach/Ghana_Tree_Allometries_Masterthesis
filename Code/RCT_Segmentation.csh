#!/bin/tcsh

# ============================================================
# UNIVERSAL RCT PRESEGMENTATION SCRIPT
# ============================================================

# ------------------------------------------------------------
# ONLY CHANGE THESE TWO LINES
# ------------------------------------------------------------

set PLOT = "AN1"

set INPUT_ORIGINAL = "/misc/scn6/2026-01-13_JW_GHANA/TLS/AN1/L1/laz_density_harmonized_final"


# ------------------------------------------------------------
# Everything below is automatic
# ------------------------------------------------------------

set OUTPUT_BASE = "/misc/scn6/Ghana/RCT_outputs/${PLOT}_preseg_RCT"
set INPUT_FIXED = "${OUTPUT_BASE}/input"
set OUTPUT_RCT = "${OUTPUT_BASE}/output"
set PIPELINE = "/misc/scn6/Ghana/RCT_outputs/rct-tile-pipeline_laudenb_test"

set LOGFILE = "${OUTPUT_RCT}/${PLOT}_preseg_RCT.log"
set MERGED = "${OUTPUT_RCT}/rct/segmented/merged.laz"


# ------------------------------------------------------------
# RCT environment
# ------------------------------------------------------------

setenv RCT /misc/soft/local/raytools-hg20260506

setenv PATH /misc/soft/local/raytools-hg20260506/bin:/misc/scn1/person/laudenb/conda/envs/RCT_dependencies/bin:/misc/scn1/person/laudenb/conda/bin:$PATH

setenv LD_LIBRARY_PATH /misc/soft/local/raytools-hg20260506/lib:$LD_LIBRARY_PATH

setenv PROJ_LIB /misc/scn1/person/laudenb/conda/envs/RCT_dependencies/share/proj

setenv PROJ_DATA /misc/scn1/person/laudenb/conda/envs/RCT_dependencies/share/proj


echo ""
echo "============================================================"
echo "RCT PRESEGMENTATION"
echo "Plot: $PLOT"
echo "============================================================"
echo ""

echo "Checking environment..."

which python
if ($status != 0) then
    echo "ERROR: python not found"
    exit 1
endif

which pdal
if ($status != 0) then
    echo "ERROR: pdal not found"
    exit 1
endif

which untwine
if ($status != 0) then
    echo "ERROR: untwine not found"
    exit 1
endif


# ------------------------------------------------------------
# Check input directory
# ------------------------------------------------------------

if (! -d "$INPUT_ORIGINAL") then
    echo ""
    echo "ERROR: Input directory does not exist:"
    echo "$INPUT_ORIGINAL"
    exit 1
endif

cd "$INPUT_ORIGINAL"


# ------------------------------------------------------------
# Count original LAZ files
# ------------------------------------------------------------

set N_ORIGINAL = `ls *.laz | wc -l`

echo ""
echo "Original LAZ files: $N_ORIGINAL"

if ($N_ORIGINAL == 0) then
    echo "ERROR: No LAZ files found."
    exit 1
endif


# ------------------------------------------------------------
# Create output directories
# ------------------------------------------------------------

mkdir -p "$INPUT_FIXED"
mkdir -p "$OUTPUT_RCT"


# ------------------------------------------------------------
# Add CRS to each input tile
# ------------------------------------------------------------

echo ""
echo "============================================================"
echo "Preparing input LAZ files"
echo "CRS: EPSG:32630"
echo "============================================================"
echo ""

foreach f (*.laz)

    set base = `basename "$f" .laz`
    set fixed_file = "${INPUT_FIXED}/${base}_fixed.laz"

    if (! -e "$fixed_file") then

        echo "Fixing CRS: $f"

        pdal translate \
            "$f" \
            "$fixed_file" \
            --writers.las.a_srs="EPSG:32630"

        if ($status != 0) then
            echo ""
            echo "ERROR while processing:"
            echo "$f"
            exit 1
        endif

    else

        echo "Skipping existing: ${base}_fixed.laz"

    endif

end


# ------------------------------------------------------------
# Verify prepared files
# ------------------------------------------------------------

set N_FIXED = `ls ${INPUT_FIXED}/*.laz | wc -l`

echo ""
echo "============================================================"
echo "Input check"
echo "============================================================"
echo "Original LAZ files : $N_ORIGINAL"
echo "Prepared LAZ files : $N_FIXED"
echo ""

if ($N_FIXED != $N_ORIGINAL) then
    echo "ERROR: Number of prepared files does not match originals."
    exit 1
endif


# ------------------------------------------------------------
# Run RCT
# ------------------------------------------------------------

cd "$PIPELINE"

echo ""
echo "============================================================"
echo "Starting RCT"
echo "============================================================"
echo "Plot:   $PLOT"
echo "Input:  $INPUT_FIXED"
echo "Output: $OUTPUT_RCT"
echo "Log:    $LOGFILE"
echo "============================================================"
echo ""

env -u DISPLAY taskset -c 0-7 \
/misc/scn1/person/laudenb/conda/envs/RCT_dependencies/bin/python -u run.py \
--input "$INPUT_FIXED" \
--output "$OUTPUT_RCT" \
|& tee -a "$LOGFILE"


# ------------------------------------------------------------
# Final result check
# ------------------------------------------------------------

echo ""
echo "============================================================"

if (-e "$MERGED") then

    echo "RCT COMPLETE"
    echo ""
    echo "Merged result:"
    echo "$MERGED"
    echo ""

    ls -lh "$MERGED"

else

    echo "WARNING:"
    echo "RCT command ended, but merged.laz was not found."
    echo ""
    echo "Check log:"
    echo "$LOGFILE"

endif

echo "============================================================"


# ------------------------------------------------------------
# Additional Information
# ------------------------------------------------------------

# For a new plot, only change:
#
# set PLOT = "BO1"
# set INPUT_ORIGINAL = "/misc/scn6/2026-01-13_JW_GHANA/TLS/BO1/L1/laz_density_harmonized_final"
