#!/usr/bin/perl

# How it works:
# 1.- Open specified directory
# 2.- Check existance of: c and h files
# 3.- Check 1:1 relation. Else: create coresponding h files (warn if h and not c)
# 4.- Cross reference files function prototypes, update h files accordingly


use strict;
use warnings;

#testing only
# use Data::Dumper qw(Dumper);


#Fills arrays with '.c' and '.h' files
sub filling {
    my ($directory)= @_;

    my @cfiles;
    my @hfiles;
    opendir DIR, $directory or die $!;

    while (my $file = readdir(DIR)) {
        if (($file =~ /[.]{1}c$/) && ($file !~ /main\.c/)) {
            # print "$file\n";
            push @cfiles, $file;
        }
        elsif ($file =~ /[.]{1}h$/) {
            push @hfiles, $file;
            # print "$file\n";
        }
        else { next; }
    }
    closedir DIR or die $!;
    return (\@cfiles, \@hfiles)
}

#retuns names of the function prototypes required in the *.h file
sub funcName {
    my ($filename) = @_;

    open INPUT, "<", $filename or die $!;
    my @func;
    while (<INPUT>) {
        if (/(^(\w){1,}.*)+\(\w{1,}\)+{+(.*)$/) {
            my ($found, $rest) = split(/{/, $_);
            # print("$found\n");
            push @func, "$found;";
        }
    }
    close INPUT or die $!;
    return @func;
}

#create coresponding h files
#if does not exist: create and fill
#if it does: cross reference and append new functions
sub balanceCH {
    my ($cfiles, $hfiles)= @_;

    foreach my $cName (@$cfiles) {
        (my $hName = $cName) =~ s/.c/.h/;
        # print("$hName\n");
        my @cfunctions = funcName($cName);
        # does the h file exist?
        if (grep(!/^$hName/i, @$hfiles)) {
            open OUTPUT, ">>", $hName or die $!;
            print OUTPUT "$_\n" for @cfunctions;
            close OUTPUT or die $!;
        }
        else {
            # compare function content
            my @hfunctions = funcName($hName);
            my @newlines = "";
            foreach my $cline (@cfunctions) {
                if (grep(!/^$cline/i, @hfunctions)) {
                    push @newlines, $cline;
                }
            }
            open OUTPUT, ">>", $hName or die $!;
            print OUTPUT "$_\n" for @newlines;
            close OUTPUT or die $!;
        }
    }
}


#replace with your own directory
my $directory = '.';

#gathering file *.c *.h names
my ($refC, $refH) = filling($directory);
my @cfiles = @$refC ;
my @hfiles = @$refH;

#creating h files, and prototpes
balanceCH(\@cfiles, \@hfiles);

