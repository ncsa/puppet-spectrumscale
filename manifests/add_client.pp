# INPUT PARAMETERS
#    master_server - String - FQDN of gpfs master server
#    sshkey_priv_contents - String - private ssh key contents to ssh into master_server
class gpfs::add_client(
    $master_server,
    $sshkey_priv_contents,
    $sshkey_pub_contents,
) 
inherits gpfs::params
{

    include gpfs::startup

    $add_client_script_filename = '/root/gpfs_add_client.sh'

    # SKIP ADD CLIENT IF NODE IS ALREADY PART OF A GPFS CLUSTER
    if ! $facts['is_gpfs_member_node'] 
    {
        # ADD_CLIENT BASH SCRIPT
        file { $add_client_script_filename:
            ensure   => present,
            owner    => root,
            group    => root,
            mode     => '0700',
            content  => epp('gpfs/add_client.epp', {
                'sshkey_priv_contents' => $sshkey_priv_contents,
                'sshkey_priv_path'     => $::gpfs::params::sshkey_priv_path,
                'gpfs_master'          => $master_server,
                'client_hostname'      => $facts['hostname'],
                'add_client_script_filename' => $add_client_script_filename,
                }
            ),
        }

        # EXECUTE ADD CLIENT SCRIPT
        exec { 'gpfs_add_client':
            command   => "${add_client_script_filename} ${master_server}",
            user      => 'root',
            logoutput => true,
            creates   => $::gpfs::params::mmsdrfs,
            require   => [ File[ $add_client_script_filename ],
                           Class[ 'gpfs' ],
                         ],
            notify    => [ Class[ 'gpfs::startup' ],
                           Exec[ 'rm_gpfs_add_client_sh' ],
                         ],
        }
        
        exec { 'rm_gpfs_add_client_sh':
            command => "/bin/rm -f ${add_client_script_filename}",
            user    => 'root',
            require => File[ $add_client_script_filename ],
        }
    }

    # AUTHORIZE SSH FROM GPFS MASTER
    ssh_authorized_key { 'gpfs_master_authorized_key':
        user  => 'root',
        type  => 'ssh-rsa',
        name  => 'root@lsst_gpfs',
        key   => $sshkey_pub_contents,
    }

    # ALLOW GPFS MASTER THROUGH FIREWALL
    firewall { '100 ssh from gpfs master':
        dport  => 22,
        proto  => tcp,
        action => accept,
        source => $master_server,
    }

    # ENSURE PRIVATE SSH KEY FILE IS REMOVED
    # add client bash script writes sshkey_priv_contents to a local file and,
    # if all goes well, it will remove the file when it's done.
    # This resource is just a backup in case the script doesn't run to completion.
    file { $::gpfs::params::sshkey_priv_path:
        ensure => absent,
    }

}
