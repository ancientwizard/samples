#!/usr/bin/env perl

##
##   TEST SET: Property
##
##   This test set performs function testing of the Property base class.
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

use Test::More tests => 87;

our $VERSION = 0.1;

BEGIN
{
  note '+ ----------------------------------------------------------------------- +';
  note '  UNIT UNDER TEST';
  note '+ ----------------------------------------------------------------------- +';

  use_ok 'Property';
}


BASIC:
{
  note '+ ----------------------------------------------------------------------- +';
  note '  BASICS';
  note '+ ----------------------------------------------------------------------- +';

  my $pro1  = Property->new;
  my $pro2;     ## Class inst
  my $listp;    ## Array ref
  my $cname = 'Property';

  #-- Create instance (Check initial status)
  ok $pro1, 'Create Property Instance';
  ok ref $pro1 eq $cname, "Class == '$cname'";
  ok ref $pro1 eq $cname && ref $pro1->getPropertyList eq 'ARRAY', 'getPropertyList returns ARRAY ref';
  ok ref $pro1 eq $cname && ref $pro1->getPropertyList eq 'ARRAY' && scalar @{$pro1->getPropertyList} == 0, 'getPropertyList is (almost) empty';
  ok $pro2 = new Property, 'Create Property Instance';
  ok ref $pro2 eq $cname, "Class == '$cname'";
  ok ref $pro2 eq $cname && ref $pro2->getPropertyList eq 'ARRAY', 'getPropertyList returns ARRAY ref';
  ok ref $pro2 eq $cname && ref $pro2->getPropertyList eq 'ARRAY' && scalar @{$pro2->getPropertyList} == 0, 'getPropertyList is (almost) empty';

  #-- Populate Properties & Verify
  foreach my $propn ( 1..20 )
  {
    ok ref $pro1 eq $cname && defined $pro1->setProperty('A-PROP-' . $propn, $propn ), 'Adding Property A-PROP-' . $propn;
  }

  ok ref $pro1 eq $cname && ref $pro1->getPropertyList eq 'ARRAY' && scalar @{$pro1->getPropertyList} == 20, 'getPropertyList has contents';

  foreach my $propn ( 1..20 )
  {
    ok ref $pro1 eq $cname && $pro1->getProperty('A-PROP-' . $propn, $propn ) == $propn, 'Checking Property A-PROP-' . $propn;
  }

  ok ref $pro1 eq $cname && defined( $listp = $pro1->getPropertyListSorted ) && scalar @$listp == 20, 'Get sorted Property List';

  #-- Remove some properties
  foreach my $propn ( 10 .. 20 )
  {
    ok ref $pro1 eq $cname && ! defined $pro1->delProperty('A-PROP-' . $propn ), 'Delete Property A-PROP-' . $propn;
  }

  #-- Check Remaining (Sorted)
  ok ref $pro1 eq $cname && defined( $listp = $pro1->getPropertyListSorted ) && scalar @$listp == 9, 'Get sorted Property List';

  foreach my $pidx ( 0 .. $#{$listp} )
  {
    my $pname = 'A-PROP-' . ($pidx+1);
    ok ref $pro1 eq $cname && defined $listp->[$pidx] && $listp->[$pidx] eq $pname, 'Check Property Name ' . $pname . ' == ' . $listp->[$pidx];
  }

  #-- Prune properties until empty
  foreach my $pname ( @$listp )
  {
    ok ref $pro1 eq $cname && ! defined $pro1->delProperty( $pname ), 'Delete Property ' . $pname;
  }

  ok ref $pro1 eq $cname && ref $pro1->getPropertyList eq 'ARRAY' && scalar @{$pro1->getPropertyList} == 0, 'getPropertyList is (almost) empty';

  #-- Check Instance separation
  ok ref $pro1 eq $cname && $pro1->setProperty('DEBUG','I\'m pro1') && $pro1->getProperty('DEBUG') eq 'I\'m pro1', 'set pro1 test "DEBUG" property';
  ok ref $pro2 eq $cname && $pro2->setProperty('DEBUG','I\'m pro2') && $pro2->getProperty('DEBUG') eq 'I\'m pro2', 'set pro2 test "DEBUG" property';
  ok ref $pro1 eq $cname && ref $pro2 eq $cname && $pro1->getProperty('DEBUG') ne $pro2->getProperty('DEBUG'), 'set1 pro1 DEBUG != pro2 DEBUG';
  ok ref $pro1 eq $cname && ! $pro1->delProperty('DEBUG'), 'Delete pro1 test "DEBUG" property';
  ok ref $pro2 eq $cname && ! $pro2->delProperty('DEBUG'), 'Delete pro1 test "DEBUG" property';
}


exit 0;


__END__


LICENSE:

  The "Artistic License"
  URL http://dev.perl.org/licenses/artistic.html

## END
