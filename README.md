# Puppet SpectrumScale
Puppet module to mount the SpectrumScale filesystem (formerly known as GPFS).

# Requirements
* GPFS is setup in *adminMode=central*
* The gpfs client nodes' hostname (as returned by the *hostname* command):
  * matches the name that will be used in the GPFS cluster
  * has valid forward and reverse DNS entries
* Access to a yum repo that hosts the gpfs packages
* GPFS version >= 4.2
* Puppet version >= 3.8 
* `ssh` and `ping` network connectivity between the gpfs master node and all
  client nodes

# Installation
1.  `git clone https://git.ncsa.illinois.edu/aloftus/puppet-spectrumscale.git gpfs`
    1. **NOTE**: the local directory name **must** be *gpfs*. 
    This is important as the contents of the puppet module refer to the module by it's legacy name, 
    *gpfs*.
1. On the gpfs master node:
    1. Create an ssh public and private key pair
    1. Add the ssh public key to */root/.ssh/authorized_keys*
    1. In */root/.ssh/config*, create a *Host* section to match all new client hostnames:
        1. Set `IdentityFile` to the private key created above
        1. Set `StrictHostKeyChecking no`
1. On the gpfs client nodes, ensure passwordless ssh login as root is allowed:
    1. This usually entails the following settings in */etc/ssh/sshd_config* on each client, usually in a *Match Address* section:
```
PermitRootLogin without-password
AllowGroups root
PubkeyAuthentication yes
PasswordAuthentication no
GSSAPIAuthentication no
```

**NOTE** The gpfs puppet module will adjust */root/.ssh/authorized_keys* on each client as well as make appropriate firewall changes.

# Usage
## Install gpfs client, join the gpfs cluster
* `include gpfs`
#### Required Parameters:
* `gpfs::install::yumrepo_baseurl` (STRING)
    * The baseurl of the yum repo from which to install gpfs modules.
    * Note: GPFS rpm's (historically) don't provide sufficient dependency information.
      Additionally, sometimes only some rpm pkg's update between versions.
      Therefore, this package assumes the Yum Repo baseurl is single, specific gpfs version.
      Likewise, the gpfs version to install is managed by changing this URL.
* `gpfs::firewall::allow_from` (ARRAY)
    * Array of Strings representing ip addresses of nodes that participate in the gpfs cluster.
    * Supported formats are
        * ip address range (ie: A.B.C.x-A.B.C.y)
        * network CIDR (ie: A.B.C.D/Z)
        * single ip address
* `gpfs::add_client::master_server` (STRING)
    * Fully qualified domain name of the gpfs master server
* `gpfs::add_client::ssh_private_key_contents` (STRING)
    * The contents of the private ssh key created above.
      Used only to ssh to the master server during setup.
      For security, the private key is removed from the client node after gpfs installation.
* `gpfs::add_client::ssh_public_key_contents` (STRING)
    * The contents of the public ssh key created above.  Added to root
      authorized keys file on each client to allow passwordless ssh from the
      master.

Hiera Example:
```
gpfs::install::yumrepo_baseurl: http://yumrepos.internal.domain.com/centos/$releasever/$basearch/gpfs-4.2.3-9/2018-06-24-1529875501/
gpfs::firewall::allow_from:
    - 1.2.3.0/24
    - 4.5.6.1-4.5.6.31
gpfs::add_client::master_server: gpfs-master.internal.domain.com
gpfs::add_client::ssh_private_key_contents: |
  -----BEGIN RSA PRIVATE KEY-----
  MIIEowI...
  ...
  -----END RSA PRIVATE KEY-----
gpfs::add_client::ssh_public_key_contents: AAAAB3N...
```

## Mount native gpfs filesystem(s)
If GPFS filesystem(s) are set to auto-mount on startup, no action is required. \
To mount non-auto-start filetems(s), the following parameters must be provided...
#### Required Paramaters:
* `gpfs::nativemounts::mountmap` (HASH)
    * Key is GPFS filesystem name
    * Value is a HASH with optional paramters:
        * `opts`
            * Comma separated string of mount options (same format as passed to `mount` command)
            * Defaults to `noauto`.
            * opts string specified here will always be appended to the default value.
        * `mountpoint`
            * String - path to mountpoint for this filesystem.
            * Default GPFS mountpath is `/FSNAME` and the module will use this format by default.
            * If the mountpath is different from the default, then this parameter is required.
    * NOTE: If the defaults for _opts_ and _mountpoint_ are sufficient, pass an empty hash as the value.

Hiera Example:
```
gpfs::nativemounts::mountmap:
    fs0:
        opts: nosuid,ro
        mountpoint: /gpfs/fs0
    fs1:
        opts: noatime
    fs2: {}
```

## Create bindmounts to a path below a gpfs mountpoint
A common use case is to create multiple filesets inside a single filesystem and make each fileset look like a mounted filesystem.
Bindmounts require the dependent filesystem to be listed in `gpfs::nativemounts::mountmap` even if the dependent filesystem is auto-mounted. \
To create bindmounts, the following parameters must be provided...
* `gpfs::bindmounts::mountmap:`
    * Key is the path at which the bindmount should appear in the filesystem
    * Value is a hash with the following keys:
        * `src_mountpoint`: mountpath of the dependent filesystem (REQUIORED)
        * `src_path`: path which the bindmount points to (REQUIRED)
        * `opts`: comma separated string of mount options (OPTIONAL)

Hiera Example:
```
gpfs::bindmounts::mountmap:
    /scratch:
        src_mountpoint: /gpfs/fs0
        src_path: /gpfs/fs0/scratch
    /software:
        src_mountpoint: /fs2
        src_path: /fs2/software
        opts: noatime,ro
```

## (OPTIONAL) Create a cron job to accept client licenses
The client install script attempts to accept the gpfs client license, but sometimes this does not succeed.
If client nodes are frequently rebuilt, or for some other reason, the gpfs client licenses are frequently not accepted,
this cron job can be installed on any one client node (it may not hurt to install on multiple client nodes,
but it is a waste of resources, at minimum, or worse, could result in unexpected behavior). \
To install the cron job, set the following parameter...
* `gpfs::cron::accept_license: True`


## (OPTIONAL) Run a custom quota command on the server
Override the native `mmlsquota` and `mmrepquota` commands with a local script that will send the requests
to a client running elsewhere (usually on a gpfs server) and return custom data. \
Set the following parameters:
* `gpfs::quota::host` (STRING)
    * host name or ip-address of the server that listens for mmlsquota
      requests from the network
* `gpfs::quota::port` (INTEGER)
    * port (on the host above) to which remote mmlsquota requests should be
      sent

See also: The file `manifests/templates/myquota.epp`

