#!/usr/bin/perl -w

use strict;

use Getopt::Long;
use POSIX; # for floor function
use Math::Trig qw(pi deg2rad asinh);
use XML::Simple;

use GD;
use LWP;

use Geo::Proj4;

my $lat;
my $lon;
my $zoomLevel;

my $mapWidth;
my $mapHeight;

my $tileBase;
my $outputFile;

my $markersKML = XMLin('html/hydranten.kml');
my $markerFile = 'html/marker_h.png';
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
my $markerProjExtentX;
my $markerProjExtentY;
my $markerCenterRatioX;
my $markerCenterRatioY;
my $markerCenterAbsoluteX;
my $markerCenterAbsoluteY;

# project to the Popular Visualisation Mercator projection
my $toPopularVisMercator = Geo::Proj4->new ('+proj=merc +a=6378137 +b=6378137 +lat_ts=0.0 +lon_0=0.0 +x_0=0.0 +y_0=0 +k=1.0 +units=m +nadgrids=@null +no_defs +over');
my ($centerInMercX, $centerInMercY) = $toPopularVisMercator->forward($lat, $lon);

my ($projExtentX, $projExtentY) = $toPopularVisMercator->forward(-85, 180);

$projExtentY = -$projExtentX; # FIXME why is this really needed?

# transform range of x and y to 0-1 and shift origin to top left corner
my $centerRatioX = (1 + ($centerInMercX / $projExtentX)) / 2;
my $centerRatioY = (1 - ($centerInMercY / -$projExtentY)) / 2;

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

my $marker = GD::Image->new($markerFile);
#$img = GD::Image->new('map.png');

while (my ($key, $folder) = each %{$markersKML->{Document}{Placemark}})  {
    my ($markerLon, $markerLat) = split(',',$folder->{Point}->{coordinates});
    ($markerCenterInMercX, $markerCenterInMercY) = $toPopularVisMercator->forward($markerLat, $markerLon);

    # TODO we can reuse those values?!
    ($markerProjExtentX, $markerProjExtentY) = $toPopularVisMercator->forward(-85, 180);

    $markerProjExtentY = -$markerProjExtentX; # FIXME why is this really needed?

    # transform range of x and y to 0-1 and shift origin to top left corner
    $markerCenterRatioX = (1 + ($markerCenterInMercX / $markerProjExtentX)) / 2;
    $markerCenterRatioY = (1 - ($markerCenterInMercY / -$markerProjExtentY)) / 2;

    # get absolute pixel of centre point
    $markerCenterAbsoluteX = $markerCenterRatioX * $worldSizeInPixels - $topLeftPixelX - ($marker->width / 2);
    $markerCenterAbsoluteY = $markerCenterRatioY * $worldSizeInPixels - $topLeftPixelY - ($marker->height);
    $img->copy($marker, $markerCenterAbsoluteX, $markerCenterAbsoluteY, 0, 0, $marker->width, $marker->height);
}

my $flame = GD::Image->new($flameFile);
$img->copy($flame, $mapWidth / 2 - ($flame->width / 2), $mapHeight / 2 - $flame->height, 0, 0, $flame->width, $flame->height);

# write out the static map
binmode STDOUT;
open my $output_fh, ">$outputFile";
print $output_fh $img->png();
close $output_fh;

