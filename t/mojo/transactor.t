use Mojo::Base -strict;

use Test::More tests => 175;

use File::Spec;
use FindBin;

# "Once the government approves something, it's no longer immoral!"
use_ok 'Mojo::UserAgent::Transactor';

# Simle GET
my $t = Mojo::UserAgent::Transactor->new;
my $tx = $t->tx(GET => 'mojolicio.us/foo.html?bar=baz');
is $tx->req->url->to_abs, 'http://mojolicio.us/foo.html?bar=baz', 'right URL';
is $tx->req->method, 'GET', 'right method';

# POST with header
$tx = $t->tx(POST => 'https://mojolicio.us', {Expect => 'nothing'});
is $tx->req->url->to_abs, 'https://mojolicio.us', 'right URL';
is $tx->req->method, 'POST', 'right method';
is $tx->req->headers->expect, 'nothing', 'right "Expect" value';

# POST with header and content
$tx = $t->tx(POST => 'https://mojolicio.us', {Expect => 'nothing'}, 'test');
is $tx->req->url->to_abs, 'https://mojolicio.us', 'right URL';
is $tx->req->method, 'POST', 'right method';
is $tx->req->headers->expect, 'nothing', 'right "Expect" value';
is $tx->req->body, 'test', 'right content';

# DELETE with content
$tx = $t->tx(DELETE => 'https://mojolicio.us', 'test');
is $tx->req->url->to_abs, 'https://mojolicio.us', 'right URL';
is $tx->req->method, 'DELETE', 'right method';
is $tx->req->headers->expect, undef, 'no "Expect" value';
is $tx->req->body, 'test', 'right content';

# Simple form
$tx = $t->form('http://kraih.com/foo' => {test => 123});
is $tx->req->url->to_abs, 'http://kraih.com/foo', 'right URL';
is $tx->req->method, 'POST', 'right method';
is $tx->req->headers->content_type, 'application/x-www-form-urlencoded',
  'right "Content-Type" value';
is $tx->req->body, 'test=123', 'right content';

# UTF-8 form
$tx = $t->form('http://kraih.com/foo', 'UTF-8', {test => 123});
is $tx->req->url->to_abs, 'http://kraih.com/foo', 'right URL';
is $tx->req->method, 'POST', 'right method';
is $tx->req->headers->content_type, 'application/x-www-form-urlencoded',
  'right "Content-Type" value';
is $tx->req->body, 'test=123', 'right content';

# UTF-8 form with header
$tx =
  $t->form('http://kraih.com/foo', 'UTF-8', {test => 123}, {Accept => '*/*'});
is $tx->req->url->to_abs, 'http://kraih.com/foo', 'right URL';
is $tx->req->method, 'POST', 'right method';
is $tx->req->headers->content_type, 'application/x-www-form-urlencoded',
  'right "Content-Type" value';
is $tx->req->headers->accept, '*/*', 'right "Accept" value';
is $tx->req->body, 'test=123', 'right content';

# Multipart form with real file
$tx =
  $t->form('http://kraih.com/foo',
  {mytext => {file => File::Spec->catdir($FindBin::Bin, 'transactor.t')}});
is $tx->req->url->to_abs, 'http://kraih.com/foo', 'right URL';
is $tx->req->method, 'POST', 'right method';
is $tx->req->headers->content_type, 'multipart/form-data',
  'right "Content-Type" value';
like $tx->req->content->parts->[0]->headers->content_disposition, qr/mytext/,
  'right "Content-Disposition" value';
like $tx->req->content->parts->[0]->asset->slurp, qr/mytext/, 'right part';
is $tx->req->content->parts->[1], undef, 'no more parts';

# Multipart form with in-memory content
$tx = $t->form('http://kraih.com/foo', {mytext => {content => 'lalala'}});
is $tx->req->url->to_abs, 'http://kraih.com/foo', 'right URL';
is $tx->req->method, 'POST', 'right method';
is $tx->req->headers->content_type, 'multipart/form-data',
  'right "Content-Type" value';
like $tx->req->content->parts->[0]->headers->content_disposition, qr/mytext/,
  'right "Content-Disposition" value';
is $tx->req->content->parts->[0]->asset->slurp, 'lalala', 'right part';
is $tx->req->content->parts->[1], undef, 'no more parts';

# Multipart form with filename
$tx =
  $t->form('http://kraih.com/foo',
  {myzip => {content => 'whatever', filename => 'foo.zip'}});
is $tx->req->url->to_abs, 'http://kraih.com/foo', 'right URL';
is $tx->req->method, 'POST', 'right method';
is $tx->req->headers->content_type, 'multipart/form-data',
  'right "Content-Type" value';
like $tx->req->content->parts->[0]->headers->content_disposition,
  qr/foo\.zip/,
  'right "Content-Disposition" value';
is $tx->req->content->parts->[0]->asset->slurp, 'whatever', 'right part';
is $tx->req->content->parts->[1], undef, 'no more parts';

# Simple peer
$tx = $t->tx(GET => 'mojolicio.us');
is(($t->peer($tx))[0], 'http',         'right scheme');
is(($t->peer($tx))[1], 'mojolicio.us', 'right host');
is(($t->peer($tx))[2], 80,             'right port');

# HTTPS peer
$tx = $t->tx(GET => 'https://mojolicio.us');
is(($t->peer($tx))[0], 'https',        'right scheme');
is(($t->peer($tx))[1], 'mojolicio.us', 'right host');
is(($t->peer($tx))[2], 443,            'right port');

# Proxy peer
$tx = $t->tx(GET => 'https://mojolicio.us');
$tx->req->proxy('http://127.0.0.1:3000');
is(($t->peer($tx))[0], 'http',      'right scheme');
is(($t->peer($tx))[1], '127.0.0.1', 'right host');
is(($t->peer($tx))[2], 3000,        'right port');

# WebSocket handshake
$tx = $t->websocket('ws://127.0.0.1:3000/echo');
is $tx->req->url->to_abs, 'http://127.0.0.1:3000/echo', 'right URL';
is $tx->req->method, 'GET', 'right method';
is $tx->req->headers->connection, 'Upgrade', 'right "Connection" value';
ok $tx->req->headers->sec_websocket_key, 'has "Sec-WebSocket-Key" value';
ok $tx->req->headers->sec_websocket_protocol,
  'has "Sec-WebSocket-Protocol" value';
ok $tx->req->headers->sec_websocket_version,
  'has "Sec-WebSocket-Version" value';
is $tx->req->headers->upgrade, 'websocket', 'right "Upgrade" value';

# WebSocket handshake with header
$tx = $t->websocket('wss://127.0.0.1:3000/echo', {Expect => 'foo'});
is $tx->req->url->to_abs, 'https://127.0.0.1:3000/echo', 'right URL';
is $tx->req->method, 'GET', 'right method';
is $tx->req->headers->expect,     'foo',     'right "Upgrade" value';
is $tx->req->headers->connection, 'Upgrade', 'right "Connection" value';
ok $tx->req->headers->sec_websocket_key, 'has "Sec-WebSocket-Key" value';
ok $tx->req->headers->sec_websocket_protocol,
  'has "Sec-WebSocket-Protocol" value';
ok $tx->req->headers->sec_websocket_version,
  'has "Sec-WebSocket-Version" value';
is $tx->req->headers->upgrade, 'websocket', 'right "Upgrade" value';

# Proxy CONNECT
$tx = $t->tx(GET => 'https://mojolicio.us');
$tx->req->proxy('http://127.0.0.1:3000');
$tx = $t->proxy_connect($tx);
is $tx->req->method, 'CONNECT', 'right method';
is $tx->req->url->to_abs,   'https://mojolicio.us',  'right URL';
is $tx->req->proxy->to_abs, 'http://127.0.0.1:3000', 'right proxy URL';

# Simple 302 redirect
$tx =
  $t->tx(POST => 'http://mojolico.us/foo', {Accept => 'application/json'});
$tx->res->code(302);
$tx->res->headers->location('http://kraih.com/bar');
is $tx->req->headers->accept, 'application/json', 'right "Accept" value';
is $tx->req->body, '', 'no content';
$tx = $t->redirect($tx);
is $tx->req->method, 'GET', 'right method';
is $tx->req->url->to_abs,       'http://kraih.com/bar', 'right URL';
is $tx->req->headers->accept,   undef,                  'no "Accept" value';
is $tx->req->headers->location, undef,                  'no "Location" value';
is $tx->req->body, '',    'no content';
is $tx->res->code, undef, 'no status';
is $tx->res->headers->location, undef, 'no "Location" value';

# 302 redirect (dynamic)
$tx = $t->tx(POST => 'http://mojolico.us/foo');
$tx->res->code(302);
$tx->res->headers->location('http://kraih.com/bar');
$tx->req->write_chunk('whatever', sub { shift->finish });
$tx = $t->redirect($tx);
is $tx->req->method, 'GET', 'right method';
is $tx->req->url->to_abs,       'http://kraih.com/bar', 'right URL';
is $tx->req->headers->accept,   undef,                  'no "Accept" value';
is $tx->req->headers->location, undef,                  'no "Location" value';
is $tx->req->body, '',    'no content';
is $tx->res->code, undef, 'no status';
is $tx->res->headers->location, undef, 'no "Location" value';

# Simple 303 redirect
$tx =
  $t->tx(POST => 'http://mojolico.us/foo', {Accept => 'application/json'});
$tx->res->code(303);
$tx->res->headers->location('http://kraih.com/bar');
is $tx->req->headers->accept, 'application/json', 'right "Accept" value';
is $tx->req->body, '', 'no content';
$tx = $t->redirect($tx);
is $tx->req->method, 'GET', 'right method';
is $tx->req->url->to_abs,       'http://kraih.com/bar', 'right URL';
is $tx->req->headers->accept,   undef,                  'no "Accept" value';
is $tx->req->headers->location, undef,                  'no "Location" value';
is $tx->req->body, '',    'no content';
is $tx->res->code, undef, 'no status';
is $tx->res->headers->location, undef, 'no "Location" value';

# 303 redirect (dynamic)
$tx = $t->tx(POST => 'http://mojolico.us/foo');
$tx->res->code(303);
$tx->res->headers->location('http://kraih.com/bar');
$tx->req->write_chunk('whatever', sub { shift->finish });
$tx = $t->redirect($tx);
is $tx->req->method, 'GET', 'right method';
is $tx->req->url->to_abs,       'http://kraih.com/bar', 'right URL';
is $tx->req->headers->accept,   undef,                  'no "Accept" value';
is $tx->req->headers->location, undef,                  'no "Location" value';
is $tx->req->body, '',    'no content';
is $tx->res->code, undef, 'no status';
is $tx->res->headers->location, undef, 'no "Location" value';

# 303 redirect (additional headers)
$tx = $t->tx(
  POST => 'http://mojolico.us/foo' => {
    Accept  => 'application/json',
    Cookie  => 'one',
    Host    => 'two',
    Referer => 'three'
  }
);
$tx->res->code(303);
$tx->res->headers->location('http://kraih.com/bar');
is $tx->req->headers->accept,   'application/json', 'right "Accept" value';
is $tx->req->headers->cookie,   'one',              'right "Cookie" value';
is $tx->req->headers->host,     'two',              'right "Host" value';
is $tx->req->headers->referrer, 'three',            'right "Referer" value';
is $tx->req->body, '', 'no content';
$tx = $t->redirect($tx);
is $tx->req->method, 'GET', 'right method';
is $tx->req->url->to_abs,       'http://kraih.com/bar', 'right URL';
is $tx->req->headers->accept,   undef,                  'no "Accept" value';
is $tx->req->headers->cookie,   undef,                  'no "Cookie" value';
is $tx->req->headers->host,     undef,                  'no "Host" value';
is $tx->req->headers->location, undef,                  'no "Location" value';
is $tx->req->headers->referrer, undef,                  'no "Referer" value';
is $tx->req->body, '',    'no content';
is $tx->res->code, undef, 'no status';
is $tx->res->headers->location, undef, 'no "Location" value';

# Simple 301 redirect
$tx =
  $t->tx(POST => 'http://mojolico.us/foo', {Accept => 'application/json'});
$tx->res->code(301);
$tx->res->headers->location('http://kraih.com/bar');
is $tx->req->headers->accept, 'application/json', 'right "Accept" value';
is $tx->req->body, '', 'no content';
$tx = $t->redirect($tx);
is $tx->req->method, 'POST', 'right method';
is $tx->req->url->to_abs,       'http://kraih.com/bar', 'right URL';
is $tx->req->headers->accept,   'application/json',     'no "Accept" value';
is $tx->req->headers->location, undef,                  'no "Location" value';
is $tx->req->body, '',    'no content';
is $tx->res->code, undef, 'no status';
is $tx->res->headers->location, undef, 'no "Location" value';

# 301 redirect with content
$tx = $t->tx(POST => 'http://mojolico.us/foo', {Accept => '*/*'}, 'whatever');
$tx->res->code(301);
$tx->res->headers->location('http://kraih.com/bar');
is $tx->req->headers->accept, '*/*', 'right "Accept" value';
is $tx->req->body, 'whatever', 'right content';
$tx = $t->redirect($tx);
is $tx->req->method, 'POST', 'right method';
is $tx->req->url->to_abs, 'http://kraih.com/bar', 'right URL';
is $tx->req->headers->accept, '*/*', 'right "Accept" value';
is $tx->req->headers->location, undef, 'no "Location" value';
is $tx->req->body, 'whatever', 'right content';
is $tx->res->code, undef,      'no status';
is $tx->res->headers->location, undef, 'no "Location" value';

# 301 redirect (dynamic)
$tx = $t->tx(POST => 'http://mojolico.us/foo');
$tx->res->code(301);
$tx->res->headers->location('http://kraih.com/bar');
$tx->req->write_chunk('whatever', sub { shift->finish });
is $t->redirect($tx), undef, 'unsupported redirect';

# Simple 307 redirect
$tx =
  $t->tx(POST => 'http://mojolico.us/foo', {Accept => 'application/json'});
$tx->res->code(307);
$tx->res->headers->location('http://kraih.com/bar');
is $tx->req->headers->accept, 'application/json', 'right "Accept" value';
is $tx->req->body, '', 'no content';
$tx = $t->redirect($tx);
is $tx->req->method, 'POST', 'right method';
is $tx->req->url->to_abs,     'http://kraih.com/bar', 'right URL';
is $tx->req->headers->accept, 'application/json',     'right "Accept" value';
is $tx->req->headers->location, undef, 'no "Location" value';
is $tx->req->body, '',    'no content';
is $tx->res->code, undef, 'no status';
is $tx->res->headers->location, undef, 'no "Location" value';

# 307 redirect with content
$tx = $t->tx(POST => 'http://mojolico.us/foo', {Accept => '*/*'}, 'whatever');
$tx->res->code(307);
$tx->res->headers->location('http://kraih.com/bar');
is $tx->req->headers->accept, '*/*', 'right "Accept" value';
is $tx->req->body, 'whatever', 'right content';
$tx = $t->redirect($tx);
is $tx->req->method, 'POST', 'right method';
is $tx->req->url->to_abs, 'http://kraih.com/bar', 'right URL';
is $tx->req->headers->accept, '*/*', 'right "Accept" value';
is $tx->req->headers->location, undef, 'no "Location" value';
is $tx->req->body, 'whatever', 'right content';
is $tx->res->code, undef,      'no status';
is $tx->res->headers->location, undef, 'no "Location" value';

# 307 redirect (dynamic)
$tx = $t->tx(POST => 'http://mojolico.us/foo');
$tx->res->code(307);
$tx->res->headers->location('http://kraih.com/bar');
$tx->req->write_chunk('whatever', sub { shift->finish });
is $t->redirect($tx), undef, 'unsupported redirect';

# 307 redirect (additional headers)
$tx = $t->tx(
  POST => 'http://mojolico.us/foo' => {
    Accept  => 'application/json',
    Cookie  => 'one',
    Host    => 'two',
    Referer => 'three'
  }
);
$tx->res->code(307);
$tx->res->headers->location('http://kraih.com/bar');
is $tx->req->headers->accept,   'application/json', 'right "Accept" value';
is $tx->req->headers->cookie,   'one',              'right "Cookie" value';
is $tx->req->headers->host,     'two',              'right "Host" value';
is $tx->req->headers->referrer, 'three',            'right "Referer" value';
is $tx->req->body, '', 'no content';
$tx = $t->redirect($tx);
is $tx->req->method, 'POST', 'right method';
is $tx->req->url->to_abs,     'http://kraih.com/bar', 'right URL';
is $tx->req->headers->accept, 'application/json',     'right "Accept" value';
is $tx->req->headers->cookie, undef,                  'no "Cookie" value';
is $tx->req->headers->host,   undef,                  'no "Host" value';
is $tx->req->headers->location, undef, 'no "Location" value';
is $tx->req->headers->referrer, undef, 'no "Referer" value';
is $tx->req->body, '',    'no content';
is $tx->res->code, undef, 'no status';
is $tx->res->headers->location, undef, 'no "Location" value';

# 308 redirect (unsupported)
$tx =
  $t->tx(POST => 'http://mojolico.us/foo', {Accept => 'application/json'});
$tx->res->code(308);
$tx->res->headers->location('http://kraih.com/bar');
is $tx->req->headers->accept, 'application/json', 'right "Accept" value';
is $tx->req->body, '', 'no content';
is $t->redirect($tx), undef, 'unsupported redirect';
