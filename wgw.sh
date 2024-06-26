#!/bin/bash

Repo="/config/auth/wireguard"
declare -A DispNames
WG=""								# Path to Wireguard (if not set, finds with "which")
[ -t 1 ] && RT=1 || RT=""					# If we have a terminal set RT (richtext)
trap "exit 1" TERM
export TOP_PID=$$

[ ! -z "$RT" ] && {
	CB="$(tput bold)"					# Bold
	CH="${CB}$(tput setaf 7)"				# Header Color
	CN="${CB}$(tput setaf 6)"				# Name Color
	CS="${CB}$(tput setaf 3)"				# Section Color
	CK="${CB}$(tput setaf 2)"				# Key Color
	CV="$(tput setaf 6)"					# Values Color (6-cyan or 3-brown)
	CR="$(tput sgr0)"					# Reset Colors
}

#--------------------------------------------------------------------------------------------------------------------------
# Utility Functions
#--------------------------------------------------------------------------------------------------------------------------
trim() {
	local x="${1#"${1%%[!   ]*}"}"                          #Trim leading spaces and tabs
	while [[ "${x:${#x}-1:1}" == $'\015' || "${x:${#x}-1:1}" == $'\012' || "${x:${#x}-1:1}" == $'\009' ]]; do
		x="${x:0:${#x}-1}"
	done
	echo -n "${x%"${x##*[!  ]}"}"                           #Trim trailing spaces and tabs
}

NoAnsi() {
	#printf '%s' "$*" | sed 's/\x1b\[[0-9]\{0,\}m\{0,1\}\x0f\{0,1\}//g'
	printf '%s' "$*" | sed -r "s/\x1B\[[0-9;]*[JKmsu]//g"
}

Echo() {
	local Switches="%s\r\n"; [ "$1" == "-n" ] && { shift; Switches="%s"; }
	local Line="$*"
	[ -z "$RT" ] && Line="$(NoAnsi "$*")"
	printf "$Switches" "$Line"
	[ ! -z "$Debug" ] && {
		[ ${#Switches} -eq 2 ] && echo ""
		EchoHex "$Line"
	}
}

EchoHex() {
	printf '%s\r\n' "$(printf '%s' "$*" | hexdump -ve '/1 "%02X"')"
}

Error() {
	printf 'ERROR: %s\r\n' "$*"
	kill -s TERM $TOP_PID
	exit 1				# Shouldn't reach this line
}

#--------------------------------------------------------------------------------------------------------------------------
# App Functions
#--------------------------------------------------------------------------------------------------------------------------
Usage() {
	Echo "Usage: $Basename <command> <arguments>"
	Echo ""
	Echo "$Basename internal commands:"
	Echo "  show: Calls wg for current config and device info and adds friendly names"
	Echo "  initialize: Initialize repository folder structure and create server keys"
	Echo "  client <show>|<addkey>|<listkeys>: Show, add, or list client keys"
	Echo "  server <show>|<endpoint>|<ipaddress>|<createkeys>: Show server template information, set it, or initialize keys"
	Echo ""
	Echo "<command> can also be any valid wg command:"
	$WG --help
}

LoadNames() {
	local FoundFile
	while read FoundFile; do
		local FileName="$(basename "$FoundFile")"
		local Name="${FileName%.*}"
		local Key="$(cat "$FoundFile")"
		DispNames["$Key"]="$Name"
		[ ! -z "$Debug" ] && Echo "Name=$Name, Key=$Key, DispNames.Count=${#DispNames[@]}"
	done <<< "$(find "$Repo/clients" -maxdepth 1 -mindepth 1 -type f -iname "*.publickey")"
}

ShowInfo() {
	LoadNames
	#echo "[$(trim "  XXYY  ")]"
	script --flush --quiet /dev/null --command "sudo $WG" | while read Line_Raw; do
		local Line_NoCR="${Line_Raw//[$'\t\r\n']}"
		local Line_NoAnsi="$(NoAnsi "$Line_NoCR")"
		case "$Line_NoAnsi" in
			peer:*)
				local PubKey="${Line_NoAnsi#*: }"
				[ ! -z "$Debug" ] && Echo "PubKey=\"$PubKey\""
				local DispName="${DispNames["$PubKey"]}"
				Echo -n "$Line_NoCR"
				#[ ! -z "$DispName" ] && printf '%s' "$(tput sgr0) ($(tput bold)$(tput setaf 6)$DispName$(tput sgr0))"
				[ ! -z "$DispName" ] && printf '%s' "${CR} (${CN}${DispName}${CR})"
				Echo ''
				;;
			interface:*)
				Echo "$Line_NoCR"
				;;
			*)
				Echo "  $Line_NoCR"
				;;
		esac
	done
}

Initialize() {
	local DateStamp="$(date +"%Y%m%d%H%M")"
	[ -d "$Repo/server" ] && {
		mv "$Repo/server" "$Repo/server.$DateStamp"
		Echo "WARNING: Existing server folder renamed to: $Repo/server.$DateStamp"
	}
	[ -d "$Repo/clients" ] && {
		mv "$Repo/clients" "$Repo/clients.$DateStamp"
		Echo "WARNING: Existing clients folder renamed to: $Repo/clients.$DateStamp"
	}
	mkdir "$Repo/server" && {
		Echo "Server keys folder created: $Repo/server"
		mkdir "$Repo/clients" && {
			Echo "Client keys folder created: $Repo/clients"
		}
	}
	CreateServerKeys
}

CreateServerKeys() {
	local DateStamp="$(date +"%Y%m%d%H%M")"
	[ -f "$Repo/server/privatekey" ] && {
		mv "$Repo/server/privatekey" "$Repo/server/privatekey.$DateStamp"
		Echo "WARNING: Existing server private key renamed to: $Repo/server/privatekey.$DateStamp"
		[ -f "$Repo/server/publickey"] && {
			mv "$Repo/server/publickey" "$Repo/server/publickey.$DateStamp"
			Echo "WARNING: Existing server public key renamed to: $Repo/server/publickey.$DateStamp"
		}
	}
	$WG genkey | tee "$Repo/server/privatekey" | $WG pubkey > "$Repo/server/publickey"
	ShowServer
}

AddClientKey() {
	local Client="$1"
	[ -z "$Client" ] && Error "$Basename client addkey <name>: can't be empty"
	[ -f "$Repo/clients/$Client.privatekey" ] && Error "Client \"$Client\" already exists"
	[ ! -f "$Repo/server/privatekey" ] && Error "Server private key isn't set.  To create it use: $Basename server createkeys"
	$WG genkey | tee "$Repo/clients/$Client.privatekey" | $WG pubkey > "$Repo/clients/$Client.publickey"
	Echo "Client keys created for: \"$Client\""
	ShowClient "$Client"
}

ShowClient() {
	local Client="$1"
	[ ! -f "$Repo/clients/$Client.privatekey" ] && Error "Private key for client \"$Client\" does not exist"
	[ ! -f "$Repo/server/publickey" ] && Error "Server public  key is missing"
	[ -f "$Repo/server/endpoint.txt" ] && local Endpoint="$(cat "$Repo/server/endpoint.txt")" || local Endpoint="<not set>"
	[ -f "$Repo/server/ipaddress.txt" ] && local AllowedIP="$(cat "$Repo/server/ipaddress.txt")" || local AllowedIP="<Server_VPN_Peer_IP_Address>"
	Echo "# ${CH}Client name${CR}: ${CN}$Client${CR}"
	Echo "# ${CH}Public key${CR}:  ${CV}$(cat "$Repo/clients/$Client.publickey")${CR}"
	Echo "# -----[ Remote Client Config File ]-----"
	Echo "[${CS}Interface${CR}]"
	Echo "${CH}PrivateKey${CR} = ${CV}$(cat "$Repo/clients/$Client.privatekey")${CR}"
	Echo "${CH}Address${CR} = xxx.xx.xxx.xxx/xx"
	Echo ""
	Echo "[${CS}Peer${CR}]"
	Echo "${CH}Endpoint${CR} = $Endpoint"
	Echo "${CH}PublicKey${CR} = ${CV}$(cat "$Repo/server/publickey")${CR}"
	Echo "${CH}AllowedIPs${CR} = ${AllowedIP},<Additional_ServerSide_Subnet>"
}

ListClientKeys() {
	LoadNames
	local Key
	Echo "${CH}Public Key                                    Name${CR}"
	for Key in ${!DispNames[@]}; do
		Echo "${CV}${Key}  ${CN}${DispNames["$Key"]}${CR}"
	done
}

ShowServer() {
	[ -f "$Repo/server/endpoint.txt" ] && local Endpoint="$(cat "$Repo/server/endpoint.txt")" || local Endpoint="<not set>"
	[ -f "$Repo/server/ipaddress.txt" ] && local AllowedIP="$(cat "$Repo/server/ipaddress.txt")" || local AllowedIP="<not set>"
	Echo "# -----[ Server Configuration ]-----"
	Echo "${CH}Private key${CR}:           ${CV}$(cat "$Repo/server/privatekey")${CR}"
	Echo "${CH}Public key${CR}:            ${CV}$(cat "$Repo/server/publickey")${CR}"
	Echo "${CH}Endpoint text${CR}:         $Endpoint"
	Echo "${CH}Peer IP Address text${CR}:  $AllowedIP"
}

client() {
	case "$2" in
		""|list|listkeys)
			ListClientKeys
			;;
		add|addkey)
			shift 2
			AddClientKey "$@"
			;;
		show|showkey)
			shift 2
			ShowClient "$@"
			;;
		*)
			Error "$Basename client: unrecognized subcommand: \"$2\""
			;;
	esac
}

server() {
	case "$2" in
		""|show)
			ShowServer
			;;
		createkeys)
			CreateServerKeys
			;;
		endpoint)
			shift 2
			[ -z "$@" ] && Error "Server endpoint text can't be empty"
			printf '%s' "$@" > "$Repo/server/endpoint.txt"
 			Echo "Server endpoint for client config templates set to \"$@\""
			;;
		ipaddress)
			shift 2
			[ -z "$@" ] && Error "Server IP Address text can't be empty"
			printf '%s' "$@" > "$Repo/server/ipaddress.txt"
 			Echo "Server peer IP Addresss text for client config templates set to \"$@\""
			;;
		*)
			Error "$Basename server: unrecognized subcommand: \"$2\""
			;;
	esac
}

#--------------------------------------------------------------------------------------------------------------------------
# Start of main code
#--------------------------------------------------------------------------------------------------------------------------
	[ ! -d "$Repo" ] && Error "Base repository folder ($Repo) doesn't exist.  (Either make it or change the Repo= variable.)"

	[ -z "$WG" ] && WG=$(which wg)
	[ -z "$WG" ] && Error "Can't find WireGuard binary (wg)."

	Basename=$(basename "$0")
	case "$1" in
		help|--help)
			Usage
			;;
		initialize}
			Initialize
			;;
		""|show)
			ShowInfo
			;;
		server|client)
			$1 "$@"
			;;
		*)
			"$WG" "$@"
			;;
	esac
	exit 0
