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

trapped() {
  trap_signal="$?"
  printf "Trapped with signal: ${trap_signal}\n"
  exit 150
}

trap trapped 1 2 3 4 5 6 7

FD_main() {
  field="${1:?ERR main: field missing, should be 01-16 or GEOCOLOR}"
  sector="${2:?ERR main: sector missing, see header for list}"
  www="${prefix}/${sector}/${field}/"
  fid="${sector}_${field}"
  wd="${sector}/${field}"
  html_tmp="${fid}.html"
  txt_tmp="${fid}.txt"
  dl_rec="download_${fid}.txt"
  wget "$www" -O "$html_tmp"
  htmltree "$html_tmp" > "$txt_tmp"
  egrep "x1808.jpg" "$txt_tmp"    \
    | grep GOES16                 \
    | grep -v href                \
    | sed -e 's/"//g' -e 's/ //g' \
    > "$dl_rec"
  rm "$html_tmp" "$txt_tmp"
  mkdir -p "${wd}"
  parallel --will-cite -vj10 wget -nc -O "${wd}/{}" "${www}{}" :::: "$dl_rec"
}

sector_main() {
  field="${1:?ERR main: field missing, should be 01-16 or GEOCOLOR}"
  sector="${2:?ERR main: sector missing, see header for list}"
  www="${prefix}/SECTOR/${sector}/${field}/"
  fid="SECTOR_${sector}_${field}"
  wd="SECTOR/${sector}/${field}"
  html_tmp="${fid}.html"
  txt_tmp="${fid}.txt"
  dl_rec="download_${fid}.txt"
  wget "$www" -O "$html_tmp"
  htmltree "$html_tmp" > "$txt_tmp"
  egrep "x(1000|1200|1080)\.jpg" "$txt_tmp" \
    | grep GOES16                         \
    | grep -v href                        \
    | sed -e 's/"//g' -e 's/ //g'         \
    > "$dl_rec"
  rm "$html_tmp" "$txt_tmp"
  mkdir -p "${wd}"
  parallel --will-cite -vj10 wget -nc -O "${wd}/{}" "${www}{}" :::: "$dl_rec"
}

for field in 08 GEOCOLOR; do
  for sector in ${sectors[@]}; do
    sector_main $field "$sector"
  done
  FD_main $field "FD"
done
