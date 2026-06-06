import unittest
import tptp
class AdapterEdges(unittest.TestCase):
 def test_biconditional(self):
  self.assertEqual(tptp.parse("fof(g,conjecture,(p <=> p)).")["goal"],"(p <=> p)")
 def test_reserved_word(self):
  with self.assertRaises(tptp.Unsupported): tptp.parse("fof(g,conjecture,true).")
