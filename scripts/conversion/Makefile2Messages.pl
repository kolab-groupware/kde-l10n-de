#! /usr/bin/env perl

# Copyright 2006 Nicolas GOUTTE <goutte@kde.org>
# License: FSF LGPL V2+

# Script to convert a "messages" target in a Makefile.am (as STDIN)
#  to a separate Bash script (to STDOUT).

# To convert many directories, you can use a script like:
#
# for i in `find . -name Makefile.am | xargs fgrep -l messages:`; do
#   echo  $i;
#   j=`dirname $i`;
#   perl Makefile2Messages.pl < $i > $j/Messages.sh;
# done

# Note: if you use the little script above, be careful that
# top subdirectories have a Makefile.am.in by default
# and that the Makefile.am must be generated first.

use v5.8.0;
use warnings;
use strict;
use Cwd;

binmode( STDIN, ":utf8" );
binmode( STDOUT, ":utf8" );

my $messages = 0;
my $comments = "";
my $exitvalue = 11;
my $allfine = 1;


open(MAK,"Makefile.am") || die "open Makefile.am";
open(SH, ">Messages.sh");
open(MAK2,">Makefile.am.new");

print SH "#! /bin/sh\n";

while( <MAK> )
{
    if ( $messages )
    {
        if ( /^[#\t ]/ )
        {
             s/^\t//; # Remove first tab (as it is part of the Makefile
             s/\s*;\s*\\$//; # Remove ;\ at end of line
             s/\sdo\s+\\$/ do/; # Remove \ after a "do" at end of line
             s/\sthen\s+\\$/ then/; # Remove \ after a "then" at end of line
             # Convert the main 5 environment variables
             s/\$\(EXTRACTRC\)/\$EXTRACTRC/;
             s/\$\(EXTRACTATTR\)/\$EXTRACTATTR/;
             s/\$\(XGETTEXT\)/\$XGETTEXT/;
             s/\$\(PREPARETIPS\)/\$PREPARETIPS/;
             s/\$\(podir\)/\$podir/;
             # Convert environment variable from $$ to $
             s/\$\$/\$/g;
             s/^\s*-?rm\s+rc\.cpp\s*$//; # remove "rm rc.cpp" 
             s/^\s*-rm\s+/rm /; # Remove - in front of rm

             if ( /\$EXTRACT/ )
             {
                 # "if extractrc or extractattr fails, exit the Bash script"
                 s/$/ || exit $exitvalue/;
                 $exitvalue++;
             }
             if ( ( /\s+-o\s+\$podir/ ) and ( not /(?:rc\.cpp|\*\.cpp)/ ) )
             {
                 # Force extracting of rc.cpp
                 s/\s+-o\s+\$podir/ rc.cpp -o \$podir/;
             }

             # A few warnings...
             if ( /\$\(/ )
             {
                 print STDERR "Warning: remaining Makefile variable at line $. $_ " . getcwd() . "\n";
		 $allfine = 0;
             }
             if ( /cd\s+/ )
             {
                 print STDERR "Warning: change of directory at line $.\n";
		 $allfine = 0;
             }
             if ( /[^\>]\>\s*rc.cpp/ )
             {
                 print STDERR "Warning: rc.cpp re-created at line $.\n";
		 $allfine = 0;
             }
	     $_ =~ s/^ *//;
             print SH $_;
	     next;
        }
        else
        {
             $messages = 0;
	     print MAK2 $_;
	     next;
        }
    }
    elsif ( /^messages:/ )
    {
        $messages = 1;
        print SH $comments;
        $comments = ""; 
        if ( /\s+#(.+)/ )
        {
            print SH "# $1\n";
        }
	next;
    }
    elsif ( /^#/ )
    {
        $comments .= $_;
    }
    else
    {
        $comments = "";
    }
    print MAK2 $_;
}

close(MAK2);
close(SH);
close(MAK);

if ($allfine)
  {
    rename("Makefile.am.new", "Makefile.am");
    system("svn add Messages.sh");
  }
