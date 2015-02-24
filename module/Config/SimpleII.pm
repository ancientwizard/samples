##
## SVN Header
##
##    Repository: $HeadURL: https://svn.worldnet.ml.com/svnrepos/secengunix/sshkeymgmt/trunk/TrustGuardian/module/Config/SimpleII.pm $
##     Committed: $LastChangedRevision: 684 $
##    Changed by: $LastChangedBy: zkokbez $
##  Changed date: $LastChangedDate: 2015-02-23 07:10:42 -0600 (Mon, 23 Feb 2015) $
##            ID: $Id: SimpleII.pm 684 2015-02-23 13:10:42Z zkokbez $
##

##
## PACKAGE Config::SimpleII( )
##
##  DESCRIPTION:  A Pure Perl replacement for the CPAN Config::Simple module.
##   It may be preferable to use Config::Simple however all too
##   often the system environment wont allow CPAN use OR Config::Simple has
##   behaviors not compatable with requirements. This version
##   only supports the ".ini" style config file format with X.Y depth.
##   This replacement does *NOT* support x.y.z nor does everything
##   Config::Simple supports.
##
##  AUTHOR: Victor Burns
##    DATE: 2014-Jan
##
##  CHANGES:
##    2014-Jan-21 VICB - First Release
##

package Config::SimpleII;

use strict;
use warnings;
use Fcntl qw(:flock);
use Returned;
use MIME::Base64;
use Data::Dumper;

##  Inherit from Returned() Class
use base qw(Returned);

## Class vars
our $VERSION;
our $PKGNAME;

sub BEGIN
{
  #-- Set Class defaults during compile
  $VERSION = 0.1;
  $PKGNAME = __PACKAGE__;
}


##
##  new( )
##
##  Constructor
##

sub new
{
  my $self = (shift)->SUPER::new(1);
  my $fnam = shift;
  my $cont = shift;

  #-- We only support INI
  ##   (Ignored for compatablity with Config::Simple)
  if( defined $fnam && lc($fnam) eq 'syntax' &&
      defined $cont && lc($cont) eq 'ini' )
  {
    $fnam = undef;
    $cont = undef;
  }

# printf STDERR "# Config::SimpleII(%s);\n", $fnam if $fnam;

  #-- Optional passed Configuration File
  ##   does not need to pre-exist
  $self->configFileName( $fnam );

  #-- Default data set {} (empty)
  $self->_configData({});

  #-- read() configuration file if exists
  $self->read;

  return $self;
}

## Store/Retrieve prop/value pairs
sub param
{
  my $self = shift;
  my $prop = shift;
  my $valu = shift;
  my $data = $self->_configData();

  $self->error_code(1);

  ## Process based on parameters
  PARAM:
  {
    ## Retrieve list of Params
    if( ! defined $prop )
    {
      $valu = [ keys %$data ];
      last PARAM;
    }

    ## Retrieve Param
    if( ! defined $valu )
    {
      $valu = exists $data->{ $prop } ? $data->{ $prop } : undef;
      last PARAM;
    }

    ## Save Data ARRAY
    if( ref $valu eq 'ARRAY' )
    {
      $data->{ $prop } = $valu;
      last PARAM;
    }

    ## Save Data SCALAR
    if( ! ref $valu )
    {
      $data->{ $prop } = $valu;
      last PARAM;
    }

    ## Unsupported ??
    $self->error_code(0);
    $self->debug_message(sprintf 'WARN: Unsupported data format [ %s ]', ref $valu );
  }

  return $valu;
}


##
## Delete a property
##
sub delete
{
  my $self = shift;
  my $prop = shift;
  my $data = $self->_configData();

  delete $data->{ $prop } if( defined $prop and exists $data->{ $prop } );

  return $self;
}


##
## Write configuration file
##
##  Returns $self
##
##  NOTE: We solve the issue with out of disk space by writign a new file
##    first
##
sub save
{
  my $self = shift;
  my $inif = $self->configFileName( shift );
  my $stat = 1;

  ## Assume operation will be okay
  $self->error_code(1);

  ## use predefined file?
  $inif = $self->configFileName unless defined $inif;

  ## No place to save
  unless( defined $inif )
  {
    $self->error_code(0);
    $self->error_message('WARN: Failed to save undefined configuration file');
  }

  ## Open and write
  if( open my $INI, '>', $inif . '.' . $$ )
  {
  # printf STDERR "# Writing: %s\n", $inif;
    $stat &&= flock( $INI, LOCK_EX );
    $stat &&= printf $INI "##\n";
    $stat &&= printf $INI "## Written by Config::SimpleII\n";
    $stat &&= printf $INI "## FILE: %s\n", $inif;
    $stat &&= printf $INI "## DATE: %s\n", scalar localtime;
    $stat &&= printf $INI "##\n";
    $stat &&= print  $INI "## WARNING: The format of this file is \"strict\".\n";
    $stat &&= print  $INI "##          Avoid using characters of the set [,]\n";
    $stat &&= print  $INI "##          Consult POD for complete details!!!\n";
    $stat &&= printf $INI "##\n";

    ## Prepare && Write Data
    my $data = $self->_convertData4Write;

    ## Write by [section]
    ##  followed by prop=value pairs
    foreach my $section ( sort keys %$data )
    {
      $stat &&= printf $INI "\n";
      $stat &&= printf $INI "[%s]\n", $section;

      my $props = $data->{ $section };

      foreach my $prop ( sort keys %$props )
      {
        $stat &&= printf $INI "%s=%s\n", $prop, $props->{ $prop };
      }
    }

    $stat &&= printf $INI "\n";
    $stat &&= printf $INI "## END\n";
    $stat &&= close  $INI;
    $stat &&= rename $inif . '.' . $$, $inif;
  }
  else
  {
    $self->error_message(sprintf 'WARN: Failed to open configuration file [ %s ] - %s', $inif, $! );
    $self->error_code(0);
  }

  ## Write Issues?
  unless( $stat )
  {
    $self->error_message(sprintf 'WARN: Failed writing configuration file [ %s ] = %s', $inif, $! );
    $self->error_code(0);
  }

  ## Remove temp version of the configuration file
  ##  (on some kinds of errors the file still exists and is expected to be broken)
  unlink $inif . '.' . $$ if -f $inif . '.' . $$;

  return $self;
}

sub write { my $self = shift; return $self->save(@_); }

##
## Loads configuration file into a hash.
##   {section.param} = value
##  OR
##   {section.param} = [ val1, val2, ... ]
##
##  Returns $self
##
sub read
{
  my $self = shift;
  my $inif = $self->configFileName( shift );
  my $data = $self->_configData;

  READ:
  {
    last READ unless defined $inif;
    last READ unless -f $inif;

#   printf STDERR "# Reading: %s\n", $inif ? $inif : 'UNDEF';

    if( open my $INI, '<', $inif )
    {
      my $section = '';
      my( $prop, $valu );

      ## Hold up, a write may be in progress
      ##  (due to our write methodology not really necessary)
      flock( $INI, LOCK_SH );

      while( my $line = <$INI> )
      {
        chomp $line;

        #-- Toss non-data
        next if $line eq '';
        next if $line =~ m=^#=;

        #-- Capture section
        if( $line =~ m=^\[= )
        {
          $section  = $line;
          $section  =~ s=[\[\]]==g;
          $section  = ''  if $section eq 'default';
          $section .= '.' if length $section;
          next;
        }

        #-- Toss other junk
        next unless $line =~ m=^\w=;

        #-- Handle white space around '='
        $line =~ s/ *= */=/;

        #-- Capture prop & value pair
        ( $prop, $valu ) = split '=', $line, 2;

        #-- Break coma list into array
        $valu = [ split m=, *=, $valu ] if $valu =~ m=,=;

        #-- Decode BASE64 strings if any
        _Decode64( ref $valu eq 'ARRAY' ? $valu : \$valu );

        #-- Store
        $data->{ $section . $prop } = $valu;
      }
   
      last READ;
    }

    ## Read error
    $self->error_message(sprintf 'WARN: Failed to open/read configuration file [ %s ] - %s', $inif, $! );
    $self->error_code(0);
  }

  return $self;
}

## Returns a unique copy of the configuration data
#    (mostly a copy, not that important, consumer should read-only)
sub vars
{
  return wantarray ? ( %{$_[0]->_configData} ) : { %{$_[0]->_configData} };
}

##
## Properties
##

sub configFileName  { return $_[0]->_setget('__CONF_FILE____', $_[1]); }

##
##  PRIVATE METHODS
##

sub _configData     { return $_[0]->_setget('__CONF_DATA____', $_[1]); }


##
## Returns: { section }{ prop } = value
##  Alternative solution is to sort the props (includes section) and let
##  it order items by section for writing and skip all this hoop jumping.
##
sub _convertData4Write
{
  my $self = shift;
  my $data = $self->_configData;
  my $wdat = {};

  foreach my $prop ( keys %$data )
  {
    my $section = 'default';
    my $valu = $data->{ $prop };

    #-- Conditionally convert to Base64 (hide commas)
    _Encode64( ref $valu eq 'ARRAY' ? $valu : \$valu );

    #-- Comma separated list on ARRAY
    $valu = join ', ', @$valu if( ref $valu eq 'ARRAY' );

    if( $prop =~ m=^([\w:-_]+)[.]= )
    {
      $section = $1;
      $prop =~ s=^[\w:-_]+[.]==;
    }

    $wdat->{ $section }{ $prop } = $valu;
  }

  return $wdat;
}

sub _Decode64
{
  my $data = shift;

# printf "== %s\n", ref $data;
  DECODE64:
  {
    if( ref $data eq 'SCALAR' && $$data =~ m=^BASE64= )
    {
      $$data =~ s=(BASE64[(]|[)])==g;
      $$data = decode_base64( $$data );
      last DECODE64;
    }

    if( ref $data eq 'ARRAY' )
    {
      foreach my $i ( 0 .. $#$data )
      {
        if( $data->[$i] =~ m=^BASE64= )
        {
          $data->[$i] =~ s=(BASE64[(]|[)])==g;
          $data->[$i] = decode_base64( $data->[$i] );
        }
      }

      last DECODE64;
    }
  }

  return;
}

sub _Encode64
{
  my $data = shift;

  ENCODE64:
  {
    if( ref $data eq 'SCALAR' )
    {
      $$data = 'BASE64(' . encode_base64( $$data, '' ) . ')' if $$data =~ m=[,\n]=;
      last ENCODE64;
    }

    if( ref $data eq 'ARRAY' )
    {
      foreach my $i ( 0 .. $#$data )
      {
        $data->[$i] = 'BASE64(' . encode_base64( $data->[$i], '' ) . ')'
            if $data->[$i] =~ m=[,\n]=;
      }

      last ENCODE64;
    }

    ##  Woops - future support? (undef etc)
  }

  return;
}


1;

__END__

##
## Documentation
##

=pod

=head1 NAME

Config::SimpleII - A Pure Perl [INI] style configuration file module

=head1 SYNOPSIS

This module provides an Object oriented abstraction interface for building
and maintaining [INI] file configuration files.

=head1 VERSION

1.0

=head1 DESCRIPTION

This package provides a Pure Perl [INI] configuration file OO interface with the following public methods.

=head1 USAGE & Examples

=head1 SUBROUTINES AND METHODS

=over 4

=item new()

The new method constructs an instance of Config::SimpleII

 use Config::SimpleII;
 
 my $config = Config::SimpleII( 'myconf.ini' );

=item param()

Used to set a property/value pair or returns a property. When only the property
name only is passed its value, if known, is returned. If a value is passed it is
saved or repalced an existing value. The value should be one of: scalar OR an
array reference.

The paramater name may consits of two parts. If a "." period is included the preceeding string
is the "section" and the following string is the parameter name. The section nam may consist
of this character set "[\w:-_]".

Example 1:
  $config->param( 'Yellow.Submarine', 'beatles' );

  # Saved as:
  [Yellow]
  Submarine=beatles

Example 2:
  $config->param( 'Lazy.Susan', [ 'spinner', 'turntable' ] );

  # Saved as:
  [Lazy]
  Susan=spinner, turntable

Example 3:
  $config->param( 'Numbers', [ 0 .. 5 ] );

  # Saved as:
  [default]
  Numbers=0, 1, 2, 3, 4, 5

Example 4:
  $valu = $config->param( 'Numbers' ); # [ 0 .. 5 ]

Example 5:
  $params = $config->param();  # [ all params ]


When a paramter value includes a special character ("comma"", may add others later)
it is encoded using MIME::Base64 and decoded before returned to the consumer. Within
the configuration file one will see something like the following.

  [SomeSection]
  Song="This old man, he had one"  # is "Broken", it has a comma, line would be split

  # Will be stored as
  [SomeSection]
  Song=BASE64(IlRoaXMgb2xkIG1hbiwgaGUgaGFkIG9uZSI=)

=item delete()

The parameter name passed as an argument is removed from the configuration. This method
is the opposit of the param() method above which "Adds/Updates" configuration parameters.
This method is used to remove them.

=item save()

Writes the current data contents to the configuration file. By default uses the filename
passed when the instance is created new(). The configuration file may also be set using
$config->configFileName('AnotherConf.ini'). Alternatively the save() method can be passed
an alternative filename which is used for the operation but not stored and does not
replace the predefined configuration file name set using new() or configFileName().

  $config->save();
  $config->save('alternate.ini');

=item read()

Read's the configuration file into memory for usage. If a configuration file is passed
to new() then read() is used to perform the load into memory. The read() method may be
called by the consumer with an alternate filename to read into memory.

  $config->read('alternate.ini');

=item vars()

Returns a copy of the configuration file as a list or a hash reference.

  my $href = $config->vars();
  my %hash = $config->vars();

=item configFileName()

Clears the saved instance debug messages from the CLASS list.

=back

=head1 DIAGNOSTICS

N/A

=head1 CONFIGURATION AND ENVIRONMENT

N/A

=head1 DEPENDENCIES

Property

=head1 INCOMPATIBILITIES

None known

=head1 AUTHOR

Victor M. Burns (ancient.wizard@verizon.net)

=head1 BUGS AND LIMITATIONS

None Known

=head1 SEE ALSO

Property

=head1 LICENSE AND COPYRIGHT

BLANK

=cut


## END