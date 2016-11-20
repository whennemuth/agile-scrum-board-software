eval `ssh-agent -s`
ssh-add C:/Users/wrh/.ssh/github_id_rsa
if [ -z "$(git remote | grep github)" ] ; then
   git remote add github git@github.com:whennemuth/agile-scrum-board-software.git
fi
