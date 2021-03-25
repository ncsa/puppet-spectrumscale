Facter.add(:is_gpfs_member_node) do
  setcode do
    File.exist? '/var/mmfs/gen/mmsdrfs'
  end
end
