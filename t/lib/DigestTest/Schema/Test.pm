package # hide from PAUSE
    DigestTest::Schema::Test;

use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/DigestOnSet Core/);
__PACKAGE__->table('test');
__PACKAGE__->add_columns
  (
   id => {
          data_type => 'int',
          is_nullable => 0,
          is_auto_increment => 1,
         },
   sha1_hex => {
                data_type => 'char',
                size      => 40,
                digest_enable => 1,
                digest_algorithm => 'SHA-1',
                digest_check_method => 'check_sha1_hex',
               },
   sha1_b64 => {
                data_type => 'char',
                size      => 27,
                digest_enable => 1,
                digest_encoding => 'base64',
                digest_check_method => 'check_sha1_b64',
               },
   sha256_hex => {
                  data_type => 'char',
                  size      => 64,
                  digest_enable    => 1,
                  digest_algorithm => 'SHA-256',
                 },
   sha256_b64 => {
                  data_type => 'char',
                  size      => 43,
                  accessor  => 'sha256b64',
                  digest_enable    => 1,
                  digest_algorithm => 'SHA-256',
                  digest_encoding  => 'base64',
                 },
   dummy_col => {
                 data_type => 'char',
                 size      => 43,
                 digest_enable    => 0,
                 digest_algorithm => 'SHA-256',
                 digest_encoding  => 'base64',
                 digest_check_method => 'check_dummy_col',
                },
  );

__PACKAGE__->set_primary_key('id');

1;
