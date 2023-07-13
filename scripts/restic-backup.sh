#!/bin/sh

# catch the error in case first pipe command fails (but second succeeds)
set -o pipefail
# turn on traces, useful while debugging but commented out by default
# set -o xtrace

EMAIL_SUBJECT_PREFIX="[Restic]"
LOG="/var/log/restic/$(date +\%Y\%m\%d_\%H\%M\%S).log"

# create log dir
mkdir -p /var/log/restic/

# e-mail notification
function notify() {
    sed -e 's/\x1b\[[0-9;]*m//g' "${LOG}" | mail -s "${EMAIL_SUBJECT_PREFIX} ${1}" ${SMTP_TO}
}

function log() {
    "$@" 2>&1 | tee -a "$LOG"
}

function run_silently() {
    "$@" >/dev/null 2>&1
}

# ###########################################################
# colorized echo helpers
# taken from: https://github.com/atomantic/dotfiles/blob/master/lib_sh/echos.sh
# ###########################################################

ESC_SEQ="\x1b["
COL_RED=$ESC_SEQ"31;01m"
COL_BLUE=$ESC_SEQ"34;01m"
COL_GREEN=$ESC_SEQ"32;01m"
COL_YELLOW=$ESC_SEQ"33;01m"
COL_RESET=$ESC_SEQ"39;49;00m"

function ok() {
    log echo -e "$COL_GREEN[ok]$COL_RESET $1"
}

function running() {
    log echo -en "$COL_BLUE ⇒ $COL_RESET $1..."
}

function warn() {
    log echo -e "$COL_YELLOW[warning]$COL_RESET $1"
}

function error() {
    log echo -e "$COL_RED[error]$COL_RESET $1"
    log echo -e "$2"
}

function notify_and_exit_on_error() {
    output=$(eval $1 2>&1)

    if [ $? -ne 0 ]; then
        error "$2" "$output"
        notify "$2"
        exit 2
    fi
}

# ###########################################################
# backup steps
# ###########################################################

running "checking restic config"

run_silently restic cat config

if [ $? -ne 0 ]; then
    warn "restic repo either not initialized or erroring out"
    running "trying to initialize it"
    notify_and_exit_on_error "restic init" "Repo init failed"
fi

ok

running "backing up sqlite database"
notify_and_exit_on_error "sqlite3 /data/db.sqlite3 '.backup /data/backup.bak'" "SQLite backup failed"
ok

running "restic backup"
notify_and_exit_on_error "restic backup --verbose --exclude='db.*' /data" "Restic backup failed"
ok

running "checking consistency of restic repository"
notify_and_exit_on_error "restic check" "Restic check failed"
ok

running "removing outdated snapshots"
notify_and_exit_on_error "restic forget --keep-daily 7 --keep-weekly 4 --keep-monthly 3 --keep-yearly 3 --prune" "Restic forget failed"
ok
