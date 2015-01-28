#!/usr/bin/env perl
# Changes plural header in PO files.
#
# Usage:
#   change-plural-header.pl <src-po-file> <po-files>...
#
# src-po-file is the PO file which contains the plural header to be
# substituted into other given PO files. The replacement is done in place.
# Outputs modified PO file names to stdout, and used plural header to stderr.
#
# Chusslove Illich <caslav.ilic@gmx.net>
# Last change: $Date$
# (first use May 5th, 2007.)

use strict;
use warnings;
use v5.8.0; # for decent Unicode support
use File::Basename;

my %teams;

# Reports or replaces plural header in the file.
# If $newplhead not given, reports plural header found in the file.
# If $newplhead is given, replaces file's plural header with this one.
sub plhead_reprep {
    my ($fname, $newplhead) = @_;

    my $base = basename($fname);
    $base =~ s/\.po$//;

    my ($firstdir) = split(/\//, $fname);
    my $teamname;
    if (defined $teams{$firstdir}) {
       $teamname=$teams{$firstdir};
    }

    my $tomodify = 0;

    # Split file into pre plural header lines, plural header lines and
    # post plural header lines.
    # If no plural header is found, the file is split at end of header message.
    # If no header message is found, all lines in the file get stored into
    # pre-plural header string.
    open IF, "<:utf8", $fname
        or die "*** Cannot read file: $fname\n";
    my ($pre, $plhead, $post) = ("", "", "");
    my $phase = 0;
    
    my $seen_mime = 0;
    my $seen_project = 0;

    while (<IF>) {

        if ($phase < 2 && m/Project-Id-Version: PACKAGE VERSION/) {
           $_ =~ s/Project-Id-Version: PACKAGE VERSION/Project-Id-Version: $base/;
           $tomodify = 1;
        }

        if ($phase < 2 && m/MIME-Version:/) {
            $seen_mime = 1;
        }

        if ($phase < 2 && m/Project-Id-Version:/) {
            $seen_project = 1;
        }

        if ($phase == 0) {
            $phase = 1 if /^\s*msgstr/;
            $pre .= $_;
        }
        elsif ($phase == 1) {
            if (/^\s*"Plural-Forms:/) {
                # Start of plural header.
                $phase = /\\n"\s*$/ ? 3 : 2;
                $plhead .= $_;
            }
            elsif (/^\s*$/) {
                # End of header message.
                $phase = 3;
                $post .= $_;
            }
            else {
                $pre .= $_;
            }
        }
        elsif ($phase == 2) {
            $phase = 3 if /\\n"\s*$/;
            $plhead .= $_;
            not /^\s*[^"\s]/
                or die "*** Badly terminated plural header in file: $fname\n";
        }
        else { # $phase == 3
            last if not defined $newplhead; # if in report mode
            $post .= $_;
        }
    }
    $phase != 2
        or die "*** EOF before termination of plural header in file: $fname\n";
    close IF;
    $plhead =~ s/^ +| +$//g;

    if (not defined $newplhead) {
        # Report mode, just return the plural header.
        return $plhead;
    }

    if (!$seen_mime) {
       # add a Mime-Version 1.0
       $pre =~ s/("Content-Type)/"MIME-Version: 1.0\\n"\n$1/;
       $tomodify = 1;
    }

    if (!$seen_project) {
       $pre =~ s/("POT-Creation-Date)/"Project-Id-Version: $base\\n"\n$1/;
       $tomodify = 1;
    }

    # remove fuzzy flag from header
    if ($pre =~ /#, fuzzy/) {
       $pre =~ s/#, fuzzy\n//;
       $tomodify = 1;
    }

    if ($pre =~ /Language-Team: LANGUAGE/ && defined $teamname) {
       $pre =~ s/Language-Team: LANGUAGE/Language-Team: $teamname/;
       $tomodify = 1;
    }

    # If the new plural header differs from found, modify the file.
    if (unwrap($plhead) ne unwrap($newplhead)) {
        $tomodify = 1;
    }

    if ($tomodify) {
        #print "$fname\n";
        open OF, ">:utf8", $fname
             or die "*** Cannot write file: $fname\n";
        print OF $pre, $newplhead, $post;
        close OF;
    }

    return $plhead;
}

# Unwraps PO string split into several lines.
sub unwrap {
    my ($postr) = @_;
    $postr =~ s/"\s*\n\s*"//gs;
    return $postr;
}

if (-f "teamnames") {
    open(TEAMS, "teamnames");
    while ( <TEAMS> ) {
      chomp;
      next if (/^#/);
      my ($lang, $name) = split(/=/, $_);
      $teams{$lang} = $name if defined($lang);
    }
    close(TEAMS);
}

# Get plural header from template file.
my $tfile = shift @ARGV;
my $plhead = plhead_reprep($tfile);
$plhead
    or die "*** No plural header in template file: $tfile\n";

$plhead =~ s/Plural-Forms:  nplurals=2; plural=\(n != 1\);/Plural-Forms: nplurals=2; plural=n != 1;/;
$plhead =~ s/  / /g;
#print STDERR "Using plural header:\n", $plhead, "----------\n";

# Replace plural headers in PO files.
plhead_reprep($_, $plhead) for (@ARGV);
