#!/usr/bin/perl -W

## Benötigt libfile-changenotify-perl
#use File::ChangeNotify;
use Time::localtime;
use File::stat;

#use Filesys::Notify::Simple;

my $template_alarm = "template/index.tpl";
my $html_name = "html/index.html";
my $template_idle = "template/idle.tpl";
my $timestamp_name = "html/timestamp.txt";
my $fax_path = "fax";
my $remote_path = "/media/fritzbox/FRITZ/faxbox";
my $extract_path = "/tmp/extract";
my $ocr_path = "/tmp/ocr";
my $ocr_file = "out";
my $ocr_txt_name = $ocr_path . "/" . $ocr_file . ".txt";
my $fms_path = "/tmp/fms";
my $fms_file = "fms.txt";

my @fax_files;
my @remote_files;

my $timestamp = 0;

#my $watcher = File::ChangeNotify->instantiate_watcher
#       ( directories => [ "./$fax_path/" ],
#         regex       => qr/\.(?:tif)$/,
#       );

my $event;

my $idle = 0;
my $ffile;

# Fax zuerst ausdrucken, dann rendern!

`mkdir -p $extract_path`;
`mkdir -p $ocr_path`;
`mkdir -p $fax_path`;
`mkdir -p $fms_path`;

# Auf neues Fax warten:
while (1) {
	# Können wir einen Idle-Screen zeigen?
        purge();
        if (!$idle) {
		# Ja, aber nur wenn timestamp noch nicht gesetzt ist (startup) oder der Alarm min 30 Minuten zurückliegt.
   		if (!$timestamp || $timestamp + 60 * 60 < time()) {
			print "going back to idle screen\n";
			render_idle();
			$idle = 1;
		}
	}
	@fax_files = `ls --color=never -tx1 $fax_path/`;
	@remote_files = `ls --color=never -tx1 $remote_path/`;
	chomp(@fax_files);
	chomp(@remote_files);
	for my $rfile (@remote_files) {
		chomp($rfile);
		#print "checking " . $rfile . "\n";
		if ( my @list = grep /^$rfile$/, @fax_files) {
	        } else {
			`cp $remote_path/$rfile $fax_path/$rfile`;
			print "copying new file $rfile\n";
			$idle = render_alarm("$fax_path/$rfile");
		}
	}


#	Alte Methode
#	# Können wir einen Idle-Screen zeigen?
#       if (!$idle) {
#		# Ja, aber nur wenn timestamp noch nicht gesetzt ist (startup) oder der Alarm min 30 Minuten zurückliegt.
#  		if (!$timestamp || $timestamp + 30 * 60 < time()) {
#			render_idle();
#			$idle = 1;
#		}
#	}
#	# Nach neuen Faxen prüfen
#	for $event ( $watcher->new_events() ) {
#		if ($event->type eq "create") {
#			#print "test! " . $event->path() . " " . $event->type() . "\n";
#			# Idle nur zurücksetzen wenn wirklich eine neue Seite generiert wurde (also z.B. ILS Fax kam und keine Werbung)
#			$idle = render_alarm($event->path());
#		}
#	}
	sleep (5);
}
#exit 1;

sub purge {
	@fax_files = `ls --color=never -tx1 $fax_path/`;
	@remote_files = `ls --color=never -tx1 $remote_path/`;
	chomp(@fax_files);
	chomp(@remote_files);
	for my $ffile (@fax_files) {
		chomp($ffile);
		#print "checking " . $rfile . "\n";
		if ( my @list = grep /^$ffile$/, @remote_files) {
	        } else {
			print "purging $fax_path/$ffile\n";
			`rm $fax_path/$ffile`;
		}
	}
}

sub render_idle {
	#print "render_idle\n";
	my $template;

	local $/=undef;
	if (!open FILE, $template_idle) {
		print "Couldn't open file: $!";
		return;
	}
	$template= <FILE>;
	close FILE;

        # Neue index.html ausgeben
	if (!open(FILE, '>', $html_name)) {
		print "Couldn't open file: $!";
		return;
	}
	print FILE $template;
	close FILE;
	update_timestamp();
}

sub render_alarm {
	#print "render_alarm\n";
	# Parameterübergabe
	my $path = shift(@_);

	# Benötigte Variablen
	my @mittel;
	my $schlagwort;
	my $bemerkung;
	my $strasse;
	my $hausnummer;
	my $abschnitt;
	my $ort;
	my $objekt;
	my $station;
	my $mit;
	my $mittel;
	my $geraet;
	my @geraet;
        my $smittel;
        my $omittel;
	my $query;
	my $map_script;
	my $map_tag;

	my $ocr_txt;
	my $template;

	my $alarmzeit;

	my $gefahr;

	print "printing...\n";
	`lp $path`;

	# Bilder aus .pdf angeln
	print "extracting images from .pdf ...\n";
	`pdfimages -p $path $extract_path/`;
	# Zusammenkleben
	print "concatenating ...\n";
        `convert $extract_path/*.* -append $extract_path/fax.tif`;

	# Ausdrucken
	# OCR auf neuem Fax
	print "doing ocr...\n";
	`tesseract $extract_path/fax.tif $ocr_path/$ocr_file -psm 4 -l ils`;
        #`./cheap_ocr -f font.tif -o $ocr_txt_name $extract_path/fax.tif`;

	# Aufräumen
	print "cleaning up...\n";
	`rm $extract_path/*`;

	local $/=undef;
	if (!open FILE, $ocr_txt_name) {
		print "Couldn't open file: $!";
		return 1;
	}

	print "checking if from ILS Donau Iller...";
	$ocr_txt= <FILE>;
	close FILE;

	if ($ocr_txt !~ m/.LS\sDonau/) {
		print "No.\n";
		return 1;
	}
	print "Yes!\n";

	print "parsing and rendering...\n";
	local $/=undef;
	if (!open FILE, $template_alarm) {
		print "Couldn't open file: $!";
		return 1;
	}
	$template= <FILE>;
	close FILE;

	$alarmzeit = ctime( stat($path)->ctime);
	$alarmzeit =~ s/.*([0-9][0-9]:[0-9][0-9]:[0-9][0-9]).*/$1/;

	# Alle möglichen Infos aus dem generierten Text herausparsen
	# $mittel = `grep -v 'Rufnummer' $ocr_txt_name | grep 'Name.*' | sed -e 's/Name.*\\(\\[:alphanum:\\]*\\)/\\1/' | sed -e '7\\.3\\..\\s\\(.*\\)/\\1/' | sed -e 's/Name\\s*.s*\\(.*\\)/\\1/'`;
	$mittel = `grep -v 'Rufnummer' $ocr_txt_name | grep 'Name.*' | grep -v 'Rufnummer' $ocr_txt_name | grep 'Name.*' | sed -e 's/7\\.3\\..\\s//' | sed -e 's/Name\\s*.\\s*//'`;
	@mittel = split /^/, $mittel;

	$geraet = `grep 'Gef.Ger.t.*' $ocr_txt_name | sed -e 's/Gef.Ger.t\\s*.\\s*//'`;
	@geraet = split /^/, $geraet;

	##echo 'Angeforderte Geräte:'
	##grep 'Gef.Ger.t' $ocr_txt_name | sed -e 's/Gef.Ger.t\s*.\s*\(.*\)/\1/'
	##echo 'Alarmiert:'
	##grep 'Alarmiert' $ocr_txt_name | sed -e 's/Alarmiert\s*.\s*\(.*\)/\1/'
	#sed -e '/^Einsatznummer\s*.\s*/!d; s///;q' < $ocr_txt_name
	$strasse = `grep 'Stra.e.*' $ocr_txt_name | sed -e 's/ *(.*)//; s/\\sHaus.Nr.*//; s/Stra.e\\s*.\\s*//;'`;
	$strasse =~ s/^\s+|\s+$//g;

	$hausnummer = `sed -e '/^.*Haus.Nr.\\s*.\\s*/!d; s///;q' < $ocr_txt_name`;
	$hausnummer =~ s/^\s+|\s+$//g;

	$abschnitt = `sed -e '/^Str.A.schn\\s*.\\s*/!d; s///;q' < $ocr_txt_name`;
	$abschnitt =~ s/^\s+|\s+$//g;

	$ort = `sed -e '/^Ort\\s*.\\s*/!d; s///;q' < $ocr_txt_name`;
	$ort =~ s/^\s+|\s+$//g;
	# Alles nach ' - ' abschneiden
	$ort =~ s/\s-\s.*$//;

	$objekt = `sed -e '/^Objekt\\s*.\\s*/!d; s///;q' < $ocr_txt_name`;
	$station = `sed -e '/^Station\\s*.\\s*/!d; s///;q' < $ocr_txt_name`;
	$schlagwort = `sed -e '/^Schlag..\\s*.\\s*/!d; s///;q' < $ocr_txt_name`;
	$bemerkung = `sed -n '/^.*BEMERKUNG.*/{n;p}' < $ocr_txt_name`;

	# Für das Einsetzen ins HTML-Template vorbereiten

	if ($schlagwort =~ m/Gefahr/) {
		$schlagwort="<div class=\"gefahr\">$schlagwort</div>";
	} else {
		$schlagwort="<div class=\"schlagw\">$schlagwort</div>";
	}

	$mittel = "";
 	$smittel = "";
 	$omittel = "";

	print "$#mittel $#geraet\n";
	for my $i (0 .. $#mittel) {
		if ($mittel[$i] =~ m/Straß/) {
			$smittel .= "<div class=\"eigene\">";
			$smittel .= "<div class=\"mittel\">\n$mittel[$i]</div>";
			$smittel .= "<div class=\"geraet\">\nGef. Gerät: $geraet[$i]</div>";
			$smittel .= "</div>";
		} else {
			$omittel .= "<div class=\"andere\">\n$mittel[$i]</div>";
		}
	}
	$mittel = $smittel . $omittel;

	# > und < ersetzen
	$strasse =~ s/>/&gt;/g;
	$abschnitt =~ s/>/&gt;/g;

	$strasse =~ s/</&lt;/g;
	$abschnitt =~ s/</&lt;/g;

	if (!$ort || $ort =~ m/Default/) {
		$ort = "Nersingen"
	}

	# query für Maps vorbereiten

	# Sanity check für Hausnummer
	$hausnummer =~ s/l/1/g;		# l wird zu 1
	$hausnummer =~ s/O/0/g;		# O wird zu 0
	$hausnummer =~ s/o/0/g;		# o wird zu 0

	# Sanity check für Ort
	$ort =~ s/1/l/g;		# 1 wird zu l
	$ort =~ s/0/O/g;		# 0 wird zu O
	$ort =~ s/([[:alpha:]])B/$1ß/g;	# B nach Kleinmbuchstabe wird zu ß

	if ($strasse =~ m/A7/) {
		$query = "";

		$map_script = "";
		$map_tag = '<iframe class="map" src="http://autobahnatlas-online.de/A7.htm#Ulm" scrolling="no"></iframe>';
	} else {
		$strasse =~ s/1/l/g;
		$strasse =~ s/0/O/g;
		$strasse =~ s/([[:alpha:]])B/$1ß/g;

		$query = $strasse . " " . $hausnummer . ", " . $ort;
		$query =~ s/\n//g;

		$map_script = '<script src="https://maps.googleapis.com/maps/api/js?region=DE" async defer></script>';
		$map_tag = '<div class="map" id="map"></div>';
	}

	# Ins HTML-Template einfügen
	$template =~ s/%map_script/$map_script/;
	$template =~ s/%map_tag/$map_tag/;
	$template =~ s/%mittel/$mittel/;
	$template =~ s/%query/$query/;
	$template =~ s/%mittel/$mittel/;
	$template =~ s/%strasse/$strasse/;
	$template =~ s/%nummer/$hausnummer/;
	$template =~ s/%abschnitt/$abschnitt/;
	$template =~ s/%ort/$ort/;
	$template =~ s/%objekt/$objekt/;
	$template =~ s/%station/$station/;
	$template =~ s/%schlagwort/$schlagwort/;
	$template =~ s/%bemerkung/$bemerkung/;
	$template =~ s/%alarmzeit/$alarmzeit/;

        # Neue index.html ausgeben
        if (!open(FILE, '>', $html_name)) {
		print "Couldn't open file: $!";
		return 1;
	}
	print FILE $template;
	close FILE;

	print "updating timestamp...\n";
	update_timestamp();
	print "all done.\n";
	return 0;
}

sub update_timestamp() {
	$timestamp = time();
	# Neuen tiemstamp schreiben und Seiet damit zum reload zwingen
	if (!open(FILE, '>', $timestamp_name)) {
		print "Couldn't open file: $!";
		return;
	}
	print FILE "<timestamp>$timestamp</timestamp>";
	close FILE;
}
