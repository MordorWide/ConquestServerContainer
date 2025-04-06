# Dedicated Server Container

This repository provides the code to run the dedicated server files of the game `The Lord of the Rings: Conquest` headlessly as a containerized service using Docker and Wine.

# How to Use
## Install
**Note:** Only x86_64 hosts are supported.

1. Install Docker and Docker compose
2. Add your user to the docker group:
```bash
sudo usermod -aG docker $USER
```
3. Reboot to apply the changes
4. Get the `Conquest Dedicated Server` setup archive, e.g. [from ausgamers.com](https://www.ausgamers.com/files/download/42316/lord-of-the-rings-conquest-dedicated-pc-server) and put it into the `data` directory as `data/LOTR_Conquest_Server_PC.zip`.
<details>
<summary>Verification for file: LOTR_Conquest_Server_PC.zip</summary>

It should look as follows:
```bash
zipinfo -1 data/LOTR_Conquest_Server_PC.zip
Autorun/
autorun.dat
AutoRun.exe
autorun.inf
Autorun/DialogLogo128x128.jpg
Autorun/en-us_AutoRun.bmp
Autorun/ES_AutoRun.bmp
Autorun/fr-fr_AutoRun.bmp
Autorun/GL.ini
Autorun/paul.dll
Autorun/readme.txt
Data0.cab
EASetup.exe
GDFBinary.dll
Levels/
Levels/BlackGates.PAK
Levels/Helm'sDeep.PAK
Levels/Isengard.PAK
Levels/Legal.PAK
Levels/level_info.dat
Levels/MinasTirith.PAK
Levels/MinasTirith_Top.PAK
Levels/Minas_Morgul.PAK
Levels/Moria.PAK
Levels/Mount_Doom.PAK
Levels/Osgiliath.PAK
Levels/PelennorFields.PAK
Levels/Rivendell.PAK
Levels/shell.PAK
Levels/Shire.PAK
Levels/Training.PAK
Levels/Weathertop.PAK
Support/
Support/localization.ini
Support/readme.txt
```
</details>

5. **[Optional]** Replace the empty `DLC_Files.zip` by the DLC data.
<details>
<summary>Verification for file: DLC_Files.zip</summary>

It should look as follows:
```bash
zipinfo -1 data/DLC_Files.zip
AddOn/HeroArenaBonus/
AddOn/HeroArenaBonus/level_info.dat
AddOn/HeroArenaBonus/Moria_DLC.BIN
AddOn/HeroArenaBonus/Moria_DLC.PAK
AddOn/HeroArenaBonus/Osgiliath_DLC.BIN
AddOn/HeroArenaBonus/Osgiliath_DLC.PAK
AddOn/HeroesandMapsPack/
AddOn/HeroesandMapsPack/Amon_Hen.BIN
AddOn/HeroesandMapsPack/Amon_Hen.PAK
AddOn/HeroesandMapsPack/Audio/
AddOn/HeroesandMapsPack/Audio/HeroArwen.bnk
AddOn/HeroesandMapsPack/Audio/HeroBoromir.bnk
AddOn/HeroesandMapsPack/Audio/HeroGothmog_DLC.bnk
AddOn/HeroesandMapsPack/Audio/Level_Amon_Hen_DLC.bnk
AddOn/HeroesandMapsPack/Audio/Level_Last_Alliance_DLC.bnk
AddOn/HeroesandMapsPack/LastAlliance_DLC.BIN
AddOn/HeroesandMapsPack/LastAlliance_DLC.PAK
AddOn/HeroesandMapsPack/level_info.dat
AddOn/HeroesandMapsPack/MinasTirithBottom_DLC.BIN
AddOn/HeroesandMapsPack/MinasTirithBottom_DLC.PAK
AddOn/HeroesandMapsPack/Weathertop_DLC.BIN
AddOn/HeroesandMapsPack/Weathertop_DLC.PAK
Audio/WWiseIDTable.bin
```
</details>

6. Build the Docker images using:
```bash
# [using compose]
docker compose build

# [or using plain Docker]
# Base image
docker build -t mordorwide/dedicated-base:latest -f Dockerfile.base .

# DLC image
docker build -t mordorwide/dedicated-dlc:latest -f Dockerfile.dlc .
```

## Run the Dedicated Server
1. Prepare a `Dedicated.xml` or `Dedicated_DLC.xml` server configuration file and use it to replace the pre-defined file `Dedicated.xml` or `Dedicated_DLC.xml`.
* The entry `<UseLAN>` should not be used or set to `false` in order to connect to the public MordorWide EA Nation re-implementation. Also, the  values for `<Username>` and `<Password>` should be set.
* You may locally install the application from the file `LOTR_Conquest_Server_PC.zip` to use the configuration tool.

2. Update/edit `docker-compose.yml`:
* Add entries for all server that should be hosted. (Example hosts two servers; `conquest-gameserver-base` and `conquest-gameserver-dlc`)
* The service names and container names should be unique and use unique ports.
* Each server should should get an individual `Dedicated.xml` server configuration.
* The port forwarding (default `11900:11900`) should match the port defined in the `Dedicated.xml` or `Dedicated_DLC.xml` file.
* Set `SHUFFLE_LEVELS=1` to shuffle the level order at the startup of the server.

3. Launch the dedicated server.
```bash
docker compose up -d
```

3. Track the server by:
```bash
docker compose logs -f
```

## Utilities

### Make a screenshot
You can make a screenshot from the running server instance as follows:
```
# Assuming ConquestGameServer-11900 as container name
docker exec ConquestGameServer-11900 ./screenshot.sh > screenshot.png
```

### Build and load image
You may want to build the Docker image locally, and later load and deploy it on the server.
```bash
# Build the image locally
docker compose build
docker save mordorwide/dedicated-base:latest | gzip > img-dedicated-base.tar.gz
docker save mordorwide/dedicated-dlc:latest | gzip > img-dedicated-dlc.tar.gz

# Upload the files to the server
# - Create the directory first
ssh main@server << 'EOF'
set -e
mkdir -p ~/mordorwide-dedicated
cd ~/mordorwide-dedicated
EOF

# - Upload the files
scp img-dedicated-base.tar.gz main@server:~/mordorwide-dedicated/img-dedicated-base.tar.gz
scp img-dedicated-dlc.tar.gz main@server:~/mordorwide-dedicated/img-dedicated-dlc.tar.gz
scp Dedicated.xml        main@server:~/mordorwide-dedicated/Dedicated.xml
scp Dedicated_DLC.xml        main@server:~/mordorwide-dedicated/Dedicated_DLC.xml
scp docker-compose.yml   main@server:~/mordorwide-dedicated/docker-compose.yml

# - Launch the server
ssh main@server << 'EOF'
set -e
cd ~/mordorwide-dedicated
docker load < img-dedicated-base.tar.gz
docker load < img-dedicated-dlc.tar.gz
docker compose up -d
EOF
```