#!/usr/bin/perl -s
use 5.10.0;
use utf8;
use strict;
use warnings;
use open qw( :utf8 :std );
use autodie qw( open close seek );
use Readonly;
use Data::Dumper;
use Term::ReadKey;
use Time::Piece;
use Fcntl qw( :seek );
use List::Util qw( max );
use Path::Class;

$Data::Dumper::Terse    = 1;
$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Indent   = 1;

Readonly my $IS_AUTHOR_TEST => $ENV{SS_AUTHOR_TEST};

Readonly my $ESC                => "\x{1b}";
Readonly my $CONTROL_U          => "\x{15}";
Readonly my $CONTROL_H          => "\x{08}";
Readonly my $CONTROL_C          => "\x{03}";
Readonly my $RETURN_KEY         => "\n";
Readonly my $SAVE_CURSOR        => "$ESC\[s";
Readonly my $UNSAVE_CURSOR      => "$ESC\[u";
Readonly my $ERASE_END_OF_LINE  => "$ESC\[K";
Readonly my $CURSOR_BACKWARD    => "$ESC\[D";

Readonly my %IDENTIFIER => (
    q{:}    => "colon",
    $ESC    => "escape",
);

Readonly my @BORDERS        => ( 800, 1_500, 3_000, 4_000, 5_000, 7_500, 10_000, 15_000, 20_000, 20_200, 30_000, 30_200, 50_000, 50_101, 100_000, 180_000 );
Readonly my @BORDER_RANGES  => do {
    my $g = sub { state $p = 0; return [ $p + 1, $p = shift ] };
    map { $g->( $_ ) } @BORDERS;
};

Readonly my $INSERT_MODE    => "insert";
Readonly my $NORMAL_MODE    => "normal";

our $h;
my $OUTPUT = do {
    my $output = shift;
    $output //= "test.data"
        if $IS_AUTHOR_TEST;
    $output;
};

die usage( )
    if !$OUTPUT || $h;

my @SCORES = ( 0 ) x @BORDERS;

Path::Class::file( $OUTPUT )->touch
    if !-e $OUTPUT;
open my $OUT, "+<", $OUTPUT;
seek $OUT, 0, SEEK_END;
my $OUT_POS = tell $OUT;

my %STATE = (
    can_continue_to_read    => 1,
    current_index           => 0,
    mode                    => $INSERT_MODE,
    start                   => localtime->datetime,
);

my %perform = (
    normal => sub {
        my $key = read_key( );
        my $subname = "run_by_key_$key";

        if ( main->can( $subname ) ) {
            no strict "refs";
            &{ $subname };
        }
        else {
            warn "No [$key] command exists"
                if $IS_AUTHOR_TEST;
        }
    },
    insert => sub {
        my $score = read_score( );

        if ( $score eq $ESC ) {
            $STATE{mode} = $NORMAL_MODE;
        }
        else {
            $SCORES[ $STATE{current_index}++ ] = $score;
        }

        if ( $STATE{current_index} == @SCORES ) {
            $STATE{current_index}--;
            say "Done all ranges, `w` to save, and `q` to quit.";
            $STATE{mode} = $NORMAL_MODE;
        }
    },
);

while ( $STATE{can_continue_to_read} ) {
    $perform{ $STATE{mode} }->( );
}

close $OUT;

ReadMode 0;

exit;

sub read_score {
    ReadMode 4;
    my $score           = q{};
    my $last_inputted   = "\x{00}";
    my $is_score_valid;
    my $prompt = join q{ }, "border of", join( " - ", @{ $BORDER_RANGES[ $STATE{current_index} ] } ), ": ";

    while ( !$is_score_valid ) {
        print $prompt, $SAVE_CURSOR;

        while ( $last_inputted ne $RETURN_KEY ) {
            my $key = $last_inputted = ReadKey;

            if ( $key eq $ESC ) {
                say "quit from insert mode.";
                return $ESC;
            }

            if ( $key eq $CONTROL_C ) {
                exit;
            }
            elsif ( $key eq $CONTROL_U ) {
                $score = q{};
                print $UNSAVE_CURSOR, $ERASE_END_OF_LINE;
            }
            elsif ( $key eq $CONTROL_H ) {
                if ( length $score ) {
                    substr $score, -1, 1, q{};
                    print $CURSOR_BACKWARD, $ERASE_END_OF_LINE;
                }
            }
            else {
                print $key;
                $score .= $key;
            }
        }

        chomp $score;
        $is_score_valid = $score !~ m{[^\d]};
        $last_inputted  = "\x{00}";

        if ( !$is_score_valid ) {
            say "invalid score [$score]";
            $score = q{};
        }
        else {
            return $score;
        }
    }

    return $score; # never evaluted.
}

sub read_key {
    ReadMode 3;
    my $key = ReadKey;

    warn "\$key: [$key] = [", ord( $key ), "]"
        if $IS_AUTHOR_TEST;

    return $IDENTIFIER{ $key } || $key;
}

sub run_by_key_r {
    ReadMode 0;
    print "what is ranking: ";
    chomp( my $ranking = <STDIN> );

    if ( $ranking =~ m{\A \d+ \z}msx ) {
        $STATE{my_ranking} = $ranking;
    }
    else {
        say "Invalid ranking: [$ranking], retry from entering ranking mode.";
        return;
    }
}

sub run_by_key_s {
    ReadMode 0;
    print "what is score: ";
    chomp( my $score = <STDIN> );

    if ( $score =~ m{\A \d+ \z}msx ) {
        $STATE{my_score} = $score;
    }
    else {
        say "Invalid score: [$score], retry from entering score mode.";
        return;
    }
}

sub run_by_key_d {
    ReadMode 0;
    print "the record date: ";
    chomp( my $datetime = <STDIN> );

    if ( $datetime =~ m{\A \d{4}-\d{2}-\d{2} \s \d{2}:\d{2}:\d{2} \z}msx ) {
        $STATE{start} = $datetime;
    }
    else {
        say "Invalid date: [$datetime]";
        return;
    }
}

sub run_by_key_n {
    $STATE{current_index}++;
    $STATE{current_index} = $#SCORES
        if $STATE{current_index} > $#SCORES;
    say "move to range: ", join( " - ", @{ $BORDER_RANGES[ $STATE{current_index} ] } ), " = $SCORES[ $STATE{current_index} ]";
}

sub run_by_key_p {
    $STATE{current_index}--;
    $STATE{current_index} = 0
        if $STATE{current_index} < 0;
    say "move to range: ", join( " - ", @{ $BORDER_RANGES[ $STATE{current_index} ] } ), " = $SCORES[ $STATE{current_index} ]";
}

sub run_by_key_w { # i can not EOF file.  Re-editing values can be cause of overflow.
    seek $OUT, $OUT_POS, 0;
    say { $OUT } join "\t", $STATE{start}, @SCORES, ( $STATE{my_score} || 0 ), ( $STATE{my_ranking} || 0 );
    $STATE{did_save}++;
}

sub run_by_key_l {
    my %max_width;
    $max_width{start_range} = max( map { length $_->[0] } @BORDER_RANGES );
    $max_width{end_range}   = max( map { length $_->[1] } @BORDER_RANGES );
    $max_width{score}       = max( map { length } @SCORES );
    my $format = "\%$max_width{start_range}d - \%$max_width{end_range}d: \%$max_width{score}d\n";

    for my $i ( 0 .. $#SCORES ) {
        printf $format, @{ $BORDER_RANGES[ $i ] }, $SCORES[ $i ];
    }
}

sub run_by_key_e {
    $STATE{mode} = $INSERT_MODE;
}

sub run_by_key_colon { &run_by_key_e }

sub run_by_key_q {
    if ( $STATE{did_save} ) {
        $STATE{can_continue_to_read} = 0;
    }
    else {
        ReadMode 0;
        my $is_key_y_n;
        my $yes_no;
        print "quit without save? [y/n]";

        while ( !$is_key_y_n ) {
            chomp( my $input = <STDIN> );
            if ( $input !~ m{\A [yn] \z}msx ) {
                say "invalid input [$input]";
            }
            else {
                $yes_no = $input;
                $is_key_y_n++;
            }
        }

        if ( $yes_no eq "y" ) {
            $STATE{can_continue_to_read} = 0;
        }
    }
}

sub run_by_key_h {
    print _help( );
}

sub _help {
    return <<END_HELP;
    h       show this help list
    ESC     quit from writing mode
    q       quit this program
    :,e     enter writing mode
    l       list borders
    w       write borders
    p       go to previous border
    n       go to next border
    d       date time of the record
    s       my score
    r       my runking
END_HELP
}

sub usage {
    return <<END_USAGE;
usage: $0 ( <output file> | -h )
END_USAGE
}

