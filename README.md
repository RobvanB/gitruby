gitruby
=======

Use ruby to access git.
This class uses a Linux shell script to pull in an email.
Then it extracts the attachments from the email.

It then loops though the attachments and uploads them to GitHub.

The class expects an attachment with an .xpo extension (these are Microsoft
Dynamics AX import/export files to move code)
It also expects an attachment with a .commit extension.
The .commit file should contain a username and date on the first line,
a customer name on the second line, and the commit message after that.

The class also uses an XML file for configuration. This is not included in this
project because it contains the username and password to login to GitHub.

The file should be called gitruby.xml and should have these tags as contents:
 <account>
   <un></un>
   <pw></pw>
   <xpodir>/xpotmp</xpodir>
   <main_repo>AKARepo</main_repo>
 </account>

Meaning of fields:
<un>        :   GitHub username
<pw>        :   GitHub Password
<xpodir>    :   Local directory where the email attachments are stored, and picked up by the clas
<main_repo> :   GitHub Repository name
