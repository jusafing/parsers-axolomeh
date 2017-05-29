#!/usr/bin/perl -w
###############################################################################
# MORRIS Segmentador v0.2
# jusafing -> minina
# Abril 2017
###############################################################################

use strict;
use utf8;
use POSIX;

###############################################################################
my $DEBUG = 0;
###############################################################################
my %file    ;
my %th      ;
my %lines   ;
my %nlines  ;
my %outlines;
$file{na}    = $ARGV[0];
$th{na}      = $ARGV[1];
$file{es}    = $ARGV[2];
$th{es}      = $ARGV[3];
###############################################################################
checkArg();
readFile($file{na});
readFile($file{es});
processThreshold();
###############################################################################
sub pdbg {
    my $msg = shift;
    print $msg if ($DEBUG == 1);
}
###############################################################################
sub checkArg {
    print "######################\n";
    print "Morris split v0.2\n";
    print "######################\n";
    if ( @ARGV != 4) {
        print "\nERROR, Wrong syntax. Usage: \n\n";
        print "\$morris_split <FILE_NA> <NA_TH> <FILE_ES> <ES_TH> [DEBUG]\n\n";
        print "   <FILE_NA> : FILE in Nahuatl\n";
        print "   <NA_TH>   : Threshold for file in Nahuatl\n";
        print "   <FILE_ES> : FILE in Spanish\n";
        print "   <ES_TH>   : Threshold for file in Spanish\n\n";
        print "----------------\n";
        print "Bye. Morris off!\n\n";
        exit -1;
    }
}
###############################################################################
sub readFile {
    my $file = shift;
    my $counter = 1;
    if (open(FH,"$file")) {
        print " ++  OK ... Reading and indexing file [$file]\n";
        while ( <FH> ) {
            chomp($_);
            my @line_words = split(/\s+/, $_);
            my $num_words  = @line_words;
            $lines{"$file"}{$counter} = [@line_words];
            $counter++;
        }
    }
    else {
        die " --  ERROR ... Unable to read file [$file]\n\n";
    }
    $counter--;
    $nlines{"$file"} = $counter;
    print " ++  OK ... Read [$counter] lines in [$file]\n";
    close(FH);
}
###############################################################################
sub processThreshold {
    unless ($nlines{$file{na}} == $nlines{$file{es}} ) {
        print " --  WARNING, number of lines of both files do not match\n";
    }
    for ( my $line = 1 ; $line <= $nlines{$file{na}} ; $line++ ) {
        my $na_nwords  = @{$lines{"$file{na}"}{$line}};
        my $es_nwords  = @{$lines{"$file{es}"}{$line}};
        my $na_nchunks = ceil($na_nwords / $th{na});
        my $es_nchunks = ceil($es_nwords / $th{es});
        pdbg(" ++  OK ... NA[$line] W:$na_nwords TH:$th{na} NC:$na_nchunks\n");
        pdbg(" ++  OK ... ES[$line] W:$es_nwords TH:$th{es} NC:$es_nchunks\n");
#        my $min_chunk = ($na_nchunks, $es_nchunks)[$na_nchunks > $es_nchunks];
        my ($min_chunk, $min_lang);
        if ($na_nchunks < $es_nchunks) {
            $min_chunk = $na_nchunks;
            $min_lang  = "na";
            pdbg(" ++  OK ... Min chunks: [$min_chunk] [$min_lang]\n");
        }
        elsif ($es_nchunks < $na_nchunks) {
            $min_chunk = $es_nchunks;
            $min_lang  = "es";
            pdbg(" ++  OK ... Min chunks: [$min_chunk] [$min_lang]\n");
        }
        else {
            $min_chunk = $es_nchunks; # Min value is equal. Both work
            $min_lang  = "none";
            pdbg(" ++  OK ... Min chunks: [$min_chunk] [$min_lang]\n");
        }
        for (my $chunk = 0 ; $chunk < $min_chunk ; $chunk++) {
            foreach my $lang ( keys %{th}) {
                my $chunk_words = '';
                for (my $word = 0 ; $word < $th{$lang} ; $word++) {
                    my $tmpsize = @ {$lines{"$file{$lang}"}{$line}};
                    if ($tmpsize > 0 ) {
                        my $tmpword = shift @ {$lines{"$file{$lang}"}{$line}};
                        $chunk_words .= "$tmpword ";
                    }
                }
                pdbg(" ++  [$lang] [$line] [$chunk] - [$chunk_words]\n");
                $outlines{"$lang"}{"$line"}{"$chunk"} = $chunk_words;
            }
        }
        if ($min_lang eq "es") {
            my ($tmpword, $remain_words);
            my $lastchunk = keys % { $outlines{na}{$line} } ;
            $lastchunk --;
            pdbg(" ++  LAST chunk to fill [na] [$line] <$outlines{na}{
                $line}{$lastchunk}> [$lastchunk]\n");
            while ( @ {$lines{$file{na}}{$line}} ) {
                $tmpword = shift @ {$lines{$file{na}}{$line}};
                $remain_words .= " $tmpword";
            }
            pdbg(" ++  REMAIN words: $remain_words\n");
            $outlines{na}{$line}{$lastchunk} .= $remain_words;
        }
        elsif ($min_lang eq "na") {
            my ($tmpword, $remain_words);
            my $lastchunk = keys % { $outlines{es}{$line} } ;
            $lastchunk --;
            pdbg(" ++  LAST chunk to fill [es] [$line] <$outlines{es}{
                $line}{$lastchunk}> [$lastchunk]\n");
            while ( @ {$lines{$file{es}}{$line}} ) {
                $tmpword = shift @ {$lines{$file{es}}{$line}};
                $remain_words .= " $tmpword";
            }
            pdbg(" ++  REMAIN words: $remain_words\n");
            $outlines{es}{$line}{$lastchunk} .= $remain_words;
        }
    } 
    print " ---------------------------------------------------------------\n";
    print " ++  OK ... Creating output file $file{na}.out\n";
    print " ++  OK ... Creating output file $file{es}.out\n";
    my $new_total = 0;
    foreach my $lang (keys %outlines) {
        $new_total = 0;
        unless (open(OFH,">$file{$lang}.out")) {
            print " ++  ERROR ... Unable to create file $file{$lang}.out\n";
        }
        foreach my $line (sort {$a<=>$b} keys %{$outlines{$lang}}) {
            foreach my $chunk (sort{$a<=>$b} keys %{$outlines{$lang}{$line}}) {
                pdbg("[$lang][$line][$chunk]:$outlines{$lang}{$line}{$chunk}\n");
                print  OFH "$outlines{$lang}{$line}{$chunk}\n";
                $new_total++;
            }
        }
        close(OFH);
    }
    print " ++  OK ... Number of lines of INPUT  files [$nlines{$file{na}}]\n";
    print " ++  OK ... Number of lines of OUTPUT files [$new_total]\n";
    print "----------------\n";
    print "Bye. Morris off!\n";
}
