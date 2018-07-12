#
# @summary
#   Create bindmounts as specified in Hiera
#
# @example
#   This class is already included by gpfs::init, so just need to specify,
#   in hiera, the list of bindmounts and associated data.
#
#   HIERA
#   ---
#   gpfs::bindmounts::mountmap:
#       /scratch:
#           opts: nosuid
#           src_path:  /lsst/scratch
#           src_mountpoint: /lsst

class gpfs::bindmounts(
    Hash $mountmap = {},
) {

    $mountmap.each | $k, $v | {
        gpfs::bindmount{ $k: * => $v }
    }

}
