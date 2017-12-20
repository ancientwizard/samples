#!/usr/bin/env perl

##
##   TEST SET: platform
##
##   This test set performs basic checks of the custom "platform" Perl module
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

use Test::More tests => 8;

BEGIN
{
  note '+ ----------------------------------------------------------------------- +';
  note '  UNIT UNDER TEST';
  note '+ ----------------------------------------------------------------------- +';

  use_ok 'platform';
}

our $VERSION = 0.1;

BASIC:
{
  note '+ ----------------------------------------------------------------------- +';
  note '  BASICS';
  note '+ ----------------------------------------------------------------------- +';

  my $platf = platform->new;
  my $cname = 'platform';

  #-- Create instance (Check initial status)
  #   (Tests assume this is UNIX/Linux, will fail on Windows)

  isa_ok $cname->new, $cname;
  isa_ok $cname->new, 'Property';

  ok $platf, 'Create Property Instance';
  ok ref $platf eq $cname, "Class == '$cname'";
  ok ref $platf eq $cname && ( defined $platf->isUNIX   && $platf->isUNIX   == 1 || ! defined $platf->isUNIX   ), 'Check isUNIX';
  ok ref $platf eq $cname && ( defined $platf->isWinTEL && $platf->isWinTEL == 1 || ! defined $platf->isWinTEL ), 'Check isWinTel';

  ok ref $platf eq $cname &&
   (( ! defined $platf->isUNIX   && defined $platf->isWinTEL && $platf->isWinTEL == 1) ||
    ( ! defined $platf->isWinTEL && defined $platf->isUNIX   && $platf->isUNIX   == 1)),
   'Verify UNIX is not WinTel';
}


__END__


LICENSE:

  The "Artistic License"
  URL http://dev.perl.org/licenses/artistic.html

## END
