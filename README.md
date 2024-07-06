# wgw
WireGuard Wrapper (Key Management + Friendly Names)

This is a wrapper script for WireGuard VPN that displays friendly names when listing WireGuard connection status, and also handles key management chores (e.g. creating new keys, listing existing keys, etc.)  

This is what WireGuard connection status looks like when it's displayed through this script:

![alt text](WGW-ExampleScreen.png)

# Overview
- The `.publickey` files of vpn peers are stored under the `clients` folder (see [Repository Structure](README.md#repository-structure) below).
- The filename of `.publickey` files becomes the "friendly name" shown for each peer (e.g. a publickey file named `Dave's Cell.publickey` creates a friendly name of "Dave's Cell" for his peer connection).  
- In addition to formatting `WG info` output with "friendly names", **wgw** also provides commands that help manage creating and maintaining private and public keys for vpn peers.
- Use `wgw` instead of `wg` to list peer connection status/information, to create new vpn clients or list existing clients, or to perform any other `wg` command (it will call wg with the full parameter list of any command it doesn't internally recognize).
<!-- determines the "friendly name" of peer connections by finding the public key for the peer in a folder that contains the public key files, and then adds the friendly name (the file name of the public key file) into the output of the "WG show" command.     (respository) of public key files maintaining a repository uses the name of the publickey file builds an associative array of "friendly names" to public keys (for VPN peers) by using the name of the file holding the publickey <peer>.publickey files in the clients folder of the base repository.-->
## Repository Structure
```
├── <Repo_Base_Folder>
│   ├── wgw.sh
│   ├── clients
│   │   ├── Dave's Cell.privatekey
│   │   ├── Dave's Cell.publickey
│   │   ├── Dan's Tablet.privatekey
│   │   ├── Dan's Tablet.publickey
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
The follow steps use `/config/auth/wireguard` as the repository base folder.  Change it to reflect the base folder you actually want to use for the key repository.
```shell
# Make base repository folder (if it doesn't already exist)
mkdir -p /config/auth/wireguard

# Download wgw to it (in subshell to keep cur dir)
(cd /config/auth/wireguard; curl -OL https://raw.githubusercontent.com/ndfan77/wgw/main/wgw.sh; chmod +x wgw.sh)

# Create a symlink to it in /usr/local/bin (which is normally in the path)
sudo mkdir -p /usr/local/bin
sudo ln -s -f /config/auth/wireguard/wgw.sh /usr/local/bin/wgw
```
# First-time wgw Configuration
#### Change the Repo= variable if the Repo_Base_Folder used is different than `/config/auth/wireguard`
Edit the `wgw.sh` file with your favorite text editor (e.g. `vi /config/auth/wireguard/wgw.sh`), and change the `Repo="/config/auth/wireguard"` variable (currently line 3) to reflect the correct path.

#### Create Repository Subfolders (if they don't already exist) and Generate server keys
```
wgw initialize
```
> [!WARNING]
> - This command will create the `<Repo_Base_Folder>/server` and `<Repo_Base_Folder>/clients` folders if they do not exist, and will generate new public and private keys for the server (`server.publickey` and `server.privatekey` under the `<Repo_Base_Folder>/server` folder).
> - Don't issue this command if you already have public and private keys for your vpn server.  Instead, manually make the `<Repo_Base_Folder>/server` and `<Repo_Base_Folder>/clients` folders and place the server.publickey and server.privatekey files under the server folder as shown above in [Repository Structure](README.md#repository-structure) (rename them if necessary). 
> - If `server.publickey` or `server.privatekey` files already exist under the `<Repo_Base_Folder>/server` folder when the initialize command is issued, they will be renamed using the current date. 
### Set Server Values For Suggested Client Configuration Files
#### Server Public Endpoint
```
wgw server endpoint <my_endpoint:1305>
```
> [!TIP]
> This is the public URL and port for your vpn server that peer's will connect to. 

> [!IMPORTANT]
> This only alters the template text suggested for client configuration files.  It has no functional effect.
#### Server VPN Endpoint IP Address
```
wgw server ipaddress 172.17.250.1
```
> [!IMPORTANT]
> This only alters the template text suggested for client configuration files.  It has no functional effect.


# Command Line Options
To see command line options:
```
wgw --help
```
For example:
```
dave@myhost:~$ wgw --help 
Usage: wgw <command> <arguments>

wgw internal commands:
  show: Calls wg for current config and device info and adds friendly names
  initialize: Initialize repository folder structure and create server keys
  client show | addkey | listkeys: Show, add, or list client keys
  server show | endpoint | ipaddress | createkeys: Show server template information, set it, or initialize keys

<command> can also be any valid wg command:
Usage: /usr/bin/wg <cmd> [<args>]

Available subcommands:
  show: Shows the current configuration and device information
  showconf: Shows the current configuration of a given WireGuard interface, for use with `setconf'
  set: Change the current configuration, add peers, remove peers, or change peers
  setconf: Applies a configuration file to a WireGuard interface
  addconf: Appends a configuration file to a WireGuard interface
  syncconf: Synchronizes a configuration file to a WireGuard interface
  genkey: Generates a new private key and writes it to stdout
  genpsk: Generates a new preshared key and writes it to stdout
  pubkey: Reads a private key from stdin and writes a public key to stdout
You may pass `--help' to any of these subcommands to view usage.
```
