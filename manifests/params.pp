class gpfs::params {

    $sshkey_priv_path = '/root/.ssh/id_gpfs'
    $mmsdrfs = '/var/mmfs/gen/mmsdrfs'
    $mmgetstate_cmd = 'test $( mmgetstate | grep active | wc -l ) -gt 0'

    # YUMREPO DEFAULTS
    Yumrepo {
        descr     => 'Puppet Spectrum Scale',
        enabled  => 1,
        gpgcheck => 0,
    }

    # FILE DEFAULTS
    File {
        ensure   => present,
        owner    => 'root',
        group    => 'root',
        mode     => '0744',
    }

    # DEFAULT EXEC PARAMETERS
    Exec { 
        path => [ "/bin/", 
                  "/sbin/" , 
                  "/usr/bin/", 
                  "/usr/sbin/", 
                  "/usr/lpp/mmfs/bin/",
                ] 
    }

    # OSFAMILY DEPENDENT VARIABLES
    case $osfamily {
        'RedHat': { 
            $gpl_dist       = "REDHAT_AS_LINUX"  #distro name for mmbuildgpl
            $gpfs_pkg_list  = [ 'kernel-devel', 
                                'libstdc++', 
                                'gpfs.base',
                                'gpfs.gpl',
                                'gpfs.docs',
                                'gpfs.msg.en_US',
                                'gpfs.ext',
                                'gpfs.gskit',
                              ]
        }
        default: { 
            fail("Unsupported osfamily ${osfamily}") 
        }
    }

}
