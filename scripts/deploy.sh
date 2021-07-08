# add travis ssh key 
eval `ssh-agent -s`
ssh-add - <<< "${DEPLOY_SSH_KEY}"
<<<<<<< HEAD
echo "${DEPLOY_PUB_KEY}" > /home/travis/.ssh/id_rsa.pub
=======
echo "${DEPLOY_PUB_KEY}" /home/travis/.ssh/id_rsa.pub
>>>>>>> f332fa0614ddd1d718eaf7c5a14276b430b00537


# Remove .gitignore and replace with the production version
rm -f .gitignore
cp scripts/prodignore .gitignore
cat .gitignore

<<<<<<< HEAD
# copy files inside the generated HTML directory to the webserver.
rsync -azP ./docs/_build/html/ koinos@173.255.232.131:/var/www/html
=======

# Push all changes to the Linode production server
git push -f production HEAD:refs/heads/master
rsync -azP ./docs/_build/html/ koinos@173.255.232.131:/var/www/html
>>>>>>> f332fa0614ddd1d718eaf7c5a14276b430b00537
