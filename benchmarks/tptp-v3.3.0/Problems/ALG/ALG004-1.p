%--------------------------------------------------------------------------
% File     : ALG004-1 : TPTP v3.3.0. Released v2.2.0.
% Domain   : Medial algebras
% Problem  : Cancellative medial algebras satisfy the quotient condition.
% Version  : [MP96] (equality) axioms.
% English  : 

% Refs     : [McC98] McCune (1998), Email to G. Sutcliffe
%          : [MP96]  McCune & Padmanabhan (1996), Automated Deduction in Eq
% Source   : [McC98]
% Names    : MED-7 [MP96]

% Status   : Unsatisfiable
% Rating   : 0.17 v3.3.0, 0.33 v3.2.0, 0.44 v3.1.0, 0.40 v2.7.0, 0.50 v2.6.0, 0.17 v2.5.0, 0.50 v2.4.0, 0.25 v2.3.0, 0.33 v2.2.1
% Syntax   : Number of clauses     :    7 (   0 non-Horn;   5 unit;   6 RR)
%            Number of atoms       :   11 (  11 equality)
%            Maximal clause size   :    3 (   2 average)
%            Number of predicates  :    1 (   0 propositional; 2-2 arity)
%            Number of functors    :    9 (   8 constant; 0-2 arity)
%            Number of variables   :   12 (   0 singleton)
%            Maximal term depth    :    3 (   2 average)

% Comments :
%--------------------------------------------------------------------------
%----Left and right cancellation:
cnf(left_cancellation,axiom,
    ( multiply(X,Y) != Z
    | multiply(U,Y) != Z
    | X = U )).

cnf(right_cancelaation,axiom,
    ( multiply(X,Y) != Z
    | multiply(X,U) != Z
    | Y = U )).

%----Medial law:
cnf(medial_law,axiom,
    ( multiply(multiply(X,Y),multiply(Z,U)) = multiply(multiply(X,Z),multiply(Y,U)) )).

%----Denial of the quotient condition:
cnf(prove_quotient_condition1,negated_conjecture,
    ( multiply(b,b0) = multiply(a,a0) )).

cnf(prove_quotient_condition2,negated_conjecture,
    ( multiply(d,b0) = multiply(c,a0) )).

cnf(prove_quotient_condition3,negated_conjecture,
    ( multiply(b,d0) = multiply(a,c0) )).

cnf(prove_quotient_condition4,negated_conjecture,
    (  multiply(d,d0) != multiply(c,c0) )).

%--------------------------------------------------------------------------
