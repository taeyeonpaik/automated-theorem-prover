%--------------------------------------------------------------------------
% File     : ALG003-1 : TPTP v3.3.0. Bugfixed v2.5.0.
% Domain   : Medial algebras
% Problem  : Cancellative medial algebras
% Version  : [MP96] (equality) axioms.
% English  : We prove a property of cancellative medial algebras.

% Refs     : [McC98] McCune (1998), Email to G. Sutcliffe
%          : [MP96]  McCune & Padmanabhan (1996), Automated Deduction in Eq
% Source   : [McC98]
% Names    : MED-1 [MP96]

% Status   : Unsatisfiable
% Rating   : 0.50 v3.3.0, 0.44 v3.2.0, 0.67 v3.1.0, 0.40 v2.7.0, 0.50 v2.6.0, 0.40 v2.5.0
% Syntax   : Number of clauses     :    5 (   0 non-Horn;   3 unit;   4 RR)
%            Number of atoms       :    9 (   9 equality)
%            Maximal clause size   :    3 (   2 average)
%            Number of predicates  :    1 (   0 propositional; 2-2 arity)
%            Number of functors    :    8 (   7 constant; 0-2 arity)
%            Number of variables   :   12 (   0 singleton)
%            Maximal term depth    :    4 (   2 average)

% Comments : 
% Bugfixes : v2.5.0 - Fixed clause idempotent_element.
%--------------------------------------------------------------------------
%----Left and right cancellation:
cnf(left_cancellation,axiom,
    ( multiply(X,Y) != Z
    | multiply(U,Y) != Z
    | X = U )).

cnf(right_cancellation,axiom,
    ( multiply(X,Y) != Z
    | multiply(X,U) != Z
    | Y = U )).

%----Medial law:
cnf(medial_law,axiom,
    ( multiply(multiply(X,Y),multiply(Z,U)) = multiply(multiply(X,Z),multiply(Y,U)) )).

%----There is an idempotent element:
cnf(idempotent_element,hypothesis,
    ( multiply(an_element,an_element) = an_element )).

%----Denial of conclusion:
cnf(prove_this,negated_conjecture,
    (  multiply(multiply(a,multiply(d,c)),multiply(multiply(b,e),f)) != multiply(multiply(a,multiply(b,c)),multiply(multiply(d,e),f)) )).

%--------------------------------------------------------------------------
