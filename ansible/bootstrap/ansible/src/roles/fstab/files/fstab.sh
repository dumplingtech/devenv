#!/bin/bash -e

mount_path=/local

format_ext4() {
    local drive=$1 mount=$2
    mkfs -t ext4 $drive
    tune2fs -m 0 $drive # remove reserved blocks
    tune2fs -o journal_data_writeback $drive # no need to wait for writes
    fstab="$drive $mount auto defaults,noatime,nodiratime,data=writeback,barrier=0,nobh,errors=remount-ro 0 1"
    if grep $drive /etc/fstab &> /dev/null; then
        sed -i "s|^$drive\s.*$|$fstab|" /etc/fstab
    else
        echo "$fstab" >> /etc/fstab
    fi
    mkdir -p $mount
    mount $mount
}

make_swap() {
    local path=$1 size=$2

    if [ ! -d $path ] || [ -f ${path}/swap ]; then
        echo "Bad path parameter to make_swap: $path"
        exit 1
    fi
    path=${path}/swap

    if [ -z "$size" ]; then
        size=$(($(free -m |grep 'Mem:' |awk '{print $2}') / 2))
    fi

    swap_size=$(free -m |grep 'Swap:' |awk '{print $2}')
    if (($swap_size > 0)); then
        echo "Swap already enabled: $swap_size"
        exit 1
    fi

    disk_size=$(df -BM $path |tail -n 1 |awk '{print $4}' |sed 's|M||')
    if (($((2*$size)) > $disk_size)); then
        echo "Disk size too small to hold swap: disk($disk_size) swap($size)"
        exit 1
    fi

    fallocate -l ${size}M $path
    chmod 600 $path
    mkswap $path
    swapon $path
    fstab="$path none swap sw 0 0"
    if grep $path /etc/fstab &> /dev/null; then
        sed -i "s|^$path\s.*$|$fstab|" /etc/fstab
    else
        echo "$fstab" >> /etc/fstab
    fi
}

link_docker() {
    local path=$1 size=$2

    disk_size=$(df -BM $path |tail -n 1 |awk '{print $4}' |sed 's|M||')

    if [ -e /var/lib/docker ]; then
        echo "Docker directory already exists"

    elif (($disk_size < $size)); then
        echo "Disk size too small to hold Docker storage: disk($disk_size) required($size)"

    else
        mkdir -p ${path}/docker
        mkdir -p /var/lib/docker
        mount --bind ${path}/docker /var/lib/docker
        echo "/var/lib/docker ${path}/docker none bind" >> /etc/fstab
    fi
}

create_raid() {
    raid_dev=$1
    shift
    DEBIAN_FRONTEND=noninteractive apt-get install -yqq --no-install-recommends mdadm
    echo -e 'y\n' | mdadm --create --force --quiet --verbose $raid_dev --level=stripe --raid-devices=$# $*
}

# determine the number of local drives
# ebs volumes are assumed to occupy xvd[f-p]
root_device=$(basename $(df -h / |tail -n 1 |awk '{print $1}') |sed 's|[0-9]||')
drives=($(ls /dev/xvd* |grep -v xvd[f-p] |grep -v ${root_device})) || true

# bail if no drives available or system was previously initialized
if [ ${#drives[@]} -eq 0 ] ; then
    mkdir -p ${mount_path}
    echo "No extra drives to manage ..."
    exit 0
fi

# unmount all extra drives
for ((i=0; i<${#drives[@]}; i++)); do
    if mount |grep ${drives[i]} &> /dev/null; then umount -f ${drives[i]}; fi
done

# clean up /etc/fstab
swapoff -a
grep LABEL=cloudimg-rootfs /etc/fstab > /tmp/fstab
mv /tmp/fstab /etc/fstab

# create raid if more than 1 device
if ((${#drives[@]} > 1)); then
    device=/dev/md0
    if ! ls $device &> /dev/null; then
        create_raid $device ${drives[@]}
    else
        umount -f $device
    fi
else
    device=${drives[0]}
fi

format_ext4 $device $mount_path
make_swap $mount_path

# link /var/lib/docker if local storage if there's enough space
# Note: docker storage should stay on EBS root partition
#
# link_docker $mount_path 10000
