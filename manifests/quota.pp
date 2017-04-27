class gpfs::quota ( 
    $host,
    $port,
) {

    $myquota = '/usr/local/bin/myquota'

    file { $myquota :
        content  => epp( 'gpfs/myquota.epp', {
            'host' => $host,
            'port' => $port,
            }
        ),
        mode     => '0755',
    }

    file { '/usr/local/bin/mmlsquota' :
        ensure => link,
        target => $myquota,
    }

    file { '/usr/local/bin/mmrepquota' :
        ensure => link,
        target => $myquota,
    }

}
