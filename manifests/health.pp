# @summary Congifure GPFS Health Checks Via Telegraf
#
# @param enabled
#   Enable or disable this health check
#
# @param file_base_name
#   Basename of files used by the health check
#
# @param telegraf_cfg
#   Hash of key:value pairs passed to telegraf::input as options
#
# @param telegraf_script_cfg_fs
#   Optional GPFS filesystems parameter.
#   This is a space separated list of file system device names according to gpfs.
#   If empty will lookup from `gpfs::nativemounts::mountmap` paramter.
#
# @param telegraf_script_cfg_paths
#   Optional GPFS paths parameter.
#   This is a space separated list of paths that the ls check should run on.
#   If empty will lookup from `gpfs::bindmounts::mountmap` paramter.
#
# @param telegraf_script_cfg_files
#   Optional GPFS files parameter.
#   This is a space separated list of files the stat check should run on.
#   If empty will lookup paths from `gpfs::nativemounts::mountmap` paramter and
#   use files from `telegraf_script_cfg_filestat` paramter.
#
# @param telegraf_script_cfg_filestat
#   Filename (or directory) to stat for file health checks
#
# @example
#   include gpfs::health
class gpfs::health (
  Boolean $enabled,
  String $file_base_name,
  Hash   $telegraf_cfg,
  String $telegraf_script_cfg_fs,
  String $telegraf_script_cfg_paths,
  String $telegraf_script_cfg_files,
  String $telegraf_script_cfg_filestat,
) {
  if ($enabled) {
    File {
      ensure => 'present',
      group => 'telegraf',
      mode => '0640',
      owner => 'root',
      notify  => [
        Service['telegraf'],
      ],
    }

    include profile_monitoring::telegraf
    include ::telegraf

  } else {
    File {
      ensure => 'absent',
      notify  => [
        Service['telegraf'],
      ],
    }
  }

  # Templatized telegraf script with config
  $telegraf_path = '/etc/telegraf'
  $script_path = "${telegraf_path}/scripts/${module_name}"
  $script_extension = '.sh'
  $script_full_path = "${script_path}/${file_base_name}${script_extension}"
  $script_cfg_full_path = "${script_path}/${file_base_name}_config"

  # Create folder for telegraf lustre scripts
  $script_dir_defaults = {
    ensure => 'directory',
    owner  => 'root',
    group  => 'telegraf',
    mode   => '0750',
  }
  ensure_resource('file', $script_path , $script_dir_defaults)

  # IF $telegraf_script_cfg_ fs, path, or file ARE EMPTY, POPULATE THEM FROM BINDMOUNT LOOKUPS
  if empty($telegraf_script_cfg_fs) {
    $fs = join ( keys( lookup('gpfs::nativemounts::mountmap', Hash) ), ' ')
  } else {
    $fs = $telegraf_script_cfg_fs
  }
  if empty($telegraf_script_cfg_paths) {
    $paths = join ( keys( lookup('gpfs::bindmounts::mountmap', Hash) ), ' ')
  } else {
    $paths = $telegraf_script_cfg_paths
  }
  if empty($telegraf_script_cfg_files) {
    $files = lookup('gpfs::nativemounts::mountmap', Hash) .map |$key, $value|
      { "${value['mountpoint']}/${telegraf_script_cfg_filestat}" } .join(' ')
  } else {
    $files = $telegraf_script_cfg_files
  }

  $config_parameters = {
    fs    => $fs,
    paths => $paths,
    files => $files,
  }

  file { $script_cfg_full_path :
    content => epp("${module_name}/gpfs_client_health_config.epp", $config_parameters),
  }

  file { $script_full_path :
    source  => "puppet:///modules/${module_name}/telegraf/gpfs_client_health.sh",
    mode    => '0750',
    require => [
      File[$script_cfg_full_path],
    ],
  }

  # Setup telegraf config
  $telegraf_cfg_final = $telegraf_cfg + { 'command' => $script_full_path }
  telegraf::input { $file_base_name :
    plugin_type => 'exec',
    options     => [ $telegraf_cfg_final ],
    require     => File[$script_full_path],
  }

}
