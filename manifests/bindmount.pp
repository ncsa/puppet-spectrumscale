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
    $resource_defaults = lookup( 'gpfs::resource_defaults' )
    $mount_defaults = $resource_defaults['mount']
    $dir_defaults = merge( $resource_defaults['file'], { 'ensure'=>'directory' } )


    # Build mount option string
    $defaultopts = 'bind,noauto'
    if $opts =~ String[2] {
        $optstr = "${defaultopts},${opts}"
    }
    else {
        $optstr = $defaultopts
    }


    # Ensure parents of target dir exist, if needed (excluding / )
    $dirparts = reject( split( $name, '/' ), '^$' )
    $numparts = size( $dirparts )
    if ( $numparts > 1 ) {
        each( Integer[2,$numparts] ) |$i| {
            ensure_resource(
                'file',
                reduce( Integer[2,$i], $name ) |$memo, $val| { dirname( $memo ) },
                $dir_defaults
            )
        }
    }


    file {
        # Ensure target directory exists
        $name:
        ;
        # Ensure source directory exists (ie: gpfs is started and mounted)
        $src:
            require => Class[ 'gpfs::startup' ],
        ;
        default: * => $dir_defaults ;
    }


    # Define the mount point
    mount {
        $name:
            device  => $src,
            options => $optstr,
            require => File[ $name, $src ],
        ;
        default: * => $mount_defaults ;
    }

}
