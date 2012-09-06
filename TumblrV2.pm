package Plagger::Plugin::Publish::TumblrV2;
use strict;
use warnings;
use Config::Pit;

use base qw( Plagger::Plugin );
use lib qw(/home/toshi/perl/lib);
use Encode;
use Time::HiRes qw(sleep);
use TumblrPostV2;

sub register {
	my($self, $context) = @_;
	$context->register_hook(
		$self,
		'publish.entry' => \&publish_entry,
		'plugin.init'   => \&initialize,
	);
}

sub initialize {
	my($self, $context) = @_;
	my $pit_account = $self->conf->{pit_account};
  $self->{tumblr} = TumblrPostV2->new($pit_account);
	return $self;
}

sub publish_entry {
	my($self, $context, $args) = @_;
	
	my $title = $args->{entry}->{title} || $args->{feed}->{title};
#	$title = encode_utf8($title);

	my $body = $args->{entry}->{body};
#	$body = encode_utf8($body);

	my $link = $args->{entry}->{link};
	my $type = $self->conf->{type} || 'regular';
	my $state = $self->conf->{state} || 'queue'; #state{ published, draft, queue}  

	$context->log(info => "Tumblr($type) posting '$title'");

	my %post_opt;

	if($type eq 'text'){
		my $post = $body . "<div><a href=\"" . $link . "\">" . $title . "</a></div>";
		%post_opt= (
			'type'	=> 'regular',
			'title'	=> $title,
			'body'	=> $post,
			'state' => $state,
		);
	}elsif($type eq 'quote'){
		my $source = "<a href=\"" . $link . "\">" . $title . "</a>";
		%post_opt = (
			'type'	=> 'quote',
			'quote'	=> $body,
			'source'=> $source,
			'state'	=> $state,
		);
	}elsif($type eq 'link'){
		%post_opt = (
			'type'	=> 'link',
			'name'	=> $title,
			'url'		=> $link,
			'description'	=> $body,
			'state'	=> $state,
		);
	}elsif($type eq 'photo'){
#       for my $enclosure ($args->{entry}->enclosures) {
		my $enclosure = $args->{entry}->enclosures->[0];
		$context->log(debug => "posting " . $enclosure->{url});
		if($self->conf->{caption}){
			%post_opt = (
				'type'		=> 'photo',
				'source'	=> $enclosure->{url},
				'caption'	=> $body,
				'click-through-url' => $link,
				'state'		=> $state,
			);
		}else{
			my $caption = "<a href=\"" . $link . "\">" . $title . "</a>";
			%post_opt =(
				'type'		=> 'photo',
				'source'	=> $enclosure->{url},
				'caption'	=> $caption,
				'click-through-url' => $link,
				'state'		=> $state,
			);
		}
	}
	
	$self->{tumblr}->set_option(%post_opt);
	$self->{tumblr}->post('post');

	if ($self->{tumblr}->_err) {
		$context->log(debug => "post failed");
	}else{
		$context->log(debug => "post succeeded");
	}

	my $sleeping_time = $self->conf->{interval} || 5;
	$context->log(info => "sleep $sleeping_time.");
	sleep( $sleeping_time );
}

1;

__END__

=head1 NAME

Plagger::Plugin::Publish::Tumblr - Post to Tumblr

=head1 SYNOPSIS

  - module: Publish::Tumblr
    config:
      pit_account: hoge.tumblr.com
      type: photo
      caption: 1
      interval: 2
      state: published # queue, draft

=head1 DESCRIPTION

This plugin automatically posts entries to Tumblr L<http://www.tumblr.com/>.

Based on L<https://github.com/riywo/plagger/blob/master/lib/Plagger/Plugin/Publish/Tumblr.pm> coded by riywo

#The email address and password used to login are stored with Config::Pit.
#For the initial run, do
#perl -MConfig::Pit -e'Config::Pit::set('tumblr.com', data=>{ email => 'foobar@eaxmple.com', password => 'barbaz' })'

use Tumblr API ver2
use TumblrPostV2 and Config::Pit's yaml

like this 

"tumblr.azwad.com":
  "blog_name": 'toshi.tumblr.com'
  "consumer_key": 'xxxxxxxxxxxxxxxxxxxxxxCa5YDBzyC0D9B3sXHsdW4lWjPglD'
  "consumer_secret": 'xxxxxxxxxxxxxxxxxxxxxfvH0MJ4rvC6SbnsPohtFx2o9wOrx'
  "token": 'xxxxxxxxxxxxxxxxxxjY6zbm4XPzGkmiFCUubkAEmnOhO229Vp1zu'
  "token_secret": 'xxxxxxxxxxxxxxxxxxW28GJxcQekNZ9uFFwJQzBCLadIfPHdtc'



The plugin posts either regular, quote, link or photo type entry.
Attributes handled vary with the post type as following:

=over 4

=item text

    - title
    - body with link added at the end

=item quote

    - quote (the body of the entry)
    - source url (the link of the entry)

=item link

    - title/name
    - link
    - description (the body of the entry)

=item photo

    - source url (the enclosure of the entry)
    - caption (the body of the entry)
    - click-through-url (the link of the entry)

=back

=head1 CONFIG

=over 4

=item group

This option allows to post to secondary tumblelog. Simply puts url of the blog.

=item caption

This option is only valid for 'photo' type posts.
By default, the plugin posts a caption like <a href="$link">$title</a>
however, by enabling this, it posts the body of the entry as the caption.

=back

=head1 AUTHOR

azwad

shenqi 

riywo

=head1 SEE ALSO

modified by azwad 
cause can't use Tumblr API ver1

L<Plagger>

=cut
