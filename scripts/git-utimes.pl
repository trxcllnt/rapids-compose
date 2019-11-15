#!/usr/bin/perl

# git-utimes: update file times to last commit on them
# Tom Christiansen <tchrist@perl.com>

use v5.10;      # for pipe open on a list
use strict;
use warnings;
use constant DEBUG => !!$ENV{DEBUG};

my @gitlog = ( 
    qw[git log --name-only], 
    qq[--format=format:"%s" %ct %at], 
    @ARGV,
);

open(GITLOG, "-|", @gitlog)             || die "$0: Cannot open pipe from `@gitlog`: $!\n";

our $Oops = 0;
our %Seen;
$/ = ""; 

while (<GITLOG>) {
    next if /^"Merge branch/;

    s/^"(.*)" //                        || die;
    my $msg = $1; 

    s/^(\d+) (\d+)\n//gm                || die;
    my @times = ($1, $2);               # last one, others are merges

    for my $file (split /\R/) {         # I'll kill you if you put vertical whitespace in our paths
        next if $Seen{$file}++;             
        next if !-f $file;              # no longer here

        printf "atime=%s mtime=%s %s -- %s\n", 
                (map { scalar localtime $_ } @times), 
                $file, $msg,
                                        if DEBUG;

        unless (utime @times, $file) {
            print STDERR "$0: Couldn't reset utimes on $file: $!\n";
            $Oops++;
        }   
    }   

}
exit $Oops;
