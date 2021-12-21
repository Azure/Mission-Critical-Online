#!/bin/bash

# This script loops through the directory with queries and replaces placeholders to each of them in the dashboard file. 

# Target file that contains the {{filename.kql}} placeholders for the queries:
dashfile=provisioning/dashboards/json/solutionhealth.json

# Source directory for the dashboard queries:
querydir=dashboard_queries

for f in $querydir/* ; do
  echo "Inserting query $f"

  # Read query from file, escape quotes and slashes and merge into single line
  query=$( sed -z 's#["\]#\\\\\\&#g;s/\n/\\\\n/g' $f) || continue

  # Replace {{filename}} in dashboard value with $query
  sed -i -e "s~{{${f##*/}}}~$query~g" $dashfile
done
