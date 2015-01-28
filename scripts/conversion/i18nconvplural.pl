#!/usr/bin/perl
# A *very temporary* script to convert KDE4 plural strings
# using %n placeholder into all-numbered counterparts.
#
# Chusslove Illich <caslav.ilic@gmx.net>
# Last change: February 10th, 2007. (first use February 9th, 2007.)
#
# Run either with no arguments in the top directory of the sources you want
# to convert (implicit . path), or give it source files or directory paths
# on command line. It will recursively convert sources in the given paths,
# printing out the names of modified files.

use warnings;
use strict;

sub upp {
    my ($str) = @_;
    $str =~ s/%(\d+)/%@{[$1+1]}/g;
    $str =~ s/%n/%1/g;
    return $str;
}

sub convert_in_string {
    my ($str) = @_;
    my $nstr;
    while ($str =~ s/(.*?i18np\s*\(\s*)(".+?"\s*,\s*".+?"\s*(,|\)))//s) {
        $nstr .= $1 . upp($2);
    }
    $nstr .= $str;
    return $nstr;
}

sub convert_in_file {
    my ($fname) = @_;

    if (   $fname =~ /klocale\.(h|cpp)$/
        or $fname =~ /klocalizedstring\.(h|cpp)$/
        or $fname =~ /kdecore\/tests\/.*$/) {
        print "Special case, skipping: $fname\n";
        return;
    }

    if (not (open IF, "<$fname")) {
        print "*** Cannot read: $fname\n";
        return;
    }
    my @flines = <IF>;
    close IF;

    my $fstr = join "", @flines;
    if ($fstr) {
        return if not $fstr =~ /i18np/s; # quick check

        $fstr .= "\n" if not $fstr =~ /\n$/s; # end with newline if it doesn't

        my $nstr = convert_in_string($fstr);
        if (not $nstr) {
            print "*** Something went wrong in: $fname\n";
            return;
        }

        if (not $fstr eq $nstr) {
            if (not (open OF, ">$fname")) {
                print "*** Cannot write: $fname\n";
                return;
            }
            print OF $nstr;
            close OF;
            print "$fname\n";
        }
    }
}

sub descend_tree {
    my ($path) = @_;

    opendir(CDIR, $path) or die "*** Cannot open directory '$path'.\n";
    my @entries = grep {not /^\./} readdir CDIR;
    closedir CDIR;

    my @files = grep {-f} map {"$path/$_"} @entries;
    my @sources = sort(
        grep {   /\.h$/i or /\.hh$/i or /\.hpp$/i or /\.hxx$/i
              or /\.h.in$/i or /\.hh.in$/i or /\.hpp.in$/i or /\.hxx.in$/i
              or /\.cc$/i or /\.cxx$/i or /\.cpp$/i
              or /\.cc.in$/i or /\.cxx.in$/i or /\.cpp.in$/i} @files);
    my @dirs = sort(grep {-d} map {"$path/$_"} @entries);

    convert_in_file($_) for (@sources);

    descend_tree($_) for (@dirs);
}

# Main
{
    my @paths;
    @paths = @ARGV if (@ARGV > 0);
    @paths = (".") if (@ARGV == 0);

    for my $path (@paths) {
        -f $path or -d $path
            or die "*** '$path' is neither file nor directory.\n";
    }

    for my $path (@paths) {
        $path =~ s/\/$//;
        if (-d $path) { descend_tree($path) }
        else { convert_in_file($path) }
    }
}
