package App::OracleInfo;
use Data::Dumper;
use Term::ANSIColor qw(:constants);
use DBI;

our $VERSION = '0.01';

use Moose;
with 'MooseX::Getopt';

has dbh => (
    traits     => ['NoGetopt'],
    is         => 'ro',
    lazy_build => 1,
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

sub print_headline {
    my ( $self, $headline ) = @_;
    print BOLD, YELLOW;
    printf( "\n%s\n%s\n", $headline, '=' x 50 );
    print RESET;
}

sub check_connect {
    my ($self) = @_;
    printf "\nConnect to %s@%s is : ", $self->username, $self->sid;
    if ( $self->dbh ) {
        print GREEN, BOLD "OK\n", RESET;
    }
    else {
        print RED, BOLD "FAIL\n", RESET;
        exit;
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

    $self->print_headline("DBMS Informations");

    foreach my $info_num ( keys %info ) {
        my $text = $info{$info_num};
        printf( "%-25s: %s\n", $text, $self->dbh->get_info($info_num) );
    }
}

sub print_version {
    my ($self) = @_;

    #
    #   Version
    #
    my $versions = $self->dbh->selectall_arrayref( q{SELECT * FROM product_component_version}, { Slice => {} } );
    my $version_format = "%-25s %10s %13s\n";
    print BOLD, YELLOW;
    printf( "\n" . $version_format . "%s\n", "Product", "Version", "Status", '=' x 50 );
    print RESET;
    foreach my $version (@$versions) {
        printf( $version_format, substr( $version->{PRODUCT}, 0, 24 ), $version->{VERSION}, $version->{STATUS} );
    }
}

sub print_priviliges {
    my ($self) = @_;

    return unless ( $self->all );

    #
    # USER_SYS_PRIVS
    #
    my $privs = $self->dbh->selectall_arrayref( q{SELECT * FROM USER_SYS_PRIVS}, { Slice => {} } );

    $self->print_headline("System Priviliges ( USER_SYS_PRIVS )");

    foreach my $priv (@$privs) {
        printf " * %s\n", $priv->{PRIVILEGE};

        # printf( $version_format, substr( $version->{PRODUCT}, 0, 24 ), $version->{VERSION}, $version->{STATUS} );
    }

    #
    # user_role_privs
    #
    my $roles = $self->dbh->selectall_arrayref( q{SELECT * FROM user_role_privs}, { Slice => {} } );

    $self->print_headline("Role Priviliges ( user_role_privs )");
    foreach my $role (@$roles) {

        # print Dumper $role;
        printf " * %s\n", $role->{GRANTED_ROLE};

        # printf( $version_format, substr( $version->{PRODUCT}, 0, 24 ), $version->{VERSION}, $version->{STATUS} );
    }
}

sub print_dbic_test_env_vars {
    my ($self) = @_;

    return unless ( $self->all );

    $self->print_headline("DBIC Test Env Vars");
    printf "export DBICTEST_ORA_DSN='dbi:Oracle:%s';\n", $self->sid;
    printf "export DBICTEST_ORA_USER='%s';\n",           $self->username;
    printf "export DBICTEST_ORA_PASS='%s';\n",           $self->password;
}

sub print_foter {
    my ($self) = @_;
    printf( "\nVersion: %s -- END...\n", $App::OracleInfo::VERSION );
}

sub run {
    my ($self) = @_;
    $self->check_attributes();
    $self->check_connect();

    $self->print_version();
    $self->print_dbms_info();
    $self->print_priviliges();
    $self->print_dbic_test_env_vars();

    $self->print_foter();
}
1;