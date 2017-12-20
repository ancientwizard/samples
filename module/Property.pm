##
## PACKAGE Property( )
##
##  Implements a simple property Object.
##   Any unique property may be saved or restored
##   using the set and get methods. All properties
##   are stored under the {PROPS} hash.
##
##  Other classes should inherit property behaviors
##   from this class.
##
##  AUTHOR: V Burns (ancient.wizard)
##    DATE: 2004
##
##  Changes:
##    2017-12-19 VICB - Style freshened
##    2009-01-09 VICB - clear Severity 3 messages from perlcritic
##

package Property;

use strict;
use warnings;

our $VERSION = 1.0;

##
##  new( )
##
##  Create empty set of properties
##
##  post: result = set{ }
##

sub new
{
  my $self = bless { }, shift;

  $self->{ PROPS } = { };

  return $self;
}


##
##  getPropertyList( )
##  getPropertyListSorted( )
##
##  Create and return a sequence (array) of property
##   names.
##
##  post: result == sequence{ properties }
##

sub getPropertyList
{
  return [ keys %{ (shift)->{ PROPS }} ];
}

sub getPropertyListSorted
{
  return [ sort keys %{ (shift)->{ PROPS }} ];
}


##
##  getProperty( $prop )
##
##  Return the value of a given property.
##
##  post: result == if set->includes( $prop ) then value
##                  else undef
##

sub getProperty
{
  my $self = shift;
  my $prop = shift;

  return exists $self->{ PROPS }{ $prop } ? $self->{ PROPS }{ $prop } : undef;
}


##
##  setProperty( $prop, $valu )
##
##  Save the property and value pair. Existing matching
##   property is replaced with new value.
##
##  pre:  $prop defined
##  post: set->including( $prop => $valu )
##

sub setProperty
{
  my $self = shift;
  my $prop = shift;
  my $valu = shift;

  if ( defined $prop )
  {
    $self->{ PROPS }{ $prop } = $valu;
  }

  return $valu;
}

##
##  delProperty( $prop )
##
##  Delete the property if it exists
##
##  pre:  $prop defined
##  post: set = set@pre->excluding( $prop )
##

sub delProperty
{
  my $self = shift;
  my $prop = shift;

  if ( defined $prop && exists $self->{ PROPS }{ $prop } )
  {
    delete $self->{ PROPS }{ $prop };
  }

  return;
}

##
##  toString( )
##
##  Creates a string description of this object.
##
##  post: result = string description
##

sub toString
{
  my $self  = shift;
  my $props = $self->getPropertyListSorted();
  my $result;

  foreach my $prop ( @ $props )
  {
    $result .= sprintf "  %-15s : %s\n", $prop, $self->{ PROPS }{ $prop };
  }

  return $result;
}


1;

__END__

##
## Documentation
##

=pod

=head1 NAME

Property -  A generic Class structure for building other classes upon

=head1 SYNOPSIS

This module provides an Object oriented abstraction interface for building
classes upon. This class provides a few basic common methods used for debugging
and normal use. It sure beats coding these features into every class I write.

=head1 VERSION

1.0

=head1 DESCRIPTION

This package provides the following public methods.

=head1 USAGE & Examples

=head2 Code Example

=begin text

 ## Example use from another package/class

 package MyChildClass;

 ## Required modules
 use strict;
 use Carp;
 use Property;

 ## Inherit from Property Class
 use base qw{Property};


 ## Define methods etc here

 sub new
 {
   my $package = shift;
   my $self    = $package->SUPER::new();

   return( $self );
 }

 DESTROY {}


=end text

=head1 SUBROUTINES/METHODS

=over 4

=item new()

The new method constructs an instance of the defined class type.

=item getPropertyList()

The getPropertyList() method returns a sequence of defined properties in hash order.
The sequence is constructed of an array reference. The members are the names of the
defined properties.

=item getPropertyListSorted()

The getPropertyListSorted() method returns a sorted sequence of defined properties.
The sequence is constructed of an array reference. The members are the names of the 
defined properties.

=item setProperty('PROPERY_NAME','PROPERTY_VALUE')

The setProperty(...) method sets or resets the value of the property given.

=item getProperty('PROPERTY_NAME')

The getProperty(...) method returns the value of a defined property. If the property
is not defined an undef is returned.

=item delProperty('PROPERTY_NAME')

The delProperty(...) method deletes the named property if it is defined.

=item toString()

The toString() method returns a text description of the current properties and values.

=back

=head1 DIAGNOSTICS

N/A

=head1 CONFIGURATION AND ENVIRONMENT

N/A

=head1 DEPENDENCIES

N/A

=head1 INCOMPATIBILITIES

None known

=head1 AUTHOR

V Burns ( ancient dot wizard at verizon dot net )

=head1 BUGS AND LIMITATIONS

None Known

=head1 SEE ALSO

N/A

=head1 LICENSE AND COPYRIGHT

The "Artistic License"

URL http://dev.perl.org/licenses/artistic.html

=cut


## END
