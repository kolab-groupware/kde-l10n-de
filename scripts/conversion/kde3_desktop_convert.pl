#! /usr/bin/env perl

# Copyright Nicolas GOUTTE <goutte@kde.org>
# License FSF LGPL V2+

# Use:
# msgcat --no-wrap in.po | perl kde3_desktop_convert.pl | msgcat - -o out.po

# The script assumes that the line containing the msgid/msgstr has the
# key and the = character too on the same line
# The output format assumes a feature of the Gettext tools that allow
# two keywords on the same line. (KBabel does not allow this.)

use strict;
use warnings;

binmode STDIN, ":utf8";
binmode STDOUT, ":utf8";

while ( <> )
{
    s/^\s*msgid\s*"([A-Za-z\-]+)=/msgctxt \"$1\"  msgid \"/;
    s/^\s*msgstr\s*"[A-Za-z\-]+=/msgstr \"/;
    print $_;
}
