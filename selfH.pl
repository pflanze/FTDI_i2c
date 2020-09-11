#!/usr/bin/perl

# For all the .c files, create or overwrite a _prototypes.h file which
# contains all the prototypes for the procedures in the corresponding
# .c file.

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
        $str =~ s/\.c\z/_prototypes.h/;
        $str
    }
    _END_
}
SelfH::File::constructors->import;

sub c_files($directory) {
    my @cfiles;
    opendir DIR, $directory or die $!;
    while (my $file = readdir(DIR)) {
        if (($file =~ /\.c$/) && ($file !~ /main\.c/)) {
            push @cfiles, $file;
        }
    }
    closedir DIR or die $!;
    [ map { File($_) } @cfiles]
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


package SelfH::Action {
    use FP::Struct ["path", "prototypes"], "FP::Struct::Show";
    sub execute($self) {
        open OUTPUT, $self->write_mode, $self->path or die $!;
        print OUTPUT "$_\n" for @{$self->prototypes};
        close OUTPUT or die $!;
    }
    _END_
}
package SelfH::CreateAction {
    use FP::Struct [], "SelfH::Action";
    sub write_mode { ">" }
    _END_
}
SelfH::CreateAction::constructors->import;

sub cFile_to_hFile_creation($cFile) {
    my @cprototypes = $cFile->prototypes('c');
    CreateAction($cFile->hPath, \@cprototypes)
}

sub cFiles_to_hFile_creations($cFiles) {
    [ map {
        cFile_to_hFile_creation($_)
      } @$cFiles ]
}

TEST { cFiles_to_hFile_creations(c_files ".") }
[
 CreateAction('bridge_prototypes.h',
              ['DWORD dev_createInfo(abr);',
               'FT_DEVICE_LIST_INFO_NODE* dev_getInfo(void);',
               'FT_HANDLE* dev_open(void);',
               'int dev_close(void);'])
];

sub main($directory) {
    my $actions= cFiles_to_hFile_creations(c_files($directory));
    $_->execute for @$actions;
}



if ($ENV{REPL}) {
    require FP::Repl::Trap;
    require FP::Repl; FP::Repl::repl();
    exit;
}


main(".");
