#!/usr/bin/perl -i.bak  --  #-*-perl-*-
#rab 2015
if( @ARGV != 1 ){
    print " \n"; 
    print "HPLUS.PL: Add plus signs to gdl files\n";
    print "Usage: hplus.pl <gdl> \n";
    print " \n";
    die "\nIncomplete Runstring\n\n";
}

# Decode the runstring
$date_save = '';
$year_save = '';
$line_save = '';
$file = $ARGV[0];
$file_tmp = $file.".bak";
while (<>) {
    if ($_ =~ /h(\d{2,2})(\d{8,8})_.{4,4}.gl?/) {
	if($2 == $date_save) {
	    chomp($line_save);
	    print "$line_save \+\n";
	} else {
	    print "$line_save";
	}
	$year_save = $1;
	$date_save = $2; 
	$line_save = $_;
    } 
}
system("tail -1 $file_tmp >> $file");
unlink("$file_tmp");

# K-Bye!
