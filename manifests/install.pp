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
    $fn_gpfs_profile = '/etc/profile.d/gpfs.sh'
    file { $fn_gpfs_profile :
        source   => "puppet:///modules/gpfs/${fn_gpfs_profile}",
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
