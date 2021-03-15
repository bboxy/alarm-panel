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
use File::DirCompare;
use Mail::POP3Client;
use MIME::Parser;
use LWP::Simple;
use URI::Escape;;

my $cfg = new Config::Simple('/etc/alarmmon.cfg') or die ("ERROR: Can't open /etc/alarmmon.cfg\n");
my %Config = $cfg->vars();

my @fax_files;
my @remote_files;
my $timestamp = 0;

my $event;

my $idle = 0;
my $ffile;

my $ocr_out = $Config{extract_path} . "/ocr.txt";
my $ocr_base = $Config{extract_path} . "/ocr";
my $ocr_file = $Config{extract_path} . "/out.txt";
my $fax_file = $Config{extract_path} . "/fax";

my $continue = 1;

make_path($Config{pop3_path});
make_path($Config{extract_path});
make_path($Config{fax_path},{mode=>0777});

$SIG{TERM} = sub { $continue = 0 };

my $parser;
my $pop;

if ($Config{enable_pop3}) {
	$parser = new MIME::Parser;
	$pop = new Mail::POP3Client(
		TIMEOUT  => 30,
		DEBUG    => 0,
		USER     => $Config{pop3_user},
		PASSWORD => $Config{pop3_password},
		HOST     => $Config{pop3_server},
		USESSL   => "true"
	);
}

my %Parsed;
my @templates;
my $html_file;

if (opendir my($dh), "widgets") {
	@templates = grep { !/^\.\.?$/ } readdir $dh;
	closedir $dh;
}
for my $template (@templates) {
	$html_file = "html/" . basename($template,  ".tpl") . ".html";
	render_template(\%Parsed, "widgets/" . $template, $html_file);
}

# Auf neues Fax warten:
while ($continue) {
	# Können wir einen Idle-Screen zeigen?
        if (!$idle) {
		# Ja, aber nur wenn timestamp noch nicht gesetzt ist (startup) oder der Alarm min 60 Minuten zurückliegt.
   		if (!$timestamp || (($timestamp + 3600) < time())) {
			print "going back to idle screen\n";
			render_idle();
			update_timestamp();
			$idle = 1;
		}
	}

	check_pop3();
	check_new_alarm();
	sleep ($Config{check_interval});
}

sub check_new_alarm_breaks {
	if (opendir my($dh), "$Config{fax_path}") {
		closedir $dh;
		if (opendir my($dh), "$Config{remote_path}") {
			closedir $dh;
			File::DirCompare->compare($Config{remote_path},$Config{fax_path}, sub {
				my ($remote, $fax) = @_;
				if (! $remote) {
					if ($Config{purge}) {
						print "purging $fax\n";
						unlink "$fax";
					}
				} else {
					if (!process_fax(basename($remote))) {;
						$idle = 0;
						print "updating timestamp...\n";
						update_timestamp();
						print "all done.\n";
					}
				}
			},
				{  }
			);
		}
	} else {
		# Im Fehlerfall versuchen zu mounten
		# `mount -a`;
		# autofs probieren
	}
}

sub check_new_alarm {
	my $rs;
	my $ls;
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
				my $lfile = (grep /^$rfile$/, @fax_files)[0];
				$rs = stat("$Config{remote_path}/$rfile");
				$ls = stat("$Config{fax_path}/$lfile");

				#printf "lfile: %s  rfile: %s\nlsize: %d  rsize: %d\n", $lfile, $rfile, $ls->size, $rs->size;

				if (!$lfile || ($rs->size != $ls->size)) {
					if (!process_fax($rfile)) {
						$idle = 0;
						print "updating timestamp...\n";
						update_timestamp();
						print "all done.\n";
					}
				}
			}

			# nicht mehr vorhandene Dateien löschen
			if ($Config{purge}) {
				for my $ffile (@fax_files) {
					chomp($ffile);
					if ( my @list = grep /^$ffile$/, @remote_files) {
				        } else {
						print "purging $Config{fax_path}/$ffile\n";
						unlink "$Config{fax_path}/$ffile";
					}
				}
			}
		} else {
			print "ERROR: Can't open $Config{remote_path}\n";
		}
	} else {
		print "ERROR: Can't open $Config{fax_path}\n";
	}
}

sub check_pop3 {
	my $count;
	if ($Config{enable_pop3}) {
		print "Checking for new mail...\n";
		if ($pop->Connect()) {
			if ($pop->Alive()) {
				$parser->output_dir($Config{pop3_path});
				$parser->output_to_core();

				my $count = $pop->Count();

				print "$count messages to fetch\n";

				for (my $i = 1; $i <= $count; $i++) {
					# Anhänge jeder Mail in pop3_path speichern
					print "Fetching message #$i\n";
					my $msg = $pop->HeadAndBody($i);
					my $entity = $parser->parse_data($msg);

					# Alle Anhänge durchgehen
					if (opendir my($dh), "$Config{pop3_path}") {
						# .txt, .tif und .pdf Datein herauspicken und in den remote_path kopieren, zur weiteren Verarbeitung
						my @extract_files = grep { !/^\.\.?$/ } readdir $dh;
						for my $efile (@extract_files) {
							if ($efile =~ m/\.(pdf|tif)$/i) {
								print "Extracted file $efile\n";
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
			}
		} else {
			print $pop->Message();
		}
	}
}

sub process_fax {
	# Parameterübergabe
	my $rfile = shift(@_);

	my $dest = "$Config{fax_path}/$rfile";
	my $source = "$Config{remote_path}/$rfile";

	my %Parsed;
	my $ocr_txt;
	my @clean;

	if ($dest =~/(\.sff|\.pdf|\.tif|\.txt)/i) {
		# Aufräumen
		print "cleaning up...\n";
		@clean = glob ("$Config{extract_path}/*");
		if (@clean) {
			 unlink @clean;
		}
		print "copying new file $rfile\n";
		copy $source, $dest || return 1;
	} else {
		return 1;
	}

	# sff-Datei - in .tif umwandeln
	if ($dest =~/\.sff$/i) {
		print "extracting images from .sff ...\n";
		`sfftobmp -tif $dest -o $Config{extract_path}/fax.tif`;
		`convert -crop 1724x2438 $Config{extract_path}/fax.tif $Config{extract_path}/fax_%d.tif`;
		unlink "$Config{extract_path}/fax.tif";
	}

	# pdf-Datei - Bilder extrahieren, drucken, dann Texterkennung
	if ($dest =~ /\.pdf$/i) {
		# Bilder aus .pdf angeln
		print "extracting images from .pdf ...\n";
		`pdfimages -p $dest $Config{extract_path}/`;
	}
	if ($dest =~ /\.tif$/i) {
		print "extracting images from .tif ...\n";
		`convert -crop 1724x2438 $dest $Config{extract_path}/fax_%d.tif`;
	}
	# .txt datei direkt parsen
	if ($dest =~ /\.txt$/i) {
		copy $dest, $ocr_out || return 1;
	} else {
		# Ausdrucken
		if ($Config{print_fax} > 1) {
			print "printing...\n";
			`lp -n $Config{print_fax} -o orientation-requested=3 -o position=top $Config{extract_path}/*`;
		}


		# OCR auf neuem Fax
		print "doing ocr...\n";
		if ($Config{ocr} eq "fast") {
			`convert -extent 1724x2438 $Config{extract_path}/*.* -append $fax_file.tif`;
		        `./cheap_ocr -f font/font.tif -o $ocr_out $fax_file`;
		}
		if ($Config{ocr} eq "tesseract") {
			`convert -extent 1724x2438 -crop 1724x2393+0+45 $Config{extract_path}/*.* -append $fax_file.tif`;
			`tesseract $fax_file.tif $ocr_base --psm 6 --oem 1 -l deu`;
		}
		if ($Config{ocr} eq "gocr") {
			`convert -extent 1724x2438 -crop 1724x2393+0+45 $Config{extract_path}/*.* -append $fax_file.pbm`;
			`gocr -m 2 -s 18 -a 100 -o $ocr_out $fax_file.pbm`;
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

	render_alarm_templates(\%Parsed);

	if ($Config{enable_divera} == 1) {
		divera_alarm(\%Parsed);
	}

	# Karte Ausdrucken
	if ($Config{print_map} > 0) {
		print "printing map...\n";
                `./map.pl --lat=$Parsed{gps_lat} --lon=$Parsed{gps_long} --width=1443 --height=1024 --zoom=17 --tileBase=$Config{map_server_url} --output=$Config{extract_path}/map.png`;
		`lp -n $Config{print_map} -o orientation-requested=4 -o position=top -o media=A4 $Config{extract_path}/map.png`;
	}
	# not idle
	return 0;
}

sub divera_alarm {
	my %Parsed = %{shift()};
	my $uri = $Config{divera_uri} . "?accesskey=" . $Config{divera_key} . "&title" . uri_escape($Parsed{schlagwort});
	print $uri . "\n";
	my $result = get($uri);
	print $result;
	return;
}

sub parse_txt {
	my $path = shift(@_);
	my %Parsed;
	my $mittel;
	my $geraet;
	my @coord;
	my @sw;

	$Parsed{alarmzeit} = ctime( stat($path)->ctime);
	$Parsed{alarmzeit} =~ s/.*([0-9][0-9]:[0-9][0-9]:[0-9][0-9]).*/$1/;

	# Alle möglichen Infos aus dem generierten Text herausparsen
	# $mittel = `grep -v 'Rufnummer' $ocr_file | grep 'Name.*' | sed -e 's/Name.*\\(\\[:alphanum:\\]*\\)/\\1/' | sed -e '7\\.3\\..\\s\\(.*\\)/\\1/' | sed -e 's/Name\\s*.s*\\(.*\\)/\\1/'`;
	$mittel = `cat $ocr_file | sed -e '1,/Stichwort/d' | grep '^Name' | sed -e 's/^Name\\s*..\\s7\\.3\\..\\s*//' | sed -e 's/^Name\\s*..\\s//'`;
	$Parsed{mittel} = [split /^/, $mittel];

	$geraet = `cat $ocr_file | sed -e '1,/Stichwort/d' | grep 'Gef.Ger.t' | sed -e 's/Gef.Ger.t//' | sed -e 's/\\s*.\\s*//'`;
	$Parsed{geraet} = [split /^/, $geraet];

	$Parsed{name} = `grep '^Name.*Rufnummer' $ocr_file | sed -e 's/ *(.*)//; s/\\s*Rufnummer.*//; s/^Name\\s*.\\s*//;'`;
	$Parsed{name} =~ s/\n//g;
	$Parsed{name} =~ s/^\s+|\s+$//g;

	$Parsed{rufnummer} = `grep '^Name.*Rufnummer' $ocr_file | sed -e '/^.*Rufnummer\\s*.\\s*/!d; s///;q'`;
	$Parsed{rufnummer} =~ s/\n//g;
	$Parsed{rufnummer} =~ s/^\s+|\s+$//g;

	$Parsed{strasse} = `grep '^Stra.s\\?e.*' $ocr_file | sed -e 's/ *(.*)//; s/\\s*Haus.Nr.*//; s/^Stra.s\\?e\\s*.\\s*//;'`;
	$Parsed{strasse} =~ s/\n//g;
	$Parsed{strasse} =~ s/^\s+|\s+$//g;

	# Falls Zeilenumbruch, nächste Zeile noch mitnehmen
	$Parsed{hausnummer} = `sed -n '/^.*Haus.Nr.\\s*.\\s*/,/^Str.Abschn/{s/^.*Haus.Nr.\\s*.\\s*//;/^Str.Abschn/d;p;}' < $ocr_file`;
	# $Parsed{hausnummer} = `sed -e '/^.*Haus.Nr.\\s*.\\s*/!d; s///;q' < $ocr_file`;
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

	# in PLZ + Stadt zerlegen
	$Parsed{stadt} = $Parsed{ort};
	$Parsed{plz} = $Parsed{ort};

	$Parsed{stadt} =~ s/.*\s+//;
	$Parsed{plz} =~ s/\s+.*//;

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
	@sw = split(/#/, $Parsed{schlagwort});
	$Parsed{schlagwort} = join(" ", $sw[2], $sw[3]);

	$Parsed{nummer} = `sed -e '/^Einsatznummer\\s*.\\s*/!d; s///;q' < $ocr_file`;
	$Parsed{nummer} =~ s/\n//g;
	$Parsed{nummer} =~ s/^\s+|\s+$//g;

	$Parsed{epn} = `sed -e '/^.*\\s*EPN\\s*.\\s*/!d; s///;q' < $ocr_file`;
	$Parsed{epn} =~ s/\n//g;
	$Parsed{epn} =~ s/^\s+|\s+$//g;

	$Parsed{x_coord} = `grep '.*X.Koordinate.*' $ocr_file | sed -e 's/*(.)//; s/\\s*Y.Koordinate.*//; s/.*X.Koordinate\\s*.\\s*//;'`;
	$Parsed{x_coord} =~ s/\n//g;
	$Parsed{x_coord} =~ s/^\s+|\s+$//g;

	$Parsed{y_coord} = `sed -e '/^.*Y.Koordinate\\s*.\\s*/!d; s///;q' < $ocr_file`;
	$Parsed{y_coord} =~ s/\n//g;
	$Parsed{y_coord} =~ s/^\s+|\s+$//g;

	#$Parsed{bemerkung} = `sed -n '/BEMERKUNG.*/{n;p}' < $ocr_file`;
	#$Parsed{bemerkung} = `sed -e '1,/BEMERKUNG.*/d' < $ocr_file`;
	$Parsed{bemerkung} = `sed -e '1,/BEMERKUNG/d' -e '/ZUSATZINFO/,\$d' < $ocr_file`;
	$Parsed{bemerkung} =~ s/\n//g;
	$Parsed{bemerkung} =~ s/^\s+|\s+$//g;

	if ($Parsed{x_coord} ne '' && $Parsed{y_coord} ne '') {
		@coord = split(/\s+/, `cs2cs -f "%.13f" +init=epsg:31468 +to +init=epsg:4326 <<EOF\n$Parsed{x_coord} $Parsed{y_coord}\nEOF`);
		($Parsed{gps_long}, $Parsed{gps_lat}, @_)=@coord;
	} else {
		$Parsed{gps_long} = '';
		$Parsed{gps_lat} = '';
	}

	print "Name: '" . $Parsed{name} . "'\n";
	print "Rufnummer: '" . $Parsed{rufnummer} . "'\n";
	print "Strasse: '" . $Parsed{strasse} . "'\n";
	print "Hausnummer: '" . $Parsed{hausnummer} . "'\n";
	print "Abschnitt: '" . $Parsed{abschnitt} . "'\n";
	print "Ort: '" . $Parsed{ort} . "'\n";
	print "PLZ: '" . $Parsed{plz} . "'\n";
	print "Stadt: '" . $Parsed{stadt} . "'\n";
	print "Objekt: '" . $Parsed{objekt} . "'\n";
	print "Station: '" . $Parsed{station} . "'\n";
	print "Schlagwort: '" . $Parsed{schlagwort} . "'\n";
	print "Bemerkung: '" . $Parsed{bemerkung} . "'\n";
	print "x-coord: '" . $Parsed{x_coord} . "'\n";
	print "y-coord: '" . $Parsed{y_coord} . "'\n";
	print "lat: '" . $Parsed{gps_lat} . "'\n";
	print "long: '" . $Parsed{gps_long} . "'\n";
	print "EPN: '" . $Parsed{epn} . "'\n";
	print "Einsatznummer: '" . $Parsed{nummer} . "'\n";
	print "Mittel:\n$mittel";
	print "Geforderte Geräte:\n$geraet";

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
					$smittel .= "<div class=\"geraet\">\n$geraet[$i]\n</div>\n";
				}
			}
			$smittel .= "</div>\n";
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

	# if ($Parsed{gps_lat} ne '' and $Parsed{gps_long} ne '') {
	#	$Parsed{query} = $Parsed{gps_lat} . " " . $Parsed{gps_long};
	# } else {
	#	$Parsed{query} = $Parsed{strasse} . " " . $Parsed{hausnummer} . ", " . $Parsed{ort};
	# }
	# $Parsed{query} =~ s/\n//g;

	# print "query: $Parsed{query}\n";

	# $Parsed{map_script} = '<script src="https://maps.googleapis.com/maps/api/js?region=DE" async defer></script>';

	# $Parsed{map_tag} = '<div class="map" id="map"></div>';
	# $Parsed{map_tag_sat} = '<div class="map" id="map_sat"></div>';

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

	$Parsed{status} = '';

	# Ins HTML-Template einfügen
	local $/=undef;
	if (!open FILE, $tpl_path) {
		print "Couldn't open file: $!";
		return 1;
	}
	$template= <FILE>;
	close FILE;

	#$template =~ s/%map_script%/$Parsed{map_script}/g;
	#$template =~ s/%map_tag%/$Parsed{map_tag}/g;
	#$template =~ s/%map_tag_sat%/$Parsed{map_tag_sat}/g;
	#$template =~ s/%query%/$Parsed{query}/g;
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
	$template =~ s/%gps_lat%/$Parsed{gps_lat}/g;
	$template =~ s/%gps_long%/$Parsed{gps_long}/g;
	$template =~ s/%home_lat%/$Config{home_lat}/g;
	$template =~ s/%home_long%/$Config{home_long}/g;
	$template =~ s/%landkreis%/$Config{landkreis}/g;
	$template =~ s/%zoom_map%/$Config{zoom_map}/g;
	$template =~ s/%zoom_sat%/$Config{zoom_sat}/g;
	$template =~ s/%play_file%/$Config{play_file}/g;

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
