#!/usr/bin/perl -w

# This script will construct a "static map" from a tile server.
#
# Given a center point, zoom level and image dimensions it will retrieve
# all the tiles it needs to construct a single image of the area and will
# go ahead and construct that single static map image.
#
# Currently functions aren't abstracted, ideally the functional parts of
# this script would be abstracted away so it can easily be adapted to
# work as either a server side script (CGI), client side script (local
# program), and either retrive tiles from a HTTP tile server or via the
# local filesystem.

# Author: Andrew Harvey <andrew.harvey4@gmail.com>
# License: CC0 http://creativecommons.org/publicdomain/zero/1.0/
#
# To the extent possible under law, the person who associated CC0
# with this work has waived all copyright and related or neighboring
# rights to this work.
# http://creativecommons.org/publicdomain/zero/1.0/

use strict;

use Getopt::Long;
use POSIX; # for floor function
use Math::Trig qw(pi deg2rad asinh);

use GD;
use LWP;

use Geo::Proj4;

use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init($INFO); #DEBUG, INFO, WARN, ERROR, FATAL

my $lat;
my $lon;
my $zoomLevel;

my $mapWidth;
my $mapHeight;

my $tileBase;
my $outputFile;

my $opts = GetOptions(
  "lat=f" => \$lat,
  "lon=f" => \$lon,
  "zoom=i" => \$zoomLevel,
  "width=i" => \$mapWidth,
  "height=i" => \$mapHeight,
  "tileBase=s" => \$tileBase,
  "output=s" => \$outputFile );

INFO "map request: lat $lat, lon $lon, zoom $zoomLevel of size ${mapWidth}x${mapHeight}px";

# width and height of tiles in pixels
my $tileSizeInPixels = 256;

# number of vectical or horizontal tiles for the current zoom level
my $numTilesAlongSingleAxis = 2 ** $zoomLevel;

# number of pixels in vertical and horizontal direction for the whole world
my $worldSizeInPixels = $tileSizeInPixels * $numTilesAlongSingleAxis;

DEBUG "At zoom $zoomLevel there are ${numTilesAlongSingleAxis}x${numTilesAlongSingleAxis} tiles";

# project to the Popular Visualisation Mercator projection
my $toPopularVisMercator = Geo::Proj4->new ('+proj=merc +a=6378137 +b=6378137 +lat_ts=0.0 +lon_0=0.0 +x_0=0.0 +y_0=0 +k=1.0 +units=m +nadgrids=@null +no_defs +over');
my ($centerInMercX, $centerInMercY) = $toPopularVisMercator->forward($lat, $lon);

my ($projExtentX, $projExtentY) = $toPopularVisMercator->forward(-85, 180);

$projExtentY = -$projExtentX; # FIXME why is this really needed?

DEBUG "The requested map center in Popular Visualisation Mercator projection is easting $centerInMercX of $projExtentX, northing $centerInMercY of $projExtentY";

# transform range of x and y to 0-1 and shift origin to top left corner
my $centerRatioX = (1 + ($centerInMercX / $projExtentX)) / 2;
my $centerRatioY = (1 - ($centerInMercY / -$projExtentY)) / 2;

DEBUG "Center has a ratio of the entire world that is $centerRatioX, $centerRatioY";

# get absolute pixel of centre point
my $centerAbsoluteX = $centerRatioX * $worldSizeInPixels;
my $centerAbsoluteY = $centerRatioY * $worldSizeInPixels;

DEBUG "Center has a worldwide absolute pixel that is $centerAbsoluteX of $worldSizeInPixels, $centerAbsoluteY of $worldSizeInPixels";

my $topLeftPixelX = $centerAbsoluteX - ($mapWidth / 2);
my $topLeftPixelY = $centerAbsoluteY - ($mapHeight / 2);

my $bottomRightPixelX = $centerAbsoluteX + ($mapWidth / 2) - 1;
my $bottomRightPixelY = $centerAbsoluteY + ($mapHeight / 2) - 1;

my $tileRefAX = floor($topLeftPixelX / $tileSizeInPixels);
my $tileRefAY = floor($topLeftPixelY / $tileSizeInPixels);

my $tileRefBX = floor($bottomRightPixelX / $tileSizeInPixels);
my $tileRefBY = floor($bottomRightPixelY / $tileSizeInPixels);

DEBUG "Tile reference of A is $tileRefAX, $tileRefAY; B is $tileRefBX, $tileRefBY";

my $offsetX = $topLeftPixelX - ($tileRefAX * $tileSizeInPixels);
my $offsetY = $topLeftPixelY - ($tileRefAY * $tileSizeInPixels);

DEBUG "Will need to retrieve tiles ${tileRefAX}/${tileRefAY} through ${tileRefBX}/${tileRefBY}";

INFO "Will retrieve a total of " . 
  ($tileRefBX - $tileRefAX + 1) . 
  "x" . 
  ($tileRefBY - $tileRefAY + 1) . 
  " = " . 
  (($tileRefBX - $tileRefAX + 1) * ($tileRefBY - $tileRefAY + 1)) . 
  " tiles.";

DEBUG "We will then need too offset this tile set by -$offsetX, -$offsetY.";

# now construct the final static map from the tiles
# tell GD to always use 24bit color
GD::Image->trueColor(1);

my $img = GD::Image->new($mapWidth, $mapHeight);

# handle transparency properly
$img->alphaBlending(0);
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

      INFO "GET $tileURL";

      my $getResponse = $ua->get($tileURL);
      die "GET $tileURL failed with " . $getResponse->status_line . "\n" unless ($getResponse->is_success);
      my $tile = GD::Image->new($getResponse->content);
      die "Unexpected tile size of " . $tile->width . "x" . $tile->height . "\n" unless (($tile->width == $tileSizeInPixels) && ($tile->height == $tileSizeInPixels));

      my $dx = (($tx - $tileRefAX) * $tileSizeInPixels) - $offsetX;
      my $dy = (($ty - $tileRefAY) * $tileSizeInPixels) - $offsetY;

      DEBUG "Pasting tile $tx/$ty at ${dx}px, ${dy}px";

      $img->copy($tile, $dx, $dy, 0, 0, $tileSizeInPixels, $tileSizeInPixels);
    } # else tile is outside valid range so don't fill it in in the final image
  }
}


# write out the static map
binmode STDOUT;
open my $output_fh, ">$outputFile";
print $output_fh $img->png();
close $output_fh;

