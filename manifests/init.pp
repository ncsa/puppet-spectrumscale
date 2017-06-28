###
### NCSA Spectrum Scale Puppet Module (formerly GPFS)
###
### This module will install the latest version of GPFS for the specified
### yum repository.  GPFS version is thus controlled by yumrepo_baseurl.

class gpfs {

    include gpfs::firewall
    include gpfs::install
    include gpfs::quota
    include gpfs::startup
    include gpfs::add_client
    include gpfs::cron

}
