# $Id: Echo.pm,v 1.2 2005/01/26 14:39:33 chris Exp $
#
# POE::Component::Server::Echo, by Chris 'BinGOs' Williams <chris@bingosnet.co.uk>
#
# This module may be used, modified, and distributed under the same
# terms as Perl itself. Please see the license that came with your Perl
# distribution for details.
#

package POE::Component::Server::Echo;

use strict;
use POE qw( Wheel::SocketFactory Wheel::ReadWrite Driver::SysRW
            Filter::Line );
use Carp;
use Socket;
use IO::Socket::INET;
use vars qw($VERSION);

use constant DATAGRAM_MAXLEN => 1024;
use constant DEFAULT_PORT => 7;

$VERSION = '1.0';

sub spawn {
  my ($package) = shift;
  croak "$package requires an even number of parameters" if @_ & 1;

  my %parms = @_;

  $parms{'Alias'} = 'Echo-Server' unless ( defined ( $parms{'Alias'} ) and $parms{'Alias'} );
  $parms{'tcp'} = 1 unless ( defined ( $parms{'tcp'} ) and $parms{'tcp'} == 0 );
  $parms{'udp'} = 1 unless ( defined ( $parms{'udp'} ) and $parms{'udp'} == 0 );

  my ($self) = bless( { }, $package );

  $self->{CONFIG} = \%parms;

  POE::Session->create(
	object_states => [ 
		$self => { _start => 'server_start',
			   _stop  => 'server_stop',
			   shutdown => 'server_close' },
		$self => [ qw(accept_new_client accept_failed client_input client_error get_datagram) ],
			  ],
	( ref $parms{'options'} eq 'HASH' ? ( options => $parms{'options'} ) : () ),
  );
  
  return $self;
}

sub server_start {
  my ($kernel,$self) = @_[KERNEL,OBJECT];

  $kernel->alias_set( $self->{CONFIG}->{Alias} );
  
  if ( $self->{CONFIG}->{tcp} ) {
    $self->{Listener} = POE::Wheel::SocketFactory->new(
      ( defined ( $self->{CONFIG}->{BindAddress} ) ? ( BindAddress => $self->{CONFIG}->{BindAddress} ) : () ),
      ( defined ( $self->{CONFIG}->{BindPort} ) ? ( BindPort => $self->{CONFIG}->{BindPort} ) : ( BindPort => DEFAULT_PORT ) ),
      SuccessEvent   => 'accept_new_client',
      FailureEvent   => 'accept_failed',
      SocketDomain   => AF_INET,             # Sets the socket() domain
      SocketType     => SOCK_STREAM,         # Sets the socket() type
      SocketProtocol => 'tcp',               # Sets the socket() protocol
      Reuse          => 'on',                # Lets the port be reused
    );
  }
  if ( $self->{CONFIG}->{udp} ) {
    $self->{udp_socket} = IO::Socket::INET->new(
        Proto     => 'udp',
        ( defined ( $self->{CONFIG}->{BindPort} ) and $self->{CONFIG}->{BindPort} ? ( ListenPort => $self->{CONFIG}->{BindPort} ) : ( $self->{CONFIG}->{BindPort} != 0 ? ( ListenPort => DEFAULT_PORT ) : () ) ),
    ) or die "Can't bind : $@\n";

    $kernel->select_read( $self->{udp_socket}, "get_datagram" );
  }
}

sub server_stop {
  my ($kernel,$self) = @_[KERNEL,OBJECT];
}

sub server_close {
  my ($kernel,$self) = @_[KERNEL,OBJECT];

  delete ( $self->{Listener} );
  delete ( $self->{Clients} );
  $kernel->select( $self->{udp_socket} );
  delete ( $self->{udp_socket} );
  $kernel->alias_remove( $self->{CONFIG}->{Alias} );
}

sub accept_new_client {
  my ($kernel,$self,$socket,$peeraddr,$peerport,$wheel_id) = @_[KERNEL,OBJECT,ARG0 .. ARG3];
  $peeraddr = inet_ntoa($peeraddr);

  my ($wheel) = POE::Wheel::ReadWrite->new (
        Handle => $socket,
        Filter => POE::Filter::Line->new(),
        InputEvent => 'client_input',
        ErrorEvent => 'client_error',
  );

  $self->{Clients}->{ $wheel->ID() }->{Wheel} = $wheel;
  $self->{Clients}->{ $wheel->ID() }->{peeraddr} = $peeraddr;
  $self->{Clients}->{ $wheel->ID() }->{peerport} = $peerport;
}

sub accept_failed {
  my ($kernel,$self) = @_[KERNEL,OBJECT];

  $kernel->yield( 'shutdown' );
}

sub client_input {
  my ($kernel,$self,$input,$wheel_id) = @_[KERNEL,OBJECT,ARG0,ARG1];

  if ( defined ( $self->{Clients}->{ $wheel_id } ) and defined ( $self->{Clients}->{ $wheel_id }->{Wheel} ) ) {
	$self->{Clients}->{ $wheel_id }->{Wheel}->put($input);
  }
}

sub client_error {
  my ($kernel,$self,$wheel_id) = @_[KERNEL,OBJECT,ARG3];

  delete ( $self->{Clients}->{ $wheel_id } );
}

sub get_datagram {
  my ( $kernel, $socket ) = @_[ KERNEL, ARG0 ];

  my $remote_address = recv( $socket, my $message = "", DATAGRAM_MAXLEN, 0 );
    return unless defined $remote_address;

  send( $socket, $message, 0, $remote_address ) == length($message)
      or warn "Trouble sending response: $!";
}

1;
__END__

=head1 NAME

POE::Component::Server::Echo - a POE component implementing a RFC 862 Echo server.

=head1 SYNOPSIS

use POE::Component::Server::Echo;

my ($self) = POE::Component::Server::Echo->spawn( 
	Alias => 'Echo-Server',
	BindAddress => '127.0.0.1',
	BindPort => 7777,
	options => { trace => 1 },
);

=head1 DESCRIPTION

POE::Component::Server::Echo implements a RFC 862 L<http://www.faqs.org/rfcs/rfc862.html> TCP/UDP echo server, using 
L<POE|POE>. The component encapsulates a class which may be used to further RFC protocols.

=head1 METHODS

=over

=item spawn

Takes a number of optional values: "Alias", the kernel alias that this component is to be blessed with; "BindAddress", the address on the local host to bind to, defaults to L<POE::Wheel::SocketFactory|POE::Wheel::SocketFactory> default; "BindPort", the local port that we wish to listen on for requests, defaults to 7 as per RFC, this will require "root" privs on UN*X; "options", should be a hashref, containing the options for the component's session, see L<POE::Session|POE::Session> for more details on what this should contain.

=back

=head1 BUGS

Report any bugs through L<http://rt.cpan.org/>.

=head1 AUTHOR

Chris 'BinGOs' Williams, <chris@bingosnet.co.uk>

=head1 SEE ALSO

L<POE|POE>
L<POE::Session|POE::Session>
L<POE::Wheel::SocketFactory|POE::Wheel::SocketFactory>
L<http://www.faqs.org/rfcs/rfc862.html>

=cut
