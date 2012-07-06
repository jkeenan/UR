####################################################################
#
#    This file was generated using Parse::Yapp version 1.05.
#
#        Don't edit this file, use source file instead.
#
#             ANY CHANGE MADE HERE WILL BE LOST !
#
####################################################################
package UR::BoolExpr::BxParser;
use vars qw ( @ISA );
use strict;

@ISA= qw ( UR::BoolExpr::Parser::ParseYappDriver );
#Included Parse/Yapp/Driver.pm file----------------------------------------
{
#
# Module Parse::Yapp::Driver
#
# This module is part of the Parse::Yapp package available on your
# nearest CPAN
#
# Any use of this module in a standalone parser make the included
# text under the same copyright as the Parse::Yapp module itself.
#
# This notice should remain unchanged.
#
# (c) Copyright 1998-2001 Francois Desarmenien, all rights reserved.
# (see the pod text in Parse::Yapp module for use and distribution rights)
#

package UR::BoolExpr::Parser::ParseYappDriver;

require 5.004;

use strict;

use vars qw ( $VERSION $COMPATIBLE $FILENAME );

$VERSION = '1.05';
$COMPATIBLE = '0.07';
$FILENAME=__FILE__;

use Carp;

#Known parameters, all starting with YY (leading YY will be discarded)
my(%params)=(YYLEX => 'CODE', 'YYERROR' => 'CODE', YYVERSION => '',
			 YYRULES => 'ARRAY', YYSTATES => 'ARRAY', YYDEBUG => '');
#Mandatory parameters
my(@params)=('LEX','RULES','STATES');

sub new {
    my($class)=shift;
	my($errst,$nberr,$token,$value,$check,$dotpos);
    my($self)={ ERROR => \&_Error,
				ERRST => \$errst,
                NBERR => \$nberr,
				TOKEN => \$token,
				VALUE => \$value,
				DOTPOS => \$dotpos,
				STACK => [],
				DEBUG => 0,
				CHECK => \$check };

	_CheckParams( [], \%params, \@_, $self );

		exists($$self{VERSION})
	and	$$self{VERSION} < $COMPATIBLE
	and	croak "Yapp driver version $VERSION ".
			  "incompatible with version $$self{VERSION}:\n".
			  "Please recompile parser module.";

        ref($class)
    and $class=ref($class);

    bless($self,$class);
}

sub YYParse {
    my($self)=shift;
    my($retval);

	_CheckParams( \@params, \%params, \@_, $self );

	if($$self{DEBUG}) {
		_DBLoad();
		$retval = eval '$self->_DBParse()';#Do not create stab entry on compile
        $@ and die $@;
	}
	else {
		$retval = $self->_Parse();
	}
    $retval
}

sub YYData {
	my($self)=shift;

		exists($$self{USER})
	or	$$self{USER}={};

	$$self{USER};
	
}

sub YYErrok {
	my($self)=shift;

	${$$self{ERRST}}=0;
    undef;
}

sub YYNberr {
	my($self)=shift;

	${$$self{NBERR}};
}

sub YYRecovering {
	my($self)=shift;

	${$$self{ERRST}} != 0;
}

sub YYAbort {
	my($self)=shift;

	${$$self{CHECK}}='ABORT';
    undef;
}

sub YYAccept {
	my($self)=shift;

	${$$self{CHECK}}='ACCEPT';
    undef;
}

sub YYError {
	my($self)=shift;

	${$$self{CHECK}}='ERROR';
    undef;
}

sub YYSemval {
	my($self)=shift;
	my($index)= $_[0] - ${$$self{DOTPOS}} - 1;

		$index < 0
	and	-$index <= @{$$self{STACK}}
	and	return $$self{STACK}[$index][1];

	undef;	#Invalid index
}

sub YYCurtok {
	my($self)=shift;

        @_
    and ${$$self{TOKEN}}=$_[0];
    ${$$self{TOKEN}};
}

sub YYCurval {
	my($self)=shift;

        @_
    and ${$$self{VALUE}}=$_[0];
    ${$$self{VALUE}};
}

sub YYExpect {
    my($self)=shift;

    keys %{$self->{STATES}[$self->{STACK}[-1][0]]{ACTIONS}}
}

sub YYLexer {
    my($self)=shift;

	$$self{LEX};
}


#################
# Private stuff #
#################


sub _CheckParams {
	my($mandatory,$checklist,$inarray,$outhash)=@_;
	my($prm,$value);
	my($prmlst)={};

	while(($prm,$value)=splice(@$inarray,0,2)) {
        $prm=uc($prm);
			exists($$checklist{$prm})
		or	croak("Unknow parameter '$prm'");
			ref($value) eq $$checklist{$prm}
		or	croak("Invalid value for parameter '$prm'");
        $prm=unpack('@2A*',$prm);
		$$outhash{$prm}=$value;
	}
	for (@$mandatory) {
			exists($$outhash{$_})
		or	croak("Missing mandatory parameter '".lc($_)."'");
	}
}

sub _Error {
	print "Parse error.\n";
}

sub _DBLoad {
	{
		no strict 'refs';

			exists(${__PACKAGE__.'::'}{_DBParse})#Already loaded ?
		and	return;
	}
	my($fname)=__FILE__;
	my(@drv);
	open(DRV,"<$fname") or die "Report this as a BUG: Cannot open $fname";
	while(<DRV>) {
                	/^\s*sub\s+_Parse\s*{\s*$/ .. /^\s*}\s*#\s*_Parse\s*$/
        	and     do {
                	s/^#DBG>//;
                	push(@drv,$_);
        	}
	}
	close(DRV);

	$drv[0]=~s/_P/_DBP/;
	eval join('',@drv);
}

#Note that for loading debugging version of the driver,
#this file will be parsed from 'sub _Parse' up to '}#_Parse' inclusive.
#So, DO NOT remove comment at end of sub !!!
sub _Parse {
    my($self)=shift;

	my($rules,$states,$lex,$error)
     = @$self{ 'RULES', 'STATES', 'LEX', 'ERROR' };
	my($errstatus,$nberror,$token,$value,$stack,$check,$dotpos)
     = @$self{ 'ERRST', 'NBERR', 'TOKEN', 'VALUE', 'STACK', 'CHECK', 'DOTPOS' };

#DBG>	my($debug)=$$self{DEBUG};
#DBG>	my($dbgerror)=0;

#DBG>	my($ShowCurToken) = sub {
#DBG>		my($tok)='>';
#DBG>		for (split('',$$token)) {
#DBG>			$tok.=		(ord($_) < 32 or ord($_) > 126)
#DBG>					?	sprintf('<%02X>',ord($_))
#DBG>					:	$_;
#DBG>		}
#DBG>		$tok.='<';
#DBG>	};

	$$errstatus=0;
	$$nberror=0;
	($$token,$$value)=(undef,undef);
	@$stack=( [ 0, undef ] );
	$$check='';

    while(1) {
        my($actions,$act,$stateno);

        $stateno=$$stack[-1][0];
        $actions=$$states[$stateno];

#DBG>	print STDERR ('-' x 40),"\n";
#DBG>		$debug & 0x2
#DBG>	and	print STDERR "In state $stateno:\n";
#DBG>		$debug & 0x08
#DBG>	and	print STDERR "Stack:[".
#DBG>					 join(',',map { $$_[0] } @$stack).
#DBG>					 "]\n";


        if  (exists($$actions{ACTIONS})) {

				defined($$token)
            or	do {
				($$token,$$value)=&$lex($self);
#DBG>				$debug & 0x01
#DBG>			and	print STDERR "Need token. Got ".&$ShowCurToken."\n";
			};

            $act=   exists($$actions{ACTIONS}{$$token})
                    ?   $$actions{ACTIONS}{$$token}
                    :   exists($$actions{DEFAULT})
                        ?   $$actions{DEFAULT}
                        :   undef;
        }
        else {
            $act=$$actions{DEFAULT};
#DBG>			$debug & 0x01
#DBG>		and	print STDERR "Don't need token.\n";
        }

            defined($act)
        and do {

                $act > 0
            and do {        #shift

#DBG>				$debug & 0x04
#DBG>			and	print STDERR "Shift and go to state $act.\n";

					$$errstatus
				and	do {
					--$$errstatus;

#DBG>					$debug & 0x10
#DBG>				and	$dbgerror
#DBG>				and	$$errstatus == 0
#DBG>				and	do {
#DBG>					print STDERR "**End of Error recovery.\n";
#DBG>					$dbgerror=0;
#DBG>				};
				};


                push(@$stack,[ $act, $$value ]);

					$$token ne ''	#Don't eat the eof
				and	$$token=$$value=undef;
                next;
            };

            #reduce
            my($lhs,$len,$code,@sempar,$semval);
            ($lhs,$len,$code)=@{$$rules[-$act]};

#DBG>			$debug & 0x04
#DBG>		and	$act
#DBG>		and	print STDERR "Reduce using rule ".-$act." ($lhs,$len): ";

                $act
            or  $self->YYAccept();

            $$dotpos=$len;

                unpack('A1',$lhs) eq '@'    #In line rule
            and do {
                    $lhs =~ /^\@[0-9]+\-([0-9]+)$/
                or  die "In line rule name '$lhs' ill formed: ".
                        "report it as a BUG.\n";
                $$dotpos = $1;
            };

            @sempar =       $$dotpos
                        ?   map { $$_[1] } @$stack[ -$$dotpos .. -1 ]
                        :   ();

            $semval = $code ? &$code( $self, @sempar )
                            : @sempar ? $sempar[0] : undef;

            splice(@$stack,-$len,$len);

                $$check eq 'ACCEPT'
            and do {

#DBG>			$debug & 0x04
#DBG>		and	print STDERR "Accept.\n";

				return($semval);
			};

                $$check eq 'ABORT'
            and	do {

#DBG>			$debug & 0x04
#DBG>		and	print STDERR "Abort.\n";

				return(undef);

			};

#DBG>			$debug & 0x04
#DBG>		and	print STDERR "Back to state $$stack[-1][0], then ";

                $$check eq 'ERROR'
            or  do {
#DBG>				$debug & 0x04
#DBG>			and	print STDERR 
#DBG>				    "go to state $$states[$$stack[-1][0]]{GOTOS}{$lhs}.\n";

#DBG>				$debug & 0x10
#DBG>			and	$dbgerror
#DBG>			and	$$errstatus == 0
#DBG>			and	do {
#DBG>				print STDERR "**End of Error recovery.\n";
#DBG>				$dbgerror=0;
#DBG>			};

			    push(@$stack,
                     [ $$states[$$stack[-1][0]]{GOTOS}{$lhs}, $semval ]);
                $$check='';
                next;
            };

#DBG>			$debug & 0x04
#DBG>		and	print STDERR "Forced Error recovery.\n";

            $$check='';

        };

        #Error
            $$errstatus
        or   do {

            $$errstatus = 1;
            &$error($self);
                $$errstatus # if 0, then YYErrok has been called
            or  next;       # so continue parsing

#DBG>			$debug & 0x10
#DBG>		and	do {
#DBG>			print STDERR "**Entering Error recovery.\n";
#DBG>			++$dbgerror;
#DBG>		};

            ++$$nberror;

        };

			$$errstatus == 3	#The next token is not valid: discard it
		and	do {
				$$token eq ''	# End of input: no hope
			and	do {
#DBG>				$debug & 0x10
#DBG>			and	print STDERR "**At eof: aborting.\n";
				return(undef);
			};

#DBG>			$debug & 0x10
#DBG>		and	print STDERR "**Dicard invalid token ".&$ShowCurToken.".\n";

			$$token=$$value=undef;
		};

        $$errstatus=3;

		while(	  @$stack
			  and (		not exists($$states[$$stack[-1][0]]{ACTIONS})
			        or  not exists($$states[$$stack[-1][0]]{ACTIONS}{error})
					or	$$states[$$stack[-1][0]]{ACTIONS}{error} <= 0)) {

#DBG>			$debug & 0x10
#DBG>		and	print STDERR "**Pop state $$stack[-1][0].\n";

			pop(@$stack);
		}

			@$stack
		or	do {

#DBG>			$debug & 0x10
#DBG>		and	print STDERR "**No state left on stack: aborting.\n";

			return(undef);
		};

		#shift the error token

#DBG>			$debug & 0x10
#DBG>		and	print STDERR "**Shift \$error token and go to state ".
#DBG>						 $$states[$$stack[-1][0]]{ACTIONS}{error}.
#DBG>						 ".\n";

		push(@$stack, [ $$states[$$stack[-1][0]]{ACTIONS}{error}, undef ]);

    }

    #never reached
	croak("Error in driver logic. Please, report it as a BUG");

}#_Parse
#DO NOT remove comment

1;

}
#End of include--------------------------------------------------




sub new {
        my($class)=shift;
        ref($class)
    and $class=ref($class);

    my($self)=$class->SUPER::new( yyversion => '1.05',
                                  yystates =>
[
	{#State 0
		ACTIONS => {
			'LEFT_PAREN' => 4,
			'BETWEEN_WORD' => 11,
			'ASC_WORD' => 1,
			'DESC_WORD' => 2,
			'IDENTIFIER' => 3,
			'NOT_WORD' => 6,
			'LIKE_WORD' => 8,
			'FALSE_WORD' => 9,
			'TRUE_WORD' => 12,
			'IN_WORD' => 13
		},
		DEFAULT => -1,
		GOTOS => {
			'boolexpr' => 5,
			'expr' => 10,
			'keyword_as_value' => 7,
			'property' => 15,
			'condition' => 14
		}
	},
	{#State 1
		DEFAULT => -62
	},
	{#State 2
		DEFAULT => -61
	},
	{#State 3
		DEFAULT => -25
	},
	{#State 4
		ACTIONS => {
			'ASC_WORD' => 1,
			'LEFT_PAREN' => 4,
			'IDENTIFIER' => 3,
			'DESC_WORD' => 2,
			'NOT_WORD' => 6,
			'LIKE_WORD' => 8,
			'FALSE_WORD' => 9,
			'BETWEEN_WORD' => 11,
			'TRUE_WORD' => 12,
			'IN_WORD' => 13
		},
		GOTOS => {
			'expr' => 16,
			'keyword_as_value' => 7,
			'condition' => 14,
			'property' => 15
		}
	},
	{#State 5
		ACTIONS => {
			'' => 17,
			'OFFSET' => 18,
			'ORDER_BY' => 20,
			'GROUP_BY' => 19,
			'LIMIT' => 21
		}
	},
	{#State 6
		DEFAULT => -60
	},
	{#State 7
		DEFAULT => -26
	},
	{#State 8
		DEFAULT => -58
	},
	{#State 9
		DEFAULT => -64
	},
	{#State 10
		ACTIONS => {
			'AND' => 22,
			'OR' => 23
		},
		DEFAULT => -2
	},
	{#State 11
		DEFAULT => -59
	},
	{#State 12
		DEFAULT => -63
	},
	{#State 13
		DEFAULT => -57
	},
	{#State 14
		DEFAULT => -7
	},
	{#State 15
		ACTIONS => {
			'DOUBLEEQUAL_SIGN' => 24,
			'NOT_BANG' => 31,
			'NOT_WORD' => 32,
			'COLON' => 25,
			'LIKE_WORD' => 33,
			'OPERATORS' => 26,
			'EQUAL_SIGN' => 34,
			'FALSE_WORD' => 35,
			'BETWEEN_WORD' => 28,
			'TILDE' => 36,
			'TRUE_WORD' => 38,
			'IN_WORD' => 39
		},
		GOTOS => {
			'operator' => 27,
			'like_operator' => 29,
			'an_operator' => 30,
			'in_operator' => 37,
			'boolean_op_word' => 41,
			'between_operator' => 40,
			'negation' => 42
		}
	},
	{#State 16
		ACTIONS => {
			'AND' => 22,
			'OR' => 23,
			'RIGHT_PAREN' => 43
		}
	},
	{#State 17
		DEFAULT => 0
	},
	{#State 18
		ACTIONS => {
			'INTEGER' => 44
		}
	},
	{#State 19
		ACTIONS => {
			'ASC_WORD' => 1,
			'IDENTIFIER' => 3,
			'DESC_WORD' => 2,
			'NOT_WORD' => 6,
			'LIKE_WORD' => 8,
			'FALSE_WORD' => 9,
			'BETWEEN_WORD' => 11,
			'TRUE_WORD' => 12,
			'IN_WORD' => 13
		},
		GOTOS => {
			'keyword_as_value' => 7,
			'group_by_list' => 45,
			'property' => 46
		}
	},
	{#State 20
		ACTIONS => {
			'ASC_WORD' => 1,
			'IDENTIFIER' => 3,
			'DESC_WORD' => 2,
			'NOT_WORD' => 6,
			'MINUS' => 47,
			'LIKE_WORD' => 8,
			'FALSE_WORD' => 9,
			'BETWEEN_WORD' => 11,
			'TRUE_WORD' => 12,
			'IN_WORD' => 13
		},
		GOTOS => {
			'order_by_list' => 50,
			'order_by_property' => 48,
			'keyword_as_value' => 7,
			'property' => 49
		}
	},
	{#State 21
		ACTIONS => {
			'INTEGER' => 51
		}
	},
	{#State 22
		ACTIONS => {
			'ASC_WORD' => 1,
			'IDENTIFIER' => 3,
			'DESC_WORD' => 2,
			'LEFT_PAREN' => 4,
			'NOT_WORD' => 6,
			'LIKE_WORD' => 8,
			'FALSE_WORD' => 9,
			'BETWEEN_WORD' => 11,
			'TRUE_WORD' => 12,
			'IN_WORD' => 13
		},
		GOTOS => {
			'expr' => 52,
			'keyword_as_value' => 7,
			'condition' => 14,
			'property' => 15
		}
	},
	{#State 23
		ACTIONS => {
			'ASC_WORD' => 1,
			'IDENTIFIER' => 3,
			'DESC_WORD' => 2,
			'LEFT_PAREN' => 4,
			'NOT_WORD' => 6,
			'LIKE_WORD' => 8,
			'FALSE_WORD' => 9,
			'BETWEEN_WORD' => 11,
			'TRUE_WORD' => 12,
			'IN_WORD' => 13
		},
		GOTOS => {
			'expr' => 53,
			'keyword_as_value' => 7,
			'condition' => 14,
			'property' => 15
		}
	},
	{#State 24
		DEFAULT => -41
	},
	{#State 25
		ACTIONS => {
			'WHITESPACE' => 55
		},
		DEFAULT => -23,
		GOTOS => {
			'optional_spaces' => 56,
			'spaces' => 54
		}
	},
	{#State 26
		DEFAULT => -39
	},
	{#State 27
		ACTIONS => {
			'WHITESPACE' => 55
		},
		DEFAULT => -23,
		GOTOS => {
			'optional_spaces' => 57,
			'spaces' => 54
		}
	},
	{#State 28
		DEFAULT => -54
	},
	{#State 29
		ACTIONS => {
			'WORD' => 58,
			'DOUBLEQUOTE_STRING' => 59,
			'MINUS' => 60,
			'BETWEEN_WORD' => 11,
			'REAL' => 64,
			'INTEGER' => 65,
			'ASC_WORD' => 1,
			'IDENTIFIER' => 66,
			'DESC_WORD' => 2,
			'NOT_WORD' => 6,
			'LIKE_WORD' => 8,
			'AND' => 70,
			'FALSE_WORD' => 9,
			'TRUE_WORD' => 12,
			'IN_WORD' => 13,
			'OR' => 71,
			'SINGLEQUOTE_STRING' => 72
		},
		GOTOS => {
			'number' => 61,
			'value' => 68,
			'keyword_as_value' => 67,
			'single_value' => 69,
			'like_value' => 63,
			'subsequent_value_part' => 62
		}
	},
	{#State 30
		DEFAULT => -35
	},
	{#State 31
		DEFAULT => -38
	},
	{#State 32
		DEFAULT => -37
	},
	{#State 33
		DEFAULT => -42
	},
	{#State 34
		DEFAULT => -40
	},
	{#State 35
		DEFAULT => -21
	},
	{#State 36
		DEFAULT => -44
	},
	{#State 37
		ACTIONS => {
			'LEFT_BRACKET' => 73
		},
		GOTOS => {
			'set' => 74
		}
	},
	{#State 38
		DEFAULT => -20
	},
	{#State 39
		DEFAULT => -47
	},
	{#State 40
		ACTIONS => {
			'WORD' => 58,
			'DOUBLEQUOTE_STRING' => 59,
			'MINUS' => 60,
			'BETWEEN_WORD' => 11,
			'REAL' => 64,
			'INTEGER' => 65,
			'ASC_WORD' => 1,
			'IDENTIFIER' => 66,
			'DESC_WORD' => 2,
			'NOT_WORD' => 6,
			'LIKE_WORD' => 8,
			'AND' => 70,
			'FALSE_WORD' => 9,
			'TRUE_WORD' => 12,
			'IN_WORD' => 13,
			'OR' => 71,
			'SINGLEQUOTE_STRING' => 72
		},
		GOTOS => {
			'between_value' => 75,
			'number' => 61,
			'keyword_as_value' => 67,
			'single_value' => 76,
			'subsequent_value_part' => 62
		}
	},
	{#State 41
		DEFAULT => -19
	},
	{#State 42
		ACTIONS => {
			'DOUBLEEQUAL_SIGN' => 24,
			'BETWEEN_WORD' => 78,
			'TILDE' => 81,
			'COLON' => 77,
			'LIKE_WORD' => 80,
			'OPERATORS' => 26,
			'IN_WORD' => 82,
			'EQUAL_SIGN' => 34
		},
		GOTOS => {
			'an_operator' => 79
		}
	},
	{#State 43
		DEFAULT => -10
	},
	{#State 44
		DEFAULT => -6
	},
	{#State 45
		DEFAULT => -4
	},
	{#State 46
		ACTIONS => {
			'AND' => 83
		},
		DEFAULT => -33
	},
	{#State 47
		ACTIONS => {
			'ASC_WORD' => 1,
			'IDENTIFIER' => 3,
			'DESC_WORD' => 2,
			'NOT_WORD' => 6,
			'LIKE_WORD' => 8,
			'FALSE_WORD' => 9,
			'BETWEEN_WORD' => 11,
			'TRUE_WORD' => 12,
			'IN_WORD' => 13
		},
		GOTOS => {
			'keyword_as_value' => 7,
			'property' => 84
		}
	},
	{#State 48
		ACTIONS => {
			'AND' => 85
		},
		DEFAULT => -31
	},
	{#State 49
		ACTIONS => {
			'ASC_WORD' => 86,
			'DESC_WORD' => 87
		},
		DEFAULT => -27
	},
	{#State 50
		DEFAULT => -3
	},
	{#State 51
		DEFAULT => -5
	},
	{#State 52
		ACTIONS => {
			'AND' => 22
		},
		DEFAULT => -8
	},
	{#State 53
		ACTIONS => {
			'AND' => 22,
			'OR' => 23
		},
		DEFAULT => -9
	},
	{#State 54
		DEFAULT => -24
	},
	{#State 55
		DEFAULT => -22
	},
	{#State 56
		ACTIONS => {
			'WORD' => 58,
			'DOUBLEQUOTE_STRING' => 59,
			'MINUS' => 60,
			'BETWEEN_WORD' => 11,
			'REAL' => 64,
			'INTEGER' => 65,
			'ASC_WORD' => 1,
			'IDENTIFIER' => 66,
			'DESC_WORD' => 2,
			'NOT_WORD' => 6,
			'LIKE_WORD' => 8,
			'AND' => 70,
			'FALSE_WORD' => 9,
			'TRUE_WORD' => 12,
			'IN_WORD' => 13,
			'OR' => 71,
			'SINGLEQUOTE_STRING' => 72
		},
		GOTOS => {
			'between_value' => 89,
			'number' => 61,
			'keyword_as_value' => 67,
			'old_syntax_in_value' => 88,
			'single_value' => 90,
			'subsequent_value_part' => 62
		}
	},
	{#State 57
		ACTIONS => {
			'WORD' => 58,
			'DOUBLEQUOTE_STRING' => 59,
			'MINUS' => 60,
			'BETWEEN_WORD' => 11,
			'REAL' => 64,
			'INTEGER' => 65,
			'ASC_WORD' => 1,
			'IDENTIFIER' => 66,
			'DESC_WORD' => 2,
			'NOT_WORD' => 6,
			'LIKE_WORD' => 8,
			'AND' => 70,
			'FALSE_WORD' => 9,
			'TRUE_WORD' => 12,
			'IN_WORD' => 13,
			'OR' => 71,
			'SINGLEQUOTE_STRING' => 72
		},
		GOTOS => {
			'number' => 61,
			'value' => 91,
			'keyword_as_value' => 67,
			'single_value' => 69,
			'subsequent_value_part' => 62
		}
	},
	{#State 58
		DEFAULT => -69
	},
	{#State 59
		DEFAULT => -70
	},
	{#State 60
		ACTIONS => {
			'INTEGER' => 93,
			'REAL' => 92
		}
	},
	{#State 61
		DEFAULT => -68
	},
	{#State 62
		DEFAULT => -77
	},
	{#State 63
		DEFAULT => -12
	},
	{#State 64
		DEFAULT => -81
	},
	{#State 65
		DEFAULT => -80
	},
	{#State 66
		DEFAULT => -67
	},
	{#State 67
		DEFAULT => -72
	},
	{#State 68
		DEFAULT => -46
	},
	{#State 69
		ACTIONS => {
			'WORD' => 58,
			'DOUBLEQUOTE_STRING' => 59,
			'MINUS' => 60,
			'BETWEEN_WORD' => 11,
			'REAL' => 64,
			'INTEGER' => 65,
			'ASC_WORD' => 1,
			'IDENTIFIER' => 66,
			'DESC_WORD' => 2,
			'NOT_WORD' => 6,
			'LIKE_WORD' => 8,
			'WHITESPACE' => 55,
			'FALSE_WORD' => 9,
			'TRUE_WORD' => 12,
			'IN_WORD' => 13,
			'SINGLEQUOTE_STRING' => 72
		},
		DEFAULT => -66,
		GOTOS => {
			'number' => 61,
			'keyword_as_value' => 67,
			'subsequent_values_list' => 96,
			'spaces' => 95,
			'subsequent_value_part' => 94
		}
	},
	{#State 70
		DEFAULT => -78
	},
	{#State 71
		DEFAULT => -79
	},
	{#State 72
		DEFAULT => -71
	},
	{#State 73
		ACTIONS => {
			'WORD' => 58,
			'DOUBLEQUOTE_STRING' => 59,
			'MINUS' => 60,
			'BETWEEN_WORD' => 11,
			'REAL' => 64,
			'INTEGER' => 65,
			'ASC_WORD' => 1,
			'IDENTIFIER' => 66,
			'DESC_WORD' => 2,
			'NOT_WORD' => 6,
			'LIKE_WORD' => 8,
			'AND' => 70,
			'FALSE_WORD' => 9,
			'TRUE_WORD' => 12,
			'IN_WORD' => 13,
			'OR' => 71,
			'SINGLEQUOTE_STRING' => 72
		},
		GOTOS => {
			'set_body' => 97,
			'number' => 61,
			'value' => 98,
			'keyword_as_value' => 67,
			'single_value' => 69,
			'subsequent_value_part' => 62
		}
	},
	{#State 74
		DEFAULT => -13
	},
	{#State 75
		DEFAULT => -16
	},
	{#State 76
		ACTIONS => {
			'MINUS' => 99
		}
	},
	{#State 77
		ACTIONS => {
			'WHITESPACE' => 55
		},
		DEFAULT => -23,
		GOTOS => {
			'optional_spaces' => 100,
			'spaces' => 54
		}
	},
	{#State 78
		DEFAULT => -55
	},
	{#State 79
		DEFAULT => -36
	},
	{#State 80
		DEFAULT => -43
	},
	{#State 81
		DEFAULT => -45
	},
	{#State 82
		DEFAULT => -48
	},
	{#State 83
		ACTIONS => {
			'ASC_WORD' => 1,
			'IDENTIFIER' => 3,
			'DESC_WORD' => 2,
			'NOT_WORD' => 6,
			'LIKE_WORD' => 8,
			'FALSE_WORD' => 9,
			'BETWEEN_WORD' => 11,
			'TRUE_WORD' => 12,
			'IN_WORD' => 13
		},
		GOTOS => {
			'keyword_as_value' => 7,
			'group_by_list' => 101,
			'property' => 46
		}
	},
	{#State 84
		DEFAULT => -28
	},
	{#State 85
		ACTIONS => {
			'ASC_WORD' => 1,
			'IDENTIFIER' => 3,
			'DESC_WORD' => 2,
			'NOT_WORD' => 6,
			'MINUS' => 47,
			'LIKE_WORD' => 8,
			'FALSE_WORD' => 9,
			'BETWEEN_WORD' => 11,
			'TRUE_WORD' => 12,
			'IN_WORD' => 13
		},
		GOTOS => {
			'order_by_list' => 102,
			'order_by_property' => 48,
			'keyword_as_value' => 7,
			'property' => 49
		}
	},
	{#State 86
		DEFAULT => -30
	},
	{#State 87
		DEFAULT => -29
	},
	{#State 88
		DEFAULT => -14
	},
	{#State 89
		DEFAULT => -17
	},
	{#State 90
		ACTIONS => {
			'IN_DIVIDER' => 103,
			'MINUS' => 99
		}
	},
	{#State 91
		DEFAULT => -11
	},
	{#State 92
		DEFAULT => -83
	},
	{#State 93
		DEFAULT => -82
	},
	{#State 94
		ACTIONS => {
			'WORD' => 58,
			'DOUBLEQUOTE_STRING' => 59,
			'MINUS' => 60,
			'BETWEEN_WORD' => 11,
			'REAL' => 64,
			'INTEGER' => 65,
			'ASC_WORD' => 1,
			'IDENTIFIER' => 66,
			'DESC_WORD' => 2,
			'NOT_WORD' => 6,
			'LIKE_WORD' => 8,
			'WHITESPACE' => 55,
			'FALSE_WORD' => 9,
			'TRUE_WORD' => 12,
			'IN_WORD' => 13,
			'SINGLEQUOTE_STRING' => 72
		},
		DEFAULT => -73,
		GOTOS => {
			'number' => 61,
			'keyword_as_value' => 67,
			'subsequent_values_list' => 104,
			'spaces' => 95,
			'subsequent_value_part' => 94
		}
	},
	{#State 95
		ACTIONS => {
			'WORD' => 58,
			'DOUBLEQUOTE_STRING' => 59,
			'MINUS' => 60,
			'BETWEEN_WORD' => 11,
			'REAL' => 64,
			'INTEGER' => 65,
			'ASC_WORD' => 1,
			'IDENTIFIER' => 66,
			'DESC_WORD' => 2,
			'NOT_WORD' => 6,
			'LIKE_WORD' => 8,
			'WHITESPACE' => 55,
			'FALSE_WORD' => 9,
			'TRUE_WORD' => 12,
			'IN_WORD' => 13,
			'SINGLEQUOTE_STRING' => 72
		},
		DEFAULT => -76,
		GOTOS => {
			'number' => 61,
			'keyword_as_value' => 67,
			'subsequent_values_list' => 105,
			'spaces' => 95,
			'subsequent_value_part' => 94
		}
	},
	{#State 96
		DEFAULT => -65
	},
	{#State 97
		ACTIONS => {
			'RIGHT_BRACKET' => 106
		}
	},
	{#State 98
		ACTIONS => {
			'SET_SEPARATOR' => 107
		},
		DEFAULT => -53
	},
	{#State 99
		ACTIONS => {
			'WORD' => 58,
			'DOUBLEQUOTE_STRING' => 59,
			'MINUS' => 60,
			'BETWEEN_WORD' => 11,
			'REAL' => 64,
			'INTEGER' => 65,
			'ASC_WORD' => 1,
			'IDENTIFIER' => 66,
			'DESC_WORD' => 2,
			'NOT_WORD' => 6,
			'LIKE_WORD' => 8,
			'AND' => 70,
			'FALSE_WORD' => 9,
			'TRUE_WORD' => 12,
			'IN_WORD' => 13,
			'OR' => 71,
			'SINGLEQUOTE_STRING' => 72
		},
		GOTOS => {
			'number' => 61,
			'keyword_as_value' => 67,
			'single_value' => 108,
			'subsequent_value_part' => 62
		}
	},
	{#State 100
		ACTIONS => {
			'WORD' => 58,
			'DOUBLEQUOTE_STRING' => 59,
			'MINUS' => 60,
			'BETWEEN_WORD' => 11,
			'REAL' => 64,
			'INTEGER' => 65,
			'ASC_WORD' => 1,
			'IDENTIFIER' => 66,
			'DESC_WORD' => 2,
			'NOT_WORD' => 6,
			'LIKE_WORD' => 8,
			'AND' => 70,
			'FALSE_WORD' => 9,
			'TRUE_WORD' => 12,
			'IN_WORD' => 13,
			'OR' => 71,
			'SINGLEQUOTE_STRING' => 72
		},
		GOTOS => {
			'between_value' => 110,
			'number' => 61,
			'keyword_as_value' => 67,
			'old_syntax_in_value' => 109,
			'single_value' => 90,
			'subsequent_value_part' => 62
		}
	},
	{#State 101
		DEFAULT => -34
	},
	{#State 102
		DEFAULT => -32
	},
	{#State 103
		ACTIONS => {
			'WORD' => 58,
			'DOUBLEQUOTE_STRING' => 59,
			'MINUS' => 60,
			'BETWEEN_WORD' => 11,
			'REAL' => 64,
			'INTEGER' => 65,
			'ASC_WORD' => 1,
			'IDENTIFIER' => 66,
			'DESC_WORD' => 2,
			'NOT_WORD' => 6,
			'LIKE_WORD' => 8,
			'AND' => 70,
			'FALSE_WORD' => 9,
			'TRUE_WORD' => 12,
			'IN_WORD' => 13,
			'OR' => 71,
			'SINGLEQUOTE_STRING' => 72
		},
		GOTOS => {
			'number' => 61,
			'keyword_as_value' => 67,
			'old_syntax_in_value' => 111,
			'single_value' => 112,
			'subsequent_value_part' => 62
		}
	},
	{#State 104
		DEFAULT => -74
	},
	{#State 105
		DEFAULT => -75
	},
	{#State 106
		DEFAULT => -51
	},
	{#State 107
		ACTIONS => {
			'WORD' => 58,
			'DOUBLEQUOTE_STRING' => 59,
			'MINUS' => 60,
			'BETWEEN_WORD' => 11,
			'REAL' => 64,
			'INTEGER' => 65,
			'ASC_WORD' => 1,
			'IDENTIFIER' => 66,
			'DESC_WORD' => 2,
			'NOT_WORD' => 6,
			'LIKE_WORD' => 8,
			'AND' => 70,
			'FALSE_WORD' => 9,
			'TRUE_WORD' => 12,
			'IN_WORD' => 13,
			'OR' => 71,
			'SINGLEQUOTE_STRING' => 72
		},
		GOTOS => {
			'set_body' => 113,
			'number' => 61,
			'value' => 98,
			'keyword_as_value' => 67,
			'single_value' => 69,
			'subsequent_value_part' => 62
		}
	},
	{#State 108
		DEFAULT => -56
	},
	{#State 109
		DEFAULT => -15
	},
	{#State 110
		DEFAULT => -18
	},
	{#State 111
		DEFAULT => -49
	},
	{#State 112
		ACTIONS => {
			'IN_DIVIDER' => 103
		},
		DEFAULT => -50
	},
	{#State 113
		DEFAULT => -52
	}
],
                                  yyrules  =>
[
	[#Rule 0
		 '$start', 2, undef
	],
	[#Rule 1
		 'boolexpr', 0,
sub
#line 10 "BxParser.yp"
{ [] }
	],
	[#Rule 2
		 'boolexpr', 1,
sub
#line 11 "BxParser.yp"
{ UR::BoolExpr::BxParser->_simplify($_[1]) }
	],
	[#Rule 3
		 'boolexpr', 3,
sub
#line 12 "BxParser.yp"
{ [@{$_[1]}, '-order', $_[3]] }
	],
	[#Rule 4
		 'boolexpr', 3,
sub
#line 13 "BxParser.yp"
{ [@{$_[1]}, '-group', $_[3]] }
	],
	[#Rule 5
		 'boolexpr', 3,
sub
#line 14 "BxParser.yp"
{ [@{$_[1]}, '-limit', $_[3]] }
	],
	[#Rule 6
		 'boolexpr', 3,
sub
#line 15 "BxParser.yp"
{ [@{$_[1]}, '-offset', $_[3]] }
	],
	[#Rule 7
		 'expr', 1,
sub
#line 18 "BxParser.yp"
{ $_[1] }
	],
	[#Rule 8
		 'expr', 3,
sub
#line 19 "BxParser.yp"
{ UR::BoolExpr::BxParser->_and($_[1], $_[3]) }
	],
	[#Rule 9
		 'expr', 3,
sub
#line 20 "BxParser.yp"
{ UR::BoolExpr::BxParser->_or($_[1], $_[3]) }
	],
	[#Rule 10
		 'expr', 3,
sub
#line 21 "BxParser.yp"
{ $_[2] }
	],
	[#Rule 11
		 'condition', 4,
sub
#line 24 "BxParser.yp"
{ [ "$_[1] $_[2]" => $_[4] ] }
	],
	[#Rule 12
		 'condition', 3,
sub
#line 25 "BxParser.yp"
{ [ "$_[1] $_[2]" => $_[3] ] }
	],
	[#Rule 13
		 'condition', 3,
sub
#line 26 "BxParser.yp"
{ [ "$_[1] $_[2]" => $_[3] ] }
	],
	[#Rule 14
		 'condition', 4,
sub
#line 27 "BxParser.yp"
{ [ "$_[1] in" => $_[4] ] }
	],
	[#Rule 15
		 'condition', 5,
sub
#line 28 "BxParser.yp"
{ [ "$_[1] $_[2] in" => $_[5] ] }
	],
	[#Rule 16
		 'condition', 3,
sub
#line 29 "BxParser.yp"
{ [ "$_[1] $_[2]" => $_[3] ] }
	],
	[#Rule 17
		 'condition', 4,
sub
#line 30 "BxParser.yp"
{ [ "$_[1] between" => $_[4] ] }
	],
	[#Rule 18
		 'condition', 5,
sub
#line 31 "BxParser.yp"
{ [ "$_[1] $_[2] between" => $_[5] ] }
	],
	[#Rule 19
		 'condition', 2,
sub
#line 32 "BxParser.yp"
{ [ "$_[1] $_[2]" => 1 ] }
	],
	[#Rule 20
		 'boolean_op_word', 1,
sub
#line 35 "BxParser.yp"
{ $_[1] }
	],
	[#Rule 21
		 'boolean_op_word', 1,
sub
#line 36 "BxParser.yp"
{ $_[1] }
	],
	[#Rule 22
		 'spaces', 1,
sub
#line 39 "BxParser.yp"
{ $_[1] }
	],
	[#Rule 23
		 'optional_spaces', 0,
sub
#line 42 "BxParser.yp"
{ undef }
	],
	[#Rule 24
		 'optional_spaces', 1,
sub
#line 43 "BxParser.yp"
{ undef }
	],
	[#Rule 25
		 'property', 1,
sub
#line 46 "BxParser.yp"
{ $_[1] }
	],
	[#Rule 26
		 'property', 1,
sub
#line 47 "BxParser.yp"
{ $_[1] }
	],
	[#Rule 27
		 'order_by_property', 1,
sub
#line 50 "BxParser.yp"
{ $_[1 ] }
	],
	[#Rule 28
		 'order_by_property', 2,
sub
#line 51 "BxParser.yp"
{ '-'.$_[2] }
	],
	[#Rule 29
		 'order_by_property', 2,
sub
#line 52 "BxParser.yp"
{ '-'.$_[1] }
	],
	[#Rule 30
		 'order_by_property', 2,
sub
#line 53 "BxParser.yp"
{ $_[1] }
	],
	[#Rule 31
		 'order_by_list', 1,
sub
#line 56 "BxParser.yp"
{ [ $_[1]] }
	],
	[#Rule 32
		 'order_by_list', 3,
sub
#line 57 "BxParser.yp"
{ [$_[1], @{$_[3]}] }
	],
	[#Rule 33
		 'group_by_list', 1,
sub
#line 60 "BxParser.yp"
{ [ $_[1] ] }
	],
	[#Rule 34
		 'group_by_list', 3,
sub
#line 61 "BxParser.yp"
{ [$_[1], @{$_[3]}] }
	],
	[#Rule 35
		 'operator', 1,
sub
#line 64 "BxParser.yp"
{ $_[1] }
	],
	[#Rule 36
		 'operator', 2,
sub
#line 65 "BxParser.yp"
{ "$_[1] $_[2]" }
	],
	[#Rule 37
		 'negation', 1,
sub
#line 68 "BxParser.yp"
{ 'not' }
	],
	[#Rule 38
		 'negation', 1,
sub
#line 69 "BxParser.yp"
{ 'not' }
	],
	[#Rule 39
		 'an_operator', 1,
sub
#line 72 "BxParser.yp"
{ $_[1] }
	],
	[#Rule 40
		 'an_operator', 1,
sub
#line 73 "BxParser.yp"
{ '=' }
	],
	[#Rule 41
		 'an_operator', 1,
sub
#line 74 "BxParser.yp"
{ '=' }
	],
	[#Rule 42
		 'like_operator', 1,
sub
#line 77 "BxParser.yp"
{ 'like' }
	],
	[#Rule 43
		 'like_operator', 2,
sub
#line 78 "BxParser.yp"
{ "$_[1] like" }
	],
	[#Rule 44
		 'like_operator', 1,
sub
#line 79 "BxParser.yp"
{ 'like' }
	],
	[#Rule 45
		 'like_operator', 2,
sub
#line 80 "BxParser.yp"
{ "$_[1] like" }
	],
	[#Rule 46
		 'like_value', 1,
sub
#line 83 "BxParser.yp"
{  $_[1] =~ m/\%/ ? $_[1] : '%' . $_[1] . '%' }
	],
	[#Rule 47
		 'in_operator', 1,
sub
#line 86 "BxParser.yp"
{ 'in' }
	],
	[#Rule 48
		 'in_operator', 2,
sub
#line 87 "BxParser.yp"
{ "$_[1] in" }
	],
	[#Rule 49
		 'old_syntax_in_value', 3,
sub
#line 90 "BxParser.yp"
{ [ $_[1], @{$_[3]} ] }
	],
	[#Rule 50
		 'old_syntax_in_value', 3,
sub
#line 91 "BxParser.yp"
{ [ $_[1], $_[3] ] }
	],
	[#Rule 51
		 'set', 3,
sub
#line 94 "BxParser.yp"
{ $_[2] }
	],
	[#Rule 52
		 'set_body', 3,
sub
#line 97 "BxParser.yp"
{ [ $_[1], @{$_[3]} ] }
	],
	[#Rule 53
		 'set_body', 1,
sub
#line 98 "BxParser.yp"
{ [ $_[1] ] }
	],
	[#Rule 54
		 'between_operator', 1,
sub
#line 101 "BxParser.yp"
{ 'between' }
	],
	[#Rule 55
		 'between_operator', 2,
sub
#line 102 "BxParser.yp"
{ "$_[1] between" }
	],
	[#Rule 56
		 'between_value', 3,
sub
#line 105 "BxParser.yp"
{ [ $_[1], $_[3] ] }
	],
	[#Rule 57
		 'keyword_as_value', 1,
sub
#line 108 "BxParser.yp"
{ $_[1] }
	],
	[#Rule 58
		 'keyword_as_value', 1,
sub
#line 109 "BxParser.yp"
{ $_[1] }
	],
	[#Rule 59
		 'keyword_as_value', 1,
sub
#line 110 "BxParser.yp"
{ $_[1] }
	],
	[#Rule 60
		 'keyword_as_value', 1,
sub
#line 111 "BxParser.yp"
{ $_[1] }
	],
	[#Rule 61
		 'keyword_as_value', 1,
sub
#line 112 "BxParser.yp"
{ $_[1] }
	],
	[#Rule 62
		 'keyword_as_value', 1,
sub
#line 113 "BxParser.yp"
{ $_[1] }
	],
	[#Rule 63
		 'keyword_as_value', 1,
sub
#line 114 "BxParser.yp"
{ $_[1] }
	],
	[#Rule 64
		 'keyword_as_value', 1,
sub
#line 115 "BxParser.yp"
{ $_[1] }
	],
	[#Rule 65
		 'value', 2,
sub
#line 118 "BxParser.yp"
{ $_[1].$_[2] }
	],
	[#Rule 66
		 'value', 1,
sub
#line 119 "BxParser.yp"
{ $_[1] }
	],
	[#Rule 67
		 'subsequent_value_part', 1,
sub
#line 122 "BxParser.yp"
{ $_[1] }
	],
	[#Rule 68
		 'subsequent_value_part', 1,
sub
#line 123 "BxParser.yp"
{ $_[1] }
	],
	[#Rule 69
		 'subsequent_value_part', 1,
sub
#line 124 "BxParser.yp"
{ $_[1] }
	],
	[#Rule 70
		 'subsequent_value_part', 1,
sub
#line 125 "BxParser.yp"
{ ($_[1] =~ m/^"(.*?)"$/)[0]; }
	],
	[#Rule 71
		 'subsequent_value_part', 1,
sub
#line 126 "BxParser.yp"
{ ($_[1] =~ m/^'(.*?)'$/)[0]; }
	],
	[#Rule 72
		 'subsequent_value_part', 1,
sub
#line 127 "BxParser.yp"
{ $_[1] }
	],
	[#Rule 73
		 'subsequent_values_list', 1,
sub
#line 130 "BxParser.yp"
{ $_[1] }
	],
	[#Rule 74
		 'subsequent_values_list', 2,
sub
#line 131 "BxParser.yp"
{ $_[1].$_[2] }
	],
	[#Rule 75
		 'subsequent_values_list', 2,
sub
#line 132 "BxParser.yp"
{ $_[1].$_[2] }
	],
	[#Rule 76
		 'subsequent_values_list', 1,
sub
#line 133 "BxParser.yp"
{ '' }
	],
	[#Rule 77
		 'single_value', 1,
sub
#line 136 "BxParser.yp"
{ $_[1] }
	],
	[#Rule 78
		 'single_value', 1,
sub
#line 137 "BxParser.yp"
{ $_[1] }
	],
	[#Rule 79
		 'single_value', 1,
sub
#line 138 "BxParser.yp"
{ $_[1] }
	],
	[#Rule 80
		 'number', 1,
sub
#line 142 "BxParser.yp"
{ $_[1] + 0 }
	],
	[#Rule 81
		 'number', 1,
sub
#line 143 "BxParser.yp"
{ $_[1] + 0 }
	],
	[#Rule 82
		 'number', 2,
sub
#line 144 "BxParser.yp"
{ 0 - $_[2] }
	],
	[#Rule 83
		 'number', 2,
sub
#line 145 "BxParser.yp"
{ 0 - $_[2] }
	]
],
                                  @_);
    bless($self,$class);
}

#line 148 "BxParser.yp"


package UR::BoolExpr::BxParser;
use strict;
use warnings;

sub _error {
    my @expect = $_[0]->YYExpect;
    my $tok = $_[0]->YYData->{INPUT};
    my $match = $_[0]->YYData->{MATCH};
    my $string = $_[0]->YYData->{STRING};
    my $err = qq(Can't parse expression "$string"\n  Syntax error near token $tok '$match');
    my $rem = $_[0]->YYData->{REMAINING};
    $err .= ", remaining text: '$rem'" if $rem;
    $err .= "\nExpected one of: " . join(", ", @expect) . "\n";
    Carp::croak($err);
}

my %token_states = (
    'DEFAULT' => [
        WHITESPACE => qr{\s+},
        AND => [ qr{and}, 'DEFAULT'],
        OR => [ qr{or}, 'DEFAULT' ],
        BETWEEN_WORD => qr{between},
        LIKE_WORD => qr{like},
        IN_WORD => qr{in},
        NOT_WORD => qr{not},
        DESC_WORD => qr{desc},
        ASC_WORD => qr{asc},
        TRUE_WORD => qr{true},
        FALSE_WORD => qr{false},
        LIMIT => qr{limit},
        OFFSET => qr{offset},
        IDENTIFIER => qr{[a-zA-Z_][a-zA-Z0-9_.]*},
        MINUS => qr{-},
        INTEGER => qr{\d+},
        REAL => qr{\d*\.\d+|\d+\.\d*},
        WORD => qr{[%\.\/\w][-\.%\w\/]*},   # also allow / for pathnames, - for hyphenated names, % for like wildcards
        DOUBLEQUOTE_STRING => qr{"(?:\\.|[^"])*"},
        SINGLEQUOTE_STRING => qr{'(?:\\.|[^'])*'},
        LEFT_PAREN => [ qr{\(}, 'DEFAULT' ],
        RIGHT_PAREN => [ qr{\)}, 'DEFAULT' ],
        LEFT_BRACKET => [ qr{\[}, 'set_contents'],
        RIGHT_BRACKET => [qr{\]}, 'DEFAULT' ],
        NOT_BANG => qr{!},
        EQUAL_SIGN => [ qr{=}, 'dont_gobble_spaces' ],
        DOUBLEEQUAL_SIGN => [ qr{=>}, 'dont_gobble_spaces' ],
        OPERATORS => [ qr{<|>|<=|>=}, 'dont_gobble_spaces' ],
        AND => [ qr{,}, 'DEFAULT' ],
        COLON => [ qr{:}, 'after_colon_value' ],
        TILDE => qr{~},
        ORDER_BY => qr{order by},
        GROUP_BY => qr{group by},
    ],
    'set_contents' => [
        SET_SEPARATOR => qr{,},  # Depending on state, can be either AND or SET_SEPARATOR
        WORD => qr{[%\.\w\:][\.\:%\w]*},   # also allow / for pathnames, - for hyphenated names, % for like wildcards
        RIGHT_BRACKET => [qr{\]}, 'DEFAULT' ],
    ],
    'after_colon_value' => [
        INTEGER => qr{\d+},
        REAL => qr{\d*\.\d+|\d+\.\d*},
        IN_DIVIDER => qr{\/},
        #WORD => qr{\w+},    # Override WORD in DEFAULT to disallow /
        WORD => qr{[%\.\w\:][\.\:%\w]*},   # Override WORD in DEFAULT to disallow /
        DOUBLEQUOTE_STRING => qr{"(?:\\.|[^"])*"},
        SINGLEQUOTE_STRING => qr{'(?:\\.|[^'])*'},
        WHITESPACE => [qr{\s+}, 'DEFAULT'],
    ],
    'dont_gobble_spaces' => [
        AND => [ qr{and}, 'DEFAULT'],
        OR => [ qr{or}, 'DEFAULT' ],
        LIMIT => [qr{limit}, 'DEFAULT'],
        OFFSET => [qr{offset}, 'DEFAULT'],
        INTEGER => qr{\d+},
        REAL => qr{\d*\.\d+|\d+\.\d*},
        WORD => qr{[%\.\/\w][\-\.\:%\w\/]*},   # also allow / for pathnames, - for hyphenated names, % for like wildcards
        ORDER_BY => [qr{order by}, 'DEFAULT'],
        GROUP_BY => [qr{group by}, 'DEFAULT'],
    ],
);

sub parse {
    my $string = shift;
    my %params = @_;

    my $debug = $params{'tokdebug'};
    my $yydebug = $params{'yydebug'} || 0;

    print "\nStarting parse for string $string\n" if $debug;
    my $parser = UR::BoolExpr::BxParser->new();
    $parser->YYData->{STRING} = $string;

    my $parser_state = 'DEFAULT';

    my $get_next_token = sub {
        if (length($string) == 0) {
            print "String is empty, we're done!\n" if $debug;
            return (undef, '');  
       }

        GET_NEXT_TOKEN:
        foreach (1) {
            my $longest = 0;
            my $longest_token = '';
            my $longest_match = '';

            for my $token_list ( $parser_state, 'DEFAULT' ) {
                print "\nTrying tokens for state $token_list...\n" if $debug;
                my $tokens = $token_states{$token_list};
                for(my $i = 0; $i < @$tokens; $i += 2) {
                    my($tok, $re) = @$tokens[$i, $i+1];
                    print "Trying token $tok... " if $debug;

                    my($regex,$next_parser_state);
                    if (ref($re) eq 'ARRAY') {
                        ($regex,$next_parser_state) = @$re;
                    } else {
                        $regex = $re;
                    }

                    if ($string =~ m/^($regex)/) {
                        print "Matched >>$1<<" if $debug;
                        my $match_len = length($1);
                        if ($match_len > $longest) {
                            print "\n  ** It's now the longest" if $debug;
                            $longest = $match_len;
                            $longest_token = $tok;
                            $longest_match = $1;
                            if ($next_parser_state) {
                                $parser_state = $next_parser_state;
                            }
                        }
                    }
                    print "\n" if $debug;
                }

                $string = substr($string, $longest);
                print "Consuming up to char pos $longest chars, string is now >>$string<<\n" if $debug;

                if ($longest_token eq 'WHITESPACE' and $parser_state ne 'dont_gobble_spaces') {
                    print "Redoing token extraction after whitespace\n" if $debug;
                    redo GET_NEXT_TOKEN;
                }

                $parser->YYData->{REMAINING} = $string;
                if ($longest) {
                    print "Returning token $longest_token, match $longest_match\n  next state is named $parser_state\n" if $debug;
                    $parser->YYData->{INPUT} = $longest_token;
                    $parser->YYData->{MATCH} = $longest_match;
                    return ($longest_token, $longest_match);
                }
                last if $token_list eq 'DEFAULT';  # avoid going over it twice if $parser_state is DEFAULT
            }
        }
        print "Didn't match anything, done!\n" if $debug;
        return (undef, '');  # Didn't match anything
    };

    return $parser->YYParse(
               yylex => $get_next_token,
               yyerror => \&_error,
               yydebug => $yydebug,
           );
}

# Used by the top-level expr production to turn an or-type parse tree with
# only a single AND condition into a simple AND-type tree (1-level arrayref).
# Or to add the '-or' to the front of a real OR-type tree so it can be passed
# directly to UR::BoolExpr::resolve()
sub _simplify {
    my($class, $expr) = @_;

    if (ref($expr->[0])) {
        if (@$expr == 1) {
            # An or-type parse tree, but with only one AND subrule - use as a simple and-type rule
            $expr = $expr->[0];
        } else {
            $expr = ['-or', $expr]; # an or-type parse tree with multiple subrules
        }
    }
    return $expr;
}

# Handles the case for "expr AND expr" where one or both exprs can be an
# OR-type expr.  In that case, it distributes the AND exprs among all the
# OR conditions.  For example:
# (a=1 or b=2) and (c=3 or d=4)
# is the same as
# (a=1 and c=3) or (a=1 and d=4) or (b=2 and c=3) or (b=2 and d=4)
# This is necessary because the BoolExpr resolver can only handle 1-level deep
# AND-type rules, or a 1-level deep OR-type rule composed of any number of
# 1-level deep AND-type rules
sub _and {
    my($class,$left, $right) = @_;

    # force them to be [[ "property operator" => value]] instead of just [ "property operator" => value ]
    $left  = [ $left ]  unless (ref($left->[0]));
    $right = [ $right ] unless (ref($right->[0]));

    my @and;
    foreach my $left_subexpr ( @$left ) {
        foreach my $right_subexpr (@$right) {
            push @and, [@$left_subexpr, @$right_subexpr];
        }
    }
    \@and;
}

sub _or {
    my($class,$left, $right) = @_;

    # force them to be [[ "property operator" => value]] instead of just [ "property operator" => value ]
    $left  = [ $left ]  unless (ref($left->[0]));
    $right = [ $right ] unless (ref($right->[0]));

    [ @$left, @$right ];
}

1;


1;
