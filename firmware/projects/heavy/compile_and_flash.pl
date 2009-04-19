#!/usr/bin/env perl

#use strict;
use FileHandle;
use IPC::Open2;

my $output = `make 2>&1`;
print $output;

if ($output !~ /error/ && $output !~ /Error/) {
    print "No error in compiling\n";

    my $pid = open2(*Reader, *Writer, "sudo sam7" );  

    print Writer "\n";
    my $got = <Reader>;
    
    while ($got !~ /Lock Regions: 16/) {
	#print "Printing \\n\n";
	print Writer "\n";
	$got = <Reader>;
	#print "Got = $got\n";
    }


    print Writer "flash output/heavy.bin\n";
    print Writer "boot_from_flash\n";
    
    print "Programming\n";

    sleep(12);
    
    print "Done programming\n";
    
} else {
    print "Error in compiling\n";
}
