#!/bin/bash

# Colors
HIGHLIGHT_COLOR='\e[36m'
TITLE_COLOR='\e[4m\e[1m'
DONE_COLOR='\e[1;32m'
ERROR_COLOR='\e[41m'
NO_COLOR='\e[0m'

# Output functions
debug(){
  log "${1}"
  echo -e "${HIGHLIGHT_COLOR}${1}${NO_COLOR}"
}
title(){
  log "== ${1} =="
  echo -e "${TITLE_COLOR}${1}${NO_COLOR}"
}
success(){
  log "== ${1} =="
  log ""
  echo -e "${DONE_COLOR}${TITLE_COLOR}${1}${NO_COLOR}"
}
error(){
  local errormsg="Error: ${1}"
  log "${errormsg}"
  echo -e "${ERROR_COLOR}${errormsg}${NO_COLOR}"
}
say_done(){
  local donemsg="Done."
  if [[ ! -z "${1}" ]]; then
    donemsg="${1}"
  fi
  log "${donemsg}"
  echo -e "${DONE_COLOR}$donemsg${NO_COLOR}"
}

# Logging
log(){
  datestamp="$(date +\%c)"
  filedate="$(date +\%Y\%m\%d)"
  if [[ -z "${CAMERA}" ]]; then
    echo "[${datestamp}] ${1}" >> /var/log/watchtower/null_camera.log 2>&1
  else
    echo "[${datestamp}] ${1}" >> /var/log/watchtower/camera_${CAMERA}.${filedate}.log 2>&1
  fi
}

# Camera stuff
take_picture(){
  camera_source="/dev/video${CAMERA}"
  debug "Camera: ${camera_source}"

  resolution=""
  if [[ ! -z "${RESOLUTION}" ]]; then
    debug "Resolution: ${RESOLUTION}"
    resolution="-s ${RESOLUTION}"
  fi

  quality=""
  if [[ ! -z "${QUALITY}" ]]; then
    debug "Quality: ${QUALITY}"
    quality="-q ${QUALITY}"
  fi

  delay=""
  if [[ ! -z "${DELAY}" ]]; then
    debug "Delay: ${DELAY}"
    delay="-ss ${DELAY}"
  fi


  filedate="$(date +\%Y\%m\%d)"
  outputdir="/var/watchtower/cameras/${CAMERA}" && mkdir -p "${outputdir}"
  outputdir="${outputdir}/images" && mkdir -p "${outputdir}"
  outputdir="${outputdir}/$(date +\%Y)" && mkdir -p "${outputdir}"
  outputdir="${outputdir}/$(date +\%m-\%d)" && mkdir -p "${outputdir}"
  output="${outputdir}/$(date +\%H:\%M:\%S).jpg"
  debug "Output file: ${output}"

  debug "Capturing image..."
  avconv -f video4linux2 -i ${camera_source} ${resolution} ${quality} ${delay} -vframes 1 ${output} >> /var/log/watchtower/camera_${CAMERA}.${filedate}.log 2>&1
  say_done
}

# Run the script
while getopts ':c:q:r:d:' opt; do
  case "${opt}" in
    c) CAMERA="$OPTARG" ;;
    q) QUALITY="$OPTARG" ;;
    r) RESOLUTION="$OPTARG" ;;
    d) DELAY="$OPTARG" ;;
    *) echo "Unknown option: -${OPTARG}" >&2
       exit ;;
  esac
done


if [[ -z "${CAMERA}" ]]; then
  error "No camera specified"
  exit 1
fi

title "Taking photo..."
take_picture
success "Picture taken."
