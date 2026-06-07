%--------------------------------------------------------------------------
% File     : ALG001-1 : TPTP v3.3.0. Released v1.0.0.
% Domain   : General Algebra
% Problem  : The composition of homomorphisms is a homomorphism
% Version  : [BL+86] axioms : Augmented.
% English  : 

% Refs     : [BL+86] Boyer et al. (1986), Set Theory in First-Order Logic: 
% Source   : [BL+86]
% Names    : Problem 221-223 [BL+86]

% Status   : Unsatisfiable
% Rating   : 1.00 v2.0.0
% Syntax   : Number of clauses     :  171 (  20 non-Horn;  19 unit; 139 RR)
%            Number of atoms       :  430 (  60 equality)
%            Maximal clause size   :    8 (   3 average)
%            Number of predicates  :   14 (   0 propositional; 1-5 arity)
%            Number of functors    :   67 (  14 constant; 0-5 arity)
%            Number of variables   :  388 (  36 singleton)
%            Maximal term depth    :    4 (   1 average)

% Comments : Augmented with previous lemmas.
%--------------------------------------------------------------------------
%----Include Godel's set axioms 
include('Axioms/SET003-0.ax').
%--------------------------------------------------------------------------
cnf(first_components_are_equal,axiom,
    ( ~ little_set(X)
    | ~ little_set(U)
    | ordered_pair(X,Y) != ordered_pair(U,V)
    | X = U )).

cnf(left_cancellation,axiom,
    ( ~ little_set(X)
    | ~ little_set(Y)
    | non_ordered_pair(Z,X) != non_ordered_pair(Z,Y)
    | X = Y )).

cnf(second_components_are_equal,axiom,
    ( ~ little_set(X)
    | ~ little_set(Y)
    | ~ little_set(U)
    | ~ little_set(V)
    | ordered_pair(X,Y) != ordered_pair(U,V)
    | Y = V )).

cnf(two_sets_equal,axiom,
    ( ~ subset(X,Y)
    | ~ subset(Y,X)
    | X = Y )).

cnf(property_of_first,axiom,
    ( ~ little_set(X)
    | ~ little_set(Y)
    | first(ordered_pair(X,Y)) = X )).

cnf(property_of_second,axiom,
    ( ~ little_set(X)
    | ~ little_set(Y)
    | second(ordered_pair(X,Y)) = Y )).

cnf(first_component_is_small,axiom,
    ( ~ ordered_pair_predicate(X)
    | little_set(first(X)) )).

cnf(second_component_is_small,axiom,
    ( ~ ordered_pair_predicate(X)
    | little_set(second(X)) )).

cnf(property_of_singleton_sets,axiom,
    ( ~ little_set(X)
    | member(X,singleton_set(X)) )).

cnf(ordered_pairs_are_small1,axiom,
    ( little_set(ordered_pair(X,Y)) )).

cnf(ordered_pairs_are_small2,axiom,
    ( ~ ordered_pair_predicate(X)
    | little_set(X) )).

cnf(containment_is_transitive,axiom,
    ( ~ subset(X,Y)
    | ~ subset(Y,Z)
    | subset(X,Z) )).

cnf(image_and_apply1,axiom,
    ( subset(apply(Xf,Y),sigma(image(singleton_set(Y),Xf))) )).

cnf(image_and_apply2,axiom,
    ( subset(image(singleton_set(Y),Xf),apply(Xf,Y)) )).

cnf(function_values_are_small,axiom,
    ( ~ function(Y)
    | little_set(apply(Y,X)) )).

cnf(composition_is_a_relation,axiom,
    ( relation(compose(Y,X)) )).

cnf(range_of_composition,axiom,
    ( subset(range_of(compose(Y,X)),range_of(Y)) )).

cnf(domain_of_composition,axiom,
    ( ~ subset(range_of(X),domain_of(Y))
    | domain_of(X) = domain_of(compose(Y,X)) )).

cnf(composition_is_a_function,axiom,
    ( ~ function(X)
    | ~ function(Y)
    | function(compose(Y,X)) )).

cnf(maps_for_composition,axiom,
    ( ~ maps(Xf,U,V)
    | ~ maps(Xg,V,W)
    | maps(compose(Xg,Xf),U,W) )).

cnf(apply_for_functions1,axiom,
    ( ~ little_set(X)
    | ~ little_set(Y)
    | ~ function(Xf)
    | ~ member(ordered_pair(X,Y),Xf)
    | apply(Xf,X) = Y )).

cnf(apply_for_functions2,axiom,
    ( ~ function(Xf)
    | ~ member(X,domain_of(Xf))
    | apply(Xf,X) != Y
    | member(ordered_pair(X,Y),Xf) )).

cnf(apply_for_functions3,axiom,
    ( ~ maps(Xf,Xd,Xr)
    | ~ member(X,Xd)
    | member(apply(Xf,X),Xr) )).

cnf(apply_for_composition1,axiom,
    ( ~ function(Xf)
    | ~ member(X,domain_of(Xf))
    | subset(apply(Xg,apply(Xf,X)),apply(compose(Xg,Xf),X)) )).

cnf(apply_for_composition2,axiom,
    ( ~ function(Xf)
    | subset(apply(compose(Xg,Xf),X),apply(Xg,apply(Xf,X))) )).

cnf(apply_for_composition3,axiom,
    ( ~ function(Xf)
    | ~ member(X,domain_of(Xf))
    | apply(Xg,apply(Xf,X)) = apply(compose(Xg,Xf),X) )).

cnf(ordered_pair_in_cross_product,axiom,
    ( ~ member(X,Xs1)
    | ~ member(Y,Xs2)
    | member(ordered_pair(X,Y),cross_product(Xs1,Xs2)) )).

cnf(one_homomorphism,hypothesis,
    ( homomorphism(f60,f62,f63,f64,f65) )).

cnf(another_homomorphism,hypothesis,
    ( homomorphism(f61,f64,f65,f66,f67) )).

cnf(prove_composition_is_a_homomorphism,negated_conjecture,
    ( ~ homomorphism(compose(f60,f61),f62,f63,f66,f67) )).

%--------------------------------------------------------------------------
