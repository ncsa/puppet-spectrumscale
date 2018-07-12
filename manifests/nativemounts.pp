# @summary
#   Mount all specified GPFS filesystems
#
# @example
#   This class is already included from gpfs::init, so just need to 
#   specify, in hiera, which filesystems to mount 
#
#   HIERA
#   ---
#   gpfs::nativemounts::mountmap:
#       lsst:
#           opts: ro
#
class gpfs::nativemounts(
    Hash $mountmap = {},
) {

    $mountmap.each | $k, $v | {
        gpfs::nativemount{ $k: * => $v }
    }

}
