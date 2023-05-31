# put this file into the container directory (rootfs) to run the image

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

unshare -rm --propagation slave bash -c "\
    mount -R /proc $SCRIPT_DIR/proc;\
    mount -R /dev $SCRIPT_DIR/dev;\
    mount --bind /etc/resolv.conf $SCRIPT_DIR/etc/resolv.conf;\
    mount -o nodev,nosuid,size=16G -t tmpfs tmpfs $SCRIPT_DIR/tmp;\
    mount -o nodev,nosuid,size=16G -t tmpfs tmpfs $SCRIPT_DIR/run;\
    export HOME=/root;\
    export SHELL=/bin/sh;\
    export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin;\
    chroot $SCRIPT_DIR $*"
