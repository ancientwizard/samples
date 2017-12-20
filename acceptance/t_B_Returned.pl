#!/usr/bin/env perl

##
##   TEST SET: Returned
##
##   This test set performs function testing of the Returned module/class.
##   This class extends the Property class and therefore inherits its abilities.
##   This class is used as a error passing and propery passing class to make
##   checking of function return status quick and easy to read.
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

##  PERLCRITIC:

use strict;
use warnings;
use Data::Dumper;

use Test::More tests => 317;

our $VERSION = 0.1;

#-- Load module (test #1)
BEGIN
{
  note '+ ----------------------------------------------------------------------- +';
  note '  UNIT UNDER TEST';
  note '+ ----------------------------------------------------------------------- +';

  use_ok 'Property';
  use_ok 'Returned';
}


BASIC:
{
  note '+ ----------------------------------------------------------------------- +';
  note '  BASICS';
  note '+ ----------------------------------------------------------------------- +';

  my $pro1  = Returned->new;
  my $pro2  = Returned->new;
  my $listp;    ## Array ref
  my $cname = 'Returned';

  #-- Create instance (Check initial status)
  new_ok $cname, [];
  isa_ok $pro1, $cname;
  isa_ok $pro1, 'Property';

  ok ref $pro1 eq $cname, "Class == '$cname'";
  ok ref $pro1 eq $cname && ref $pro1->getPropertyList eq 'ARRAY', 'getPropertyList returns ARRAY ref';
  ok ref $pro1 eq $cname && ref $pro1->getPropertyList eq 'ARRAY' && scalar @{$pro1->getPropertyList} == 1, 'getPropertyList is (almost) empty';

  isa_ok $pro2, 'Property';
  ok ref $pro2 eq $cname, "Class == '$cname'";
  ok ref $pro2 eq $cname && ref $pro2->getPropertyList eq 'ARRAY', 'getPropertyList returns ARRAY ref';
  ok ref $pro2 eq $cname && ref $pro2->getPropertyList eq 'ARRAY' && scalar @{$pro2->getPropertyList} == 1, 'getPropertyList is (almost) empty';

  #-- Check and Prune (__ErrOr_CoDe___)
  ok ref $pro1 eq $cname && $pro1->getProperty('__ErrOr_CoDe___') == 0, 'Property "__ErrOr_CoDe___" == 0';
  ok ref $pro1 eq $cname && ! $pro1->delProperty('__ErrOr_CoDe___'), 'Delete Property "__ErrOr_CoDe___"';
  ok ref $pro1 eq $cname && ref $pro1->getPropertyList eq 'ARRAY' && scalar @{$pro1->getPropertyList} == 0, 'getPropertyList is empty';
  ok ref $pro2 eq $cname && $pro2->getProperty('__ErrOr_CoDe___') == 0, 'Property "__ErrOr_CoDe___" == 0';
  ok ref $pro2 eq $cname && ! $pro2->delProperty('__ErrOr_CoDe___'), 'Delete Property "__ErrOr_CoDe___"';
  ok ref $pro2 eq $cname && ref $pro2->getPropertyList eq 'ARRAY' && scalar @{$pro2->getPropertyList} == 0, 'getPropertyList is empty';

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

  #-- Returned specific
  is $cname->new([1,'no error','no debug'])->isOkay, 1, $cname . '([1, err-msg, debug ])';
  is $cname->new([0,'no error','no debug'])->isOkay, 0, $cname . '([0, err-msg, debug ])';
  is $cname->new([1,'no error','no debug'])->debug_message, 'no debug', $cname . '([1, err-msg, debug ]) (debug message)';
  is $cname->new([0,'no error','no debug'])->error_message, 'no error', $cname . '([0, err-msg, debug ]) (error message)';
  is( ref($listp = $cname->new->get_errors), 'ARRAY', 'Verify get_errors() ARRAY REF' );
  is( ref($listp = $cname->new->get_debugs), 'ARRAY', 'Verify get_debugs() ARRAY REF' );
  is $cname->new->debug_capture_off, 0, 'Verify debug_capture_off()';
  is $cname->new->debug_capture_on,  1, 'Verify debug_capture_on()';
  is @{$cname->reset_errors}, 0, 'Clear reset_errors()';
  is @{$cname->reset_debugs}, 0, 'Clear reset_debugs()';

  #-- Debug Message capture
  foreach my $bug ( 101 .. 200 )
  {
    is $pro1->debug_message( $bug ), $bug , 'Debug Message ' . $bug;
  }

  is @{$cname->get_debugs}, 100, 'Debug Message count';
  is @{$cname->get_errors},   0, 'Error Message count';

  foreach my $bug ( 301 .. 400 )
  {
   is $pro1->error_message( $bug ), $bug , 'Error Message ' . $bug;
  }

  is @{$cname->get_debugs}, 200, 'Debug Message count';
  is @{$cname->get_errors}, 100, 'Error Message count';
  is ! $pro1->debug_prune(50) && @{$pro1->get_debugs}, 50, 'Pruned debug count';
  is @{$pro1->get_errors}, 0, 'Pruned Error Count';
  is @{$pro1->reset_debugs}, 0, 'Clear reset_debugs()';

  #-- Odd cases
  is $cname->new(0)->isOkay, 0, 'Error Code only (0)';
  is $cname->new(1)->isOkay, 1, 'Error Code only (1)';
  is $cname->new(1,'error-message')->error_message, 'error-message', 'Error message   defined';
  is $cname->new(1,'error-message')->debug_message, undef, 'Debug message ! defined';
}


exit 0;


__END__


LICENSE:

  The "Artistic License"
  URL http://dev.perl.org/licenses/artistic.html

## END
