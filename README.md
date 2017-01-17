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
  1. **NOTE** The gpfs puppet module will adjust */root/.ssh/authorized_keys* on each client as well as make appropriate firewall changes.

# Usage
The following are required parameters:
* gpfs
    * `firewall_allowed_cidr` (STRING)
        * A network address in CIDR format that encompasses all nodes that will be
        part of the cluster.  This is used to create a firewall exception
        allowing incoming traffic from this CIDR to GPFS ports.
    * `yumrepo_baseurl` (STRING)
        * The baseurl of the yum repo from which to install gpfs modules.
        Use this to control which version of gpfs is installed.
* gpfs::add_client
    * `master_server` (STRING)
        * Fully qualified domain name of the gpfs master server
    * `sshkey_priv_contents`
        * The contents of the private ssh key created above.
        Used only to ssh to the master server during setup (ie: addclient,
        chlicense).  After setup, the private key is destroyed from the client node.
    * `sshkey_pub_contents`
        * The contents of the public ssh key created above.  Added to root
        authorized keys file on each client to allow passwordless ssh from the
        master.

## Hiera Example
In the appropropriate YAML file(s), define the following keys:
```
gpfs::firewall_allowed_cidr: 111.222.0.0/16
gpfs::yumrepo_baseurl: http://rh.my.company/rhelrepos/SpectrumScale_420-client
gpfs::add_client::master_server: gpfs00.my.company
gpfs::add_client::sshkey_priv_contents: |
  -----BEGIN RSA PRIVATE KEY-----
  abcdefgxyz123
  SNIP - SNIP - SNIP
  321zyxgfedcba
  -----END RSA PRIVATE KEY-----
gpfs::add_client::sshkey_pub_contents: AAAAB3NzaC1yc2EAAAADAQABAAABAQDjCJxNeh+sgZ4HeaF6TrDf6QD0SfZ//ZvdEOoyb5cBMS7hqPBuDbwMtpI9+80sCmtwTVLW0S09e8oG+2q68LNZxXBjIDr9b4n6GnUIxphTtVxkG8AIbvmVhD1QzoeGEMVQlpFKsHyJoWYyg5PDFdgpcpxNdue0CcLjSNDe1hXnUmOCwLjBvXkDkf2ROmdGRD3e+7HEXlesfIreXxuMTwcDK/2Q8XoB7EHgL5APm1GzrISE7Pd15ShED4klF+uivbs0B/V6fNdF0BmYjB7AqY+W7jCP6T1MrsJgLYIQiJfa7vb2Gmd7E39N3HyZiUKex0Sey3h1ld96zRcIeeEguPkx
```

## Declarative Example
```
class { 'gpfs' :
    firewall_allowed_cidr => '111.222.0.0/16',
    yumrepo_baseurl => 'http://rh.my.company/rhelrepos/SpectrumScale_420',
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
