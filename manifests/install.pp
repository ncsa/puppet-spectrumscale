# Parameters: 
#     yumrepo_baseurl - Yum repo from which to install gpfs client packages
#                       This will control the version of gpfs
#                       Set this to empty string to disable yumrepo management
#     gpl_dist        - OPTIONAL
#                       Defines the OS type for the GPFS install script
#                       default value defined in module hiera
#     pkg_list        - OPTIONAL
#                       list of dependent OS packages to install
#                       default value defined in module hiera
class gpfs::install(
    String              $yumrepo_baseurl,
    String[1]           $gpl_dist,
    Array[String[1], 1] $pkg_list,
)
{

#    notify {
#        "yumrepo_baseurl='${yumrepo_baseurl}'":
#            withpath => true,
#    }



    # INSTALL THE YUM REPO (if provided)
    if $yumrepo_baseurl =~ String[1] {
        notify { 'yumrepo_baseurl is set, about to setup yumrepo': }
        yumrepo { 'puppet-gpfs':
            ensure   => present,
            baseurl  => $yumrepo_baseurl,
            descr    => 'Puppet Spectrum Scale',
            enabled  => 1,
            gpgcheck => 0,
        }
    }


    # GPFS profile.d PATH SCRIPT
    $fn_gpfs_profile = '/etc/profile.d/gpfs.sh'
    file {
        $fn_gpfs_profile:
            source   => "puppet:///modules/gpfs/${fn_gpfs_profile}",
        ;
        default:
            * => $gpfs::resource_defaults['file']
        ;
    }


    # INSTALL DEPENDENT OS PACKAGES
    ensure_packages( $pkg_list )


    # BUILD KERNEL MODULE
    exec {
        'GPFS-kernel-module':
            environment => "LINUX_DISTRIBUTION=${gpl_dist}",
            command     => 'mmbuildgpl',
            creates     => "/lib/modules/${facts['kernelrelease']}/extra/mmfs26.ko",
            require     => Package[ $pkg_list ],
        ;
        default:
            * => $gpfs::resource_defaults['exec']
        ;
    }

}
