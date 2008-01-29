#! /usr/bin/perl -w

# Load the Module::Install bundled in ./inc/
use inc::Module::Install;

# Define metadata
name 'DBIx-Class-DigestOnSet';
abstract "Automatically encode values when they are set";
all_from 'lib/DBIx/Class/DigestOnSet.pm';

# Specific dependencies
requires 'Digest'      => '1.11';
requires 'DBIx::Class' => '0.06002';

#build dependencies
build_requires 'Test::More';
build_requires 'DBD::SQLite';
build_requires 'Digest::SHA';
build_requires 'File::Spec';

#recommended modules
recommends 'Digest::MD5';

auto_install;
WriteAll;
