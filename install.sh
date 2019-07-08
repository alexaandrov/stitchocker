#!/bin/bash

function scr_install
{
    set -e

    # Set variables

    local destination_path="/tmp"
    local bin_path="/usr/local/bin"
    local stitchoker_uri="https://raw.githubusercontent.com/alexaandrov/stitchocker/0.0.1/stitchocker.sh"
    local stitchocker_name="stitchoker"
    local stitchocker_tmp_path="$destination_path/$stitchocker_name.sh"
    local stitchocker_bin_path="$bin_path/$stitchocker_name"

    scr_info "Downloading $stitchocker_name"

    curl --url $stitchoker_uri --output $stitchocker_tmp_path

    scr_info "Installing $stitchocker_name"

    mv $stitchocker_tmp_path $stitchocker_bin_path

    chmod +x $stitchocker_bin_path

    scr_info "Installation complete!"
    scr_info "Run $stitchocker_name -h to see the help"
}

function scr_info {
  local green=$(tput setaf 2)
  local reset=$(tput sgr0)
  echo -e "${green}$@${reset}"
}

function scr_error {
  local red=$(tput setaf 1)
  local reset=$(tput sgr0)
  echo >&2 -e "${red}$@${reset}"
  exit 1
}

scr_install "$@"