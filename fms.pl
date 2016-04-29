#!/usr/bin/perl -W

# Benötigt libxml-simple-perl
use XML::Simple qw(:strict);
use Data::Dumper;

my $xml_path = "html/fuhrpark.xml";

my $fms;
my $xml = XML::Simple->new(ForceArray => [], KeyAttr => [], KeepRoot => 1, NoAttr => 1, OutputFile => $xml_path);
my $fuhrpark = $xml->XMLin($xml_path);

my $id;
my $status;

while(my $stdin = <STDIN>) {
	# Nur korrekte Stati verwenden
	if ($stdin && $stdin =~ m/correct/) {
		# Vom Fahrzeug?
               	if($stdin =~ m/FMS: ([^\s]*).*0=FZG->LST/) {
			# 48 Bit FMS ausschneiden
			$fms = $1;
			# ID ausschneiden
			$id = substr($fms,4,8);
			# Status ausschneiden
			$status = substr($fms,3,1);


			# Suche in unseren Fahrzeugen nach ID
			for (my $fzg = 0; $fzg <= $#{$fuhrpark->{fuhrpark}->{fahrzeug}}; $fzg++) {
				#printf $fuhrpark->{fuhrpark}->{fahrzeug}->[$fzg]->{id} . "\n";
				if ($id eq $fuhrpark->{fuhrpark}->{fahrzeug}->[$fzg]->{id}) {
					if ($status > 0 && $status < 7 && $status != 5) {
						print ("FMS: $fms\n");
						print "Found in XML, updating status for $id to $status\n";
						$fuhrpark->{fuhrpark}->{fahrzeug}->[$fzg]->{status} = $status;
						$fuhrpark->{fuhrpark}->{fahrzeug}->[$fzg]->{timestamp} = time();
						$xml->XMLout($fuhrpark);
					}
				}
			}
		}
	}
}
