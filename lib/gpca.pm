#!/usr/bin/perl

################################################################################
#                                                                              #
#  Permanent Compressed Archive                                                #
#                                                                              #
#  (C) 2020 OnEhIppY, Domero, Groningen                                        #
#                                                                              #
################################################################################

package gpca;

use strict;
use warnings;
use Exporter;
use gfio;
use Compress::Zlib;

# Module version
our $VERSION = '1.0.1';

# Inherit from Exporter
our @ISA = qw(Exporter);
our @EXPORT = qw();
our @EXPORT_OK = qw();

=head1 NAME

gpca - Permanent Compressed Archive

=head1 SYNOPSIS

  use gpca;

=head1 DESCRIPTION

This module provides a way to store and retrieve compressed data in a permanent archive.

=head1 METHODS

=cut

################################################################################

=head2 open

  my $gpca = gpca::open($file);

Opens a new archive or an existing one, initializing internal structures.

=cut

sub open {
    my ($file) = @_;
    my $self = { dat => $file, hdr => "$file.gpca", mem => [] };
    bless $self;
    return $self->_init();
}

################################################################################

=head2 put

  $gpca->put($key, $data);

Stores a string in the archive with a given key.

=cut

sub put {
    my ($self, $key, $str) = @_;
    my $size = length($str);
    my ($pos, $len) = $self->_add($str);
    gfio::open($self->{hdr}, 'w')->lock()->appenddata("$key,$pos,$len,$size\n")->unlock()->close();
    push @{$self->{mem}}, [$key, $pos, $len, $size];
    $self->{mem} = [sort { $a->[0] cmp $b->[0] } @{$self->{mem}}];
}

################################################################################

=head2 get

  my $data = $gpca->get($key);

Retrieves a string from the archive using the given key.

=cut

sub get {
    my ($self, $key) = @_;
    my $at = $self->_find($key);
    return ref($at) eq 'ARRAY' ? $self->_get(@$at) : undef;
}

################################################################################

=head2 index

  my $data = $gpca->index($index);

Retrieves a string from the archive using the given index.

=cut

sub index {
    my ($self, $index) = @_;
    my $at = $self->_index($index);
    return ref($at) eq 'ARRAY' ? $self->_get(@$at) : undef;
}

################################################################################

=head2 search

  my @results = $gpca->search($search);

Searches for strings in the archive that match the given search term.

=cut

sub search {
    my ($self, $search) = @_;
    my $num = $#{$self->{mem}} + 1;
    my $bn = int(log($num) / log(2));
    my $bp = 2**$bn;
    my $fnd = 0;
    my $jump = $bp;
    my @res = ();

    # Binary Search
    do {
        $jump >>= 1;
        my ($key, $pos, $len, $size) = @{$self->{mem}[$bp - 1]};
        if (!defined $key || (($key cmp $search) > 0)) {
            $bp -= $jump;
        } elsif (($key cmp $search) == 0) {
            push @res, $bp - 1;
            $fnd = 1;
        } else {
            $bp += $jump;
        }
        $bn--;
    } until ($fnd || ($bn < 0));

    # Collect Results
    if ($fnd) {
        my $pp = $res[0];
        my $np = $res[0];
        do {
            $pp--;
            if (defined $self->{mem}[$pp] && $self->{mem}[$pp] =~ /^$search/gs) {
                unshift @res, $pp;
            }
        } until ($pp < 0 || $self->{mem}[$pp] !~ /^$search/gs);
        do {
            $np++;
            if (defined $self->{mem}[$np] && $self->{mem}[$np] =~ /^$search/gs) {
                push @res, $np;
            }
        } until (!defined $self->{mem}[$np] || $self->{mem}[$np] !~ /^$search/gs);
        for my $i (0..$#res) {
            my ($key, $pos, $len, $size) = @{$self->{mem}[$res[$i]]};
            $res[$i] = { key => $key, data => $self->_get($pos, $len, $size) };
        }
    }
    return @res;
}

################################################################################

=head2 _init

  $gpca->_init();

Initializes the archive, reading existing data if available.

=cut

sub _init {
    my ($self) = @_;
    $self->{mem} = [];
    if (-e $self->{hdr}) {
        for my $line (split(/[\r\n]+/, gfio::content($self->{hdr}))) {
            push @{$self->{mem}}, [split(/\,/, $line)];
        }
        $self->{mem} = [sort { $a->[0] cmp $b->[0] } @{$self->{mem}}];
    }
    return $self;
}

################################################################################

=head2 _add

  $gpca->_add($str);

Compresses and adds a string to the data file, returning its position and length.

=cut

sub _add {
    my ($self, $str) = @_;
    my $bin = compress($str, Z_BEST_COMPRESSION);
    my $len = length($bin);
    my $pos = (-e $self->{dat} ? -s $self->{dat} : 0);
    gfio::open($self->{dat}, 'w')->lock()->appenddata($bin)->unlock()->close();
    return ($pos, $len);
}

################################################################################

=head2 _get

  $gpca->_get($pos, $len, $size);

Retrieves and decompresses a string from the data file given its position, length, and size.

=cut

sub _get {
    my ($self, $pos, $len, $size) = @_;
    die " **** gpca Error **** File Not Found $self->{dat}\n\n" unless -e $self->{dat};
    my $fs = (-s $self->{dat});
    die " **** gpca Error **** File $self->{dat} Size ($fs) Smaller than " . ($pos + $len) . " : Pos $pos, Len $len\n\n" if $pos + $len > $fs;
    my $fh = gfio::open($self->{dat}, 'r');
    $fh->seek($pos);
    my $bin = $fh->read($len);
    $fh->close();
    my $str = uncompress($bin);
    die " **** gpca Error **** String Length Error - got `" . length($str) . "` but wanted `$size`\nBIN($len):[$bin]\nSTR!($size):[$str]\n\n" if length($str) ne $size;
    return $str;
}

################################################################################

=head2 _find

  $gpca->_find($key);

Finds the position, length, and size of the string associated with the given key.

=cut

sub _find {
    my ($self, $key) = @_;
    for my $line (@{$self->{mem}}) {
        return [$line->[1], $line->[2], $line->[3]] if $line->[0] eq $key;
    }
    return undef;
}

################################################################################

=head2 _index

  $gpca->_index($index);

Finds the position, length, and size of the string at the given index.

=cut

sub _index {
    my ($self, $index) = @_;
    my $line = $self->{mem}[$index];
    return defined $line ? [$line->[1], $line->[2], $line->[3]] : undef;
}

################################################################################

=head1 AUTHOR

OnEhIppY, Domero, Groningen

=head1 COPYRIGHT AND LICENSE

(C) 2020 OnEhIppY, Domero, Groningen. All rights reserved.

=cut

1;

################################################################################
# EOF (C) 2020 OnEhIppY, Domero, Groningen
################################################################################
