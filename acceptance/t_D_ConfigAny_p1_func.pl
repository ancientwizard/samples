#!/usr/bin/env perl

##
## Perform tests on Config::Any module
##  (PART 1) - Normal Operational testing
##
##  Author: Victor Burns
##    Date: 2013-11-20
##
##   LICENSE:
##    The "Artistic License"
##    URL http://dev.perl.org/licenses/artistic.html
##

use strict;
use warnings;
use Carp;
use POSIX;
use Data::Dumper;
use File::Temp qw| tempfile |;

use Test::More;

our $VERSION = 0.1;

#-- Test Module loading
BEGIN
{
  note '+ ----------------------------------------------------------------------- +';
  note '  UNIT UNDER TEST';
  note '+ ----------------------------------------------------------------------- +';

  use_ok 'Returned';
  use_ok 'Sys::Hostname';

  # Data::UUID
  GOOD_UUID:
  {
    eval { require Data::UUID; } && last GOOD_UUID;

    diag 'Requires Data::UUID (not found)';
    done_testing();
    exit 0;
  }

  GOOD_MYSQL:
  {
    eval { require DBD::mysql; } && last GOOD_MYSQL;

    diag 'Requires DBD::mysql for full testing (not found)';
    done_testing();
    exit 0;
  }

  use_ok 'Config::SimpleII';
  use_ok 'Config::Any';
}


BASIC:
{
  note '+ ----------------------------------------------------------------------- +';
  note '  BASICS';
  note '+ ----------------------------------------------------------------------- +';

  #-- Test Variables
  my ( $mod_A, $mod_B, $mod_C, $mod_D, $mod_E );
  my ( $p_A_lst, $p_E_lst );

  my ( $ini_file ) = ( tempfile UNLINK => 1, SUFFIX => '.ini' )[1];
  my $targetName = Data::UUID->new->create_from_name_str( Data::UUID::NameSpace_DNS, hostname) . '-TEST';
  my $dsn = 'DBI:mysql(PrintWarn=>1,PrintError=>0,Taint=>1):database=test;host=localhost;port=3306:user=test';

  #-- Define Configuration File
  ok ! defined Config::Any::Pathname(), 'Default Configuration file undefined';
  ok   defined Config::Any::Pathname($ini_file), 'Set Configuration pathname';
  ok Config::Any::Pathname() eq $ini_file, 'Check Configuration';

  #-- Define TARGET
  ok ! defined Config::Any::Target(), 'Default Host Name Target';
  is Config::Any::Target($targetName), $targetName, 'Set Host Name Target';
  is Config::Any::Target(), $targetName, 'Check Host Name Target';


  #--
  #--  PART #1 - Perform Testing with File backing ONLY
  #--  PART #2 - Perform Testing with mySQL enabled
  #--

  foreach my $part ( 1, 2 )
  {

    #-- Enable DB For Testing PART 2
    ok( Config::Any::openDB( $dsn ), 'Config::Any::openDB("DSN")') if $part == 2;

    #-- Create Instance and perform basic tests
    ok( $mod_A = Config::Any->new( 'Test::ModuleA' ), 'Create Instance A' );
    ok( $mod_B = Config::Any->new( 'Test::ModuleB' ), 'Create Instance B' );
    ok( $mod_C = Config::Any->new( 'Test::ModuleC' ), 'Create Instance C' );
    ok( $mod_D = Config::Any->new( 'Test::ModuleD' ), 'Create Instance D' );
    ok( $mod_E = Config::Any->new(                 ), 'Create Instance "default"' );
    ok( $mod_A->module eq 'Test::ModuleA', 'Module A Name check' );
    ok( $mod_B->module eq 'Test::ModuleB', 'Module B Name check' );
    ok( $mod_C->module eq 'Test::ModuleC', 'Module C Name check' );
    ok( $mod_D->module eq 'Test::ModuleD', 'Module D Name check' );
    ok( ! defined $mod_E->module, 'Module E Name check as undef' );


    #-- Store / Retrieve Data
    foreach my $i ( 1 .. 5 )
    {
      ok( $mod_A->param( 'propA_' . $i, 'valueA_' . $i ), "Set PropA_$i");
      ok( $mod_B->param( 'propB_' . $i, 'valueB_' . $i ), "Set PropB_$i");
      ok( $mod_C->param( 'propC_' . $i, 'valueC_' . $i ), "Set PropC_$i");
      ok( $mod_D->param( 'propD_' . $i, 'The Quick Brown Fox Jumped...'), "Set PropD_$i");

      ok( $mod_A->param( 'propA_' . $i) eq 'valueA_' . $i, "Get PropA_$i = " . $mod_A->param( 'propA_' . $i));
      ok( $mod_B->param( 'propB_' . $i) eq 'valueB_' . $i, "Get PropB_$i = " . $mod_B->param( 'propB_' . $i));
      ok( $mod_C->param( 'propC_' . $i) eq 'valueC_' . $i, "Get PropC_$i = " . $mod_C->param( 'propC_' . $i));
      ok( $mod_D->param( 'propD_' . $i) eq 'The Quick Brown Fox Jumped...', "Set PropD_$i = The Quick Brown Fox...");
    }

    ok( $mod_A->param( 'prop_A_ARY', [ 0, 1, 2, 3 ] ), 'Save an array' );
    ok( $mod_E->param( 'prop_E_def', [ 4, 5, 6, 7 ] ), 'Save an array in "default"');


    #-- Test Confirguration Persistence
    $mod_A = $mod_B = $mod_C = $mod_C = $mod_E = undef;
    ok( Config::Any::closeDB(), 'Close DB' ) if $part == 2;
    ok( Config::Any::openDB(), 'Config::Any::openDB()') if $part == 2;

    ok( $mod_A = Config::Any->new( 'Test::ModuleA' ), 'Create Instance A' );
    ok( $mod_B = Config::Any->new( 'Test::ModuleB' ), 'Create Instance B' );
    ok( $mod_C = Config::Any->new( 'Test::ModuleC' ), 'Create Instance C' );
    ok( $mod_D = Config::Any->new( 'Test::ModuleD' ), 'Create Instance D' );
    ok( $mod_E = Config::Any->new(                 ), 'Create Instance "default"' );

    foreach my $i ( 1 .. 5 )
    {
      ok( $mod_A->param( 'propA_' . $i) eq 'valueA_' . $i, "Get PropA_$i = " . $mod_A->param( 'propA_' . $i));
      ok( $mod_B->param( 'propB_' . $i) eq 'valueB_' . $i, "Get PropB_$i = " . $mod_B->param( 'propB_' . $i));
      ok( $mod_C->param( 'propC_' . $i) eq 'valueC_' . $i, "Get PropC_$i = " . $mod_C->param( 'propC_' . $i));
      ok( $mod_D->param( 'propD_' . $i) eq 'The Quick Brown Fox Jumped...', "Set PropD_$i = The Quick Brown Fox...");
    }

    ok( $p_A_lst = $mod_A->param( 'prop_A_ARY' ), 'Restore an array' );
    foreach my $i ( 0 .. 3 )
    {
      ok( scalar @$p_A_lst && defined $p_A_lst->[$i] && $p_A_lst->[$i] == $i, 'Checking Array Contents' );
    }

    ok( $p_E_lst = $mod_E->param( 'prop_E_def' ), 'Restore array from "default"' );
    foreach my $i ( 4 .. 7 )
    {
      ok( scalar @$p_E_lst && defined $p_E_lst->[$i-4] && $p_E_lst->[$i-4] == $i, 'Checking Array Contents from "default"' );
    }

    #-- Nonexistent Property
    ok( ! defined $mod_A->param( 'piggy'), 'This prop does not exist');

    #-- Do we have five instances?
    ok( $Config::Any::C_COUNT == 5, 'Instance count is 5 (five instances');

    #-- Destroy TEST Config Instances
    $mod_A = undef;
    $mod_B = undef;
    $mod_C = undef;
    $mod_D = undef;
    $mod_E = undef;

    #-- Do we have zero instances?
    is( $Config::Any::C_COUNT, 0, 'Instance count is 0 (no instances');

    #-- Cleanup
    # diag( system('cat /tmp/test-config.ini 1>&2'));
    ok(( -f $ini_file && unlink $ini_file ), 'Remove test ini config file ' . "PART($part)");

  } # END Part 1/2


  #-- Drop Test Table and Close DB
  ok( Config::Any::DropTable(), 'DROP the Configuration Testing Table');
  ok( Config::Any::closeDB(), 'Close DB' );

  #-- Error Count should be zero (0)
  ok( scalar @{Returned::get_errors()} == 0, 'Errors should be zero' );

  if( scalar @{Returned::get_errors()} )
  {
    diag(sprintf '- (Errors) cnt=%d', scalar @{Returned::get_errors()});

    foreach my $i (@{Returned::get_errors()}) { diag( $i ); }
  }

  if( scalar @{Returned::get_debugs()} )
  {
    diag(sprintf '- (Debug Info) cnt=%d', scalar @{Returned::get_debugs()});

    foreach my $i (@{Returned::get_debugs()}) { diag ( $i ); }
  }
}

done_testing();

exit 0;


__END__


LICENSE:

  The "Artistic License"
  URL http://dev.perl.org/licenses/artistic.html

## END - Test Config::Any
