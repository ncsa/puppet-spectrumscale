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

## Mount native gpfs filesystem(s)
If GPFS filesystem(s) are set to auto-mount on startup, no action is required. \
To mount non-auto-start filetems(s), add the following to hiera...
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
            * Default GPFS mountpath is usually `/FSNAME` and the module will use this format by default.
            * If the mountpath is different from the default, then this parameter is required.
    * NOTE: To mount a non-auto-mount filesystem for which the default _opts_ and _mountpoint_ are sufficient, pass an empty hash as the value.
        * (ie: `gpfs::nativemounts::mountmap: { FSNAME: {} }` )


* `gpfs::quota::host` (STRING)
    * host name or ip-address of a gpfs core server that listens for mmlsquota
      requests from the network
* `gpfs::quota::port` (INTEGER)
    * port (on the host above) to which remote mmlsquota requests should be
      sent

## Hiera Example
In the appropropriate YAML file(s), define the following keys:
```
gpfs::firewall::allowed_cidr: 111.222.0.0/16
gpfs::install::yumrepo_baseurl: http://rh.my.company/rhelrepos/SpectrumScale_420-client
gpfs::add_client::master_server: gpfs00.my.company
gpfs::add_client::sshkey_priv_contents: |
  -----BEGIN RSA PRIVATE KEY-----
  abcdefgxyz123
  SNIP - SNIP - SNIP
  321zyxgfedcba
  -----END RSA PRIVATE KEY-----
gpfs::add_client::sshkey_pub_contents: AAAAB3NzaC1yc2EAAAADAQABAAABAQDjCJxNeh+sgZ4HeaF6TrDf6QD0SfZ//ZvdEOoyb5cBMS7hqPBuDbwMtpI9+80sCmtwTVLW0S09e8oG+2q68LNZxXBjIDr9b4n6GnUIxphTtVxkG8AIbvmVhD1QzoeGEMVQlpFKsHyJoWYyg5PDFdgpcpxNdue0CcLjSNDe1hXnUmOCwLjBvXkDkf2ROmdGRD3e+7HEXlesfIreXxuMTwcDK/2Q8XoB7EHgL5APm1GzrISE7Pd15ShED4klF+uivbs0B/V6fNdF0BmYjB7AqY+W7jCP6T1MrsJgLYIQiJfa7vb2Gmd7E39N3HyZiUKex0Sey3h1ld96zRcIeeEguPkx
gpfs::quota::host: 111.222.3.4
gpfs::quota::port: 9876
```

## Declarative Example
```
class { 'gpfs::firewall' :
    allowed_cidr => '111.222.0.0/16',
}

class { 'gpfs::install' :
    yumrepo_baseurl => 'http://rh.my.company/rhelrepos/SpectrumScale_420',
}

class { 'gpfs::quota' :
    host => '111.222.3.4',
    port => 9876,
}

### Add node to GPFS cluster and start GPFS
class { 'gpfs::add_client' :
    master_server => 'gpfs00.my.company',
    sshkey_pub_contents => 'AAABBBCCC......xyz',
    sshkey_priv_contents => '-----BEGIN RSA PRIVATE KEY-----
...
-----END RSA PRIVATE KEY-----',
}
```

## Specifying bind mount points (useful for making a gpfs fileset look like a filesystem mount)
```
# A single bind mount
gpfs::bindmount{ "/datasets": src => "/gpfs/fs0/datasets" }

# Multiple bind mounts in a single declaration
gpfs::bindmount{
    "/scratch"  : src => "/gpfs/fs0/scratch";
    "/software" : src => "/gpfs/fs0/software", opts => "ro";
}
```

## Mounting filesystems readonly
todo

## Ignore mountpoint completely
todo

## Ignore mount at (GPFS) startup
todo
