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

    exec {
        # START GPFS
        'mmstartup':
            command => 'mmstartup',
            unless  => $cmds[ 'mmgetstate' ],
            notify  => Exec[ 'mmgetstate' ],
        ;

        # WAIT FOR GPFS STATE TO BECOME ACTIVE (mmgetstate | grep active | wc -l)
        'mmgetstate':
            command     => $cmds[ 'mmgetstate' ],
            tries       => 4,
            try_sleep   => 10,
            refreshonly => true,
            notify      => Exec[ 'wait_for_gpfs_mount' ],
        ;

        # WAIT FOR GPFS FILESYSTEMS TO BE MOUNTED
        'wait_for_gpfs_mount':
            command     => $cmds[ 'is_gpfs_mounted' ],
            tries       => 4,
            try_sleep   => 10,
            refreshonly => true,
        ;

        default:
            * => $gpfs::resource_defaults['exec'],
        ;
    }

}
