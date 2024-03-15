#!/usr/bin/env bash
set -e

mypath=$(ls -lah `which bacula-dir` | awk '{ print $11 }')
mypath="${mypath%/*}"  # Remove the last part of the path
mypath="${mypath%/*}"
mypath=$mypath/etc/make_postgresql_tables
script=$(cat $mypath)
sql=$(echo "$script" | awk '/END-OF-DATA/ {p=0} p; /<<END-OF-DATA/ {p=1}')

database_address={{ database_address }}
echo "sql" | PGPASSWORD={{ database_password }} psql -h $database_address -U bacula bacula 
