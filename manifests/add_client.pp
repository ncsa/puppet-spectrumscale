###
#  Add this node to the gpfs cluster
#  PARAMETERS
#    master_server            - FQDN of gpfs master server
#    ssh_private_key_contents - private ssh key contents to enable ssh into
#                               master_server
#    ssh_public_key_contents  - public ssh key contents to enable ssh into
#                               master_server
#    ssh_private_key_path     - OPTIONAL
#                               path to store the gpfs private key
#                               default set in module hiera
#    script_tgt_fn            - OPTIONAL
#                               where to store the "add_client" bash script
#                               default set in module hiera
#    mmsdrfs                  - OPTIONAL
#                               path to mmsdrfs command
#                               default set in module hiera
####
class gpfs::add_client(
    String[1] $master_server,
    String[1] $ssh_private_key_contents,
    String[1] $ssh_public_key_contents,
    String[1] $ssh_private_key_path,
    String[1] $script_tgt_fn,
    String[1] $mmsdrfs,
)
{

    include gpfs::startup

    # SKIP ADD CLIENT IF NODE IS ALREADY PART OF A GPFS CLUSTER
    if ! $facts['is_gpfs_member_node']
    {
        # ADD_CLIENT BASH SCRIPT
        file {
            $script_tgt_fn:
                ensure  => present,
                owner   => root,
                group   => root,
                mode    => '0700',
                content => epp('gpfs/add_client.epp', {
                    'ssh_private_key_contents' => $ssh_private_key_contents,
                    'ssh_private_key_path'     => $ssh_private_key_path,
                    'gpfs_master'              => $master_server,
                    'client_hostname'          => $facts['hostname'],
                    'script_fn'                => $script_tgt_fn,
                    }
                ),
            ;
            default:
                * => $gpfs::resource_defaults['file']
            ;
        }

        # EXECUTE ADD CLIENT SCRIPT
        exec {
            'gpfs_add_client':
                command => "${script_tgt_fn} ${master_server}",
                creates => $mmsdrfs,
                require => [ File[ $script_tgt_fn ],
                             Class[ 'gpfs' ],
                           ],
                notify  => [ Class[ 'gpfs::startup' ],
                             Exec[ 'rm_gpfs_add_client_sh' ],
                           ],
            ;
            'rm_gpfs_add_client_sh':
                command => "/bin/rm -f ${script_tgt_fn}",
                require => File[ $script_tgt_fn ],
            ;
            default:
                * => $gpfs::resource_defaults['exec']
            ;
        }
    }

    # AUTHORIZE SSH FROM GPFS MASTER
    ssh_authorized_key { 'gpfs_master_authorized_key':
        user => 'root',
        type => 'ssh-rsa',
        name => 'root@lsst_gpfs',
        key  => $ssh_public_key_contents,
    }

    # ALLOW GPFS MASTER THROUGH FIREWALL
    firewall { '100 ssh from gpfs master':
        dport  => 22,
        proto  => tcp,
        action => accept,
        source => $master_server,
    }

    # ENSURE PRIVATE SSH KEY FILE IS REMOVED
    # add client bash script writes ssh_private_key_contents to a local file and,
    # if all goes well, it will remove the file when it's done.
    # This resource is just a backup in case the script doesn't run to completion.
    file { $ssh_private_key_path:
        ensure => absent,
    }

}
