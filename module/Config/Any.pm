##
##  Module: Config::Any
##
##  Description:
##    A generic multi configuration module that stores configuration details
##    in a mySQL back-end and includes a local file based configuration backing
##    store to support mySQL outages (runtime continuity). The use of mySQL
##    can be disabled entirely however its use is recommended to support
##    remote configuration and control (common settings).
##
##  Author: Victor Burns
##    Date: 2013-11
##
##  Changes:
##    2013-11-19 VICB - Initial Version
##
##  PerlCritic: Passes level 3 - with pain
##    - fails to understand these are the same explicit vs. default and barks
##      at the explicit which I prefer!!!
##      my $self = shift(@_); # barks
##      my $self = shift;     # ok but I hate defaults!
##
##    - Complains about the use of die; but its okay when used properly
##      Had to use carp/croak just to shut it up! (provides no value!)
##
##    - Complains about error checking on try; an issue only when dealing
##      with objects; in no case of its use am I using objects so not a problem.
##      I shut perlcritic up by placing a dummy "if" around the try. (bugus)
##
##    - Complains about multiline strings; heredocs are often uglier!
##
##    - MY::Class->new() looks bogus compared to new MY::Class
##

package Config::Any;

use strict;
use warnings;
use Returned;
use Carp 'croak';
use Data::UUID;
use Data::Dumper;
use Sys::Hostname;
use Config::SimpleII;
use DBD::mysql;
use POSIX qw| :signal_h |;


##  Inherit from Returned Class
use base qw| Returned |;


##
## Module Properties
##

#-- Version
our $VERSION    = 1.0;

#-- Misc
our $S_CHANGED  = 0;
our $S_TARGET   = undef;
our $S_CLOSED   = 0;

#-- Identification
our $D_UUID     = undef;
our $D_TS       = undef;

#-- File Store
our $C_PATHNAME = undef;
our $C_SIMPLE   = undef;
our $C_COUNT    = 0;

#-- mySQL Store
our $M_CONN     = undef;
our $M_ENABLED  = 0;
our $M_TIMEOUT  = 3;
our $M_DSN      = undef;
our $M_SQL;


sub BEGIN
{
  $M_SQL->{'SQL_CREATE_TABLE'} = <<'SQL_CREATE_TABLE';
    CREATE TABLE IF NOT EXISTS ConfigAny (
      target varchar(48) NOT NULL,
      module varchar(48) NOT NULL,
      prop   varchar(48) NOT NULL,
      indx   int(4),
      valu   varchar(256),
      KEY `TARGET_IDX` (`target`),
      KEY `TARGET_PROP_IDX` (`target`,`module`,`prop`)
    ) ENGINE=MyISAM DEFAULT CHARSET=utf8
SQL_CREATE_TABLE

  $M_SQL->{'SQL_DELETE'} = <<'SQL_DELETE';
    DELETE FROM ConfigAny
      WHERE target = ?
        AND module = ?
        AND prop   = ?
SQL_DELETE

  $M_SQL->{'SQL_SELECT'} = <<'SQL_SELECT';
    SELECT * FROM ConfigAny
      WHERE target = ?
        AND module = ?
        AND prop   = ?
SQL_SELECT

  $M_SQL->{'SQL_SELECT_ALL'} = 'SELECT * FROM ConfigAny WHERE target = ?';

  $M_SQL->{'SQL_SELECT4UPDATE'} = <<'SQL_SELECT4UPDATE';
    SELECT * FROM ConfigAny
      WHERE target = ?
        AND module = ?
        AND prop   = ? FOR UPDATE
SQL_SELECT4UPDATE

  $M_SQL->{'SQL_UPDATE'} = <<'SQL_UPDATE';
    UPDATE ConfigAny
      SET valu=?
      WHERE target = ?
        AND module = ?
        AND prop   = ?
        AND indx IS NULL
SQL_UPDATE

  $M_SQL->{'SQL_INSERT'} = 'INSERT INTO ConfigAny VALUES(?,?,?,?,?)';

  $M_SQL->{'SQL_DROP_TABLE'} = 'DROP TABLE IF EXISTS ConfigAny';

  $M_SQL->{'SQL_PRUNE'} = 'DELETE FROM ConfigAny WHERE target = ?';

  return;
}


#-- Constructor
## (see POD)
sub new
{
  my $class = shift;
  my $self  = (ref $class || $class)->SUPER::new();

  #-- The module/block name our properties (this instance)
  #--  will be stored under (empty/undef == default/global)
  $self->module( shift );

  unless ( defined $C_SIMPLE )
  {
    #-- Load existing ini file OR start a new one
    $C_SIMPLE = ( defined $C_PATHNAME && -f $C_PATHNAME )
      ? Config::SimpleII->new( $C_PATHNAME )
      : Config::SimpleII->new( syntax => 'ini' );
  }

  #-- Unable to open Existing Configuration
  #--  (runing with configuration file disabled - in memory only)
  unless ( $C_SIMPLE )
  {
    $self->error_message("Unable to open ($C_PATHNAME) - " . $!);
    $C_SIMPLE = Config::SimpleII->new( syntax => 'ini' );
  }

  #-- Track number of CLASS Instances
  $C_COUNT++;

  #-- Configure / Check UUID
  $self->_InitUUID;

  return $self;
}


#-- called upon destruction of each instance
sub DESTROY
{
  #-- save only if changed && LAST reference is being DESTROY'ed

  --$C_COUNT;  # Instance Count

  #-- File SAVE
  if ( $C_SIMPLE && $C_COUNT==0 && $S_CHANGED )
  {
    $C_SIMPLE->param( 'TIMESTAMP', $D_TS );

    #-- write configuration file (write & rename)
    #--  this will keep us from destroying an existing ini
    #--  file if we have a permissions or low disk space issue.
    #--  (we dont want to write a partial or empty ini file)
    if ( $C_PATHNAME )
    {
      my $F_TEMP = $C_PATHNAME . '.tmp';

      if ( $C_SIMPLE->write( $F_TEMP ))
      {
        rename $F_TEMP, $C_PATHNAME;
      }
      else
      {
        unlink $F_TEMP if -f $F_TEMP;
        Returned->new->error_message("Unable to write ($C_PATHNAME) - " . $!);
      }
    }
    else
    {
      Returned->new->error_message("Unable to write configuration file; file is undefined.");
    }
  }

  #-- Clear to "start" status (no instances)
  $C_SIMPLE  = undef unless $C_COUNT;
  $S_CHANGED = 0     unless $C_COUNT;

  return;
}


#-- Set/Get Class properties (common to all instances)
## (see POD)
sub Pathname    { my $p = shift; $C_PATHNAME = $p if defined $p; return $C_PATHNAME; }
sub Target      { my $t = shift; $S_TARGET   = $t if defined $t; return $S_TARGET; }


#-- Used to start/create mySQL connection
## (see POD)
sub openDB
{
  my $dsn  = shift;
  my $timo = shift || $M_TIMEOUT;

  #-- Save the DSN; we can reuse it as needed for recovery
  #--  (we can recall this method without the argument)
  $M_DSN = $dsn if defined $dsn;

  #-- Without a Target OR DSN we can't use this service!
  return -1 unless defined $S_TARGET;
  return -1 unless defined $M_DSN;

  #-- Connect to DB if not already connected

  unless ( defined $M_CONN )
  {
    my $timer  = time;
    my $action = POSIX::SigAction->new(
        sub { croak "DB connect timeout" },
        POSIX::SigSet->new( SIGALRM )
    );
    my $oldaction = POSIX::SigAction->new();
    sigaction( SIGALRM, $action, $oldaction );

    1 if ( eval {
      eval {
        alarm( $timo );
        $M_CONN = DBI->connect( $M_DSN );
      };

      #-- Cancel alarm
      alarm(0);
      croak "$@";
    });

    sigaction( SIGALRM, $oldaction );

    #-- Oops failed to get a DB connection?
    unless ( $M_CONN )
    {
      $timer = time - $timer;
      chomp( $@ );
      Returned->new->debug_message((DBI::errstr() ? DBI::errstr() : $@)  . " (timeout=${timer} seconds)\n");
    }
  }

  #-- Create Required Table IF NOT EXISTS
  if ( $M_CONN )
  {
    $M_CONN->do( $M_SQL->{'SQL_CREATE_TABLE'});
    $M_ENABLED = 1;
  }

  #-- Configure / Check UUID
  Config::Any->new->_InitUUID;

  #-- No actual "Errors", handle things internally
  return $M_CONN ? 1 : -1;
}


#-- Used to stop mySQL connection
## (see POD)
sub closeDB
{
  my $rslt = 1;
  my $timo = shift || $M_TIMEOUT;

  if ( $M_CONN )
  {
    my $timer  = time;
    my $action = POSIX::SigAction->new(
        sub { croak "DB disconnect timeout" },
        POSIX::SigSet->new( SIGALRM )
    );
    my $oldaction = POSIX::SigAction->new();
    sigaction( SIGALRM, $action, $oldaction );

    1 if ( eval {
      eval {
        alarm( $timo );
        $rslt &&= $M_CONN->disconnect();
      };

      #-- Cancel alarm
      alarm(0);
      croak "$@";
    });

    sigaction( SIGALRM, $oldaction );

    $M_ENABLED = 0;
    $M_CONN    = undef;
    $timer     = time - $timer;

    unless ( $rslt == 1 )
    {
      Returned->new->debug_message((DBI::errstr() ? DBI::errstr() : $@)  . " (timeout=${timer} seconds - $rslt)\n");
      $rslt = -1;
    }
  }

  return $rslt;
}


#-- DROP Configuration Testing table
## (see POD)
sub DropTable
{
  #-- Used During Testing Only
  #-- Not typically useful in an application
  #-- In an application we'd like our configuration to be persistent
  return $M_CONN ? $M_CONN->do( $M_SQL->{'SQL_DROP_TABLE'} ) : 1;
}


#-- Stores, updates, returns a configuration parameter
## (This method is our sole purpose for existing)
## (see POD)
sub param
{
  my $self = shift;
  my $prop = shift;
  my $valu = shift;
  my $rslt;

  #-- We're making a change?
  #--  then timestamp it
  $S_CHANGED  ||= defined $valu;
  $D_TS = time if defined $valu;

  $rslt = defined $valu
    ? $self->_putProperty( $prop, $valu )
    : $self->_getProperty( $prop, $valu );

  return $rslt;
}


#-- Performs housekeeping, maintinance and recovery
## (see POD)
sub run
{
  #-- TODO: implement the recovery and hosekeeping
  ## Posibilities:
  ##   - No changes made in over 10 minutes disconnect from Database
  ##   - Disconnected for 4 hours and have changes to save; reconnect
  ##      and resync.
  ##   - ??
  ##   - Will not be pruning LOGS; log module will handle that
  return;
}


#-- Instance Properties
## (see POD)
sub module
{
  my( $self, $prop ) = (shift,shift);

  return $self->_setget('_MODULE_____', $prop);
}


#--
#-- (private methods)
#--

##
## Method (internal): $self->_putProperty( $prop, $valu );
##   Called internally to update both mySQL and conf-file
##   storage solutions.
##
##  Two arguments, boolean result code.
##
sub _putProperty
{
  my $self = shift;
  my $prop = shift;
  my $valu = shift;
  my $modu = $self->module ? $self->module . '.' : '';
  my $rSQL = 1;
  my $rFIL = 1;

  #-- Save property/value to MySQL & configuration-file
  $rSQL = _saveMySQL( $self->module ? $self->module : '__DEFAULT__', $prop, $valu );
  $rFIL = $C_SIMPLE ? $C_SIMPLE->param( $modu . $prop, $valu ) : undef;

  #-- Store Timestamp
  _saveMySQL( '__DEFAULT__', 'TIMESTAMP', $D_TS );
  $C_SIMPLE || $C_SIMPLE->param( 'TIMESTAMP', $D_TS );

  return( $rSQL && $rFIL );
}


##
## Method (internal): _saveSQL( $module, $prop, $value )
##   Called internally to save a property/value pair to mySQL.
##
##  Three arguments, always returns true
##
sub _saveMySQL
{
  my $modu = shift;
  my $prop = shift;
  my $valu = shift;
  my $rslt = 1;

  return $rslt unless $M_ENABLED;
  return $rslt unless $S_TARGET;

  #-- Perform MySQL Action
  my $sth = $M_CONN->prepare( $M_SQL->{'SQL_SELECT4UPDATE'} );
  my $ste = _timed_sql_execute( $sth, [ $S_TARGET, $modu ? $modu : 'NULL', $prop ], 'SELECT FOR UPDATE' );

  return $rslt unless $M_ENABLED;

# Returned->new->debug_message( sprintf "ret(%s), rows(%d), flds(%d)\n", $ste, $sth->rows, $sth->{'NUM_OF_FIELDS'} );

  UPDATE_METHOD:
  {
    my $rows = $sth->rows;

    #-- Single Row (use UPDATE)

    if ( $rows == 1 )
    {
      my $aref = $sth->fetchrow_hashref;
      my $sthu;

      #-- No update to be made (no difference)
      last UPDATE_METHOD if ( defined $aref->{'valu'} && $valu eq $aref->{'valu'} );

      $sthu = $M_CONN->prepare( $M_SQL->{'SQL_UPDATE'} );
      $ste  = _timed_sql_execute( $sthu, [ $valu, $S_TARGET, $modu, $prop ], 'UDPATE' );
      last UPDATE_METHOD;
    }

    #-- Multi Rows (use DELETE,INSERT)
    #--  (simpifies updating - performance is not a concern)

    if ( $rows )
    {
      $sth = $M_CONN->prepare( $M_SQL->{'SQL_DELETE'} );
      $ste = _timed_sql_execute( $sth, [ $S_TARGET, $modu, $prop ], 'DELETE' );
    }

    #-- No Row(s) OR we just deleted
    #--  (use INSERT)

    $sth = $M_CONN->prepare( $M_SQL->{'SQL_INSERT'} );

    if ( ref $valu eq 'ARRAY' )
    {
      my $indx = 0;

      foreach my $itm ( @$valu )
      {
        $ste = _timed_sql_execute( $sth, [ $S_TARGET, $modu, $prop, $indx++, $itm ], 'INSERT' );
      }

      last UPDATE_METHOD;
    }

    #-- Single ROW
    $ste = _timed_sql_execute( $sth, [ $S_TARGET, $modu, $prop, undef, $valu ], 'INSERT' );
  }

  if ( defined $sth )
  {
    $sth->finish;
    $sth = undef;
  }

  return $rslt;
}


##
## Method (internal): $self->_getProperty( $prop );
##   Called internally to retrieve a value of a saved property.
##   Tries mySQL first and then falls back to local conf-file.
##
##  One parameter, returns property's value OR undef
##
sub _getProperty
{
  my $self = shift;
  my $prop = shift;
  my $modu = $self->module ? $self->module . '.' : '';
  my $rslt = 1;

  $rslt   = _readMySQL( $self->module ? $self->module : '__DEFAULT__', $prop );
  $rslt ||= $C_SIMPLE ? $C_SIMPLE->param( $modu . $prop ) : undef;

  return $rslt;
}


##
## Method (internal): _readMySQL( $module, $property );
##   Called internally to retrieve the value of a save configuration
##   property.
##
##  Two arguments, returns property value OR undef
##
sub _readMySQL
{
  my $modu = shift;
  my $prop = shift;
  my $rslt = 1;
  my $errs = 0;

  #-- Return if mySQL not enabled
  return unless $M_ENABLED;

  #-- SELECT the Config Property(s)
  my $sth = $M_CONN->prepare( $M_SQL->{'SQL_SELECT'} );
  my $ste = _timed_sql_execute( $sth, [ $S_TARGET, $modu ? $modu : 'NULL', $prop ], 'SELECT' );

  $errs++ unless $ste;

# Returned->new->debug_message( sprintf "ret(%s), rows(%d), flds(%d)\n", $ste, $sth->rows, $sth->{'NUM_OF_FIELDS'} );

  return unless $sth;
  return unless $sth->rows;

  $rslt = [];

  while ( my $aref = $sth->fetchrow_hashref )
  {
    #-- Return just the one row
    #-- Place multi rows on array ref
    ( $sth->rows == 1 )
      ? $rslt = $rslt->[0]
      : $rslt->[$aref->{'indx'}] = $aref->{'valu'};
  }

  #-- No rows
  $rslt = undef if ref $rslt eq 'ARRAY' && scalar @$rslt == 0;

  return $rslt;
}


##
## Method (internal): _InitUUID()
##   Called internally to retrieve / set our configuration UUID
##
## Has no arguments, has no return value.
##
sub _InitUUID
{
  my $self = shift;

  #-- Collect known UUID from MySQL && Conf-File (if ANY)
  my $uuid_mySQL = _readMySQL( '__DEFAULT__', 'UUID' );
  my $uuid_cfile = $C_SIMPLE ? $C_SIMPLE->param( 'UUID' ) : undef;


  SETUP_UUID:
  {
    #-- UUID Set and matches
    if ( defined $uuid_mySQL && defined $uuid_cfile && $uuid_cfile eq $uuid_mySQL )
    {
      $D_UUID = $uuid_mySQL unless defined $D_UUID;
      last SETUP_UUID;
    }

    #-- UUID Known But no cfile
    if ( defined $uuid_cfile && ! $C_SIMPLE )
    {
      $D_UUID = $uuid_mySQL unless defined $D_UUID;
      last SETUP_UUID;
    }

    #-- UUID Known But no mySQL
    if ( defined $uuid_cfile && ! $M_ENABLED )
    {
      $D_UUID = $uuid_cfile unless defined $D_UUID;
      last SETUP_UUID;
    }

    #-- UUID Does not Match! (This is Ugly)
    #-- (should not be possible)
    if ( defined $uuid_mySQL && defined $uuid_cfile && $uuid_cfile ne $uuid_mySQL )
    {
      $D_UUID = $uuid_mySQL unless defined $D_UUID;
      $self->error_message("UUID Mismatch cfile(${uuid_cfile})\n");
      $self->error_message("UUID Mismatch mySQL(${uuid_mySQL})\n");
      last SETUP_UUID;
    }

    #-- Create UUID
    #-- (Based on hostname which should be unique and predictable)
    $D_UUID = Data::UUID->new->create_from_name_str( NameSpace_DNS, hostname());
  }

  #-- ensure sync
  $self->_ensureSynced;

  return;
}


##
## Method (internal): _ensureSynced()
##   Called internally Sync storage types as needed
##
## Has no arguments, has no return value.
##
sub _ensureSynced
{
  my $self = shift;

  #-- Ensure We're synced
  #--  Note: $S_CLOSED indicates mysql was turned off on error
  #--  (Force re-sync)
  my $ts_mysql = _readMySQL( '__DEFAULT__', 'TIMESTAMP' );
  my $ts_cfile = $C_SIMPLE ? $C_SIMPLE->param( 'TIMESTAMP' ) : undef;

  if (( defined $ts_mysql && defined $ts_cfile && $ts_mysql <=> $ts_cfile ) || $S_CLOSED )
  {
    $ts_mysql = 0 unless $ts_mysql;
    $ts_cfile = 0 unless $ts_cfile;

    #-- The source with the newest Timestamp wins!
    #--   (in principle that is ...)
    $ts_mysql > $ts_cfile ? _sync2cfile() : _sync2mysql();

  # $self->debug_message("Storage Types out of sync\n");
    $self->debug_message(sprintf "mysql ->> %s\n", scalar localtime $ts_mysql );
    $self->debug_message(sprintf "cfile ->> %s\n", scalar localtime $ts_cfile );
  }

  #-- Rubber Stamp the UUID
  _saveMySQL( '__DEFAULT__', 'UUID', $D_UUID );
  $C_SIMPLE && $C_SIMPLE->param( 'UUID', $D_UUID );

  return;
}


##
## Method (internal): _timed_sql_execute( $prepared, [ args, ... ], 'purpose msg', $timeout )
##   Called internally to perform a prepared SQL statement. It is wrapped with
##   a timer in case of issues. We'll pick up the pieces when we establish a
##   new connection at a future time.
##
##  Four arguments, last optional, returns the return code of the $SQL->execute(@vals)
##
sub _timed_sql_execute
{
  my $sqlh = shift; # A "prepared" handle
  my $vals = shift; # ArrayRef items to execute
  my $emsg = shift; # Description of our action
  my $timo = shift || $M_TIMEOUT;
  my $ste;

  #-- Try SQL Action
  TRY_SQL:
  {
    my $timer  = time;
    my $action = POSIX::SigAction->new(
        sub { croak "DB operation timeout (${emsg})" },
        POSIX::SigSet->new( SIGALRM )
    );
    my $oldaction = POSIX::SigAction->new();
    sigaction( SIGALRM, $action, $oldaction );

    1 if ( eval {
      eval {
        alarm( $timo );
        $ste = $sqlh->execute( @$vals );
      };

      #-- Cancel alarm
      alarm(0);
      croak "$@";
    });

    sigaction( SIGALRM, $oldaction );
    $timer = time - $timer;

    last TRY_SQL if ( defined $sqlh && defined $ste );

    chomp( $@ );
    Returned->new->debug_message((DBI::errstr() ? DBI::errstr() : $@)  . " (timeout=${timer} seconds)\n");

    #-- On error stop using this resource
    #-- Reconnect again later, mark the CLOSED flag to indicate it was working.
    closeDB();
    $S_CLOSED = 1;
  }  

  return $ste;
}


##
## Method (internal): _sync2mysql()
##   Called internally to update mySQL records using local file
##   when local file has newer timestamp, assumed to mean we
##   were operating on local file while mysql was having issues.
##
## Has no arguments, has no return value.
##
sub _sync2mysql
{
  #-- Return if mySQL || conf-file not enabled
  return unless $M_ENABLED;
  return unless $C_SIMPLE;

  Returned->new->debug_message("Resyncing remote MySQL\n");

  #-- Prune from mySQL
  my $sth = $M_CONN->prepare( $M_SQL->{ 'SQL_PRUNE' } );
  my $ste = _timed_sql_execute( $sth, [ $S_TARGET ], 'PRUNE ALL' );


  #-- Insert From File
  return unless $M_ENABLED;
  return unless $C_SIMPLE;

  my $cfile = { $C_SIMPLE->vars() };

  foreach my $itm ( keys %$cfile )
  {
    my( $module, $prop ) = split '[.]', $itm, 2;
    $module = '__DEFAULT__' if $module eq 'default';
    _saveMySQL( $module, $prop, $cfile->{$itm} );
  }

  # No longer Closed
  $S_CLOSED = 0 if $M_ENABLED && $C_SIMPLE;

  return;
}


##
## Method (internal): _sync2cfile()
##   Called internally to update Conf-File records using mySQL
##   when local file has older timestamp, assumed to mean we
##   were operating on mySQL while Conf-File was having issues.
##
## Has no arguments, has no return value.
##
sub _sync2cfile
{
  #-- Return if mySQL || conf-file not enabled
  return unless $M_ENABLED;
  return unless $C_SIMPLE;

  Returned->new->debug_message("Resyncing local Conf-File\n");

  #-- Get Data From MySQL
  my $sth = $M_CONN->prepare( $M_SQL->{ 'SQL_SELECT_ALL' } );
  my $ste = _timed_sql_execute( $sth, [ $S_TARGET ], 'SELECT ALL' );

  my $data = {};

  while ( my $row = $sth->fetchrow_hashref )
  {
    my $modu = $row->{'module'} eq '__DEFAULT__' ? 'default.' : $row->{'module'} . '.';

    if ( defined $row->{ 'indx' } )
    {
      ${$data->{$modu . $row->{prop}}}[$row->{'indx'}] = $row->{'valu'};
    }
    else
    {
      $data->{$modu . $row->{prop}} = $row->{'valu'};
    }
  }

  #-- Did we have an oops getting the data from mySQL?
  return unless $M_ENABLED;

  #-- Update Conf File (delete/add)
  my $cfile = { $C_SIMPLE->vars() };

  foreach my $prop ( keys %$cfile )
  {
    $C_SIMPLE->delete( $prop );
  }

  foreach my $prop (keys %$data )
  {
    $C_SIMPLE->param( $prop, $data->{$prop} );
  }

  #-- File SAVE
  if ( $C_SIMPLE )
  {
    $C_SIMPLE->param( 'TIMESTAMP', $D_TS );

    #-- write configuration file (write & rename)
    #--  this will keep us from destroying an existing ini
    #--  file if we have a permissions or low disk space issue.
    if ( $C_PATHNAME )
    {
      my $F_TEMP = $C_PATHNAME . '.tmp';

      if ( $C_SIMPLE->write( $F_TEMP ))
      {
        rename $F_TEMP, $C_PATHNAME;
      }
      else
      {
        unlink $F_TEMP if -f $F_TEMP;
        Returned->new->error_message("Unable to write ($C_PATHNAME) - " . $!);
      }
    }
    else
    {
      Returned->new->error_message("Unable to write configuration file; file is undefined.");
    }
  }

  # No longer Closed
  $S_CLOSED = 0 if $M_ENABLED && $C_SIMPLE;

  return;
}


1;

__END__


##
##  Documentation: POD
##

=pod

=head1 NAME

Configure::Any

=over 4

Flexible yet simple configuration settings manager with redundant storage sources.

=back

=head1 SYNOPSIS

The Config::Any class provides resilient configuration storage and retrieval abstraction for
a consumer application by providing dual storage, one remote and one local.

=head1 VERSION

1.0

=head1 DESCRIPTION

This configuration mangement module (properties storage) is used to store and retrieve property/value
pairs based on groups in two storage medium for redundancy and resiliency. So long as just one is
available at all times this should go unnoticed by consumer modules. The module automatcically handles
the updating and syncing of storage types when out of sync. As an example if the MySQl service becomes
out of service while propertites have been updated the mySQL storage will be updated when its service
is restored. The same is true if an external source updates the MySQl settings the module detects and
updates the local storage. Any time a not-in-sync condition is detected regardless of cause the module
updates the out of sync storage.

=head1 STORAGE TYPES

=over 4

=item mySQL - (Remote)

Recommended to be used with a remote MySQL server.

=item Configuration File - (local)

Maintains a local "file" based copy.

=back

=head1 USAGE & EXAMPLES

=over 4

 #-- Be good to our self
 use strict;
 use warnings;
 use Config::Any;
 use Sys::Hostname;
 
 #-- Prime the Configuration pump!
 Config::Any::Pathname('/opt/app/XYX/etc/configuration.ini');
 Config::Any::Target( hostname ); # Sys::Hostname
 Config::Any::openDB('DBI:mysql:database=test;host=localhost;port=3306');
 
 #-- We have more than one module/instance
 my $conf1 = Config::Any->new('Private::Module::Fudge');
 my $conf2 = Config::Any->new('Private::Module::Factor');

 $conf1->param('Monkey','See');
 $conf2->param('Monkey','Do');
 
 if ( $conf1->param('Monkey') ne $conf2->param('Monkey'))
 {
   print "That's Correct these are not the same Property!\n";
   print "They are in two different modules (configuration blocks)\n";
 }
 

=back

=head1 SUBROUTINES AND METHODS

=over 4

=item Pathname()

This CLASS level method sets the pathname of the configuration file used for local storage.
It is essential that the path be Set before an instance of this CLASS is created. Not setting
this property basically disables local configuration file storage; however the memory storage
of saved propertied since run time start can be retrieved but will not be persistent. When
called without an argument the current value is returned.

Config::Any::Pathname('/my/path/app.ini');

=item Target()

This CLASS level method sets the TARGET property used to identify all properties stored as
a whole in the mySQL DB. If not set MySQL will not be enabled. When called without an argument
the current value is returned which will be undef if not set. While the value could be any
unique string for this application below are some recommendations.

  Config::Any::Target('hostname.fqdn');

  Recommended Use:

  use strict;
  use warnings;
  use Config::Any;
  use Data::UUID;
  use Sys::Hostname;
 
  Config::Any::Target(( Data::UUID->new )->create_from_name_str( NameSpace_DNS, hostname));

=item openDB()

This CLASS level method opens/establishes a mySQL server connection for providing a
persistent remote configuration storage. If not called the mySQL storage is not enabled.
When called a mySQL DSN string should be passed with all required augments to connect
to the server. Once called with a valid DSN it may be called again to reestablish a
connection using the same saved DSN.

Note: See DBD::mysql for details on a valid DSN.

Config::Any::openDB($DSN);

=item closeDB()

This CLASS level method closes/disconnects from an established mySQL server.

Config::Any::closeDB();

=item DropTable()

NOTE: for Testing only!!!

This method should not be used by a consumer application. Dropping the mySQL TABLE
housing the configuration data will cause *all* data to be lost not just that of
this system/application. In a real scenario N hosts running the same application
would share the same table but not their configuration.

=item run()

This CLASS method is called periodically by the applications main loop. This method
will check the status of the module, correct issues, collect statistics etc. Think of
it as a pump putting life into the module. Calling this method is optional and
primarily useful only on long running or daemon applications. This method facilitates
the auto recovery features of the module.

=item new()

This is the CLASS instance constructor. Each instance share the same backing storage but
is contained within its own unique "Module / Block" which can be most any string that
contains alphanumeric and colons. No other characters are recommended use and "test"
other characters for compatability.  The recommendation is to use the name of the
application OR the unique module name such as MY::Module::Zap which will group it's
settings together. The use of no block / module name create a constructor that accesses
the "default" group of properties. The main application could use this space if it wishes.

my $config = new Config::Any('My::Class');

OR

my $conf_default = new Config::Any;

=item module()

Sets or returns the module name used to group a modules properties together. However it is
recommended to pass the module name via the constructor as illustrated above. This method can be used
to retrieve the current module name for this instance.

my $module = $config->module;

=item param()

This is the action method used to retrieve and store configuration properties
and their values.

 my $stat = $config->param('PropertyX', 'MyValue'); # Store
 my $data = $config->param('PropertyX');            # Read

=back

=head1 DIAGNOSTICS

See: Test code for this module (in separate file)

=head1 CONFIGURATION AND ENVIRONMENT

N/A

=head1 DEPENDENCIES

Config::SimpleII;
Data::Dumper;
Data::UUID;
DBD::mysql;
Returned;
Property

=head1 INCOMPATIBILITIES

None known

=head1 AUTHOR

Victor M. Burns (ancient.wizard@verizon.net)

=head1 BUGS AND LIMITATIONS

None Known

=head1 SEE ALSO

Property, Returned, Config::SimpleII, DBD::mysql

=head1 LICENSE AND COPYRIGHT

The "Artistic License"

URL http://dev.perl.org/licenses/artistic.html

=head1 TO-DO

- Logging module not created, integrate when available

- Metrics module not created, integrate when available
  (start collecting metrics now)

- Add run() method to provide timmer based activities
  (auto recovery and house keeping activities)

- Add testing for resilience abilities

=cut

## END
