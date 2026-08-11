"""Ground equality oracle independent of inference rules and clausification."""
import itertools
import random
import unittest
from test_qed import direct


class EqualitySemanticsTests(unittest.TestCase):
    def test_ground_equality_truth_models(self):
        rng=random.Random(931)
        atoms=['p(a)','p(b)','q(a)','q(b)','a = b']
        # With only a,b and unary predicates, these cover every possible
        # ground interpretation, including a=b and its congruence obligations.
        models=[]
        for same in [False,True]:
            for bits in itertools.product([False,True],repeat=4):
                if same and (bits[0]!=bits[1] or bits[2]!=bits[3]):
                    continue
                models.append(dict(zip(atoms,[*bits,same])))
        def generate(depth):
            if not depth or rng.random()<.3:
                return rng.choice(atoms)
            op=rng.choice(['~','&','|','->','<->'])
            return (op,generate(depth-1)) if op=='~' else (op,generate(depth-1),generate(depth-1))
        def show(f):
            if isinstance(f,str): return '('+f+')'
            if f[0]=='~': return '~'+show(f[1])
            return '('+show(f[1])+' '+f[0]+' '+show(f[2])+')'
        def evaluate(f,model):
            if isinstance(f,str): return model[f]
            a=evaluate(f[1],model)
            if f[0]=='~': return not a
            b=evaluate(f[2],model)
            return {'&':a and b,'|':a or b,'->':not a or b,'<->':a==b}[f[0]]
        for i in range(160):
            premises=[generate(2),generate(2)];goal=generate(2)
            expected=all(not all(evaluate(p,m) for p in premises) or evaluate(goal,m) for m in models)
            with self.subTest(case=i):
                result=direct(list(map(show,premises)),show(goal))
                self.assertEqual(result['status'],'proved' if expected else 'not_entailed')
                self.assertEqual(result['proof_checked'],expected)
