#!/usr/bin/env perl
# Corrects number of msgstrs for plural messages in PO files.
#
# Usage:
#   fix-num-plural-msgstr.pl <po-files>...
#
# The files are modified in place. The corrected messages are made fuzzy.
# Outputs modified PO file names to stdout.
#
# Chusslove Illich <caslav.ilic@gmx.net>
# Last change: $Date$
# (first use May 19th, 2007.)

use strict;
use warnings;

binmode(STDOUT, ":utf8");

my $g_any_changed;

for my $fname (@ARGV) {
    open IF, "<:utf8", $fname
        or die "*** Cannot read file: $fname\n";
    my $text;
    my $cmsg;
    my $nforms;
    my $nmsgs = 0;

    $g_any_changed = 0; # clear modified status for this file
    while (<IF>) {
        $cmsg .= $_;
        if (/^\s*$/ and $cmsg =~ /[^\s]/) { # end of entry
            ++$nmsgs;

            my $nmsgid = @{[$cmsg =~ /^(#~)?\s*msgid[^_]/mg]};
            $nmsgid == 1 or die "Cannot parse file (line $.): $fname\n";

            if ($nmsgs == 1) { # header entry
                # Find number of plural forms.
                $cmsg =~ /Plural-Forms:\s*nplurals\s*=\s*([0-9]+)/
                    or die "Plural header not defined: $fname\n";
                $nforms = $1;
            }

            # Check message, correct if needed, append to previous.
            $text .= fixmsg($cmsg, $nforms);
            $cmsg = "";
        }
    }
    $text .= fixmsg($cmsg, $nforms); # one message possibly left
    close IF;

    if ($g_any_changed) {
        open OF, ">:utf8", $fname
             or die "*** Cannot write file: $fname\n";
        print OF $text;
        close OF;
        print "$fname\n";
    }
}

sub fixmsg {
    my ($cmsg, $nforms) = @_;

    return $cmsg if $cmsg !~ /^\s*[^\s#]/m; # obsolete entry

    return $cmsg if $cmsg !~ /^\s*msgid_plural/m; # not plural entry

    # Count present forms.
    my $nmsgstr = @{[$cmsg =~ /^\s*msgstr/mg]};

    # Check if message is translated.
    my $tmprx = 'msgstr\s*\[[0-9]+]\s*""\n' x $nmsgstr;
    my $translated = $cmsg !~ /$tmprx/;

    # Check if message is fuzzy.
    my $fuzzy = $cmsg =~ /^\s*#,(.*?,)*\s*fuzzy/m;

    # Add or remove forms.
    if ($nmsgstr < $nforms) { # less forms, append some
        my $addforms;
        for my $n ($nmsgstr .. $nforms - 1) {
            $addforms .= "msgstr[$n] \"\"\n";
        }
        $cmsg =~ s/\n\s*(\n|$)/\n$addforms\n/s;
    }
    elsif ($nmsgstr > $nforms) { # more forms, truncate some
        $cmsg =~ s/\n\s*msgstr\s*\[$nforms].*/\n\n/s;
    }

    if ($nmsgstr != $nforms) {
        $g_any_changed = 1; # set to save file

        # Mark as fuzzy if translated and not fuzzy and
        # needs more forms.
        if ($translated and not $fuzzy and $nmsgstr < $nforms) {
            if ($cmsg =~ /^\s*#,/m) { # has flags comment
                $cmsg =~ s/^(\s*#,)/$1 fuzzy,/m;
            }
            else { # no flags comment
                $cmsg =~ s/^((\s*#:.*?\n)*)/$1#, fuzzy\n/;
            }
            #print "=====> fuzzied\n";
        }
        #print "{$cmsg}\n";
    }

    return $cmsg;
}
