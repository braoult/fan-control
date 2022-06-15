# Developers only: Testing different models fans/temp sensors

Each directory is the model of the computer.

__Important__: This directory is not supposed to be directly used for testing (we want to keep the original ones).

## How to determine model name
On target host, you may use `sudo dmidecode -t system | grep Product\ Name`.

Example (on a iMac early 2009) :
```
$ sudo dmidecode -t system | grep 'Product Name'
	Product Name: iMac9,1
```

## How to create a model data
On target host move all `/sys/devices/platform/applesmc.768` files to a temp directory, then copy them in repository's `examples` directory, with the above `Model Name` as subdirectory.

For example, you may do:

1. On target host
```
$ mkdir /tmp/768
$ cd /sys/devices/platform/applesmc.768
$ sudo cp -p * /tmp/768 2>/dev/null
```
Then, if the repository is not on same host, copy the `/tmp/768` directory to your working host.

2. In `fan-control` repository
Given that the Mac model is "$MODEL", from repo root directory, type the following commands :
```
$ cd examples
$ mkdir -p "$MODEL/sys/devices/platform/applesmc.768"
$ sudo cp -p /tmp/768/* "$MODEL/sys/devices/platform/applesmc.768"
$ sudo chown -R "$(id -un):$(id -gn)" "$MODEL"
```

## Protect from any change
We want to keep these directories intact: Add the new created directory in `.gitignore` file.

Example (from repo root):
```
$ printf "/examples/$MODEL/\n" >> ".gitignore"
```

## How to use
To use, it is better to set ownership of `sys` subdirectories to "root:root", to allow basic access right control.

Example (for repo directory) :
```
$ sudo chown root:root examples/*/sys/
```

Then use `fan.sh`'s `-r` option, for example (from repo directory):
```
$ ./fan.sh -r examples/iMac9,1
```
