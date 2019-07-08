#!/bin/bash

################################################################################################
#                                  Stitchoker Interface                                        #
#                                                                                              #
# $self  $path_flag  $path  $command  $first_flag  $second_flag  $flags                        #
#        $1          $2     $3        $4           $5            ${@:4}                        #
# scr    -p          path   up        -d           backend       eg. stacks (basic front back) #
################################################################################################

function scr
{
	local fn="stitchocker"
	local help="
	Usage:
		$fn [-a <arg>...] [alias] [docker-compose COMMAND] [SETS...]
		$fn [docker-compose COMMAND] [SETS...]
		$fn -h|--help

	Options:
		-h  Shows this help text
		-p  Path to stitching directory
		-a  Alias to stitching directory
		
	Examples:
		$fn up
		$fn up default backend frontend
		$fn -a my-projects-alias-from-env up default backend frontend
	"

	local debug=$(scr_env stitchocker_debug)
	if [[ ! -z $debug && $debug == true ]]; then
		debug=true
	else
		debug=false
	fi

	local self="scr"
	local path_flag="-p"
	local exec="$self $path_flag"

	if [ $# -lt 1 ]; then
		echo "$help"
		exit 1
	fi

    # Entrypoint
	case $1 in
		# Main handler
		$path_flag)
			# Function arguments
			local path="$2"
			local command="$3"
			local first_flag="$4"
			local second_flag="$5"
			local flags="${@:4}"

			if [[ -z $path ]]; then
				scr_error "Path not specified"
			fi

			if [[ -z $command ]]; then
				scr_error "Command not specified"
			fi

			# if [[ $first_flag == "--all" ]]; then
			# 	for service_name in $(cd $path && ls -d */) ; do
			# 		local path="$path/$service_name"
			# 		local cmd="$exec $path $command"
			# 		if [[ $command != "up" ]]; then
			# 			local cmd="$cmd $flags"
			# 		else
			# 			local cmd="$cmd -d"
			# 		fi
			# 		eval $cmd
			# 	done
			# fi

			# General variables
			local config="docker-compose.yaml"
			local config_path="$path/$config"

			if [[ ! -e $config_path ]]; then
				config="docker-compose.yml"
				config_path="$path/$config"
				if [[ ! -e $config_path ]]; then
					scr_error "No such file or directory: '$config_path'"
				fi
			fi

			local default_set=$(scr_env stitchocker_default_set)
			if [[ ! -z $default_set && $default_set != "null" ]]; then
				default_set="$default_set"
			else
				default_set="default"
			fi

			local sets_field="scr_config_sets"

			scr_create_yaml_variables $config_path "scr_config_"

			local sets_data="$(eval echo \$${sets_field}_${default_set})"

			if [[ ! -z $sets_data ]]; then
				if	[[ ! -z $first_flag ]]; then
					if [[ ! -z $second_flag ]]; then
						for set in $flags; do
							eval "$exec $path $command $set"
						done
					fi
					local set="$first_flag"
				else
					local set="$default_set"
				fi

				local services="$(eval echo \${${sets_field}_${set}[*]})"

				if [[ -z $services ]]; then
					scr_error "Your config doesn't have \"$set\" value"
				fi

				echo
				scr_info "$(echo "$command" | awk '{print toupper(substr($0,0,1))tolower(substr($0,2))}') $set set:"

				for service_alias in ${services}; do
					if [[ $service_alias == *"@"* ]]; then
						local set="${service_alias//@}"
						eval "$exec $path $command $set"
					else
						if [[ $service_alias == *"/"* ]]; then
							local service_path="$(scr_env $service_alias)"
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
					fi
				done
			else
				local cmd="docker-compose -f $config_path $command $flags"

				if [[ $debug == false ]]; then
					eval $cmd
				else
					echo $cmd
				fi
			fi
		;;
		# Path flag wrapper
		"-a")
			if [[ -z $2 ]]; then
				scr_error "Path alias not specified"
			fi

			if [[ -z $3 ]]; then
				scr_error "Command not specified"
			fi

			local path=$(scr_env $2)
			eval "$exec $path ${@:3}"
		;;
		# Help page
		"-h")
			echo "$help"
			exit 0
		;;
		# Help page
		"--help")
			echo "$help"
			exit 0
		;;
		# Default path flag wrapper
		*)
			local path=$(pwd)
			eval "$exec $path $command $@"
		;;
	esac
}

# -----------------------------------------------
# Tools
# -----------------------------------------------

function scr_env
{
    local env_alias=$(echo $1 | cut -d "/" -f 1)
    local env_additional_path=${1//"$env_alias/"}
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

# --
# Messages
# --

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

# --
# Data parsing
# --

##
# Based on https://gist.github.com/pkuczynski/8665367
# From https://github.com/jasperes/bash-yaml
##
function scr_parse_yaml() {
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

function scr_create_yaml_variables() {
    local yaml_file="$1"
    local prefix="$2"

	if [[ ! -z $prefix ]]; then
		scr_unset_yaml_variables $prefix
	fi

    eval "$(scr_parse_yaml "$yaml_file" "$prefix")"
}

function scr_unset_yaml_variables()
{
	local prefix="$1"
	local variables=$( set -o posix; set |  cut -f1 -d"=" | grep $prefix )

	for variable in $variables; do
		unset $variable
	done
}


# -----------------------------------------------
# Bootstrap
# -----------------------------------------------

scr $@
