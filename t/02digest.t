#! /usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 24;
use Digest;

use File::Spec;
use FindBin '$Bin';
use lib File::Spec->catdir($Bin, 'lib');

use_ok("DigestTest");

my $schema = DigestTest->init_schema;
my $rs     = $schema->resultset('Test');

my $sha256_maker = Digest->new('SHA-256');

my $checks = {};
for my $algorithm( qw/SHA-1 SHA-256/){
  my $maker = Digest->new($algorithm);
  my $encodings = $checks->{$algorithm} = {};
  for my $encoding (qw/base64 hex/){
    my $values = $encodings->{$encoding} = {};
    my $encoding_method = $encoding eq 'binary' ? 'digest' :
      ($encoding eq 'hex' ? 'hexdigest' : 'b64digest');
    for my $value (qw/test1 test2/){
      $maker->add($value);
      $values->{$value} = $maker->$encoding_method;
    }
  }
}

my $row = $rs->create(
                      {
                       dummy_col  => 'test1',
                       sha1_hex   => 'test1',
                       sha1_b64   => 'test1',
                       sha256_hex => 'test1',
                       sha256_b64 => 'test1',
                      }
                     );

is($row->dummy_col,  'test1',                            'dummy on create');
is($row->sha1_hex,   $checks->{'SHA-1'}{hex}{test1},     'hex sha1 on create');
is($row->sha1_b64,   $checks->{'SHA-1'}{base64}{test1},  'b64 sha1 on create');
is($row->sha256_hex, $checks->{'SHA-256'}{hex}{test1},   'hex sha256 on create');
is($row->sha256b64,  $checks->{'SHA-256'}{base64}{test1},'b64 sha256 on create');

can_ok($row, qw/check_sha1_hex check_sha1_b64/);
ok(!$row->can('check_dummy_col'));
ok($row->check_sha1_hex('test1'),'Checking hex digest_check_method');
ok($row->check_sha1_b64('test1'),'Checking b64 digest_check_method');

$row->sha1_hex('test2');
is($row->sha1_hex, $checks->{'SHA-1'}{hex}{test2}, 'Checking accessor');

$row->update({sha1_b64 => 'test2',  dummy_col => 'test2'});
is($row->sha1_b64, $checks->{'SHA-1'}{base64}{test2}, 'Checking update');
is($row->dummy_col,  'test2', 'dummy on update');

$row->set_column(sha256_hex => 'test2');
is($row->sha256_hex, $checks->{'SHA-256'}{hex}{test2}, 'Checking set_column');

$row->sha256b64('test2');
is($row->sha256b64, $checks->{'SHA-256'}{base64}{test2}, 'custom accessor');

$row->update;

my $copy = $row->copy({sha256_b64 => 'test2'});
is($copy->sha1_hex,   $checks->{'SHA-1'}{hex}{test2},     'hex sha1 on copy');
is($copy->sha1_b64,   $checks->{'SHA-1'}{base64}{test2},  'b64 sha1 on copy');
is($copy->sha256_hex, $checks->{'SHA-256'}{hex}{test2},   'hex sha256 on copy');
is($copy->sha256b64,  $checks->{'SHA-256'}{base64}{test2},'b64 sha256 on copy');

my $new = $rs->new(
                   {
                    sha1_hex   => 'test1',
                    sha1_b64   => 'test1',
                    sha256_hex => 'test1',
                    sha256_b64 => 'test1',
                    dummy_col  => 'test1',
                   }
                  );

is($new->dummy_col,  'test1',                             'dummy on new');
is($new->sha1_hex,   $checks->{'SHA-1'}{hex}{test1},      'hex sha1 on new');
is($new->sha1_b64,   $checks->{'SHA-1'}{base64}{test1},   'b64 sha1 on new');
is($new->sha256_hex, $checks->{'SHA-256'}{hex}{test1},    'hex sha256 on new');
is($new->sha256b64,  $checks->{'SHA-256'}{base64}{test1}, 'b64 sha256 on new');

DigestTest->clear;

#TODO
# -- dies_ok tests when using invalid cyphers and encodings

1;

