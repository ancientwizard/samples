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
##    2009-Jan-09 VICB - clear Severity 3 messages from perlcritic
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
  my $package = shift;
  my $self    = { };

  $self->{PROPS} = { };

  bless( $self, $package );
  return( $self );
}

sub DESTROY { }


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
  my $self = shift;

  return( [ keys %{$self->{PROPS}} ] );
}

sub getPropertyListSorted
{
  my $self = shift;

  return( [ sort keys %{$self->{PROPS}} ] );
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

  return( defined $self->{PROPS}{$prop} ? $self->{PROPS}{$prop} : undef );
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

  if( defined( $prop ) )
  {
    $self->{PROPS}{$prop} = $valu;
  }

  return( undef );
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

  if( defined( $prop ) && defined $self->{PROPS}{$prop} )
  {
    delete $self->{PROPS}{$prop};
  }

  return( undef );
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

  foreach my $prop ( @$props )
  {
    $result .= sprintf("  %-15s : %s\n", $prop, $self->{PROPS}{$prop} );
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

V Burns (ancient.wizard@verizon.net)

=head1 BUGS AND LIMITATIONS

None Known

=head1 SEE ALSO

N/A

=head1 LICENSE AND COPYRIGHT

Copyright 2005-2014, ancient.wizard. All rights reserved.

=cut


## END