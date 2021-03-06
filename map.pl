#!/usr/bin/perl -w

use strict;

use Getopt::Long;
use POSIX; # for floor function
use Math::Trig qw(pi deg2rad asinh);
use XML::Twig;

use GD;
use LWP;

my $lat;
my $lon;
my $zoomLevel;

my $mapWidth;
my $mapHeight;

my $tileBase;
my $outputFile;

my $hydranten_kml = XML::Twig->new();
$hydranten_kml->parsefile('html/hydranten/hydranten.kml');
my $hydranten_icon = 'html/hydranten/marker_h.png';

my $bahnkilometer_kml = XML::Twig->new();
$bahnkilometer_kml->parsefile('html/bahn/bahn.kml');

my $rettungspunkte_kml = XML::Twig->new();
$rettungspunkte_kml->parsefile('html/rettungspunkte/rp_nu_ul_gz.kml');
my $rettungspunkte_icon = 'html/rettungspunkte/marker_r.png';

my $flameFile = 'html/flame.png';

my $opts = GetOptions(
  "lat=f" => \$lat,
  "lon=f" => \$lon,
  "zoom=i" => \$zoomLevel,
  "width=i" => \$mapWidth,
  "height=i" => \$mapHeight,
  "tileBase=s" => \$tileBase,
  "output=s" => \$outputFile );

# width and height of tiles in pixels
my $tileSizeInPixels = 256;

# number of vectical or horizontal tiles for the current zoom level
my $numTilesAlongSingleAxis = 2 ** $zoomLevel;

# number of pixels in vertical and horizontal direction for the whole world
my $worldSizeInPixels = $tileSizeInPixels * $numTilesAlongSingleAxis;

my $markerCenterInMercX;
my $markerCenterInMercY;
my $markerCenterRatioX;
my $markerCenterRatioY;
my $markerCenterAbsoluteX;
my $markerCenterAbsoluteY;

# project to the Popular Visualisation Mercator projection
#my $toPopularVisMercator = Geo::Proj4->new ('+proj=merc +a=6378137 +b=6378137 +lat_ts=0.0 +lon_0=0.0 +x_0=0.0 +y_0=0 +k=1.0 +units=m +nadgrids=@null +no_defs +over');
my ($centerInMercX, $centerInMercY) = to_mercator($lat, $lon);
my ($projExtentX, $projExtentY) = to_mercator(-85, 180);

# transform range of x and y to 0-1 and shift origin to top left corner
my $centerRatioX = (1 + ($centerInMercX / $projExtentX)) / 2;
my $centerRatioY = (1 - ($centerInMercY / $projExtentX)) / 2;

# get absolute pixel of centre point
my $centerAbsoluteX = $centerRatioX * $worldSizeInPixels;
my $centerAbsoluteY = $centerRatioY * $worldSizeInPixels;

my $topLeftPixelX = $centerAbsoluteX - ($mapWidth / 2);
my $topLeftPixelY = $centerAbsoluteY - ($mapHeight / 2);

my $bottomRightPixelX = $centerAbsoluteX + ($mapWidth / 2) - 1;
my $bottomRightPixelY = $centerAbsoluteY + ($mapHeight / 2) - 1;

my $tileRefAX = floor($topLeftPixelX / $tileSizeInPixels);
my $tileRefAY = floor($topLeftPixelY / $tileSizeInPixels);

my $tileRefBX = floor($bottomRightPixelX / $tileSizeInPixels);
my $tileRefBY = floor($bottomRightPixelY / $tileSizeInPixels);

my $offsetX = $topLeftPixelX - ($tileRefAX * $tileSizeInPixels);
my $offsetY = $topLeftPixelY - ($tileRefAY * $tileSizeInPixels);

# now construct the final static map from the tiles
# tell GD to always use 24bit color
GD::Image->trueColor(1);

my $img = GD::Image->new($mapWidth, $mapHeight);

# handle transparency properly
$img->alphaBlending(1);
$img->saveAlpha(1);

my $ua = LWP::UserAgent->new();

# get all the tiles we need to cover the area of this static map
for (my $tx = $tileRefAX; $tx <= $tileRefBX; $tx++) {
  for (my $ty = $tileRefAY; $ty <= $tileRefBY; $ty++) {
    if (($tx >= 0) && ($ty >= 0) && ($tx < $numTilesAlongSingleAxis) && ($ty < $numTilesAlongSingleAxis)) {
      my $tileURL = $tileBase;
      $tileURL =~ s/{x}/$tx/g;
      $tileURL =~ s/{y}/$ty/g;
      $tileURL =~ s/{z}/$zoomLevel/g;

      my $getResponse = $ua->get($tileURL);
      #die "GET $tileURL failed with " . $getResponse->status_line . "\n" unless ($getResponse->is_success);
      my $tile = GD::Image->new($getResponse->content);
      #die "Unexpected tile size of " . $tile->width . "x" . $tile->height . "\n" unless (($tile->width == $tileSizeInPixels) && ($tile->height == $tileSizeInPixels));

      my $dx = (($tx - $tileRefAX) * $tileSizeInPixels) - $offsetX;
      my $dy = (($ty - $tileRefAY) * $tileSizeInPixels) - $offsetY;

      $img->copy($tile, $dx, $dy, 0, 0, $tileSizeInPixels, $tileSizeInPixels);
    } # else tile is outside valid range so don't fill it in in the final image
  }
}

my $marker = GD::Image->new($hydranten_icon);

foreach my $placemark($hydranten_kml->get_xpath('//Document/Placemark/Point/coordinates')) {
    my ($markerLon, $markerLat) = split(',',$placemark->text);
    ($markerCenterInMercX, $markerCenterInMercY) = to_mercator($markerLat, $markerLon);

    # transform range of x and y to 0-1 and shift origin to top left corner
    $markerCenterRatioX = (1 + ($markerCenterInMercX / $projExtentX)) / 2;
    $markerCenterRatioY = (1 - ($markerCenterInMercY / $projExtentX)) / 2;

    # get absolute pixel of centre point
    $markerCenterAbsoluteX = $markerCenterRatioX * $worldSizeInPixels - $topLeftPixelX - ($marker->width / 2);
    $markerCenterAbsoluteY = $markerCenterRatioY * $worldSizeInPixels - $topLeftPixelY - ($marker->height);
    $img->copy($marker, $markerCenterAbsoluteX, $markerCenterAbsoluteY, 0, 0, $marker->width, $marker->height);
}

$marker = GD::Image->new(38,50);
$marker->copy(GD::Image->new($rettungspunkte_icon),0,0,0,0,38,38);
my $black = $marker->colorAllocate(0,0,0);
my $white = $marker->colorAllocate(255,255,255);

foreach my $placemark($rettungspunkte_kml->get_xpath('//Document/Placemark')) {
    my $coords = $placemark->get_xpath('./Point/coordinates', 0)->text;
    my $name = $placemark->get_xpath('./ExtendedData/SchemaData/SimpleData[@name="RP_Nr"]', 0)->text;
    #print($coords . " " . $name . "\n");
    my ($markerLon, $markerLat) = split(',',$coords);
    ($markerCenterInMercX, $markerCenterInMercY) = to_mercator($markerLat, $markerLon);

    # transform range of x and y to 0-1 and shift origin to top left corner
    $markerCenterRatioX = (1 + ($markerCenterInMercX / $projExtentX)) / 2;
    $markerCenterRatioY = (1 - ($markerCenterInMercY / $projExtentX)) / 2;

    # get absolute pixel of centre point
    $markerCenterAbsoluteX = $markerCenterRatioX * $worldSizeInPixels - $topLeftPixelX - ($marker->width / 2);
    $markerCenterAbsoluteY = $markerCenterRatioY * $worldSizeInPixels - $topLeftPixelY - ($marker->width / 2); #center on the dot on icon, that is why we use width here;

    $marker->filledRectangle(0,38,37,49,$white);
    $marker->string(gdTinyFont,2,40,$name,$black);

    $img->copy($marker, $markerCenterAbsoluteX, $markerCenterAbsoluteY, 0, 0, $marker->width, $marker->height);
}

$marker = GD::Image->new(38,38);

foreach my $placemark($bahnkilometer_kml->get_xpath('//Document/Placemark')) {
    my $coords = $placemark->get_xpath('./Point/coordinates', 0)->text;
    my $name = $placemark->get_xpath('./ExtendedData/SchemaData/SimpleData[@name="km_l"]', 0)->text;
#    print($coords . " " . $name . "\n");
    my ($markerLon, $markerLat) = split(',',$coords);
    ($markerCenterInMercX, $markerCenterInMercY) = to_mercator($markerLat, $markerLon);

    # transform range of x and y to 0-1 and shift origin to top left corner
    $markerCenterRatioX = (1 + ($markerCenterInMercX / $projExtentX)) / 2;
    $markerCenterRatioY = (1 - ($markerCenterInMercY / $projExtentX)) / 2;

    # get absolute pixel of centre point
    $markerCenterAbsoluteX = $markerCenterRatioX * $worldSizeInPixels - $topLeftPixelX - ($marker->width / 2);
    $markerCenterAbsoluteY = $markerCenterRatioY * $worldSizeInPixels - $topLeftPixelY - ($marker->height / 2);

    $marker->filledRectangle(0,0,37,37,$white);
    $marker->rectangle(0,0,37,37,$black);
    $marker->string(gdMediumBoldFont,12,2,$name,$black);
    $marker->string(gdMediumBoldFont,15,20,"0",$black);

    $img->copy($marker, $markerCenterAbsoluteX, $markerCenterAbsoluteY, 0, 0, $marker->width, $marker->height);
}


my $flame = GD::Image->new($flameFile);
$img->copy($flame, $mapWidth / 2 - ($flame->width / 2), $mapHeight / 2 - $flame->height, 0, 0, $flame->width, $flame->height);

# write out the static map
binmode STDOUT;
open my $output_fh, ">$outputFile";
print $output_fh $img->png();
close $output_fh;

sub to_mercator {
    my $r = 6378137.000;
    my $x = $_[0];
    my $y = $_[1];

    if ($x > 89.5) { $x = 89.5; }
    if ($x < -89.5) { $x = -89.5; }

    my $phi = (pi/180.0) * $x;
    my $ts = tan(((pi / 2) - $phi) / 2.0);
    return ($r * (pi / 180.0) * $y, -$r * log($ts));
}
