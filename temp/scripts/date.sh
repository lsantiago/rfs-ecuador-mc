#!/bin/bash

issueyear=$(date +'%Y')		# 4 digit year
issuemonth=$(date +'%m')	# 2 digit month
issueday=$(date +'%d')		# 2 digit day

yester_year=$(date --date="-1 day" +'%Y')
yester_month=$(date --date="-1 day" +'%m')
yester_day=$(date --date="-1 day" +'%d')

echo $issueyear"-"$issuemonth"-"$issueday
echo $yester_year"-"$yester_month"-"$yester_day


