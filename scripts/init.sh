#!/bin/bash

dos2unix remote_lists.txt
readarray -t BLOCKLIST_DOWNLOADS < remote_lists.txt

BL_FILE="/tmp/hosts-blocklist.txt"
BL_TMP_FILE="/tmp/hosts-blocklist.txt.tmp"

rm -f $BL_FILE
touch $BL_FILE

## Keep a "cache" around so that if the remote site is (temporarily) not reachable one can still build the final list
echo "Downloading blocklists..."

BL_DWL_TMP_DIR=/tmp/bl-dwls
rm -rf $BL_DWL_TMP_DIR
mkdir -p $BL_DWL_TMP_DIR

cached_file_names=()
for dwl_url in "${BLOCKLIST_DOWNLOADS[@]}"
do
    if [[ -z $dwl_url ]] || [[ $dwl_url == \#* ]]; then
        continue;
    fi
    file_name=$(echo $dwl_url | sed -r 's@[:/.]+@_@g')
    cached_file_names+=($file_name)

    if [ "$SKIP_DOWNLOAD" = true ]; then
        continue;
    fi
    {
        echo "Downloading blocklist from $dwl_url to $file_name"
        if wget --timeout=30 -qO - $dwl_url > $BL_DWL_TMP_DIR/$file_name; then
            if [ -s $BL_DWL_TMP_DIR/$file_name ]; then
                mv $BL_DWL_TMP_DIR/$file_name /source_cached_remote_lists/$file_name
            else
                echo "[WARN] Empty payload received from $dwl_url - not copying"
            fi
        else
            echo "[WARN] Failed to download $dwl_url"
        fi
    } &
done
wait
echo "Finished downloading"

echo "Importing remote lists"
for to_import in /source_cached_remote_lists/*
do
    file_name=$(basename $to_import)
    if [[ ! " ${cached_file_names[*]} " =~ " ${file_name} " ]]; then
        echo "[WARN] Deleting $to_import as it's not on the download list"
        rm -f $to_import
        continue;
    fi
    echo "Importing remote lists $to_import"
    cat "$to_import" >> $BL_FILE
done
echo "Importing remote lists finished"

echo "Importing local blocklist from local.txt and appending to $BL_FILE"
dos2unix local.txt
cat local.txt >> $BL_FILE

sed -i -e '$a\' $BL_FILE

rm -f $BL_TMP_FILE

cat $BL_FILE | \
  sed \
    -e 's/0.0.0.0//g' \
    -e 's/127.0.0.1//g' \
    -e '/255.255.255.255/d' \
    -e '/::/d' \
    -e '/#/d' \
    -e 's/\t/ /g' \
    -e 's/ //g' \
    -e 's/  //g' \
    -e '/^$/d' \
    -e 's/^/0.0.0.0 /g' | \
  awk '!a[$0]++' > $BL_TMP_FILE

echo "Removing duplicates from the list..."
sort -u $BL_TMP_FILE -o $BL_FILE

echo "Filtering out false positives / allowlisting"

dos2unix allowlist.txt
readarray -t ALLOWLIST_ENTRIES < allowlist.txt

for allowlist_entry in "${ALLOWLIST_ENTRIES[@]}"
do
    echo "Filtering out $allowlist_entry"
    sed -i "/0.0.0.0 $allowlist_entry/d" $BL_FILE
done

cat $BL_FILE > $OUT_FILE
