#!/bin/sh

# Rob vanBrandenburg voorTech@gmail.com
# August 18, 2013
# Script is part of gitruby https://github.com/RobvanB/gitruby
# Dependencies:
# getmail-4.41.0 http://pyropus.ca/software/getmail
# munpack http://linux.die.net/man/1/munpack

# This script will pull email, then extract the attachments from the email.

## SETUP ##
email_dir=/home/rob/voorTechMail/new
archive_dir=/home/rob/voorTechMail/archive
output_dir=/xpotmp
## END SETUP ##

getmail

for f in `ls ${email_dir}`
do
 munpack -C ${email_dir} ${f}
 mv ${email_dir}/${f} ${archive_dir}
 mv ${email_dir}/* ${output_dir}
done

