###
#  Install cron jobs for:
#    - Exempt gpfs from linux kernel OOM killer
#    - (OPTIONAL) accept license for all nodes in cluster
#
# Parameters: 
#     accept_license - Boolean - install cron script to auto accept license
###
class gpfs::cron (
    Boolean $accept_license,
) {

    # CRON FILE LOCATIONS
    $root_cron       = '/root/cron'
    $fn_gpfs_oom     = "${root_cron}/gpfs_oom.sh"
    $fn_gpfs_license = "${root_cron}/gpfs_license.sh"

    # CRON DIRECTORY
    ensure_resource( 'file', $root_cron, { ensure => 'directory',
                                           owner  => 'root',
                                           group  => 'root',
                                           mode   => '0700',
                                         }
    )

    # EXEMPT GPFS FROM OOM KILLER
    file {
        $fn_gpfs_oom :
            source => "puppet:///modules/gpfs${fn_gpfs_oom}",
            mode   => '0700',
        ;
        default:
            * => $gpfs::resource_defaults['file']
        ;
    }
    cron {
        'gpfs_oom' :
            ensure  => present,
            command => $fn_gpfs_oom,
            hour    => 0,
            minute  => 2,
        ;
        default:
            * => $gpfs::resource_defaults['cron']
        ;
    }

    # CHECK & ACCEPT LICENSE FEATURE IS OPTIONAL
    if $accept_license {
        $license_ensure = 'present'
    }
    else {
        $license_ensure = 'absent'
    }
    file {
        $fn_gpfs_license :
            ensure => $license_ensure,
            source => "puppet:///modules/gpfs${fn_gpfs_license}",
            mode   => '0700',
        ;
        default:
            * => $gpfs::resource_defaults['file']
        ;
    }
    cron {
        'gpfs_license' :
            ensure  => $license_ensure,
            command => $fn_gpfs_license,
            hour    => 0,
            minute  => 1,
        ;
        default:
            * => $gpfs::resource_defaults['cron']
        ;
    }
}
