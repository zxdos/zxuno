#!/bin/bash -e
# extract.sh - extract contents of an archive.
#
# SPDX-FileCopyrightText: 2021 Ivan Tatarinov <ivan-tat@ya.ru>
#
# SPDX-License-Identifier: GPL-3.0-or-later

declare -a errors
declare -A tmp_files
declare o_input
declare o_check=0
declare o_sha256
declare o_type
declare o_subdir=.
declare o_output
declare o_use_tmp=0

msg_err_begin() {
	echo -en '\E[1;31m'
}

msg_err_end() {
	echo -en '\E[0m'
}

# $1 = message
add_error() {
	errors[${#errors[@]}]="$1"
}

# $1 = argument name, $2 = argument index
add_missing_arg_error() {
	add_error "Missing parameter for '$1' (argument #$2)."
}

exit_on_errors() {
	local -i i
	local -i N
	N=${#errors[@]}
	if [[ $N -ne 0 ]]; then
		msg_err_begin >&2
		i=0
		while [[ $i -lt $N ]]; do
			echo "$BASH_SOURCE: Error ($((i+1))): ${errors[$i]}" >&2
			let i=i+1
		done
		echo -n "$BASH_SOURCE: " >&2
		if [[ $N -eq 1 ]]; then
			echo -n "$N error occured." >&2
		else
			echo -n "$N errors occured." >&2
		fi
		echo " Stopped." >&2
		msg_err_end >&2
		exit 1
	fi
}

# $1 = message (optional)
error_exit() {
	if [[ -n "$1" ]]; then
		msg_err_begin >&2
		echo "$1" >&2
		msg_err_end >&2
	fi
	exit 1
}

# $1 = temporary file name
new_tmp_file() {
	tmp_files[$1]=f
}

# $1 = temporary directory name
new_tmp_dir() {
	tmp_files[$1]=d
}

# $1 = temporary file or directory name
free_tmp() {
	unset tmp_files[$1]
}

# $1 = temporary file name
rm_tmp_file() {
	rm -f "$1"
	free_tmp "$1"
}

# $1 = temporary directory name
rm_tmp_dir() {
	rm -rf "$1"
	free_tmp "$1"
}

rm_all_tmps() {
	local t
	if [[ ${#tmp_files[*]} -gt 0 ]]; then
		OFS="$IFS"
		IFS=`echo -en "\t"`
		for t in ${!tmp_files[*]}; do
			case ${tmp_files[$t]} in
			f)
				rm_tmp_file "$t"
				;;
			d)
				rm_tmp_dir "$t"
				;;
			esac
		done
		IFS="$OFS"
	fi
}

show_usage() {
	cat <<EOT
Usage:
  $BASH_SOURCE [--sha256 SHA256] --type TYPE [--subdir SUBDIR] --output DIR [--use-tmp-dir] [--] input_file
Where:
  --sha256 SHA256	check SHA256 message digest of input file
  --type TYPE		type of input archive (.zip, .tar.gz, .tar.bz2, .7z)
  --subdir SUBDIR	specify SUBDIR sub-directory of input file to strip
  --output DIR		specify output directory
  --use-tmp-dir		use temporary directory
EOT
}

OnError() {
	local err=$?
	msg_err_begin >&2
	echo "$BASH_SOURCE: Error on line $BASH_LINENO: Exit status $err. Stopped." >&2
	msg_err_end >&2
	exit $err
}

OnExit() {
	rm_all_tmps
}

trap OnError ERR
trap OnExit EXIT

if [[ $# -eq 0 ]]; then
	show_usage
	exit
fi

parse_option=1
i=1
while [[ $# -gt 0 ]]; do
	non_option=0
	if [[ $parse_option -eq 1 ]]; then
		case "$1" in
		--sha256)
			if [[ $# -eq 1 ]]; then
				add_missing_arg_error $1 $i
				break
			fi
			o_check=1
			o_sha256=$2
			shift 2
			let i=i+1
			;;
		--type)
			if [[ $# -eq 1 ]]; then
				add_missing_arg_error $1 $i
				break
			fi
			case "$2" in
			.zip|.tar.gz|.tar.bz2|.7z)
				o_type=$2
				;;
			*)
				add_error "Unknown archive type specified: '$2' (argument #$((i+1)))."
				;;
			esac
			shift 2
			let i=i+1
			;;
		--subdir)
			if [[ $# -eq 1 ]]; then
				add_missing_arg_error $1 $i
				break
			fi
			o_subdir=$2
			shift 2
			let i=i+1
			;;
		--output)
			if [[ $# -eq 1 ]]; then
				add_missing_arg_error $1 $i
				break
			fi
			o_output=$2
			shift 2
			let i=i+1
			;;
		--use-tmp-dir)
			o_use_tmp=1
			shift 1
			;;
		--)
			parse_option=0
			shift 1
			;;
		-*)
			add_error "Unknown option '$1' (argument #$i)."
			shift 1
			;;
		*)
			non_option=1
			;;
		esac
	else
		non_option=1
	fi
	if [[ $non_option -eq 1 ]]; then
		if [[ -z "$o_input" ]]; then
			o_input="$1"
		else
			add_error "Extra input file specified: '$1' (argument #$i)."
		fi
		shift 1
	fi
	let i=i+1
done

if [[ -z "$o_input" ]]; then
	add_error "No input file specified."
fi

if [[ -z "$o_type" ]]; then
	add_error "No input file type specified."
fi

if [[ -z "$o_output" ]]; then
	add_error "No output directory specified."
fi

#~ echo "$BASH_SOURCE: o_input:   \"$o_input\""
#~ echo "$BASH_SOURCE: o_check:   $o_check"
#~ echo "$BASH_SOURCE: o_sha256:  \"$o_sha256\""
#~ echo "$BASH_SOURCE: o_type:    \"$o_type\""
#~ echo "$BASH_SOURCE: o_subdir:  \"$o_subdir\""
#~ echo "$BASH_SOURCE: o_output:  \"$o_output\""
#~ echo "$BASH_SOURCE: o_use_tmp: $o_use_tmp"

exit_on_errors

tmp=`mktemp`
new_tmp_file "$tmp"
echo "$o_sha256  $o_input" >"$tmp"
sha256sum -c "$tmp"
rm_tmp_file "$tmp"

if [[ $o_use_tmp -eq 0 ]]; then
	if [[ "$o_subdir" != "$o_output" && "$o_subdir" != '.' ]]; then
		rm -rf "$o_subdir"
	fi
	echo "Extracting archive, please wait..."
	case "$o_type" in
	.zip)
		if [[ "$o_subdir" = '.' ]]; then
			unzip -nq -d "$o_output" "$o_input"
		else
			unzip -nq "$o_input"
		fi
		;;
	.tar.gz)
		if [[ "$o_subdir" = '.' ]]; then
			add_error "Not implemented for '$o_type': subdir='$o_subdir'."
			exit_on_errors
		else
			tar -xzf "$o_input"
		fi
		;;
	.tar.bz2)
		if [[ "$o_subdir" = '.' ]]; then
			add_error "Not implemented for '$o_type': subdir='$o_subdir'."
			exit_on_errors
		else
			tar -xjf "$o_input"
		fi
		;;
	.7z)
		if [[ "$o_subdir" = '.' ]]; then
			7z x -bd -o"$o_output" "$o_input"
		else
			7z x -bd "$o_input"
		fi
		;;
	*)
		add_error "Not supported archive type: '$o_type'."
		exit_on_errors
		;;
	esac
	if [[ "$o_subdir" != "$o_output" && "$o_subdir" != '.' ]]; then
		mv "$o_subdir" "$o_output"
	fi
else
	add_error "Temporary directory usage is not implemented yet."
	exit_on_errors
fi
