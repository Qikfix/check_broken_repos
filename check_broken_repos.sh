#!/bin/bash

# check for broken repositories by comparing metadata info.
# based on this solution: https://access.redhat.com/solutions/2653831
# must be run on satellite or capsule
# Note: depending on the number of repos, may take 30 minutes or more.
# usage hints: Use screen and
# nice -10 check_broken_repos.sh | tee -a /var/log/broken_repos_$(date +%F_%H%M%S).log 2>&1
# or
# nice -10 nohup ./check_broken_repos.sh > /var/log/broken_repos_$(date +%F_%H%M%S).log &

# To fix repos, just pass as parameter fix_repos

REPO_PATH=/var/lib/pulp/published/yum/master/yum_distributor
NO_REPOS=$(ls -1 $REPO_PATH | wc -l)
NO_RELEVANT_REPOS=0
BROKEN=0
BROKEN_ORG=0
BROKEN_RPMLINKS=0
FLAT_RPMLINKS=0
ZERO_PKGS_REPOS=0
LOG="/var/log/repos_check.log"
FIX=false
FIXED_REPOS=0

if [ $1 ]; then
  if [ $1 == "fix_repos" ]; then
    FIX=true
  fi
fi


fix_repo()
{
  echo "==== FIX IN ===="												| tee -a $LOG
  echo "Fixing REPO: $1"												| tee -a $LOG
  echo															| tee -a $LOG
  echo "## Mongo Update"												| tee -a $LOG
  echo															| tee -a $LOG
  PULP_ID=$1

  cat << EOF | mongo													| tee -a $LOG
  use pulp_database
  db.repo_distributors.update({repo_id:"$PULP_ID"},{\$set: {"last_publish": null}},{multi:true})
EOF


  echo "## Foreman Rake Console"											| tee -a $LOG
  echo															| tee -a $LOG
  cat << EOF | foreman-rake console											| tee -a $LOG
  User.current = User.first
  aux_repo = Katello::Repository.where(:pulp_id => "$PULP_ID").map()
  pulp_id=""
  aux_repo.each do |item| pulp_id = "#{item.pulp_id}" end

  ForemanTasks.async_task(Actions::Katello::Repository::MetadataGenerate,  Katello::Repository.find_by(:pulp_id => pulp_id), :force => true)
EOF

  echo "==== FIX OUT ===="												| tee -a $LOG
}

check_repo()
{
echo "$(date) INFO: Checking for broken repos..."

for REPO in $(ls -1 $REPO_PATH); do
#  echo "FIX VALUE === $FIX"
  echo "$(date) INFO: Check Repo $REPO ..."										| tee -a $LOG
  if echo "$REPO" | grep ^INGDiBa | grep -v ^INGDiBa-cv | grep -v ^INGDiBa-ccv > /dev/null; then
     ((NO_RELEVANT_REPOS++))
  fi
  METADATA=$(zgrep "metadata packages" $REPO_PATH/$REPO/*/repodata/*-primary.xml.gz | cut -d \" -f2)
  PACKAGES=$(xmllint --format $REPO_PATH/$REPO/*/repodata/*-primary.xml.gz | fgrep -c "<name>" | cut -d \" -f2)
  SUBDIR=$(ls -1 $REPO_PATH/$REPO/)
  RPM_FILES_FLAT=$(find $REPO_PATH/$REPO/$SUBDIR/ -maxdepth 1 -name "*.rpm"|wc -l)
  if [ -d "$REPO_PATH/$REPO/$SUBDIR/Packages/" ]; then
     RPM_FILES_SUBDIRS=$(find $REPO_PATH/$REPO/$SUBDIR/Packages/ -maxdepth 2 -mindepth 2 -name "*.rpm"|wc -l)
  else
     RPM_FILES_SUBDIRS=0
  fi
  RPM_FILES_TOTAL=$(($RPM_FILES_FLAT +  $RPM_FILES_SUBDIRS))
  if [ $METADATA != $PACKAGES ]; then
     echo "$(date) ERROR:      Repo $REPO is broken, metadata packages: $METADATA, package entries: $PACKAGES"		| tee -a $LOG
     ((BROKEN++))
     if echo $REPO | grep -v -e "-cv_" -e "-ccv_"; then
        ((BROKEN_ORG++))
        echo "$(date) ORIGINAL:        $REPO"										| tee -a $LOG
     else
        echo "$(date) DERIVED:         $REPO"										| tee -a $LOG
    fi
  fi
  if [ $METADATA != $RPM_FILES_TOTAL ]; then
     echo "$(date) ERROR:      Repo $REPO metadata packages: $METADATA, RPM Link count: $RPM_FILES_TOTAL"		| tee -a $LOG
     ((BROKEN_RPMLINKS++))


    # This call will fix the REPO
    if [ $FIX == true ]; then
      echo "### Fixing REPO - $REPO"											| tee -a $LOG
      fix_repo "$REPO"
      ((FIXED_REPOS++))
    fi
  fi
  if [ $METADATA -eq 0 ] && [ $PACKAGES -eq 0 ] && [ $RPM_FILES_TOTAL -eq 0 ]; then 
     echo "$(date) ERROR:      Repo $REPO has 0 packages"
     #echo "$(date) INFO:      Repo $REPO has 0 packages - CCV"								| tee -a $LOG
     ((ZERO_PKGS_REPOS++))
  fi
  if [ $RPM_FILES_FLAT -gt 0 ]; then
     echo "$(date) WARNING:    Repo $REPO still has $RPM_FILES_FLAT of $RPM_FILES_TOTAL flat RPM File links"		| tee -a $LOG
     ((FLAT_RPMLINKS++))
  fi
done

echo "###############################################"									| tee -a $LOG
echo "$(date) Number of repos: $NO_REPOS"										| tee -a $LOG
echo "$(date) Number of relevant repos: $NO_RELEVANT_REPOS"								| tee -a $LOG
echo "$(date) Broken repos found: $BROKEN"										| tee -a $LOG
echo "$(date) Broken ORIGINAL repos found: $BROKEN_ORG"									| tee -a $LOG
echo "$(date) Broken RPM links repos found: $BROKEN_RPMLINKS"								| tee -a $LOG
echo "$(date) Repos still with flat RPM links found: $FLAT_RPMLINKS"							| tee -a $LOG
echo "$(date) Repos with 0 packages: $ZERO_PKGS_REPOS"									| tee -a $LOG
echo "$(date) Fixed Repos: $FIXED_REPOS"										| tee -a $LOG
echo "###############################################"									| tee -a $LOG
exit $BROKEN_ORG
}

# Main
check_repo
fix_repo
