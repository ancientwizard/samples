
##
##  PACKAGE: Simple::Table
##
##  DESCRIPTION: A text table formatting tool with support for a title,
##          field names and row data. It provides filed alignent and
##          other features.
##
##  AUTHOR: V Burns (ancient.wizard@verizon.net)
##    DATE: 2007 - A rewrite of a work I did about this time
##
##  CHANGES:
##    2017-12-17 VICB - Rewrite of a idea I wrote in 2007 or earlier.
##          Having a simple class for printing text tables is very useful.
##
##  PERLCRITIC:
##

package Simple::Table;

use strict;
use warnings;

## Extends Returned
use base qw| Returned |;

## Class Vars
our $VERSION = 0.1;
our $PKGNAME = __PACKAGE__;
our $INDENT  = 2;

## Constructor
sub new
{
  my $self = (shift)->SUPER::new(1);
  my $args = ref $_[0] ? shift : { @_ };

  #- Defaults
  $self->fields([]);
  $self->rows([]);
  $self->widths([]);
  $self->alignments({});

  #- INIT
  SETTINGS:
  {
    last SETTINGS unless ref $args eq 'HASH';

    $self->title(     $args->{ -TITLE  } )      if exists $args->{ -TITLE  };
    $self->addField(  $args->{ -FIELDS } )      if exists $args->{ -FIELDS };
    $self->addRow(    $args->{ -ROWS   } )      if exists $args->{ -ROWS   };

    if ( exists $args->{ -ALIGN  } && ref $args->{ -ALIGN } eq 'ARRAY' )
    {
      $self->align( @ $_ )    for @{ $args->{ -ALIGN }};
    }
  }

  return $self;
}


## addField
sub addField
{
  my $self  = shift;
  my $field = shift;
  my $flds  = $self->fields;

  ## Add one or more fields
  push @ $flds,   $field  if ref $field eq '';
  push @ $flds, @ $field  if ref $field eq 'ARRAY';

  return $field;
}


## addRow
sub addRow
{
  my $self = shift;
  my $row  = shift; #scalar @_ > 1 ? [ @_ ] : shift;
  my $rows = $self->rows;

  ## Add one or more rows
  push @ $rows, ( scalar @ $row && ref $row->[0] eq 'ARRAY' )
      ? @ $row : $row;

  return $row;
}


## compute Width
sub computeWidths
{
  my $self    = shift;
  my $fields  = $self->fields;
  my $rows    = $self->rows;
  my $widths  = $self->widths;

  foreach my $idx ( 0 .. $#$fields )
  {
    my $field = $fields->[$idx] ? length $fields->[$idx] : 0;
    my $width = $widths->[$idx] ? $widths->[$idx] : 0;

    $width = $field if $field > $width;

    foreach my $rowl ( @ $rows )
    {
      my $row = $rowl->[$idx] ? length $rowl->[$idx] : 0;

      $width = $row if $row > $width;
    }

    $widths->[$idx] = $width;
  }

  return $self;
}


# align
sub align
{
  my $self  = shift;
  my $field = shift;
  my $align = uc shift;

  ALIGN:
  {
    last ALIGN unless defined $field && defined $align;
    last ALIGN unless $align =~ m=^(LEFT|CENTER|RIGHT)$=x;

    $self->alignments->{ $field } = $align;
  }

  return $self;
}

sub toString
{
  my $self = shift;
  my $str  = '';

  TABLE:
  {
    my $title   = $self->title;
    my $fields  = $self->fields;
    my $rows    = $self->rows;
    my $widths  = $self->widths([]);
    my $align   = $self->alignments;
    my $content = [];

    last TABLE unless scalar @ $fields;

    ## Compute Widths
    $self->computeWidths;

    ## Title
    if ( $title )
    {
      push @ $content, '';
      push @ $content, sprintf "%${INDENT}s%s", '', $title;
      push @ $content, '';
    }

    ## Head
    my $FL = '';
    my $UL = '';

    foreach my $idx ( 0 .. $#$fields )
    {
      my $field = defined $fields->[$idx] ? $fields->[$idx] : '-';
      my $width = $widths->[$idx] || 10;
      $FL .= sprintf "%s%-${width}s", ( $idx ? ' ' : '' ), $field;
      $UL .= sprintf "%s%${width}s",  ( $idx ? ' ' : '' ), '=' x $width;
    }

    $FL  =~ s=\s+$==x;
    $UL  =~ s=\s+$==x;

    push @ $content, ' ' x $INDENT . $FL;
    push @ $content, ' ' x $INDENT . $UL;

    ## Body
    foreach my $row ( @ $rows )
    {
      my $RL = '';

      foreach my $fidx ( 0 .. $#$fields )
      {
        my $width = $widths->[$fidx];
        my $fv    = defined $row->[$fidx] ? $row->[$fidx] : '-';
        my $pos   = ( $fv =~ m=[a-z]=xi || $fv !~ m=[0-9]=x ) ? '-' : '';

        ALIGN:
        {
          my $align_fleld = $align->{ $fields->[$fidx] };

          last ALIGN unless defined $align_fleld;

          if ( $self->alignments->{ $fields->[$fidx] } eq 'CENTER' )
          {
            $pos = '-';
            $fv  = ' ' x int(( $width - length $fv ) / 2 ) . $fv;
            last ALIGN;
          }

          $pos =
              $align->{ $fields->[$fidx] } eq 'LEFT'  ? '-'
            : $align->{ $fields->[$fidx] } eq 'RIGHT' ? ''
            : $pos;
        }

        $RL .= sprintf "%s%${pos}${width}s", ( $fidx ? ' ' : '' ), $fv;
      }

      push @ $content, ' ' x $INDENT . $RL;
    }

    ## Final Assembly
    $str = join "\n", @ $content, '', '';
  }

  return $str;
}

sub toStringBox
{
  my $self = shift;
  my $str  = '';

  TABLE:
  {
    my $title   = $self->title;
    my $fields  = $self->fields;
    my $rows    = $self->rows;
    my $widths  = $self->widths([]);
    my $align   = $self->alignments;
    my $content = [];
    my $default = 8;

    last TABLE unless scalar @ $fields;

    ## Compute Widths
    $self->computeWidths;

    ## Title
    if ( $title )
    {
      my $width = scalar( @ $fields ) * 3 - 3;
      $width += $widths->[$_] || $default for 0 .. $#$fields;

      ## We might have a wide title bursting at the seams
      while ( length $title > $width )
      {
        my $delta = length( $title ) - $width;
        my $width_indexs = [];

        while ( $delta )
        {
          for my $idx ( 0 .. $#$fields )
          {
            push @ $width_indexs, $idx;
            last unless --$delta;
          }
        }

        $widths->[$_]++ for @ $width_indexs;

        $width = scalar( @ $fields ) * 3 - 3;
        $width += $widths->[$_] || $default for 0 .. $#$fields;
      }

      push @ $content, ' +-' . '-' x $width . '-+';
      push @ $content, sprintf " | %-${width}s |", $title;
    }

    ## Head
    my $FL = [];
    my $UL = [];
    my $divider;

    foreach my $idx ( 0 .. $#$fields )
    {
      my $field = defined $fields->[$idx] ? $fields->[$idx] : '-';
      my $width = $widths->[$idx] || $default;
      push @ $FL, sprintf " %-${width}s ", $field;
      push @ $UL, sprintf "-%${width}s-",  '-' x $width;
    }

    $divider = ' +' . join( '+', @ $UL ) . '+';

    push @ $content, $divider;
    push @ $content, ' |' . join( '|', @ $FL ) . '|';
    push @ $content, $divider;

    ## Body
    foreach my $row ( @ $rows )
    {
      my $RL = [];

      foreach my $fidx ( 0 .. $#$fields )
      {
        my $width = $widths->[$fidx] || $default;
        my $fv    = defined $row->[$fidx] ? $row->[$fidx] : '-';
        my $pos   = ( $fv =~ m=[a-z]=xi || $fv !~ m=[0-9]=x ) ? '-' : '';

        ALIGN:
        {
          my $align_fleld = $align->{ $fields->[$fidx] };

          last ALIGN unless defined $align_fleld;

          if ( $self->alignments->{ $fields->[$fidx] } eq 'CENTER' )
          {
            $pos = '-';
            $fv  = ' ' x int(( $width - length $fv ) / 2 ) . $fv;
            last ALIGN;
          }

          $pos =
              $align->{ $fields->[$fidx] } eq 'LEFT'  ? '-'
            : $align->{ $fields->[$fidx] } eq 'RIGHT' ? ''
            : $pos;
        }

        push @ $RL, sprintf " %${pos}${width}s ", $fv;
      }

      push @ $content, ' |' . join( '|', @ $RL ) . '|';
    }

    ## Final Assembly
    $str = join "\n", '', @ $content, $divider, '', '';
  }

  return $str;
}

## Properties
sub title       { return $_[0]->_setget('_TITLE_______', $_[1]) }
sub fields      { return $_[0]->_setget('_FIELDS______', $_[1]) }
sub rows        { return $_[0]->_setget('_ROWS________', $_[1]) }
sub widths      { return $_[0]->_setget('_WIDTHS______', $_[1]) }
sub alignments  { return $_[0]->_setget('_ALIGNMENTS__', $_[1]) }


1;

__END__

##
## Documentation
##

=pod

=head1 NAME

Simple::Table - A text table formatting tool

=head1 VERSION

0.1

=head1 DESCRIPTION

A text based auto-sizing formatting tool for displaying tables of data that are
representable as Fields and Rows.


=head1 SYNOPSIS

 use strict;
 use warnings;
 use Simple::Table;

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

 ## The output is seen in the next section
 ##  (EXAMPLE TABLES)
 print $planitary_data->toString;
 print $planitary_data->toStringBox;

 exit 0;


=head1 EXAMPLE TABLES


  Solar System Data

  Object  Distance Period/Rev Period/Rot Diameter Mass   Density
  ======= ======== ========== ========== ======== ====== =======
  Mercury     57.9      88.0d        59d    4,879   0.06     5.4
  Venus      108.2     224.7d       243d   12,104   0.82     5.2
  Earth      149.6     365.3d   23h56m4s   12,756      1     5.5
  Mars       227.9     687.0d  24h37m23s    6,794   0.11     3.9
  Jupiter    778.4      11.9y   9h50m30s  142,984 317.83     1.3
  Saturn   1,426.7      29.5y     10h14m  120,536  95.16     0.7
  Uranus   2,871.0      84.0y     17h14m   51,118  14.54     1.3
  Neptune  4,498.3     164.8y        16h   49,528  17.15     1.8


 +----------------------------------------------------------------------------+
 | Solar System Data                                                          |
 +---------+----------+------------+------------+----------+--------+---------+
 | Object  | Distance | Period/Rev | Period/Rot | Diameter | Mass   | Density |
 +---------+----------+------------+------------+----------+--------+---------+
 | Mercury |     57.9 |      88.0d |        59d |    4,879 |   0.06 |     5.4 |
 | Venus   |    108.2 |     224.7d |       243d |   12,104 |   0.82 |     5.2 |
 | Earth   |    149.6 |     365.3d |   23h56m4s |   12,756 |      1 |     5.5 |
 | Mars    |    227.9 |     687.0d |  24h37m23s |    6,794 |   0.11 |     3.9 |
 | Jupiter |    778.4 |      11.9y |   9h50m30s |  142,984 | 317.83 |     1.3 |
 | Saturn  |  1,426.7 |      29.5y |     10h14m |  120,536 |  95.16 |     0.7 |
 | Uranus  |  2,871.0 |      84.0y |     17h14m |   51,118 |  14.54 |     1.3 |
 | Neptune |  4,498.3 |     164.8y |        16h |   49,528 |  17.15 |     1.8 |
 +---------+----------+------------+------------+----------+--------+---------+


=head1 SUBROUTINES/METHODS

The classes public interface

=over 4

=item ->new()

The constructor for this class. Requires no arguments, but i capable of accepting all data needed
to define a tables contents and configuration.

 Accepts these arguments
 (SEE SYNOPSIS)

 -TITLE     => 'string'
 -FIELDS    => [ qw| Array of field names | ]
 -ROWS      => [ [ 'array', 'of', 'row', 'values' ], ... ]
 -ALIGN     => [ [ 'Field' => 'LEFT|RIGHT|CENTER' ]]

=item ->addField()

Adds a Field label to the table. Fields are display in the order thay are added.
All fields should be defined before row data is added.

 $table->addField( [ qw| One OR more | ] );

=item ->addRow()

Adds one or more rows to the table. Row data should be added after fields are defined.
Row data is displayed in the order it is added. Row data wider than Fields exist will be
ignored and not displayed in output.

=item ->computeWidths()

Provided for visibiity and unnecessary for the consumer to call. It is used to
automatically compute field widths and done so when a toString method is used.

=item ->align()

Sets a Fields alignment as LEFT, RIGHT or CENTER to override the fields default alignment
guessed based on the value in the field.

 $table->align( 'Field-name' => 'CENTER' );

=item ->toString()

Returns a formatted string based on the table objects current state

See: EXAMPLES

=item ->toStringBox()

Returns a formatted boxed string based on the table objects current state

See: EXAMPLES

=item ->title()

Used to set and/or get the tables title.

 $table->title( 'The best title ever!' );

=item ->fields()

Returns an array reference of the defined fields. The consumer must refrain from
changing the array that is returned. This method is provided for visibility but it is
otherwise unnecessary for use and normal operation.

=item ->rows()

Returns an array of arrays of the defined ROW data. The consumer must refrain from
changing the array that is returned. This method is provided for visibility but it is
otherwise unnecessary for use and normal operation.

=item ->widths()

Returns an array or data defining the automaticly detected field widths. The WIDTH's
are determined when the ->computeWidths() method is used but after all fields and
data have been defined. This method is provided for visibility but it is
otherwise unnecessary for use and normal operation.

=item ->alignments()

Returns an has reference of the defined fields having overidden alignment hints.
The consumer must refrain from changing the array that is returned. This method is
provided for visibility but it is otherwise unnecessary for use and normal operation.

=back

=head1 CONFIGURATION AND ENVIRONMENT

None

=head1 DEPENDENCIES

Returned, Property

=head1 DIAGNOSTICS

t_B_Simple_Table.pl

=head1 INCOMPATIBILITIES

None

=head1 BUGS AND LIMITATIONS

It's Simple, I'm sure it cannot be everything to everyone!

=head1 AUTHOR

V Burns ( ancient dot wizard at verizon dot net )

=head1 LICENSE AND COPYRIGHT

  The "Artistic License"
  URL http://dev.perl.org/licenses/artistic.html

=cut

## END
