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

# If an attached filename has "(1)" in it (which happens with XPOs), 
# it will be renamed like this by munpack:
# SharedProject_aka_VCS(1).desc -> SharedProject_aka_VCSXX1X.desc
# We need to get rid of that:
cd ${output_dir}

for f in `ls`
do
  new_name=`ls ${f} | awk -F'XX.+X' '{print $1$2}' `
  mv ${f} ${new_name}
done
