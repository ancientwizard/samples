
## DESCRIPTION: Simple::ClockArt
##    An unfinished work for illustrative purposes only
##    Only a couple of sub classes have been stubbed out
##    and the primary class a "test" run to illustrate the sub class usage.
##  Run as $ perl -MSimple::ClockArt -e ""
##

##  PERLCRITIC:
##    no critic [Documentation::RequirePodSections]
##      (one day I'll finish this work, including the POD)

package Simple::ClockArt;

use strict;
use warnings;
use Carp;
use List::Util    qw| max maxstr |;
use Data::Dumper;

use parent qw | Returned |;

our $PKGNAME = __PACKAGE__;
our $VERSION = 0.1;

local $Data::Dumper::Indent = 1;

my $scale = 15;

print Simple::ClockArt::Dial->new(
    -TITLE  => 'Timer Map Scale:' . $scale
  , -SCALE  => $scale
  , -MARKUP =>
    {
        E => 'US/Eastern'
      , C => 'US/Central'
      , M => 'US/Mountain'
      , P => 'US/Pacific'
      , J => 'Japan'
      , K => 'Hongkong'
      , H => 'US/Hawaii'
      , R => 'Europe/Moscow'
      , I => '+05:30'   ## India
      , G => 'GMT'
    }
  )->toString;

print ' ', $_, "\n" for $PKGNAME->merge(
  Simple::ClockArt::Timer->new(
      -NAME       => 'TMR1'
    , -START      => '17:00'
    , -DURATION   => '12:00'
    , -SCALE      => $scale
  )->toString
,
  Simple::ClockArt::Timer->new(
      -NAME       => 'TMR2'
    , -START      => '11:00'
    , -DURATION   => '02:30'
    , -SCALE      => $scale
  )->toString
,
  Simple::ClockArt::Timer->new(
      -NAME       => 'TRM3'
    , -START      => '14:00'
    , -DURATION   => '02:30'
    , -SCALE      => $scale
  )->toString
,
  Simple::ClockArt::Timer->new(
      -NAME       => 'TMR[a-e]'
    , -START      => '02:30'
    , -DURATION   => '05:00'
    , -SCALE      => $scale
  )->toString
);


sub merge
{
  my $self = shift;
  my $list = [ @_ ];
  my $merged = [];

  MERGE:
  {
    last MERGE unless scalar @ $list;

    if ( scalar @ $list == 1 )
    {
      push @ $merged, shift @ $list;
      last MERGE;
    }

    if ( scalar @ $list == 2 )
    {
      my ( $rowA, $rowB );
      my $rowm = [];
      my $row1 = [ split m==x, ( $rowA = shift @ $list )];
      my $row2 = [ split m==x, ( $rowB = shift @ $list )];

      eval
      {
        while ( scalar @ $row1 || scalar @ $row2 )
        {
          my ( $_a, $_b ) = ( shift( @ $row1 ), shift( @ $row2 ));

          croak sprintf 'merge failure (%s,%s)', $_a, $_b
              if $_a && $_b && $_a ne ' ' && $_b ne ' ';

          push @ $rowm, (( $_a && $_b ) && maxstr( $_a, $_b ))
            || ( $_a && ! $_b ? $_a : $_b );
        }

        push @ $merged, join '', @ $rowm;
      }
      ||
      do
      {
        push @ $merged, $rowA, $rowB;
      };

      last MERGE;
    }

    push @ $merged, shift @ $list ;

    while ( @ $list )
    {
      push @ $merged, $self->merge( shift @ $merged, shift @ $list );
    }
  }

  return @ $merged;
}


## ---------------------------------------------------------------------------
##  Helper Class

## no critic [Modules::ProhibitMultiplePackages]
## no critic [Variables::ProhibitReusedNames]
##   Critic would'nt know unpacking if it was hit with a suitcase!

package Simple::ClockArt::Timer;

use strict;
use warnings;
use Carp;
use Data::Dumper;

use parent qw| Returned |;

our $PKGNAME;

BEGIN { $PKGNAME = __PACKAGE__ }

sub new
{
  my $self = (shift)->SUPER::new(1);
  my $args = ref $_[0] ? shift : { @_ };

  $self->name(      $args->{ -NAME     } );
  $self->scale(     $args->{ -SCALE    } // 15 );
  $self->start(     $args->{ -START    } // '' );
  $self->duration(  $args->{ -DURATION } // '' );

  my ( $shr, $smn ) = split m=:=x, $self->start;
  my ( $dhr, $dmn ) = split m=:=x, $self->duration;

  ## Exceptions
  croak sprintf '%s (L#%d) - Unnamed timer, use: -NAME => Name'
          , $PKGNAME, __LINE__
        unless defined $self->name;

  croak sprintf '%s (L#%d) - Invalid timer-start, use: -START => HH::MM'
          , $PKGNAME, __LINE__
        unless defined $self->start
            && $self->start =~ m=^[0-9]{2}:[0-9]{2}$=x
            && $shr >= 0 && $shr <= 23 && $smn >= 0 && $smn <= 59;

  croak sprintf '%s (L#%d) - Invalid timer-duration, use: -DURATION => HH:MM'
          , $PKGNAME, __LINE__
        unless defined $self->duration
            && $self->duration =~ m=[0-9]{2}:[0-9]{2}$=x
            && $dhr >= 0 && $dhr <= 23 && $dmn >= 0 && $dmn <= 59;

  croak sprintf '%s (L#%d) - Invalid time-scale, use: -SCALE => 10 | 15'
          , $PKGNAME, __LINE__
        unless defined $self->scale
            && ( $self->scale == 15 || $self->scale == 10 );

  return $self;
}

sub name          { return $_[0]->_setget( '_NAME________', $_[1] ) }
sub start         { return $_[0]->_setget( '_START_______', $_[1] ) }
sub duration      { return $_[0]->_setget( '_DURATION____', $_[1] ) }
sub scale         { return $_[0]->_setget( '_SCALE_______', $_[1] ) }

sub toString
{
  my $self  = shift;
  my $name  = $self->name;
  my $scale = 60 / $self->scale;

  my ($dura_hr,$dura_mn) = split m=:=x, $self->duration;
  my ($strt_hr,$strt_mn) = split m=:=x, $self->start;
  my ($str,    $buf    ) = ('','');

  $str = '-' x ( $dura_hr * $scale + $dura_mn / 60 * $scale );
  $buf = ' ' x ( $strt_hr * $scale + $strt_mn / 60 * $scale );

  ## Prep timer
  substr $str, -1, 1, '>';
  substr $str,  0, 1, '<';

  LABEL:
  {
    my $timer_length = length $str;
    my $label_length = length $name;

    if ( $timer_length < $label_length )
    {
      $str = '*' . substr $name, 0, $timer_length - 1;
      last LABEL;
    }

    if ( $timer_length == $label_length )
    {
      $str = $name;
      last LABEL;
    }

    if ( $timer_length <= $label_length + 2 )
    {
      substr $str, 1, $label_length, $name;
      last LABEL;
    }

    substr $str, 2, $label_length, $name;
  }

  ## Overlay timer on top of buf
  OVERLAY:
  {
    my $start_length = length $buf;
    my $label_length = length $str;

    if ( $start_length + $label_length < 24 * $scale )
    {
      $buf .= $str;
      last OVERLAY;
    }

    my $tail_length = 24 * $scale - $start_length;
    my $head_length = $label_length - $tail_length;

  # print "# ( $head_length, $tail_length )\n";

    $buf .= substr $str, 0, $tail_length;
    substr $buf, 0, $head_length, substr $str, -$head_length
        if $head_length;
  }

  return $buf;
}


package Simple::ClockArt::Dial;

use strict;
use warnings;
use Carp;
use DateTime;
use Data::Dumper;

use parent qw| Returned |;

sub new
{
  my $self = (shift)->SUPER::new(1);
  my $args = ref $_[0] ? shift : { @_ };

  $self->markup( $args->{ -MARKUP } // 0 );
  $self->scale(  $args->{ -SCALE  } // 15 );
  $self->title(  $args->{ -TITLE  } );

  ## Exceptions
  croak sprintf '%s (L#%d) - Invalid time-scale, use: -SCALE => 10 | 15'
          , $PKGNAME, __LINE__
        unless defined $self->scale
            && ( $self->scale == 15 || $self->scale == 10 );

  return $self;
}

sub markup        { return $_[0]->_setget( '_MARKUP______', $_[1] ) }
sub scale         { return $_[0]->_setget( '_SCALE_______', $_[1] ) }
sub title         { return $_[0]->_setget( '_TITLE_______', $_[1] ) }

sub toString
{
  my $self  = shift;
  my $scale = 60 / $self->scale;
  my $head  = [];
  my $str   = '';
  my ( $hr, $mn );

  HEADER:
  {
    push @ $head, '';
    push @ $head, ' Title: ' . $self->title if $self->title;
  # push @ $head, '' if $self->title;
    push @ $head, ' ' . join ' ' x ($scale - 1), ((' ') x 10, (1) x 10, (2) x 4 );
    push @ $head, ' ' . join ' ' x ($scale - 1), ((0 .. 9) x 2, 0 .. 3 );
    $str .= ' ' . (( $scale == 6 ? '+--~--' : '+-~-' ) x 24 ) . "\n";

    last HEADER unless $self->markup;

    my $TZs = $self->markup;

    foreach my $short_id ( keys % $TZs )
    {
      my $dt = DateTime->from_epoch( time_zone => $TZs->{ $short_id }, epoch => time );
      ( $hr, $mn ) = ( $dt->hour, $dt->minute );
      substr $str, ( $hr * $scale + $mn / 60 * $scale + 1 ), 1, $short_id;
    }
  }

  return join "\n", @ $head, $str;
}


1;

__END__

##
## Documentation
##

=pod

=head1 NAME

Simple::ClockArt - An ASCII clock/timer viewer

=head1 LICENSE AND COPYRIGHT

The "Artistic License"

URL http://dev.perl.org/licenses/artistic.html

=cut


## END
