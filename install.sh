#!/bin/bash

function scr_install
{
    set -e

    # Set variables

    local destination_path="/tmp"
    local bin_path="/usr/local/bin"
    local stitchocker_stable_release="1.1.0"
    local stitchoker_uri="https://raw.githubusercontent.com/alexaandrov/stitchocker/$stitchocker_stable_release/stitchocker.sh"
    local stitchocker_name="stitchocker"
    local stitchocker_tmp_path="$destination_path/$stitchocker_name.sh"
    local stitchocker_bin_path="$bin_path/$stitchocker_name"

    scr_info "Downloading $stitchocker_name $stitchocker_stable_release"

    echo
    local http_code=$(curl -H 'Cache-Control: no-cache' --url $stitchoker_uri --output $stitchocker_tmp_path --write-out "%{http_code}")

    if [[ $http_code != 200 ]]; then
      scr_error "An error occurred while downloading the $stitchocker_name. Try again later or manually download the $stitchocker_name."
    fi
    echo

    scr_info "Installing $stitchocker_name"

    if [[ -f $stitchocker_bin_path ]]; then
      scr_info "Removing previous version"
      rm -f $stitchocker_bin_path
    fi

    mv $stitchocker_tmp_path $stitchocker_bin_path

    chmod +x $stitchocker_bin_path

    scr_info "Installation complete!"
    scr_info "Run $stitchocker_name -h to see the help"
    echo
    scr_info "Your $($stitchocker_name --version)"
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
