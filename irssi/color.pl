use strict;
use Irssi 20020101.0250 ();
use vars qw($VERSION %IRSSI);
$VERSION = "1";
%IRSSI = (
  authors     => "Joseph Roth",
  contact     => "josephroth\@google.com",
  name        => "Color Nicks",
  description => "Assign colors to nicks",
  url         => "http://irssi.org/",
  changed     => "2017-04-05T20:00+0000"
);

my %saved_colors;
my %session_colors;
my @colors = ('%g', '%b', '%M', '%m', '%r', '%R', '%W', '%w');

sub load_colors {
  open my $color_fh, "<", "$ENV{HOME}/.irssi/saved_colors";
  while (<$color_fh>) {
    chomp;
    my($nick, $color) = split ":";
    $saved_colors{$nick} = $color;
  }
}

sub save_colors {
  open COLORS, ">", "$ENV{HOME}/.irssi/saved_colors";
  foreach my $nick (keys %saved_colors) {
    print COLORS "$nick:$saved_colors{$nick}\n";
  }
  close COLORS;
}

# If someone we've colored (either through the saved colors, or the hash
# function) changes their nick, we'd like to keep the same color associated
# with them (but only in the session_colors, ie a temporary mapping).
sub sig_nick {
  my ($server, $newnick, $nick, $address) = @_;
  my $color;

  $newnick = substr ($newnick, 1) if ($newnick =~ /^:/);

  if ($color = $saved_colors{$nick}) {
    $session_colors{$newnick} = $color;
  } elsif ($color = $session_colors{$nick}) {
    $session_colors{$newnick} = $color;
  }
}

# This gave reasonable distribution values when run across
# /usr/share/dict/words
sub simple_hash {
  my ($string) = @_;
  chomp $string;
  my @chars = split //, $string;
  my $counter;

  foreach my $char (@chars) {
    $counter += ord $char;
  }

  $counter = $colors[$counter % $#colors];

  return $counter;
}

sub sig_public {
  my ($server, $msg, $nick, $address, $target) = @_;
  my $chanrec = $server->channel_find($target);
  return if not $chanrec;
  my $nickrec = $chanrec->nick_find($nick);
  return if not $nickrec;
  my $nickmode = $nickrec->{op} ? "@" : $nickrec->{voice} ? "+" : "";

  if ($nick eq 'comlink') {
    my @parts = split />/, $msg;
    $nick = substr $parts[0], 1;
  }

  my $color = $saved_colors{$nick};
  if (!$color) {
    $color = $session_colors{$nick};
  }
  if (!$color) {
    $color = simple_hash $nick;
    $session_colors{$nick} = $color;
  }

  $server->command('/^format pubmsg {pubmsgnick $2 {pubnick ' . $color . '$[-10]0}}$1');
}

sub sig_private {
  my ($server, $msg, $nick, $address) = @_;

  my $color = $saved_colors{$nick};
  if (!$color) {
    $color = $session_colors{$nick};
  }
  if (!$color) {
    $color = simple_hash $nick;
    $session_colors{$nick} = $color;
  }

  $server->command('/^format msg_private_query {privmsgnick ' . $color . '$[-10]0}$2');
}

sub sig_join {
  my ($server, $channel, $nick, $address) = @_;

  my $color = $saved_colors{$nick};
  if (!$color) {
    $color = $session_colors{$nick};
  }
  if (!$color) {
    $color = simple_hash $nick;
    $session_colors{$nick} = $color;
  }

  $server->command('/^format join {channick '.$color.'$0} joined {channel $2}');
}

sub sig_part {
  my ($server, $channel, $nick, $address) = @_;

  my $color = $saved_colors{$nick};
  if (!$color) {
    $color = $session_colors{$nick};
  }
  if (!$color) {
    $color = simple_hash $nick;
    $session_colors{$nick} = $color;
  }

  $server->command('/^format part {channick '.$color.'$0} left {channel $2} {reason $3}');
}

sub sig_quit {
  my ($server, $channel, $nick, $address) = @_;

  my @parts = split /@/, $nick;
  $nick = @parts[0];

  my $color = $saved_colors{$nick};
  if (!$color) {
    $color = $session_colors{$nick};
  }
  if (!$color) {
    $color = simple_hash $nick;
    $session_colors{$nick} = $color;
  }

  $server->command('/^format quit {channick '.$color.'$0} quit {reason $2}');
}

sub cmd_color {
  my ($data, $server, $witem) = @_;
  my ($op, $nick, $color) = split " ", $data;

  $op = lc $op;

  if (!$op) {
    Irssi::print ("No operation given");
  } elsif ($op eq "save") {
    save_colors;
    Irssi::print("Colors saved to disk");
  } elsif ($op eq "set") {
    if (!$nick) {
      Irssi::print ("Nick not given");
    } elsif (!$color) {
      Irssi::print ("Color not given");
    } else {
      $saved_colors{$nick} = $color;
    }
  } elsif ($op eq "clear") {
    if (!$nick) {
      Irssi::print ("Nick not given");
    } else {
      delete ($saved_colors{$nick});
    }
  } elsif ($op eq "list") {
    Irssi::print ("\nSaved Colors:");
    foreach my $nick (keys %saved_colors) {
      my $escaped = $saved_colors{$nick};
      $escaped =~ s/\%/_/g;
      Irssi::print ("$escaped".": $saved_colors{$nick}$nick");
    }
    Irssi::print ("\nSession Colors:");
    foreach my $nick (keys %session_colors) {
      my $escaped = $session_colors{$nick};
      $escaped =~ s/\%/_/g;
      Irssi::print ("$escaped".": $session_colors{$nick}$nick");
    }
  } elsif ($op eq "preview") {
    Irssi::print ("\nAvailable colors:");
    while ($color=shift(@colors)) {
      my $escaped = $color;
      $escaped =~ s/\%/_/g;
      Irssi::print ("$color" . "Color $escaped");
    }
  }
}

load_colors;

Irssi::command_bind('color', 'cmd_color');

Irssi::signal_add('message public', 'sig_public');
Irssi::signal_add('message private', 'sig_private');
Irssi::signal_add('message join', 'sig_join');
Irssi::signal_add('message part', 'sig_part');
Irssi::signal_add('message quit', 'sig_quit');
Irssi::signal_add('event nick', 'sig_nick');
