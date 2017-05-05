#!/usr/bin/perl -w
#
#|---------------------------------------|
#| Fetch Cypress FX3 streamer-in samples |
#|---------------------------------------|
#| Version P1A, Deyan Levski, 14.02.2017 |
#|---------------------------------------|
#|-+-|
#


use strict;

#use constant COLUMN => 1;

my $fname = $ARGV[0];
my $fparsename = $ARGV[1];

local $/ = \16536;

open(F, '<', $fname) or die("Unable to open file $fname, $!");
binmode(F);

my $buf;
my $ct=0;
my $byte=0;
#my $byte_old=0;
my $byte_cnt=0;
my $byte_lock=0;
my $sample_msb=0;
my $sample_lsb=0;

open(my $fh, '>', $fparsename) or die "Could not open file '$fparsename' $!";
print $fh ("Sample, Value, \n");

while($buf = <F>){
	foreach(split(//, $buf)){

		my $byte_old = $byte;
		$byte = ord($_);	# fetch byte (in decimal)

		#printf("0x%02x ",$byte);

		if (($byte_old == 202) && ($byte == 254)) {	# CA = 202, FE = 254
			$byte_cnt = 0;
			$byte_lock = 1;
		}

		if ($byte_lock == 1) {
			$byte_cnt++;
		}

		if ($byte_cnt == 20) {	# 20th byte after CAFE in header
			$sample_msb = $byte;
		}
		if ($byte_cnt == 21) {	# 21th byte after CAFE in header
			$sample_lsb = $byte;
		}

		if (($byte_cnt == 22) && ($byte_lock == 1)) {	# lock down and concatenate
			$byte_lock = 0;
			$byte_cnt = 0;

			my $sample_8b_m = sprintf("%08b", $sample_msb);
			my $sample_8b_l = sprintf("%08b", $sample_lsb);

			my $sample_16b = $sample_8b_m . $sample_8b_l;

			# convert bin to decimal
			my $sample_16b_unsigned_dec = oct("0b".$sample_16b);

			my $out_form = sprintf("%d, %s, \n", $ct++, $sample_16b_unsigned_dec);

			printf $fh $out_form;
		}

	}

}
close(F);
close($fh);
print "done\n";
