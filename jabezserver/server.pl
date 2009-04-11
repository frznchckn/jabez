#!/usr/bin/env perl

use IO::Socket;
use String::CRC32;
use strict;

my $direction = shift;
my $val1 = shift;
my $val2 = shift;
my $port = 10228;



if ($direction =~ /out/) {
    my $bcaddr = '255.255.255.255';
    
    socket(sock, PF_INET, SOCK_DGRAM, getprotobyname("udp"))
	or die "socket:$@";
    setsockopt(sock, SOL_SOCKET, SO_BROADCAST, 1)
	or die "setsockopt:$@";
    my $dest = sockaddr_in($port,inet_aton($bcaddr));
    #my @array = (0xdeadc0de, 0xdeadbeef, 0x12345678, 0xabcdef01, 0x01ab02, 0xcd03ef);

    for (my $i = 0; $i < 1; $i++) {
	
	
	my @array;
	if ($val1 eq "") {
	    @array = ($i, $i);
	} elsif ($val1 ne "" && $val2 eq "") {
	    $val1 = hex($val1);
	    @array = ($val1, $val1);
	} else {
	    $val1 = hex($val1);
	    $val2 = hex($val2);
	    @array = ($val1, $val2);
	}
	my $out = bin2string(\@array);
	my @crc = (crc32($out));
	my $crcout = bin2string(\@crc);
	$out .= $crcout;
	print "Out = $out\n";
	
	send(sock, $out, 0, $dest);
	select(undef, undef, undef, 0.200);
    }
} else {
    my $socket=new IO::Socket::INET->new(LocalPort=>$port,Proto=>'udp');

    my $text;
    my $i = 0;
    while (1) {
	$socket->recv($text,128);
	print "$i: '", $text,"'\n";
	$i++;
	
	my @decoded = string2bin($text);
	for (my $i = 0; $i <= $#decoded; $i++) {
	    printf("  - Decoded[$i] = 0x%08x\n", $decoded[$i]);
	}
    }
    
}

sub bin2string {
    my (@input) = @{(shift)};
    my $length = $#input ;
    my $out = "";
    for (my $i = 0; $i <= $length; $i++) {
	$out .= pack("c4", ($input[$i] >> 24) & 0xFF,
		     ($input[$i] >> 16) & 0xFF,
		     ($input[$i] >> 8) & 0xFF,
		     ($input[$i] >> 0) & 0xFF
	    );
    }
    
    return $out
}

sub string2bin {
    my $input = shift;
    my $length = length($input);
    my $word_pointer = 0;
    my @out;
    for (my $i = 0; $i < $length; $i++) {
	if ($i % 4 == 0) {
	    $out[$i/4] = ord(substr($input, $i, 1)) << 24;
	} elsif ($i % 4 == 1) {
	    $out[$i/4] = $out[$i/4] | (ord(substr($input, $i, 1)) << 16);
	} elsif ($i % 4 == 2) {
	    $out[$i/4] = $out[$i/4] | (ord(substr($input, $i, 1)) << 8);
	} elsif ($i % 4 == 3) {
	    $out[$i/4] = $out[$i/4] | (ord(substr($input, $i, 1)) << 0);
	}
    }
    
    return @out;
}
