
##
## PACKAGE Base64( )
##
##  Implements a simple class for encoding integer
##   numbers into Base64.
##
##  NOTE: The class provides two character sets to encode with.
##        The alternate/custom set produces strings that should be
##        suitable as file names etc. I.E. plus(+) and slashes(/)
##        have special meaning and therefore not used.
##
##  AUTHOR: V Burns (ancient.wizard)
##    DATE: 2009-Apr
##
##  Changes:
##    2012-Apr-03 VICB - Corrected bug in _decode() method.
##    2009-Apr-xx VICB - First Release
##

package Base64;

use strict;
use warnings;
use Property;


##  Inherit from Property Class
use base qw| Property |;

our $VERSION = 1.0;

our $BASE64_STANDARD;
our $BASE64_CUSTOM;
our $BASE64_MAP;


sub BEGIN
{
  $BASE64_STANDARD = [ 'A'..'Z', 'a'..'z', '0'..'9', '+', '/' ];
  $BASE64_CUSTOM   = [ 'A'..'Z', 'a'..'z', '0'..'9', '_', '.' ];  # safe for file names
  $BASE64_MAP      = {};

  for my $i ( 0 .. $#$BASE64_STANDARD )
  {
    $BASE64_MAP->{$BASE64_STANDARD->[$i]} = $i;
  }

  ## Custom Cases
  $BASE64_MAP->{'_'} = $BASE64_MAP->{'+'};
  $BASE64_MAP->{'.'} = $BASE64_MAP->{'/'};

  return;
}


##
##  new( )
##
##  Constructor
##

sub new
{
  return (shift)->SUPER::new();
}


sub encode64_standard { return (shift)->_encode64($BASE64_STANDARD, @_); }
sub encode64_custom   { return (shift)->_encode64($BASE64_CUSTOM, @_); }
sub encode64          { return (shift)->_encode64($BASE64_CUSTOM, @_); }

sub decode64          { return (shift)->_decode64(@_); }


sub _encode64
{
  my $self   = shift;
  my $code64 = shift;
  my $in_num = shift;

  my $base64num = '';


  INPUT_TYPE:
  {
    ## Single integer
    if ( defined $in_num && '' eq ref $in_num )
    {
      $base64num = $self->_encode64_i( $code64, $in_num );
      last INPUT_TYPE;
    }

    ## Array of integers
    if ( defined $in_num && 'ARRAY' eq ref $in_num )
    {
      foreach my $i ( reverse @ $in_num )
      {
        $base64num .= $self->_encode64_i($code64, $i );
      }

      last INPUT_TYPE;
    }
  }

  return $base64num;
}

sub _encode64_i
{
  my $self   = shift;
  my $code64 = shift;
  my $curRem = shift;

  my $curDig;
  my $base64num = '';

  while (( $base64num eq '' ) || ( $curRem > 0 ))
  {
    $curDig    = ($curRem % 64);
    $base64num = $code64->[$curDig] . $base64num;
    $curRem    = int($curRem / 64);
  }

  return $base64num;
}


sub _decode64
{
  my $self   = shift;
  my $b64s   = shift;
  my $numbr  = 0;
  my $c;

  my $ichars = [ split //, $b64s ];

  while ( defined( $c = shift @ $ichars ))
  {
    $numbr *= 64;
    $numbr += $BASE64_MAP->{$c};
  }

  return $numbr;
}


1;

__END__

##
## Documentation
##

=pod

=head1 NAME

Base64 -  A generic Class for performing base64 encode/decode using integers

=head1 SYNOPSIS

Performs base64 encode and decode. Provides an alternate charcter set useable in file names.

=head1 VERSION

1.0

=head1 DESCRIPTION

This package provides the following public methods.

=head1 USAGE & Examples

=head1 SUBROUTINES/METHODS

=over 4

=item new()

The new method constructs an instance of the defined class type.

 use Base64;
 my $b64 = new Base64;

 ## Filename safe (does not use '.' || '/')
 printf "%s\n", $b64->encode64(time);
 printf "%s\n", $b64->encode64(5672819042);

 ## Standard Encoding
 printf "%s\n", $b64->encode64_standard(31456871728364);

 ## Always True
 my $ts = time;
 if ( $ts == $b64->decode64($b64->encode64($ts)))
 {
    ...
 }

 if ( $ts == $b64->decode64($b64->encode64_standard($ts)))
 {
    ...
 }

=item encode64(something)

Returns a custom base64 string of the input number/string.

  '_'  used in the place of '+'
  '.'  used in the place of '/'

=item decode64(base64_string)

Returns the decoded value.

=item encode64_standard(something)

Returns a standard base64 string of the input number/string.

=item decode64(base64_string)

Returns the decoded value of a standard base64 encoded string.

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

V Burns (ancient.wizard@verizon.net)

=head1 BUGS AND LIMITATIONS

Limited to operation using integers.

=head1 SEE ALSO

Property

=head1 LICENSE AND COPYRIGHT

The "Artistic License"

URL http://dev.perl.org/licenses/artistic.html

=cut


## END
