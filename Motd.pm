package Apache::Motd;

use strict;
use vars qw($VERSION);
use Apache;
use Apache::Cookie;
use Apache::Constants qw(:common);

$VERSION = '0.01';

sub handler {
    my $r    = shift;
    my $uri  = $r->uri;
    my $cn   = $r->dir_config('CookieName')     || 'seenMOTD';
    my $exp  = $r->dir_config('ExpireCookie')   || '+1d';
    my $sec  = $r->dir_config('RedirectInSecs') || 10;
    my $file = $r->dir_config('MessageFile')    || 0;

    unless ($file) {
       $r->log_error("Apache::Motd::Error : No MessageFile Specified!");
       return SERVER_ERROR;
    }
 
    return OK unless $r->is_initial_req;
 
    ## Look for cookie and verify value
    my $cookies = Apache::Cookie->new($r)->parse;
    if (my $c   = $cookies->{$cn}) {
        my $cv  = $c->value;
 
        return OK if $cv eq '1';
    }
 
    ## Prepare cookie information
    my $cookie = Apache::Cookie->new($r,
                      -name => $cn,-value => '1',-expires => $exp );
 
    $cookie->bake;
 
    ## Open motd file, otherwise server error
    unless (open MSG,$file) {
       $r->log_error("Apache::Motd::Error : Unable to load: $file");
       return SERVER_ERROR;
    }
 
    ## Slurp message $file into a string
    my $msg = "";
    {
      local $/;
      $msg = <MSG>;
    }
    close MSG;
 
    ## Substitute template variables
    $msg =~ s/<VAR_URI>/$uri/g;
    $msg =~ s/<VAR_REDIRECT>/$sec/g;
 
    $r->send_http_header('text/html');
    $r->print($msg);
 
    return DONE;
}

1;
__END__


=head1 NAME

Apache::Motd - Provide motd (Message of the Day) functionality to a webserver

=head1 SYNOPSIS

 in your httpd.conf 

 <Directive /path/>
   PerlHeaderParserHandler Apache::Motd
   PerlSetVar MessageFile   /path/to/motd/message **
   PerlSetVar CookieName     CookieName [seeMOTD]
   PerlSetVar ExpireCookie   CookieExpirationTime [+1d]
   PerlSetVar RedirectInSecs N [10]
 </Directive>

 **Required Variable, all others are optional

=head1 DESCRIPTION

This Apache Perl module provides a web administrator the ability to 
configure a webserver with motd (Message of the Day) functionality, just
like you find on UNIX systems. This allows custom messages to appear when 
visitors enter a website or a section of the website, without the need to
modify any webpages or web application code!  The message can be a "Message 
of the Day", "Terms of Use", "Server Going Down in N Hours", etc. When 
applied in the main server configuration (i.e. non <Location|Directory|Files> 
directives), any webpage accessed on the webserver will redirect the visitor 
to the custom message momentarily. Then after N seconds, will be redirected 
to their originally requested URI, at the same time setting a cookie so that 
subsequent requests will not be directed to the custom message.  A link to the 
requested URI can also be provided, so that the user has the option of 
proceeding without having to wait the entire redirect time. (See motd.txt 
example provided in this distribution)
 

The intention of this module is to provide an alternate and more efficient
method of notifying your web users of potential downtime or problems affecting
your webserver and/or webservices.


=head1 CONFIGURATION

The module can be placed in <Location>, <Directory>, <Files> and main server
configuration areas. 

=over 4

=item MessageFile (required)

The filesystem path to the file that contains the custom message

See B<MessageFile Format> for a description how the message should
be used.


=item RedirectInSecs (default: 10 seconds)

This sets the wait time (in seconds) before the visitor is redirected to the
initally requested URI


=item CookieName (default: seenMOTD)

Set the name of the cookie name 


=item ExpireCookie (default: +1d, 1 day)

Set the expiration time for the cookie

=back

   Example:

   <Location />
    PerlHeaderParserHandler Apache::Motd
    PerlSetVar MessageFile /proj/www/motd.txt
    PerlSetVar CookieName TermUsage
    PerlSetVar RedirectInSecs 5
   </Location>


  The example above, sets a server wide message (/proj/www/motd.txt) that
  sets a cookie called TermUsage which expires in one day (default value)
  and redirects the user to the original URI in 5 seconds.


=head1 Message File Format

The text file containing the custom message has access to the following
tag variables:

=over 4

=item B<VAR_URI>

This tag will be replaced with the requested URI. 

Recommended usage:

<a href="<VAR_URI>">click here to proceed</a>

The above example provides a link to the original requested URI, so that
a user can click and bypass the time redirect.



=item B<VAR_REDIRECT>

This tag will be replaced with the value set in RedirectInSecs.
Which can be used in the meta tag for redirection. 

=back

Example:

   ...
   <head>
   <meta http-equiv="refresh" content="<VAR_REDIRECT>;URL=<VAR_URI>">
   ...
   </head>
   ...

The custom message should at least contain a redirect (using a meta tag) and
a link to allow users to bypass the redirect time (for impatient users and
as a courtesy). Omitting these will result in the page not redirecting the user
to the initially requested page.


=head1 BUGS

=over 4

=item No error checking on the custom message

The template is not checked for the neccessary information required for the
redirection to work properly, i.e. usage of <VAR_URI> and <VAR_REDIRECT>. 
Therefore not using the available tags as described will result in 
unpredictable behavior.

=back
 

=head1 REQUIREMENTS

 L<mod_perl>, L<Apache::Cookie>

=head1 AUTHOR

 Carlos Ramirez <carlos@quantumfx.com>

=head1 COPYRIGHT

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
 

If you have questions or problems regarding use or installation of this module
please feel free to email me directly.


=cut
