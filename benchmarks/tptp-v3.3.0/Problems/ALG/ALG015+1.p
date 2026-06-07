%--------------------------------------------------------------------------
% File     : ALG015+1 : TPTP v3.3.0. Released v2.7.0.
% Domain   : General Algebra
% Problem  : Groups 4: CPROPS-ISO-COMPLETE-PROBLEM-1
% Version  : Especial.
% English  : 

% Refs     : [Mei03] Meier (2003), Email to G.Sutcliffe
%          : [CM+04] Colton et al. (2004), Automatic Generation of Classifi
% Source   : [Mei03]
% Names    : 

% Status   : Theorem
% Rating   : 0.33 v3.3.0, 0.11 v3.2.0, 0.22 v3.1.0, 0.25 v2.7.0
% Syntax   : Number of formulae    :   38 (   2 unit)
%            Number of atoms       : 1006 (1006 equality)
%            Maximal formula depth :   64 (  13 average)
%            Number of connectives : 1104 ( 136 ~  ; 287  |; 649  &)
%                                         (   0 <=>;  32 =>;   0 <=)
%                                         (   0 <~>;   0 ~|;   0 ~&)
%            Number of predicates  :    1 (   0 propositional; 2-2 arity)
%            Number of functors    :   26 (  10 constant; 0-2 arity)
%            Number of variables   :    0 (   0 singleton;   0 !;   0 ?)
%            Maximal term depth    :    3 (   2 average)

% Comments : 
%--------------------------------------------------------------------------
fof(ax1,axiom,
    ( ( op1(e10,e10) = e10
      | op1(e10,e10) = e11
      | op1(e10,e10) = e12
      | op1(e10,e10) = e13 )
    & ( op1(e10,e11) = e10
      | op1(e10,e11) = e11
      | op1(e10,e11) = e12
      | op1(e10,e11) = e13 )
    & ( op1(e10,e12) = e10
      | op1(e10,e12) = e11
      | op1(e10,e12) = e12
      | op1(e10,e12) = e13 )
    & ( op1(e10,e13) = e10
      | op1(e10,e13) = e11
      | op1(e10,e13) = e12
      | op1(e10,e13) = e13 )
    & ( op1(e11,e10) = e10
      | op1(e11,e10) = e11
      | op1(e11,e10) = e12
      | op1(e11,e10) = e13 )
    & ( op1(e11,e11) = e10
      | op1(e11,e11) = e11
      | op1(e11,e11) = e12
      | op1(e11,e11) = e13 )
    & ( op1(e11,e12) = e10
      | op1(e11,e12) = e11
      | op1(e11,e12) = e12
      | op1(e11,e12) = e13 )
    & ( op1(e11,e13) = e10
      | op1(e11,e13) = e11
      | op1(e11,e13) = e12
      | op1(e11,e13) = e13 )
    & ( op1(e12,e10) = e10
      | op1(e12,e10) = e11
      | op1(e12,e10) = e12
      | op1(e12,e10) = e13 )
    & ( op1(e12,e11) = e10
      | op1(e12,e11) = e11
      | op1(e12,e11) = e12
      | op1(e12,e11) = e13 )
    & ( op1(e12,e12) = e10
      | op1(e12,e12) = e11
      | op1(e12,e12) = e12
      | op1(e12,e12) = e13 )
    & ( op1(e12,e13) = e10
      | op1(e12,e13) = e11
      | op1(e12,e13) = e12
      | op1(e12,e13) = e13 )
    & ( op1(e13,e10) = e10
      | op1(e13,e10) = e11
      | op1(e13,e10) = e12
      | op1(e13,e10) = e13 )
    & ( op1(e13,e11) = e10
      | op1(e13,e11) = e11
      | op1(e13,e11) = e12
      | op1(e13,e11) = e13 )
    & ( op1(e13,e12) = e10
      | op1(e13,e12) = e11
      | op1(e13,e12) = e12
      | op1(e13,e12) = e13 )
    & ( op1(e13,e13) = e10
      | op1(e13,e13) = e11
      | op1(e13,e13) = e12
      | op1(e13,e13) = e13 ) )).

fof(ax2,axiom,
    ( op1(op1(e10,e10),e10) = op1(e10,op1(e10,e10))
    & op1(op1(e10,e10),e11) = op1(e10,op1(e10,e11))
    & op1(op1(e10,e10),e12) = op1(e10,op1(e10,e12))
    & op1(op1(e10,e10),e13) = op1(e10,op1(e10,e13))
    & op1(op1(e10,e11),e10) = op1(e10,op1(e11,e10))
    & op1(op1(e10,e11),e11) = op1(e10,op1(e11,e11))
    & op1(op1(e10,e11),e12) = op1(e10,op1(e11,e12))
    & op1(op1(e10,e11),e13) = op1(e10,op1(e11,e13))
    & op1(op1(e10,e12),e10) = op1(e10,op1(e12,e10))
    & op1(op1(e10,e12),e11) = op1(e10,op1(e12,e11))
    & op1(op1(e10,e12),e12) = op1(e10,op1(e12,e12))
    & op1(op1(e10,e12),e13) = op1(e10,op1(e12,e13))
    & op1(op1(e10,e13),e10) = op1(e10,op1(e13,e10))
    & op1(op1(e10,e13),e11) = op1(e10,op1(e13,e11))
    & op1(op1(e10,e13),e12) = op1(e10,op1(e13,e12))
    & op1(op1(e10,e13),e13) = op1(e10,op1(e13,e13))
    & op1(op1(e11,e10),e10) = op1(e11,op1(e10,e10))
    & op1(op1(e11,e10),e11) = op1(e11,op1(e10,e11))
    & op1(op1(e11,e10),e12) = op1(e11,op1(e10,e12))
    & op1(op1(e11,e10),e13) = op1(e11,op1(e10,e13))
    & op1(op1(e11,e11),e10) = op1(e11,op1(e11,e10))
    & op1(op1(e11,e11),e11) = op1(e11,op1(e11,e11))
    & op1(op1(e11,e11),e12) = op1(e11,op1(e11,e12))
    & op1(op1(e11,e11),e13) = op1(e11,op1(e11,e13))
    & op1(op1(e11,e12),e10) = op1(e11,op1(e12,e10))
    & op1(op1(e11,e12),e11) = op1(e11,op1(e12,e11))
    & op1(op1(e11,e12),e12) = op1(e11,op1(e12,e12))
    & op1(op1(e11,e12),e13) = op1(e11,op1(e12,e13))
    & op1(op1(e11,e13),e10) = op1(e11,op1(e13,e10))
    & op1(op1(e11,e13),e11) = op1(e11,op1(e13,e11))
    & op1(op1(e11,e13),e12) = op1(e11,op1(e13,e12))
    & op1(op1(e11,e13),e13) = op1(e11,op1(e13,e13))
    & op1(op1(e12,e10),e10) = op1(e12,op1(e10,e10))
    & op1(op1(e12,e10),e11) = op1(e12,op1(e10,e11))
    & op1(op1(e12,e10),e12) = op1(e12,op1(e10,e12))
    & op1(op1(e12,e10),e13) = op1(e12,op1(e10,e13))
    & op1(op1(e12,e11),e10) = op1(e12,op1(e11,e10))
    & op1(op1(e12,e11),e11) = op1(e12,op1(e11,e11))
    & op1(op1(e12,e11),e12) = op1(e12,op1(e11,e12))
    & op1(op1(e12,e11),e13) = op1(e12,op1(e11,e13))
    & op1(op1(e12,e12),e10) = op1(e12,op1(e12,e10))
    & op1(op1(e12,e12),e11) = op1(e12,op1(e12,e11))
    & op1(op1(e12,e12),e12) = op1(e12,op1(e12,e12))
    & op1(op1(e12,e12),e13) = op1(e12,op1(e12,e13))
    & op1(op1(e12,e13),e10) = op1(e12,op1(e13,e10))
    & op1(op1(e12,e13),e11) = op1(e12,op1(e13,e11))
    & op1(op1(e12,e13),e12) = op1(e12,op1(e13,e12))
    & op1(op1(e12,e13),e13) = op1(e12,op1(e13,e13))
    & op1(op1(e13,e10),e10) = op1(e13,op1(e10,e10))
    & op1(op1(e13,e10),e11) = op1(e13,op1(e10,e11))
    & op1(op1(e13,e10),e12) = op1(e13,op1(e10,e12))
    & op1(op1(e13,e10),e13) = op1(e13,op1(e10,e13))
    & op1(op1(e13,e11),e10) = op1(e13,op1(e11,e10))
    & op1(op1(e13,e11),e11) = op1(e13,op1(e11,e11))
    & op1(op1(e13,e11),e12) = op1(e13,op1(e11,e12))
    & op1(op1(e13,e11),e13) = op1(e13,op1(e11,e13))
    & op1(op1(e13,e12),e10) = op1(e13,op1(e12,e10))
    & op1(op1(e13,e12),e11) = op1(e13,op1(e12,e11))
    & op1(op1(e13,e12),e12) = op1(e13,op1(e12,e12))
    & op1(op1(e13,e12),e13) = op1(e13,op1(e12,e13))
    & op1(op1(e13,e13),e10) = op1(e13,op1(e13,e10))
    & op1(op1(e13,e13),e11) = op1(e13,op1(e13,e11))
    & op1(op1(e13,e13),e12) = op1(e13,op1(e13,e12))
    & op1(op1(e13,e13),e13) = op1(e13,op1(e13,e13)) )).

fof(ax3,axiom,
    ( op1(unit1,e10) = e10
    & op1(e10,unit1) = e10
    & op1(unit1,e11) = e11
    & op1(e11,unit1) = e11
    & op1(unit1,e12) = e12
    & op1(e12,unit1) = e12
    & op1(unit1,e13) = e13
    & op1(e13,unit1) = e13
    & ( unit1 = e10
      | unit1 = e11
      | unit1 = e12
      | unit1 = e13 ) )).

fof(ax4,axiom,
    ( op1(e10,inv1(e10)) = unit1
    & op1(inv1(e10),e10) = unit1
    & op1(e11,inv1(e11)) = unit1
    & op1(inv1(e11),e11) = unit1
    & op1(e12,inv1(e12)) = unit1
    & op1(inv1(e12),e12) = unit1
    & op1(e13,inv1(e13)) = unit1
    & op1(inv1(e13),e13) = unit1
    & ( inv1(e10) = e10
      | inv1(e10) = e11
      | inv1(e10) = e12
      | inv1(e10) = e13 )
    & ( inv1(e11) = e10
      | inv1(e11) = e11
      | inv1(e11) = e12
      | inv1(e11) = e13 )
    & ( inv1(e12) = e10
      | inv1(e12) = e11
      | inv1(e12) = e12
      | inv1(e12) = e13 )
    & ( inv1(e13) = e10
      | inv1(e13) = e11
      | inv1(e13) = e12
      | inv1(e13) = e13 ) )).

fof(ax5,axiom,
    ( ( op2(e20,e20) = e20
      | op2(e20,e20) = e21
      | op2(e20,e20) = e22
      | op2(e20,e20) = e23 )
    & ( op2(e20,e21) = e20
      | op2(e20,e21) = e21
      | op2(e20,e21) = e22
      | op2(e20,e21) = e23 )
    & ( op2(e20,e22) = e20
      | op2(e20,e22) = e21
      | op2(e20,e22) = e22
      | op2(e20,e22) = e23 )
    & ( op2(e20,e23) = e20
      | op2(e20,e23) = e21
      | op2(e20,e23) = e22
      | op2(e20,e23) = e23 )
    & ( op2(e21,e20) = e20
      | op2(e21,e20) = e21
      | op2(e21,e20) = e22
      | op2(e21,e20) = e23 )
    & ( op2(e21,e21) = e20
      | op2(e21,e21) = e21
      | op2(e21,e21) = e22
      | op2(e21,e21) = e23 )
    & ( op2(e21,e22) = e20
      | op2(e21,e22) = e21
      | op2(e21,e22) = e22
      | op2(e21,e22) = e23 )
    & ( op2(e21,e23) = e20
      | op2(e21,e23) = e21
      | op2(e21,e23) = e22
      | op2(e21,e23) = e23 )
    & ( op2(e22,e20) = e20
      | op2(e22,e20) = e21
      | op2(e22,e20) = e22
      | op2(e22,e20) = e23 )
    & ( op2(e22,e21) = e20
      | op2(e22,e21) = e21
      | op2(e22,e21) = e22
      | op2(e22,e21) = e23 )
    & ( op2(e22,e22) = e20
      | op2(e22,e22) = e21
      | op2(e22,e22) = e22
      | op2(e22,e22) = e23 )
    & ( op2(e22,e23) = e20
      | op2(e22,e23) = e21
      | op2(e22,e23) = e22
      | op2(e22,e23) = e23 )
    & ( op2(e23,e20) = e20
      | op2(e23,e20) = e21
      | op2(e23,e20) = e22
      | op2(e23,e20) = e23 )
    & ( op2(e23,e21) = e20
      | op2(e23,e21) = e21
      | op2(e23,e21) = e22
      | op2(e23,e21) = e23 )
    & ( op2(e23,e22) = e20
      | op2(e23,e22) = e21
      | op2(e23,e22) = e22
      | op2(e23,e22) = e23 )
    & ( op2(e23,e23) = e20
      | op2(e23,e23) = e21
      | op2(e23,e23) = e22
      | op2(e23,e23) = e23 ) )).

fof(ax6,axiom,
    ( op2(op2(e20,e20),e20) = op2(e20,op2(e20,e20))
    & op2(op2(e20,e20),e21) = op2(e20,op2(e20,e21))
    & op2(op2(e20,e20),e22) = op2(e20,op2(e20,e22))
    & op2(op2(e20,e20),e23) = op2(e20,op2(e20,e23))
    & op2(op2(e20,e21),e20) = op2(e20,op2(e21,e20))
    & op2(op2(e20,e21),e21) = op2(e20,op2(e21,e21))
    & op2(op2(e20,e21),e22) = op2(e20,op2(e21,e22))
    & op2(op2(e20,e21),e23) = op2(e20,op2(e21,e23))
    & op2(op2(e20,e22),e20) = op2(e20,op2(e22,e20))
    & op2(op2(e20,e22),e21) = op2(e20,op2(e22,e21))
    & op2(op2(e20,e22),e22) = op2(e20,op2(e22,e22))
    & op2(op2(e20,e22),e23) = op2(e20,op2(e22,e23))
    & op2(op2(e20,e23),e20) = op2(e20,op2(e23,e20))
    & op2(op2(e20,e23),e21) = op2(e20,op2(e23,e21))
    & op2(op2(e20,e23),e22) = op2(e20,op2(e23,e22))
    & op2(op2(e20,e23),e23) = op2(e20,op2(e23,e23))
    & op2(op2(e21,e20),e20) = op2(e21,op2(e20,e20))
    & op2(op2(e21,e20),e21) = op2(e21,op2(e20,e21))
    & op2(op2(e21,e20),e22) = op2(e21,op2(e20,e22))
    & op2(op2(e21,e20),e23) = op2(e21,op2(e20,e23))
    & op2(op2(e21,e21),e20) = op2(e21,op2(e21,e20))
    & op2(op2(e21,e21),e21) = op2(e21,op2(e21,e21))
    & op2(op2(e21,e21),e22) = op2(e21,op2(e21,e22))
    & op2(op2(e21,e21),e23) = op2(e21,op2(e21,e23))
    & op2(op2(e21,e22),e20) = op2(e21,op2(e22,e20))
    & op2(op2(e21,e22),e21) = op2(e21,op2(e22,e21))
    & op2(op2(e21,e22),e22) = op2(e21,op2(e22,e22))
    & op2(op2(e21,e22),e23) = op2(e21,op2(e22,e23))
    & op2(op2(e21,e23),e20) = op2(e21,op2(e23,e20))
    & op2(op2(e21,e23),e21) = op2(e21,op2(e23,e21))
    & op2(op2(e21,e23),e22) = op2(e21,op2(e23,e22))
    & op2(op2(e21,e23),e23) = op2(e21,op2(e23,e23))
    & op2(op2(e22,e20),e20) = op2(e22,op2(e20,e20))
    & op2(op2(e22,e20),e21) = op2(e22,op2(e20,e21))
    & op2(op2(e22,e20),e22) = op2(e22,op2(e20,e22))
    & op2(op2(e22,e20),e23) = op2(e22,op2(e20,e23))
    & op2(op2(e22,e21),e20) = op2(e22,op2(e21,e20))
    & op2(op2(e22,e21),e21) = op2(e22,op2(e21,e21))
    & op2(op2(e22,e21),e22) = op2(e22,op2(e21,e22))
    & op2(op2(e22,e21),e23) = op2(e22,op2(e21,e23))
    & op2(op2(e22,e22),e20) = op2(e22,op2(e22,e20))
    & op2(op2(e22,e22),e21) = op2(e22,op2(e22,e21))
    & op2(op2(e22,e22),e22) = op2(e22,op2(e22,e22))
    & op2(op2(e22,e22),e23) = op2(e22,op2(e22,e23))
    & op2(op2(e22,e23),e20) = op2(e22,op2(e23,e20))
    & op2(op2(e22,e23),e21) = op2(e22,op2(e23,e21))
    & op2(op2(e22,e23),e22) = op2(e22,op2(e23,e22))
    & op2(op2(e22,e23),e23) = op2(e22,op2(e23,e23))
    & op2(op2(e23,e20),e20) = op2(e23,op2(e20,e20))
    & op2(op2(e23,e20),e21) = op2(e23,op2(e20,e21))
    & op2(op2(e23,e20),e22) = op2(e23,op2(e20,e22))
    & op2(op2(e23,e20),e23) = op2(e23,op2(e20,e23))
    & op2(op2(e23,e21),e20) = op2(e23,op2(e21,e20))
    & op2(op2(e23,e21),e21) = op2(e23,op2(e21,e21))
    & op2(op2(e23,e21),e22) = op2(e23,op2(e21,e22))
    & op2(op2(e23,e21),e23) = op2(e23,op2(e21,e23))
    & op2(op2(e23,e22),e20) = op2(e23,op2(e22,e20))
    & op2(op2(e23,e22),e21) = op2(e23,op2(e22,e21))
    & op2(op2(e23,e22),e22) = op2(e23,op2(e22,e22))
    & op2(op2(e23,e22),e23) = op2(e23,op2(e22,e23))
    & op2(op2(e23,e23),e20) = op2(e23,op2(e23,e20))
    & op2(op2(e23,e23),e21) = op2(e23,op2(e23,e21))
    & op2(op2(e23,e23),e22) = op2(e23,op2(e23,e22))
    & op2(op2(e23,e23),e23) = op2(e23,op2(e23,e23)) )).

fof(ax7,axiom,
    ( op2(unit2,e20) = e20
    & op2(e20,unit2) = e20
    & op2(unit2,e21) = e21
    & op2(e21,unit2) = e21
    & op2(unit2,e22) = e22
    & op2(e22,unit2) = e22
    & op2(unit2,e23) = e23
    & op2(e23,unit2) = e23
    & ( unit2 = e20
      | unit2 = e21
      | unit2 = e22
      | unit2 = e23 ) )).

fof(ax8,axiom,
    ( op2(e20,inv2(e20)) = unit2
    & op2(inv2(e20),e20) = unit2
    & op2(e21,inv2(e21)) = unit2
    & op2(inv2(e21),e21) = unit2
    & op2(e22,inv2(e22)) = unit2
    & op2(inv2(e22),e22) = unit2
    & op2(e23,inv2(e23)) = unit2
    & op2(inv2(e23),e23) = unit2
    & ( inv2(e20) = e20
      | inv2(e20) = e21
      | inv2(e20) = e22
      | inv2(e20) = e23 )
    & ( inv2(e21) = e20
      | inv2(e21) = e21
      | inv2(e21) = e22
      | inv2(e21) = e23 )
    & ( inv2(e22) = e20
      | inv2(e22) = e21
      | inv2(e22) = e22
      | inv2(e22) = e23 )
    & ( inv2(e23) = e20
      | inv2(e23) = e21
      | inv2(e23) = e22
      | inv2(e23) = e23 ) )).

fof(ax9,axiom,
    ( inv1(unit1) = unit1 )).

fof(ax10,axiom,
    ( inv1(inv1(e10)) = e10
    & inv1(inv1(e11)) = e11
    & inv1(inv1(e12)) = e12
    & inv1(inv1(e13)) = e13 )).

fof(ax11,axiom,
    ( ( inv1(e10) = e10
     => inv1(e10) = e10 )
    & ( inv1(e10) = e11
     => inv1(e11) = e10 )
    & ( inv1(e10) = e12
     => inv1(e12) = e10 )
    & ( inv1(e10) = e13
     => inv1(e13) = e10 )
    & ( inv1(e11) = e10
     => inv1(e10) = e11 )
    & ( inv1(e11) = e11
     => inv1(e11) = e11 )
    & ( inv1(e11) = e12
     => inv1(e12) = e11 )
    & ( inv1(e11) = e13
     => inv1(e13) = e11 )
    & ( inv1(e12) = e10
     => inv1(e10) = e12 )
    & ( inv1(e12) = e11
     => inv1(e11) = e12 )
    & ( inv1(e12) = e12
     => inv1(e12) = e12 )
    & ( inv1(e12) = e13
     => inv1(e13) = e12 )
    & ( inv1(e13) = e10
     => inv1(e10) = e13 )
    & ( inv1(e13) = e11
     => inv1(e11) = e13 )
    & ( inv1(e13) = e12
     => inv1(e12) = e13 )
    & ( inv1(e13) = e13
     => inv1(e13) = e13 ) )).

fof(ax12,axiom,
    ( inv1(e10) != inv1(e11)
    & inv1(e10) != inv1(e12)
    & inv1(e10) != inv1(e13)
    & inv1(e11) != inv1(e12)
    & inv1(e11) != inv1(e13)
    & inv1(e12) != inv1(e13) )).

fof(ax13,axiom,
    ( inv2(unit2) = unit2 )).

fof(ax14,axiom,
    ( inv2(inv2(e20)) = e20
    & inv2(inv2(e21)) = e21
    & inv2(inv2(e22)) = e22
    & inv2(inv2(e23)) = e23 )).

fof(ax15,axiom,
    ( ( inv2(e20) = e20
     => inv2(e20) = e20 )
    & ( inv2(e20) = e21
     => inv2(e21) = e20 )
    & ( inv2(e20) = e22
     => inv2(e22) = e20 )
    & ( inv2(e20) = e23
     => inv2(e23) = e20 )
    & ( inv2(e21) = e20
     => inv2(e20) = e21 )
    & ( inv2(e21) = e21
     => inv2(e21) = e21 )
    & ( inv2(e21) = e22
     => inv2(e22) = e21 )
    & ( inv2(e21) = e23
     => inv2(e23) = e21 )
    & ( inv2(e22) = e20
     => inv2(e20) = e22 )
    & ( inv2(e22) = e21
     => inv2(e21) = e22 )
    & ( inv2(e22) = e22
     => inv2(e22) = e22 )
    & ( inv2(e22) = e23
     => inv2(e23) = e22 )
    & ( inv2(e23) = e20
     => inv2(e20) = e23 )
    & ( inv2(e23) = e21
     => inv2(e21) = e23 )
    & ( inv2(e23) = e22
     => inv2(e22) = e23 )
    & ( inv2(e23) = e23
     => inv2(e23) = e23 ) )).

fof(ax16,axiom,
    ( inv2(e20) != inv2(e21)
    & inv2(e20) != inv2(e22)
    & inv2(e20) != inv2(e23)
    & inv2(e21) != inv2(e22)
    & inv2(e21) != inv2(e23)
    & inv2(e22) != inv2(e23) )).

fof(ax17,axiom,
    ( op1(e10,e10) != op1(e11,e10)
    & op1(e10,e10) != op1(e12,e10)
    & op1(e10,e10) != op1(e13,e10)
    & op1(e11,e10) != op1(e12,e10)
    & op1(e11,e10) != op1(e13,e10)
    & op1(e12,e10) != op1(e13,e10)
    & op1(e10,e11) != op1(e11,e11)
    & op1(e10,e11) != op1(e12,e11)
    & op1(e10,e11) != op1(e13,e11)
    & op1(e11,e11) != op1(e12,e11)
    & op1(e11,e11) != op1(e13,e11)
    & op1(e12,e11) != op1(e13,e11)
    & op1(e10,e12) != op1(e11,e12)
    & op1(e10,e12) != op1(e12,e12)
    & op1(e10,e12) != op1(e13,e12)
    & op1(e11,e12) != op1(e12,e12)
    & op1(e11,e12) != op1(e13,e12)
    & op1(e12,e12) != op1(e13,e12)
    & op1(e10,e13) != op1(e11,e13)
    & op1(e10,e13) != op1(e12,e13)
    & op1(e10,e13) != op1(e13,e13)
    & op1(e11,e13) != op1(e12,e13)
    & op1(e11,e13) != op1(e13,e13)
    & op1(e12,e13) != op1(e13,e13)
    & op1(e10,e10) != op1(e10,e11)
    & op1(e10,e10) != op1(e10,e12)
    & op1(e10,e10) != op1(e10,e13)
    & op1(e10,e11) != op1(e10,e12)
    & op1(e10,e11) != op1(e10,e13)
    & op1(e10,e12) != op1(e10,e13)
    & op1(e11,e10) != op1(e11,e11)
    & op1(e11,e10) != op1(e11,e12)
    & op1(e11,e10) != op1(e11,e13)
    & op1(e11,e11) != op1(e11,e12)
    & op1(e11,e11) != op1(e11,e13)
    & op1(e11,e12) != op1(e11,e13)
    & op1(e12,e10) != op1(e12,e11)
    & op1(e12,e10) != op1(e12,e12)
    & op1(e12,e10) != op1(e12,e13)
    & op1(e12,e11) != op1(e12,e12)
    & op1(e12,e11) != op1(e12,e13)
    & op1(e12,e12) != op1(e12,e13)
    & op1(e13,e10) != op1(e13,e11)
    & op1(e13,e10) != op1(e13,e12)
    & op1(e13,e10) != op1(e13,e13)
    & op1(e13,e11) != op1(e13,e12)
    & op1(e13,e11) != op1(e13,e13)
    & op1(e13,e12) != op1(e13,e13) )).

fof(ax18,axiom,
    ( op2(e20,e20) != op2(e21,e20)
    & op2(e20,e20) != op2(e22,e20)
    & op2(e20,e20) != op2(e23,e20)
    & op2(e21,e20) != op2(e22,e20)
    & op2(e21,e20) != op2(e23,e20)
    & op2(e22,e20) != op2(e23,e20)
    & op2(e20,e21) != op2(e21,e21)
    & op2(e20,e21) != op2(e22,e21)
    & op2(e20,e21) != op2(e23,e21)
    & op2(e21,e21) != op2(e22,e21)
    & op2(e21,e21) != op2(e23,e21)
    & op2(e22,e21) != op2(e23,e21)
    & op2(e20,e22) != op2(e21,e22)
    & op2(e20,e22) != op2(e22,e22)
    & op2(e20,e22) != op2(e23,e22)
    & op2(e21,e22) != op2(e22,e22)
    & op2(e21,e22) != op2(e23,e22)
    & op2(e22,e22) != op2(e23,e22)
    & op2(e20,e23) != op2(e21,e23)
    & op2(e20,e23) != op2(e22,e23)
    & op2(e20,e23) != op2(e23,e23)
    & op2(e21,e23) != op2(e22,e23)
    & op2(e21,e23) != op2(e23,e23)
    & op2(e22,e23) != op2(e23,e23)
    & op2(e20,e20) != op2(e20,e21)
    & op2(e20,e20) != op2(e20,e22)
    & op2(e20,e20) != op2(e20,e23)
    & op2(e20,e21) != op2(e20,e22)
    & op2(e20,e21) != op2(e20,e23)
    & op2(e20,e22) != op2(e20,e23)
    & op2(e21,e20) != op2(e21,e21)
    & op2(e21,e20) != op2(e21,e22)
    & op2(e21,e20) != op2(e21,e23)
    & op2(e21,e21) != op2(e21,e22)
    & op2(e21,e21) != op2(e21,e23)
    & op2(e21,e22) != op2(e21,e23)
    & op2(e22,e20) != op2(e22,e21)
    & op2(e22,e20) != op2(e22,e22)
    & op2(e22,e20) != op2(e22,e23)
    & op2(e22,e21) != op2(e22,e22)
    & op2(e22,e21) != op2(e22,e23)
    & op2(e22,e22) != op2(e22,e23)
    & op2(e23,e20) != op2(e23,e21)
    & op2(e23,e20) != op2(e23,e22)
    & op2(e23,e20) != op2(e23,e23)
    & op2(e23,e21) != op2(e23,e22)
    & op2(e23,e21) != op2(e23,e23)
    & op2(e23,e22) != op2(e23,e23) )).

fof(ax19,axiom,
    ( e10 != e11
    & e10 != e12
    & e10 != e13
    & e11 != e12
    & e11 != e13
    & e12 != e13 )).

fof(ax20,axiom,
    ( e20 != e21
    & e20 != e22
    & e20 != e23
    & e21 != e22
    & e21 != e23
    & e22 != e23 )).

fof(ax21,axiom,
    ( e10 != e20
    & e10 != e21
    & e10 != e22
    & e10 != e23
    & e11 != e20
    & e11 != e21
    & e11 != e22
    & e11 != e23
    & e12 != e20
    & e12 != e21
    & e12 != e22
    & e12 != e23
    & e13 != e20
    & e13 != e21
    & e13 != e22
    & e13 != e23 )).

fof(ax22,axiom,
    ( ( op1(e10,e10) = e10
      & op1(e11,e11) = e10
      & op1(e12,e12) = e10
      & op1(e13,e13) = e10 )
    | ( op1(e10,e10) = e11
      & op1(e11,e11) = e11
      & op1(e12,e12) = e11
      & op1(e13,e13) = e11 )
    | ( op1(e10,e10) = e12
      & op1(e11,e11) = e12
      & op1(e12,e12) = e12
      & op1(e13,e13) = e12 )
    | ( op1(e10,e10) = e13
      & op1(e11,e11) = e13
      & op1(e12,e12) = e13
      & op1(e13,e13) = e13 ) )).

fof(ax23,axiom,
    ( ( op2(e20,e20) = e20
      & op2(e21,e21) = e20
      & op2(e22,e22) = e20
      & op2(e23,e23) = e20 )
    | ( op2(e20,e20) = e21
      & op2(e21,e21) = e21
      & op2(e22,e22) = e21
      & op2(e23,e23) = e21 )
    | ( op2(e20,e20) = e22
      & op2(e21,e21) = e22
      & op2(e22,e22) = e22
      & op2(e23,e23) = e22 )
    | ( op2(e20,e20) = e23
      & op2(e21,e21) = e23
      & op2(e22,e22) = e23
      & op2(e23,e23) = e23 ) )).

fof(ax24,axiom,
    ( e10 = op1(e13,e13)
    & e11 = op1(e12,e13) )).

fof(ax25,axiom,
    ( e20 = op2(e23,e23)
    & e21 = op2(e22,e23) )).

fof(ax26,axiom,
    ( h1(e12) = e20
    & h1(e13) = e21
    & h1(e10) = op2(e21,e21)
    & h1(e11) = op2(e20,e21) )).

fof(ax27,axiom,
    ( h2(e12) = e20
    & h2(e13) = e22
    & h2(e10) = op2(e22,e22)
    & h2(e11) = op2(e20,e22) )).

fof(ax28,axiom,
    ( h3(e12) = e20
    & h3(e13) = e23
    & h3(e10) = op2(e23,e23)
    & h3(e11) = op2(e20,e23) )).

fof(ax29,axiom,
    ( h4(e12) = e21
    & h4(e13) = e20
    & h4(e10) = op2(e20,e20)
    & h4(e11) = op2(e21,e20) )).

fof(ax30,axiom,
    ( h5(e12) = e21
    & h5(e13) = e22
    & h5(e10) = op2(e22,e22)
    & h5(e11) = op2(e21,e22) )).

fof(ax31,axiom,
    ( h6(e12) = e21
    & h6(e13) = e23
    & h6(e10) = op2(e23,e23)
    & h6(e11) = op2(e21,e23) )).

fof(ax32,axiom,
    ( h7(e12) = e22
    & h7(e13) = e20
    & h7(e10) = op2(e20,e20)
    & h7(e11) = op2(e22,e20) )).

fof(ax33,axiom,
    ( h8(e12) = e22
    & h8(e13) = e21
    & h8(e10) = op2(e21,e21)
    & h8(e11) = op2(e22,e21) )).

fof(ax34,axiom,
    ( h9(e12) = e22
    & h9(e13) = e23
    & h9(e10) = op2(e23,e23)
    & h9(e11) = op2(e22,e23) )).

fof(ax35,axiom,
    ( h10(e12) = e23
    & h10(e13) = e20
    & h10(e10) = op2(e20,e20)
    & h10(e11) = op2(e23,e20) )).

fof(ax36,axiom,
    ( h11(e12) = e23
    & h11(e13) = e21
    & h11(e10) = op2(e21,e21)
    & h11(e11) = op2(e23,e21) )).

fof(ax37,axiom,
    ( h12(e12) = e23
    & h12(e13) = e22
    & h12(e10) = op2(e22,e22)
    & h12(e11) = op2(e23,e22) )).

fof(co1,conjecture,
    ( ( h1(op1(e10,e10)) = op2(h1(e10),h1(e10))
      & h1(op1(e10,e11)) = op2(h1(e10),h1(e11))
      & h1(op1(e10,e12)) = op2(h1(e10),h1(e12))
      & h1(op1(e10,e13)) = op2(h1(e10),h1(e13))
      & h1(op1(e11,e10)) = op2(h1(e11),h1(e10))
      & h1(op1(e11,e11)) = op2(h1(e11),h1(e11))
      & h1(op1(e11,e12)) = op2(h1(e11),h1(e12))
      & h1(op1(e11,e13)) = op2(h1(e11),h1(e13))
      & h1(op1(e12,e10)) = op2(h1(e12),h1(e10))
      & h1(op1(e12,e11)) = op2(h1(e12),h1(e11))
      & h1(op1(e12,e12)) = op2(h1(e12),h1(e12))
      & h1(op1(e12,e13)) = op2(h1(e12),h1(e13))
      & h1(op1(e13,e10)) = op2(h1(e13),h1(e10))
      & h1(op1(e13,e11)) = op2(h1(e13),h1(e11))
      & h1(op1(e13,e12)) = op2(h1(e13),h1(e12))
      & h1(op1(e13,e13)) = op2(h1(e13),h1(e13))
      & ( h1(e10) = e20
        | h1(e11) = e20
        | h1(e12) = e20
        | h1(e13) = e20 )
      & ( h1(e10) = e21
        | h1(e11) = e21
        | h1(e12) = e21
        | h1(e13) = e21 )
      & ( h1(e10) = e22
        | h1(e11) = e22
        | h1(e12) = e22
        | h1(e13) = e22 )
      & ( h1(e10) = e23
        | h1(e11) = e23
        | h1(e12) = e23
        | h1(e13) = e23 ) )
    | ( h2(op1(e10,e10)) = op2(h2(e10),h2(e10))
      & h2(op1(e10,e11)) = op2(h2(e10),h2(e11))
      & h2(op1(e10,e12)) = op2(h2(e10),h2(e12))
      & h2(op1(e10,e13)) = op2(h2(e10),h2(e13))
      & h2(op1(e11,e10)) = op2(h2(e11),h2(e10))
      & h2(op1(e11,e11)) = op2(h2(e11),h2(e11))
      & h2(op1(e11,e12)) = op2(h2(e11),h2(e12))
      & h2(op1(e11,e13)) = op2(h2(e11),h2(e13))
      & h2(op1(e12,e10)) = op2(h2(e12),h2(e10))
      & h2(op1(e12,e11)) = op2(h2(e12),h2(e11))
      & h2(op1(e12,e12)) = op2(h2(e12),h2(e12))
      & h2(op1(e12,e13)) = op2(h2(e12),h2(e13))
      & h2(op1(e13,e10)) = op2(h2(e13),h2(e10))
      & h2(op1(e13,e11)) = op2(h2(e13),h2(e11))
      & h2(op1(e13,e12)) = op2(h2(e13),h2(e12))
      & h2(op1(e13,e13)) = op2(h2(e13),h2(e13))
      & ( h2(e10) = e20
        | h2(e11) = e20
        | h2(e12) = e20
        | h2(e13) = e20 )
      & ( h2(e10) = e21
        | h2(e11) = e21
        | h2(e12) = e21
        | h2(e13) = e21 )
      & ( h2(e10) = e22
        | h2(e11) = e22
        | h2(e12) = e22
        | h2(e13) = e22 )
      & ( h2(e10) = e23
        | h2(e11) = e23
        | h2(e12) = e23
        | h2(e13) = e23 ) )
    | ( h3(op1(e10,e10)) = op2(h3(e10),h3(e10))
      & h3(op1(e10,e11)) = op2(h3(e10),h3(e11))
      & h3(op1(e10,e12)) = op2(h3(e10),h3(e12))
      & h3(op1(e10,e13)) = op2(h3(e10),h3(e13))
      & h3(op1(e11,e10)) = op2(h3(e11),h3(e10))
      & h3(op1(e11,e11)) = op2(h3(e11),h3(e11))
      & h3(op1(e11,e12)) = op2(h3(e11),h3(e12))
      & h3(op1(e11,e13)) = op2(h3(e11),h3(e13))
      & h3(op1(e12,e10)) = op2(h3(e12),h3(e10))
      & h3(op1(e12,e11)) = op2(h3(e12),h3(e11))
      & h3(op1(e12,e12)) = op2(h3(e12),h3(e12))
      & h3(op1(e12,e13)) = op2(h3(e12),h3(e13))
      & h3(op1(e13,e10)) = op2(h3(e13),h3(e10))
      & h3(op1(e13,e11)) = op2(h3(e13),h3(e11))
      & h3(op1(e13,e12)) = op2(h3(e13),h3(e12))
      & h3(op1(e13,e13)) = op2(h3(e13),h3(e13))
      & ( h3(e10) = e20
        | h3(e11) = e20
        | h3(e12) = e20
        | h3(e13) = e20 )
      & ( h3(e10) = e21
        | h3(e11) = e21
        | h3(e12) = e21
        | h3(e13) = e21 )
      & ( h3(e10) = e22
        | h3(e11) = e22
        | h3(e12) = e22
        | h3(e13) = e22 )
      & ( h3(e10) = e23
        | h3(e11) = e23
        | h3(e12) = e23
        | h3(e13) = e23 ) )
    | ( h4(op1(e10,e10)) = op2(h4(e10),h4(e10))
      & h4(op1(e10,e11)) = op2(h4(e10),h4(e11))
      & h4(op1(e10,e12)) = op2(h4(e10),h4(e12))
      & h4(op1(e10,e13)) = op2(h4(e10),h4(e13))
      & h4(op1(e11,e10)) = op2(h4(e11),h4(e10))
      & h4(op1(e11,e11)) = op2(h4(e11),h4(e11))
      & h4(op1(e11,e12)) = op2(h4(e11),h4(e12))
      & h4(op1(e11,e13)) = op2(h4(e11),h4(e13))
      & h4(op1(e12,e10)) = op2(h4(e12),h4(e10))
      & h4(op1(e12,e11)) = op2(h4(e12),h4(e11))
      & h4(op1(e12,e12)) = op2(h4(e12),h4(e12))
      & h4(op1(e12,e13)) = op2(h4(e12),h4(e13))
      & h4(op1(e13,e10)) = op2(h4(e13),h4(e10))
      & h4(op1(e13,e11)) = op2(h4(e13),h4(e11))
      & h4(op1(e13,e12)) = op2(h4(e13),h4(e12))
      & h4(op1(e13,e13)) = op2(h4(e13),h4(e13))
      & ( h4(e10) = e20
        | h4(e11) = e20
        | h4(e12) = e20
        | h4(e13) = e20 )
      & ( h4(e10) = e21
        | h4(e11) = e21
        | h4(e12) = e21
        | h4(e13) = e21 )
      & ( h4(e10) = e22
        | h4(e11) = e22
        | h4(e12) = e22
        | h4(e13) = e22 )
      & ( h4(e10) = e23
        | h4(e11) = e23
        | h4(e12) = e23
        | h4(e13) = e23 ) )
    | ( h5(op1(e10,e10)) = op2(h5(e10),h5(e10))
      & h5(op1(e10,e11)) = op2(h5(e10),h5(e11))
      & h5(op1(e10,e12)) = op2(h5(e10),h5(e12))
      & h5(op1(e10,e13)) = op2(h5(e10),h5(e13))
      & h5(op1(e11,e10)) = op2(h5(e11),h5(e10))
      & h5(op1(e11,e11)) = op2(h5(e11),h5(e11))
      & h5(op1(e11,e12)) = op2(h5(e11),h5(e12))
      & h5(op1(e11,e13)) = op2(h5(e11),h5(e13))
      & h5(op1(e12,e10)) = op2(h5(e12),h5(e10))
      & h5(op1(e12,e11)) = op2(h5(e12),h5(e11))
      & h5(op1(e12,e12)) = op2(h5(e12),h5(e12))
      & h5(op1(e12,e13)) = op2(h5(e12),h5(e13))
      & h5(op1(e13,e10)) = op2(h5(e13),h5(e10))
      & h5(op1(e13,e11)) = op2(h5(e13),h5(e11))
      & h5(op1(e13,e12)) = op2(h5(e13),h5(e12))
      & h5(op1(e13,e13)) = op2(h5(e13),h5(e13))
      & ( h5(e10) = e20
        | h5(e11) = e20
        | h5(e12) = e20
        | h5(e13) = e20 )
      & ( h5(e10) = e21
        | h5(e11) = e21
        | h5(e12) = e21
        | h5(e13) = e21 )
      & ( h5(e10) = e22
        | h5(e11) = e22
        | h5(e12) = e22
        | h5(e13) = e22 )
      & ( h5(e10) = e23
        | h5(e11) = e23
        | h5(e12) = e23
        | h5(e13) = e23 ) )
    | ( h6(op1(e10,e10)) = op2(h6(e10),h6(e10))
      & h6(op1(e10,e11)) = op2(h6(e10),h6(e11))
      & h6(op1(e10,e12)) = op2(h6(e10),h6(e12))
      & h6(op1(e10,e13)) = op2(h6(e10),h6(e13))
      & h6(op1(e11,e10)) = op2(h6(e11),h6(e10))
      & h6(op1(e11,e11)) = op2(h6(e11),h6(e11))
      & h6(op1(e11,e12)) = op2(h6(e11),h6(e12))
      & h6(op1(e11,e13)) = op2(h6(e11),h6(e13))
      & h6(op1(e12,e10)) = op2(h6(e12),h6(e10))
      & h6(op1(e12,e11)) = op2(h6(e12),h6(e11))
      & h6(op1(e12,e12)) = op2(h6(e12),h6(e12))
      & h6(op1(e12,e13)) = op2(h6(e12),h6(e13))
      & h6(op1(e13,e10)) = op2(h6(e13),h6(e10))
      & h6(op1(e13,e11)) = op2(h6(e13),h6(e11))
      & h6(op1(e13,e12)) = op2(h6(e13),h6(e12))
      & h6(op1(e13,e13)) = op2(h6(e13),h6(e13))
      & ( h6(e10) = e20
        | h6(e11) = e20
        | h6(e12) = e20
        | h6(e13) = e20 )
      & ( h6(e10) = e21
        | h6(e11) = e21
        | h6(e12) = e21
        | h6(e13) = e21 )
      & ( h6(e10) = e22
        | h6(e11) = e22
        | h6(e12) = e22
        | h6(e13) = e22 )
      & ( h6(e10) = e23
        | h6(e11) = e23
        | h6(e12) = e23
        | h6(e13) = e23 ) )
    | ( h7(op1(e10,e10)) = op2(h7(e10),h7(e10))
      & h7(op1(e10,e11)) = op2(h7(e10),h7(e11))
      & h7(op1(e10,e12)) = op2(h7(e10),h7(e12))
      & h7(op1(e10,e13)) = op2(h7(e10),h7(e13))
      & h7(op1(e11,e10)) = op2(h7(e11),h7(e10))
      & h7(op1(e11,e11)) = op2(h7(e11),h7(e11))
      & h7(op1(e11,e12)) = op2(h7(e11),h7(e12))
      & h7(op1(e11,e13)) = op2(h7(e11),h7(e13))
      & h7(op1(e12,e10)) = op2(h7(e12),h7(e10))
      & h7(op1(e12,e11)) = op2(h7(e12),h7(e11))
      & h7(op1(e12,e12)) = op2(h7(e12),h7(e12))
      & h7(op1(e12,e13)) = op2(h7(e12),h7(e13))
      & h7(op1(e13,e10)) = op2(h7(e13),h7(e10))
      & h7(op1(e13,e11)) = op2(h7(e13),h7(e11))
      & h7(op1(e13,e12)) = op2(h7(e13),h7(e12))
      & h7(op1(e13,e13)) = op2(h7(e13),h7(e13))
      & ( h7(e10) = e20
        | h7(e11) = e20
        | h7(e12) = e20
        | h7(e13) = e20 )
      & ( h7(e10) = e21
        | h7(e11) = e21
        | h7(e12) = e21
        | h7(e13) = e21 )
      & ( h7(e10) = e22
        | h7(e11) = e22
        | h7(e12) = e22
        | h7(e13) = e22 )
      & ( h7(e10) = e23
        | h7(e11) = e23
        | h7(e12) = e23
        | h7(e13) = e23 ) )
    | ( h8(op1(e10,e10)) = op2(h8(e10),h8(e10))
      & h8(op1(e10,e11)) = op2(h8(e10),h8(e11))
      & h8(op1(e10,e12)) = op2(h8(e10),h8(e12))
      & h8(op1(e10,e13)) = op2(h8(e10),h8(e13))
      & h8(op1(e11,e10)) = op2(h8(e11),h8(e10))
      & h8(op1(e11,e11)) = op2(h8(e11),h8(e11))
      & h8(op1(e11,e12)) = op2(h8(e11),h8(e12))
      & h8(op1(e11,e13)) = op2(h8(e11),h8(e13))
      & h8(op1(e12,e10)) = op2(h8(e12),h8(e10))
      & h8(op1(e12,e11)) = op2(h8(e12),h8(e11))
      & h8(op1(e12,e12)) = op2(h8(e12),h8(e12))
      & h8(op1(e12,e13)) = op2(h8(e12),h8(e13))
      & h8(op1(e13,e10)) = op2(h8(e13),h8(e10))
      & h8(op1(e13,e11)) = op2(h8(e13),h8(e11))
      & h8(op1(e13,e12)) = op2(h8(e13),h8(e12))
      & h8(op1(e13,e13)) = op2(h8(e13),h8(e13))
      & ( h8(e10) = e20
        | h8(e11) = e20
        | h8(e12) = e20
        | h8(e13) = e20 )
      & ( h8(e10) = e21
        | h8(e11) = e21
        | h8(e12) = e21
        | h8(e13) = e21 )
      & ( h8(e10) = e22
        | h8(e11) = e22
        | h8(e12) = e22
        | h8(e13) = e22 )
      & ( h8(e10) = e23
        | h8(e11) = e23
        | h8(e12) = e23
        | h8(e13) = e23 ) )
    | ( h9(op1(e10,e10)) = op2(h9(e10),h9(e10))
      & h9(op1(e10,e11)) = op2(h9(e10),h9(e11))
      & h9(op1(e10,e12)) = op2(h9(e10),h9(e12))
      & h9(op1(e10,e13)) = op2(h9(e10),h9(e13))
      & h9(op1(e11,e10)) = op2(h9(e11),h9(e10))
      & h9(op1(e11,e11)) = op2(h9(e11),h9(e11))
      & h9(op1(e11,e12)) = op2(h9(e11),h9(e12))
      & h9(op1(e11,e13)) = op2(h9(e11),h9(e13))
      & h9(op1(e12,e10)) = op2(h9(e12),h9(e10))
      & h9(op1(e12,e11)) = op2(h9(e12),h9(e11))
      & h9(op1(e12,e12)) = op2(h9(e12),h9(e12))
      & h9(op1(e12,e13)) = op2(h9(e12),h9(e13))
      & h9(op1(e13,e10)) = op2(h9(e13),h9(e10))
      & h9(op1(e13,e11)) = op2(h9(e13),h9(e11))
      & h9(op1(e13,e12)) = op2(h9(e13),h9(e12))
      & h9(op1(e13,e13)) = op2(h9(e13),h9(e13))
      & ( h9(e10) = e20
        | h9(e11) = e20
        | h9(e12) = e20
        | h9(e13) = e20 )
      & ( h9(e10) = e21
        | h9(e11) = e21
        | h9(e12) = e21
        | h9(e13) = e21 )
      & ( h9(e10) = e22
        | h9(e11) = e22
        | h9(e12) = e22
        | h9(e13) = e22 )
      & ( h9(e10) = e23
        | h9(e11) = e23
        | h9(e12) = e23
        | h9(e13) = e23 ) )
    | ( h10(op1(e10,e10)) = op2(h10(e10),h10(e10))
      & h10(op1(e10,e11)) = op2(h10(e10),h10(e11))
      & h10(op1(e10,e12)) = op2(h10(e10),h10(e12))
      & h10(op1(e10,e13)) = op2(h10(e10),h10(e13))
      & h10(op1(e11,e10)) = op2(h10(e11),h10(e10))
      & h10(op1(e11,e11)) = op2(h10(e11),h10(e11))
      & h10(op1(e11,e12)) = op2(h10(e11),h10(e12))
      & h10(op1(e11,e13)) = op2(h10(e11),h10(e13))
      & h10(op1(e12,e10)) = op2(h10(e12),h10(e10))
      & h10(op1(e12,e11)) = op2(h10(e12),h10(e11))
      & h10(op1(e12,e12)) = op2(h10(e12),h10(e12))
      & h10(op1(e12,e13)) = op2(h10(e12),h10(e13))
      & h10(op1(e13,e10)) = op2(h10(e13),h10(e10))
      & h10(op1(e13,e11)) = op2(h10(e13),h10(e11))
      & h10(op1(e13,e12)) = op2(h10(e13),h10(e12))
      & h10(op1(e13,e13)) = op2(h10(e13),h10(e13))
      & ( h10(e10) = e20
        | h10(e11) = e20
        | h10(e12) = e20
        | h10(e13) = e20 )
      & ( h10(e10) = e21
        | h10(e11) = e21
        | h10(e12) = e21
        | h10(e13) = e21 )
      & ( h10(e10) = e22
        | h10(e11) = e22
        | h10(e12) = e22
        | h10(e13) = e22 )
      & ( h10(e10) = e23
        | h10(e11) = e23
        | h10(e12) = e23
        | h10(e13) = e23 ) )
    | ( h11(op1(e10,e10)) = op2(h11(e10),h11(e10))
      & h11(op1(e10,e11)) = op2(h11(e10),h11(e11))
      & h11(op1(e10,e12)) = op2(h11(e10),h11(e12))
      & h11(op1(e10,e13)) = op2(h11(e10),h11(e13))
      & h11(op1(e11,e10)) = op2(h11(e11),h11(e10))
      & h11(op1(e11,e11)) = op2(h11(e11),h11(e11))
      & h11(op1(e11,e12)) = op2(h11(e11),h11(e12))
      & h11(op1(e11,e13)) = op2(h11(e11),h11(e13))
      & h11(op1(e12,e10)) = op2(h11(e12),h11(e10))
      & h11(op1(e12,e11)) = op2(h11(e12),h11(e11))
      & h11(op1(e12,e12)) = op2(h11(e12),h11(e12))
      & h11(op1(e12,e13)) = op2(h11(e12),h11(e13))
      & h11(op1(e13,e10)) = op2(h11(e13),h11(e10))
      & h11(op1(e13,e11)) = op2(h11(e13),h11(e11))
      & h11(op1(e13,e12)) = op2(h11(e13),h11(e12))
      & h11(op1(e13,e13)) = op2(h11(e13),h11(e13))
      & ( h11(e10) = e20
        | h11(e11) = e20
        | h11(e12) = e20
        | h11(e13) = e20 )
      & ( h11(e10) = e21
        | h11(e11) = e21
        | h11(e12) = e21
        | h11(e13) = e21 )
      & ( h11(e10) = e22
        | h11(e11) = e22
        | h11(e12) = e22
        | h11(e13) = e22 )
      & ( h11(e10) = e23
        | h11(e11) = e23
        | h11(e12) = e23
        | h11(e13) = e23 ) )
    | ( h12(op1(e10,e10)) = op2(h12(e10),h12(e10))
      & h12(op1(e10,e11)) = op2(h12(e10),h12(e11))
      & h12(op1(e10,e12)) = op2(h12(e10),h12(e12))
      & h12(op1(e10,e13)) = op2(h12(e10),h12(e13))
      & h12(op1(e11,e10)) = op2(h12(e11),h12(e10))
      & h12(op1(e11,e11)) = op2(h12(e11),h12(e11))
      & h12(op1(e11,e12)) = op2(h12(e11),h12(e12))
      & h12(op1(e11,e13)) = op2(h12(e11),h12(e13))
      & h12(op1(e12,e10)) = op2(h12(e12),h12(e10))
      & h12(op1(e12,e11)) = op2(h12(e12),h12(e11))
      & h12(op1(e12,e12)) = op2(h12(e12),h12(e12))
      & h12(op1(e12,e13)) = op2(h12(e12),h12(e13))
      & h12(op1(e13,e10)) = op2(h12(e13),h12(e10))
      & h12(op1(e13,e11)) = op2(h12(e13),h12(e11))
      & h12(op1(e13,e12)) = op2(h12(e13),h12(e12))
      & h12(op1(e13,e13)) = op2(h12(e13),h12(e13))
      & ( h12(e10) = e20
        | h12(e11) = e20
        | h12(e12) = e20
        | h12(e13) = e20 )
      & ( h12(e10) = e21
        | h12(e11) = e21
        | h12(e12) = e21
        | h12(e13) = e21 )
      & ( h12(e10) = e22
        | h12(e11) = e22
        | h12(e12) = e22
        | h12(e13) = e22 )
      & ( h12(e10) = e23
        | h12(e11) = e23
        | h12(e12) = e23
        | h12(e13) = e23 ) ) )).

%--------------------------------------------------------------------------
