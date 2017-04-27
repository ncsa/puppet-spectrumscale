# Parameters: 
#     allowed_cidr - String 
#                  - gpfs ports will be opened in firewall to allow 
#                    communication from this network space
class gpfs::firewall( 
    $allowed_cidr,
)
{
    # FIREWALL SETTINGS
    firewall { '100 gpfs 1191':
        dport  => 1191,
        proto  => tcp,
        action => accept,
        source => $allowed_cidr,
    }

    firewall { '100 gpfs 30K range':
        dport  => '30000-30100',
        proto  => tcp,
        action => accept,
        source => $allowed_cidr,
    }
}
