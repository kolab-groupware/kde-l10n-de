#!/usr/bin/perl
# A script to convert KDE 3 PO files to standard gettext format.
# Chusslove Illich <caslav.ilic@gmx.net>
# Last change: $Date: 2009-05-14 01:31:54 +0200 (Do, 14. Mai 2009) $.
# (first use December 28th, 2005.)
#
# The first command line argument to the script is a file which contains
# the desired Plural-Forms header field for the conversion (as it would
# appear in a PO file: with quotes, can have more lines, etc.)
# This is followed by zero or more paths, which are to be searched
# recursively for PO files. If no path is given, the current working
# directory is taken implicitely.
#
# Warning: The script is very touchy -- it can choke on valid PO files
# which contain some unusual formatting.

use strict;
use warnings;
use v5.8.0;

use open IO  => ':utf8';

my $obs = "#~";

my $nplurals;
my $pluralformline;

sub upp {
    my ($str) = @_;
    $str =~ s/%(\d+)/%@{[$1+1]}/g;
    $str =~ s/%n/%1/g;
    return $str;
}

sub convert_msgid {
    my @lines = @_;

    my @clines = ();
    my $is_plural = 0;
    local $_;

    # Convert context
    if (   (@lines > 0 and $lines[0] =~ /^\s*msgid\s*"_: /)
        or (@lines > 1 and $lines[1] =~ /^\s*"_: /)) {
        my $i;
        if ($lines[0] =~ /^\s*msgid\s*"_: /) {
            $lines[0] =~ s/msgid\s*"/"/;
            $i = 0;
        }
        else {
            $i = 1;
        }

        if ($lines[$i] =~ /^\s*"_: (.*)\\n"\s*$/) {
            push(@clines, "msgctxt \"$1\"\n");
            ++$i;
        }
        else {
            $lines[$i] =~ /^\s*"_: (.*)"\s*$/;
            push(@clines, "msgctxt \"\"\n");
            push(@clines, "\"$1\"\n");
            ++$i;
            while ($i < @lines and $lines[$i] !~ /\\n"\s*$/) {
                push(@clines, $lines[$i]);
                ++$i;
            }
            if ($i == @lines) { # Happens only once in kdelibs.po, for LTR msg
                return (0, ());
            }
            $lines[$i] =~ /^(.*)\\n"\s*$/;
            push(@clines, "$1\"\n");
            ++$i;
        }

        if ($lines[$i] =~ /^(.*\\n")\s*$/) {
            push(@clines, "msgid \"\"\n");
            push(@clines, "$1\n");
        }
        elsif ($i < @lines - 1) {
            push(@clines, "msgid \"\"\n");
            push(@clines, $lines[$i]);
        }
        else {
            $lines[$i] =~ /^\s*?"(.*)"\s*$/;
            push(@clines, "msgid \"$1\"\n");
        }
        ++$i;
        while ($i < @lines) {
            push(@clines, $lines[$i]);
            ++$i;
        }
    }
    # Convert plural
    elsif (   (@lines > 0 and $lines[0] =~ /^\s*msgid\s*"_n: /)
           or (@lines > 1 and $lines[1] =~ /^\s*"_n: /)) {
        my $i;
        if ($lines[0] =~ /^\s*msgid\s*"_n: /) {
            $lines[0] =~ s/msgid\s*"/"/;
            $i = 0;
        }
        else {
            $i = 1;
        }

        if ($lines[$i] =~ /^\s*"_n: (.*)\\n"\s*$/) {
            push(@clines, "msgid \"".upp($1)."\"\n");
            ++$i;
        }
        else {
            $lines[$i] =~ /^\s*"_n: (.*)"\s*$/;
            push(@clines, "msgid \"\"\n");
            push(@clines, "\"".upp($1)."\"\n");
            ++$i;
            while ($lines[$i] !~ /\\n"\s*$/) {
                push(@clines, upp($lines[$i]));
                ++$i;
            }
            $lines[$i] =~ /^(.*)\\n"\s*$/;
            push(@clines, upp($1)."\"\n");
            ++$i;
        }

        if ($lines[$i] =~ /^(.*\\n")\s*$/) {
            push(@clines, "msgid_plural \"\"\n");
            push(@clines, upp($1)."\n");
        }
        elsif ($i < @lines - 1) {
            push(@clines, "msgid_plural \"\"\n");
            push(@clines, upp($lines[$i]));
        }
        else {
            $lines[$i] =~ /^\s*"(.*)"\s*$/;
            push(@clines, "msgid_plural \"".upp($1)."\"\n");
        }
        ++$i;
        while ($i < @lines) {
            push(@clines, upp($lines[$i]));
            ++$i;
        }

        $is_plural = 1;
    }

    return ($is_plural, @clines);
}

sub convert_msgstr {
    my @lines = @_;
    my @clines = ();
    local $_;

    $lines[0] =~ s/^\s*msgstr\s*//;
    shift @lines if $lines[0] =~ /^\s*\"\"\s*$/;

    if (@lines == 0) {
        # msgstr is not translated
        for (my $p = 0; $p < $nplurals; ++$p) {
            push(@clines, "msgstr[$p] \"\"\n");
        }
        return @clines;
    }

    my $p = 0;
    my $i = 0;
    while ($i < @lines) {
        my $ie = $i;
        ++$ie while $ie < @lines and $lines[$ie] !~ /\\n"\s*$/;
        if ($ie > $i and $i < @lines - 1) {
            push(@clines, "msgstr[$p] \"\"\n");
            for (my $ic = $i; $ic < $ie; ++$ic) {
                push(@clines, upp($lines[$ic]));
            }
            if ($ie < @lines) {
                $lines[$ie] =~/^(.*)\\n"\s*$/;
                push(@clines, upp($1)."\"\n");
            }
            $i = $ie + 1;
        }
        else {
            my $form;
            if ($i < @lines - 1) {
                $lines[$i] =~/^\s*"(.*)\\n"\s*$/;
                $form = $1;
            }
            else {
                $lines[$i] =~/^\s*"(.*)"\s*$/;
                $form = $1;
            }
            push(@clines, "msgstr[$p] \"".upp($form)."\"\n");
            ++$i;
        }

        ++$p;
    }

    return @clines;
}

sub convert_in_file($) {
    local $_;
    my @nlines = ();

    my ($fname) = (@_);

    if (not (open IF, "<:utf8", "$fname")) {
        print STDERR "*** Cannot read: $fname\n";
        return;
    }

    # Go over the header.
    my $plset = 0;
    while (<IF>) {
        last if /^$/; # consider first blank line as end of header
        ### TODO: the Plural-Forms entry could be multi-line
        if (/Plural-Forms:/) {
            push(@nlines, '"' . $pluralformline . '"' );
            $plset = 1;
        }
        else {
            push(@nlines, $_);
        }
    }
    if (not $plset) {
        push(@nlines, '"' . $pluralformline . '"' );
    }
    push(@nlines, "\n");

    my $some_converted = 0;
    my ($in_msgid, $in_msgstr) = (0, 0);
    my (@conv_lines, @msgid_lines, @msgstr_lines);
    my $is_plural;

    while (<IF>) {
        next if (/^$/ and not $in_msgstr) or /^$obs/;

        #print "*** Something went wrong in: $fname\n";
        if (/^\s*msgid\s*"/) {
            $in_msgid = 1;
            $in_msgstr = 0;
            push(@msgid_lines, $_);
        }
        elsif (/^\s*msgstr\s*/) {
            ($is_plural, @conv_lines) = convert_msgid(@msgid_lines);
            if (@conv_lines > 0) {
                $some_converted = 1;
                push(@nlines, $_) for (@conv_lines);
            }
            else {
                push(@nlines, $_) for (@msgid_lines);
            }
            @msgid_lines = ();

            $in_msgstr = 1;
            $in_msgid = 0;
            push(@msgstr_lines, $_);
        }
        elsif (/^$/) {
            if ($is_plural) {
                (@conv_lines) = convert_msgstr(@msgstr_lines);
                $some_converted = 1;
                push(@nlines, $_) for (@conv_lines);
            }
            else {
                push(@nlines, $_) for (@msgstr_lines);
            }
            @msgstr_lines = ();

            $in_msgstr = 0;
            $in_msgid = 0;
            push(@nlines, "\n");
            #print @nlines; exit 1 if @nlines > 100;
        }
        elsif ($in_msgid) {
            push(@msgid_lines, $_);
        }
        elsif ($in_msgstr) {
            push(@msgstr_lines, $_);
        }
        else {
            push(@nlines, $_);
        }
    }

    close(IF);

    if ($in_msgstr) {
            if ($is_plural) {
                (@conv_lines) = convert_msgstr(@msgstr_lines);
                $some_converted = 1;
                push(@nlines, $_) for (@conv_lines);
            }
            else {
                push(@nlines, $_) for (@msgstr_lines);
            }
    }

    if ($some_converted) {
        if (not (open OF, ">:utf8", "$fname")) {
            print STDERR "*** Cannot write: $fname\n";
            return;
        }
	my $lines = join(' ', @nlines);
        print OF $lines;
        close OF;
    }
}

$pluralformline=$ARGV[0];
$nplurals=$pluralformline;
$nplurals=~ s/.*nplurals=//;
$nplurals=~ s/;.*//;
my $file=$ARGV[1];
convert_in_file($file);

