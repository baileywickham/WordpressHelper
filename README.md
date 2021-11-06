# WordpressHelper
Install my least favorite toolset

## TODO
* [x] add backup
* [x] add restore
* [x] install shell
* [x] fail2ban
* [x] block xmlrpc
* [x] enable automated updates
* [ ] ufw firewall, block ports besides 22, 80, 443
* [x] certbot

## Use
### Clone
```bash
sudo apt install git
git clone https://github.com/baileywickham/WordpressHelper.git
```

### Install wordpress
```bash
./install_wp.sh --install
```


### Backup wordpress
```bash
./backup_wp.sh --backup
```

### Restore wordpress
```bash
./install_wp.sh --restore <filename>
```
