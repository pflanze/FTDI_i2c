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


package SelfH::File {
    # a File, possibly with in-memory content for testing
    use Chj::xIOUtil qw(xgetfile_utf8);
    use FP::Struct ["path", "content"], "FP::Struct::Show";

    sub content($self) {
        $$self{content} //= xgetfile_utf8($$self{path})
    }
    sub prototypes($self, $c_or_h) {
        main::string_prototypes($self->content, $c_or_h)
    }
    sub hPath($self) {
        my $str= $self->path;
        $str =~ s/\.c\z/.h/;
        $str
    }
    _END_
}
SelfH::File::constructors->import;

package SelfH::CAndHFiles {
    use FP::Struct ["directory", "cfiles", "hfiles"], "FP::Struct::Show";

    sub hfiles_hash($self) {
        $$self{hfiles_hash} //= +{ map { $_->path => $_ } @{$self->hfiles} }
    }
    sub has_h($self, $cFile) {
        my $hpath= $cFile->hPath;
        exists $self->hfiles_hash->{$hpath}
    }
    sub maybe_hFile($self, $cFile) {
        # the corresponding h file if it already exists
        my $hpath= $cFile->hPath;
        $self->hfiles_hash->{$hpath}
    }
    _END_
}
SelfH::CAndHFiles::constructors->import;


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
    CAndHFiles($directory,
               [ map { File($_) } @cfiles],
               [ map { File($_) } @hfiles])
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

my $tst_bridge_h= q'
#include "../ftd2xx.h"

DWORD dev_createInfo(void);
FT_DEVICE_LIST_INFO_NODE*  dev_getInfo(void);
FT_HANDLE* dev_open(void);
int dev_close(void);
// int dev_init(void);

';

my $tst_bridge_c= '
/*------------------------Populates device information
Notes:
    Call before 
*/
DWORD dev_createInfo(abr) {
    // create the device information list
    DWORD numDevs;
...
}
/* ..
    ftHandle=Null >>> indicates that a handle has not yet been created or open
*/

FT_DEVICE_LIST_INFO_NODE* dev_getInfo(void) { 
    DWORD numDevs = dev_createInfo();      
...
}
//------------------------------------Device Initialization && termination

FT_HANDLE* dev_open(void) {
    FT_HANDLE* ftHandle = malloc(sizeof(FT_HANDLE));// Handle of the FTDI device
    ...
}

//Not finished
int dev_close(void) {
    //free data
}

//------------------------------------
// int dev_init(void){
//    ...
// }
';

TEST { [ string_prototypes $tst_bridge_h, "h" ] }
[
 'DWORD dev_createInfo(void);',
 'FT_DEVICE_LIST_INFO_NODE*  dev_getInfo(void);',
 'FT_HANDLE* dev_open(void);',
 'int dev_close(void);'
];

TEST { [ string_prototypes $tst_bridge_c, "c" ] }
[
 'DWORD dev_createInfo(abr);',
 'FT_DEVICE_LIST_INFO_NODE* dev_getInfo(void);',
 'FT_HANDLE* dev_open(void);',
 'int dev_close(void);'
];


#create coresponding h files
#if does not exist: create and fill
#if it does: cross reference and append new functions

package SelfH::Action {
    use FP::Struct ["path", "prototypes"], "FP::Struct::Show";
    sub execute($self) {
        open OUTPUT, ">>", $self->path or die $!;
        print OUTPUT "$_\n" for @{$self->prototypes};
        close OUTPUT or die $!;
    }
    _END_
}
package SelfH::CreateAction {
    use FP::Struct [], "SelfH::Action";
    _END_
}
SelfH::CreateAction::constructors->import;
package SelfH::AppendAction {
    use FP::Struct [], "SelfH::Action";
    _END_
}
SelfH::AppendAction::constructors->import;

sub balance_c_h($cAndHFiles, $cFile) {
    my @cprototypes = $cFile->prototypes('c');
    if (defined (my $hFile= $cAndHFiles->maybe_hFile($cFile))) {
        # compare function content
        my @hprototypes = file_prototypes($hFile, 'h');
        AppendAction($cFile->hPath,
                     [ grep {
                         my $cline=$_;
                         ! grep { $_ eq $cline } @hprototypes
                       } @cprototypes ])
    }
    else {
        # h file doesn't exist yet
        CreateAction($cFile->hPath, \@cprototypes)
    }
}

sub balance_all($cAndHFiles) {
    [ map { balance_c_h($cAndHFiles, $_) } @{$cAndHFiles->cfiles} ]
}

TEST { balance_all(c_and_h_files ".") }
[
 AppendAction('bridge.h',
              ['DWORD dev_createInfo(abr);',
               'FT_DEVICE_LIST_INFO_NODE* dev_getInfo(void);'])
];

sub balanceCH($cAndHFiles) {
    my $actions= balance_all($cAndHFiles);
    $_->execute for @$actions;
}



if ($ENV{REPL}) {
    require FP::Repl::Trap;
    require FP::Repl; FP::Repl::repl();
    exit;
}

#replace with your own directory
my $directory = '.';

#gathering file *.c *.h names
balanceCH(c_and_h_files($directory));

