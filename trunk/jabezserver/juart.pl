#!/usr/bin/perl

use strict;

open(FILE, "kermit jabezuart.ksc | sed 's/*/\n/g' |");
while (my $line = <FILE>) {
    print "Line = $line\n";
}
