{ lib, ... }:

{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        # The device path will be determined during installation
        # Common values: /dev/sda, /dev/nvme0n1, /dev/vda
        device = lib.mkDefault "/dev/sda";
        content = {
          type = "gpt";
          partitions = {
            # EFI System Partition
            ESP = {
              size = "512M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];
              };
            };
            # Swap partition
            # Default 4G is suitable for systems with 8-16GB RAM
            # Adjust based on your hardware (recommend 1x-2x RAM for hibernation)
            swap = {
              size = "4G";
              content = {
                type = "swap";
                resumeDevice = true;
              };
            };
            # Root partition (rest of the disk)
            root = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
              };
            };
          };
        };
      };
    };
  };
}
