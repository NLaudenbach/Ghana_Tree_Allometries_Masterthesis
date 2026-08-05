library(lidR)
library(ITSMe)
library(openxlsx)

# Ordner und Ausgabedatei
tree_dirs <- c(
  "/home/laudenb/Bonus_Trees_SAV",
  "/home/laudenb/Segmented_Trees_SAV"
)

output_file <- "/home/laudenb/ITSMe_DBH_DAB_results_SAV.xlsx"

# Alle LAZ-Dateien aus beiden Ordnern
tree_files <- sort(unlist(
  lapply(tree_dirs, list.files, pattern = "\\.laz$", full.names = TRUE)
))

cat("Gefundene Baumdateien:", length(tree_files), "\n")

# Hilfsfunktion: Wert unabhängig von Groß-/Kleinschreibung auslesen
get_value <- function(x, possible_names) {
  if (is.null(x)) return(NA_real_)
  
  x_names <- names(x)
  if (is.null(x_names)) return(NA_real_)
  
  match_pos <- match(
    tolower(possible_names),
    tolower(x_names),
    nomatch = 0
  )
  
  match_pos <- match_pos[match_pos > 0]
  
  if (length(match_pos) == 0) return(NA_real_)
  
  value <- x[[match_pos[1]]]
  
  if (length(value) == 0 || is.null(value)) {
    return(NA_real_)
  }
  
  value
}

# Ergebnisliste
results <- vector("list", length(tree_files))

for (i in seq_along(tree_files)) {
  
  file <- tree_files[i]
  tree_id <- tools::file_path_sans_ext(basename(file))
  
  cat(
    "\n[", i, "/", length(tree_files), "] ",
    tree_id, "\n",
    sep = ""
  )
  
  # LAZ einlesen
  las <- readLAS(file)
  
  if (is.empty(las)) {
    warning("Leere Punktwolke: ", tree_id)
    
    results[[i]] <- data.frame(
      tree_id = tree_id,
      file = file,
      n_points = 0,
      height_m = NA_real_,
      dbh_cm = NA_real_,
      fdbh_cm = NA_real_,
      r2 = NA_real_,
      arc_coverage = NA_real_,
      inner_circle_empty = NA,
      dab_cm = NA_real_,
      fdab_cm = NA_real_,
      dab_height_m = NA_real_,
      status = "leere Punktwolke"
    )
    
    next
  }
  
  # ITSMe benötigt nur X, Y und Z
  tree_pc <- as.data.frame(las@data[, c("X", "Y", "Z")])
  
  n_points <- nrow(tree_pc)
  height_m <- max(tree_pc$Z, na.rm = TRUE) -
    min(tree_pc$Z, na.rm = TRUE)
  
  # Standardwerte, falls eine Berechnung fehlschlägt
  dbh_result <- NULL
  dab_result <- NULL
  status <- "OK"
  
  # DBH und funktionalen DBH berechnen
  dbh_result <- tryCatch(
    dbh_pc(
      pc = tree_pc,
      functional = TRUE,
      plot = FALSE
    ),
    error = function(e) {
      warning(tree_id, " – DBH-Fehler: ", conditionMessage(e))
      status <<- paste("DBH-Fehler:", conditionMessage(e))
      NULL
    }
  )
  
  # Problembaum ohne funktionalen DAB berechnen
  use_functional_dab <- tree_id != "SAV_T620_3"
  
  dab_result <- tryCatch(
    dab_pc(
      pc = tree_pc,
      functional = use_functional_dab,
      maxbuttressheight = 2.5,
      plot = FALSE
    ),
    error = function(e) {
      warning(tree_id, " – DAB-Fehler: ", conditionMessage(e))
      status <<- paste("DAB-Fehler:", conditionMessage(e))
      NULL
    }
  )
  
  # Werte aus den ITSMe-Ergebnissen auslesen
  dbh_m <- get_value(dbh_result, c("dbh", "DBH"))
  fdbh_m <- get_value(dbh_result, c("fdbh", "fDBH"))
  
  r2 <- get_value(dbh_result, c("r2", "R2", "r_squared"))
  arc_coverage <- get_value(
    dbh_result,
    c("arc_coverage", "arccoverage")
  )
  inner_circle_empty <- get_value(
    dbh_result,
    c("inner_circle_empty", "innercircleempty")
  )
  
  dab_m <- get_value(dab_result, c("dab", "DAB"))
  fdab_m <- get_value(dab_result, c("fdab", "fDAB"))
  dab_height_m <- get_value(
    dab_result,
    c(
      "dab_height",
      "dabheight",
      "measurement_height",
      "height"
    )
  )
  
  # Beim Problembaum muss fDAB ausdrücklich fehlen
  if (!use_functional_dab) {
    fdab_m <- NA_real_
    status <- "OK – DAB ohne funktionalen Fit"
  }
  
  # NaN sauber als NA speichern
  numeric_values <- list(
    dbh_m = dbh_m,
    fdbh_m = fdbh_m,
    r2 = r2,
    arc_coverage = arc_coverage,
    dab_m = dab_m,
    fdab_m = fdab_m,
    dab_height_m = dab_height_m
  )
  
  numeric_values <- lapply(
    numeric_values,
    function(x) {
      x <- suppressWarnings(as.numeric(x)[1])
      if (length(x) == 0 || is.nan(x)) NA_real_ else x
    }
  )
  
  results[[i]] <- data.frame(
    tree_id = tree_id,
    file = file,
    n_points = n_points,
    height_m = height_m,
    dbh_cm = numeric_values$dbh_m * 100,
    fdbh_cm = numeric_values$fdbh_m * 100,
    r2 = numeric_values$r2,
    arc_coverage = numeric_values$arc_coverage,
    inner_circle_empty = as.logical(inner_circle_empty)[1],
    dab_cm = numeric_values$dab_m * 100,
    fdab_cm = numeric_values$fdab_m * 100,
    dab_height_m = numeric_values$dab_height_m,
    status = status
  )
  
  # Zwischenergebnis direkt anzeigen
  print(results[[i]])
}

# Alle Bäume zu einer Tabelle verbinden
results_df <- do.call(rbind, results)
rownames(results_df) <- NULL

# Tabelle in R anzeigen
print(results_df)
View(results_df)

# Als Excel-Datei speichern
write.xlsx(
  results_df,
  output_file,
  overwrite = TRUE
)

cat(
  "\nFertig.\n",
  "Verarbeitete Bäume: ", nrow(results_df), "\n",
  "Excel-Datei: ", output_file, "\n",
  sep = ""
)

file.exists(output_file)


### Visualisierung

library(lidR)
library(ITSMe)

# Ordner mit den einzelnen Baumdateien
tree_dirs <- c(
  "/home/laudenb/Bonus_Trees_SAV",
  "/home/laudenb/Segmented_Trees_SAV"
)

tree_files <- sort(unlist(
  lapply(
    tree_dirs,
    list.files,
    pattern = "\\.laz$",
    full.names = TRUE
  )
))

cat("Gefundene Bäume:", length(tree_files), "\n")

for (i in seq_along(tree_files)) {
  
  file <- tree_files[i]
  tree_id <- tools::file_path_sans_ext(basename(file))
  
  cat(
    "\n---------------------------------\n",
    "[", i, "/", length(tree_files), "] ",
    tree_id,
    "\n---------------------------------\n",
    sep = ""
  )
  
  las <- readLAS(file)
  
  if (is.empty(las)) {
    warning("Leere Punktwolke: ", tree_id)
    next
  }
  
  # ITSMe benötigt nur XYZ
  tree_pc <- as.data.frame(
    las@data[, c("X", "Y", "Z")]
  )
  
  # DBH-Querschnitt
  tryCatch(
    {
      dbh_pc(
        pc = tree_pc,
        functional = TRUE,
        plot = TRUE
      )
      
      # Baum-ID oben rechts in den Plot schreiben
      grid::grid.text(
        paste("Baum:", tree_id),
        x = 0.98,
        y = 0.98,
        just = c("right", "top"),
        gp = grid::gpar(
          fontsize = 14,
          fontface = "bold"
        )
      )
    },
    error = function(e) {
      warning(
        tree_id,
        " – DBH-Plot nicht möglich: ",
        conditionMessage(e)
      )
    }
  )
  
  # Bei diesem Baum nur normalen DAB berechnen
  use_functional_dab <- tree_id != "SAV_T620_3"
  
  # DAB-Querschnitt
  tryCatch(
    {
      dab_pc(
        pc = tree_pc,
        functional = use_functional_dab,
        maxbuttressheight = 2.5,
        plot = TRUE
      )
      
      # Baum-ID oben rechts in den Plot schreiben
      grid::grid.text(
        paste("Baum:", tree_id),
        x = 0.98,
        y = 0.98,
        just = c("right", "top"),
        gp = grid::gpar(
          fontsize = 14,
          fontface = "bold"
        )
      )
    },
    error = function(e) {
      warning(
        tree_id,
        " – DAB-Plot nicht möglich: ",
        conditionMessage(e)
      )
    }
  )
}

cat("\nAlle Querschnitte wurden erstellt.\n")