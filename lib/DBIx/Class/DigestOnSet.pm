package DBIx::Class::DigestOnSet;

use strict;
use warnings;

use base qw/DBIx::Class/;
use Digest;

__PACKAGE__->mk_classdata( _digest_encoders => {} );

our $VERSION = '0.000001_01';

sub register_column {
  my $self = shift;
  my ($column, $info) = @_;
  $self->next::method(@_);

  return unless ( exists $info->{digest_enable} && $info->{digest_enable} );
  my $enc = exists $info->{digest_encoding}  ? $info->{digest_encoding}  : 'hex';
  my $alg = exists $info->{digest_algorithm} ? $info->{digest_algorithm} : 'SHA-1';

  $self->throw_exception("Valid values for digest_encoding are 'binary', 'hex' or 'base64'. You used '${enc}'")
    unless $enc =~ /^(?:hex|base64|binary)$/;
  my $object = eval{ Digest->new($alg) };
  $self->throw_exception("Digest->new('${alg}') failed: $@") if $@;

  my $encoding_method = $enc eq 'binary' ? 'digest' :
    ($enc eq 'hex' ? 'hexdigest' : 'b64digest');
  my $encoder = $self->_digest_encoders->{$column} = sub {
    $object->add(@_);
    return $object->$encoding_method;
  };

  if ( exists $info->{digest_check_method} && $info->{digest_check_method} ){
    no strict 'refs';
    my $check_method = $self->result_class.'::'.$info->{digest_check_method};
    #candidate for inlining...
    *$check_method = sub{ $_[0]->get_column($column) eq $encoder->($_[1]) };
  }
}

sub set_column {
  my $self = shift;
  if (defined(my $encoder = $self->_digest_encoders->{$_[0]})){
    return $self->next::method($_[0], $encoder->($_[1]));
  }
  $self->next::method(@_);
}

sub new {
  my($self, $attr, @rest) = @_;
  my $encoders = $self->_digest_encoders;
  for my $col (keys %$encoders ) {
    next unless exists $attr->{$col} && defined $attr->{$col};
    $attr->{$col} = $encoders->{$col}->( $attr->{$col} );
  }
  return $self->next::method($attr, @rest);
}

1;

__END__;

=head1 NAME

DBIx::Class::DigestOnSet - Automatically encode columns with Digest

=head1 SYNOPSIS

In your L<DBIx::Class> ResultSource class (the 'table' class):

  __PACKAGE__->load_components(qw/DigestOnSet ... Core/);

  #Simplest example. use hex encoding and SHA-1 algorithm
  __PACKAGE__->add_columns(
    'password' => {
      data_type     => 'CHAR',
      size          => 40,
      digest_enable => 1,
  }

  #SHA-1 / hex encoding / generate check method
  __PACKAGE__->add_columns(
    'password' => {
      data_type   => 'CHAR',
      size        => 40,
      digest_enable       => 1,
      digest_check_method => 'check_password',
  }

  #SHA-1 / binary encoding / generate check method
  __PACKAGE__->add_columns(
    'password' => {
      data_type   => 'BLOB',
      size        => 20,
      digest_enable       => 1,
      digest_encoding     => 'binary',
      digest_check_method => 'check_password',
  }

  #MD5 /  hex encoding / generate check method
  __PACKAGE__->add_columns(
    'password' => {
      data_type => 'CHAR',
      size      => 32,
      digest_enable       => 1,
      digest_algorithm    => 'MD5',
      digest_check_method => 'check_password',
  }

In your application code:

   #updating the value.
   $row->password('plaintext');
   my $digest = $row->password;

   #checking against an existing value with a check_method
   $row->check_password('old_password'); #true
   $row->password('new_password');
   $row->check_password('new_password'); #returns true
   $row->check_password('old_password'); #returns false


B<Note:> The component needs to be loaded I<before> Core.

=head1 DESCRIPTION

This L<DBIx::Class> component can be used to automatically encode a column's
contents whenever the value of that column is set.

This module is similar to the existing L<DBIx::Class::DigestColumns>, but there
is some key differences. The main difference is that C<DigestColumns> performs
the encode operation on C<insert> and C<update>, and C<DigestOnSet> performs
the operation when the value is set. Another difference is that DigestOnSet
supports having more than one encoded column per table using different
L<Digest> algorithms. Finally, C<DigestOnSet> adds only one item to the
namespace of the object utilizing it (C<_digest_encoders>).

There is, unfortunately, some defficiencies that come with C<DigestOnSet>.
C<DigestColumns> supports changing certain options at runtime, as well as
the option to not automatically encode values on set. The author of this module
found these options to be non essential and they were left out by design.

=head1 Options added to add_column

If any one of these options is present the column will be treated as a digest
column and all of the defaults will be applied to the rest of the options.

=head2 digest_enable => 1

Enable automatic encoding of column values. If this option is not set to true
any other options will become noops.

=head2 digest_check_method => $method_name

By using the digest_check_method attribute when you declare a column you
can create a check method for that column. The check method accepts a plain
text string, and returns a boolean that indicates whether the digest of the
provided value matches the current value.

=head2 digest_encoding

The encoding to use for the digest. Valid values are 'binary', 'hex', and
'base64'. Will default to 'hex' if not specified.

=head2 digest_algorithm

The digest algorithm to use for the digest. You may specify any valid L<Digest>
algorithm. Examples are L<MD5|Digest::MD5>, L<SHA-1|Digest::SHA>,
L<Whirlpool|Digest::Whirlpool> etc. Will default to 'SHA-1' if not specified.

See L<Digest> for supported digest algorithms.

=head1 EXTENDED METHODS

The following L<DBIx::Class::ResultSource> method is extended:

=over 4

=item B<register_column> - Handle the options described above.

=back

The following L<DBIx::Class::Row> methods are extended by this module:

=over 4

=item B<new> - Encode the columns on new() so that copy and create DWIM.

=item B<set_column> - Encode values whenever column is set.

=back

=head1 SEE ALSO

L<DBIx::Class::DigestColumns>, L<DBIx::Class>, L<Digest>

=head1 AUTHOR

Guillermo Roditi (groditi) <groditi@cpan.org>

Inspired by the original module written by Tom Kirkpatrick (tkp) <tkp@cpan.org>
featuring contributions from Guillermo Roditi (groditi) <groditi@cpan.org>
and Marc Mims <marc@questright.com>

=head1 LICENSE

You may distribute this code under the same terms as Perl itself.

=cut
