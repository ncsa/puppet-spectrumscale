# A description of what this class does
#
# @summary A short summary of the purpose of this class
#
# @example
#   include gpfs::bindmounts
class gpfs::bindmounts(
    Hash $mountmap = {},
) {

    $mountmap.each | $k, $v | {
        gpfs::bindmount{ $k: * => $v }
    }

}
