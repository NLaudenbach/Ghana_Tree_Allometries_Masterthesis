#!/usr/bin/env bash

# ============================================================
# RCT QSM BATCH PROCESSING
# ============================================================

set -u

# ============================================================
# RCT ENVIRONMENT
# ============================================================

export PATH="/misc/soft/local/raytools-hg20260506/bin:/misc/scn1/person/laudenb/conda/envs/RCT_dependencies/bin:/misc/scn1/person/laudenb/conda/bin:$PATH"

export LD_LIBRARY_PATH="/misc/soft/local/raytools-hg20260506/lib:${LD_LIBRARY_PATH:-}"

export PROJ_LIB="/misc/scn1/person/laudenb/conda/envs/RCT_dependencies/share/proj"
export PROJ_DATA="/misc/scn1/person/laudenb/conda/envs/RCT_dependencies/share/proj"


# ============================================================
# INPUT DIRECTORIES
#
# Später einfach weitere Ordner ergänzen.
# ============================================================

INPUT_DIRS=(
    "/misc/scn6/Ghana/MT_NL_Trees/NK_Trees_BO1"
    "/misc/scn6/Ghana/MT_NL_Trees/NK_Trees_BO2"
    "/misc/scn6/Ghana/MT_NL_Trees/NK_Trees_KO4"
    "/misc/scn6/Ghana/MT_NL_Trees/NL_Trees_SAV"
)

# ============================================================
# OUTPUT
# ============================================================

OUTPUT_ROOT="/misc/scn6/Ghana/MT_NL_Trees/RCT_QSM_OUTPUT"

mkdir -p "$OUTPUT_ROOT"

SUMMARY_FILE="$OUTPUT_ROOT/RCT_QSM_summary.csv"


# ============================================================
# HEADER
# ============================================================

echo ""
echo "============================================================"
echo "RCT QSM BATCH"
echo "============================================================"
echo ""

echo "rayimport:  $(which rayimport)"
echo "rayextract: $(which rayextract)"
echo "treeinfo:   $(which treeinfo)"
echo ""


# ============================================================
# SUMMARY NEU ANLEGEN, FALLS NICHT VORHANDEN
# ============================================================

if [ ! -f "$SUMMARY_FILE" ]; then
    echo "plot,tree_id,status,n_trees,volume_m3,dbh_m,height_m" > "$SUMMARY_FILE"
fi


# ============================================================
# INPUT DIRECTORIES
# ============================================================

for INPUT_DIR in "${INPUT_DIRS[@]}"
do

    if [ ! -d "$INPUT_DIR" ]; then
        echo "FEHLER: Input-Ordner existiert nicht:"
        echo "$INPUT_DIR"
        continue
    fi

    PLOT_NAME=$(basename "$INPUT_DIR")
    PLOT_OUTPUT="$OUTPUT_ROOT/$PLOT_NAME"

    mkdir -p "$PLOT_OUTPUT"

    shopt -s nullglob
    TREE_FILES=("$INPUT_DIR"/*.laz)
    shopt -u nullglob

    N_TREES=${#TREE_FILES[@]}

    echo ""
    echo "============================================================"
    echo "Plot: $PLOT_NAME"
    echo "Gefundene Einzelbäume: $N_TREES"
    echo "============================================================"


    COUNTER=0


    for LAZ_FILE in "${TREE_FILES[@]}"
    do

        COUNTER=$((COUNTER + 1))

        TREE_ID=$(basename "$LAZ_FILE" .laz)
        TREE_DIR="$PLOT_OUTPUT/$TREE_ID"

        mkdir -p "$TREE_DIR"

        echo ""
        echo "------------------------------------------------------------"
        echo "Baum $COUNTER / $N_TREES : $TREE_ID"
        echo "------------------------------------------------------------"

        cd "$TREE_DIR" || continue


        # ====================================================
        # Original-LAZ nur verlinken
        # ============================================================

        if [ ! -e "${TREE_ID}.laz" ]; then
            ln -s "$LAZ_FILE" "${TREE_ID}.laz"
        fi


        # ====================================================
        # STEP 1 - RAYIMPORT
        # ============================================================

        if [ -s "${TREE_ID}.ply" ]; then

            echo "[1/4] rayimport -> bereits vorhanden"

        else

            echo "[1/4] rayimport -> START"

            START=$(date +%s)

            if ! rayimport \
                "${TREE_ID}.laz" \
                ray 0,0,-1 \
                --max_intensity 0 \
                --remove_start_pos \
                > rayimport.log 2>&1
            then

                echo "ERROR: rayimport"

                rm -f "${TREE_ID}.ply"

                continue
            fi

            END=$(date +%s)

            echo "rayimport runtime: $((END - START)) s"

        fi


        # ====================================================
        # STEP 2 - TERRAIN
        # ============================================================

        if [ -s "${TREE_ID}_mesh.ply" ]; then

            echo "[2/4] terrain   -> bereits vorhanden"

        else

            echo "[2/4] terrain   -> START"

            START=$(date +%s)

            if ! rayextract terrain \
                "${TREE_ID}.ply" \
                > terrain.log 2>&1
            then

                echo "ERROR: terrain"

                rm -f "${TREE_ID}_mesh.ply"

                continue
            fi

            END=$(date +%s)

            echo "terrain runtime: $((END - START)) s"

        fi


        # ====================================================
        # STEP 3 - QSM
        # ============================================================

        if [ -s "${TREE_ID}_trees.txt" ] && \
           [ -s "${TREE_ID}_trees_mesh.ply" ]; then

            echo "[3/4] QSM       -> bereits vorhanden"

        else

            echo "[3/4] QSM       -> START"

            START=$(date +%s)

            if ! rayextract trees \
                "${TREE_ID}.ply" \
                "${TREE_ID}_mesh.ply" \
                > qsm.log 2>&1
            then

                echo "ERROR: QSM"

                rm -f "${TREE_ID}_trees.txt"
                rm -f "${TREE_ID}_trees_mesh.ply"
                rm -f "${TREE_ID}_segmented.ply"

                continue
            fi

            END=$(date +%s)

            echo "QSM runtime: $((END - START)) s"

        fi


        # ====================================================
        # STEP 4 - TREEINFO
        # ============================================================

        echo "[4/4] treeinfo"

        START=$(date +%s)

        TREEINFO_OUTPUT=$(treeinfo "${TREE_ID}_trees.txt" 2>&1)

        echo "$TREEINFO_OUTPUT" > treeinfo.log

        END=$(date +%s)

        echo "treeinfo runtime: $((END - START)) s"


        # ====================================================
        # VALUES EXTRACT
        # ============================================================

        N_RCT_TREES=$(echo "$TREEINFO_OUTPUT" \
            | grep -m1 "trees:" \
            | awk '{print $2}')

        VOLUME=$(echo "$TREEINFO_OUTPUT" \
            | grep -m1 "volume of wood:" \
            | awk '{print $4}')

        DBH=$(echo "$TREEINFO_OUTPUT" \
            | grep -m1 "trunk diameter (DBH)" \
            | awk '{print $5}' \
            | tr -d ',')

        HEIGHT=$(echo "$TREEINFO_OUTPUT" \
            | grep -m1 "tree height (m)" \
            | awk '{print $4}' \
            | tr -d ',')


        # ====================================================
        # QC
        # ============================================================

        if [ "$N_RCT_TREES" = "1" ]; then
            STATUS="OK"
        else
            STATUS="REVIEW_MULTIPLE_TREES"
        fi


        # ====================================================
        # TERMINAL OUTPUT
        # ============================================================

        echo ""
        echo "Ergebnis $TREE_ID"
        echo "  Status:    $STATUS"
        echo "  RCT trees: $N_RCT_TREES"
        echo "  Volume:    $VOLUME m3"
        echo "  DBH:       $DBH m"
        echo "  Height:    $HEIGHT m"


        # ====================================================
        # SUMMARY
        #
        # vorhandene Zeile dieses Baumes zuerst entfernen
        # ============================================================

        TMP_FILE="${SUMMARY_FILE}.tmp"

        awk -F',' \
            -v plot="$PLOT_NAME" \
            -v tree="$TREE_ID" \
            'NR==1 || !($1==plot && $2==tree)' \
            "$SUMMARY_FILE" > "$TMP_FILE"

        mv "$TMP_FILE" "$SUMMARY_FILE"

        echo "$PLOT_NAME,$TREE_ID,$STATUS,$N_RCT_TREES,$VOLUME,$DBH,$HEIGHT" \
            >> "$SUMMARY_FILE"

    done

done


echo ""
echo "============================================================"
echo "FERTIG"
echo "============================================================"
echo ""
echo "Summary:"
echo "$SUMMARY_FILE"
echo ""


# ============================================================
# WORKFLOW-ZUSAMMENFASSUNG
# ============================================================
#
# Dieses Skript verarbeitet bereits vorsegmentierte Einzelbaum-
# Punktwolken im LAZ-Format mit RayCloudTools / RayExtract.
#
# Für jeden Eingabeordner werden alle *.laz-Dateien gefunden.
# Für jeden einzelnen Baum wird ein eigener Output-Ordner erzeugt.
#
# Verarbeitung pro Baum:
#
# 1. rayimport
#    - liest die ursprüngliche LAZ-Punktwolke direkt ein
#    - erzeugt eine RCT-kompatible Raycloud als *.ply
#    - mit --remove_start_pos werden große absolute Koordinaten
#      auf lokale Koordinaten verschoben
#
# 2. rayextract terrain
#    - berechnet aus der Einzelbaum-Punktwolke ein lokales
#      Terrain-/Ground-Mesh
#    - Output: *_mesh.ply
#
# 3. rayextract trees
#    - rekonstruiert die holzige Baumstruktur
#    - erzeugt das eigentliche QSM sowie weitere Kontroll-Dateien
#
#    Wichtige Outputs:
#      *_trees.txt
#          -> eigentliches QSM mit Baum-/Aststruktur
#
#      *_trees_mesh.ply
#          -> visualisierbares 3D-QSM-Mesh
#             z.B. zur Kontrolle in CloudCompare
#
#      *_segmented.ply
#          -> interne RCT-Segmentierung der Punktwolke
#
# 4. treeinfo
#    - liest das erzeugte QSM aus
#    - berechnet u.a.:
#          Holzvolumen [m3]
#          DBH [m]
#          Baumhöhe [m]
#          Anzahl erkannter Bäume
#    - erzeugt zusätzlich *_trees_info.txt
#
# QUALITÄTSKONTROLLE:
#
# Da die Eingabedateien bereits jeweils einen einzelnen
# vorsegmentierten Baum enthalten, sollte RCT normalerweise
# genau einen Baum erkennen:
#
#      n_trees = 1  -> OK
#
# Werden mehrere Bäume erkannt:
#
#      n_trees > 1  -> REVIEW_MULTIPLE_TREES
#
# Dies kann z.B. bei fehlerhafter Vorsegmentierung,
# tiefen Ästen oder einer problematischen Stammbasis auftreten.
# Solche Bäume sollten anhand des *_trees_mesh.ply in
# CloudCompare visuell kontrolliert werden.
#
# Alle Tree-Level-Ergebnisse werden zusätzlich in einer
# gemeinsamen CSV-Datei zusammengeführt:
#
#      RCT_QSM_summary.csv
#
# Die ursprünglichen LAZ-Dateien werden nicht verändert.
#
# ============================================================
