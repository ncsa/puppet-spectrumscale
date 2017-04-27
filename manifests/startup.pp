class gpfs::startup inherits gpfs::params {

    # START GPFS
    exec { 'mmstartup':
        command   => 'mmstartup',
        user      => root,
        logoutput => true,
        unless    => $::gpfs::params::mmgetstate_cmd,
        notify    => Exec[ 'mmgetstate' ]
    }

    # WAIT FOR GPFS STATE TO BECOME ACTIVE (mmgetstate | grep active | wc -l)
    exec { 'mmgetstate':
        command   => $::gpfs::params::mmgetstate_cmd,
        user      => root,
        tries     => 4,
        try_sleep => 10,
        logoutput => true,
#        require   => Exec[ 'mmstartup' ],
        refreshonly => true,
        notify    => Exec[ 'wait_for_gpfs_mount' ],
    }


    # WAIT FOR GPFS FILESYSTEMS TO BE MOUNTED
    exec { 'wait_for_gpfs_mount':
        command   => 'test $( mount -t gpfs | wc -l ) -gt 0',
        user      => root,
        tries     => 4,
        try_sleep => 10,
        logoutput => true,
#        require   => Exec[ 'mmgetstate' ],
        refreshonly => true,
    }

}
