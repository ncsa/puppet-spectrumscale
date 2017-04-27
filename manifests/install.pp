# Parameters: 
#     yumrepo_baseurl - String 
#                     - Yum repo from which to install gpfs client packages
#                     - This will control the version of gpfs
class gpfs::install( 
    $yumrepo_baseurl,
) inherits gpfs::params {

    # FILE RESOURCE DEFAULTS ARE IN GPFS::PARAMS
    # YUMREPO RESOURCE DEFAULTS ARE IN GPFS::PARAMS

    # INSTALL THE YUM REPO FILE
    yumrepo { 'puppet-gpfs':
        baseurl => $yumrepo_baseurl,
    }


    # GPFS profile.d PATH SCRIPT
    file { "/etc/profile.d/gpfs.sh":
        source   => "puppet:///modules/gpfs/gpfs.sh",
    }

  
    # RPM PACKAGES TO INSTALL
    ensure_packages( $gpfs::params::gpfs_pkg_list )

    # BUILD KERNEL MODULE
    exec { "GPFS-kernel-module":
        environment => "LINUX_DISTRIBUTION=${gpfs::params::gpl_dist}",
        command     => "mmbuildgpl",
        path        => "/usr/lpp/mmfs/bin",
        user        => 'root',
        logoutput   => true,
        creates     => "/lib/modules/${kernelrelease}/extra/mmfs26.ko",
        require     => Package[ $gpfs::params::gpfs_pkg_list ],
    }

}
