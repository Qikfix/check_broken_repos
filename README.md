Hi

Execute the command `./check_broken_repos.sh` just to check all repos
```
# ./check_broken_repos_v2.sh 
Thu Sep  6 14:34:33 EDT 2018 INFO: Checking for broken repos...
Thu Sep  6 14:34:33 EDT 2018 INFO: Check Repo 1-ccv_rhel7_ACME-Library-3d430f89-2482-4693-a653-1ac62a8101be ...
Thu Sep  6 14:34:33 EDT 2018 INFO: Check Repo 1-ccv_rhel7_ACME-Library-4b55b942-9be5-41b4-ae2d-ddbda4d1f3c2 ...
Thu Sep  6 14:34:41 EDT 2018 INFO: Check Repo 1-ccv_rhel7_ACME-Library-52ca6edc-0a6c-4443-b7d0-4a83e6c0e7e9 ...
Thu Sep  6 14:34:42 EDT 2018 INFO: Check Repo 1-ccv_rhel7_ACME-Library-e53f14c8-c4db-4364-94bc-b99ec02b0cdd ...
...
###############################################
Thu Sep  6 14:35:44 EDT 2018 Number of repos: 33
Thu Sep  6 14:35:44 EDT 2018 Number of relevant repos: 0
Thu Sep  6 14:35:44 EDT 2018 Broken repos found: 0
Thu Sep  6 14:35:44 EDT 2018 Broken ORIGINAL repos found: 0
Thu Sep  6 14:35:44 EDT 2018 Broken RPM links repos found: 0
Thu Sep  6 14:35:44 EDT 2018 Repos still with flat RPM links found: 0
Thu Sep  6 14:35:44 EDT 2018 Repos with 0 packages: 0
Thu Sep  6 14:35:44 EDT 2018 Fixed Repos: 0
###############################################
```
The command above will just show all repos and point if there is issues on that "different values between metadata and rpm file"

If you would like to fix, just rerun the command passing the flag `fix_repos`

```
# ./check_broken_repos.sh fix_repos
```

Note. Will be generated a great log here `/var/log/repos_check.log`

- On the Sat Server will fix everything during the execution.
- On the Capsule, after conclude this step, will be necessary sync again.

TODO
  - Change the approach just to consume the API instead use foreman-rake to fix the repo issue.
