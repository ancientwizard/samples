#!/usr/bin/env perl

##
## Perform tests on Config::SimpleII module
##  Normal Operational testing
##
##  Author: Victor Burns
##    Date: 2014-01-31
##
##   LICENSE:
##    The "Artistic License"
##    URL http://dev.perl.org/licenses/artistic.html
##

use strict;
use warnings;
use Data::Dumper;
use File::Temp qw| tempfile |;

use Test::More tests => 83;

our $VERSION = 0.1;

#-- Test Module loading
BEGIN
{
  note '+ ----------------------------------------------------------------------- +';
  note '  UNIT UNDER TEST';
  note '+ ----------------------------------------------------------------------- +';

  use_ok 'Property';
  use_ok 'Returned';
  use_ok 'MIME::Base64';
  use_ok 'Config::SimpleII';
}

local $Data::Dumper::Indent = 1;

#-- Test INI file
my ( $ini_fh, $ini_file ) = tempfile( UNLINK => 1, SUFFIX => '.ini' );

#-- We need the name, not the file!
close $ini_fh or 0 if $ini_fh;


END
{
  #-- House-keeping
  ##  (auto clean-up test configuration file)
  unlink $ini_file if -e $ini_file;
}


CONFIG_II_A:
{
  note '+ ----------------------------------------------------------------------- +';
  note '  Test set "A"';
  note '+ ----------------------------------------------------------------------- +';

  #--
  #--  Perform Testing
  #--

  my ( $conf );
  my ( $p_A_lst, $p_E_lst );

  #-- Create Instance and perform basic tests
  ok( $conf = Config::SimpleII->new( $ini_file ), 'Create Instance' );

  #-- Store / Retrieve Data
  foreach my $i ( 1 .. 5 )
  {
    ok $conf->param( 'Section::A.propA_' . $i, 'valueA_' . $i ), "Set PropA_$i";
    ok $conf->param( 'Section::B.propB_' . $i, 'valueB_' . $i ), "Set PropB_$i";
    ok $conf->param( 'Section::C.propC_' . $i, 'valueC_' . $i ), "Set PropC_$i";
    ok $conf->param( 'Section::D.propD_' . $i, 'The Quick Brown Fox Jumped...'), "Set PropD_$i";

    ok $conf->param( 'Section::A.propA_' . $i) eq 'valueA_' . $i, "Get PropA_$i = " . $conf->param( 'Section::A.propA_' . $i);
    ok $conf->param( 'Section::B.propB_' . $i) eq 'valueB_' . $i, "Get PropB_$i = " . $conf->param( 'Section::B.propB_' . $i);
    ok $conf->param( 'Section::C.propC_' . $i) eq 'valueC_' . $i, "Get PropC_$i = " . $conf->param( 'Section::C.propC_' . $i);
    ok $conf->param( 'Section::D.propD_' . $i) eq 'The Quick Brown Fox Jumped...', "Set PropD_$i = The Quick Brown Fox...";
  }

  ok $conf->param( 'Section::A.prop_A_ARY', [ 0, 1, 2, 3 ] ), 'Save an array';
  ok $conf->param( 'prop_E_def', [ 4, 5, 6, 7 ] ), 'Save an array in "default"';


  #-- Save and close configuration.
  ok $conf->save, 'Saving config file';
}


CONFIG_II_B:
{
  note '+ ----------------------------------------------------------------------- +';
  note '  Test set "B"';
  note '+ ----------------------------------------------------------------------- +';

  #-- Test Configuration Persistence
  my ( $conf );
  my ( $p_A_lst, $p_E_lst );

  ok( $conf = Config::SimpleII->new( $ini_file ), 'Create Instance' );

  foreach my $i ( 1 .. 5 )
  {
    ok $conf->param( 'Section::A.propA_' . $i) eq 'valueA_' . $i, "Get PropA_$i = " . $conf->param( 'Section::A.propA_' . $i);
    ok $conf->param( 'Section::B.propB_' . $i) eq 'valueB_' . $i, "Get PropB_$i = " . $conf->param( 'Section::B.propB_' . $i);
    ok $conf->param( 'Section::C.propC_' . $i) eq 'valueC_' . $i, "Get PropC_$i = " . $conf->param( 'Section::C.propC_' . $i);
    ok $conf->param( 'Section::D.propD_' . $i) eq 'The Quick Brown Fox Jumped...', "Set PropD_$i = The Quick Brown Fox...";
  }

  ok $p_A_lst = $conf->param( 'Section::A.prop_A_ARY' ), 'Restore an array';

  foreach my $i ( 0 .. 3 )
  {
    ok @ $p_A_lst && defined $p_A_lst->[$i] && $p_A_lst->[$i] == $i, 'Checking Array Contents';
  }

  ok( $p_E_lst = $conf->param( 'prop_E_def' ), 'Restore array from "default"' );

  foreach my $i ( 4 .. 7 )
  {
    ok @ $p_E_lst && defined $p_E_lst->[$i-4] && $p_E_lst->[$i-4] == $i, 'Checking Array Contents from "default"';
  }

  #-- Nonexistent Property
  ok ! defined $conf->param( 'piggy'), 'This prop does not exist';

  #-- List of params
  note Dumper $conf->param();
  is @{$conf->param}, 22,'Config has N parameters';
}


CLEANUP:
{
  note '+ ----------------------------------------------------------------------- +';
  note '  Clean-up';
  note '+ ----------------------------------------------------------------------- +';

  #-- Cleanup
  if ( open my $INI ,'<', $ini_file )
  {
    my @lines = <$INI>;
    close $INI || 0;
    note @lines;
  }

  ok(( -f $ini_file && unlink $ini_file ), 'Remove test ini config file ' );
}


ERRORS:
{
  note '+ ----------------------------------------------------------------------- +';
  note '  ERRORS & DEBUGS';
  note '+ ----------------------------------------------------------------------- +';

  #-- Error Count should be zero (0)
  ok @{Returned::get_errors()} == 0, 'Errors should be zero';

  if ( scalar @{Returned->get_errors} )
  {
    diag sprintf '- (Errors) cnt=%d', scalar @{Returned::get_errors()};

    diag $_ for @{ Returned->get_errors };
  }

  if ( scalar @{Returned->get_debugs} )
  {
    diag sprintf '- (Debug Info) cnt=%d', scalar @{Returned::get_debugs()};

    diag $_ for @{ Returned->get_debugs };
  }
}


exit 0;


__END__


LICENSE:

  The "Artistic License"
  URL http://dev.perl.org/licenses/artistic.html

## END - Test Config::SimpleII
