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

        # Port 1191
        firewall { '100 gpfs 1191':
            dport => 1191,
            *     => $fw_parms,
        }

        # Ports in the 30K range
        firewall { '100 gpfs 30K range':
            dport => '30000-30100',
            *     => $fw_parms,
        }
    }
}
