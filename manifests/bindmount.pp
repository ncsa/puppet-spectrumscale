# Create a bindmount
#
# @summary
#   Defined type, not intended to be invoked directly, but rather via
#   gpfs::bindmounts. The name of the resource is the target mountpath.
#
# @param src_path
#   The source of this bindmount (ie: the directory this bindmount will point
#   to).
#
# @param src_mountpoint
#   The mountpath of the gpfs filesystem that this bindmount depends
#   on
# @param ops
#   Comma separated list of mount options.
#
define gpfs::bindmount(
  String[1] $src_path,
  String[1] $src_mountpoint,
  String    $opts = '',
)
{
#    notify {"gpfs::bindmount ${name}":}

  # Resource defaults
  $dir_defaults = merge(
    $gpfs::resource_defaults['file'],
    { 'ensure' => 'directory' }
  ).delete( [ 'mode', 'group', 'owner' ] )


  # Build mount option string
  $defaultopts = 'bind,noauto'
  if $opts =~ String[2] {
    $optstr = "${defaultopts},${opts}"
  }
  else {
    $optstr = $defaultopts
  }


  # Ensure parents of target dir exist, if needed (excluding / )
  $dirparts = reject( split( $name, '/' ), '^$' )
  $numparts = size( $dirparts )
  if ( $numparts > 1 ) {
    each( Integer[2,$numparts] ) |$i| {
      ensure_resource(
        'file',
        reduce( Integer[2,$i], $name ) |$memo, $val| { dirname( $memo ) },
        $dir_defaults
      )
    }
  }


  # Remove mode from defaults so that existing tgt mount won't be affected
  # otherwise might change perms on target mountpoint
  file {
    # Ensure target directory exists
    $name:
    ;
    default: * => $dir_defaults
    ;
  }


  # Define the bind mount point
  mount {
    $name:
      device  => $src_path,
      options => $optstr,
      require => [
        File[ $name ],
        Exec[ "mmmount ${src_mountpoint}" ],
      ],
    ;
    default: * => $gpfs::resource_defaults['mount']
    ;
  }

}
