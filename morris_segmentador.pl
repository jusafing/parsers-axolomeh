#!/usr/bin/perl -w
# MORRIS Segmentador version =^0.1^=
use strict;
use utf8;

###############################################################################
my $RNGMIN = 1;
my $RNGMAX = 5;
###############################################################################
checkArg();
my $file    = $ARGV[0];
my $outfile = "$file.segmented";
readFile();
###############################################################################
sub checkArg {
    if ( @ARGV != 1 ) {
        die "\nERROR, Wrong syntax. Usage:  \$ morris_segmentador FILE\n\n";
    }
}
###############################################################################
sub readFile {
    if (open(FH,"$file")) {
        unless (open(OFH,">$outfile")) {
            die "ERROR, Unable to write output file [$outfile]\n"
        }
        my ($word, $data, $n);
        print "Processing file [$file]\n";
        while ( ($n = read FH, $data, 1) != 0 ) {
            unless ($data =~ /[ |\n|\t|\r]/ ) {
                $word .= $data;
            }
            else {
                processWord(\$word);
                $word = "";
            }
        }
        close(FH); 
        close(OFH); 
    }
    else {
        die "ERROR, Unable to open file [$file]\n";
    }
}
###############################################################################
sub processWord {
    my $word    = shift;
    print "WORD extracted: [$$word]\n" if ( $$word =~ /.+/);
    my $seed = $RNGMIN + int(rand($RNGMAX - $RNGMIN));
    print "RND: [$seed]\n";
    if ($seed > length $$word) {
        print "\tSEG [$$word]\n";
        binmode(STDOUT, ":utf8");
        print OFH "$$word ";
    }
    else {
        my $cnt     = 0;
        my $segment = "";
        while ($$word =~ /(.)/gs) {
            if ($cnt < $seed) {
                $segment .= $1;
            }
            else {
                print "\tSEG [$segment]\n";
                binmode(STDOUT, ":utf8");
                print OFH "$segment ";
                $cnt = 0;
                $segment = $1;
            }
            $cnt++;
        }
        print "\tSEG [$segment]\n";
        binmode(STDOUT, ":utf8");
        print OFH "$segment ";
    }
}
