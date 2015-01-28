#!/usr/bin/env perl
# Repack PO template produced by KDE extraction scripts.
#
# Usage: repack-pot.pl <pot-file>
#
# The POT file is repacked in place.
#
# Repacking means the following:
#
# - move #. ... file: ... comments into proper source references
#   (these are extracted from dummy rc.cpp, via extractrc)
#
# - sort messages by source filename
#   (xgettext can sort on extraction, but previous point ruffles it)
#
# The script should be conservative.
# Highest priority is on not producing an invalid template.

use warnings;
use strict;

# Dummy extraction files.
my @dummies = ("rc.cpp", "rc.py", "tips.cpp", "tips.cc"); # default, for all
my %dummies_per_po = ( # additional, per catalog
    "libmuon" => ["categoriesxml.cpp"],
    "kcells" => ["xml_doc.cpp"],
    "kregexpeditor" => ["predefined-regexps.cpp"],
    "kspread" => ["xml_doc.cpp"],
    "okular_ghostview" => ["rc_okular_ghostview.cpp"],
    "okular_www" => ["news.cpp"],
    "sheets" => ["xml_doc.cpp"],
    "system-config-printer-kde" => ["ui.py"],
);

(my $cmdname = $0) =~ s/.*\///;

sub error {
    my ($msg) = @_;
    die "$cmdname: error: $msg\n";
}
sub warning {
    my ($msg) = @_;
    print STDERR "$cmdname: warning: $msg\n";
}

if (@ARGV != 1) {
    die "usage: $cmdname <pot-file>\n";
}

my $potpath = $ARGV[0];
if (not -r $potpath) {
    error "cannot read file: $potpath";
}
my ($poname) = ($potpath =~ /([^\/]*)\.[^.]*$/);

# Prepare regex for matching dummy file name in source references.
if (defined $dummies_per_po{$poname}) {
    push @dummies, @{$dummies_per_po{$poname}};
}
my $dummiesrx = join "|", @dummies;

# Parse the POT into list of messages.
# Use empty line as separator.
# Split out obsolete messages, to just append them at the end.
my @olines;
my @msgs;
my @msglnos;
my @obsmsgs;
open POT, "<$potpath";
my $msg = [];
my $msglno;
while (1) {
    my $line = <POT>;
    if (defined $line) {
        push @olines, $line;
        chomp $line;
    }
    if (not defined $line or $line =~ /^\s*$/) {
        if (@{$msg}) {
            if ($msg->[-1] !~ /^#~/) {
                push @msgs, $msg;
                push @msglnos, $msglno;
            } else {
                push @obsmsgs, $msg;
            }
            $msg = [];
        }
        last if not defined $line;
    } else {
        push @{$msg}, $line;
        $msglno = $. if $line =~ /^msgid/;
    }
}
close POT;
my $ocontent = join "", @olines;

# Remove header message, to avoid mixing it in the processing.
my $headmsg = shift @msgs;
shift @msglnos;

# Convert extracted comments into proper source references.
my %nmsgsbyfile;
my @toofewrc;
for (my $i = 0; $i < @msgs; ++$i) {
    my $msg = $msgs[$i];
    my $msglno = $msglnos[$i];

    # Collect file references in comments and in real source references.
    # Collect ectx extracted comments too.
    # Remove all collected lines.
    my @extrefs;
    my @srcrefs;
    my @ectxcomms;
    my $inspos = -1; # position where to later insert new references
    my $nmsg = [];
    for my $line (@{$msg}) {
        if ($line =~ /^#\..*?\bfile:\s*(\S+:[1-9]\d*)\s*$/) {
            # File reference in extracted comment.
            push @extrefs, $1;
        } elsif ($line =~ /^#:\s*(.*?)\s*$/) {
            # File references in source references.
            my @refs = split /\s+/, $1;
            push @srcrefs, @refs;
        } elsif ($line =~ /^#\..*?\bectx:/) {
            push @ectxcomms, $line;
        } else {
            push @{$nmsg}, $line;
        }

        if ($inspos < 0 and $line =~ /^(#,|msgctxt|msgid)/) {
            $inspos = @{$nmsg} - 1;
        }
    }
    # Make references and ectx comments unique.
    my %seen;
    %seen = (); @extrefs = grep {not $seen{$_}++} @extrefs;
    %seen = (); @srcrefs = grep {not $seen{$_}++} @srcrefs;
    %seen = (); @ectxcomms = grep {not $seen{$_}++} @ectxcomms;
    # Replace dummy source references references from extracted comments.
    my @nsrcrefs;
    for my $srcref (@srcrefs) {
        if ($srcref =~ /(?:^|\/)($dummiesrx):/) {
            if (@extrefs > 0) {
                push @nsrcrefs, shift @extrefs;
            }
        } else {
            push @nsrcrefs, $srcref;
        }
    }
    if (@extrefs > 0) {
        push @nsrcrefs, @extrefs;
        push @toofewrc, $msglno;
    }
    # Sort references and collect the first source filename and line number
    # (to prepare sorting messages by source files).
    my ($primfname, $primlno) = ("", 0);
    if (@nsrcrefs > 0) {
        my %splitrefs;
        for my $srcref (@nsrcrefs) {
            my ($srcfname, $srclno) = ($srcref =~ /(.*):(.*)/);
            $splitrefs{$srcfname} = [] if not defined $splitrefs{$srcfname};
            push @{$splitrefs{$srcfname}}, $srclno;
        }
        @nsrcrefs = ();
        for my $srcfname (sort {lc $a cmp lc $b} keys %splitrefs) {
            for my $srclno (sort {$a <=> $b} @{$splitrefs{$srcfname}}) {
                push @nsrcrefs, "$srcfname:$srclno";
                ($primfname, $primlno) = ($srcfname, $srclno) if not $primfname;
            }
        }
    }
    if (not defined $nmsgsbyfile{$primfname}) {
        $nmsgsbyfile{$primfname} = {};
    }
    if (not defined $nmsgsbyfile{$primfname}{$primlno}) {
        $nmsgsbyfile{$primfname}{$primlno} = [];
    }
    # Compose source reference lines from newly assembled references.
    my @srcreflines;
    if (@nsrcrefs > 0) {
        my $srcrefline = "#:";
        while (1) {
            my $srcref = shift @nsrcrefs;
            $srcrefline .= " " . $srcref;
            if (length($srcrefline . " " . $srcref) > 79 or @nsrcrefs == 0) {
                push @srcreflines, $srcrefline;
                $srcrefline = "#:";
            }
            last if @nsrcrefs == 0;
        }
    }
    # Put back into the message all processed lines.
    splice @{$nmsg}, $inspos, 0, @ectxcomms, @srcreflines;
    # Add repacked message into array according to primary source filename.
    push @{$nmsgsbyfile{$primfname}{$primlno}}, $nmsg;
}

# Report on problems.
if (@toofewrc) {
    warning sprintf "%s: too few dummy source references in %d messages",
                    $potpath, 0+@toofewrc;
    #warning sprintf "...near lines (original): %s", join ", ", @toofewrc;
}

# Sort messages by primary source filename and line number.
my @nmsgs;
for my $primfname (sort {lc $a cmp lc $b} keys %nmsgsbyfile) {
    for my $primlno (sort {$a <=> $b} keys %{$nmsgsbyfile{$primfname}}) {
        push @nmsgs, @{$nmsgsbyfile{$primfname}{$primlno}};
    }
}

# Overwrite the original file with repacked messages.
my @lines;
push @lines, @{$headmsg}, "";
for my $msg (@nmsgs, @obsmsgs) {
    push @lines, @{$msg}, ""; # one spacing empty line
}

my $content = join "\n", @lines;
if ($content ne $ocontent) {
    open POT, ">$potpath";
    print POT $content;
    close POT;
}
