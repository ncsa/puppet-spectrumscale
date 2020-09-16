# Parameters: 
#     allow_from - allow incoming traffic from these sources
#                  on GPFS specific tcp ports
class gpfs::firewall(
  Array[String[1], 1] $allow_from,
)
{
  $common_parms = {
    proto  => tcp,
    action => accept,
  }

  each( $allow_from ) |$ip_src| {
    if '-' in $ip_src {
      # Source looks like an ip-range (ie: IP1-IP2)
      $key = 'src_range'
    } else {
      # Otherwise, assume ip_src is a valid "source"
      # (ie: ip address or cidr)
      $key = 'source'
    }

    # merged set of params for each firewall definition below
    $fw_parms = merge( $common_parms, { $key => $ip_src } )

    # Open firewall ports
    each( ['1191', '30000-30100'] ) |$dport| {
      firewall {
        "100 gpfs ${dport} allow from ${ip_src}":
          dport => $dport,
          *     => $fw_parms
          ;
      }
    }
  }
}
