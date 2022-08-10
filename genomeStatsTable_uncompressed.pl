#/usr/bin/perl -w
use strict;
use Data::Dumper;

#Calculates basic stats for all .fa or .fa.gz files in a directory
#Joana Damas
#16 November 2017 

my $dir = $ARGV[0]; #directory with fasta files
my $output = $ARGV[1]; #output file, will be tab separated file

my %data;

opendir (DIR, $dir) or die "Couldn't open $dir!\n";
my @files= readdir DIR;
closedir DIR;

foreach my $file(@files){
	print "Reading $dir/$file...\n";
	if ($file =~ /.fa$/ or $file =~ /.fna$/ or $file =~ /.fasta$/){ 
		@{$data{$file}} = &stats("${dir}/${file}");
		`module load kentutils`;
		`faSize $file`;
	}
}

open(OUT, ">$output") or die "Couldn't create $output!\n";
print OUT "File\tNoFrags\tTotal length\tN90\tL90\tN50\tL50\tMinimum length\tMaximum length\n";
foreach my $key (keys %data){
	print OUT "$key\t".join("\t",@{$data{$key}})."\n";
}
close OUT;

sub commify {
    my $text = reverse $_[0];
    $text =~ s/(\d\d\d)(?=\d)(?!\d*\.)/$1,/g;
    return scalar reverse $text
}

sub stats{
	my $input = shift;
	#print "Inside sub $input\n";
	open (IN, $input) or warn "Couldn't open $input!\n";
	my $length=0;
	my $cnt=0;
	my $totalLength;
	my $seq;
	my @arr;

	while (<IN>) {
		my $line = $_;
		if ($line =~/^>(\w+)/) { #fasta header
			$cnt++; 
			if($length!=0)	{
				$totalLength+=$length;
				push(@arr,$length);
			}
			$length=0;
		}
		else {
			chomp;## chomp removes newlines
			$seq = $line;
			$length+=length($seq);
		}	
	}
	#Adds last seq
	$totalLength+=$length;
	push(@arr,$length);
	close IN;

	my @sort = sort {$b <=> $a} @arr;
	my $n50len;
	my $n90len;
	my $l50 = 0;
	my $l90 = 0;
	my $n90;
	my $n50;
	my $min = $sort[-1];
	my $max = $sort[0];

	foreach my $val(@sort){
		$n90len+=$val;
		$l90++;
		if($n90len >= $totalLength*0.9){ $n90 = $val; last; }
	}

	foreach my $val(@sort){
		$n50len+=$val;
		$l50++;
		if($n50len >= $totalLength*0.5){ $n50 = $val; last; }
	}

	return ($cnt, &commify($totalLength), &commify($n90), &commify($l90), &commify($n50), &commify($l50), $min, $max);
}

