###
#  NCSA custom quota command
#
#  @summary
#  Override native gpfs quota command with a script that will
#  invoke a custom quota command on the gpfs server specified by
#  $host on $port.
###
class gpfs::quota (
    String[1]         $host,
    Integer[1, 65535] $port,
) {

    $myquota = '/usr/local/bin/myquota'
    $symlinks = ['/usr/local/bin/mmlsquota', '/usr/local/bin/mmrepquota']

    file {
        $symlinks:
            ensure => link,
            target => $myquota,
        ;
        $myquota :
            content => epp( 'gpfs/myquota.epp', {
                'host' => $host,
                'port' => $port,
                }
            ),
            mode    => '0755',
        ;
        default:
            * => $gpfs::resource_defaults['file']
        ;
    }

}
