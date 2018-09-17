# @summary
#   Manage a gpfs yum repo (optional)
#   Install gpfs
#   Build kernel module
#   Parameters: 
#     yumrepo_baseurl - Yum repo from which to install gpfs client packages
#                       This will control the version of gpfs
#                       Set this to empty string to disable yumrepo management
#     gpl_dist        - OPTIONAL
#                       Defines the OS type for the GPFS install script
#                       default value defined in module hiera
#     pkg_list        - OPTIONAL
#                       list of dependent OS packages to install
#                       default value defined in module hiera
#     kernel_module_build_only_if
#                     - OPTIONAL
#                       determine if the kernel module needs to be (re)built
#                       default value defined in module hiera
class gpfs::install(
    String              $yumrepo_baseurl,
    String[1]           $gpl_dist,
    Array[String[1], 1] $pkg_list,
    String[1]           $kernel_module_build_only_if,
)
{

    # INSTALL THE YUM REPO (if provided)
    if $yumrepo_baseurl =~ String[1] {
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
    # In an attempt to address the fact that gpfs rpm's don't have good
    # dependency information, a custom yumrepo is built for each specific
    # gpfs version and each custom yumrepo has only the rpm's that are relevant
    # for that release.
    # Ensure that gpfs rpms are present. Not using "latest" since
    # gpfs rpm upgrade will fail while gpfs is running and this module is not
    # built to shutdown gpfs first (nor is a random gpfs shutdown a useful
    # action.)
    ensure_packages( $pkg_list, {'ensure' => 'present'} )


    # BUILD KERNEL MODULE
    # Kernel modules need to be built when:
    # 1. New kernel is installed, thus mmfs26.ko won't exist
    # 2. New gpfs rpm's are installed, thus mmfs26.ko mtime will be older than
    #    gpfs rpm installtime
    exec {
        'build-gpfs-kernel-module':
            environment => "LINUX_DISTRIBUTION=${gpl_dist}",
            command     => 'mmbuildgpl',
            onlyif      => $kernel_module_build_only_if,
            require     => Package[ $pkg_list ],
        ;
        default:
            * => $gpfs::resource_defaults['exec']
        ;
    }

}
