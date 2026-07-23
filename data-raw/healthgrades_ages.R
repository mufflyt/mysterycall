## Healthgrades Physician Ages (unified, current-year-adjusted)
##
## Source: Healthgrades physician profile scrapes collected 2013-2024, plus the
## GOBA (Google/ABOG board-certification) crosswalk that carries NPI numbers.
## Raw files live on an external drive under BASE (see below) and are NOT shipped
## with the package; this script is provenance only and is run manually.
##
## Pipeline:
##   1. Read all eight age-bearing sources and normalise each to a common schema.
##   2. Adjust every observed age to the current year:
##        age_current = age_at_scrape + (CURRENT_YEAR - scrape_year)
##   3. Deduplicate to one row per physician on normalised (last, first, state),
##      keeping the most recent scrape as the authoritative age and coalescing
##      NPI / middle initial / city / honorific across observations.
##
## GOBA's "age MERGED HG" column has no per-row scrape date; it is tagged
## scrape_year = 2016 (mid-point of the Healthgrades scrape era) so it can be
## re-aged, and flagged via age_source == "goba_merged_hg".

suppressWarnings(suppressMessages({
  library(dplyr); library(readr); library(stringr); library(tidyr)
}))
pkgload::load_all(".", quiet = TRUE)

CURRENT_YEAR <- 2026L
BASE <- "/Volumes/MufflySamsung 1/isochrones_moved/data/healthgrades_2022_scrape_age"

if (!dir.exists(BASE)) {
  stop("Source directory not found (external drive not mounted?):\n  ", BASE,
       call. = FALSE)
}

# ---- helpers ---------------------------------------------------------------
norm <- function(x) x %>% as.character() %>% str_squish() %>% str_to_upper() %>%
  str_replace_all("[.,]", "") %>% na_if("")

honorific_of <- function(x) {                       # MD vs DO from any string
  x <- toupper(as.character(x)); x[is.na(x)] <- ""
  dplyr::case_when(
    str_detect(x, "\\bD\\.?O\\.?\\b|OSTEOPATH") ~ "DO",
    str_detect(x, "\\bM\\.?D\\.?\\b")           ~ "MD",
    TRUE ~ NA_character_
  )
}

parse_age <- function(x) {                          # plausible physician ages only
  n <- suppressWarnings(as.integer(str_extract(as.character(x), "\\d{2,3}")))
  ifelse(!is.na(n) & n >= 25 & n <= 100, n, NA_integer_)
}

mid_initial <- function(mid) {
  mi <- str_to_upper(str_sub(str_squish(mid), 1, 1))
  mi[mi == "" | is.na(str_squish(mid))] <- NA
  mi
}

read_hg <- function(path, ...) suppressWarnings(suppressMessages(
  read_csv(path, show_col_types = FALSE, name_repair = "minimal", ...)))

# ---- Source 1: merged_healthgrades_all (full_name + scrape_date) -----------
src_merged <- function() {
  f <- sort(list.files(BASE, "^merged_healthgrades_all_.*\\.csv$", full.names = TRUE))
  f <- f[which.max(file.mtime(f))]
  d <- read_hg(f)
  p <- mysterycall_parse_physician_name(d$full_name)
  tibble(
    first_name     = p$first_name,
    middle_initial = mid_initial(p$middle_name),
    last_name      = p$last_name,
    honorific      = honorific_of(d$full_name),
    npi            = NA_character_,
    city           = d$city, state = d$state,
    age_at_scrape  = parse_age(d$age_at_scrape),
    scrape_year    = as.integer(str_sub(as.character(d$scrape_date_parsed), 1, 4)),
    age_source     = "merged_all"
  )
}

# ---- Source 2: raw 2013 (structured First / Additional / Last / Honorific) --
src_2013 <- function() {
  d <- read_hg(file.path(BASE, "HealthGradesDatabase from 9.23.2013 CSV.csv"))
  tibble(
    first_name     = d[["First Name"]],
    middle_initial = mid_initial(d[["Additional Name"]]),
    last_name      = d[["Last Name"]],
    honorific      = honorific_of(d[["Honorific Suffix"]]),
    npi            = NA_character_,
    city           = d[["Address City"]], state = d[["Address State"]],
    age_at_scrape  = parse_age(d[["Age"]]),
    scrape_year    = 2013L, age_source = "raw_2013"
  )
}

# ---- Sources 3-4: 2015 & 2016 "from healthgrades" (Full First/Last, Title) --
src_fullname_title <- function(file, year, tag) {
  d  <- read_hg(file.path(BASE, file))
  ff <- str_squish(d[["Full First Name"]])
  tibble(
    first_name     = str_extract(ff, "^\\S+"),
    middle_initial = mid_initial(str_trim(str_remove(ff, "^\\S+"))),
    last_name      = d[["Full Last Name"]],
    honorific      = honorific_of(d[["Title"]]),
    npi            = NA_character_,
    city           = d[["Address 1 - City"]], state = d[["Address 1 - State"]],
    age_at_scrape  = parse_age(d[["Age"]]),
    scrape_year    = as.integer(year), age_source = tag
  )
}

# ---- Source 5: GOBA -> NPI + merged HG age (the NPI-bearing crosswalk) ------
src_goba <- function() {
  hdr  <- names(read_hg(file.path(BASE, "GOBA.csv"), n_max = 0))
  pick <- function(rx) hdr[str_detect(hdr, regex(rx, ignore_case = TRUE))][1]
  cols <- c(
    npi = pick("^NPI Number$"), first = pick("^GOBA_Full\\.First\\.Name$"),
    last = pick("^GOBA_Full\\.Last\\.Name$"), suf = pick("^GOBA_Full\\.Name\\.Suffix$"),
    deg = pick("^GOBA_Degree\\.1$"), cs = pick("^GOBA_CITY_STATE$"),
    st = pick("^GOBA_State$"), age = pick("^age MERGED HG, DOX$")
  )
  d <- read_hg(file.path(BASE, "GOBA.csv"), col_select = all_of(unname(cols)))
  names(d) <- names(cols)[match(names(d), unname(cols))]
  tibble(
    first_name     = d$first, middle_initial = NA_character_, last_name = d$last,
    honorific      = honorific_of(paste(d$suf, d$deg)),
    npi            = str_extract(as.character(d$npi), "\\d{10}"),
    city           = na_if(str_squish(str_remove(d$cs, ",.*$")), ""), state = d$st,
    age_at_scrape  = parse_age(d$age),
    scrape_year    = NA_integer_, age_source = "goba_merged_hg"
  )
}

message("Reading sources ...")
all <- bind_rows(
  src_merged(), src_2013(),
  src_fullname_title("ob gyn 4.25.2016 from healthgrades.csv", 2016, "raw_2016"),
  src_fullname_title("GO 4.25.2015 from healthgrades.csv",     2015, "raw_2015_go"),
  src_fullname_title("FPMRS O 4.25.2015 from healthgrades.csv",2015, "raw_2015_fpmrs"),
  src_fullname_title("mfm 4.25.2015 from healthgrades.csv",    2015, "raw_2015_mfm"),
  src_fullname_title("rei 4.25.2015 from healthgrades.csv",    2015, "raw_2015_rei"),
  src_goba()
)

# ---- Adjust age to CURRENT_YEAR --------------------------------------------
all <- all %>%
  mutate(
    scrape_year_eff = if_else(is.na(scrape_year) & age_source == "goba_merged_hg",
                              2016L, scrape_year),
    age_current = age_at_scrape + (CURRENT_YEAR - scrape_year_eff)
  ) %>%
  filter(!is.na(last_name), !is.na(first_name), !is.na(age_current),
         age_current >= 25, age_current <= 110)

# ---- Clean name artifacts (NMN/NMI, trailing initials, stray punctuation) ---
all <- all %>%
  mutate(
    first_name = str_squish(str_remove_all(first_name, "\\bN\\.?M\\.?[NI]\\.?\\b")),
    first_name = str_squish(str_remove(first_name, "[.,]+$")),
    .init = str_match(first_name, "^(.*\\S)\\s+([A-Za-z])\\.?$"),
    middle_initial = coalesce(middle_initial,
                              if_else(!is.na(.init[, 1]), str_to_upper(.init[, 3]), NA_character_)),
    first_name = if_else(!is.na(.init[, 1]), .init[, 2], first_name),
    last_name  = str_squish(str_remove(last_name, "[.,]+$"))
  ) %>%
  select(-.init) %>%
  filter(str_length(str_remove_all(last_name, "[^A-Za-z]")) >= 2)

# ---- Deduplicate to one row per physician ----------------------------------
# Key: normalised (last, first, state). Missing state is backfilled within a
# (last, first) group only when that group has a single distinct state, so
# stateless rows merge without fusing true homonyms in different states.
healthgrades_ages <- all %>%
  mutate(k_first = norm(first_name), k_last = norm(last_name), k_state = norm(state)) %>%
  group_by(k_last, k_first) %>%
  mutate(.uniq = { s <- unique(k_state[!is.na(k_state)]); if (length(s) == 1) s else NA_character_ },
         k_state = if_else(is.na(k_state) & !is.na(.uniq), .uniq, k_state)) %>%
  ungroup() %>%
  group_by(k_last, k_first, k_state) %>%
  arrange(desc(scrape_year_eff), !is.na(npi), .by_group = TRUE) %>%
  summarise(
    first_name     = first(first_name),
    middle_initial = first(na.omit(middle_initial)) %||% NA_character_,
    last_name      = first(last_name),
    honorific      = first(na.omit(honorific))      %||% NA_character_,
    npi            = first(na.omit(npi))            %||% NA_character_,
    city           = first(na.omit(city))           %||% NA_character_,
    state          = first(na.omit(state))          %||% NA_character_,
    age_current    = first(age_current),
    age_at_scrape  = first(age_at_scrape),
    scrape_year    = first(scrape_year_eff),
    age_source     = first(age_source),
    n_obs          = n(),
    .groups = "drop"
  ) %>%
  mutate(
    first_name = str_to_title(first_name), last_name = str_to_title(last_name),
    city = str_to_title(city), state = str_to_upper(state)
  ) %>%
  select(first_name, middle_initial, last_name, honorific, npi, city, state,
         age_current, age_at_scrape, scrape_year, age_source, n_obs) %>%
  arrange(last_name, first_name) %>%
  as.data.frame(stringsAsFactors = FALSE)

# ---- Validate --------------------------------------------------------------
stopifnot(
  nrow(healthgrades_ages) > 80000L,
  !anyNA(healthgrades_ages$first_name),
  !anyNA(healthgrades_ages$last_name),
  !anyNA(healthgrades_ages$age_current),
  all(healthgrades_ages$age_current >= 25 & healthgrades_ages$age_current <= 110),
  # re-aging identity holds for every row
  all(healthgrades_ages$age_current ==
        healthgrades_ages$age_at_scrape + (CURRENT_YEAR - healthgrades_ages$scrape_year)),
  all(healthgrades_ages$honorific %in% c("MD", "DO", NA)),
  all(is.na(healthgrades_ages$npi) | grepl("^\\d{10}$", healthgrades_ages$npi))
)

message(sprintf("healthgrades_ages: %d physicians | %d with NPI | median age %d",
                nrow(healthgrades_ages), sum(!is.na(healthgrades_ages$npi)),
                as.integer(median(healthgrades_ages$age_current))))

usethis::use_data(healthgrades_ages, overwrite = TRUE, compress = "xz")
