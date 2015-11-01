#!/usr/bin/perl

use strict;
use Data::Dumper;

my %stats = ();

sub get_total_rw_n {
    my $proc_name = shift;
    return $stats{$proc_name}->{'total_read_n'} + $stats{$proc_name}->{'total_written_n'};
}

sub dump_per_proc_stats {
#     print Dumper(\%stats);
     my $total_rw_n = 0;
     foreach my $proc_name (keys %stats) {
         $total_rw_n += get_total_rw_n($proc_name) / 1000;
     }
     print sprintf("total: %d\n", $total_rw_n);
     foreach my $proc_name (sort {get_total_rw_n($b) <=> get_total_rw_n($a)} keys %stats) {
          my $s = $stats{$proc_name};
          print sprintf("%s: %d%% (R: %d, W: %d)\n",
               $proc_name, 100 * (get_total_rw_n($proc_name) / 1000) / $total_rw_n,
               $s->{'total_read_n'} / 1000, $s->{'total_written_n'} / 1000);
     }
}

sub do_per_proc_stats {
    while( my $line = <>) {
        #30 0 (expr) E n y 0 0 0 0 0
        my ($proc_name, $read_n, $written_n) = ($line =~ '\d+ \d+ \((.*)\) [a-zA-Z]+ n y \d+ (\d+) \d+ (\d+) \d+$');
        unless ($proc_name) {
            print "can't parse $line\n";
            next;
        }
        #print "$proc_name: $read_n $written_n\n";
        $stats{$proc_name} = {'total_read_n' => 0, 'total_written_n' => 0} unless defined $stats{$proc_name};
        $stats{$proc_name}->{'total_read_n'} += int($read_n);
        $stats{$proc_name}->{'total_written_n'} += int($written_n);
    }
    dump_per_proc_stats();
}

sub do_cpu_stats {
    my ($s, $u, $w) = (0, 0, 0);
    while( my $line = <STDIN>) {
        chomp $line;
        #CPU st1924 1441639925 2015/09/07 18:32:05 600 100 8 68769 10273 0 382687 9498 1 914 0 0 17056 100
        my ($stime, $utime, $wtime) = ($line =~ '^CPU .* \d+:\d+:\d+ \d+ \d+ \d+ (\d+) (\d+) \d+ \d+ (\d+) \d+ \d+ \d+ \d+ \d+ \d+$');
        die "fail of '$line'" unless ($stime && $utime && $wtime);
        $s += int($stime);
        $w += int($wtime);
        $u += int($utime);
    }
    my $m = 1e3;
    $s = int($s/$m);
    $u = int($u/$m);
    $w = int($w/$m);
    my ($date) = ($ARGV[1] =~ '^atop_(\d+)$');
    print sprintf('{"date":"%s", "t": %d, "s": %d, "u":%d, "w":%d}', $date, $s + $u + $w, $s, $u, $w) . "\n";
}

sub do_disk_stats {
    my ($i, $r, $w) = (0, 0, 0);
    my @io_ms_samples = ();
    while( my $line = <STDIN>) {
        chomp $line;
        #DSK st1924 1441573805 2015/09/07 00:10:05 600 sdp 9918 275 6552 1720 16953
        my ($io_ms, $nrsect, $nwsect) = ($line =~ '^DSK .* \d+:\d+:\d+ \d+ [a-z]+ (\d+) \d+ (\d+) \d+ (\d+)$');
        die "fail of '$line'" unless (defined $io_ms && defined $nrsect && defined $nwsect);
        $i += int($io_ms);
        $r += int($nrsect);
        $w += int($nwsect);
        push(@io_ms_samples, int($io_ms));
    }
    $i = int($i/1e6);
    $r = int($r/1e6);
    $w = int($w/1e6);
    my ($date) = ($ARGV[1] =~ '^atop_(\d+)$');
    @io_ms_samples = sort {$a <=> $b} @io_ms_samples;
    my $i50 = $io_ms_samples[int(0.5*($#io_ms_samples))] / 1e3;
    my $i95 = $io_ms_samples[int(0.95*($#io_ms_samples))] / 1e3;
    print sprintf('{"date":"%s", "i": %d, "i50": %d, "i95": %d, "r": %d, "w":%d}', $date, $i, $i50, $i95, $r, $w) . "\n";
}


sub do_net_stats {
    my ($in_total, $out_total) = (0, 0);
    while( my $line = <STDIN>) {
        chomp $line;
        #NET st1924 1441597925 2015/09/07 06:52:05 600 upper 425643 431826 3191 5301 429060 355802 429060 0
        my ($in, $out) = ($line =~ '^NET .* \d+:\d+:\d+ \d+ upper (\d+) (\d+) \d+ \d+ \d+ \d+ \d+ \d+$');
        die "fail of '$line'" unless (defined $in && defined $out);
        $in_total += int($in);
        $out_total += int($out);
    }
    $in_total = int($in_total/1e6);
    $out_total = int($out_total/1e6);
    my ($date) = ($ARGV[1] =~ '^atop_(\d+)$');
    print sprintf('{"date":"%s", "in":%d, "out":%d}', $date, $in_total, $out_total) . "\n";
}

sub do_mem_stats {
    my ($free, $cached, $buf) = (0, 0);
    while( my $line = <STDIN>) {
        chomp $line;
        #MEM st1924 1441620725 2015/09/07 13:12:05 600 4096 2040147 114190 292957 1007 212389 234
        my ($f, $c, $b) = ($line =~ '^MEM .* \d+:\d+:\d+ \d+ \d+ \d+ (\d+) (\d+) (\d+) \d+ \d+$');
        die "fail of '$line'" unless (defined $c && defined $b && defined $f);
        $free += int($f);
        $cached += int($c);
        $buf += int($b);
    }
    $free /= 1e6;
    $cached /= 1e6;
    $buf /= 1e4;
    my ($date) = ($ARGV[1] =~ '^atop_(\d+)$');
    print sprintf('{"date":"%s", "free":%d, "cached":%d, "buf":%d}', $date, $free, $cached, $buf) . "\n";
}

my $type = $ARGV[0];
if ($type eq 'pdisk') {
    do_per_proc_stats();
} elsif ($type eq 'cpu') {
    do_cpu_stats();
} elsif ($type eq 'disk') {
    do_disk_stats();
} elsif ($type eq 'net') {
    do_net_stats();
} elsif ($type eq 'mem') {
    do_mem_stats();
} else {
    die "bad type $type";
}
