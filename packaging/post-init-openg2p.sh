#!/usr/bin/env bash

#ODOO_CONF_FILE=
#ODOO_ADDONS_DIR=
#ODOO_VOLUME_DIR=
#ODOO_DATABASE_NAME=
EXTRA_ADDONS_PATH="/opt/bitnami/odoo/extraaddons"

for dir in $EXTRA_ADDONS_PATH/*/; do
  ODOO_ADDONS_DIR="$ODOO_ADDONS_DIR,${dir%/}"
done

if [ -n "$EXTRA_ADDONS_URLS_TO_PULL" ]; then
  EXTRA_ADDONS_PULLED_DIR=$ODOO_VOLUME_DIR/extraaddons
  mkdir -p $EXTRA_ADDONS_PULLED_DIR
  IFS=",";
  for addon_pull_url in $EXTRA_ADDONS_URLS_TO_PULL; do
    if [[ $addon_pull_url == "git://"* ]]; then
      package_value=${addon_pull_url#"git://"}
      branch_name=${package_value%%"//"*}
      git_address=${package_value#*"//"}
      repo_name=$(basename $git_address)
      repo_name=${repo_name%.*}

      if ! [ -d $EXTRA_ADDONS_PULLED_DIR/$repo_name ]; then
        git clone --depth 1 -b ${branch_name} ${git_address} $EXTRA_ADDONS_PULLED_DIR/$repo_name
      fi
      if [ -f $EXTRA_ADDONS_PULLED_DIR/$repo_name/requirements.txt ]; then
        source $ODOO_BASE_DIR/venv/bin/activate;
        pip install -f $EXTRA_ADDONS_PULLED_DIR/$repo_name/requirements.txt
        deactivate
      fi
    # elif [[ ${PACKAGES_VALUES[i]} == "file://"* ]]; then
    # TBD: Define other prefixes.
    fi
  done
  unset IFS
  for addon_dir in $EXTRA_ADDONS_PULLED_DIR/*/*/; do
    if ! [ -e $ODOO_VOLUME_DIR/addons/$(basename $addon_dir) ]; then
      ln -s ${addon_dir%/} $ODOO_VOLUME_DIR/addons/$(basename $addon_dir)
    fi
  done
fi

TO_REPLACE=$(grep -i addons_path $ODOO_CONF_FILE)
sed -i "s#$TO_REPLACE#addons_path = $ODOO_ADDONS_DIR#g" $ODOO_CONF_FILE

TO_REPLACE=$(grep -i limit_time_real $ODOO_CONF_FILE)
sed -i "s/$TO_REPLACE/limit_time_real = $LIMIT_TIME_REAL/g" $ODOO_CONF_FILE

if [ -n "$OPENG2P_SMTP_PORT" ] ; then
  TO_REPLACE=$(grep -i smtp_port $ODOO_CONF_FILE)
  sed -i "s/$TO_REPLACE/smtp_port = $OPENG2P_SMTP_PORT/g" $ODOO_CONF_FILE
fi

if [ -n "$OPENG2P_SMTP_HOST" ] ; then
  TO_REPLACE=$(grep -i smtp_server $ODOO_CONF_FILE)
  sed -i "s/$TO_REPLACE/smtp_server = $OPENG2P_SMTP_HOST/g" $ODOO_CONF_FILE
fi

if ! [ "$LIST_DB" = "true" ]; then
  TO_REPLACE=$(grep -i list_db $ODOO_CONF_FILE)
  sed -i "s/$TO_REPLACE/list_db = $LIST_DB/g" $ODOO_CONF_FILE
fi

if ! [ "$LIST_DB" = "true" ]; then
  TO_REPLACE=$(grep -i dbfilter $ODOO_CONF_FILE)
  sed -i "s/$TO_REPLACE/dbfilter = $ODOO_DATABASE_NAME/g" $ODOO_CONF_FILE
fi

if [ -n "$LOG_DB" ]; then
  TO_REPLACE=$(grep -i log_db $ODOO_CONF_FILE)
  sed -i "s/$TO_REPLACE/log_db = $LOG_DB/g" $ODOO_CONF_FILE
fi

if [ -n "$LOG_HANDLER" ]; then
  TO_REPLACE=$(grep -i log_handler $ODOO_CONF_FILE)
  sed -i "s/$TO_REPLACE/log_handler = $LOG_HANDLER/g" $ODOO_CONF_FILE
fi

if [ -n "$SERVER_WIDE_MODULES" ]; then
  TO_REPLACE=$(grep -i server_wide_modules $ODOO_CONF_FILE)
  if [ -z "$TO_REPLACE" ]; then
    echo "server_wide_modules = $SERVER_WIDE_MODULES" >> $ODOO_CONF_FILE
  else
    sed -i "s/$TO_REPLACE/server_wide_modules = $SERVER_WIDE_MODULES/g" $ODOO_CONF_FILE
  fi
fi
