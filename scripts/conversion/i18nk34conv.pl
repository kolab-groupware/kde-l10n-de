#!/usr/bin/perl
# A script to convert KDE 3 i18n handling to KDE 4.
#
# Chusslove Illich <caslav.ilic@gmx.net>
# Last change: February 10th, 2007. (first use October 23rd, 2005.)
#
# Run either with no arguments in the top directory of the sources you want
# to convert (implicit . path), or give it source files or directory paths
# on command line. It will recursively convert sources in the given paths,
# printing out the names of modified files.
#
# Note: Old and converted files cannot be unambiguously distinguished, so
# *do not* interrupt the run or make another run on already converted files.

use warnings;

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

sub upp {
    my ($str) = @_;
    $str =~ s/%(\d+)/%@{[$1+1]}/g;
    $str =~ s/%n/%1/g;
    return $str;
}

sub normalize {
    my ($str) = @_;
    my $strn;

    my $mwrn = "#warning";
    my $merr = "#error";

    my $i = 0;
    while ($i < length($str)) {
        # Put symbols instead of string literals.
        if (substr($str, $i, 1) eq '"' or substr($str, $i, 1) eq "'") {
            my $comm = substr($str, $i, 1);
            $strn .= "S";
            $i++;
            while (not substr($str, $i, 1) eq $comm) {
                if (substr($str, $i, 1) eq "\\") {
                    $strn .= "S";
                    $i++;
                }
                $strn .= "S";
                $i++;
            }
            $strn .= "S";
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
        return (substr($str, 0, $i), $match, substr($str, $i + length($match)), substr($strn, $i + length($match)));
    }
    else {
        return ($str, "", "", "");
    }
}

sub start_substr {
    my ($str, $strn, @subs) = @_;

    my ($pre, $mch, $res, $resn) = next_substr($str, $strn, @subs);

    if ($mch and (not $pre or normalize($pre) =~ /^\s*$/s)) {
        return ($pre . $mch, $res, $resn);
    }
    else {
        return ("", $str, $strn);
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

sub convert_in_string {
    my ($ostr) = @_;
    my $ostrn = normalize($ostr);
    if (length($ostrn) != length($ostr)) {
        print ">>>>>>>>>>>>>>>>>>>>|$ostr|\n";
        print "<<<<<<<<<<<<<<<<<<<<|$ostrn|\n";
        die "*** Normalized string has different length!\n";
    }

    my $nstr;
    while ($ostr) {
        my ($pre, $match, $rest, $restn) = next_substr($ostr, $ostrn, '([^a-zA-Z0-9_]i|^i)18n\s*\(\s*');
        $nstr .= $pre;
        $ostr = $rest;
        $ostrn = $restn;
        if ($match) {
            my $call = $match;

            # Check if any of the arg()'s of this call are of multiple type.
            # Check if first arg() is naked literal string.
            my $multies = 0;
            my $literal = 0;
            my $tmp_ostr = $ostr;
            my $tmp_ostrn = $ostrn;
            if (1)
            {
                my ($narg, $args, $rest, $restn) = all_arguments($ostr, $ostrn);
                $ostr = $rest;
                $ostrn = $restn;
                my $prev;
                my $expr = '\.\s*arg\s*\(';
                ($prev, $rest, $restn) = start_substr($ostr, $ostrn, $expr);
                my $currarg = 1;
                while ($prev) {
                    my @allargs;
                    ($narg, $args, $rest, $restn, @allargs) = all_arguments($rest, $restn);
                    $ostr = $rest;
                    $ostrn = $restn;
                    if ($narg > 1) {
                        $multies = 1;
                        if (not $g_fname_written_multies) {
                            print OFM "$g_fname\n";
                            $g_fname_written_multies = 1;
                        }
                        $g_nmulties++;
                        $g_fmulties{$g_fname}++;
                    }
                    if ($currarg == 1 and $allargs[0] =~ /^\s*"/) {
                        $literal = 1;
                        if (not $g_fname_written_literals) {
                            print OFL "$g_fname\n";
                            $g_fname_written_literals = 1;
                        }
                        $g_nliterals++;
                        $g_fliterals{$g_fname}++;
                    }
                    ($prev, $rest, $restn) = start_substr($ostr, $ostrn, $expr);
                    $currarg++;
                }
            }
            $ostr = $tmp_ostr; # Restore for further use
            $ostrn = $tmp_ostrn;
            # End check.

            if (not $multies) {
                # Convert to template notation.

                # Rename call properly.
                my ($narg, $args, $rest, $restn) = all_arguments($ostr, $ostrn);
                if (not $literal) {
                    $call =~ s/i18n/i18n/s  if $narg == 1;
                    $call =~ s/i18n/i18nc/s if $narg == 2;
                    $call =~ s/i18n/i18np/s if $narg == 3;
                }
                else {
                    $call =~ s/i18n/LITERAL_i18n/s  if $narg == 1;
                    $call =~ s/i18n/LITERAL_i18nc/s if $narg == 2;
                    $call =~ s/i18n/LITERAL_i18np/s if $narg == 3;
                }
                $args = upp($args) if $narg == 3; # replace %n with %1 and increase others
                $nstr .= $call . substr($args, 0, length($args) - 1); # omit closing bracket
                $ostr = $rest;
                $ostrn = $restn;

                # Change any following .arg() into argument of the call.
                my $prev;
                my $expr = '\.\s*arg\s*\(';
                ($prev, $rest, $restn) = start_substr($ostr, $ostrn, $expr);
                while ($prev) {
                    ($narg, $args, $rest, $restn) = all_arguments($rest, $restn);

                    $args = convert_in_string($args); # There might be i18n inside arg
                    # Replace . with ,
                       $prev =~ s/(\s*\/\/.*?)\n(\s*)\./,$1\n$2 /gs
                    or $prev =~ s/\n(\s*)\./,\n$1 /gs
                    or $prev =~ s/\./, /gs;
                    $prev =~ s/arg|\(//gs; # remove arg and opening brace

                    $nstr .= $prev . substr($args, 0, length($args) - 1);
                    $ostr = $rest;
                    $ostrn = $restn;

                    ($prev, $rest, $restn) = start_substr($ostr, $ostrn, $expr);
                }
                $nstr .= ")"; # add closing bracket
            }
            else {
                # Convert to class notation.
                # Class notation is actually disabled (no ki18nx calls),
                # so the instance won't compile -> force refactoring.

                # Rename call properly.
                my ($narg, $args, $rest, $restn) = all_arguments($ostr, $ostrn);
                #print ">>>>> $g_fname: $call$args\n";
#                 $call =~ s/i18n/ki18n/s if $narg == 1;
#                 $call =~ s/i18n/ki18nc/s if $narg == 2;
#                 $call =~ s/i18n/ki18np/s if $narg == 3;
                if (not $literal) {
                    $call =~ s/i18n/MULTI_i18n/s  if $narg == 1;
                    $call =~ s/i18n/MULTI_i18nc/s if $narg == 2;
                    $call =~ s/i18n/MULTI_i18np/s if $narg == 3;
                }
                else {
                    $call =~ s/i18n/LITERAL_MULTI_i18n/s  if $narg == 1;
                    $call =~ s/i18n/LITERAL_MULTI_i18nc/s if $narg == 2;
                    $call =~ s/i18n/LITERAL_MULTI_i18np/s if $narg == 3;
                }
                $args = upp($args) if $narg == 3; # replace %n with %1 and increase others
                $nstr .= $call . $args;
                $ostr = $rest;
                $ostrn = $restn;

                # Find last .arg() and append finalization.
                my $prev;
                my $expr = '\.\s*arg\s*\(';
                ($prev, $rest, $restn) = start_substr($ostr, $ostrn, $expr);
                while ($prev) {
                    ($narg, $args, $rest, $restn) = all_arguments($rest, $restn);

                    $args = convert_in_string($args); # There might be i18n inside arg

                    $nstr .= $prev . $args;
                    $ostr = $rest;
                    $ostrn = $restn;

                    ($prev, $rest, $restn) = start_substr($ostr, $ostrn, $expr);
                }
                # Class notation disabled, so no finalization...
                #$nstr .= ".toString()"; # add finalization
            }
        }
    }

    return $nstr;
}

sub convert_in_file {
    my ($fname) = @_;

    if (   $fname =~ /klocale\.(h|cpp)$/
        or $fname =~ /klocalizedstring\.(h|cpp)$/
        or $fname =~ /\/kdecore\//) {
        print "Special case, skipping: $fname\n";
        return;
    }

    $g_fname = $fname; # global
    $g_fname_written_multies = 0; # global
    $g_fname_written_literals = 0; # global
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

    $g_nmulties = 0;
    my $outmulties = "conv-multies.txt";
    open OFM, ">$outmulties"
        or die "*** Cannot write file $outmulties\n";
    $g_nliterals = 0;
    my $outliterals = "conv-literals.txt";
    open OFL, ">$outliterals"
        or die "*** Cannot write file $outliterals\n";

    for my $path (@paths) {
        $path =~ s/\/$//;
        if (-d $path) { descend_tree($path) }
        else { convert_in_file($path) }
    }

    close OFM;
    close OFL;

    if ($g_nmulties > 0) {
        my @fnames = sort keys %g_fmulties;
        my $nfiles = @fnames;
        print "\n";
        print "----- Warning: Multiargument arg() methods -----\n";
        print qq{\
Found total $g_nmulties multiargument arg() methods to i18n calls, in
$nfiles files (their names have been written to conv-multies.txt).

Prefix MULTI_ has been added to these calls, so that you can easily locate
them. Try to change them into i18n[cp] template forms: multiargument arg()
methods taking several QStrings are simply no longer needed.

If you really want to add arguments later, you can use the non-finalization
forms, ki18n[cp]() functions. These will return a KLocalizedString, to which
you can append arguments through its subs() methods, and then finalize
translation (obtain QString) with its toString() method. Note that
concatenation of several subs() methods is safe with respect to arguments
themselves containing placeholders, as placeholders get replaced in one pass
at finalization.

You can also use non-finalization forms if you want special formating of
arguments (eg. field width, precision...), which subs() methods provide.
Do *not* use Qt's formaters here, eg. QString::number(), since they do not
know about KDE's locale formats).
};
        #for my $fname (@fnames) { print "$fname\n" }
    }
    else {
        unlink $outmulties;
    }

    if ($g_nliterals > 0) {
        my @fnames = sort keys %g_fliterals;
        my $nfiles = @fnames;
        print "\n";
        print "----- Warning: String literals in first arg() -----\n";
        print qq{\
Found total $g_nliterals i18n calls having a naked string literal as first
argument, in $nfiles files (their names have been written to conv-literals.txt).

Prefix LITERAL_ has been added to these calls, so that you can easily locate
them. Quick fix would be to wrap string literal in first argument with QString
constructor, but consider refactoring the code: if you are using that same
literal somewhere else in the code, it should probably be stored in a const
QString, or the like. It might also be that the literal itself should be
translated, so you would wrap it with an i18n() call.

Literal string as first argument is dangerous because at a later point you
might decide to add context or pluralize the message, bug *forget* to change
call to i18nc() or i18np(), which could compile and result in some funky
effects. Therefore, by a small hack such code is made not to compile in
debug mode.
};
    }
    else {
        unlink $outliterals;
    }

    print "\n";
}
