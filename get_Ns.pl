#!/usr/bin/perl

use strict;
use warnings;
use Bio::SeqIO;

my $file = shift;
#my $output = shift;

my %results;

open (OUT, ">${file}.Ns") or die "Couldn't open ${file}.Ns";
open (OUT2, ">${file}.Ns.coord") or die "Couldn't open ${file}.Ns.coord";
open (OUT3, ">${file}.Ns.fullScaf") or die "Couldn't open ${file}.Ns.fullScaf";

my $full_object = Bio::SeqIO -> new (-file => $file, -format => "Fasta");

while (my $seq_object = $full_object -> next_seq()){   
	my $seqName = $seq_object -> display_id;
	#print $seqName."\n";
	my $seq = $seq_object -> seq();
	my $length = $seq_object -> length();
  	my $count = 0;
  	my $nStart = -1;
  	my $full_count = 0;
  	foreach my $i (0 .. $length){
		#print substr($seq, $i, 1)."\n";
		if ( substr($seq, $i, 1) eq "N" || substr($seq, $i, 1) eq "n"){
			if ($nStart == -1){ $nStart = $i; }
            $count++;
            $full_count++;
			if ( substr($seq, $i+1, 1) ne "N" && substr($seq, $i+1, 1) ne "n"){
				print OUT2 "$seqName\t$nStart\t$i\t$count\n";
				if (exists $results{$seqName}){
					push(@{$results{$seqName}},$count);
				}
				else{
					@{$results{$seqName}}=($count);	
				}
				$count = 0;
				$nStart = -1;
			}
		}
	}
	if (! exists $results{$seqName}){
		@{$results{$seqName}}=($count);
	}
	my $perc = $full_count / $length;
	if ($perc >= 0.9){
		print OUT3 "$seqName\t$length\t$full_count\t$perc\n";
	}
}

foreach my $key (keys %results){
	my @sorted = sort {$b <=> $a} @{$results{$key}};
	my $blocks = join ("-", @sorted);
	print OUT "$key\t$blocks\n";
}

close OUT;
close OUT2;
close OUT3;