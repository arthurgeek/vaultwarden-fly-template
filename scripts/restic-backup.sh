#!/bin/sh

EMAIL_SUBJECT_PREFIX="[Restic] "
LOG="/var/log/restic/$(date +\%Y\%m\%d_\%H\%M\%S).log"

notify() {
    cat "${LOG}" | mail -s "${EMAIL_SUBJECT_PREFIX}${1}" ${SMTP_TO}
}

# prepare_restic
mkdir -p /var/log/restic/

if restic cat config >/dev/null 2>&1; then
    echo -e "skipping restic repo init\n------------\n" | tee -a "$LOG"
else
    echo -e "initializing restic\n------------\n" | tee -a "$LOG"
    restic init | tee -a "$LOG" 2>&1
fi

# prepare_backup
sqlite3 /data/db.sqlite3 ".backup '/data/backup.bak'"

# backup
echo -e "restic backup\n------------\n" | tee -a "$LOG"
restic backup --verbose --exclude="db.*" /data | tee -a "$LOG" 2>&1
if [ $? -ne 0 ]
then
    notify "Failed Vaultwarden backup"
    exit 2
fi

# check consistency of the repository
echo -e "\n------------\nrestic check\n-----------\n" | tee -a "$LOG"
restic check | tee -a "$LOG" 2>&1
if [ $? -ne 0 ]
then
    notify "Failed Vaultwarden check"
    exit 3
fi

# remove outdated snapshots
echo -e "\n-------------\nrestic forget\n------------\n" | tee -a "$LOG"
restic forget \
        --keep-daily 7 \
        --keep-weekly 4 \
        --keep-monthly 3 \
        --keep-yearly 3 \
        --prune \
        | tee -a "$LOG" 2>&1
if [ $? -ne 0 ]
then
    notify "Failed Vaultwarden forget"
    exit 4
fi
