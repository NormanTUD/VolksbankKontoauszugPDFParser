use strict;
use warnings;
use Data::Dumper;

sub main {
	my @files = @_;
	my @ueberweisungen = ();
	foreach my $filename (@_) {
		die "Unknown file $filename" unless -e $filename;
		my $contents = qx(pdftotext -layout $filename -);
		push @ueberweisungen, parse($contents);
	}
	
	my $gesamtwert = 0;
	my $max_wert = 0;
	my $min_wert = 99999999999999999999999999999;
	print "Typ; Wert\n";
	my %typ_wert = ();
	foreach my $ueberweisung (@ueberweisungen) {
		if(exists $ueberweisung->{wert}) {
			$gesamtwert += $ueberweisung->{wert};
			$max_wert = $gesamtwert if $gesamtwert > $max_wert;
			$min_wert = $gesamtwert if $gesamtwert < $min_wert;
			$typ_wert{$ueberweisung->{typ}} += $ueberweisung->{wert};
			#print $ueberweisung->{typ}."; ".$ueberweisung->{wert}."\n";
		} else {
			die Dumper $ueberweisung;
		}
	}
	
	foreach my $typ (keys %typ_wert) {
		print "$typ; $typ_wert{$typ}\n";
	}
	#print "Gesamtwert: $gesamtwert\nMax-Wert: $max_wert\nMin-Wert: $min_wert\n";
}

sub parse {
	my $str = shift;
	my @blocks = ();

	my $date_re = qr#\d+.\d+\.\s+\d+.\d+\.\s+#;
	while ($str =~ m#^\s*($date_re.*?)($date_re|\R\R)#gism) {
		my $first_match = $1;
		my $second_match = $2;
		my $pos = pos($str);
		pos($str) = $pos - length($second_match) - length($first_match);
		push @blocks, $first_match;
	}

	my @parsed_blocks = ();
	foreach (@blocks) {
		push @parsed_blocks, parse_block($_);
	}
	return @parsed_blocks;
}

sub parse_block {
	my $block = shift;
	my %data = ();
	if($block =~ m#^\s*(\d+\.\d+\.)\s#) {
		$data{datum} = $1;
	}

	if($block =~ m#^\s*\d+\.\d+\.\s(.*?)\s+([0-9\.]*,\d+)\s*([HS])#) {
		my $typ = $1;
		my $zahl = $2;
		my $haben_oder_soll = $3;

		$typ =~ s#.*\s##g;

		$zahl =~ s#\.##g;
		$zahl =~ s#,#.#g;
		if($haben_oder_soll eq "S") {
			$zahl = -$zahl;
		}
		$data{wert} = $zahl;
		$data{typ} = $typ;
	}

	my $beschreibung = $block;
	$beschreibung =~ s/^(?:.*\n)//g;
	$beschreibung =~ s#^\s*##gism;

	$data{beschreibung} = $beschreibung;
	return \%data;
}

main(@ARGV);
