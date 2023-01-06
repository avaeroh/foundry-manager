**About**
Allows for development on Worlds in [FoundryVTT](https://foundryvtt.com/) to be migrated across various machines by sharing the latest Data dir via Cloud Storage (E.g. Google Drive). This is useful when switching machines, or for sharing FoundryVTT Worlds.

Scripts have only been tested on Linux (Raspbian/WSL) and may not work on other OS.

Currently supports:
- Running FoundryVTT via Docker.
- Pulling Data dir after checking that remote is more recent.
- Pushing Data dir. 

This repo is not designed to manage conflicts in Data - the latest files will always be assumed to be the 'desired', and will overwrite all others.

**Requirements**
- zsh
- tar
- git
- rclone
- docker
- docker-compose

**Install**

*Foundry Config*
- firstly, protect your creds: `git update-index --assume-unchanged docker/docker-compose/.env`
- populate `docker/docker-compose/.env` with your Foundry Config. Note that each Foundry license can have a corresponding instance running on any one machine at a time. 
- execute docker compose `/docker/docker-compose/docker-compose.yml` via `docker-compose up -d`
- the foundry application will be running on localhost on your specified port. Note that running this is required to create the Data dir in the first instance.
- if desired, modify config & port-forward to allow for the server to be internet-accessible.
- set `environment.properties` to your [remote dir in rclone](https://rclone.org/remote_setup/).
- set execute permissions on the `.sh` files (`sudo chmod +x <filename>`)
- run `pullLatestFoundryBackup.sh`, this will pull the latest archive from remote & extract it. If local Data dir is the most recent, nothing will be pulled.
