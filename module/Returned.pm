
##
## PACKAGE Returned( )
##
##  Implements a simple class for returning a set of items
##   back to a caller. This set includes error codes/status,
##   debug and error messages as well as creating any
##   arbitrary named values.
##
##  AUTHOR: V Burns (ancient.wizard)
##    DATE: 2009-Apr
##
##  Changes:
##    2011-May-19 VICB - Add support for pruning and clearing stored debug
##                       traceback messages. During huge jobs issues can arise
##                       when the Perl run's out of memory.
##                        added - debug_prune(nn)
##                        doc'd - reset_errors()
##                        doc'd - reset_debugs()
##    2009-Apr-xx VICB - First Release
##

package Returned;

use strict;
use warnings;
use Property;

##  Inherit from Property Class
use base qw| Property |;

our $VERSION = 1.0;

our $ERRORMSGS = [];
our $DEBUGMSGS = [];
our $DEBUGCAPT = 1;

##
##  new( )
##
##  Constructor
##

sub new
{
  return (shift)->SUPER::new()->_init_(@_);
}

sub _init_
{
  my $self  = shift(@_);
  my $props = \@_;

  ##  defaults
  $self->error_code( 0 );


  ## Any properties passed?
  ##   (three possibilities - no combinations!)
  ##

  if ( my $cnt = scalar @$props )
  {
    CHECK_PROP_TYPE:
    {
      ## Array Ref of stuff?
      if ( $cnt == 1 && ref $props->[0] eq 'ARRAY' )
      {
        ## assume [ error-code, error-msg, debug-message ]
        $self->error_code(    $props->[0][0] );
        $self->error_message( $props->[0][1] );
        $self->debug_message( $props->[0][2] );

        last CHECK_PROP_TYPE;
      }


      ## Hash Ref?
      if ( $cnt == 1 && ref $_[0] eq 'HASH' )
      {
        my $r = $_[0];

        ## pull standard items then use remainder as named values.

        ## ERROR_CODE
        if ( exists $r->{error_code} ) { $self->error_code( $r->{error_code} ); delete $r->{error_code}; }
        if ( exists $r->{errorcode}  ) { $self->error_code( $r->{errorcode}  ); delete $r->{errorcode};  }

        ## ERROR_MESSGE
        if ( exists $r->{error_message} ) { $self->error_message( $r->{error_message} ); delete $r->{error_message}; }
        if ( exists $r->{errormessage}  ) { $self->error_message( $r->{errormessage}  ); delete $r->{errormessage};  }
        if ( exists $r->{error_msg}     ) { $self->error_message( $r->{error_msg}     ); delete $r->{error_msg};     }
        if ( exists $r->{errormsg}      ) { $self->error_message( $r->{errormsg}      ); delete $r->{errormsg};      }

        ## DEBUG
        if ( exists $r->{debug}         ) { $self->debug_message( $r->{debug}         ); delete $r->{debug};         }
        if ( exists $r->{debugmsg}      ) { $self->debug_message( $r->{debugmsg}      ); delete $r->{debugmsg};      }
        if ( exists $r->{debug_msg}     ) { $self->debug_message( $r->{debug_msg}     ); delete $r->{debug_msg};     }
        if ( exists $r->{debugmessage}  ) { $self->debug_message( $r->{debugmessage}  ); delete $r->{debugmessage};  }
        if ( exists $r->{debug_message} ) { $self->debug_message( $r->{debug_message} ); delete $r->{debug_message}; }

        ## Everything Else is named!
        foreach my $prop ( keys %$r ) { $self->setProperty( $prop, $r->{ $prop } ); }

        last CHECK_PROP_TYPE;
      }


      ## Assume @_
      $self->error_code( $_[0] );
      $self->error_message( $_[1] );
      $self->debug_message( $_[2] );
    }
  }

  return( $self );
}


sub error_code    { return $_[0]->_setget('__ErrOr_CoDe___', $_[1]); }
sub error_message {        $_[0]->_adderr($_[1]) if( defined $_[1]);
                    return $_[0]->_setget('__ErrOr_MeSSaGe', $_[1]); }
sub debug_message {        $_[0]->_addbug($_[1]) if( $DEBUGCAPT && defined $_[1]);
                    return $_[0]->_setget('__dEbUg_MeSSaGe', $_[1]); }

sub get_errors    { return $ERRORMSGS; }
sub get_debugs    { return $DEBUGMSGS; }
sub reset_errors  { return $ERRORMSGS = []; }
sub reset_debugs  { return $DEBUGMSGS = []; }

sub isOkay
{
  my $self = shift(@_);

  return( defined $self->error_code && $self->error_code );
}

sub debug_capture_off { return $DEBUGCAPT = 0; }
sub debug_capture_on  { return $DEBUGCAPT = 1; }

sub debug_prune
{
  my $self = shift(@_);
  my $size = shift(@_);
  my $len  = scalar @$DEBUGMSGS;

  $size = 0 unless( defined $size );
  $size = 0 unless( $size =~ m/^[0-9]+$/ );

  $self->reset_errors;

  if ( $size >= $len )
  {
    $self->reset_debugs;
  }
  else
  {
    @$DEBUGMSGS = @$DEBUGMSGS[ $len-$size .. $len-1 ];
  }

  return;
}


##
##  PRIVATE METHODS
##


## ERROR's are pushed on the DEBUG and ERROR message array's
sub _adderr
{
  $_[0]->_addbug($_[1]);
  push @$ERRORMSGS, $_[1];
  return;
}

## DEBUG Message are pushed on the DEBUG message array.
sub _addbug { push @$DEBUGMSGS, $_[1]; return; }

sub _setget
{
  my ( $self, $prop, $val ) = @_;

  defined $val && $self->setProperty( $prop, $val );

  return $self->getProperty( $prop );
}


1;

__END__

##
## Documentation
##

=pod

=head1 NAME

Returned -  A generic Class structure for passing error-codes, messages and misc data

=head1 SYNOPSIS

This module provides an Object oriented abstraction interface for building
classes upon and passing misc data. It can also be used alone.

=head1 VERSION

1.0

=head1 DESCRIPTION

This package provides the following public methods.

=head1 USAGE & Examples

=head1 SUBROUTINES/METHODS

=over 4

=item new()

The new method constructs an instance of the defined class type.

 note: may be passed one of:
   [ error-code, error-message, debug-message ]

   ( error-code, error-message, debug-message ]

   {
     'error_code' => 1,    # set of { 1, 0 }
     'error_msg'  => 'something happened',
     'debug_msg'  => 'blah blah blah'
   }

=item error_code(0 | 1)

Sets an error status code. Normally something that could be tested as true/false.
Its value should have no more meaning then if it can be tested as true or false.

=item error_message('blah')

Set a message.

=item debug_message('blah')

Set a message.

=item reset_errors()

Clears the saved instance error messages from the CLASS list.

=item reset_debugs()

Clears the saved instance debug messages from the CLASS list.

=item debug_capture_off()

By default every debug message is placed on an array in the order received.
The intent is to make the array available should an error take place in the consumer
application so it may present them in a log for debugging purposes. There may be times
where too much debugging is not useful. This method disable the capture of
debug messages. Error messages are always captured.

=item debug_capture_on()

The capture of debug messages are enabled by this method after the use of
the debug_capture_off() method.

=item debug_prune(size)

Debug messages from each instance are captured into the CLASS as a list.
Over time this list can consume large amounts of memory. This method is used
to prune the saved debug list when doing so is ideal, such as when a stage
of work has completed successfully and pruning would be good before moving on
to new work. If size is omitted the debug list is emptied. If size is provided
the debug message list is pruned to include only "size" latest messages. This
method always calls reset_errors().

=back

=head1 DIAGNOSTICS

N/A

=head1 CONFIGURATION AND ENVIRONMENT

N/A

=head1 DEPENDENCIES

Property

=head1 INCOMPATIBILITIES

None known

=head1 AUTHOR

V Burns (ancient.wizard@verizon.net)

=head1 BUGS AND LIMITATIONS

None Known

=head1 SEE ALSO

Property

=head1 LICENSE AND COPYRIGHT

The "Artistic License"

URL http://dev.perl.org/licenses/artistic.html

=cut


## END
