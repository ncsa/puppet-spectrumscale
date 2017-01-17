###
### NCSA Spectrum Scale Puppet Module (formerly GPFS)
###
### This module will install the latest version of GPFS for the specified
### yum repository.  GPFS version is thus controlled by the repository.

# Parameters: 
#     yumrepo_baseurl - String 
#                     - Yum repo from which to install gpfs client packages
#                     - This will control the version of gpfs
#     firewall_allowed_cidr - String 
#                           - gpfs ports will be opened in firewall to allow 
#                             communication from this network space
class gpfs( 
    $yumrepo_baseurl,
    $firewall_allowed_cidr,
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
    exec { "GPFS-${gpfs_version}-kernel-module":
        environment => "LINUX_DISTRIBUTION=${gpfs::params::gpl_dist}",
        command     => "mmbuildgpl",
        path        => "/usr/lpp/mmfs/bin",
        user        => 'root',
        logoutput   => true,
        creates     => "/lib/modules/${kernelrelease}/extra/mmfs26.ko",
        require     => Package[ $gpfs::params::gpfs_pkg_list ],
    }


    # FIREWALL SETTINGS
    firewall { '100 gpfs 1191':
        dport  => 1191,
        proto  => tcp,
        action => accept,
        source => $firewall_allowed_cidr,
    }

    firewall { '100 gpfs 30K range':
        dport  => '30000-30100',
        proto  => tcp,
        action => accept,
        source => $firewall_allowed_cidr,
    }
}
