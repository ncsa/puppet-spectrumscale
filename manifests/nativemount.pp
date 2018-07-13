# Represent a native gpfs filesystem mount
#
# @summary
#   Create mount options file, populated with specified options
#   Ensure parent (mountpoint) directory exists
#   Ensure the filesystem is mounted
#
#   Name: gpfs filesystem name
#   Parameters:
#     opts       - OPTIONAL
#                  comma separated string of additional mount options
#                  defaults to 'noauto'
#                  note: 'noauto' will always be included in the options
#                        (cannot be overridden)
#     mountpoint - OPTIONAL
#                  where the filesystem is mounted at
#                  defaults to '/FSNAME', where FSNAME is replaced with the
#                  gpfs filesystem name
#                  note: this must match the mountpoint specified in the gpfs
#                        filesystem configuration (ie: mmlsfs)
#     
#
# @example
#   gpfs::nativemount { 'software': }
#
#   gpfs::nativemount { 'data': 
#       opts='ro,nosuid',
#       mountpoint='/data' }
#   }
define gpfs::nativemount(
    $opts = '',
    $mountpoint = '',
) {

    # Resource defaults
    $dir_defaults = merge(
        $gpfs::resource_defaults['file'],
        { 'ensure' => 'directory',
          'mode'   => '0744',
        }
    )

    # Build mount options string
    $defaultopts = 'noauto'
    if $opts =~ String[2] {
        $optstr = "${defaultopts},${opts}"
    }
    else {
        $optstr = $defaultopts
    }

    # Create mount options control file
    $optfile = "/var/mmfs/etc/localMountOptions.${name}"
    file {
        $optfile :
            content => $optstr,
        ;
        default: * => $gpfs::resource_defaults['file']
        ;
    }

    # Determine mountpath
    $default_mountpoint = "/${name}"
    if $mountpoint =~ String[1] {
        $mpath = $mountpoint
    } else {
        $mpath = $default_mountpoint
    }

    # Ensure parents of mountpath dir exist, if needed (excluding / )
    $dirparts = reject( split( $mpath, '/' ), '^$' )
    $numparts = size( $dirparts )
    if ( $numparts > 1 ) {
        each( Integer[2,$numparts] ) |$i| {
            ensure_resource(
                'file',
                reduce( Integer[2,$i], $mpath ) |$memo, $val| { dirname( $memo ) },
                $dir_defaults
            )
        }
    }

    # Ensure mountpath dir exists
    file {
        $mpath:
        ;
        default: * => $dir_defaults
        ;
    }

    # Ensure fstab is up to date
    $fstab_update_cmdname = "fstab update ${mpath}"
    exec {
        $fstab_update_cmdname:
            command => 'mmrefresh -f',
            unless  => "grep '^${name} \{1,\}${mpath} \{1,\}gpfs' /etc/fstab",
        ;
        default: * => $gpfs::resource_defaults['exec']
        ;
    }

    # Ensure mounted
    mount {
        $mpath:
            require => [ Class[ 'gpfs::startup' ],
                         File[ $mpath, $optfile ],
                         Exec[ $fstab_update_cmdname ],
                       ],
        ;
        default: * => $gpfs::resource_defaults['mount']
        ;
    }

}
