#!/usr/bin/env perl

## AUTHOR: V Burns ( ancient dot wizard at verizon dot net )
##
## LICENSE:
## The "Artistic License"
## URL http://dev.perl.org/licenses/artistic.html
##

##  PERLCRITIC:
##    clean

use strict;
use warnings;
use TAP::Harness;

our $VERSION = 1.0;

exit
  TAP::Harness->new(
    {
        verbosity => 0
      , lib       => [ '../module' ]
      , timer     => 0
    }
  )->runtests( glob 't_[A-Z]_*' )->failed;

__END__


LICENSE:

  The "Artistic License"
  URL http://dev.perl.org/licenses/artistic.html

## END
