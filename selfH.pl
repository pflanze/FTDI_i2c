#!/usr/bin/perl

# How it works:
# 1.- Open specified directory
# 2.- Check existance of: c and h files
# 3.- Check 1:1 relation. Else: create coresponding h files (warn if h and not c)
# 4.- Cross reference files function prototypes, update h files accordingly


use strict;
use warnings FATAL => 'uninitialized';
use feature 'signatures'; no warnings 'experimental::signatures';

#testing only
# use Data::Dumper qw(Dumper);


sub c_and_h_files($directory) {
    my @cfiles;
    my @hfiles;
    opendir DIR, $directory or die $!;

    while (my $file = readdir(DIR)) {
        if (($file =~ /\.c$/) && ($file !~ /main\.c/)) {
            # print "$file\n";
            push @cfiles, $file;
        }
        elsif ($file =~ /\.h$/) {
            push @hfiles, $file;
            # print "$file\n";
        }
        else { next; }
    }
    closedir DIR or die $!;
    return (\@cfiles, \@hfiles)
}

# function prototype strings for a .c (extract from definition) or .h
# (take declaration) file
sub prototypes($cfile, $c_or_h) {
    my $expected_braceOrSem=
        $c_or_h eq 'h' ? ";" :
        $c_or_h eq 'c' ? "{" :
        die "invalid c_or_h value";
    open INPUT, "<", $cfile or die $!;
    my @func;
    while (<INPUT>) {
        if (my ($proto,
                $return_type_and_name, $parameters,
                $braceOrSem)=
            /^
            (
            (\w+.*)+
            \((\w+)\)+
            )
            \s*
            (\{|;)
            /x) {
            if ($braceOrSem eq $expected_braceOrSem) {
                push @func, "$proto;";
            }
        }
    }
    close INPUT or die $!;
    return @func;
}

#create coresponding h files
#if does not exist: create and fill
#if it does: cross reference and append new functions
sub balanceCH($cfiles, $hfiles) {
    foreach my $cName (@$cfiles) {
        (my $hName = $cName) =~ s/.c/.h/;
        # print("$hName\n");
        my @cprototypes = prototypes($cName, 'c');
        # does the h file exist?
        if (! grep(/^\Q$hName\E\z/, @$hfiles)) {
            open OUTPUT, ">>", $hName or die $!;
            print OUTPUT "$_\n" for @cprototypes;
            close OUTPUT or die $!;
        }
        else {
            # compare function content
            my @hprototypes = prototypes($hName, 'h');
            my @newlines = "";
            foreach my $cline (@cprototypes) {
                if (! grep(/^\Q$cline\E\z/, @hprototypes)) {
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
my ($refC, $refH) = c_and_h_files($directory);
my @cfiles = @$refC ;
my @hfiles = @$refH;

#creating h files, and prototpes
balanceCH(\@cfiles, \@hfiles);

