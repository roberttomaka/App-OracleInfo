package App::OracleInfo;
use Data::Dumper;
use DBI;

our $VERSION = '0.01';

use App::OracleInfo::Out;
use Moose;
with 'MooseX::Getopt';

has dbh => (
    traits     => ['NoGetopt'],
    is         => 'ro',
    lazy_build => 1,
);

has out => (
    traits     => ['NoGetopt'],
    is         => 'ro',
    lazy       => 1,
    default    => sub { return App::OracleInfo::Out->new( ctx => shift ) },
);

has sid => (
    traits  => ['NoGetopt'],
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub { return shift->extra_argv->[0]; },
);

has username => (
    traits  => ['NoGetopt'],
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub { return shift->extra_argv->[1]; },
);

has password => (
    traits  => ['NoGetopt'],
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub { my $self = shift; return $self->extra_argv->[2] || $self->username },
);

has 'all' => (
    traits      => ['Getopt'],
    cmd_aliases => [qw/a/],

    is  => 'ro',
    isa => 'Bool',

    documentation => "Print all informations",
);

has 'batch' => (
    traits      => ['Getopt'],
    cmd_aliases => [qw/b/],

    is  => 'ro',
    isa => 'Bool',

    documentation => "Batchmode",
);

has 'env' => (
    traits      => ['Getopt'],
    cmd_aliases => [qw/e/],

    is  => 'ro',
    isa => 'ArrayRef',

    documentation => "Env...",
);

has predefined_module_envs => (
    traits      => ['NoGetopt'],
    is          => 'ro',
    isa         => 'HashRef',
    lazy_build => 1,
);

sub _build_predefined_module_envs {
    my $self = shift;
    return {
        'DBICTEST' => [
            DBICTEST_ORA_DSN  => sprintf( "dbi:Oracle:%s", $self->sid() ),
            DBICTEST_ORA_USER => $self->username,
            DBICTEST_ORA_PASS => $self->password,
        ],
        'DBICTEST_EXTRAUSER' => [
            DBICTEST_ORA_EXTRAUSER_DSN  => sprintf( "dbi:Oracle:%s", $self->sid() ),
            DBICTEST_ORA_EXTRAUSER_USER => $self->username,
            DBICTEST_ORA_EXTRAUSER_PASS => $self->password,
        ]
    }
}

sub _build_dbh {
    my $self = shift;
    return DBI->connect( 'dbi:Oracle:' . $self->sid, $self->username, $self->password );
}

sub check_attributes {
    my ($self) = @_;

    foreach my $attribute_name ( $self->meta->get_attribute_list() ) {
        my $attribute = $self->meta->get_attribute($attribute_name);
        next unless $attribute->does('MooseX::Getopt::Meta::Attribute::Trait');

        # Alle Getopt attribute...
    }
}

sub check_connect {
    my ($self) = @_;
    $self->out->printf("\nConnect to %s@%s is : ", $self->username, $self->sid);
    if ( $self->dbh ) {
        $self->out->color('bold green')->print("OK\n")->color('reset');
    }
    else {
        $self->out->color('bold red')->print("FAIL\n")->color('reset');
        exit 1;
    }
}

sub print_dbms_info {
    my ($self) = @_;
    my %info = (
        2  => 'Data Source Name',
        17 => 'DBMS Name',
        18 => 'DBMS Version',
        6  => 'Driver Name',
        7  => 'Driver Version',
        13 => 'Servername',
        47 => 'Username'
    );

    $self->out->headline("DBMS Informations");

    foreach my $info_num ( keys %info ) {
        my $text = $info{$info_num};
        $self->out->printf( "%-25s: %s\n", $text, $self->dbh->get_info($info_num) );
    }
}

sub print_version {
    my ($self) = @_;

    #
    #   Version
    #
    my $versions = $self->dbh->selectall_arrayref( q{SELECT * FROM product_component_version}, { Slice => {} } );
    my $version_format = "%-25s %10s %13s\n";
    $self->out->headline(sprintf($version_format,"Product", "Version", "Status"));
    foreach my $version (@$versions) {
        $self->out->printf( $version_format, substr( $version->{PRODUCT}, 0, 24 ), $version->{VERSION}, $version->{STATUS} );
    }
}

sub print_priviliges {
    my ($self) = @_;

    return unless ( $self->all );

    #
    # USER_SYS_PRIVS
    #
    my $privs = $self->dbh->selectall_arrayref( q{SELECT * FROM USER_SYS_PRIVS}, { Slice => {} } );

    $self->out->headline("System Priviliges ( USER_SYS_PRIVS )");

    foreach my $priv (@$privs) {
        $self->out->printf(" * %s\n", $priv->{PRIVILEGE});

        # printf( $version_format, substr( $version->{PRODUCT}, 0, 24 ), $version->{VERSION}, $version->{STATUS} );
    }

    #
    # user_role_privs
    #
    my $roles = $self->dbh->selectall_arrayref( q{SELECT * FROM user_role_privs}, { Slice => {} } );

    $self->out->headline("Role Priviliges ( user_role_privs )");
    foreach my $role (@$roles) {

        # print Dumper $role;
        $self->out->printf(" * %s\n", $role->{GRANTED_ROLE});

        # printf( $version_format, substr( $version->{PRODUCT}, 0, 24 ), $version->{VERSION}, $version->{STATUS} );
    }
}

sub print_foter {
    my ($self) = @_;
    $self->out->printf( "\nVersion: %s -- END...\n", $App::OracleInfo::VERSION );
}

sub build_env {
    my ( $self,$name ) = @_;
    return @{ $self->predefined_module_envs->{$name} || [] };
}

sub print_env {
    my ($self) = @_;
    foreach my $env ( @{ $self->env || [] } ) {
        $self->out->env_vars( $self->build_env($env) );
    }
}

sub run {
    my ($self) = @_;
    $self->check_attributes();
    $self->check_connect();

    if ( $self->env ){
        $self->print_env();
    }else{
        $self->print_version();
        $self->print_dbms_info();
        $self->print_priviliges();
        $self->print_env();
        $self->print_foter();
    }

}
1;
__END__
=head1 NAME

=head1 DESCRIPTION

=head1 SYNOPSIS

=head1 METHODS

=head1 AUTHOR

Robert Bohne <rbo@cpan.org>

=head1 LICENSE

You may distribute this code under the same terms as Perl itself.

=cut