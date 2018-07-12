# A description of what this class does
#
# @summary A short summary of the purpose of this class
#
# @example
#   include gpfs::nativemounts
class gpfs::nativemounts(
    Hash $mountmap = {},
) {

    $mountmap.each | $k, $v | {
        gpfs::nativemount{ $k: * => $v }
    }

}
