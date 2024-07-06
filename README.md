# wgw
WireGuard Wrapper (Key Management + Friendly Names)

This is a wrapper script for WireGuard VPN that displays friendly names when listing WireGuard connection status, and also handles key management chores (e.g. creating new keys, listing existing keys, etc.)  

This is what WireGuard connection status looks like when it's displayed through this script:

![alt text](WGW-ExampleScreen.png)

# Overview
- The `.publickey` files of vpn peers are stored under the `clients` folder (see [Repository Structure](README.md#repository-structure) below).
- The filename of `.publickey` files becomes the "friendly name" shown for each peer (e.g. a publickey file named `Dave's Cell.publickey` creates a friendly name of "Dave's Cell" for his publickey).  
- In addition to formatting `WG info` output with "friendly names", **wgw** also provides commands that help manage creating and maintaining private and public keys for vpn peers.
<!-- determines the "friendly name" of peer connections by finding the public key for the peer in a folder that contains the public key files, and then adds the friendly name (the file name of the public key file) into the output of the "WG show" command.     (respository) of public key files maintaining a repository uses the name of the publickey file builds an associative array of "friendly names" to public keys (for VPN peers) by using the name of the file holding the publickey <peer>.publickey files in the clients folder of the base repository.-->
## Repository Structure
```
├── <Repo_Base_Folder>
│   ├── wgw.sh
│   ├── clients
│   │   ├── Dave's Cell.privatekey
│   │   ├── Dave's Cell.publickey
│   │   ├── Dan's Cell.privatekey
│   │   ├── Dan's Cell.publickey
│   ├── server
│   │   ├── server.privatekey
│   │   ├── server.publickey
```

# Installation
- Determine where the Repo_Base_Folder will be located (which holds the client public and private keys, as well as the server public and private keys)
- Determine where to store the wgw.sh script.  (The example below stores it in the Repo_Base_Folder and then creates a symlink to it in /usr/local/bin.)
#### General Linux
A suitable place to store configuration data might be `/usr/local/etc` (i.e. set Repo="/usr/local/etc/wireguard" in wgw.sh).
#### EdgeOS
A good place to store configuration data on EdgeOS is under `/config/auth` since it persists across version upgrades (i.e. set Repo="/config/auth/wireguard" in wgw.sh).
## Installation Steps
The follow steps use `/config/auth/wireguard` as the repisotry base folder.  Change it to reflect the base folder you actually want to use for the key repository.
```shell
# Make base repository folder (if it doesn't already exist)
mkdir -p /config/auth/wireguard

# Download WGW to it (in subshell to keep cur dir)
(cd /config/auth/wireguard; curl -OL https://raw.githubusercontent.com/ndfan77/wgw/main/wgw.sh; chmod +x wgw.sh)

# Create a symlink to it in /usr/local/bin (which is normally in the path)
sudo mkdir -p /usr/local/bin
sudo ln -s -f /config/auth/wireguard/wgw.sh /usr/local/bin/wgw
```
# First-time Wgw Configuration
#### Set the Repo= variable if the Repo_Base_Folder selected is different than `/config/auth/wireguard`
- [ ] Edit wgw.sh file with your favorite text editor (e.g. `vi /config/auth/wireguard/wgw.sh`), and change the `Repo="/config/auth/wireguard"` variable (currently on line 3) to reflect the correct path.

#### Initialize Key Repo and Generate server keys
```
wgw initialize
```
NOTE:  There is no need to do this if you've already created public and private keys for your vpn server
NOTE:  If `server.publickey` or `server.privatekey` files already exist under the `<Repo_Base_Folder>/server` folder when the initialize command is issued, they will be renamed using the current date. 
#### Set server values (shown in client config templates only - otherwise no logical value)
```
wgw server endpoint <my_endpoint:1305
```

### Set server values (shown in client config templates only - otherwise no logical value)
wgw server ipaddress 172.17.250.1



# Command Line Options
- ToDo
