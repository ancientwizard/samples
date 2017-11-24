##
## PACKAGE platform( )
##
##  A simple object for detecting the local system type
##
##  AUTHOR: V Burns (ancient.wizard)
##    DATE: ??-???-2004
##
##  Changes:
##    2009-Jan-09 VICB - clear Severity 5 messages from perlcritic
##
##  Passes perlcritic level 3
##

package platform;

use strict;
use warnings;
use Carp;
use base qw| Property |;

our $VERSION = 1.0;

my $isUNIX;
my $isWinTEL;

sub BEGIN {
  if ( -d '/var' ) { $isUNIX = 1;     $isWinTEL = undef; }
  if ( -d 'C:\\' ) { $isUNIX = undef; $isWinTEL = 1; }

  unless ( defined $isUNIX || defined $isWinTEL )
  {
    croak( 'Could not determine if this system is UNIX or WinTEL.' );
  }
}

##
##  new( )
##
##  Create platform object
##

sub new
{
  return (shift)->SUPER::new();
}


##
##  isUNIX( )
##  isWinTEL( )
##

sub isUNIX   { return $isUNIX;   }
sub isWinTEL { return $isWinTEL; }


1;

__END__

##
## Documentation
##

=pod

=head1 NAME

platform -  simple module to detect if we are on UNIX or Wintel

=head1 SYNOPSIS

use platform;

=head1 VERSION

1.0

=head1 DESCRIPTION

Simple module for detecting if runtime host is UNIX or WinTEL.

=head1 SUBROUTINES/METHODS

=over 4

=item isUNIX()

Returns true is this system looks like UNIX.

=item isWinTEL()

Returns true if this system looks like WinTEL.

=back

=head1 DIAGNOSTICS

N/A

=head1 CONFIGURATION AND ENVIRONMENT

N/A

=head1 DEPENDENCIES

N/A

=head1 INCOMPATIBILITIES

None known

=head1 AUTHOR

V Burns (ancient.wizard@verizon.net)

=head1 BUGS AND LIMITATIONS

TOO Simple. I believe there is a better module on CPAN. I just
never broke down and started using it.

=head1 SEE ALSO

N/A

=head1 LICENSE AND COPYRIGHT

The "Artistic License"

URL http://dev.perl.org/licenses/artistic.html

=cut


## END
