###
#   NCSA Spectrum Scale Puppet Module (formerly GPFS)
#
#   @summary
#   This module will install the latest version of GPFS for the specified
#   yum repository.  GPFS version is thus controlled by yumrepo_baseurl.
#
#   Parameters:
# @param resource_defaults
#   OPTIONAL - default values set in module hiera
#
# @example
#   include gpfs
###
#
class gpfs (
  Hash[String[1], Hash[String[1], Data, 1], 1] $resource_defaults,
) {

  include gpfs::firewall
  include gpfs::install
  include gpfs::add_client
  include gpfs::cron
  include gpfs::nativemounts
  include gpfs::bindmounts
  include gpfs::health

}
