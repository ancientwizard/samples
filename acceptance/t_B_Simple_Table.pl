#!/usr/bin/env perl

##
##   TEST SET: Simple::Table
##
##   This test set performs basic checks of the custom "Simple::Table" Perl module
##
##   AUTHOR: Victor Burns
##    DATE: 2007 - A rewrite of a work I did about this time
##
##   CHANGES:
##    2017-Apr-20 VICB - Original release
##
##   LICENSE:
##    The "Artistic License"
##    URL http://dev.perl.org/licenses/artistic.html
##

##  PERLCRITIC:
##

use strict;
use warnings;
use Data::Dumper;

use Test::More tests => 22;

BEGIN
{
  note '+ ----------------------------------------------------------------------- +';
  note '  UNIT UNDER TEST';
  note '+ ----------------------------------------------------------------------- +';

  use_ok 'Property';
  use_ok 'Returned';
  use_ok 'Simple::Table';
}

our $VERSION = 0.1;

local $Data::Dumper::Indent = 1;

BASIC:
{
  note '+ ----------------------------------------------------------------------- +';
  note '  Basic Construction';
  note '+ ----------------------------------------------------------------------- +';

  isa_ok( Simple::Table->new,           'Simple::Table' );
  ok(     Simple::Table->new->isOkay,   'table->isOkay' );

  my $table = Simple::Table->new;

  is $table->title( 'Price List' ), 'Price List',       'table->title( Price List )';

  is $table->addField( 'Description' ), 'Description',  'table->addField( Description )';
  is $table->addField( 'Qty'         ), 'Qty',          'table->addFIeld( Qty )';
  is $table->addField( 'Price'       ), 'Price',        'table->addField( Price )';

  ok $table->addRow( [ 'Eggs/Carton',    18,   '$3.15' ] ), 'table->addRow(Eggs,...)';
  ok $table->addRow( [ 'Milk/Gal',        1,   '$2.35' ] ), 'table->addRow(Milk,...)';
  ok $table->addRow( [ 'Speaker set L/R', 1, '$178.22' ] ), 'table->addRow(Stuf,...)';
  ok $table->addRow( [ 'Green-Beans',    12,   '$1.32' ] ), 'table->addRow(Bean,...)';

  is $table->toString, <<'TABLE', 'table->toString';

  Price List

  Description     Qty Price
  =============== === =======
  Eggs/Carton      18   $3.15
  Milk/Gal          1   $2.35
  Speaker set L/R   1 $178.22
  Green-Beans      12   $1.32

TABLE

# note Dumper $table;

  note $table->toString;
  note $table->toStringBox;
}


ALIGNMENT:
{
  note '+ ----------------------------------------------------------------------- +';
  note '  Alignment';
  note '+ ----------------------------------------------------------------------- +';

  my $table = Simple::Table->new(
        -TITLE    => 'The planets have aligned'
      , -FIELDS   => [ 'Field A', 'Field B' ]
      , -ROWS     => [
          [ 'A String', 1 ]
        , [ '$500.01',  2 ]  # smells like dollars
        , [ 9876.2,     3 ]
      ]
    );

  is $table->title,       'The planets have aligned',         'table->title';
  is $table->fields->[0], 'Field A',                          'table->fields[0]';
  is $table->fields->[1], 'Field B',                          'table->fields[1]';
  is scalar(@{$table->fields}), 2,                            'table->fields';

  note $table->toString;

  is $table->toStringBox, <<'NORMAL',   'table->toStringBox  (NORMAL)';

 +--------------------------+
 | The planets have aligned |
 +-------------+------------+
 | Field A     | Field B    |
 +-------------+------------+
 | A String    |          1 |
 |     $500.01 |          2 |
 |      9876.2 |          3 |
 +-------------+------------+

NORMAL

  $table->align( 'Field A', 'CENTER' );
  is $table->toStringBox, <<'CENTER',   'table->toStringBox  (CENTER)';

 +--------------------------+
 | The planets have aligned |
 +-------------+------------+
 | Field A     | Field B    |
 +-------------+------------+
 |  A String   |          1 |
 |   $500.01   |          2 |
 |   9876.2    |          3 |
 +-------------+------------+

CENTER

  $table->align( 'Field A', 'LEFT' );
  is $table->toStringBox, <<'LEFT',   'table->toStringBox  (LEFT)';

 +--------------------------+
 | The planets have aligned |
 +-------------+------------+
 | Field A     | Field B    |
 +-------------+------------+
 | A String    |          1 |
 | $500.01     |          2 |
 | 9876.2      |          3 |
 +-------------+------------+

LEFT

  $table->align( 'Field A', 'RIGHT' );
  is $table->toStringBox, <<'RIGHT',   'table->toStringBox  (RIGHT)';

 +--------------------------+
 | The planets have aligned |
 +-------------+------------+
 | Field A     | Field B    |
 +-------------+------------+
 |    A String |          1 |
 |     $500.01 |          2 |
 |      9876.2 |          3 |
 +-------------+------------+

RIGHT
}


EXAMPLE:
{
  note '+ ----------------------------------------------------------------------- +';
  note '  Examples';
  note '+ ----------------------------------------------------------------------- +';

  my $planitary_data
    = Simple::Table->new(
        -TITLE    => 'Solar System Data'
      , -FIELDS   => [ 'Object', 'Distance', 'Period/Rev', 'Period/Rot', 'Diameter', 'Mass', 'Density' ]
      , -ROWS     =>
      [
        [ 'Mercury',    '57.9',    '88.0d',   '59d',        '4,879',   0.06, 5.4 ]
      , [ 'Venus',     '108.2',   '224.7d',  '243d',       '12,104',   0.82, 5.2 ]
      , [ 'Earth',     '149.6',   '365.3d',  '23h56m4s',   '12,756',   1.00, 5.5 ]
      , [ 'Mars',      '227.9',   '687.0d',  '24h37m23s',   '6,794',   0.11, 3.9 ]
      , [ 'Jupiter',   '778.4',    '11.9y',   '9h50m30s', '142,984', 317.83, 1.3 ]
      , [ 'Saturn',  '1,426.7',    '29.5y',  '10h14m',    '120,536',  95.16, 0.7 ]
      , [ 'Uranus',  '2,871.0',    '84.0y',  '17h14m',     '51,118',  14.54, 1.3 ]
      , [ 'Neptune', '4,498.3',   '164.8y',  '16h',        '49,528',  17.15, 1.8 ]
      ]
      , -ALIGN    => [[ 'Period/Rev' => 'RIGHT' ],[ 'Period/Rot' => 'RIGHT' ]]
    );

 note $planitary_data->toString;
 note $planitary_data->toStringBox;

 $planitary_data->addField([ 'A', 'B', 'C' ]);
 $planitary_data->align( 'Object' => 'CENTER' );
 note $planitary_data->toStringBox;
}


exit 0;

__END__


LICENSE:

  The "Artistic License"
  URL http://dev.perl.org/licenses/artistic.html

## END
