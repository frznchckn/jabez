#!/usr/bin/perl

use strict;
use String::CRC32;
use Device::SerialPort;

my $port = new Device::SerialPort ( "/dev/ttyUSB0");
$port->baudrate(230400);
$port->databits(8);
$port->stopbits(1);
$port->parity("none"); 
#$port->carrierwatch("off");
#$port->flowcontrol("none");

my $filename = shift;

my $time = `date +%y_%m_%d__%H_%M_%S`;
chomp($time);
open(LOG, ">20${time}_jabezuart_${filename}.log");

my $time = `date +'%y %m %d @ %H:%M:%S'`;
chomp($time);
printf("Time = $time\n");
printf(LOG "Log started at 20$time....\n");


my $in;
my $prev_time = 0;
my $i = 0;
while (1) {
    my $innow = $port->input; 
    if ($innow ne '') {
        $in .= $innow;
    }

    if ($in =~ /^\n([0123456789ABCDEF]{32})/) {
        my $packet = $1;
        #printf("In before = $in\n");
        $in = substr($in, 33);
        #printf("In after  = $in\n");

        my $word0 = hex(substr($packet, 0, 8));
        my $value = hex(substr($packet, 8, 8));
        my $crc   = hex(substr($packet, 16, 8));
        my $time  = hex(substr($packet, 24, 8));

        #printf("Packet %05d: 0x%08x, 0x%08x, 0x%08x, 0x%08x\n", $i, $word0, $value, $crc, $time);

        my $bte_status   = ($word0 & 0x20000000) > 0;
        my $bte_error    = ($word0 & 0x10000000) > 0;
        my $motor_tx     = ($word0 & 0x04000000) > 0;
        my $cont_b_tx    = ($word0 & 0x02000000) > 0;
        my $cont_a_tx    = ($word0 & 0x01000000) > 0;
        my $ack          = ($word0 & 0x00800000) > 0;
        my $nack         = ($word0 & 0x00400000) > 0;
        my $command      = ($word0 & 0x00200000) > 0;
        my $status       = ($word0 & 0x00100000) > 0;
        my $command_type = ($word0 >> 16) & 0xF;
        my $error_target = ($word0 >> 12) & 0x3;
        my $error_type   = ($word0 >> 8)  & 0xF;
        my $b_prime      = ($word0 & 0x00000020) > 0;
        my $a_prime      = ($word0 & 0x00000010) > 0;
        my $b_alive      = ($word0 & 0x00000002) > 0;
        my $a_alive      = ($word0 & 0x00000001) > 0;
        my $no_undastan0 = ($word0 & 0xC800C0CC) > 0; 
        
        my $no_undastan1 = 0;
        my $temp = ($motor_tx << 2) | ($cont_a_tx << 1) | ($cont_b_tx);
        if ( ($temp != 0) && ($temp != 1) && ($temp != 2) && ($temp != 4) ) {
            $no_undastan1 = 1;
        }
        
        my $diff_time = $time > $prev_time ? $time - $prev_time : $time + (0xFFFFFFFF - $prev_time);
        my $time_ms = $time * 0.0001;
        my $diff_time_ms = $diff_time * 0.0001;
        printf("%11.4f (+%7.4f ms): ", $time_ms, $diff_time_ms);
        printf(LOG "%11.4f (+%7.4f ms): ", $time_ms, $diff_time_ms);
        
        
        if ($no_undastan0 || $no_undastan1) {
            printf("No undastan: 0x%08X.", $word0);
            printf(LOG "No undastan: 0x%08X.", $word0);
        }

        if ($bte_status && !$bte_error) {
            printf("BTE sent status. PrimeA = %d, PrimeB = %d, AliveA = %d, AliveB = %d.", 
                   $a_prime, $b_prime, $a_alive, $b_alive);
            printf(LOG "BTE sent status. PrimeA = %d, PrimeB = %d, AliveA = %d, AliveB = %d.", 
                   $a_prime, $b_prime, $a_alive, $b_alive);
        }
        
        if ($bte_error) {
            my $target = "";
            if ($error_target == 0) {
                $target = "Controller A";
            } elsif ($error_target == 1) {
                $target = "Controller B";
            } elsif ($error_target == 2) {
                $target = "FDU for Controller A";
            } elsif ($error_target == 3) {
                $target = "FDU for Controller B";
            } else {
                $target = "Unknown ($error_target)";
            }

            my $type = "";
            if ($error_type == 0) {
                $type = "No error";
            } elsif ($error_type == 1) {
                $type = "Data packet corruption";
            } elsif ($error_type == 2) {
                $type = "Watchdog timeout";
            } elsif ($error_type == 3) {
                $type = "Bus stuck";
            } elsif ($error_type == 4) {
                $type = "Gray stuck";
            } elsif ($error_type == 5) {
                $type = "Gray out of order";
            } elsif ($error_type == 6) {
                $type = "Gray slow";
            } elsif ($error_type == 7) {
                $type = "Runaway task";
            } elsif ($error_type == 8) {
                $type = "Alive stuck";
            } else {
                $type = "Unknown ($error_type)";
            }
            printf("BTE sent error injection. PrimeA = %d, PrimeB = %d, AliveA = %d, AliveB = %d, Error Target = \"%s\", Error Type = \"%s\".", 
                   $a_prime, $b_prime, $a_alive, $b_alive, $target, $type);
            printf(LOG "BTE sent error injection. PrimeA = %d, PrimeB = %d, AliveA = %d, AliveB = %d, Error Target = \"%s\", Error Type = \"%s\".", 
                   $a_prime, $b_prime, $a_alive, $b_alive, $target, $type);
        }
        

        my $source = "";
        if ($motor_tx) {
            $source .= "Motor Controller";
        }
        if ($cont_a_tx) {
            $source .= "Controller A";
        }
        if ($cont_b_tx) {
            $source .= "Controller B";
        }

        my $crc_match = "";
        if ($crc == crc_calc($word0, $value)) {
            $crc_match = "matches";
        } else {
            $crc_match = "DOES NOT MATCH";
        }
        
        if ($status) {
            printf("%s sent status: Ack = %d, NAck = %d, Value = 0x%08X, CRC %s.", $source, $ack, $nack, $value, $crc_match);
            printf(LOG "%s sent status: Ack = %d, NAck = %d, Value = 0x%08X, CRC %s.", $source, $ack, $nack, $value, $crc_match);
        }
        
        if ($command) {
            my $cmd = "";
            if ($command_type == 0) {
                $cmd = "Send status";
            } elsif ($command_type == 1) {
                $cmd = "Move Backward";
            } elsif ($command_type == 2) {
                $cmd = "Move Forward";
            } else {
                $cmd = "Unkown Command ($command_type)";
            }
            if ($motor_tx) {
                printf("Motor did not send a status message. This is bad (0x%08X).", $word0);
                printf(LOG "Motor did not send a status message. This is bad (0x%08X).", $word0);
            } else {
                printf("%s sent the command \"%s\", with value 0x%08X. CRC %s.", $source, $cmd, $value, $crc_match);
                printf(LOG "%s sent the command \"%s\", with value 0x%08X. CRC %s.", $source, $cmd, $value, $crc_match);
            }
        }
        
        
        printf("\n");
        printf(LOG "\n");

        $prev_time = $time;
        $i++;
        
    }
}


sub crc_calc {
    my @val;
    $val[0] = shift;
    $val[1] = shift;
    
    my $out = bin2string(\@val);
    return crc32($out);
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
    
    return $out;
}
