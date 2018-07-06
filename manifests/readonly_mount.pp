define gpfs::readonly_mount {
### 
### This class will let you set a system to mount a device read-only.
### To use this, call gpfs::readonly_mount{"scratch": } 
### 
    file { "/var/mmfs/etc/localMountOptions.${name}":,
        source  => 'puppet:///modules/gpfs/localMountOptions.ro',
        require => Class['gpfs'],
    }
}
