use Mojo::Base -strict;

use Test::More;
use Mojo::Exception;
use Mojo::File 'path';

# Basics
my $e = Mojo::Exception->new;
is $e->message, 'Exception!', 'right message';
is "$e", 'Exception!', 'right message';
$e = Mojo::Exception->new('Test!');
is $e->message, 'Test!', 'right message';
is "$e", 'Test!', 'right message';

# Context information
my $line = __LINE__;
eval {

  # test

  my $wrapper = sub { Mojo::Exception->throw('Works!') };
  $wrapper->();

  # test

};
$e = $@;
isa_ok $e, 'Mojo::Exception', 'right class';
is $e,     'Works!',          'right result';
like $e->frames->[0][1], qr/exception\.t/, 'right file';
is $e->lines_before->[0][0], $line + 1, 'right number';
is $e->lines_before->[0][1], 'eval {', 'right line';
is $e->lines_before->[1][0], $line + 2, 'right number';
ok !$e->lines_before->[1][1], 'empty line';
is $e->lines_before->[2][0], $line + 3, 'right number';
is $e->lines_before->[2][1], '  # test', 'right line';
is $e->lines_before->[3][0], $line + 4, 'right number';
ok !$e->lines_before->[3][1], 'empty line';
is $e->lines_before->[4][0], $line + 5, 'right number';
is $e->lines_before->[4][1],
  "  my \$wrapper = sub { Mojo::Exception->throw('Works!') };", 'right line';
is $e->line->[0], $line + 6, 'right number';
is $e->line->[1], "  \$wrapper->();", 'right line';
is $e->lines_after->[0][0], $line + 7, 'right number';
ok !$e->lines_after->[0][1], 'empty line';
is $e->lines_after->[1][0], $line + 8, 'right number';
is $e->lines_after->[1][1], '  # test', 'right line';
is $e->lines_after->[2][0], $line + 9, 'right number';
ok !$e->lines_after->[2][1], 'empty line';
is $e->lines_after->[3][0], $line + 10, 'right number';
is $e->lines_after->[3][1], '};', 'right line';
is $e->lines_after->[4][0], $line + 11, 'right number';
is $e->lines_after->[4][1], '$e = $@;', 'right line';

# Trace
sub wrapper2 { Mojo::Exception->new->trace(@_) }
sub wrapper1 { wrapper2(@_) }
like wrapper1()->frames->[0][3], qr/wrapper2/, 'right subroutine';
like wrapper1(0)->frames->[0][3], qr/trace/,    'right subroutine';
like wrapper1(1)->frames->[0][3], qr/wrapper2/, 'right subroutine';
like wrapper1(2)->frames->[0][3], qr/wrapper1/, 'right subroutine';

# Inspect (UTF-8)
my $file = path(__FILE__)->sibling('exception', 'utf8.txt');
$e = Mojo::Exception->new("Whatever at $file line 3.");
is_deeply $e->lines_before, [], 'no lines';
is_deeply $e->line,         [], 'no line';
is_deeply $e->lines_after,  [], 'no lines';
$e->inspect;
is_deeply $e->lines_before->[-1], [2, 'use warnings;'], 'right line';
is_deeply $e->line,               [3, 'use utf8;'],     'right line';
is_deeply $e->lines_after->[0],   [4, ''],              'right line';
$e->message("Died at $file line 4.")->inspect;
is_deeply $e->lines_before->[-1], [3, 'use utf8;'], 'right line';
is_deeply $e->line,               [4, ''],          'right line';
is_deeply $e->lines_after->[0], [5, "my \$s = 'Über•résumé';"],
  'right line';

# Inspect (non UTF-8)
$file = $file->sibling('non_utf8.txt');
$e    = Mojo::Exception->new("Whatever at $file line 3.");
is_deeply $e->lines_before, [], 'no lines';
is_deeply $e->line,         [], 'no line';
is_deeply $e->lines_after,  [], 'no lines';
$e->inspect;
is_deeply $e->lines_before->[-1], [2, 'use warnings;'], 'right line';
is_deeply $e->line,               [3, 'no utf8;'],      'right line';
is_deeply $e->lines_after->[0],   [4, ''],              'right line';
$e->message("Died at $file line 4.")->inspect;
is_deeply $e->lines_before->[-1], [3, 'no utf8;'], 'right line';
is_deeply $e->line,               [4, ''],         'right line';
is_deeply $e->lines_after->[0], [5, "my \$s = '\xDCber\x95r\xE9sum\xE9';"],
  'right line';

# Verbose
$e = Mojo::Exception->new('Test!')->verbose(1);
$e->lines_before([[3, 'foo();']])->line([4, 'die;'])
  ->lines_after([[5, 'bar();']]);
is $e, <<EOF, 'right result';
Test!
3: foo();
4: die;
5: bar();
EOF
$e->message("Works!\n")->lines_before([])->lines_after([]);
is $e, <<EOF, 'right result';
Works!
4: die;
EOF

done_testing();
