# Monero Amount Hiding {#chapter:pedersen-commitments}

In most cryptocurrencies like Bitcoin, transaction output notes, which
give spending rights to 'amounts' of money, communicate those amounts in
clear text. This allows observers to easily verify the amount spent
equals the amount sent.

In Monero we use *commitments* to hide output amounts from everyone
except senders and receivers, while still giving observers confidence
that a transaction sends no more or less than what is spent. As we will
see, amount commitments must also have corresponding 'range proofs'
which prove the hidden amount is within a legitimate range.

## Commitments {#sec:commitments}

Generally speaking, a cryptographic *commitment scheme* is a way of
committing to a value without revealing the value itself. After
committing to something, you are stuck with it.

For example, in a coin-flipping game Alice could privately commit to one
outcome (i.e. 'call it') by hashing her committed value with secret data
and publishing the hash. After Bob flips the coin, Alice declares which
value she committed to and proves it by revealing the secret data. Bob
could then verify her claim.

In other words, assume that Alice has a secret string $blah$ and the
value she wants to commit to is $heads$. She hashes
$h = \mathcal{H}(blah, heads)$ and gives $h$ to Bob. Bob flips a coin,
then Alice tells Bob the secret string $blah$ and that she committed to
$heads$. Bob calculates $h’ = \mathcal{H}(blah, heads)$. If $h' = h$,
then he knows Alice called $heads$ before the coin flip.

Alice uses the so-called 'salt', $blah$, so Bob can't just guess
$\mathcal{H}(heads)$ and $\mathcal{H}(tails)$ before his coin flip, and
figure out she committed to $heads$.[^1]

## Pedersen commitments {#pedersen_section}

A *Pedersen commitment* [@Pedersen1992] is a commitment that has the
property of being *additively homomorphic*. If $C(a)$ and $C(b)$ denote
the commitments for values $a$ and $b$ respectively, then
$C(a + b) = C(a) + C(b)$.[^2] This property will be useful when
committing transaction amounts, as one can prove, for instance, that
inputs equal outputs, without revealing the amounts at hand.\
Fortunately, Pedersen commitments are easy to implement with elliptic
curve cryptography, as the following holds trivially
$$a G + b G = (a + b) G$$

Clearly, by defining a commitment as simply $C(a) = a G$, we could
easily create cheat tables of commitments to help us recognize common
values of $a$.

To attain information-theoretic privacy, one needs to add a secret
*blinding factor* and another generator $H$, such that it is unknown for
which value of $\gamma$ the following holds: $H = \gamma G$. The
hardness of the discrete logarithm problem ensures calculating $\gamma$
from $H$ is infeasible.[^3]

We can then define the commitment to a value $a$ as
$C(x, a) = x G + a H$, where $x$ is the blinding factor (a.k.a. 'mask')
that prevents observers from guessing $a$.

Commitment $C(x, a)$ is information-theoretically private because there
are many possible combinations of $x$ and $a$ that would output the same
$C$.[^4] If $x$ is truly random, an attacker would have literally no way
to figure out $a$ [@maxwell-ct; @SCOZZAFAVA1993313].

## Amount commitments {#sec:pedersen_monero}

In Monero, output amounts are stored in transactions as Pedersen
commitments. We define a commitment to an output's amount $b$ as:
$$C(y,b) = y G + b H\marginnote{src/ringct/ rctOps.cpp {\tt addKeys2()}}$$

Recipients should be able to know how much money is in each output they
own, as well as reconstruct the amount commitments, so they can be used
as the inputs to new transactions. This means the blinding factor $y$
and amount $b$ must be communicated to the receiver.

The solution adopted is a Diffie-Hellman shared secret $r K_B^v$ using
the 'transaction public key' (recall Section
[\[sec:multi_out_transactions\]](#sec:multi_out_transactions){reference-type="ref"
reference="sec:multi_out_transactions"}). For any given transaction in
the blockchain, each of its outputs $t \in \{0, ..., p-1\}$ has a mask
$y_t$ that senders and receivers can privately compute, and an *amount*
stored in the transaction's data. While $y_t$ is an elliptic curve
scalar and occupies 32 bytes, $b$ will be restricted to 8 bytes by the
range proof so only an 8 byte value needs to be
stored.[^5][^6]\[.725cm\] $$\begin{aligned}
  y_t &= \mathcal{H}_n(``commitment\_mask",\mathcal{H}_n(r K_B^v, t)) \\
  \mathit{amount}_t &= b_t \oplus_8 \mathcal{H}_n(``amount”, \mathcal{H}_n(r K_B^v, t))\end{aligned}$$

Here, $\oplus_8$ means to perform an XOR operation (Section
[\[sec:XOR_section\]](#sec:XOR_section){reference-type="ref"
reference="sec:XOR_section"}) between the first 8 bytes of each operand
($b_t$ which is already 8 bytes, and $\mathcal{H}_n(...)$ which is 32
bytes). Recipients can perform the same XOR operation on
$\mathit{amount}_t$ to reveal $b_t$.

The receiver Bob will be able to calculate the blinding factor $y_t$ and
the amount $b_t$ using the transaction public key $r G$ and his view key
$k_B^v$. He can also check that the commitment $C(y_t, b_t)$ provided in
the transaction data, henceforth denoted $C_t^b$, corresponds to the
amount at hand.\
More generally, any third party with access to Bob's view key could
decrypt his output amounts, and also make sure they agree with their
associated commitments.

## RingCT introduction {#sec:ringct-introduction}

A transaction will contain references to other transactions' outputs
(telling observers which old outputs are to be spent), and its own
outputs. The content of an output includes a one-time address (assigning
ownership of the output) and an output commitment hiding the amount
(also the encoded output amount from Section
[1.3](#sec:pedersen_monero){reference-type="ref"
reference="sec:pedersen_monero"}).

While a transaction's verifiers don't know how much money is contained
in each input and output, they still need to be sure the sum of input
amounts equals the sum of output amounts. Monero uses a technique called
RingCT [@MRL-0005-ringct], first implemented in January 2017 (v4 of the
protocol), to accomplish this.

If we have a transaction with $m$ inputs containing amounts
$a_1, ..., a_m$, and $p$ outputs with amounts $b_0, ..., b_{p-1}$, then
an observer would justifiably expect that:[^7]
$$\sum_j a_j - \sum_t b_t = 0$$

Since commitments are additive and we don't know $\gamma$, we could
easily prove our inputs equal outputs to observers by making the sum of
commitments to input and output amounts equal zero (i.e. by setting the
sum of output blinding factors equal to the sum of old input blinding
factors):[^8] $$\sum_{j}{C_{j, in}} - \sum_{t}{C_{t, out}} = 0$$

To avoid sender identifiability we use a slightly different approach.
The amounts being spent correspond to the outputs of previous
transactions, which had commitments $$C^a_{j} = x_j G + a_j H$$

The sender can create new commitments to the same amounts but using
different blinding factors; that is, $$C'^a_{j} = x'_j G + a_j H$$

Clearly, she would know the private key of the difference between the
two commitments: $$C^a_{j} - C'^a_{j} = (x_j - x'_j) G$$\
Hence, she would be able to use this value as a *commitment to zero*,
since she can make a signature with the private key $(x_j - x'_j) = z_j$
and prove there is no $H$ component to the sum (assuming $\gamma$ is
unknown). In other words prove that $C^a_{j} - C'^a_{j} = z_j G + 0H$,
which we will actually do in Chapter
[\[chapter:transactions\]](#chapter:transactions){reference-type="ref"
reference="chapter:transactions"} when we discuss the structure of
RingCT transactions.

Let us call $C'^a_j$ a *pseudo output commitment*. Pseudo output
commitments are included in transaction data, and there is one for each
input.

Before committing a transaction to the blockchain, the network will want
to verify that its amounts balance. Blinding factors for pseudo and
output commitments are selected such that
$$\sum_j x'_j  - \sum_t y_t = 0$$

This allows us to prove input amounts equal output amounts:
$$(\sum_j C'^a_{j} - \sum_t C^b_{t}) = 0$$

Fortunately, choosing such blinding factors is easy. In the current
version of Monero, all blinding factors are random except for the
$m$pseudo out commitment, where $x'_m$ is simply
$$x'_m = \sum_t y_t - \sum_{j=1}^{m-1} x'_j$$

## Range proofs {#sec:range_proofs}

One problem with additive commitments is that, if we have commitments
$C(a_1)$, $C(a_2)$, $C(b_1)$, and $C(b_2)$ and we intend to use them to
prove that $(a_1 + a_2) - (b_1 + b_2) = 0$, then those commitments would
still apply if one value in the equation were 'negative'.

For instance, we could have $a_1 = 6$, $a_2 = 5$, $b_1 = 21$, and
$b_2 = -10$.

&& (6 + 5) - (&21 + -10) = 0&\
&& 21G + -10G = 21G + (&l-10)G = (l + 11)G = 11G&

Since $-10 = l-10$, we have effectively created $l$ more Moneroj (over
7.2x10$^{74}$!) than we put in.

The solution addressing this issue in Monero is to prove each output
amount is in a certain range (from 0 to $2^{64}-1$) using the
Bulletproofs proving scheme first described by Benedikt Bünz *et al.* in
[@Bulletproofs_paper] (and also explained in
[@adam-zero-to-bulletproofs; @dalek-bulletproofs-notes]).[^9] Given the
involved and intricate nature of Bulletproofs, it is not elucidated in
this document. Moreover we feel the cited materials adequately present
its concepts.[^10]

The Bulletproof proving algorithm takes as input output amounts $b_t$
and commitment masks $y_t$, and outputs all $C^b_t$ and an $n$-tuple
aggregate proof
$\Pi_{BP} = (A, S, T_1, T_2, \tau_x, \mu, \mathbb{L}, \mathbb{R}, a, b, t)$[^11][^12].
That single proof is used to prove all output amounts are in range at
the same time, as aggregating them greatly reduces space requirements
(although it does increase the time to verify).[^13] The verification
algorithm takes as input all $C^b_t$, and $\Pi_{BP}$, and outputs `true`
if all committed amounts are in the range 0 to $2^{64} - 1$.

The $n$-tuple $\Pi_{BP}$ occupies
$(2 \cdot \lceil \textrm{log}_2(64 \cdot p) \rceil + 9) \cdot 32$ bytes
of storage.

[^1]: If the committed value is very difficult to guess and check, e.g.
    if it's an apparently random elliptic curve point, then salting the
    commitment isn't necessary.

[^2]: Additively homomorphic in this context means addition is preserved
    when you transform scalars into EC points by applying, for scalar
    $x$, $x \rightarrow x G$.

[^3]: In the case of Monero, $H = 8*to\_point(\mathcal{H}_n(G))$. This
    differs from the $\mathcal{H}_p$ hash function in that it directly
    interprets the output of $\mathcal{H}_n(G)$ as a compressed point
    coordinate instead of deriving a curve point mathematically (see
    [@hashtopoint-writeup]). The historical reasons for this discrepancy
    are unknown to us, and indeed this is the only place where
    $\mathcal{H}_p$ is not used (Bulletproofs also use $\mathcal{H}_p$).
    Note how there is a $*8$ operation, to ensure the resultant point is
    in our $l$ subgroup ($\mathcal{H}_p$ also does that).

[^4]: Basically, there are many $x’$ and $a’$ such that
    $x’+a’ \gamma = x+a \gamma$. A committer knows one combination, but
    an attacker has no way to know which one. This property is also
    known as 'perfect hiding' [@adam-zero-to-bulletproofs]. Furthermore,
    even the committer can't find another combination without solving
    the DLP for $\gamma$, a property called 'computational binding'
    [@adam-zero-to-bulletproofs].

[^5]: As with the one-time address $K^o$ from Section
    [\[sec:one-time-addresses\]](#sec:one-time-addresses){reference-type="ref"
    reference="sec:one-time-addresses"}, the output index $t$ is
    appended to the shared secret before hashing. This ensures outputs
    directed to the same address do not have similar masks and
    *amounts*, except with negligible probability. Also like before, the
    term $r K^v_B$ is multiplied by 8, so it's really $8rK^v_B.$

[^6]: This solution (implemented in v10 of the protocol) replaced a
    previous method that used more data, thereby causing the transaction
    type to change from v3 (`RCTTypeBulletproof`) to v4
    (`RCTTypeBulletproof2`). The first edition of this report discussed
    the previous method [@ztm-1].

[^7]: If the intended total output amount doesn't precisely equal any
    combination of owned outputs, then transaction authors can add a
    'change' output sending extra money back to themselves. By analogy
    to cash, with a 20\$ bill and 15\$ expense you will receive 5\$ back
    from the cashier.

[^8]: Recall from Section
    [\[elliptic_curves_section\]](#elliptic_curves_section){reference-type="ref"
    reference="elliptic_curves_section"} we can subtract a point by
    inverting its coordinates then adding it. If $P = (x, y)$,
    $-P = (-x, y)$. Recall also that negations of field elements are
    calculated$\pmod q$, so $(–x \pmod q)$.

[^9]: It's conceivable that with several outputs in a legitimate range,
    the sum of their amounts could roll over and cause a similar
    problem. However, when the maximum output is much smaller than $l$
    it takes a huge number of outputs for that to happen. For example,
    if the range is 0-5, and l = 99, then to counterfeit money using an
    input of 2, we would need
    $5 + 5 + …. + 5 + 1 = 101 \equiv 2 \pmod{99}$, for 21 total outputs.
    In Monero $l$ is about 2\^189 times bigger than the available range,
    which means a ridiculous 2\^189 outputs to counterfeit money.

[^10]: Prior to protocol v8 range proofs were accomplished with
    Borromean ring signatures, which were explained in the first edition
    of Zero to Monero [@ztm-1].

[^11]: Vectors $\mathbb{L}$ and $\mathbb{R}$ contain
    $\lceil \textrm{log}_2(64 \cdot p) \rceil$ elements each. $\lceil$
    $\rceil$ means the log function is rounded up. Due to their
    construction, some Bulletproofs use 'dummy outputs' as padding to
    ensure $p$ plus the number of dummy outputs is a power of 2. Those
    dummy outputs can be generated during verification, and are not
    stored with the proof data.

[^12]: The variables in a Bulletproof are unrelated to other variables
    in this document. Symbol overlap is merely coincidental. Note that
    group elements $A, S, T_1, T_2, \mathbb{L},$ and $\mathbb{R}$ are
    multiplied by 1/8 before being stored, then multiplied by 8 during
    verification. This ensures they are all members of the $l$ sub-group
    (recall Section
    [\[elliptic_curves_section\]](#elliptic_curves_section){reference-type="ref"
    reference="elliptic_curves_section"}).

[^13]: It turns out multiple separate Bulletproofs can be 'batched'
    together, which means they are verified simultaneously. Doing so
    improves how long it takes to verify them, and currently in Monero
    Bulletproofs are batched on a per-block basis, although there is no
    theoretical limit to how many can be batched together. Each
    transaction is only allowed to have one Bulletproof.
