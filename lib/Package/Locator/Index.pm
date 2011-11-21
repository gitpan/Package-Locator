package Package::Locator::Index;

# ABSTRACT: The package index of a repository

use Moose;
use MooseX::Types::URI qw(Uri);
use MooseX::Types::Path::Class;

use Carp;
use Path::Class;
use File::Temp;
use Parse::CPAN::Packages::Fast;
use LWP::UserAgent;
use URI::Escape;
use URI;

use namespace::autoclean;

#------------------------------------------------------------------------

our $VERSION = '0.001'; # VERSION

#------------------------------------------------------------------------


has repository_url => (
    is        => 'ro',
    isa       => Uri,
    required  => 1,
    coerce    => 1,
);



has user_agent => (
   is          => 'ro',
   isa         => 'LWP::UserAgent',
   default     => sub { LWP::UserAgent->new() },
);


has cache_dir => (
   is         => 'ro',
   isa        => 'Path::Class::Dir',
   default    => sub { Path::Class::Dir->new( File::Temp::tempdir(CLEANUP => 1) ) },
   coerce     => 1,
);



has force => (
   is         => 'ro',
   isa        => 'Bool',
   default    => 0,
);


has _index_file => (
    is         => 'ro',
    isa        => 'Path::Class::File',
    init_arg   => undef,
    lazy_build => 1,
);


has _index => (
    is         => 'ro',
    isa        => 'Parse::CPAN::Packages::Fast',
    init_arg   => undef,
    lazy_build => 1,
);

#------------------------------------------------------------------------------

sub BUILDARGS {
    my ($class, %args) = @_;

    if (my $cache_dir = $args{cache_dir}) {
        # Manual coercion here...
        $cache_dir = dir($cache_dir);
        $class->__mkpath($cache_dir);
        $args{cache_dir} = $cache_dir;
    }

    return \%args;
}

#------------------------------------------------------------------------------


sub _build__index_file {
    my ($self) = @_;

    my $repos_url = $self->repository_url->canonical();;

    my $cache_dir = $self->cache_dir->subdir( URI::Escape::uri_escape($repos_url) );
    $self->__mkpath($cache_dir);

    my $destination = $cache_dir->file('02packages.details.txt.gz');
    $destination->remove() if -e $destination and $self->force();

    my $source = URI->new( "$repos_url/modules/02packages.details.txt.gz" );

    my $response = $self->user_agent->mirror($source, $destination);
    $self->__handle_ua_response($response, $source, $destination);

    return $destination;
}

#------------------------------------------------------------------------------

sub _build__index {
    my ($self) = @_;

    my $index_file = $self->_index_file();

    return Parse::CPAN::Packages::Fast->new($index_file->stringify());
}

#------------------------------------------------------------------------------

sub __handle_ua_response {
    my ($self, $response, $source, $destination) = @_;

    return 1 if $response->is_success();   # Ok
    return 1 if $response->code() == 304;  # Not modified
    croak sprintf 'Request to %s failed: %s', $source, $response->status_line();
}

#------------------------------------------------------------------------------

sub __mkpath {
    my ($self, $dir) = @_;

    return if -e $dir;
    $dir = dir($dir) unless eval { $dir->isa('Path::Class::Dir') };
    return $dir->mkpath() or croak "Failed to make directory $dir: $!";
}

#------------------------------------------------------------------------


sub lookup_package {
    my ($self, $package_name) = @_;

    return $self->_index->package($package_name);
}

#------------------------------------------------------------------------


sub lookup_dist {
    my ($self, $dist_path) = @_;

    my @dists = $self->_index->distributions();

    my @found = grep { $_->prefix() eq $dist_path } @dists;

    croak "Found multiple versions of $dist_path" if @found > 1;

    return pop @found;
}

#------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#------------------------------------------------------------------------
1;



=pod

=for :stopwords Jeffrey Ryan Thalhammer Imaginative Software Systems

=head1 NAME

Package::Locator::Index - The package index of a repository

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  use Package::Locator::Index;

  my $index = Package::Locator::Index->new( repository_url => 'http://somewhere' );
  my $dist  = $index->lookup_dist( 'F/FO/FOO/Bar-1.0.tar.gz' );
  my $pkg   = $index->lookup_package( 'Foo::Bar' );

=head1 DESCRIPTION

B<This is a private module and there are no user-serviceable parts
here.  The API documentation is for my own reference only.>

L<Package::Locator::Index> represents the contents of the index file
for a CPAN-like repository.  You can then query the index to find
which distribution a package is in, or if the index contains a
particular distribution at all.

It is assumed that the index file conforms to the typical
F<02package.details.txt.gz> file format, and that the index file
contains only the latest version of each package.

=head1 CONSTRUCTOR

=head2 new( %attributes )

All the attributes listed below can be passed to the constructor, and
retrieved via accessor methods with the same name.  All attributes are
read-only, and cannot be changed once the object is constructed.

=head1 ATTRIBUTES

=head2 repository_url => 'http://somewhere'

The base URL of the repository you want to get the index from.  This
is usually a CPAN mirror, but can be any site or directory that is
organized in a CPAN-like structure.  This attribute is required.

=head2 user_agent => $user_agent_obj

The L<LWP::UserAgent> object that will fetch the index file.  If you
do not provide a user agent, then a default one will be constructed
for you.

=head2 cache_dir => '/some/directory/path'

The path (as a string or L<Path::Class::Dir> object) to a directory
where the index file will be cached.  If the directory does not exist,
it will be created for you.  If you do not specify a cache directory,
then a temporary directory will be used.  The temporary directory will
be deleted when your application terminates.

=head2 force => $boolean

Causes any cached index files to be removed, thus forcing a new one to
be downloaded when the object is constructed.  This only has effect if
you specified the C<cache_dir> attribute.  The default is false.

=head1 METHODS

=head2 lookup_package( $package_name )

Returns an object representing the distribution that contains the
specified C<$package_name>.  Returns undef if the index does not know
of any such C<$package_name>

=head2 lookup_dist( $dist_path )

Returns an object representing the distribution located at the
specified C<$dist_path>.  Returns undef if the index does not know of
any such C<$dist_path>.

=head1 AUTHOR

Jeffrey Ryan Thalhammer <jeff@imaginative-software.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Imaginative Software Systems.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

