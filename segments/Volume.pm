
##
##  Example POD: taken from a module I composed which cannot be
##         shared in it entirety
##

1;

__END__

##
## Documentation
##

=pod

=head1 NAME

 AC::Tier3::Volume()

=head1 SYNOPSIS

Abstracts management behaviors for a single Tier3 Storage Volume.

=head1 DESCRIPTION

This class implements a storage manager that clients use
to query the status of and make changes to a single volumes contents.

=head1 USAGE

=head2 Code Example

=begin text

  ## Example usage
  use AC::Tier3::Volume;

  my $ret;
  my $vol = new AC::Tier3::Volume('/volume/mount-point');

  ## Get volume name back from object
  ##  (see: perldoc Returned for details)
  if(($ret = $vol->volumePathName)->isOkay ))
  {
     printf "%s\n", $ret->getProperty('volume');
  }

  $ret = $vol->setoption('LOCK1','ONLINE');


=end text

=head1 METHODS

=over 4

=item volumePathName()

Returns the volume pathname of this volume.

my $volume = ($vol->volumePathName)->getProperty('volume');

=item isOnline()

Tests the assigned volume to determine if it is in an online state.

=item isReadable()

Alias for isOnline.

=item isWritable()

Tests if the volume is online and writable.

=item isEmpty()

The isEmpty() method scans the filesystem for objects. Returns true
if no objects are found and the Volume is online.

=item kbytesfree()

Employs the use of the UNIX "df" command to collect the amount of free space
for the attached volume mount point. The collected value is cached. Further calls
to this method skips the using of the unix df command and returns the cached value.
This method can be forced to ignore the cached value and collect a fresh value
by passing an argument of '-force'. In most cases the cached value is acceptable
due to the short runtime (program not a daemon).

  my $kbfree = ($vol->kbytesfree)->getProperty('kbytesfree');

=item inodesfree()

Employs the use of the UNIX "df" command to collect the number of free inodes
for the attached volume mount point. The value is cached and returned during
additional calls.
This method can be forced to ignore the cached value and collect a fresh value
by passing an argument of '-force'. In most cases the cached value is acceptable
due to the short runtime (program not a daemon).

  my $inodesfree = ($vol->inodesfree)->getProperty('inodesfree');


=item setoption()

Argument: option

Possible Options

=over 4

=item LOCK1

This is considered a *SOFT* lock because the filesystem is not truly locked
by this operation. It will be locked to further writes by the AC::Tier3 application
and any of its consumers. There are two locks. This allows for automated locks
based on application errors detected to block further writes as well as an
enabling an independent lock for administrative control. The existence of
one or both locks blocks all copy_in operations. The lock1 is expected to be used
by the application while lock2 (see below) for administrative use.

=item LOCK2

Complements lock1 by allowing two independent locks with comments. Both locks
must be removed to enable a copy-in. See lock1 for full details.

=item UNLOCK1

On success a lock1 is removed.

=item UNLOCK2

On success a lock2 is removed.

=item ONLINE

Marks the Tier3 volume online flag to true.

=item OFFLINE

Marks the Tier3 volume online flag to false.

=item ERRORS

Clears the Tier3 volume read/write error counters.

=back

=item isUnlocked()

Checks for lock files. Returns false on existence of any LOCK
file. See: lock1() and lock2() for details. A locked volume inhibits
the copy_in operation.

 my $unlocked = ($vol->isUnlocked)->isOkay;

=item remove(path,kbytes)

If the volume is online and writable and the path is (full path) on this volume
it is removed.  Kbytes is used to update the running free space for this volume.

 my $success = ($vol->remove($path,kbytes))->isOkay;

=item copy_out(source,destination)

The source should be a path on the assigned volume. The destination only
exists on copy_out success. Destination cannot preexist!

 my $success = ($vol->copy_out($src,$dest))->isOkay;

=item copy_in(source,destination,kbytes)

The destination should be a path on the assigned volume. The destination
cannot preexist! Kbytes is used to update the running free space on this
volume.

 my $success = ($vol->copy_in($src,$dest))->isOkay;

=item retire()

If this volume is empty and offline the volume is removed from the DB,
retired from service.

=item make_bucket(int)

Files must be stored in a b-tree fashion to avoid max-dir-size while
maximizing inodes for file utilization. The consumer *MUST* never make
changes to a volume directly. This method is used to create a bucket by
providing a single integer argument. The integer should be between
0-9999 to allow the number to be formatted internally as follows.

  $bucket_dir_name = sprintf("%04d", int($yourarg));
  mkdir "$this_volumes_volume_path/$bucket_dir_name";
  chmod 02770 "$this_volumes_volume_path/$bucket_dir_name";

  # an argument in($arg) == 17 will create folder
  #   /mount-point/volume/0017

=item query_bucket(int)

Queries the index bucket for the number of directory objects excluding(.|..)
and returns the number of objects (entries).

  my $bucket_use = Returned(1)->getProperty('object_count');

=item object_list_next()

Scans the volume for objects and returns the first 100
bucket/objects found. Each successive call returns another
100 bucket/objects. If there are less than 100 bucket/objects
then the list contains all objects on the volume. Scanned
buckets are removed if empty. The returned list will be empty
if the volume is offline or is empty.

=item sync()

Forces the volume to query its current free space and number of objects in the
currently selected bucket. The collected values are updated in the Tier3 DB.

=item initialize()

The initialize() method is used as part of the process to add a volume into
the Tier3 solution. The method post-processes the volumes meta data and updates
the object instance with actual volume facts.

=item initFinish()

This method update the Tier3 DB volume table with the facts collected by
the initialize() method.

=item meta_check()

The meta_check() method validates the volumes metadata and verifies the
volumes readyness. Its primary purpose is to test and report that the volumes
metadata (.../meta/README) is readable and that this volumes defined purpose
is as expected. it is important that a volumes path and its metadata are consistent.

=item fsck()

Performs a consistency check between this volume and the CLIP DB. Optional parameters
may be provided to change the behavior. By default all volume buckets are checked.
If the DB table FSCK_BUCKET exists then bucket check data is captured in this table
by volume/bucket. When a prior successful fsck() record for a bucket exists and the
record is not marked as changed the check is bypassed and the successful record data
and date ate reported. This behavior is expected to reduce load on the environment
by skipping unnecessary checking and provides the ability to obtain a report without
expensive checking. A check may be forced by passing the optional argument '--force'
with or without a bucket list. If bucket number(s) are provided the force option must
preseed them. The following examples illustrate a report showing the date of a prior successful
bucket fsck() and second bucket having been checked during this invocation.

  INFO - Checked 2674 Objects    0 faults [ /lts/arcendevl-t3-0003/0142/ ] 0.0 minutes - 2012-03-19
  INFO - Checked 2674 Objects    0 faults [ /lts/arcendevl-t3-0003/0143/ ] 0.0 minutes


=back

=head1 BUGS

None Known

=head1 SEE ALSO

 Property
 Returned

=cut

## END
