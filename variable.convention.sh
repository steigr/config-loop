#!/usr/bin/env bash

[[ "$TRACE" ]] && set -x
set -eo pipefail

variable_convention_all() {
	cat <<EO_CONVENTIONAL_VARIABLES
APP_DATA_DIR
APP_TEMP_DIR
APP_INSTALL_DIR
APP_URL
DATABASE_URL
KVSTORE_URL
MAIL_URL
MESSAGEBUS_URL
EO_CONVENTIONAL_VARIABLES
}

variable_convention_alias() {
	local original_variable="$1"
	local convention_variable="$2"
	export "$2=${!1}"
}