#!/usr/bin/perl

# How it works:
# 1.- Open specified directory
# 2.- Check existance of: c and h files
# 3.- Check 1:1 relation. Else: create coresponding h files (warn if h and not c)
# 4.- Cross reference files function prototypes, update h files accordingly


use strict;
use warnings FATAL => 'uninitialized';
use feature 'signatures'; no warnings 'experimental::signatures';

use Chj::TEST;
use Chj::xIOUtil qw(xgetfile_utf8);


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

sub string_prototypes($inp, $c_or_h) {
    my $expected_braceOrSem=
        $c_or_h eq 'h' ? ";" :
        $c_or_h eq 'c' ? "{" :
        die "invalid c_or_h value";
    my @func;
    while ($inp=~
            /\n
            (
            (\w+[^\n]*?)+
            \((\w+)\)+
            )
            \s*
            (\{|;)
           /sxgc) {
        my ($proto,
            $return_type_and_name, $parameters,
            $braceOrSem)= ($1,$2,$3,$4);
        if ($braceOrSem eq $expected_braceOrSem) {
            push @func, "$proto;";
        }
    }
    return @func;
}

sub file_prototypes($path, $c_or_h) {
    string_prototypes(xgetfile_utf8($path),
                      $c_or_h)
}

TEST { [file_prototypes  "bridge.h","h"] }
[
 'DWORD dev_createInfo(void);',
 'FT_DEVICE_LIST_INFO_NODE*  dev_getInfo(void);',
 'FT_HANDLE* dev_open(void);',
 'int dev_close(void);'
];

TEST { [file_prototypes  "bridge.c","c"] }
[
 'DWORD dev_createInfo(abr);',
 'FT_DEVICE_LIST_INFO_NODE* dev_getInfo(void);',
 'FT_HANDLE* dev_open(void);',
 'int dev_close(void);'
];


#create coresponding h files
#if does not exist: create and fill
#if it does: cross reference and append new functions
sub balanceCH($cfiles, $hfiles) {
    foreach my $cName (@$cfiles) {
        (my $hName = $cName) =~ s/.c/.h/;
        # print("$hName\n");
        my @cprototypes = file_prototypes($cName, 'c');
        # does the h file exist?
        if (! grep(/^\Q$hName\E\z/, @$hfiles)) {
            open OUTPUT, ">>", $hName or die $!;
            print OUTPUT "$_\n" for @cprototypes;
            close OUTPUT or die $!;
        }
        else {
            # compare function content
            my @hprototypes = file_prototypes($hName, 'h');
            my @newlines;
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

