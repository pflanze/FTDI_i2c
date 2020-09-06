#!/usr/bin/perl


Helps generating 

use strict;
use warnings;

#tesrting only
# use Data::Dumper qw(Dumper);

#replace with your own directory
my $directory = '/media/sf_C/FTDI/i2cSoftware';

#gathering file *.c *.h names
my ($refC, $refH) = &filling(); 
my @cfiles = @$refC ;
my @hfiles = @$refH;

#creating h files, and prototpes
&balanceCH(\@cfiles, \@hfiles);

exit(0);

#Fills arrays with '.c' and '.h' files
sub filling{
    my @cfiles;
    my @hfiles;
    opendir (DIR, $directory) or die $!;

    while (my $file = readdir(DIR)) {
        if(($file =~ /[.]{1}c$/) && ($file !~ /main\.c/)){
            # print "$file\n";
            push(@cfiles, $file);
        }
        elsif($file =~ /[.]{1}h$/){
            push(@hfiles, $file);
            # print "$file\n";
        }
        else{next;}
    }
    close(DIR);
    return (\@cfiles, \@hfiles)
}

#retuns names of the function prototypes required in the *.h file
sub funcName{
    my $filename = $_[0];
    open(INPUT, "<$filename") or die $!;;
    my @func;
    while (<INPUT>) {
        if (/(^(\w){1,}.*)+\(\w{1,}\)+{+(.*)$/) {
            my ($found, $rest) = split(/{/, $_);
            # print("$found\n");
            push(@func, "$found;");
        }
    }
    close(INPUT);
    return @func;
}

#create coresponding h files
#if does not exist: create and fill
#if it does: cross reference and append new functions
sub balanceCH{
    my @cfiles = @{$_[0]};
    my @hfiles = @{$_[1]};

    foreach my $cName (@cfiles){
        (my $hName = $cName) =~ s/.c/.h/;
        # print("$hName\n");
        my @cfunctions = &funcName($cName);
        if(grep(!/^$hName/i, @hfiles)){#does the h file exist
            open(OUTPUT, ">>$hName") or die $!;
            print OUTPUT "$_\n" for @functions;
            close(OUTPUT);
        }
        else{#compare function content
            my @hfunctions = &funcName($hName);
            my @newlines = "";
            foreach my $cline (@cfunctions){
                if(grep(!/^$cline/i, @hfunctions)){
                    push($cline, @newlines);
                }
            }
            open(OUTPUT, ">>$hName") or die $!;
            print OUTPUT "$_\n" for @newlines;
            close(OUTPUT);
        }
    }
}

#create function to write to file 
#inputs: $var, @array

__END__

How it works:
1.- Open specified directory
2.- Check existance of: c and h files
3.- Check 1:1 relation. Else: create coresponding h files (warn if h and not c)
4.- Cross reference files function prototypes, update h files accordingly