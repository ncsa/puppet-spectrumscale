# @summary Add this node to the gpfs cluster
#
# @param interface
#   OPTIONAL - Name of network interface whose IP will be used to register with GPFS.
#   If undefined with add with default (accoring to Puppet) IP address.
#
# @param master_server
#   FQDN of gpfs master server
#
# @param mmsdrfs
#   OPTIONAL - path to mmsdrfs command default set in module hiera
#
# @param nodeclasses
#   OPTIONAL - list of nodeclasses to which this node should be added master_server
#
# @param pagepool
#   OPTIONAL - Amount of RAM to dedicate to gpfs pagepool.
#   Format: integer number followed by one of K, M, or G.
#
# @param pagepool_max_ram_percent
#   OPTIONAL - Max percent of RAM allowed for gpfs pagepool.
#   Must be an integer between 10 and 90.
#
# @param script_tgt_fn
#   OPTIONAL - where to store the "add_client" bash script default set in module hiera
#
# @param ssh_private_key_contents
#   private ssh key contents to enable ssh into master_server
#
# @param ssh_private_key_path
#   OPTIONAL - path to store the gpfs private key (default set in module hiera)
#
# @param ssh_public_key_contents
#   public ssh key contents to enable ssh into master_server
#
# @param ssh_public_key_type
#   public ssh key type, e.g. 'rsa'
#
class gpfs::add_client (
  String    $interface,
  String[1] $master_server,
  String[1] $mmsdrfs,
  Array     $nodeclasses,
  String    $pagepool,
  Integer   $pagepool_max_ram_percent,
  String[1] $script_tgt_fn,
  String[1] $ssh_private_key_contents,
  String[1] $ssh_private_key_path,
  String[1] $ssh_public_key_contents,
  String[1] $ssh_public_key_type,
) {

  include gpfs::startup

  # AUTHORIZE SSH FROM GPFS MASTER
  ssh_authorized_key { 'gpfs_master_authorized_key':
    user => 'root',
    type => $ssh_public_key_type,
    #name => "root@${master_server}",
    name => 'root@gpfs',
    key  => $ssh_public_key_contents,
  }

  # ALLOW GPFS MASTER THROUGH FIREWALL
  firewall { '100 ssh from gpfs master':
    dport  => 22,
    proto  => tcp,
    action => accept,
    source => $master_server,
  }

  # SKIP ADD CLIENT IF NODE IS ALREADY PART OF A GPFS CLUSTER
  if ! $facts['is_gpfs_member_node']
  {
    # GET IP OF GPFS INTERFACE
    if ( ! empty( $interface ) ) {
      $gpfs_ip_address = $facts['networking']['interfaces'][$interface]['ip']
    } else {
      $gpfs_ip_address = $facts['ipaddress']
    }

    # ADD_CLIENT BASH SCRIPT
    file {
      $script_tgt_fn:
        ensure  => present,
        owner   => root,
        group   => root,
        mode    => '0700',
        content => epp('gpfs/add_client.epp', {
          'hostname'                 => $facts['hostname'],
          'gpfs_master'              => $master_server,
          'ipaddress'                => $gpfs_ip_address,
          'nodeclasses'              => $nodeclasses,
          'pagepool'                 => $pagepool,
          'pagepool_max_ram_percent' => $pagepool_max_ram_percent,
          'script_fn'                => $script_tgt_fn,
          'ssh_private_key_contents' => $ssh_private_key_contents,
          'ssh_private_key_path'     => $ssh_private_key_path,
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
        onlyif  => "/usr/bin/test ! -e ${gpfs::startup::no_gpfs_file}",
        require => [
          File[ $script_tgt_fn ],
          Class[ 'gpfs' ],
          Ssh_authorized_key[ 'gpfs_master_authorized_key' ],
          Firewall[  '100 ssh from gpfs master' ],
        ],
        notify  => [
          Class[ 'gpfs::startup' ],
          Exec[ 'rm_gpfs_add_client_sh' ],
          File[ $ssh_private_key_path ],
        ],
      ;
      'rm_gpfs_add_client_sh':
        command => "/bin/rm -f ${script_tgt_fn}",
        require => [
          File[ $script_tgt_fn ],
          Exec[ 'gpfs_add_client' ],
        ]
      ;
      default:
        * => $gpfs::resource_defaults['exec']
      ;
    }
  }
  else
  {
    exec {
      'rm_gpfs_add_client_sh':
        command => "/bin/rm -f ${script_tgt_fn}",
        onlyif  => "test -f ${script_tgt_fn}",
      ;
      default:
        * => $gpfs::resource_defaults['exec']
      ;
    }
  }

  # ENSURE PRIVATE SSH KEY FILE IS REMOVED
  # add client bash script writes ssh_private_key_contents to a local file and,
  # if all goes well, it will remove the file when it's done.
  # This resource is just a backup in case the script doesn't run to completion.
  file { $ssh_private_key_path:
    ensure => absent,
  }

}
