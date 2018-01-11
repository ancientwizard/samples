#!/usr/bin/env perl

## NOTE: on Windows requires something like Strawberry Perl to be installed
##  (a litle simthing I put together for my teenager)

use strict;
use warnings;
use Carp;
use IO::Socket::INET;

my $host = shift( @ARGV ) // 'localhost';
my $port = shift( @ARGV ) // 5555;

unless ( $host )
{
  printf STDERR " ERR ->> Bad or no HOST/IP-Address\n";
  printf STDERR "\nUsage: $0 hostname port\n";
  printf STDERR " * port must be an integer\n";
  exit -1;
}

unless ( $port && $port =~ m=^[0-9]+$=x )
{
  printf STDERR " ERR ->> Bad or no PORT\n";
  printf STDERR "\nUsage: $0 hostname port\n";
  printf STDERR " * port must be an integer\n";
  exit -1;
}

my $client = IO::Socket::INET->new(
      PeerAddr  => $host
    , PeerPort  => $port
    , Proto     => 'tcp'
    , Timeout   => 4
  );

$client or croak "Failed to connect, bad host, port OR timed out\n";

printf "# Success: %s:%d ->> %s", $host, $port, <$client>;

$client->close();

exit 0;

## END