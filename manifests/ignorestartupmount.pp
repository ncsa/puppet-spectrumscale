define gpfs::ignorestartupmount {
### 
### This class will let you set a system to ignore a gpfs mount at startup.
### 
    file { "/var/mmfs/etc/ignoreStartupMount.${name}":,
       source   => "puppet:///modules/gpfs/ignoreStartupMount",
       require  => Class['gpfs'],
    }
}
