# The name passed is the mount target.
# src is the gpfs source directory (usually a fileset)
# opts is a comma separated string of mount options
define gpfs::bindmount(
    $src,
    $opts = '',
)
{
#    notify {"gpfs::bindmount ${name}":}

    # Resource defaults
    Mount {
        ensure  => mounted,
        fstype   => 'none',
    }

    File {
        ensure => directory,
        owner  => 'root',
        group  => 'root',
    }

    # Build mount option string
    $defaultopts = "bind,noauto"
    if $opts =~ String[2] {
        $optstr = "${defaultopts},${opts}"
    }
    else {
        $optstr = $defaultopts
    }

    # Ensure target directory exists
    file { $name: }

    # Ensure source directory exists (ie: gpfs is started and mounted)
    file { $src:
        require => Class[ 'gpfs::startup' ],
    }

    # Define the mount point
    mount{ $name:
        device  => $src,
        options => $optstr,
        require => File[ $name, $src ],
    }

}
