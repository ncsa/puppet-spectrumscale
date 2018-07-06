define gpfs::ignoremount {
### 
### This class will let you set a system to ignore a gpfs mount.  To prevent
### /scratch from mounting, issue the following:
### gpfs::ignore_mount{"scratch": } 
### 
    file { "/var/mmfs/etc/ignoreAnyMount.${name}":,
       source  => 'puppet:///modules/gpfs/ignoreAnyMount',
       require => Class['gpfs'],
    }
}
