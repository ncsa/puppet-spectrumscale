# @summary
#   Start GPFS and wait for verification that it started successfully
#
# @param cmds
#   OPTIONAL - default values set in module hiera
#
# @param no_gpfs_file
#   File path of lock file to prevent GPFS from starting
#
class gpfs::startup (
  Hash[String[1], String[1], 2, 2] $cmds,
  String $no_gpfs_file,
) {

  exec { "${no_gpfs_file} is manually set to disable GPFS startup. Remove ${no_gpfs_file} when ready for GPFS to start.":
    command  => 'true',
    path     =>  ['/usr/bin','/usr/sbin', '/bin'],
    onlyif   => "test -e ${no_gpfs_file}",
    loglevel => 'warning',
  }

  exec {
    # START GPFS
    'mmstartup':
      command => 'mmstartup',
      unless  => $cmds[ 'mmgetstate' ],
      notify  => Exec[ 'mmgetstate' ],
      onlyif  => "/usr/bin/test ! -e ${no_gpfs_file}",
      ;

    # WAIT FOR GPFS STATE TO BECOME ACTIVE (mmgetstate | grep active | wc -l)
    'mmgetstate':
      command     => $cmds[ 'mmgetstate' ],
      tries       => 4,
      try_sleep   => 10,
      refreshonly => true,
      ;

    default:
      * => $gpfs::resource_defaults['exec'],
      ;
  }

}
