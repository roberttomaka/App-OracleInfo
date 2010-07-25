package App::OracleInfo::Out;

use Term::ANSIColor ();
use Moose;
has ctx => (
    is      => 'ro',
    isa     => 'App::OracleInfo',
    handles => [qw/batch/],
);

sub headline {
    my ( $self, $headline ) = @_;

    return $self if $self->batch();

    $self->color('bold yellow')->printf( "\n%s\n%s\n", $headline, '=' x 50 )->color('reset');

    return $self;
}

sub print {
    my $self = shift;
    return $self if $self->batch();
    print @_;
    return $self;
}

sub printf {
    my $self = shift;

    return $self if $self->batch();

    my $format = shift;
    printf($format,@_);
    return $self;
}

sub color {
    my ( $self, $color ) = @_;
    print Term::ANSIColor::color($color);
    return $self;
}

sub env_vars {
    my $self = shift;
    my @envs = @_;
    my $out = '';
    # TODO: shell detection
    my $shelltype = 'bourne';
    while (@envs) {
        my ( $name, $value ) = ( shift(@envs), shift(@envs) );
        $value =~ s/(\\")/\\$1/g;
        $out .= $self->${ \"build_${shelltype}_env_declaration" }( $name, $value );
    }
    print $out;
}

sub build_bourne_env_declaration {
    my ( $self, $name, $value ) = @_;
    return qq{export ${name}="${value}"\n};
}

sub build_csh_env_declaration {
    my ( $self, $name, $value ) = @_;
    return qq{setenv ${name} "${value}"\n};
}

__PACKAGE__->meta->make_immutable;
1;
__END__

=head1 NAME

=head1 DESCRIPTION

=head1 SYNOPSIS

=head1 METHODS

=head1 AUTHOR

=head1 LICENSE

=cut
