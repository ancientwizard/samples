#!/usr/local/bin/perl -w

## zonetool.pl -- Solaris Zone Creation Automation Tool.
##
##  Description:
##
##   When used within its ability this tool will build a fully functioning
##   and running zone from scratch thereby saving many manual steps required
##   to produce the same results.
##
##   This tool outputs three files in /tmp/. See the code for their exact names.
##     file1   - custom shell script that does the actual zone building
##     file2   - zonecfg input file that describes the zone being created.
##     file3   - sysidcfg file placed in the zones /etc directory to help
##               the new zone self (sysconfig) configure during its first boot.
##
##  Example: (See POD for *FULL* information)
##   ./zonetool [ -debug ] -c -z zone01 -h zone01.your.dom  \
##     -n 'ce0=192.168.29.2/23,ce1=192.168.21.2/23' -p /zones \
##     -a [ true | false ] -i '/opt,/zpools/tools' \
##     -f '/export/home,/export/disk0' -t US/Central \
##     -r timeserver -s 'name_service=NONE'
##
##  Author: Victor Burns
##    Date: 2007-March
##
##  Releases: (External)
##    2009-Jan-19  (VICB) - Sent to Linux Journal by permission. May be used for any
##                          purpose as long as user takes full responsibility.
##
##  Changes:
##    2010-Feb-08  (VICB) - Added zone-level resource control options (Container)
##                          --memory  physical,locked,swap
##                          --cpu     num-cpu,cpu-shares,scheduling-class
##
##    2010-Feb-08  (VICB) - Added -m copy for use with --clone. The clone will make a copy.
##
##    2010-Jan-28  (VICB) - Added command line option to set the root password.
##                          (Must be encrypted already - to avoid security issues!!!)
##
##    2009-Jul-29  (VICB) - Added support for physical (exclusive) NIC
##                          (the default is shared)
##
##    2009-Jul-29  (VICB) - Corrected bug: when a networkless zone was created
##                          the host name was ignored.
##
##    2008-Dec-10  (VICB) - Corrected problem with defining more than one IP for
##                          the same physical interface.
##
##    2008-Oct-13  (VICB) - Added support for zone clone option
##
##    2008-Aug-28  (VICB) - Added ability to define sysidcfg file
##                          name_service option.
##
##    2007-Nov-29  (VICB) - Misc editing of header and POD etc.
##

use strict;
use Carp;
use Getopt::Long;
use Data::Dumper;

my $opts = {};

GetOptions(
  ## Create
    'c'			=> \$opts->{create},
    'create'		=> \$opts->{create},

  ## Delete
    'd'			=> \$opts->{delete},
    'delete'		=> \$opts->{delete},

  ## zonename
    'z=s'		=> \$opts->{zonename},
    'zonename=s'	=> \$opts->{zonename},

  ## BrandZ
    'b=s'		=> \$opts->{brand},
    'brand=s'		=> \$opts->{brand},

  ## Clone
    'e=s'		=> \$opts->{clone},
    'clone=s'		=> \$opts->{clone},

  ## Solaris container (memory)
    'memory=s'		=> \$opts->{t_memory},

  ## Solaris container (cpu)
    'cpu=s'		=> \$opts->{t_cpu},

  ## Media
    'm=s'		=> \$opts->{media},
    'media=s'		=> \$opts->{media},

  ## Hostname
    'h=s'		=> \$opts->{hostname},
    'hostname=s'	=> \$opts->{hostname},

  ## zone path
    'p=s'		=> \$opts->{zonepath},
    'zonepath=s'	=> \$opts->{zonepath},

  ## Autoboot [ true | false ]
    'a=s'		=> \$opts->{autoboot},
    'autoboot=s'	=> \$opts->{autoboot},

  ## Networks
    'n=s'		=> \$opts->{network},
    'network=s'		=> \$opts->{network},

  ## Interface type (shared | exclusive)
    'k=s'		=> \$opts->{iptype},
    'iptype=s'		=> \$opts->{iptype},

  ## inherit-pkg-dir
    'i=s'		=> \$opts->{inherit},
    'inherit=s'		=> \$opts->{inherit},

  ## fs
    'f=s'		=> \$opts->{fs},
    'filesystem=s'	=> \$opts->{fs},

  ## Timezone
    't=s'		=> \$opts->{timezone},
    'timezone=s'	=> \$opts->{timezone},

  ## Time server
    'r=s'		=> \$opts->{timeserv},
    'timeserv=s'	=> \$opts->{timeserv},

  ## Name Service
    's=s'		=> \$opts->{nameserv},
    'nameserv=s'	=> \$opts->{nameserv},

  ## Root Account Password
    'rootpassword=s'	=> \$opts->{rootpw},
    'rootpw=s'		=> \$opts->{rootpw},

  ## Debug
    'debug'		=> \$opts->{debug},

  ## Help
    'help'		=> \$opts->{help}
);

###############################################################################
###  HELP
###############################################################################

my @opts = grep(defined $_, values %$opts );
if( defined $opts->{help} and $opts->{help} or scalar @opts == 0 )
{
  system("perldoc $0");
  exit 0;
}


###############################################################################
###  Collect Definition
###############################################################################

  my $zone = Solaris::zone->new( $opts->{zonename} );

  $zone->clone   ( $opts->{clone}    )  if defined $opts->{clone};
  $zone->brand   ( $opts->{brand}    )  if defined $opts->{brand};
  $zone->media   ( $opts->{media}    )  if defined $opts->{media};
  $zone->hostname( $opts->{hostname} )	if defined $opts->{hostname};
  $zone->zonepath( '/zones'          ); ## Default
  $zone->zonepath( $opts->{zonepath} )	if defined $opts->{zonepath};
  $zone->autoboot( $opts->{autoboot} )	if defined $opts->{autoboot};
  $zone->network ( $opts->{network}  )	if defined $opts->{network};
  $zone->inherit ( $opts->{inherit}  )	if defined $opts->{inherit};
  $zone->paths   ( $opts->{fs}       )	if defined $opts->{fs};
  $zone->timezone( $opts->{timezone} )	if defined $opts->{timezone};
  $zone->timeserv( $opts->{timeserv} )	if defined $opts->{timeserv};
  $zone->nameserv( $opts->{nameserv} )  if defined $opts->{nameserv};
  $zone->iptype  ( $opts->{iptype}   )  if defined $opts->{iptype};
  $zone->password( $opts->{rootpw}   )  if defined $opts->{rootpw};
  $zone->memory  ( $opts->{t_memory} )  if defined $opts->{t_memory};
  $zone->cpu     ( $opts->{t_cpu}    )  if defined $opts->{t_cpu};

  unless( defined $zone->timezone )
  {
    print " WARN -- A timezone was not defined or could not be discovered.\n";
    print "         aborting run\n";
    exit 0;
  }


###############################################################################
###  Misc Vars
###############################################################################

my $line="";		# Used for file enum
my $pid=$$;		# Processid (used for uniq tmp files)


###############################################################################
###	CREATE 
###############################################################################

if( defined $opts->{create} and $opts->{create} )
{
  my $zname         = $zone->zonename;
  my $media         = $zone->media;
  my $cluster       = $zone->cluster;
  my $temp_zone_def = "/tmp/${zname}.cfg";
  my $temp_sysidcfg = "/tmp/${zname}.sysidcfg";
  my $temp_build    = "/tmp/zcrea.$pid";
  my $ZCF;

  # Option sanity check
  ##################################################

  # Non Native zone creation must provide installation media
  #  or clone from existing installed zone
  if( defined $zone->clone and $zone->media and 'copy' ne lc($zone->media))
  {
    print " ERR  -- Clone operation selected and media path defined. Could not\n";
    print "         determine proper installation type. Clone and media options\n";
    print "         are exclusive. Aborting run.\n";
    exit 0;
  }

  if( ! $zone->is_native && ! ( defined $zone->media || defined $zone->clone )||
      ! $zone->is_native &&   defined $zone->media && ! -d $zone->media )
  {
    printf("\n");
    print("  Option error: Creation and Installation of Non Native BrandZ zones\n");
    print("    require installation media. Please define the path of the ISO\n");
    print("    installation media of a supported brand or use the clone option.\n");
    print("\n");
    exit(1);
  }

  # Collect Root password if we dont have one
  ##################################################

  unless( defined $zone->password )
  {
    my @SHADOW=();	# Elements of the root shadow entry
    my $SHAD;

    if( open $SHAD, '<', '/etc/shadow' )
    {
      while($line = <$SHAD>)
      {
        if ($line =~ /^root:/)
        {
          @SHADOW = split(/:/,$line);
          last;
        }
      }

      close($SHAD);
    }
    else
    {
      print(" WARN - Could not get root's encrypted passwd to place in non-global zone\n");
      print("        using [ changeme ] as the password.");

      @SHADOW = ( '', 'ir9Ru048IlDPs' );
    }

    $zone->password( $SHADOW[1] );
  }


  # Create the zone config file
  ##################################################

  if( open $ZCF, '>',  ${temp_zone_def} )
  {
    my $zconfig = $zone->zone_definition;

    foreach my $l ( @$zconfig )
    {
      printf( $ZCF "%s\n", $l );
    }
    close( $ZCF );
  }


  # Create the sysidcfg 
  ##################################################

  if( $zone->is_native and open( $ZCF, '>', ${temp_sysidcfg} ))
  {
    my $sysidcfg = $zone->sysidcfg;

    foreach my $line ( @$sysidcfg )
    {
      printf( $ZCF "%s\n", $line );
    }
    close( $ZCF );
  }


  # Script Build
  ##################################################

  if( open $ZCF, '>', ${temp_build} )
  {
    my $zoneroot = $zone->zonepath . '/' . $zname;

    printf( $ZCF "#!/bin/ksh\n");

    printf( $ZCF "# Define the zone\n" );
    printf( $ZCF "echo \"(/usr/sbin/zonecfg -z %s -f %s)\"\n", $zname, $temp_zone_def );
    printf( $ZCF "       /usr/sbin/zonecfg -z %s -f %s\n",     $zname, $temp_zone_def );
    printf( $ZCF "\n" );

    my $install_t = 'install';

    if( $zone->clone )
    {
      my $clone_copy = '';

      print " INFO - The defined source zone clone was not verified. Cloning will\n";
      print "        fail unless the source zone is in the \"installed\" state.\n";

      $clone_copy = '-m copy ' if defined $zone->media and 'copy' eq lc($zone->media);
      $install_t = sprintf("clone %s%s", $clone_copy, $zone->clone );
    }

    if( $zone->is_native )
    {
      printf( $ZCF "# Install/Build the zone\n" );
      printf( $ZCF "echo \"(/usr/sbin/zoneadm -z %s %s)\"\n", $zname, $install_t );
      printf( $ZCF "       /usr/sbin/zoneadm -z %s %s\n",     $zname, $install_t );
      printf( $ZCF "\n" );

      printf( $ZCF "# Prep the zone before first boot\n" );
      printf( $ZCF "/bin/cp %s %s/root/etc/sysidcfg\n", $temp_sysidcfg, $zoneroot );
      printf( $ZCF "/bin/touch %s/root/etc/.NFS4inst_state.domain\n",   $zoneroot );
#     printf( $ZCF "/bin/ls -al %s %s/root/etc/sysidcfg\n", $temp_sysidcfg, $zoneroot );
      printf( $ZCF "\n" );
    }
    else
    {
      $cluster = ''             unless( defined $cluster );
      $cluster = ' ' . $cluster unless( length( $cluster ) == 0 );
      if( $zone->clone )
      {
        $install_t = sprintf("clone %s", $zone->clone );
      }
      else
      {
        $install_t = sprintf("install -d %s%s", $media, $cluster );
      }
      printf( $ZCF "# Install/Build the zone\n" );
      printf( $ZCF "echo \"(/usr/sbin/zoneadm -z %s %s)\"\n", $zname, $install_t );
      printf( $ZCF "       /usr/sbin/zoneadm -z %s %s\n",     $zname, $install_t );
      printf( $ZCF "\n" );
    }

    printf( $ZCF "# Boot the zone\n" );
    printf( $ZCF "echo \"(/usr/sbin/zoneadm -z %s boot)\"\n", $zname );
    printf( $ZCF "       /usr/sbin/zoneadm -z %s boot\n",     $zname );

    close( $ZCF );

    if( defined $opts->{debug} )
    {
      print "\n";
      print "INFO -- Debug mode\n";
      print "\n";
      print "The following script would have been executed using the data that follows.\n";
      print "# -- $temp_build\n";
      system("cat $temp_build");
      print "\n";

      print "# -- $temp_zone_def\n";
      system("cat $temp_zone_def");
      print "\n";

      if( $zone->is_native )
      {
        print "# -- $temp_sysidcfg\n";
        system("cat $temp_sysidcfg");
        print "\n";
      }
    }
    else
    {
      system("sh  $temp_build");
    }
  }

  unlink $temp_zone_def if -f $temp_zone_def;
  unlink $temp_sysidcfg if -f $temp_sysidcfg;
  unlink $temp_build    if -f $temp_build;

  exit 0;
}


###############################################################################
###	DELETE
###############################################################################

if( defined $opts->{delete} and $opts->{delete} )
{
  printf "Delete operation not supported - remove it yourself\n";
  exit 0;
}


###############################################################################
###  No valid option provided
###############################################################################

printf "No valid operation selected. (exiting)\n";

exit 0;


## Packages

##
## PACKAGE Property( )
##
##  Implements a simple property Object.
##  Any unique property may be saved or restored
##  using the set and get methods. All properties
##  are stored under the {PROPS} hash.
##
## Other classes should inherit property behaviors
##  from this class.
##

package Property;

use Carp;

##
##  new( )
##
##  Create empty set of properties
##
##  post: result = set{ }
##

sub new
{
  my $package = shift(@_);
  my $self    = { };

  $self->{PROPS} = { };

  bless( $self, $package );
  return( $self );
}

sub DESTROY { }


##
##  getPropertyList( )
##  getPropertyListSorted( )
##
##  Create and return a sequence (array) of property
##   names.
##
##  post: result == sequence{ properties }
##

sub getPropertyList
{
  my $self = shift(@_);

  return( [ keys %{$self->{PROPS}} ] );
}

sub getPropertyListSorted
{
  my $self = shift(@_);

  return( [ sort keys %{$self->{PROPS}} ] );
}


##
##  getProperty( $prop )
##
##  Return the value of a given property.
##
##  post: result == if set->includes( $prop ) then value
##                  else undef
##

sub getProperty
{
  my $self = shift(@_);
  my $prop = shift(@_);

  return( defined $self->{PROPS}{$prop} ? $self->{PROPS}{$prop} : undef );
}


##
##  setProperty( $prop, $valu )
##
##  Save the property and value pair. Existing matching
##   property is replaced with new value.
##
##  pre:  $prop defined
##  post: set->including( $prop => $valu )
##

sub setProperty
{
  my $self = shift(@_);
  my $prop = shift(@_);
  my $valu = shift(@_);

  if( defined( $prop ) )
  {
    $self->{PROPS}{$prop} = $valu;
  }

  return( undef );
}

##
##  delProperty( $prop )
##
##  Delete the property if it exists
##
##  pre:  $prop defined
##  post: set = set@pre->excluding( $prop )
##

sub delProperty
{
  my $self = shift(@_);
  my $prop = shift(@_);

  if( defined( $prop ) && defined $self->{PROPS}{$prop} )
  {
    delete $self->{PROPS}{$prop};
  }

  return( undef );
}

##
##  toString( )
##
##  Creates a string description of this object.
##
##  post: result = string description
##

sub toString
{
  my $self = shift;
  my $props = $self->getPropertyListSorted();
  my $prop;
  my $result;

  foreach $prop ( @$props )
  {
    $result .= sprintf("  %-15s : %s\n", $prop, $self->{PROPS}{$prop} );
  }

  return $result;
}

sub _setget
{
  my( $self, $prop, $val ) = @_;
  $self->setProperty( $prop, $val ) if( defined $val );
  return $self->getProperty( $prop );
}


##
## PACKAGE solaris::zone;
##
##  Implements simplified zone creation and deletion interface
##

package Solaris::zone;

use strict;
use Data::Dumper;
use Carp;

## Inherit from Property Class
use base qw{Property};

sub new
{
  my $package  = shift(@_);
  my $zonename = shift(@_);
  my $self     = $package->SUPER::new();

  unless( defined $zonename )
  {
    croak "no defined zone-name";
  }

  $self->zonename( $zonename );
  $self->autoboot( 'false'   );

  ## TimeZone Default to local
  my $TZ;
  if( -f '/etc/TIMEZONE' && open( $TZ, '<', '/etc/TIMEZONE' ))
  {
    my $tz = (grep(/^TZ=/,<$TZ>))[0];
       $tz =~ s/^TZ=//;
    chomp( $tz );
    $self->timezone( $tz );
    ## print " INFO: Default TZ = $tz\n";
    close($TZ);
  }

  return $self;
}

sub zonename    { $_[0]->_setget('ZONE___', $_[1] );}
sub clone       { $_[0]->_setget('CLONE__', $_[1] );}
sub media       { $_[0]->_setget('MEDIA__', $_[1] );}
sub _hostname   { $_[0]->_setget('HOST___', $_[1] );}
sub zonepath    { $_[0]->_setget('ZPTH___', $_[1] );}
sub _autoboot   { $_[0]->_setget('ABOOT__', $_[1] );}
sub _network    { $_[0]->_setget('NETS___', $_[1] );}
sub _iptype     { $_[0]->_setget('IPTYPE_', $_[1] );}
sub _paths      { $_[0]->_setget('DIRS_WR', $_[1] );}
sub _inherit    { $_[0]->_setget('DIRS_RO', $_[1] );}
sub timezone    { $_[0]->_setget('TZ_____', $_[1] );}
sub password    { $_[0]->_setget('PW_____', $_[1] );}
sub timeserv    { $_[0]->_setget('NTP____', $_[1] );}
sub nameserv    { $_[0]->_setget('NAMSRV_', $_[1] );}
sub _brandz     { $_[0]->_setget('BRANDZ_', $_[1] );}
sub cluster     { $_[0]->_setget('CLUSTR_', $_[1] );}
sub template    { $_[0]->_setget('TEMPLT_', $_[1] );}
sub num_cpu     { $_[0]->_setget('NUMCPU_', $_[1] );}
sub cpu_shares  { $_[0]->_setget('CPUSHRS', $_[1] );}
sub sched_class { $_[0]->_setget('SCHDCLS', $_[1] );}
sub mem_phys    { $_[0]->_setget('MPHYS__', $_[1] );}
sub mem_locked  { $_[0]->_setget('MLOCKED', $_[1] );}
sub mem_swap    { $_[0]->_setget('MSWAP__', $_[1] );}

sub cpu
{
  ##  --cpu     num-cpu,cpu-shares,scheduling-class
  my $self = shift(@_);
  my $info = shift(@_);

  if( defined $info )
  {
    my( $num, $shares, $sclass ) = split ',', $info;

    $self->num_cpu( $num )          if defined $num;
    $self->cpu_shares( $shares )    if defined $shares;
    $self->sched_class( 'FSS' )     if defined $shares;
    $self->sched_class(uc($sclass)) if defined $sclass;
  }
  else
  {
    my( $num, $shares, $sclass ) = ('','','');

    $num    = $self->num_cpu     if defined $self->num_cpu;
    $shares = $self->cpu_shares  if defined $self->cpu_shares;
    $sclass = $self->sched_class if defined $self->sched_class;

    $info = "$num,$shares,$sclass";
  }

  return $info;
}

sub memory
{
  ##  --memory  physical,locked,swap
  my $self = shift(@_);
  my $info = shift(@_);

  if( defined $info )
  {
    my( $phys, $locked, $swap ) = split ',', $info;

    $self->mem_phys( lc($phys))     if defined $phys;
    $self->mem_locked( lc($locked)) if defined $locked;
    $self->mem_swap( lc($swap))     if defined $swap;
  }
  else
  {
    my( $phys, $locked, $swap ) = ('','','');

    $phys   = $self->mem_phys       if defined $self->mem_phys;
    $locked = $self->mem_locked     if defined $self->mem_locked;
    $swap   = $self->mem_swap       if defined $self->mem_swap;

    $info = "${phys},${locked},${swap}";
  }

  return $info;
}

sub brand
{
  my $self = shift(@_);
  my $info = shift(@_);

  return $self->_brandz unless( defined $info );

  my( $brand, $cluster ) = split( ',', $info );

  $self->_brandz( $brand   );

  $self->template( $cluster ) if $self->is_native;
  $self->cluster( $cluster )  if $self->is_brandlx;
}

sub hostname
{
  my $self = shift(@_);
  my $name = shift(@_);

  $self->_hostname( $name ) if( defined $name );

  $name = $self->_hostname;
  $name = $self->zonename  unless defined $name;

  return $name;
}

sub paths
{
  my $self = shift(@_);
  my $dirs = shift(@_);

  return $self->_paths unless( defined $dirs );

  ## Define Dirs
  my $dirpaths = [ split(',', $dirs ) ];

  $self->_paths( $dirpaths );
}

sub is_native
{
  my $self = shift(@_);
  return ( ! defined $self->brand ) unless defined $self->brand;
  return (   defined $self->brand and lc($self->brand) eq 'native' );
}

sub is_brandlx
{
  my $self = shift(@_);
  return ( defined $self->brand and lc($self->brand) eq 'sunwlx' );
}

sub inherit
{
  my $self = shift(@_);
  my $dirs = shift(@_);

  return $self->_inherit unless( defined $dirs );

  ## Define Dirs
  my $dirpaths = [ split(',', $dirs ) ];

  $self->_inherit( $dirpaths );
}


sub iptype
{
  my $self  = shift(@_);
  my $itype = shift(@_);

  IP_TYPE:
  {
    if( defined $itype && 'shared' eq lc( $itype ))
    {
      $itype = lc( $itype );
      last IP_TYPE;
    }

    if( defined $itype && 'exclusive' eq lc( $itype ))
    {
      $itype = lc( $itype );
      last IP_TYPE;
    }

    printf " WARN - Unsupported interface type [ %s ] not one of [ shared | exclusive ]\n",
      defined $itype ? lc( $itype ) : 'undefined';
    exit -1;
  }

  $self->_iptype( $itype );
}

sub network
{
  my $self = shift(@_);
  my $netw = shift(@_);

  return $self->_network unless( defined $netw );

  ## Define Networks
  my $nettype  = undef;
  my $typeerr  = undef;
  my $networks = [];
  my $netdata  = [ split(',', $netw ) ];

  foreach my $ent ( @$netdata )
  {
    my( $interface, $network ) = split('=', $ent, 2 );

    ## We should test sanaty of this information (but we dont)
    ##  does /dev/${interface} exist?
    ##  does $network "look like" xxx.xxx.xxx.xxx/xx
    ##  zonecfg will do some checking for us but it would be better
    ##  if we try to catch some things now.

    push @$networks, [ $interface, $network ];
  }

  $self->_network( $networks );
}

sub autoboot
{
  my $self = shift(@_);
  my $auto = shift(@_);

  $auto = lc($auto) if( defined $auto );

  if( defined $auto and $auto =~ /^(true|false)$/ )
  {
    $self->_autoboot( $auto );
  }  

  return $self->_autoboot;
}


sub zone_definition
{
  my $self = shift(@_);
  my $rslt = [];

  if( $self->is_native )
  {
    my $template = defined $self->template ? sprintf(" -t %s", $self->template ) : '';
    push( @$rslt, "create -F${template}" );
  }
  else
  {
    push( @$rslt, sprintf("create -F -t %s", $self->brand ));
  }

  push( @$rslt, sprintf("set zonepath=%s/%s", $self->zonepath, $self->zonename ));
  push( @$rslt, sprintf("set autoboot=%s",    $self->autoboot ));

  ## Read-Write Filesystems
  ##  (assumption: (global):/export/home -> (non-global):/export/home
  my $readwrite = $self->paths;

  foreach my $dir ( @$readwrite )
  {
    push( @$rslt, "add fs" );
    push( @$rslt, sprintf("set dir=%s", $dir ));
    push( @$rslt, sprintf("set special=%s", $dir ));
    push( @$rslt, 'set type=lofs' );
    push( @$rslt, 'add options [rw,nodevices]' );
    push( @$rslt, "end" );
  }

  ## Inherited Readonly-paths
  my $inherited= $self->inherit;

  foreach my $dir ( @$inherited )
  {
    push( @$rslt, "add inherit-pkg-dir" );
    push( @$rslt, sprintf("set dir=%s", $dir ));
    push( @$rslt, "end" );
  }

  ## IP-TYPE ()

  if( defined $self->_iptype && 'exclusive' eq $self->_iptype )
  {
    push( @$rslt, sprintf("set ip-type=%s", $self->_iptype ));
  }

  ## Network interfaces
  my $networks = $self->network;

  foreach my $net ( 0..$#$networks )
  {
    push( @$rslt, "add net" );
    push( @$rslt, sprintf("set physical=%s", $networks->[$net][0] ));
    push( @$rslt, sprintf("set address=%s",  $networks->[$net][1] ))
      unless( defined $self->_iptype && 'exclusive' eq $self->_iptype );
#       if( defined $networks->[$net][1] && length $networks->[$net][1]);
    push( @$rslt, "end" );
  }

  ## Container Support

  CPU_CONSTRAINTS:
  {
    my $cpus   = $self->num_cpu;
    my $shares = $self->cpu_shares;
    my $sclass = $self->sched_class;

    last CPU_CONSTRAINTS unless( defined $cpus or defined $shares or defined $sclass );

    ## We assume the caller is using the correct mix of arguments and values!
    ##  (we let zonecfg and zoneadm do the complaining!)

    push( @$rslt, sprintf("add capped-cpu; set ncpus=%s; end", $cpus ))
      if( defined $cpus and '' ne $cpus );

    push( @$rslt, sprintf("set cpu-shares = %s", $shares ))
      if( defined $shares and '' ne $shares );

    push( @$rslt, sprintf("set scheduling-class = %s", $sclass ))
      if( defined $sclass and '' ne $sclass );
  }

  MEM_CONSTRAINTS:
  {
    my $phys   = $self->mem_phys;
    my $locked = $self->mem_locked;
    my $swap   = $self->mem_swap;

    last MEM_CONSTRAINTS unless( defined $phys or defined $locked or defined $swap );

    push( @$rslt, "add capped-memory" );
    push( @$rslt, "set physical = $phys"   ) if( defined $phys   and '' ne $phys );
    push( @$rslt, "set locked   = $locked" ) if( defined $locked and '' ne $locked );
    push( @$rslt, "set swap     = $swap"   ) if( defined $swap   and '' ne $swap );
    push( @$rslt, "end" );
  }

  return $rslt;
}


sub sysidcfg
{
  my $self = shift(@_);
  my $conf = [];

  my $interface = 'primary';
  my $networks  = $self->network;

  if( defined $self->_iptype && 'exclusive' eq $self->_iptype &&
      defined $networks && 'ARRAY' eq ref $networks )
  {
    $interface = $networks->[0][0];
  }

  push( @$conf, sprintf("timezone=%s", $self->timezone ));
  push( @$conf, sprintf("system_locale=%s", 'C' ));
  push( @$conf, sprintf("root_password=%s", $self->password ));
  push( @$conf, "name_service=NONE" ) unless defined $self->nameserv;
  push( @$conf, $self->nameserv )         if defined $self->nameserv;
  push( @$conf, sprintf("security_policy=%s", 'NONE' ));
  push( @$conf, sprintf("terminal=%s",        'vt100' ));
  push( @$conf, sprintf("timeserver=%s", $self->timeserv )) if defined $self->timeserv;
  push( @$conf, sprintf("nfs4_domain=%s",     'dynamic' ));

  if( defined $self->_iptype && 'exclusive' eq $self->_iptype )
  {
    foreach my $net ( 0..$#$networks )
    {
      my $def_router = $self->timeserv; # same as time server around here :)
      my $ip_addr    = $self->_getipadder($networks->[$net][1]);
      my $ip_mask    = $self->_getnetmask($networks->[$net][1]);

      push( @$conf, sprintf("network_interface=%s {hostname=%s ip_address=%s netmask=%s protocol_ipv6=no}",
        $networks->[$net][0],
        $self->hostname,
        $ip_addr,
        $ip_mask
      ));
    }
  }
  else
  {
    push( @$conf, sprintf("network_interface=%s {hostname=%s}",
        ((defined $self->_network && scalar @{$self->_network} )
          ? $interface : 'NONE' ),
        $self->hostname
      ));
  }

  return $conf;
}


sub _getipadder
{
  my $self = shift(@_);
  my $data = shift(@_);
  my $addr = '';

  if( defined $data && $data =~ m=^[0-9]{1,3}[.][0-9]{1,3}[.][0-9]{1,3}[.][0-9]{1,3}= )
  {
    my( $ip, $mbits ) = split '/', $data;
    $addr = $ip;
  }

  return $addr;
}

sub _getnetmask
{
  my $self = shift(@_);
  my $data = shift(@_);
  my $mask = 'junk';

  if( defined $data && $data =~ m=^[0-9]{1,3}[.][0-9]{1,3}[.][0-9]{1,3}[.][0-9]{1,3}= )
  {
    my( $ip, $mbits ) = split '/', $data;
    my $hbits = 32 - $mbits;
    my $bmask = 0;

    while( $mbits )
    {
      $mbits--;
      $bmask <<= 1;
      $bmask |= 1;
    }

    while( $hbits )
    {
      $hbits--;
      $bmask <<= 1;
    }


    $mask = sprintf("%d.%d.%d.%d",
        ( $bmask >> 24 ) & 255,
        ( $bmask >> 16 ) & 255,
        ( $bmask >>  8 ) & 255,
        ( $bmask       ) & 255
      );
  }

  return $mask;
}




__END__

##
## Documentation
##

=pod

=head1 NAME

zonetool.pl - A Solaris zone building tool

=head1 SYNOPSYS

The zonetool.pl controls and configures many aspects of the zone
building process from a single command line operation.

=head1 USAGE

 (native Solaris example)
 $ zonetool.pl -c [ -b native ] -z zonename \
    -h myhost.company.dom.com -p /zones \
    [ -k ( shared | exclusive ) ] \
    -n 'ce0=192.168.120.22/24,ce1=192.168.192.22/24' \
    -a ( true | false ) [ -i '/opt,/example/blah' ] \
    [ -f '/export/home,/export/disk0' ] -t US/Central \
    -r timeserver -s 'name_service=NONE'

 (Linux lx branded example)
  note: options not shown in example are ignored for lx brand
 $ zonetool.pl -c -b SUNWlx[,development] -z zonename -p /zones \
    -m /zone/compatable/installation/media \
    -n 'ce0=192.168.120.23/24,ce1=192.168.192.23/24' \
    -a ( true | false )

 (Zone Removal Unsupported)
 $ ./zonetool -d -z zonename (unsupported)

=head1 OPTIONS

=over 4

=item -c | --create

This option designates a create zone operation. By default a native
Solaris zone is created. The "brand" of the zone can be explicitly defined
as an argument to the brand option.

=item -d | --delete

The automatic removal of a zone is unsupported at this time. I am
currently not sure that automatic removal of a zone is a good idea.

=item -b | --brand [ native[,template] | SUNWlx[,cluster] ]

By default a native sparse root Solaris zone is created. Other native
zone templates may be used by using the "native,template" argument format.
A whole root zone is created using this option. For example using
"--brand native,SUNWblank" defines the zone as a whole root.

The "brand" of the zone is
explicitly defined as an argument to the brand option. When the brand
option is used an argument is required. The argument must be "native"
or a currently known BrandZ template of the zonecfg tool.

There is some confusion about the keywords to be used to select an
installation cluster for lx brand zones. Most documented lists include
[ core, server, desktop, developer, all ]; however during testing the
"developer" cluster was selected by using the "development" keyword.

=item -z | --zonename

Defines the name of the zone.

=item -e | --clone source-zone [ -m copy ]

The installation of the new zone will take place by cloning an exiting,
installed, non-running zone. The zones *MUST* be the same BrandZ. No
checking is done by zonetool.pl. The operator is expected to ensure
that both zones are the same type, the source zone exists and is
in the "installed" state. By default the cloning process is completed by
making a snapshot and cloning from it. This is very fast. By using the
optional [ -m copy ] option argument the clone will be produced by making
a copy.

=item -h | --hostname

Defines the primary hostname of this zone.

=item -k | --iptype

The default network interface for a zone is shared. The shared type plumbs an
alias of the selected interface within the global zone and places this interface
witin the zone for its use. The exclusive network type places the defined physical
interface in the zone. The zone performs its own configuration of the interface.
Consult the -n | --network option for usage details about selecting an interface
and defining IP-address and netmask properties. The use of this option to define
an exclusive network interface is at the mercy of the Solaris uptade being used
and its patch level.

=item -n | --network

Define one or more interfaces. The form for each interface is 'interface=IP'.
More than one may be defined by using a comma separated list of the form
'interfaceX=IP/maskbits,interfaceY=IP/maskbits,...'. A zone may use a shared
(the default) or an exclusive network interface. A zone cannot have both a
shared and an exclusive interface. The ip-type: [shared,exclusive] is defined
by the -k | --iptype argument.

=item -p | --zonepath

Define the path where the zone will be created. The final path used will be
the combination of ( -p )/( -z ). When the options '-z myzone1' and '-p /zones'
are used the zone will be created at the path /zones/myzone1.

=item -a | --autoboot

Define if the zone should autoboot. true=autoboot false=no-autoboot. To turn
on autobooting the option is specified as "-a true". Example: -a true

=item -i | --inherit

Define one or more paths that will be mounted read-only and defined as zone
inherit-pkg-dir from the global zone. Example: -i '/opt'

=item -f | --filesystem

Define one or more paths that will be read-write file-systems to be mounted in this
zone from the global. Example -f '/export/home,/export/disk1'

=item -t | --timezone

Define the timezone this zone should be configured to use. Example: -t US/Central

=item -r | --timeserv

Define the IP address of the time server. Used in the sysidcfg file.

=item -s | --nameserv

Define the name_service configuration entry to place in the sysidcfg file. The
argument is not tested or checked. The value provided is placed in the sysidcfg
as-is and must include the complete and full syntax expected by the Solaris
system configuration startup activity. The default value when this option is
not used is "name_service=NONE".

=item --memory physical,locked,swap

At least one value must be supplied. No white-space should be included. Leaving
a field empty will make that setting empty/unused/unset in the zone's configuration.
If you only want to limit swap use two comma's and a value for swap. By default the
created zone will have no memory limits placed on it.

Examples:
 --memory 2g,200m,3g  (physical=2g, locked=200m, swap=3g)
 --memory ,250m       ( only locked will be set @ 250m )
 --memory ,,5g        ( only swap will be se @ 5g )

=item --cpu num-cpu,cpu-shares,scheduling-class

At least one value must be supplied. No white-space should be included. Leaving
a field empty will make that setting empty/unused/unset in the zone's configuration
except where noted later. It is recommended that all three fields be provided (set)
when this option is used. By default a zone's CPU settings are open or controlled by
the global zone (resource management).

The num-cpu field "caps" the zones cpu usage
to a whole integer (ie. 1 2 3 4 ...) or a fractional CPU (ie. 1.25, 2.5 ...). A
value of 1.5 will cap the zone at 1.5 CPU utilization where 2 will cap the zone at
an even two (2).

The cpu-shares field sets a zones minimum fair share of CPU units. Unlike the num-cpu
field the cpu-shares must always be a whole positive integer. The value of cpu-shares
is a percentage of one CPU. For example cpu-shares value of 50 will guarantee that
the zone will receive 1/2 or 50% of a CPU per second while a value of 225 will
guarantee the zone receives 225% or 2 and 1/4 CPU usage per second. It is important to
note that this guarantee only works if the sum of the non-global-zone cpu-shares and
the actual global zone usage do not exceed 100 * Number-of-System CPU's.

The scheduling-class defaults to the systems global zone default. This is normally Time-
Sharing (TS). If this option is used it is set to Fair Share Scheduler (FSS). It is
not recommended that this value be over ridden, this being the case the field need not
be supplied. If supplied the only valid value is "FSS", other values operation are
undefined.

=item -m | --media

Define the path that contains installation media for a non native zone.

=item --rootpassword | --rootpw

Define the encrypted root password for this zone. The default behavior is to use
the password from the global zone. This option must be provided an argument that
is encrypted. The encryption requirement is to keep cleartext passwords from being
seen on the command-line or process list.

 --rootpw Qwer99ty       (WRONG!!!)
 --rootpw ir9Ru048IlDPs  (Correct == changeme)

=item --debug

Run without actually building the zone. The zone building files are created and
available for review.

=item --help

Display this documentation.

=back

=head1 Source

Master location: south-campus:/data/mobilize/DZ-Management/zonetool/

=head1 AUTHOR

Victor Burns

=head1 BUGS

None Known (Okay many, but who's looking)

=head1 SEE ALSO

N/A

=head1 COPYRIGHT

LICENSE 2009, Released by permission to Linux Journal for inclusion in publication and/or electronic downloading by the public from LINUX Journal servers. The end-user takes full responsibility for the use of this script/tool/utility. Texas Instruments and the Author take no responsibility for its use.

Copyright 2007-2008, Texas Instruments Incorporated. All rights reserved as an unpublished work.

=cut


## END
