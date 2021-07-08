# add travis ssh key 
eval `ssh-agent -s`
ssh-add - <<< "${DEPLOY_SSH_KEY}"
echo "${DEPLOY_PUB_KEY}" > /home/travis/.ssh/id_rsa.pub


# Remove .gitignore and replace with the production version
rm -f .gitignore
cp scripts/prodignore .gitignore
cat .gitignore

# copy files inside the generated HTML directory to the webserver.
rsync -azP ./docs/_build/html/ koinos@173.255.232.131:/var/www/html