#!/usr/bin/evn perl

## NOTE: on Windows requires something like Strawberry Perl to be installed
##  (a litle simthing I put together for my teenager)

use strict;
use warnings;
use Carp;
use IO::Socket::INET;

my $port = shift( @ARGV ) // 5555;

unless ( $port && $port =~ m=^[0-9]+$=x )
{
  printf STDERR " ERR ->> Bad or no PORT\n";
  printf STDERR "\nUsage: $0 port\n";
  printf STDERR " * port must be an integer\n";
  exit -1;
}

printf " INFO ->> Listen port: %d\n", $port;

my $server = IO::Socket::INET->new(
        LocalPort   => $port
      , Proto       => 'tcp'
      , Listen      => 5
    # , ReusePort   => 1    ## Sorry not on Windows!
    );

$server or croak "Failed to start server, is the PORT inuse?\n";

while ( my $conn = $server->accept )
{
  printf "# accepted %s:%d\n", $conn->peerhost, $conn->peerport;
  print $conn "Hello World!\n";
}

exit 0;

## END