#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 10;
use File::Temp qw(tempfile tempdir);
use gpca;

# Create a temporary directory for testing
my $tempdir = tempdir(CLEANUP => 1);

# Define test file paths
my $data_file = "$tempdir/test.gpca";
my $hdr_file = "$data_file.gpca";

# Initialize the gpca module
my $gpca = gpca::open($data_file);

# Test if the object is created successfully
isa_ok($gpca, 'gpca', 'gpca object created');

# Test put method
$gpca->put('test_key', 'test_data');
ok(-e $hdr_file, 'Header file created');
ok(-e $data_file, 'Data file created');

# Test get method
my $retrieved_data = $gpca->get('test_key');
is($retrieved_data, 'test_data', 'Data retrieved successfully');

# Test put and get with multiple entries
$gpca->put('key1', 'data1');
$gpca->put('key2', 'data2');
$gpca->put('key3', 'data3');

is($gpca->get('key1'), 'data1', 'Data for key1 retrieved successfully');
is($gpca->get('key2'), 'data2', 'Data for key2 retrieved successfully');
is($gpca->get('key3'), 'data3', 'Data for key3 retrieved successfully');

# Test index method
my $index_data = $gpca->index(0);
is($index_data, 'test_data', 'Data retrieved by index successfully');

# Test search method
my @search_results = $gpca->search('key');
is(scalar(@search_results), 3, 'Search found 3 matching entries');
is_deeply(\@search_results, [
    { key => 'key1', data => 'data1' },
    { key => 'key2', data => 'data2' },
    { key => 'key3', data => 'data3' }
], 'Search results are correct');

done_testing();
