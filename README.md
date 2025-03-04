# Dedicated Server Container

This repository provides the code to run the dedicated server files of the game `The Lord of the Rings: Conquest` headless as a containerized service using Docker and Wine.

# How to Use
## Install
**Note:** Only x86_64 hosts are supported.

1. Install Docker and Docker compose
2. Add your user to the docker group:
```bash
sudo usermod -aG docker $USER
```
3. Reboot to apply the changes
4. Get the `Conquest Dedicated Server` setup archive, e.g. from ausgamers.com](https://www.ausgamers.com/files/download/42316/lord-of-the-rings-conquest-dedicated-pc-server) and put it into the `data` directory as `data/LOTR_Conquest_Server_PC.zip`.
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

6. Build the Docker image using:
```bash
docker compose build
```

## Run the Dedicated Server
1. Prepare a `Dedicated.xml` server configuration file and use it to replace the pre-defined file `Dedicated.xml`.
* The entry `<UseLAN>` should not be used or set to `false` in order to connect to the public MordorWide EA Nation re-implementation. Also, the  values for `<Username>` and `<Password>` should be set.
* You may locally install the application from the file `LOTR_Conquest_Server_PC.zip` to use the configuration tool.

2. Update the port forwarding (default `11900:11900`) within `docker-compose.yml`, if the port differs in the `Dedicated.xml` file.
2. Launch the dedicated server.
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
# Assuming ConquestGameServer as container name
docker exec ConquestGameServer ./screenshot.sh > screenshot.png
```

### Build and load image
You may want to build the Docker image locally, and later load and deploy it on the server.
```bash
# Build the image locally
docker compose build
docker save mordorwide/dedicated:latest | gzip > img-dedicated.tar.gz

# Upload the files to the server
# - Create the directory first
ssh main@server << 'EOF'
set -e
mkdir -p ~/mordorwide-dedicated
cd ~/mordorwide-dedicated
EOF

# - Upload the files
scp img-dedicated.tar.gz main@server:~/mordorwide-dedicated/img-dedicated.tar.gz
scp Dedicated.xml        main@server:~/mordorwide-dedicated/Dedicated.xml
scp docker-compose.yml   main@server:~/mordorwide-dedicated/docker-compose.yml

# - Launch the server
ssh main@server << 'EOF'
set -e
cd ~/mordorwide-dedicated
docker compose up -d
EOF
```