#!/usr/bin/perl
# A script to check validity of i18n calls.
#
# Chusslove Illich <caslav.ilic@gmx.net>
# Last change: April 19th, 2007. (first use September 14th, 2005.)
#
# Run with no arguments in the top directory of the sources which you want
# to check. Alternatively, you can supply paths on command line.
# During run it prints out the files and line numbers with possible problems,
# and does not modify any files.
#
# Command line options are of the form option=value:
#   stats=[0|1] - print summary of problems at the end of run [0]
#   group=[0|1] - group same problems in one line [1]

use warnings;
use strict;

# ------------------------------------------------------------------------------
# Globals.

my $maxnarg = 9; # maximum number of arguments in template calls
my $showstats = 0; # print statistics at the end of run
my $grouplines = 1; # group same problems in one line

my ($g_lineno, $g_fname);
my ($gg_nwgaps, $gg_ncount, $gg_nqnumber, $gg_novermax, $gg_nlegplu) = (0,0,0,0,0);
my (%gg_fwgaps, %gg_fcount, %gg_fqnumber, %gg_fovermax, %gg_flegplu);

# ------------------------------------------------------------------------------
# Functions.

$0 =~ s/.*\///;
sub error {
    die "$0: *** @_\n";
}

my %g_errcnt;
sub report {
    my ($fn, $ln, $ptype, $msg) = @_;
    my $msgf = "(i18n $ptype) $msg";
    if (not $grouplines) { print "$fn:$ln: $msgf\n" }
    else                 { push @{$g_errcnt{$msgf}}, $ln; }
}

sub cfill {
    my ($str) = @_;
    $str =~ s/./ /gs;
    return $str;
}

sub jump_to {
    my ($str, $i, $end) = @_;
    my $endl = length($end);
    $i++ while not substr($str, $i, $endl) eq $end;
    return $i;
}

sub normalize {
    my ($str) = @_;
    my $strn;

    my $mwrn = "#warning";
    my $merr = "#error";
    my $sym = "S";

    my $i = 0;
    while ($i < length($str)) {
        # Put symbols instead of string literals.
        if (substr($str, $i, 1) eq '"' or substr($str, $i, 1) eq "'") {
            my $comm = substr($str, $i, 1);
            $strn .= "S";
            $i++;
            while (not substr($str, $i, 1) eq $comm) {
                if (substr($str, $i, 1) eq "\\") {
                    $strn .= $sym;
                    $i++;
                }
                $strn .= $sym;
                $i++;
            }
            $strn .= $sym;
            $i++;
        }
        # Put spaces instead of // comments.
        elsif (substr($str, $i, 2) eq "//") {
            my $ji = jump_to($str, $i, "\n");
            $strn .= " " x ($ji - $i);
            $i = $ji;
        }
        # Put spaces instead of /**/ comments.
        elsif(substr($str, $i, 2) eq "/*") {
            my $ji = jump_to($str, $i + 2, "*/");
            $strn .= " " x ($ji - $i);
            $strn .= "  "; # instead of */
            $i = $ji + 2; # +2 for */
        }
        # Put spaces instead of line wraps.
        elsif(substr($str, $i, 2) eq "\\\n") {
            $strn .= " \n";
            $i += 2;
        }
        # Put spaces instead of #warning macros.
        elsif (substr($str, $i, length($mwrn)) eq $mwrn) {
            my $ji = jump_to($str, $i, "\n");
            $strn .= " " x ($ji - $i);
            $i = $ji;
        }
        # Put spaces instead of #error macros.
        elsif (substr($str, $i, length($merr)) eq $merr) {
            my $ji = jump_to($str, $i, "\n");
            $strn .= " " x ($ji - $i);
            $i = $ji;
        }
        # Put original.
        else {
            $strn .= substr($str, $i, 1);
            $i++;
        }
    }

    return $strn;
}

sub next_substr {
    my ($str, $strn, @subs) = @_;

    my $reg = join "|", @subs;
    my ($match) = ($strn =~ /($reg)/s);
    if ($match) {
        my $i = length($`);
        $match = substr($str, $i, length($match));
        my $pre = substr($str, 0, $i);
        map {++$g_lineno} ($pre.$match) =~ /(\n)/sg;
        return ($pre, $match, substr($str, $i + length($match)), substr($strn, $i + length($match)));
    }
    else {
        map {++$g_lineno} $str =~ /(\n)/sg;
        return ($str, "", "", "");
    }
}

sub next_argument {
    my ($str, $strn) = @_;

    my ($arg, $done);
    my $balance = 0;
    while ($str and not $done) {
        my ($pre, $mch, $res, $resn) = next_substr($str, $strn, ',', '\(', '\)');
        $balance++ if $mch eq '(';
        $balance-- if $mch eq ')';

        $arg .= $pre . $mch;
        $str = $res;
        $strn = $resn;

        $done = ($balance < 0 or ($balance == 0 and $mch eq ','));
    }

    return ($arg, $str, $strn);
}

sub all_arguments {
    my ($str, $strn) = @_;

    my $narg = 0;
    my $arg = "";
    my ($args, $rest, $restn, @arglist);
    while (not ($arg =~ /\)$/s)) {
        ($arg, $rest, $restn) = next_argument($str, $strn);
        $args .= $arg;
        $str = $rest;
        $strn = $restn;
        push @arglist, substr($arg, 0, length($arg) - 1);
        last if $arg =~ /^\s*\)$/s;
        $narg++;
    }

    return ($narg, $args, $str, $strn, @arglist);
}

# Returns sorted list of unique placeholders in message string.
sub uniqpl {
    my ($str) = @_;
    $str =~ s/%%//sg; # remove possible % escapes
    my %plh;
    map { ++$plh{$_} } ($str =~ /%([1-9]\d*)/sg);
    return sort {$a <=> $b} keys %plh;
}

sub check_in_string {
    my ($ostr) = @_;
    my $ostrn = normalize($ostr);
    if (length($ostr) != length($ostrn)) {
        print ">>>>>>>>>>>>>>>>>>>>|$ostr|\n";
        print "<<<<<<<<<<<<<<<<<<<<|$ostrn|\n";
        error "Normalized string has different length!";
    }
    my $nstr;

    while ($ostr) {
        my ($pre, $match, $rest, $restn) = next_substr($ostr, $ostrn,
                                           '([^a-zA-Z0-9_]|^)k?i18n(|c|p|cp)\s*\(\s*');
        $nstr .= $pre;
        $ostr = $rest;
        $ostrn = $restn;
        if ($match) {
            my $call = $match;
            my ($narg, $args, $rest, $restn, @arglist) = all_arguments($ostr, $ostrn);
            $ostr = $rest;
            $ostrn = $restn;

            # Split out message strings from argument list.
            my (@strlist);
            if ($call =~ /i18ncp/)      { push @strlist, shift @arglist for 1..3; }
            elsif ($call =~ /i18n[cp]/) { push @strlist, shift @arglist for 1..2; }
            else                        { push @strlist, shift @arglist; }

            # Skip checks if message strings are not literals.
            if ($call =~ /i18nc?p/) {
                next if ($strlist[-1] !~ /"/ and $strlist[-2] !~ /"/);
            }
            else {
                next if ($strlist[-1] !~ /"/);
            }
            # skittish, Toombs, skittish...

            # Get sorted unique lists of placeholder numbers
            # (first string is context in i18n*c, hence look at strings
            # from the back).
            my (@upl, @upls, @uplp);
            if ($call =~ /i18nc?p/) {
                @upls = uniqpl($strlist[-2]);
                @uplp = uniqpl($strlist[-1]);
            }
            else {
                @upl = uniqpl($strlist[-1]);
            }

            # Check for legacy %n placeholder in plural calls.
            my $legplu = 0;
            if ($call =~ /i18nc?p/) {
                if ($strlist[-1] =~ /%n/ or $strlist[-2] =~ /%n/) {
                    $legplu = 1;
                    report $g_fname, $g_lineno, "error",
                           "legacy \%n placeholder in plural call";
                    $gg_nlegplu++;
                    $gg_flegplu{$g_fname}++;
                }
            }

            # Check for gaps in placeholder numbering
            # and count the needed number of arguments.
            # (provided that legacy plural check passed)
            my $wgaps = 0;
            my $nneedargs = 0;
            my $gapstr;
            if (not $legplu) {
            if ($call =~ /i18nc?p/) {
                # Plural-deciding placeholder can be missing in plural calls.
                if (@upls == @uplp) {
                    $nneedargs = @upls;
                    if ($nneedargs > 0) {
                        # - it can be %1 which is plural-number and missing,
                        # hence first placeholder must be either %1 or %2;
                        # - allow plural-number placeholder missing
                        # in both singular and plural;
                        ++$nneedargs if $upls[0] == 2;
                        if ($upls[0] > 2) {
                            $wgaps = 1;
                        }
                        else {
                            for(my $i = 0; $i < @upls; ++$i) {
                                if ($upls[$i] != $uplp[$i]) {
                                    $wgaps = 1;
                                    last;
                                }
                            }
                        }
                    }
                }
                elsif (@upls + 1 == @uplp) {
                    # - allow plural-number placeholder missing in singular
                    $nneedargs = @uplp;
                    if ($uplp[0] != 1 or $uplp[-1] != $nneedargs) {
                        $wgaps = 1;
                    }
                    elsif ($nneedargs > 1) {
                        my $gapwidth = $upls[0] - 1;
                        for (my $i = 1; $i < @upls; ++$i) {
                            $gapwidth += ($upls[$i] - $upls[$i - 1]) - 1;
                        }
                        if ($gapwidth > 1) {
                            $wgaps = 1;
                        }
                    }
                }
                else {
                    $wgaps = 1;
                }

                $gapstr = "(@upls) (@uplp)" if $wgaps;
            }
            else {
                # All placeholders must be in sequence for non-plural calls.
                $nneedargs = @upl;
                if (    $nneedargs > 0
                    and ($upl[0] != 1 or $upl[-1] != $nneedargs)) {
                    $wgaps = 1;
                    $gapstr = "(@upl)";
                }
            }
            if ($wgaps) {
                report $g_fname, $g_lineno, "error",
                       "gaps in placeholder numbering, $gapstr";
                $gg_nwgaps++;
                $gg_fwgaps{$g_fname}++;
            }
            }

            # Check if there is exact number of arguments supplied
            # (provided that legacy plural and gap check passed)
            my $badcount = 0;
            my $nhaveargs = @arglist;
            if (not $legplu and not $wgaps) {
            if ($call !~ /ki18n/) {
                if ($call =~ /i18nc?p/) {
                    # - allow one argument extra in case both singular and plural
                    # placeholder lists start with 1 and are of same length;
                    if ($nneedargs != $nhaveargs) {
                        if (   $nneedargs + 1 != $nhaveargs
                            or @upls != @uplp
                            or (@upls and $upls[0] != 1)) {
                            $badcount = 1;
                        }
                    }
                }
                else {
                    # - need exact match in non-plural calls.
                    $badcount = 1 if $nneedargs != $nhaveargs;
                }
                if ($badcount) {
                    report $g_fname, $g_lineno, "error",
                           "wrong argument count, have $nhaveargs need $nneedargs";
                    $gg_ncount++;
                    $gg_fcount{$g_fname}++;
                }
            }
            }

            # Check if number of arguments exceeds capacity of template calls
            # (provided that legacy plural, gap and count checks passed)
            my $toomany = 0;
            if (not $legplu and not $wgaps and not $badcount) {
            if ($call !~ /ki18n/ and $nhaveargs > $maxnarg) {
                $toomany = 1;
                report $g_fname, $g_lineno, "error",
                       "too many arguments, have $nhaveargs max $maxnarg";
                $gg_novermax++;
                $gg_fovermax{$g_fname}++;
            }
            }

            # Check if there are any QString::number() conversions.
            for my $arg (@arglist) {
                if ($arg =~ /QString\s*::\s*number/) {
                    report $g_fname, $g_lineno, "warning",
                           "use of QString::number()";
                    $gg_nqnumber++;
                    $gg_fqnumber{$g_fname}++;
                }
            }
        }
    }
}

sub check_in_file {
    my ($fname) = @_;

    if (   $fname =~ /klocale\.(h|cpp)$/
        or $fname =~ /klocalizedstring\.(h|cpp)$/
        or $fname =~ /kjsembed\/kjseglobal\.h$/
        or $fname =~ /kdecore\/tests\/.*$/) {
        #print "Special case, skipping: $fname\n";
        return;
    }

    $g_lineno = 1; # Global line number.
    $g_fname = $fname; # Debug global variable, for other functions to use
    if (not (open IF, "<$fname")) {
        print "*** Cannot read: $fname\n";
        return;
    }
    my @flines = <IF>;
    close IF;
    #print "--------------------> $fname\n";

    my $fstr = join "", @flines;
    if ($fstr) {
        return if not $fstr =~ /i18n/s; # quick check

        $fstr .= "\n" if not $fstr =~ /\n$/s; # end with newline if it doesn't

        check_in_string($fstr);

        if ($grouplines) {
            for (keys %g_errcnt) {
                my $lstr = join ",", @{$g_errcnt{$_}};
                print "$fname: $_ line#$lstr\n";
            }
            %g_errcnt = ();
        }
    }
}

sub descend_tree {
    my ($path) = @_;

    opendir(CDIR, $path) or error "Cannot open directory '$path'.";
    my @entries = grep {not /^\./} readdir CDIR;
    closedir CDIR;

    my @files = grep {-f} map {"$path/$_"} @entries;
    my @sources = sort(
        grep {   /\.h$/i or /\.hh$/i or /\.hpp$/i or /\.hxx$/i
              or /\.h.in$/i or /\.hh.in$/i or /\.hpp.in$/i or /\.hxx.in$/i
              or /\.cc$/i or /\.cxx$/i or /\.cpp$/i
              or /\.cc.in$/i or /\.cxx.in$/i or /\.cpp.in$/i} @files);
    my @dirs = sort(grep {-d} map {"$path/$_"} @entries);

    check_in_file($_) for (@sources);

    descend_tree($_) for (@dirs);
}

# ------------------------------------------------------------------------------
# Main body.

my %opts = map {/(.*)=(.*)/} grep /=/, @ARGV;
my @rest = grep /^[^=]*$/, @ARGV;

# Handle options.
for (keys %opts) {
    if    (/^stats$/) { $showstats = $opts{$_}; }
    elsif (/^group$/) { $grouplines = $opts{$_}; }
    #elsif (/^...$/) { ... }
    else { error "Unknown command line option: $_=$opts{$_}" }
}

# Handle rest.
my @paths;
@paths = @rest if (@rest > 0);
@paths = (".") if (@rest == 0);

for my $path (@paths) {
    -f $path or -d $path
        or error "'$path' is neither file nor directory.";
}

# Go through all paths.
for my $path (@paths) {
    $path =~ s/\/$//;
    if (-d $path) { descend_tree($path) }
    else { check_in_file($path) }
}

$showstats or exit 0;

if ($gg_nwgaps > 0 or $gg_ncount > 0 or $gg_nqnumber > 0 or $gg_novermax > 0) {
    print "-----\n";
}

if ($gg_nwgaps > 0) {
    my @fnames = sort keys %gg_fwgaps;
    my $nfiles = @fnames;
    print "Total $gg_nwgaps i18n calls with gaps in placeholder numbering, in $nfiles files.\n";
    #for my $fname (@fnames) { print "$fname\n" }
}

if ($gg_ncount > 0) {
    my @fnames = sort keys %gg_fcount;
    my $nfiles = @fnames;
    print "Total $gg_ncount i18n calls with wrong argument count, in $nfiles files.\n";
    #for my $fname (@fnames) { print "$fname\n" }
}

if ($gg_nqnumber > 0) {
    my @fnames = sort keys %gg_fqnumber;
    my $nfiles = @fnames;
    print "Total $gg_nqnumber QString::number() calls in i18n arguments, in $nfiles files.\n";
    #for my $fname (@fnames) { print "$fname\n" }
}

if ($gg_novermax > 0) {
    my @fnames = sort keys %gg_fovermax;
    my $nfiles = @fnames;
    print "Total $gg_novermax i18n template calls with too many arguments, in $nfiles files.\n";
    #for my $fname (@fnames) { print "$fname\n" }
}

if ($gg_nlegplu > 0) {
    my @fnames = sort keys %gg_flegplu;
    my $nfiles = @fnames;
    print "Total $gg_nlegplu plural i18n calls with legacy \%n placeholder, in $nfiles files.\n";
    #for my $fname (@fnames) { print "$fname\n" }
}
