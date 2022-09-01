# @summary
#   Manage a gpfs yum repo (optional) & Install GPFS
#
# @param yumrepo_baseurl
#   Yum repo from which to install gpfs client packages. This will control the
#   version of gpfs. Set this to empty string to disable yumrepo management.
# @param pkg_list
#   OPTIONAL - List of dependent OS packages to install. Default value defined
#   in module hiera.
#
class gpfs::install (
  String              $yumrepo_baseurl,
  Array[String[1], 1] $pkg_list,
) {

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

}
