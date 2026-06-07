%--------------------------------------------------------------------------
% File     : ALG008-1 : TPTP v3.3.0. Released v2.2.0.
% Domain   : General Algebra
% Problem  : TC + right identity does not give RC.
% Version  : [MP96] (equality) axioms : Especial.
% English  : An algebra with a right identity satisfying the Thomsen
%            Closure (RC) condition does not necessarily satisfy the
%            Reidemeister Closure (RC) condition.

% Refs     : [McC98] McCune (1998), Email to G. Sutcliffe
%          : [MP96]  McCune & Padmanabhan (1996), Automated Deduction in Eq
% Source   : [McC98]
% Names    : TC-3 [MP96]

% Status   : Satisfiable
% Rating   : 0.50 v3.3.0, 0.33 v3.2.0, 0.80 v3.1.0, 0.67 v2.7.0, 0.33 v2.6.0, 0.86 v2.5.0, 0.50 v2.4.0, 0.67 v2.3.0, 1.00 v2.2.1
% Syntax   : Number of clauses     :    6 (   0 non-Horn;   5 unit;   5 RR)
%            Number of atoms       :   10 (  10 equality)
%            Maximal clause size   :    5 (   2 average)
%            Number of predicates  :    1 (   0 propositional; 2-2 arity)
%            Number of functors    :    9 (   8 constant; 0-2 arity)
%            Number of variables   :    9 (   0 singleton)
%            Maximal term depth    :    2 (   2 average)

% Comments : The smallest model has 3 elements.
%--------------------------------------------------------------------------
%----Thomsen Closure (TC) condition:
cnf(thomsen_closure,axiom,
    ( multiply(X,Y) != Z
    | multiply(U,V) != Z
    | multiply(X,W) != V6
    | multiply(V7,V) != V6
    | multiply(U,W) = multiply(V7,Y) )).

%----Right identity:
cnf(right_identity,axiom,
    ( multiply(X,identity) = X )).

%----Denial of Reidimeister Closure (RC) condidition.
cnf(prove_reidimeister1,negated_conjecture,
    ( multiply(c4,a) = multiply(c3,b) )).

cnf(prove_reidimeister2,negated_conjecture,
    ( multiply(c2,a) = multiply(c1,b) )).

cnf(prove_reidimeister3,negated_conjecture,
    ( multiply(c4,f) = multiply(c3,identity) )).

cnf(prove_reidimeister4,negated_conjecture,
    (  multiply(c2,f) != multiply(c1,identity) )).

%--------------------------------------------------------------------------
