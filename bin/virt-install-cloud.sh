#!/bin/bash

usage() {
	cat <<-EOF
	Usage:
	    $0 [options] -- [virt-install options]
	    -n|--name: instance name (default: instance-0)
	    -r|--memory: instance memory size (default: 1024)
	    -i|--image: cloud image path (required option)
	    -k|--ssh-key: ssh public key to inject into instance (default: ~/.ssh/id_rsa.pub)
	    -s|--disk-size: instance disk image size (default: 20G)
	    -f|--disk-format: instance disk image format (default: qcow2)
	    -p|--password: password for default user (default: goodluck)
	    -h|--help: print usage and exit
	EOF
}

TEMP=$(getopt -o 'n:r:i:k:s:f:p:h' -l 'name:,memory:,image:,ssh-key:,disk-size:,disk-format:,password:,help' -n 'virt-install-cloud' -- "$@")
if [[ $? -ne 0 ]]; then
	usage >&2
	exit 1
fi

eval set -- "$TEMP"
unset TEMP

while :; do
	case "$1" in
		'-n'|'--name')
			INSTANCE_NAME="$2"; shift 2; continue;;
		'-r'|'--memory')
			MEMORY_SIZE="$2"; shift 2; continue;;
		'-i'|'--image')
			CLOUD_IMAGE="$2"; shift 2; continue;;
		'-k'|'--ssh-key')
			SSH_KEY_FILE="$2"; shift 2; continue;;
		'-s'|'--disk-size')
			DISK_SIZE="$2"; shift 2; continue;;
		'-f'|'--disk-format')
			DISK_FORMAT="$2"; shift 2; continue;;
		'-p'|'--password')
			PASSWORD="$2"; shift 2; continue;;
		'-h'|'--help')
			usage; shift; exit 0;;
		'--')
			shift; break;;
		*) echo "internal error" >&2; exit 1;;
	esac
done

INSTANCE_NAME=${INSTANCE_NAME:-"instance-0"}
MEMORY_SIZE=${MEMORY_SIZE:-"1024"}
SSH_KEY_FILE=${SSH_KEY_FILE:-"~/.ssh/id_rsa.pub"}
DISK_SIZE=${DISK_SIZE:-"20G"}
DISK_FORMAT=${DISK_FORMAT:-"qcow2"}
PASSWORD=${PASSWORD:-"goodluck"}

if [[ -z $CLOUD_IMAGE || ! -f $CLOUD_IMAGE ]]; then
	echo "cloud image is required" >&2
	exit 1
fi
CLOUD_IMAGE=$(realpath $CLOUD_IMAGE)

if [[ -f $SSH_KEY_FILE ]]; then
	SSH_KEY=$(cat $SSH_KEY_FILE)
fi

TEMP_DIR=$(mktemp -d)
chmod 755 $TEMP_DIR
pushd $TEMP_DIR
cat > meta-data <<-EOF
	instance-id: $INSTANCE_NAME
	local-hostname: $INSTANCE_NAME.localdomain
EOF

cat > user-data <<-EOF
	#cloud-config
	password: $PASSWORD
	chpasswd: { expire: False }
	ssh_pwauth: True
EOF

if [[ -n $SSH_KEY ]]; then
cat >> user-data <<-EOF
	ssh_authorized_keys:
	  - $SSH_KEY
EOF
fi

genisoimage -output cidata.iso \
	-volid cidata \
	-joliet \
	-rock \
	user-data meta-data || {
	echo "failed to create cidata.iso: $?" >&2
	exit 1
}

popd

BACKING_FORMAT=$(qemu-img info $CLOUD_IMAGE | grep 'file format' | cut -d' ' -f3)
virsh vol-create-as --pool default \
	--name $INSTANCE_NAME.qcow2 \
	--capacity $DISK_SIZE \
	--format $DISK_FORMAT \
	--backing-vol $CLOUD_IMAGE \
	--backing-vol-format $BACKING_FORMAT || {
	echo "failed to create volume: $?" >&2
	exit 1
}

virt-install --import \
	--cpu host \
	--name $INSTANCE_NAME \
	--disk vol=default/$INSTANCE_NAME.$DISK_FORMAT \
	--disk path=$TEMP_DIR/cidata.iso,device=cdrom \
	--memory $MEMORY_SIZE \
	"$@"
