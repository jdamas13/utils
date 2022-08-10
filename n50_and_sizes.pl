#/usr/bin/perl -w
use strict;

my @arr;
my @names;
my $length;
my $noGC;
my $totalGC;
my $noN;
my $totalN;
my $totalLength;
my $seq;

my $file = $ARGV[0];
#print $file."\n";
#my $statsout = $ARGV[1];
#print $statsout."\n";
#my $sizesout = $ARGV[2];

sub commify {
    my $text = reverse $_[0];
    $text =~ s/(\d\d\d)(?=\d)(?!\d*\.)/$1,/g;
    return scalar reverse $text
}

if ($file =~ /.gz/){
	`zcat $file > tmp.fa`;
	open (IN, "tmp.fa") or die "Couldn't open tmp.fa";
	$length=0;
	$noGC=0;
	$noN=0;
	while (<IN>) {
		my $line = $_;
		if ($line =~/^>(\w+)/ ) {
			$line =~s/>//;
			my @tmp = split(/\s+/, $line);
			push(@names, $tmp[0]);
			if($length!=0)	{
				$totalLength+=$length;
				$totalGC+=$noGC;
				$totalN+=$noN;
				push(@arr,$length);
			}
			$length=0;
			$noGC=0;
			$noN=0;
		}
		else {
			chomp $line;## chomp removes newlines
			$seq = $line;
			$length+=length($seq);
			$noGC+= () = $seq =~ /G|g|C|c/g;
			$noN+= () = $seq =~ /N|n/g;
		}	
	}
} 

unlink "tmp.fa";

if ($file =~ /.fasta$/ || $file =~ /.fa$/ || $file =~ /.fna$/ || $file =~ /.fasta.masked$/ || $file =~ /.fa.masked$/){
	open (IN, $file) or die "Couldn't open $file";
	$length=0;
	$noGC=0;
	$noN=0;
	while (<IN>) {
		my $line = $_;
		#print $line."\n";
		if ($line =~ /^>(\w+)/ ) {
			#print $line."\n";
			$line =~s/>//;
			my @tmp = split(/\s+/, $line);
			push(@names, $tmp[0]);
			if($length!=0)	{
				$totalLength+=$length;
				$totalGC+=$noGC;
				$totalN+=$noN;
				push(@arr,$length);
			}
			$length=0;
			$noGC=0;
			$noN=0;
		}
		else {
			chomp $line;## chomp removes newlines
			$seq = $line;
			$length+=length($seq);
			$noGC+= () = $seq =~ /G|g|C|c/g;
			$noN+= () = $seq =~ /N|n/g;
			#print $noGC."\n";
		}	
	}
}
$totalGC+=$noGC;
$totalN+=$noN;
#print $totalGC."\n";
$totalLength+=$length;
push(@arr,$length);
close IN;

my $percGC=($totalGC/$totalLength)*100;
my $roundedGC = sprintf("%.2f", $percGC);

my $percN=($totalN/$totalLength)*100;
my $roundedN = sprintf("%.2f", $percN);

my @sort = sort {$b <=> $a} @arr;
my $n50len;
my $n90len;
my $l50 = 0;
my $l90 = 0;
open(OUT1, ">${file}.stats") or die "Couldn't create ${file}.stats!\n";
foreach my $val(@sort){
	$n90len+=$val;
	$l90++;
	if($n90len >= $totalLength*0.9){
		#print "====================\n";
		print OUT1 "$file\n";
		print OUT1 "Nofrag\t".commify(scalar(@arr))."\n";
		print OUT1 "Total genome size\t".commify($totalLength)."\n";
		print OUT1 "N90\t".commify($val)."\n";
		print OUT1 "L90\t".commify($l90)."\n";
		last;
	}
}

foreach my $val(@sort){
	$n50len+=$val;
	$l50++;
	if($n50len >= $totalLength*0.5){
		#print "====================\n";
		print OUT1 "N50\t".commify($val)."\n";
		print OUT1 "L50\t".commify($l50)."\n";
		print OUT1 "GC perc\t".$roundedGC."\n";
		print OUT1 "Length Ns\t".$totalN."\n";
		print OUT1 "N perc\t".$roundedN."\n";
		last;
	}
}
close OUT1;

open(OUT2, ">${file}.sizes") or die "Couldn't create ${file}.sizes!\n";
print OUT2 "$file\n";
foreach my $i (0..$#arr){
	print OUT2 $names[$i]."\t".commify(@arr[$i])."\n";
}
print OUT2 "Total\t".commify($totalLength)."\n";
close OUT2;