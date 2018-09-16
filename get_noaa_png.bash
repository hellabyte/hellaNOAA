#!/usr/bin/env bash
# ======================================================================
# get_noaa_png.bash
# ----------------------------------------------------------------------
# Sectors:
#   car -- Caribbean                   -- 1000x1000
#   cgl -- Cent. Great Lakes           -- 1200x1200
#   eus -- Eastern U.S.                -- 1000x1000
#   gm  -- Gulf of Mexico              -- 1000x1000
#   ne  -- North East                  -- 1200x1200 
#   nr  -- Northern Rockies            -- 1200x1200 
#   pnw -- Pacific North West          -- 1200x1200
#   pr  -- Puerto Rico                 -- 1200x1200
#   psw -- Pacific South West          -- 1200x1200 
#   se  -- South East                  -- 1200x1200
#   smv -- Southern Mississippi Valley -- 1200x1200
#   sp  -- Southern Plains             -- 1200x1200 
#   sr  -- Southern Rockies            -- 1200x1200 
#   taw -- Tropical Atlantic Wide-view -- 1800x1080 
#   umw -- U. Mid West                 -- 1200x1200  
#   FD  -- Full Disk                   -- 1808x1808
# ======================================================================
prefix="https://cdn.star.nesdis.noaa.gov/GOES16/ABI"

# car cgl eus gm ne nr pnw pr psw se smv sp sr taw umw
sectors=(
  eus
  psw
  taw
)

fields=(
  08
  GEOCOLOR
)

trapped() {
  trap_signal="$?"
  printf "Trapped with signal: ${trap_signal}\n"
  exit 150
}

trap trapped 1 2 3 4 5 6 7

main() {
  html_file="${1:?ERR main: html_file missing}"
  down_file="${2:?ERR main: down_file missing}"
  wd="${3:?ERR main: working directory missing}"
  wget "$www" -O "$html_file"
  egrep "x(1000|1080|1200|1808)\.jpg" "$html_file" \
    | perl -lane "{ s/(<|>)/\n/g; print }"         \
    | awk '!/href/ && /GOES16/ {print}'            \
    > "$down_file"
  rm "$html_file" 
  mkdir -p "${wd}"
  par_opts=(
    --will-cite 
    -v
    -j10
  )
  parallel ${par_opts[@]} wget -nv -nc -O "${wd}/{}" "${www}{}" :::: "$down_file"
}

FD_header() {
  field="${1:?ERR FD_header: field missing, should be 01-16 or GEOCOLOR}"
  sector="${2:?ERR FD_header: sector missing, see header for list}"
  www="${prefix}/${sector}/${field}/"
  fid="${sector}_${field}"
  wd="${sector}/${field}"
  html_tmp="${fid}.html"
  down_file="download_${fid}.txt"
  main "$html_tmp" "$down_file" "$wd"
}

sector_header() {
  field="${1:?ERR sector_header: field missing, should be 01-16 or GEOCOLOR}"
  sector="${2:?ERR sector_header: sector missing, see header for list}"
  www="${prefix}/SECTOR/${sector}/${field}/"
  fid="SECTOR_${sector}_${field}"
  wd="SECTOR/${sector}/${field}"
  html_tmp="${fid}.html"
  down_file="download_${fid}.txt"
  main "$html_tmp" "$down_file" "$wd"
}

for field in ${fields[@]}; do
  for sector in ${sectors[@]}; do
    sector_header $field "$sector"
  done
  FD_header $field "FD"
done
