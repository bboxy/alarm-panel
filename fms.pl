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

local $SIG{ALRM} = sub {
	alarm(60);
	print "timeout\n";
	# Suche in unseren Fahrzeugen nach alten Einträgen
	for (my $fzg = 0; $fzg <= $#{$fuhrpark->{fuhrpark}->{fahrzeug}}; $fzg++) {
		if (time() > $fuhrpark->{fuhrpark}->{fahrzeug}->[$fzg]->{timestamp} + 6 * 60 * 60) {
			if ($fuhrpark->{fuhrpark}->{fahrzeug}->[$fzg]->{status} != 2) {
				print "expiring entry\n";
				$fuhrpark->{fuhrpark}->{fahrzeug}->[$fzg]->{status} = 2;
				$fuhrpark->{fuhrpark}->{fahrzeug}->[$fzg]->{timestamp} = time();
				$xml->XMLout($fuhrpark);
			}
		}
	}
};

alarm(1);

while(<>) {
	print "$_";
        #if (!$stdin) {
        #    print "timer\n";
        #    $time = time();
        #}
        # XXX TODO exprire periodically here? but how? xml is open here -> while stdin or timer -> if timer tick -> check timestamps, if stadin !="" also rest?
	# Nur korrekte Stati verwenden
	if ($_ && $_ =~ m/correct/) {
		# Vom Fahrzeug?
               	if($_ =~ m/FMS: ([^\s]*).*FZG->LST/) {
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
						# set new time stamp first to aoid expiring and reset to status 2
						$fuhrpark->{fuhrpark}->{fahrzeug}->[$fzg]->{timestamp} = time();
						print ("FMS: $fms\n");
						print "Found in XML, updating status for $id to $status\n";
						$fuhrpark->{fuhrpark}->{fahrzeug}->[$fzg]->{status} = $status;
						$xml->XMLout($fuhrpark);
					}
				}
			}
		}
	}
}
print "fms.pl Exiting...\n";
