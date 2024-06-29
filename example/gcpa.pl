#!/usr/bin/perl

################################################################################
#                                                                              #
#  Example usage of the gpca module                                            #
#                                                                              #
#  (C) 2024 OnEhIppY, Domero, Groningen                                        #
#                                                                              #
################################################################################

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use gpca;

# File paths for the example
my $data_file = 'example.data';

# Initialize the gpca module
my $gpca = gpca::open($data_file);

# Add some data to the archive
$gpca->put('key1', 'This is some test data for key1.');
$gpca->put('key2', 'Another piece of data for key2.');
$gpca->put('key3', 'More test data stored under key3.');

# Retrieve data using keys
print "Data for key1: ", $gpca->get('key1'), "\n";
print "Data for key2: ", $gpca->get('key2'), "\n";
print "Data for key3: ", $gpca->get('key3'), "\n";

# Retrieve data by index
print "Data at index 0: ", $gpca->index(0), "\n";
print "Data at index 1: ", $gpca->index(1), "\n";
print "Data at index 2: ", $gpca->index(2), "\n";

# Search for data using a partial key match
my @results = $gpca->search('key');
print "Search results for 'key':\n";
foreach my $result (@results) {
    print "Key: $result->{key}, Data: $result->{data}\n";
}

# Clean up the example files
unlink($data_file, "$data_file.gpca");

################################################################################
# EOF (C) 2024 OnEhIppY, Domero, Groningen
################################################################################
