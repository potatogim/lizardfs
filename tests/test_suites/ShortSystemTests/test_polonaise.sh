timeout_set '4 minutes'

assert_program_installed git
assert_program_installed cmake
assert_program_installed lizardfs-polonaise-server
assert_program_installed polonaise-fuse-client

CHUNKSERVERS=1 \
	USE_RAMDISK=YES \
	MOUNT_EXTRA_CONFIG="mfscachemode=NEVER" \
	setup_local_empty_lizardfs info

# Start Polonaise
lizardfs-polonaise-server localhost ${info[matocl]} "${info[mount0]}" &>/dev/null &
sleep 3
mnt="$TEMP_DIR/mfspolon"
mkdir -p "$mnt"

# fsname below is important. When the test is ended framework unmounts all the filesystems
# that match a given regex.
polonaise-fuse-client "$mnt" -o big_writes,allow_other,fsname=mfspolon &
assert_eventually 'mfsdirinfo "$mnt"'

# Perform a compilation
cd "$mnt"
assert_success git clone https://github.com/lizardfs/lizardfs.git
mkdir lizardfs/build
cd lizardfs/build
assert_success cmake .. -DCMAKE_INSTALL_PREFIX="$mnt"
make -j4 install
