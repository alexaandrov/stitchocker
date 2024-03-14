#!/bin/bash

######################################################################################################
#                                      Stitchoker Interface                                          #
#                                                                                                    #
# $self        $path_flag  $path  $command  $first_flag  $second_flag  $flags                        #
#              $1          $2     $3        $4           $5            ${@:4}                        #
# stitchocker  -p          path   up        -d           backend       eg. stacks (basic front back) #
######################################################################################################

stitchocker() {
  local self="stitchocker"
  local version="1.2.3"
  local version_info="Stitchocker version $version"
  local help="
  Usage:
    $self [--verbose|--debug] [-a <env_alias>] [docker-compose COMMAND] [SETS...]
    $self -h|--help
    $self -v|--version

  Options:
    -h|--help            Shows this help text
    -v|--version         Shows $self version
    --update             Updates $self to the latest stable version
    --debug              Runs all commands in debug mode
    --verbose            Runs all commands in verbose mode
    -p                   Path to stitching directory
    -a                   Alias to stitching directory

  Examples:
    $self up
    $self up default backend frontend
    $self -a my-projects-alias-from-env up default backend frontend
    $self --debug -a my-projects-alias-from-env up default backend frontend
    $self --verbose -a my-projects-alias-from-env up default backend frontend
  "

  local debug_env=""$self"_debug"
  local debug=$(env $debug_env)
  if [[ ! -z $debug && $debug == true ]]; then
    debug=true
  else
    debug=false
  fi

  local verbose_env=""$self"_verbose"
  local verbose=$(env $verbose_env)
  if [[ ! -z $verbose && $verbose == true ]]; then
    verbose=true
  else
    verbose=false
  fi

  local path_flag="-p"
  local exec="$self $path_flag"

  if [ $# -lt 1 ]; then
    info "$help"
    exit 1
  fi

  # Entrypoint
  case $1 in
  # --------------------------------------------------------------
  # Help info
  # --------------------------------------------------------------
  "-h" | "--help")
    info --exit "$help"
    ;;
  # --------------------------------------------------------------
  # Version info
  # --------------------------------------------------------------
  "-v" | "--version")
    info --exit "$version_info"
    ;;
  # --------------------------------------------------------------
  # Updates to the latest stable version
  # --------------------------------------------------------------
  "--update")
    sudo bash -c "$(curl -H 'Cache-Control: no-cache' -fsSL https://raw.githubusercontent.com/alexaandrov/stitchocker/master/install.sh)"
    exit 0
    ;;
  # --------------------------------------------------------------
  # Runs all commands in debug mode
  # --------------------------------------------------------------
  "--debug")
    local debug_export="export $(echo $debug_env | awk '{print toupper($0)}')"
    eval "$debug_export=true"
    $self ${@:2}
    eval "$debug_export=false"
    ;;
  # --------------------------------------------------------------
  # Runs all commands in verbose mode
  # --------------------------------------------------------------
  "--verbose")
    local verbose_export="export $(echo $verbose_env | awk '{print toupper($0)}')"
    eval "$verbose_export=true"
    $self ${@:2}
    eval "$verbose_export=false"
    ;;
  # --------------------------------------------------------------
  # The entry point for all commands
  # --------------------------------------------------------------
  $path_flag)
    # Function arguments
    local path="$2"
    local command="$3"
    local first_flag="$4"
    local second_flag="$5"
    local flags="${@:4}"
    local config_env="$self.env"

    if [[ -z $path ]]; then
      error "Path not specified"
    fi

    if [[ -z $command ]]; then
      error "Command not specified"
    fi

    if [[ $command == "down" ]]; then
      $self -p $path stop $flags
    fi

    if [[ $command == "reload" ]]; then
      $self -p $path down $flags
      $self -p $path up $flags
      exit 1
    fi

    local available_config_names=("$self.yml" "$self.yaml" "docker-compose.yaml" "docker-compose.yml")
    local available_dirs=(".dev" ".local")

    local custom_config_env=""$self"_config"
    local custom_config_name=$(env $custom_config_env)
    if [[ ! -z $custom_config_name && $custom_config_name != "null" ]]; then
      available_config_names+=($custom_config_name)
    fi

    local config_path=""
    for subdir in ${available_dirs[@]}; do
      for config_name in ${available_config_names[@]}; do
        if [[ -f "$path/$config_name" ]]; then
          config_path="$path/$config_name"
          break 2
        elif [[ -f "$path/$subdir/$config_name" ]]; then
          config_path="$path/$subdir/$config_name"
          break 2
        fi
      done
    done

    if [[ ! -f $config_path ]]; then
      error --no-exit "No config found for: $path"
      info --exit "Available config names: ${available_config_names[@]}\nAvailable config directories: ${available_dirs[@]}"
    fi

    local default_set=$(env ${self}_default_set)
    if [[ ! -z $default_set && $default_set != "null" ]]; then
      default_set="$default_set"
    else
      default_set="default"
    fi

    local sets_field="${self}_config_sets"

    create_yaml_variables $config_path "${self}_config_"

    local sets_data="$(eval echo \$${sets_field}_${default_set})"

    if [[ ! -z $sets_data ]]; then
      if [[ ! -z $first_flag ]]; then
        if [[ ! -z $second_flag ]]; then
          for set in $flags; do
            eval "$exec $path $command $set"
          done
          exit 1
        fi
        local set=$(echo "$first_flag" | tr '-' '_')
        local set_info=$first_flag
      else
        local set="$default_set"
        local set_info=$set
      fi

      local services="$(eval echo \${${sets_field}_${set}[*]})"
      local search_mode="set"

      if [[ -z $services ]]; then
        search_mode="directory"
        warn "Your ${self} config doesn't have \"$set_info\" value. Trying to find an existing directory on path."
        services=$flags
      fi

      info "$(echo "$command" | awk '{print toupper(substr($0,0,1))tolower(substr($0,2))}') $set_info $search_mode:"

      for service_alias in ${services}; do
        local service_alias_head="$(echo $service_alias | head -c 1)"
        if [[ $service_alias == *"/"* ]]; then
          if [[ $service_alias_head == "@" ]]; then
            local service_alias="${service_alias//@/}"
            local service_path="$(env $service_alias)"
          elif [[ $service_alias_head == "/" || $service_alias_head == "~" ]]; then
            local service_path="$service_alias"
          else
            local service_path="$path/$service_alias"
          fi

          local cmd="$exec $service_path $command"
          if [[ $command != "up" ]]; then
            cmd="$cmd"
          else
            cmd="$cmd -d"
          fi
          eval $cmd
        elif [[ $service_alias_head == "@" ]]; then
          local set="${service_alias//@/}"
          eval "$exec $path $command $set"
        else
          local service_path="$path/$service_alias"
          local cmd="$exec $service_path $command"

          if [[ $command != "up" ]]; then
            cmd="$cmd"
          else
            cmd="$cmd -d"
          fi
          eval $cmd
        fi
      done
    else
      # --------------------------------------------------------------
      # The main unit where commands are generated for docker compose
      # --------------------------------------------------------------
      if [[ -z $config_env ]]; then
        local config_env="$self.env"
      fi

      env_handle "$initial_path" "$config_env" "$path"

      if [[ -f "$initial_path/.env" ]]; then
        local cmd_env="--env-file $initial_path/.env"
      else
        local cmd_env=""
      fi

      if docker compose version | grep "Docker Compose version" &>/dev/null; then
        local docker_compose="docker compose"
      elif docker-compose version | grep "Docker Compose version" &>/dev/null; then
        local docker_compose="docker-compose"
      fi

      local cmd="$docker_compose $cmd_env -f $config_path $command $flags"

      if [[ $debug == false ]]; then
        if [[ $verbose == true ]]; then
          echo $cmd
        fi
        echo "$(
          cd $initial_path
          $cmd
        )"
      else
        echo $cmd
      fi

      env_handle -c "$initial_path"
    fi
    return 1
    ;;
  # --------------------------------------------------------------
  # Entry point wrapper
  # Triggered when stitchocker -a {alias} {command}
  # --------------------------------------------------------------
  "-a")
    if [[ -z $2 ]]; then
      error "Path alias not specified"
    fi

    if [[ -z $3 ]]; then
      error "Command not specified"
    fi

    local path=$(env $2)
    local initial_path=$path
    eval "$exec $path ${@:3}"
    ;;
  # --------------------------------------------------------------
  # Default entry point wrapper
  # Triggered when stitchocker {command}
  # --------------------------------------------------------------
  *)
    local path=$(pwd)
    local initial_path=$path
    eval "$exec $path $command $@"
    ;;
  esac
}

# -----------------------------------------------
# Tools
# -----------------------------------------------

##
# Returns absolute path to user env
##
env() {
  local env_alias=$(echo $1 | cut -d "/" -f 1)
  local env_additional_path=${1//$env_alias\//}
  local env=$(echo $env_alias | awk '{print toupper($0)}')

  local env_path="$(eval "echo \"\$$env\"")"

  if [[ ! -z "$env_additional_path" && "$env_alias" != "$env_additional_path" ]]; then
    env_path="$env_path/$env_additional_path"
  fi

  if [[ $env_path == *"himBHs"* || -z $env_path ]]; then
    echo "null"
  fi

  echo $env_path
}

##
# Adds an environment from config to each service
##
env_handle() {
  local env_name=".env"
  if [[ $1 != "-c" ]]; then
    local path="$1"
    local config_env="$2"
    local env_path="$path/$env_name"

    if [[ ! -z $path && ! -z $config_env ]]; then
      local config_env_path="$path/$config_env"
      local service_env_name=".env"
      local service_env_path="$service_path/$service_env_name"

      # If stitchocker env file exist use it
      if [[ -f $config_env_path ]]; then
        cp $config_env_path $env_path
      fi

      # If the service has its own env file, it will expand the existing env file
      if [[ -f $service_env_path ]]; then
        echo >>$env_path
        cat $service_env_path >>$env_path
      fi
    fi
  else
    # Remove temporary env file
    local path="$2"
    local env_path="$path/$env_name"
    if [[ -f $env_path ]]; then
      rm $env_path
    fi
  fi
}

# --
# Messages
# --

info() {
  local green=$(tput setaf 2)
  local reset=$(tput sgr0)

  if [[ $1 != "--exit" ]]; then
    echo -e "${green}$@${reset}"
    echo
  else 
    echo -e "${green}${@:2}${reset}"
    exit 0
  fi
}

warn() {
  local grey=$(tput setaf 8)
  local reset=$(tput sgr0)
  echo -e "${grey}$@${reset}"
  echo
}

error() {
  local red=$(tput setaf 1)
  local reset=$(tput sgr0)

  if [[ $1 != "--no-exit" ]]; then
    echo >&2 -e "${red}$@${reset}"
    exit 1
  else
    echo >&2 -e "${red}${@:2}${reset}"
    echo
  fi
}

# --
# Data parsing
# --

##
# Based on https://gist.github.com/pkuczynski/8665367
# From https://github.com/jasperes/bash-yaml
##
parse_yaml() {
  local yaml_file=$1
  local prefix=$2
  local s
  local w
  local fs

  s='[[:space:]]*'
  w='[a-zA-Z0-9_.-]*'
  fs="$(echo @|tr @ '\034')"

  (
      sed -e '/- [^\“]'"[^\']"'.*: /s|\([ ]*\)- \([[:space:]]*\)|\1-\'$'\n''  \1\2|g' |
      sed -ne '/^--/s|--||g; s|\"|\\\"|g; s/[[:space:]]*$//g;' \
          -e "/#.*[\"\']/!s| #.*||g; /^#/s|#.*||g;" \
          -e "s|^\($s\)\($w\)$s:$s\"\(.*\)\"$s\$|\1$fs\2$fs\3|p" \
          -e "s|^\($s\)\($w\)${s}[:-]$s\(.*\)$s\$|\1$fs\2$fs\3|p" |

      awk -F"$fs" '{
          indent = length($1)/2;
          if (length($2) == 0) { conj[indent]="+";} else {conj[indent]="";}
          vname[indent] = $2;
          for (i in vname) {if (i > indent) {delete vname[i]}}
              if (length($3) > 0) {
                  vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
                  printf("%s%s%s%s=(\"%s\")\n", "'"$prefix"'",vn, $2, conj[indent-1],$3);
              }
          }' |
      sed -e 's/_=/+=/g' |

      awk 'BEGIN {
              FS="=";
              OFS="="
          }
          /(-|\.).*=/ {
              gsub("-|\\.", "_", $1)
          }
          { print }'
  ) < "$yaml_file"
}

create_yaml_variables() {
  local yaml_file="$1"
  local prefix="$2"

  if [[ ! -z $prefix ]]; then
    unset_yaml_variables $prefix
  fi

  eval "$(parse_yaml "$yaml_file" "$prefix")"
}

unset_yaml_variables() {
  local prefix="$1"
  local variables=$( set -o posix; set |  cut -f1 -d"=" | grep $prefix )

  for variable in $variables; do
    unset $variable
  done
}

# -----------------------------------------------
# Bootstrap
# -----------------------------------------------

stitchocker $@
