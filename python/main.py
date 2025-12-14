class DiffieHellman:
    def __init__(self, p, g):
        # public parameters
        self.p = p # prime number
        self.g = g # generator in Fp

        # public keys
        self.kA = None
        self.kB = None

        # private keys
        self.cA = None
        self.cB = None

        # shared secret
        self.d = None

    def set_private_keys(self, kA, kB):
        self.kA = kA
        self.kB = kB

    def compute_public_keys(self):
        self.cA = pow(self.g, self.kA, self.p)
        self.cB = pow(self.g, self.kB, self.p)

    def compute_shared_secret(self):
        d1 = pow(self.cA, self.kB, self.p)
        d2 = pow(self.cB, self.kA, self.p)

        assert d1 == d2, "Secrets do not match!"
        self.d = d1

class Group:
    """
    Mathematical group (G, *, e).

    A group consists of:
    - a non-empty finite set G,
    - a binary operation * : G × G → G,
    - an identity element e ∈ G,

    satisfying the axioms:
    1) Associativity: (a * b) * c = a * (b * c)
    2) Identity:      a * e = e * a = a
    3) Inverse:       for every a ∈ G there exists a⁻¹ ∈ G such that
                      a * a⁻¹ = a⁻¹ * a = e

    This class represents a finite group by explicitly storing
    its elements and the group operation.
    """

    def __init__(self, elements, operation, identity):
        """
        @elements: set G
        @operation: operation on any of two elements of set G
        @identity: neutral element of set G
        """
        self._G = set(elements)
        self._op = operation
        self._e = identity

    def elements(self):
        return self._G

    def identity(self):
        return self._e

    def order(self):
        return len(self._G)

    def op(self, a, b):
        return self._op(a, b)

    def inverse(self, a):
        for b in self._G:
            if self._op(a, b) == self._e:
                return b
        raise ValueError(f"No inverse of {a} in set {self._G}!")

def mul_mod_p(a, b, p=7):
    return (a * b) % p

def main():
    G = {1, 2, 3, 4, 5, 6, 14}
    group = Group(G, lambda a, b: mul_mod_p(a, b, 7), 1)
    print("G =", group.elements())
    print("e =", group.identity())
    print("|G| =", group.order())

    for a in G:
        inv = group.inverse(a)
        print(f"{a}^-1 =", inv, " check:", group.op(a, inv))

if __name__=="__main__":
    main()
