#!/bin/bash

[[ "$TRACE" ]] && set -x
set -eo pipefail

config_variable_add_property() {
	# Variables must be upper-case
	# Properties must be lower-case
	export "${1}_${2}=$3"
}

config_save_severity() {
	local var_name="$1"
	local severity="${2:-optional}"
	export "${var_name}_severity=$severity"
}

config_variables_list() {
	printf "$CONFIG_VARIABLES" \
	| grep -v -E "^\s*$"
}

config_variables_add() {
	local var_name="$1"
	export "CONFIG_VARIABLES=$var_name\n$CONFIG_VARIABLES"
}

config_variable() {
	local var_name="$1"
	# Set to value, fallback to default $2
	local value="${!var_name:-$2}"
	# Append prefix and suffix if value is given
	export "$var_name=${value:+$4$value$5}"
	# Register variable
	config_variables_add "$var_name"
	# Save default plus prefix and suffix
	config_variable_add_property "$var_name" "default" "${2:+$4$2$5}"
	# Save severity
	config_variable_add_property "$var_name" "severity" "${3:-optional}"
}

config_variable_reset() {
	local var_name="$1"
	config_variable	"$var_name" "${!${var_name}_default}" "${!${var_name}_severity}"
}

config_ok() {
	local config_error=false
	for config_variable in $(config_variables_list); do
		[[ "${!config_variable}" ]] && continue
		local severity_var="${config_variable}_severity"
		case "${!severity_var}" in
			required)
				printf "[ERROR/CONFIG] $config_variable is not defined but required!\n"
				config_error=true
			;;
			recommended)
				printf "[INFO/CONFIG] $config_variable is not defined yet!\n"
			;;
		esac
	done
	[[ "$config_error" = "true" ]] \
	&& return 1 \
	|| return 0
}

config_variables() {
	config_variables_list
}

config_print() {
	local target="${1:-/proc/self/fd/1}"
	config_variables_list \
	| while read config_variable; do
		local severity_var="${config_variable}_severity"
		printf "# ${!severity_var}\nexport $config_variable='${!config_variable}'\n" >> "$target"
	done
}

config_module() {
	local cmd="$1"
	shift
	case "$cmd" in
		print|update)
			config_print $@
			exit $?
		;;
		ok)
			"config_ok" $@
			exit $?
		;;
		variables|env-file|transfer)
			"config_variables" $@
			exit $?
		;;
	esac
	exit $?
}