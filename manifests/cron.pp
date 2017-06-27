# Parameters: 
#     accept_license - Boolean - install cron script to auto accept license
class gpfs::cron (
    Boolean $accept_license,
) {

    # RESOURCE DEFAULTS
    File {
        owner    => 'root',
        group    => 'root',
        mode     => '0700',
    }

    # CRON FILE LOCATIONS
    $root_cron       = '/root/cron'
    $fn_gpfs_oom     = "${root_cron}/gpfs_oom"
    $fn_gpfs_license = "${root_cron}/gpfs_license"
    $fn_crontab      = '/etc/cron.d/gpfs'

    # CRON DIRECTORY
    file { $root_cron :
        ensure   => 'directory',
    }

    # EXEMPT GPFS FROM OOM KILLER
    file { $fn_gpfs_oom :
        ensure  => present,
        source  => "puppet:///modules/gpfs/${fn_gpfs_oom}"
    }
    file_line { 'crontab_gpfs_oom' :
        path  => $fn_crontab,
        line  => "2 0 * * * root ( ${fn_gpfs_oom} )"
    }

    # CHECK & ACCEPT LICENSE FEATURE IS OPTIONAL
    if $accept_license {
        $license_ensure = 'present'
        $license_crontab = "1 0 * * * root ( ${fn_gpfs_license} )"
    }
    else {
        $license_ensure = 'absent'
        $license_crontab = ''
    }
    file { $fn_gpfs_license :
        ensure   => $license_ensure,
        source   => "puppet:///modules/gpfs/${fn_gpfs_license}",
    }
    file_line { 'crontab_gpfs_license' :
        path  => $fn_crontab,
        line  => $license_crontab,
    }
}
