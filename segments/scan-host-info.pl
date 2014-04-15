#!/usr/bin/perl

##
##  Description:
##   A small Perl script that was intended for a larger project.
##   The project changed direction and this code set is no longer
##   needed. Rather than deleting it I have saved it as an
##   unfinished work to Illustrate my clean and understandable
##   coding style.
##
##  AUTHOR: Victor Burns
##   Not for redistibution
##

use strict;
use warnings;
use lib '/home/vburns/lib';
use Data::Dumper;

my $hosts = new BagOf::Hosts;

printf "\n";
printf "  INFO ->> Host Scanner\n";
printf "\n";

$hosts->setFilters(qw+ ^(aa|ss)(dal|tul|sjc) +);
$hosts->loadHosts;

## .. program continues here
# print Dumper $hosts;


##
##  CLASSES
##

##
##  CLASS: Obj::Host
##

package Obj::Host;

use strict;
use warnings;
use Property;
use Carp;

use base 'Property';

sub new
{
  my $self = (shift)->SUPER::new(@_);
  my( $ip, $name, @aliases ) = @_;

  $self->IPv4 ( $ip );   # no type checking
  $self->hostname( $name );
  $self->aliases( \@aliases );

  return $self;
}

## Properties
sub IPv4       { return $_[0]->_setget('__IPv4____', $_[1]); }
sub hostname   { return $_[0]->_setget('__NAME____', $_[1]); }
sub aliases    { return $_[0]->_setget('__ALIASES_', $_[1]); }



##
## CLASS: BagOf::Hosts
##

package BagOf::Hosts;

use strict;
use warnings;
use Property;
use Carp;

use base 'Property';

sub new
{
  my $self = (shift)->SUPER::new(@_);

  $self->filters( [] );  # Default - no filters

  return $self;
}

sub loadHosts
{
  my $self = shift(@_);
  my $stat = 1;
  my $hosts = {};
  my $filters = $self->filters;

  ## Load host names using unix switch environment
  ##  (we're not concerned about the source)
  if ( open my $hFH, '-|', '/usr/bin/getent hosts' )
  {
    ## Read each host entry and build host object
    while( my $hEnt = <$hFH> )
    {
      chomp( $hEnt );

      ## Ignore empty and commented lines
      next if $hEnt =~ m=^(|#.*)$=;

      my $host = new Obj::Host( split ' ', $hEnt );

      ## Filter?
      if ( scalar @$filters )
      {
        my $matched = 0;

        foreach my $fltr ( @$filters )
        {
          $matched = 1, last if $host->hostname =~ m/$fltr/;
        }
        # printf "Droped: %d %s\n", $matched, $host->hostname unless $matched;
        next unless $matched;
      }

      # printf "Saved: %s\n", $host->hostname;
      $hosts->{ $host->hostname } = $host;
    }

    ## Close hosts FILE
    close $hFH;
  }
  else
  {
    ## Failed to open
    croak '"/usr/bin/getent hosts" - failure';
  }

  printf "  INFO ->> Loaded %d hosts\n", scalar keys %$hosts;
  $self->hosts( $hosts );

  return $stat;
}

sub setFilters
{
  my $self    = shift(@_);
  my $filters = [ @_ ];

  return $self->filters( $filters );
}

## Properties
sub hosts      { return $_[0]->_setget('__HOSTS___', $_[1]); }
sub filters    { return $_[0]->_setget('__FLTRS___', $_[1]); }


## END
