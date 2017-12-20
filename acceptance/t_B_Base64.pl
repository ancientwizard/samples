#!/usr/bin/env perl

##
##   TEST SET: Base64
##
##   This test set performs checks on the custom Base64 module which encodes
##   and decodes base64 strings.
##
##   AUTHOR: Victor Burns
##     DATE: 2012-Apr-20
##
##   CHANGES:
##    2012-Apr-20 VICB - Original release
##
##   LICENSE:
##    The "Artistic License"
##    URL http://dev.perl.org/licenses/artistic.html
##

use strict;
use warnings;
use Data::Dumper;

use Test::More tests => 20;

our $VERSION = 0.1;

BEGIN
{
  note '+ ----------------------------------------------------------------------- +';
  note '  UNIT UNDER TEST';
  note '+ ----------------------------------------------------------------------- +';

  use_ok 'Property';
  use_ok 'Base64 ';
}


BASIC:
{
  note '+ ----------------------------------------------------------------------- +';
  note '  BASICS';
  note '+ ----------------------------------------------------------------------- +';

  my $b64   = Base64->new;
  my $cname = 'Base64';
  my $ts    = time();
  my $tests = [
      [ 'BPcvEN',      1_332_932_877 ]
    , [ 'Base64',      1_521_610_424 ]
    , [ 'Scouts',     19_807_791_980 ]
    , [ '100005',     57_794_579_769 ]
    , [ 'Babies',      1_517_168_556 ]
    , [ 'Rainbow', 1_196_729_154_096 ]
    , [ 'Zero0GG', 1_750_931_292_550 ]
    , [ 'Alma',              154_010 ]
    , [ '_._._',       10_56_960_510 ]
    , [ '__...',       10_56_702_463 ]
    , [ '...__',       10_73_741_758 ]
    , [ '._._.',       10_73_479_615 ]
  ];

  #-- Create instance (Check initial status)
  new_ok 'Base64', [];
  isa_ok $b64, $cname;
  isa_ok $b64, 'Property';

  ok ref $b64 eq $cname, "Class == '$cname'";
  ok ref $b64 eq $cname && $b64->encode64(1_332_932_877) eq 'BPcvEN', 'Check before';
  ok ref $b64 eq $cname && $b64->decode64($b64->encode64($ts)) == $ts, 'Check now';

  foreach my $i ( @$tests )
  {
    is $b64->decode64($i->[0]), $i->[1], 'checking pattern ' . $i->[0];
  }
}


exit 0;


__END__


LICENSE:

  The "Artistic License"
  URL http://dev.perl.org/licenses/artistic.html

## END
