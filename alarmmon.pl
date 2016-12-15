#!/usr/bin/perl -W
use strict;
use warnings;

use Time::localtime;
use File::stat;
use File::Copy qw(copy);
use Config::Simple;
use Proc::Daemon;
use File::Path qw(make_path);
use File::Basename;
use Mail::POP3Client;
use MIME::Parser;

my $cfg = new Config::Simple('/etc/alarmmon.cfg') or die ("ERROR: Can't open /etc/alarmmon.cfg\n");
my %Config = $cfg->vars();

my @fax_files;
my @remote_files;
my $timestamp = 0;

my $event;

my $idle = 0;
my $ffile;

my $ocr_out = $Config{extract_path} . "/ocr.txt";
my $ocr_file = $Config{extract_path} . "/out.txt";
my $fax_file = $Config{extract_path} . "/fax.tif";

my $continue = 1;

make_path($Config{pop3_path});
make_path($Config{extract_path});
make_path($Config{fax_path},{mode=>0777});

$SIG{TERM} = sub { $continue = 0 };

if ($Config{enable_fms}) {
	#FMS decoder starten
	print "starting FMS decoder";
	system("arecord -f S16_LE -t raw -c 1 -r 20000 | ./fms_decoder | ./fms.pl &");
}

my $parser;
my $pop;

	#match against abschnitt if no objekt, else against objekt
	#AS Nersingen / Behelfsumfahrung Moserrampe
	#B10 Neu-Ulm > Ulm AS Neu-Ulm / Landesgrenze BW (9,25 bis 10,8)
	#Fl Donau
my @highways = (
	['B28','AS Senden','https://www.google.com/maps/embed?pb=!1m14!1m12!1m3!1d25226.797278690363!2d10.02952679108558!3d48.34821641268395!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!5e0!3m2!1sde!2sde!4v1478694917637'],
	['B28','Überleitung B28 / B30 Wiblingen','https://www.google.com/maps/embed?pb=!1m14!1m12!1m3!1d12609.22130206609!2d9.994767973980975!3d48.3650920095004!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!5e0!3m2!1sde!2sde!4v1478694966011'],
	['A7','Parkplatz Leibisee-Ost AS Nersingen','https://www.google.com/maps/embed?pb=!1m14!1m12!1m3!1d4451.793257854581!2d10.11034860612837!3d48.436339672831785!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!5e0!3m2!1sde!2sde!4v1478693521362'],
	['A7','Parkplatz Hahnenberg-West AS Nersingen','https://www.google.com/maps/embed?pb=!1m14!1m12!1m3!1d5299.121489491573!2d10.086086083483618!3d48.388173690688355!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!5e0!3m2!1sde!2sde!4v1478695330295'],
	['A7','AS Nersingen / Behelfsumfahrung Moserrampe','https://www.google.com/maps/embed?pb=!1m14!1m12!1m3!1d17804.93034756187!2d10.113632555731657!3d48.44273782889928!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!5e0!3m2!1sde!2sde!4v1478693046054'],
	['Donau','Fl Donau','https://www.google.com/maps/embed?pb=!1m14!1m12!1m3!1d14980.068153241617!2d10.043441491120616!3d48.415707168750416!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!5e0!3m2!1sde!2sde!4v1478693697358'],
	['A7','AS Nersingen / AD Hittistetten','https://www.google.com/maps/embed?pb=!1m14!1m12!1m3!1d29989.158628853886!2d10.05740052741409!3d48.36643831730517!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!5e0!3m2!1sde!2sde!4v1478694868275']
);

if ($Config{enable_pop3}) {
	$parser = new MIME::Parser;
	$pop = new Mail::POP3Client(
		DEBUG    => 0,
		HOST     => $Config{pop3_server},
		USESSL   => "true"
	);
	$pop->User($Config{pop3_user});
	$pop->Pass($Config{pop3_password});
}

# Auf neues Fax warten:
while ($continue) {
	# Können wir einen Idle-Screen zeigen?
        if (!$idle) {
		# Ja, aber nur wenn timestamp noch nicht gesetzt ist (startup) oder der Alarm min 30 Minuten zurückliegt.
   		if (!$timestamp || $timestamp + 60 * 60 < time()) {
			print "going back to idle screen\n";
			render_idle();
			update_timestamp();
			$idle = 1;
		}
	}

	if ($Config{enable_pop3}) {
		print "Checking for new mail...\n";
		if($pop->Connect() >= 0) {
			$parser->output_dir($Config{pop3_path});
			$parser->output_to_core();

			for (my $i = 1; $i <= $pop->Count(); $i++) {
				# Anhänge jeder Mail in pop3_path speichern
				print "Fetching message #$i\n";
				my $msg = $pop->HeadAndBody($i);
				my $entity = $parser->parse_data($msg);
	
				# Alle Anhänge durchgehen
				if (opendir my($dh), "$Config{pop3_path}") {
					# .tif unf .pdf Datein herauspicken und in den remote_path kopieren, zur weiteren Verarbeitung
					my @extract_files = grep { !/^\.\.?$/ } readdir $dh;
					for my $efile (@extract_files) {
						if ($efile =~ m/\.(pdf|tif)$/i) {
							copy "$Config{pop3_path}/$efile", "$Config{remote_path}/";
						}
					}
	
					# danach aufräumen
					my @clean = glob ("$Config{pop3_path}/*");
					if (@clean) {
						 unlink @clean;
					}
				}
	
				# E-Mail auf Server löschen
				$pop->Delete($i);
			}
			$pop->Close();
 		} else {
			print $pop->Message();
		}
	}

	# TODO vorher prüfen mit nem notifyWatch ob sich was am Pfad ändert? Email nicht so oft abrufen?
	if (opendir my($dh), "$Config{fax_path}") {
		@fax_files = grep { !/^\.\.?$/ } readdir $dh;
		closedir $dh;
		if (opendir my($dh), "$Config{remote_path}") {
			@remote_files = grep { !/^\.\.?$/ } readdir $dh;
			closedir $dh;
			chomp(@fax_files);
			chomp(@remote_files);

			# nach neuen Dateien suchen
			for my $rfile (@remote_files) {
				chomp($rfile);
				if ( my @list = grep /^$rfile$/, @fax_files) {
					# File existiert bereits in fax_path
			        } else {
					$idle = process_fax($rfile);
					if (!$idle) {
						print "updating timestamp...\n";
						update_timestamp();
					}
					print "all done.\n";
				}
			}

			# nicht mehr vorhandene Dateien löschen
			for my $ffile (@fax_files) {
				chomp($ffile);
				if ( my @list = grep /^$ffile$/, @remote_files) {
			        } else {
					print "purging $Config{fax_path}/$ffile\n";
					unlink "$Config{fax_path}/$ffile";
				}
			}
		} else {
			print "ERROR: Can't open $Config{remote_path}\n";
		}
	} else {
		print "ERROR: Can't open $Config{fax_path}\n";
	}

	sleep ($Config{check_interval});
}

sub process_fax {
	# Parameterübergabe
	my $rfile = shift(@_);

	my $dest = "$Config{fax_path}/$rfile";
	my $source = "$Config{remote_path}/$rfile";

	my %Parsed;
	my $ocr_txt;
	my @clean;

	print "copying new file $rfile\n";
	copy $source, $dest;

	# Aufräumen
	print "cleaning up...\n";
	@clean = glob ("$Config{extract_path}/*");
	if (@clean) {
		 unlink @clean;
	}

	# pdf-Datei - Bilder extrahieren, drucken, dann Texterkennung
	if ($dest =~ /\.pdf$/i) {
		# Bilder aus .pdf angeln
		print "extracting images from .pdf ...\n";
		`pdfimages -p $dest $Config{extract_path}/`;

		# Ausdrucken
		if ($Config{print_fax} == 1) {
			print "printing...\n";
			`lp -o orientation-requested=3 -o position=top $Config{extract_path}/*`;
		}

		# Zusammenkleben
		print "concatenating ...\n";
		`convert -extent 1724x2438 $Config{extract_path}/*.* -append $fax_file`;
	}

	# tif-Datei - nur drucken und dann Texterkennung
	if ($dest =~ /\.tif$/i) {
		copy $dest, $fax_file;

		# TODO split up file to pages
		# Ausdrucken
		if ($Config{print_fax} == 1) {
			print "printing...\n";
			`lp -o orientation-requested=3 -o position=top $fax_file`;
		}
	}

	# .txt datei direkt parsen
	if ($dest =~ /\.txt$/i) {
		copy $dest, $ocr_out;
	} else {
		# OCR auf neuem Fax
		print "doing ocr...\n";
		if ($Config{fast_ocr} == 1) {
		        `./cheap_ocr -f font/font.tif -o $ocr_out $fax_file`;
		} else {
			`tesseract $fax_file basename($ocr_out, ".txt") -psm 3 -l ils`;
		}

		print "checking if from ILS Donau Iller...";
		local $/=undef;
		if (!open FILE, $ocr_out) {
			print "Couldn't open file: $!";
			return 1;
		}

		$ocr_txt= <FILE>;
		close FILE;

		if ($ocr_txt !~ m/.LS\sDonau/) {
			print "No.\n";
			return 1;
		}
		print "Yes!\n";

	}

	# Spaces am Zeilenanfang und Ende entfernen
	`cat $ocr_out | sed -e 's/^\\s*//g;s/\\s*\$//g' > $ocr_file`;

	print "parsing and rendering...\n";

	# ocr.txt parsen
	%Parsed = parse_txt($dest, $ocr_txt);

	# Werte in templates einfügen und html Datein erzeugen
	render_alarm_templates(\%Parsed);

	# not idle
	return 0;
}

sub parse_txt {
	my $path = shift(@_);
	my %Parsed;
	my $mittel;
	my $geraet;
	my @coord;

	#cat /tmp/extract/out.txt | sed -n '/^Str.Abschn\s*.\s*/,/^Ort\s*.\s*/p' | grep -v '^Ort\s*.\s*'

	$Parsed{alarmzeit} = ctime( stat($path)->ctime);
	$Parsed{alarmzeit} =~ s/.*([0-9][0-9]:[0-9][0-9]:[0-9][0-9]).*/$1/;

	# Alle möglichen Infos aus dem generierten Text herausparsen
	# $mittel = `grep -v 'Rufnummer' $ocr_file | grep 'Name.*' | sed -e 's/Name.*\\(\\[:alphanum:\\]*\\)/\\1/' | sed -e '7\\.3\\..\\s\\(.*\\)/\\1/' | sed -e 's/Name\\s*.s*\\(.*\\)/\\1/'`;
	$mittel = `cat $ocr_file | sed -e '1,/MITTEL/d' | grep '^Name' | sed -e 's/^Name\\s*.\\s7\\.3\\..\\s*//' | sed -e 's/^Name\\s*.\\s//'`;
	$Parsed{mittel} = [split /^/, $mittel];

	$geraet = `cat $ocr_file | sed -e '1,/MITTEL/d' | grep 'Gef.Ger.t' | sed -e 's/Gef.Ger.t//' | sed -e 's/\\s*.\\s*//'`;
	$Parsed{geraet} = [split /^/, $geraet];

	$Parsed{strasse} = `grep '^Stra.s\\?e.*' $ocr_file | sed -e 's/ *(.*)//; s/\\s*Haus.Nr.*//; s/^Stra.s\\?e\\s*.\\s*//;'`;
	$Parsed{strasse} =~ s/\n//g;
	$Parsed{strasse} =~ s/^\s+|\s+$//g;

	$Parsed{hausnummer} = `sed -e '/^.*Haus.Nr.\\s*.\\s*/!d; s///;q' < $ocr_file`;
	$Parsed{hausnummer} =~ s/\n//g;
	$Parsed{hausnummer} =~ s/^\s+|\s+$//g;

	#kann über mehrere Zeilen gehen
	$Parsed{abschnitt} = `cat $ocr_file | sed -n '/^Str.Abschn\\s*.\\s*/,/^Ort\\s*.\\s*/p' | sed -e 's/^Str.Abschn\\s*.\\s*//' -e 's/^Ort\\s*.\\s*.*//'`;
	$Parsed{abschnitt} =~ s/\n//g;
	$Parsed{abschnitt} =~ s/^\s+|\s+$//g;

	$Parsed{ort} = `sed -e '/^Ort\\s*.\\s*/!d; s///;q' < $ocr_file`;
	$Parsed{ort} =~ s/\\n//;
	$Parsed{ort} =~ s/^\s+|\s+$//g;
	# Alles nach ' - ' abschneiden
	$Parsed{ort} =~ s/\s-\s.*$//;

	#kann über mehrere Zeilen gehen
	$Parsed{objekt} = `cat $ocr_file | sed -n '/^Objekt\\s*.\\s*/,/^Station\\s*.\\s*/p' | sed -e 's/^Objekt\\s*.\\s*//' -e 's/^Station\\s*.\\s*.*//'`;
	$Parsed{objekt} =~ s/\n//g;
	$Parsed{objekt} =~ s/^\s+|\s+$//g;

	$Parsed{station} = `sed -e '/^Station\\s*.\\s*/!d; s///;q' < $ocr_file`;
	$Parsed{station} =~ s/\n//g;
	$Parsed{station} =~ s/^\s+|\s+$//g;

	$Parsed{schlagwort} = `sed -e '/^Schlag..\\s*.\\s*/!d; s///;q' < $ocr_file`;
	$Parsed{schlagwort} =~ s/\n//g;
	$Parsed{schlagwort} =~ s/^\s+|\s+$//g;

	$Parsed{x_coord} = `grep '^X-Koordinate.*' $ocr_file | sed -e 's/*(.)//; s/\\s*Y-Koordinate.*//; s/^X-Koordinate\\s*.\\s*//;'`;
	$Parsed{x_coord} =~ s/\n//g;
	$Parsed{x_coord} =~ s/^\s+|\s+$//g;

	$Parsed{y_coord} = `sed -e '/^.*Y-Koordinate\\s*.\\s*/!d; s///;q' < $ocr_file`;
	$Parsed{y_coord} =~ s/\n//g;
	$Parsed{y_coord} =~ s/^\s+|\s+$//g;

	#$Parsed{bemerkung} = `sed -n '/BEMERKUNG.*/{n;p}' < $ocr_file`;
	$Parsed{bemerkung} = `sed -e '1,/BEMERKUNG.*/d' < $ocr_file`;
	$Parsed{bemerkung} =~ s/^\s+|\s+$//g;

	if ($Parsed{x_coord} != '' && $Parsed{Y_coord} != '') {
		@coord = split(/\s+/, `cs2cs -f "%.13f" +init=epsg:31468 +to +init=epsg:4326 <<EOF\n$Parsed{x_coord} $Parsed{y_coord}\nEOF`);
		($Parsed{gps_long}, $Parsed{gps_lat}, @_)=@coord;
	} else {
		$Parsed{gps_long} = '';
		$Parsed{gps_lat} = '';
	}

	print "Strasse: '" . $Parsed{strasse} . "'\n";
	print "Hausnummer: '" . $Parsed{hausnummer} . "'\n";
	print "Abschnitt: '" . $Parsed{abschnitt} . "'\n";
	print "Ort: '" . $Parsed{ort} . "'\n";
	print "Objekt: '" . $Parsed{objekt} . "'\n";
	print "Station: '" . $Parsed{station} . "'\n";
	print "Schlagwort: '" . $Parsed{schlagwort} . "'\n";
	print "Bemerkung: '" . $Parsed{bemerkung} . "'\n";
	print "x-coord: '" . $Parsed{x_coord} . "'\n";
	print "y-coord: '" . $Parsed{y_coord} . "'\n";
	print "lat: '" . $Parsed{gps_lat} . "'\n";
	print "long: '" . $Parsed{gps_long} . "'\n";


	return %Parsed;
}

sub render_idle {
	#print "render_idle\n";
	my %Parsed;
	my @templates;
	my $html_file;

	if (opendir my($dh), "template") {
		@templates = grep { !/^\.\.?$/ } readdir $dh;
		closedir $dh;
	}
	for my $template (@templates) {
		$html_file = "html/" . basename($template,  ".tpl") . ".html";
		render_template(\%Parsed, "template/idle.tpl", $html_file);
	}
}

sub render_alarm_templates {
	my %Parsed = %{shift()};

        my $smittel = "";
        my $omittel = "";
	my $mittel = "";
	my $maxm = 0;

	my @geraet = @{$Parsed{geraet}};
	my @mittel = @{$Parsed{mittel}};

	my @templates;
	my $html_file;

	my $is_hw = 0;
	my $url = "";

	# Für das Einsetzen ins HTML-Template vorbereiten
	$Parsed{bemerkung} =~ s/$/<br>/mg;

	if ($Parsed{schlagwort} =~ m/Gefahr/) {
		$Parsed{schlagwort}="<div class=\"gefahr\">$Parsed{schlagwort}</div>";
	} else {
		$Parsed{schlagwort}="$Parsed{schlagwort}";
	}

	for my $i (0 .. $#mittel) {
		if ($mittel[$i] =~ m/$Config{own_ffw_name}/) {
			$smittel .= "<div class=\"eigene_mittel\">\n$mittel[$i]";
			if ($#geraet >= $i) {
				$geraet[$i] =~ s/^\s+|\s+$//g;
				if (length($geraet[$i]) > 0) {
					$smittel .= "<div class=\"geraet\">\n$geraet[$i]</div>";
				}
			}
			$smittel .= "</div>";
			$maxm++;
		}
	}
	for my $i (0 .. $#mittel) {
		if ($maxm > $Config{max_mittel}) {
			$i = $#mittel;
		} else {
			if ($mittel[$i] =~ m/$Config{own_ffw_name}/) {
			} else {
				$omittel .= "<div class=\"andere_mittel\">\n$mittel[$i]</div>";
				$maxm++;
			}
		}
	}

	if ($maxm > $Config{max_mittel}) {
		$omittel .= "<div class=\"andere_mittel\">...</div>";
	}

	$mittel = $smittel . $omittel;

	$Parsed{mittel} = $mittel;

	# > und < ersetzen
	$Parsed{strasse} =~ s/>/&gt;/g;
	$Parsed{abschnitt} =~ s/>/&gt;/g;

	$Parsed{strasse} =~ s/</&lt;/g;
	$Parsed{abschnitt} =~ s/</&lt;/g;

	# TODO in ein config-array auslagern?

        $is_hw = 0;
	if($Parsed{ort} eq '' or $Parsed{ort} =~ m/Default/) {
		$Parsed{adresse} = "";
		if ($Parsed{abschnitt} ne '') {
			$Parsed{adresse} .= "$Parsed{abschnitt}<br>";
		}
		if ($Parsed{objekt} ne '') {
			$Parsed{adresse} .= "$Parsed{objekt}<br>";
		}
		$Parsed{adresse} .= "(KM: $Parsed{hausnummer})";

		$Parsed{query} = "";
		$Parsed{map_tag} = '';
		$Parsed{map_tag_sat} = '';
		$Parsed{map_script} = '';

		# Erst mit Objekt vergleichen falsl vorhanden
		foreach my $loc (@highways) {
			if ($Parsed{strasse} =~ m/@$loc[0]/) {
				print "@$loc[0]\n";
				if ($Parsed{objekt} ne '' and $Parsed{objekt} =~ m/@$loc[1]/) {
					$is_hw = 1;
					print "@$loc[1]\n";
					$url = @$loc[2];
				}
                	}   
		}

		# Dann gegen Abshcnitt
		if (!$is_hw) {
			foreach my $loc (@highways) {
				if ($Parsed{strasse} =~ m/@$loc[0]/) {
					print "@$loc[0]\n";
					if ($Parsed{abschnitt} ne '' and $Parsed{abschnitt} =~ m/@$loc[1]/) {
						$is_hw = 1;
						print "@$loc[1]\n";
						$url = @$loc[2];
					}
       		         	}   
			}
		}

		$Parsed{map_tag} = '<div class="map"><iframe class="map" src="' . $url . '" scrolling="no"></iframe></div>';
	}
	if (!$is_hw) {
		$Parsed{adresse} = "";
		if (!$Parsed{ort} || $Parsed{ort} =~ m/Default/) {
			$Parsed{ort} = $Config{default_ort}
		}

		if ($Parsed{objekt} ne '') {
			$Parsed{adresse} .= "$Parsed{objekt}<br>";
		}

		$Parsed{adresse} .= "$Parsed{strasse} $Parsed{hausnummer}<br>";

		if ($Parsed{abschnitt} ne $Parsed{strasse} and $Parsed{abschnitt} ne '') {
			$Parsed{adresse} .= "$Parsed{abschnitt}<br>";
		}

		$Parsed{adresse} .= "$Parsed{ort}";

		$Parsed{query} = $Parsed{strasse} . " " . $Parsed{hausnummer} . ", " . $Parsed{ort};
		$Parsed{query} =~ s/\n//g;

		$Parsed{map_script} = '<script src="https://maps.googleapis.com/maps/api/js?region=DE" async defer></script>';

		$Parsed{map_tag} = '<div class="map" id="map"></div>';
		$Parsed{map_tag_sat} = '<div class="map" id="map_sat"></div>';
	}

	# query für Maps vorbereiten

	# Sanity check für Hausnummer
	# $Parsed{hausnummer} =~ s/l/1/g;		# l wird zu 1
	# $Parsed{hausnummer} =~ s/O/0/g;		# O wird zu 0
	# $Parsed{hausnummer} =~ s/o/0/g;		# o wird zu 0

	# TODO in andere sub routine auslagern?
	# Sanity check für Ort
	# #$Parsed{ort} =~ s/1/l/g;		# 1 wird zu l
	# #$Parsed{ort} =~ s/0/O/g;		# 0 wird zu O
	# $Parsed{ort} =~ s/([[:alpha:]])B/$1ß/g;	# B nach Kleinmbuchstabe wird zu ß

	if (opendir my($dh), "template") {
		@templates = grep { !/^\.\.?$/ } readdir $dh;
		closedir $dh;
	}
	for my $template (@templates) {
		$html_file = "html/" . basename($template,  ".tpl") . ".html";
		render_template(\%Parsed, "template/" . $template, $html_file);
	}

	return 0;
}

sub render_template {
	my %Parsed = %{shift()};
	my $tpl_path = shift(@_);
	my $html_path = shift(@_);

	my $template;

	if($Config{enable_fms} == 1) {
		$Parsed{status} = '<div id="status"></div>';
	} else {
		$Parsed{status} = '';
	}

	# Ins HTML-Template einfügen
	local $/=undef;
	if (!open FILE, $tpl_path) {
		print "Couldn't open file: $!";
		return 1;
	}
	$template= <FILE>;
	close FILE;

	$template =~ s/%map_script%/$Parsed{map_script}/g;
	$template =~ s/%map_tag%/$Parsed{map_tag}/g;
	$template =~ s/%map_tag_sat%/$Parsed{map_tag_sat}/g;
	$template =~ s/%query%/$Parsed{query}/g;
	$template =~ s/%mittel%/$Parsed{mittel}/g;
	$template =~ s/%strasse%/$Parsed{strasse}/g;
	$template =~ s/%nummer%/$Parsed{hausnummer}/g;
	$template =~ s/%abschnitt%/$Parsed{abschnitt}/g;
	$template =~ s/%ort%/$Parsed{ort}/g;
	$template =~ s/%objekt%/$Parsed{objekt}/g;
	$template =~ s/%station%/$Parsed{station}/g;
	$template =~ s/%adresse%/$Parsed{adresse}/g;
	$template =~ s/%schlagwort%/$Parsed{schlagwort}/g;
	$template =~ s/%bemerkung%/$Parsed{bemerkung}/g;
	$template =~ s/%alarmzeit%/$Parsed{alarmzeit}/g;
	$template =~ s/%status%/$Parsed{status}/g;

        # Neue index.html ausgeben
        if (!open(FILE, '>', $html_path)) {
		print "Couldn't open file: $!";
		return 1;
	}
	print FILE $template;
	close FILE;
}

sub update_timestamp {
	$timestamp = time();
	# Neuen tiemstamp schreiben und Seite damit zum reload zwingen
	if (!open(FILE, '>', "html/timestamp.txt")) {
		print "Couldn't open file: $!";
		return;
	}
	print FILE "<timestamp>$timestamp</timestamp>";
	close FILE;
}
