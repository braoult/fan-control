# Linux on mac fan control
Note: This script has been  primary coded for my iMac 12,1 (2011, 21.5 inch) and was later updated to work as well on the following macs: MacBook 5,1 and 5,2 running Ubuntu 20.04 and Macmini 3,1 (2009 Macmini), if you have problems with this script on other Macs please open an issue

Usage:
## Option A
(here you don't create the actual command, just an alias, but it's more updatable, just `git pull` will get the job done)


1. Clone the repo in home
```
cd ~/ && git clone https://github.com/juampapo546/fan-control/

2. Create the alias for this script <br>
   If you use bash :

```
echo  'alias fan="sudo sh /home/$USER/fan-control/fan.sh"' >> ~/.bashrc
 ```
If you use zsh :
 ```
 sudo echo  'alias fan="sudo sh /home/$USER/fan-control/fan.sh"' >> ~/.zshrc
 ```
If you have doubts you probably use bash, to be sure check if you have in your /home .bashrc or .zshrc
___

## Option B
(here you create the command but you'll have to repeat the whole process every time you want to update)

1. Clone the repo in home <br>
```
cd ~/ && git clone https://github.com/juampapo546/fan-control/
```

2. Move the script to /bin and make it executable <br>
```
sudo mv ~/fan-control/fan.sh /bin/fan && sudo chmod +x /bin/fan
```

3. (optional) Clean remainings of the repo <br>
```
rm -rf ~/fan-control
```

____

### Run fan!

First check what fans are available for your mac

```
fan
```
Then choose one one of the output fans and run:

```
sudo fan [ -aHhs ] [ 'all' | fan number | fan name ] [ 'auto' | 0-100 speed ]
```

### Examples

List fans :
```
$ fan
odd
hdd
cpu
```
View speed :
```
$ fan all
odd   798
hdd  1598
cpu  1200

$ fan 1
odd  798

$ fan -H odd
fan  speed
odd    798
```
View all fan information with header line
```
$ fan -aH all
\#  fan  mode  speed  wanted   min   max
1  odd  auto    799     n/a   800  4800
2  hdd  auto   1598     n/a  1600  5900
3  cpu  auto   1199     n/a  1200  3600

$ fan -a 1
1  odd  auto  797  n/a  800  4800
```
Set speed :

```
$ sudo fan all auto
```
