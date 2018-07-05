###
#   NCSA Spectrum Scale Puppet Module (formerly GPFS)
#
#   This module will install the latest version of GPFS for the specified
#   yum repository.  GPFS version is thus controlled by yumrepo_baseurl.
#
#   Parameters:
#       resource_defaults - OPTIONAL
#                           default values set in module hiera
###

class gpfs(
    Hash[String[1], default, 1] $resource_defaults,
)
{

    include gpfs::firewall
    include gpfs::install
#    include gpfs::quota
#    include gpfs::startup
    include gpfs::add_client
    include gpfs::cron

}
