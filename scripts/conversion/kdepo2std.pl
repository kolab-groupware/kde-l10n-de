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

sub get_msgkey {
    my (@lines) = @_;
    my $msgctxt = "";
    my $msgid = "";

    my ($in_msgctxt, $in_msgid) = (0, 0);
    for (@lines) {
        if (not /^\s*"/) {
            if (/^\s*msgctxt\s*"(.*)"\s*$/) {
                $in_msgctxt = 1;
                $in_msgid = 0;
                $msgctxt .= $1;
            }
            elsif (/^\s*msgid\s*"(.*)"\s*$/) {
                $in_msgctxt = 0;
                $in_msgid = 1;
                $msgid .= $1;
            }
            elsif (/^\s*msgid_plural\s*"(.*)"\s*$/) {
                $in_msgctxt = 0;
                $in_msgid = 0;
            }
        }
        elsif (/^\s*"(.*)"\s*$/) {
            $msgctxt .= $1 if $in_msgctxt;
            $msgid .= $1 if $in_msgid;
        }
    }

    return $msgctxt . "|~|" . $msgid;
}

sub convert_msgid {
    my ($desktop, @lines) = @_;

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
            if ($i == @lines) { # happens sometimes, these are invalid in KDE4
                return (0, "", ());
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
    # Transfer Variable= of desktop file messages into context.
    elsif (    $desktop
           and (   (@lines > 0 and $lines[0] =~ /^\s*msgid\s*"\w+=/)
                or (@lines > 1 and $lines[1] =~ /^\s*"\w+=/))) {
        my $i;
        if ($lines[0] =~ /^\s*msgid\s*"\w+=/) {
            $lines[0] =~ s/msgid\s*"/"/;
            $i = 0;
        }
        else {
            $i = 1;
        }

        $lines[$i] =~ /^\s*"(\w+)=(.*)"\s*$/;
        push(@clines, "msgctxt \"$1\"\n");
        if ($i > 0) {
            push(@clines, "msgid \"\"\n");
            push(@clines, "\"$2\"\n");
        }
        else {
            push(@clines, "msgid \"$2\"\n");
        }
        ++$i;
        while ($i < @lines) {
            push(@clines, $lines[$i]);
            ++$i;
        }
    }

    my $msgkey;
    if (@clines) {
        $msgkey = get_msgkey(@clines);
    }
    else {
        $msgkey = get_msgkey(@lines);
    }

    return ($is_plural, $msgkey, @clines);
}

sub convert_msgstr {
    my ($desktop, $plural, @lines) = @_;
    my @clines = ();
    local $_;

    if ($plural) {
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
        while ($p < $nplurals) {
            push(@clines, "msgstr[$p] \"\"\n");
            ++$p;
        }
    }
    elsif ($desktop) {
        my $i;
        if ($lines[0] =~ /^\s*msgstr\s*"\w+=/) {
            $lines[0] =~ s/msgstr\s*"/"/;
            $i = 0;
        }
        else {
            $i = 1;
        }

        $lines[$i] =~ /^\s*"(\w+)=(.*)"\s*$/;
        if ($i > 0) {
            push(@clines, "msgstr \"\"\n");
            push(@clines, "\"$2\"\n");
        }
        else {
            push(@clines, "msgstr \"$2\"\n");
        }
        ++$i;
        while ($i < @lines) {
            push(@clines, $lines[$i]);
            ++$i;
        }
    }

    return @clines;
}

sub convert_in_file {
    my ($fname) = @_;

    if (not (open IF, "<:utf8", "$fname")) {
        print STDERR "*** Cannot read: $fname\n";
        return;
    }

    local $_;

    my @nlines = ();
    my $some_converted = 0;

    # Check if this is a desktop_*.po
    my $is_desk = ($fname =~ /^(desktop_)/);

    # Go over the header.
    my $plset = 0;
    while (<IF>) {
        last if /^$/; # consider first blank line as end of header
        if (/Plural-Forms:/) {
            my $cplhead = $_;
            while (not /\\n"\s*$/) {
                $_ = <IF>;
                $cplhead .= $_;
            }
            push(@nlines, $pluralformline);
            $plset = 1;
            if ($cplhead ne $pluralformline) {
                $some_converted = 1
            }
        }
        else {
            push(@nlines, $_);
        }
    }
    if (not $plset) {
        push(@nlines, $pluralformline);
    }
    push(@nlines, "\n");

    my ($in_msgid, $in_msgstr, $duplicate) = (0, 0, 0);
    my (@conv_lines, @msgid_lines, @msgstr_lines, @comment_lines);
    my $is_plural;
    my %msgkeys;

    while (<IF>) {
        next if (/^$/ and not $in_msgstr) or /^$obs/;

        #print "*** Something went wrong in: $fname\n";
        if (/^\s*msgid\s*"/) {
            $in_msgid = 1;
            $in_msgstr = 0;
            push(@msgid_lines, $_);
        }
        elsif (/^\s*msgstr\s*/) {
            my $key;
            ($is_plural, $key, @conv_lines) = convert_msgid($is_desk, @msgid_lines);
            $duplicate = defined $msgkeys{$key};
            if (not $duplicate) {
                if (@conv_lines > 0) {
                    $some_converted = 1;
                    push(@nlines, $_) for (@comment_lines, @conv_lines);
                }
                else {
                    push(@nlines, $_) for (@comment_lines, @msgid_lines);
                }
            }
            @comment_lines = ();
            @msgid_lines = ();

            $msgkeys{$key} = 1;
            $in_msgstr = 1;
            $in_msgid = 0;
            push(@msgstr_lines, $_);
        }
        elsif (/^$/) {
            (@conv_lines) = convert_msgstr($is_desk, $is_plural, @msgstr_lines);
            if (not $duplicate) {
                if (@conv_lines > 0) {
                    $some_converted = 1;
                    push(@nlines, $_) for (@conv_lines);
                }
                else {
                    push(@nlines, $_) for (@msgstr_lines);
                }
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
            push(@comment_lines, $_);
        }
    }
    if ($in_msgstr and not $duplicate) {
            (@conv_lines) = convert_msgstr($is_desk, $is_plural, @msgstr_lines);
            if (@conv_lines > 0) {
                $some_converted = 1;
                push(@nlines, $_) for (@conv_lines);
            }
            else {
                push(@nlines, $_) for (@msgstr_lines);
            }
    }
    close IF;

    if ($some_converted) {
        if (not (open OF, ">:utf8", "$fname")) {
            print STDERR "*** Cannot write: $fname\n";
            return;
        }
        print OF @nlines;
        close OF;
        print "$fname\n";
    }
}

sub descend_tree {
    my ($path) = @_;

    opendir(CDIR, $path) or die "*** Cannot open directory '$path'.\n";
    my @entries = grep {not /^\./} readdir CDIR;
    closedir CDIR;

    my @files = grep {-f} map {"$path/$_"} @entries;
    my @sources = sort(grep {/\.po$/i} @files);
    my @dirs = sort(grep {-d} map {"$path/$_"} @entries);

    convert_in_file($_) for (@sources);

    descend_tree($_) for (@dirs);
}

# Main
{
    die "*** Error: no arguments!\n" if ($#ARGV == -1);
    
    my $plheaderfile = shift @ARGV;
    if ( $plheaderfile eq "--template" ) {
        print STDERR "Entering template mode...\n"; # DEBUG
        # Templates are similar to languages with two plural forms, like English
        $nplurals = 2;
        # ... but templates have an incomplete form declaration
        $pluralformline = "\"Plural-Forms: nplurals=INTEGER; plural=EXPRESSION;\\n\"\n";
    }
    else {
        $pluralformline = "";
        my $found = 0;
        open PL, "<:utf8", "$plheaderfile"
            or die "*** Cannot open file with plural header: $plheaderfile\n";
        # As the user has selected the file, we assume that no line is shared by two entries.
        while (<PL>) {
            if ( $found ) {
                if ( /^#/ or /^\s*$/ ) {
                    # Comment or empty line; probably msgstr was finished
                    print STDERR "Warning: the Plural-Forms declaration did not contain \\n\n";
                    last;
                }
                $pluralformline .= $_;
                if ( /\\n/ ) {
                    last;
                }
            }
            elsif ( /Plural-Forms:/ ) {
                if ( /Plural-Forms:.*\\n/ ) {
                    $pluralformline = $_;
                    last;
                }
                else {
                    # The declaration is on multiple lines, so have to start to collect
                    $pluralformline = $_;
                    $found = 1;
                }

            }
        }
        close PL;
        print STDERR "Plural form line:\n", $pluralformline, "---\n"; # DEBUG
        $nplurals = -1;
        # We assume that the nplurals declaration is in one line
        if ( $pluralformline =~ /nplurals\s*=\s*([0-9]+)/ ) {
            $nplurals = $1;
            print STDERR "Plural number: ", $nplurals, "\n"; # DEBUG
        }
        if ( $nplurals < 1 ) {
            die "*** File with plural header $plheaderfile does ".
                "not contain a correct number of plural forms.\n";
        }
    }

    my @paths;
    @paths = @ARGV if ($#ARGV >= 0);
    @paths = (".") if ($#ARGV == -1);

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
