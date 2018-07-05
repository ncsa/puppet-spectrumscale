###
#  Start GPFS and wait for verification that it started successfully
#  PARAMETERS
#    cmds - OPTIONAL
#           default values set in module hiera
###

class gpfs::startup(
    Hash[String[1], String[1], 2, 2] $cmds,
)
{

    # START GPFS
    exec {
        'mmstartup':
            command   => 'mmstartup',
            user      => root,
            logoutput => true,
            unless    => $cmds[ 'mmgetstate' ],
            notify    => Exec[ 'mmgetstate' ],
        ;
        default:
            * => $gpfs::resource_defaults['exec'],
        ;
    }

    # WAIT FOR GPFS STATE TO BECOME ACTIVE (mmgetstate | grep active | wc -l)
    exec {
        'mmgetstate':
            command     => $cmds[ 'mmgetstate' ],
            user        => root,
            tries       => 4,
            try_sleep   => 10,
            logoutput   => true,
            refreshonly => true,
            notify      => Exec[ 'wait_for_gpfs_mount' ],
        ;
        default:
            * => $gpfs::resource_defaults['exec'],
        ;
    }


    # WAIT FOR GPFS FILESYSTEMS TO BE MOUNTED
    exec {
        'wait_for_gpfs_mount':
            command     => $cmds[ 'is_gpfs_mounted' ],
            user        => root,
            tries       => 4,
            try_sleep   => 10,
            logoutput   => true,
            refreshonly => true,
        ;
        default:
            * => $gpfs::resource_defaults['exec'],
        ;
    }

}
