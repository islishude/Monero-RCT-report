# Monero Transaction-Related Knowledge Proofs {#chapter:tx-knowledge-proofs}

https://github.com/monero-project/monero/pull/6329/files

https://monero.stackexchange.com/questions/8122/what-is-the-spendproofv1-or-outproofv1-in-the-details-of-a-sent-transa

https://monero.stackexchange.com/questions/9991/how-does-the-get-reserve-proof-command-work

https://github.com/monero-project/research-lab/issues/68

Monero is a currency, and like any currency its uses are complex. From
corporate accounting, to market exchange, to legal arbitration,
different interested parties may want to know detailed information about
transactions made.

How can you know for sure that money you received came from a specific
person? Or prove that you did in fact send a certain output or
transaction to someone despite claims to the contrary? Senders and
recipients in the Monero public ledger are ambiguous. How can you prove
you have a certain amount of money, without compromising your private
keys? Amounts in Monero are completely hidden from observers.

We consider several types of transaction assertions, a few of which are
implemented in Monero and available with built-in wallet tools. We also
outline a framework for auditing the full balance owned by a person or
organization, that doesn't require leaking information about future
transactions they might make.

## Transaction proofs in Monero {#sec:proofs-monero-proofs}

Monero transaction proofs are in the process of being updated
[@sarang-txproofs-updates-issue]. The currently implemented proofs are
all 'version 1', and don't include domain separation. We describe only
the most advanced proofs, whether they be currently implemented, slated
for implementation in future releases [@sarang-txproofs-v2-update-pr],
or hypothetical proofs that may or may not get implemented (Sections
[1.1.5](#subsec:proofs-owned-output-spent-unspentproof){reference-type="ref"
reference="subsec:proofs-owned-output-spent-unspentproof"}
[@unspent-proof-issue-68], and
[1.2.1](#subsec:proofs-address-subaddress-correspond-subaddressproof){reference-type="ref"
reference="subsec:proofs-address-subaddress-correspond-subaddressproof"}).

### Multi-base Monero transaction proofs {#subsec:proofs-multi-base-monero}

There are a few details to be aware of going forward. Most Monero
transaction proofs involve multi-base proofs (recall Section
[\[sec:proofs-discrete-logarithm-multiple-bases\]](#sec:proofs-discrete-logarithm-multiple-bases){reference-type="ref"
reference="sec:proofs-discrete-logarithm-multiple-bases"}). Wherever
relevant, the domain separator is
$T_{txprf2} = \mathcal{H}_n(``\textrm{TXPROOF\_V2}")$.[^1] The message
being signed is usually (unless otherwise specified)
$\mathfrak{m} = \mathcal{H}_n(\texttt{tx\_hash, \texttt{message}})$,
where `tx_hash` is the relevant transaction's ID (Section
[\[subsec:transaction-id\]](#subsec:transaction-id){reference-type="ref"
reference="subsec:transaction-id"}), and `message` is an optional
message that provers or third parties can provide to make sure the
prover actually makes a proof and hasn't stolen it.

Proofs are encoded in base-58, a binary-to-text encoding scheme first
introduced for Bitcoin [@base-58-encoding]. Verifying these proofs
always involves first decoding them from base-58 back to binary. Note
that verifiers also need access to the blockchain, so they can use
transaction ID references to get information like one-time
addresses.[^2]\
The structure of key prefixing in proofs is somewhat lopsided, due in
part to accumulating updates that haven't reorganized it. Challenges for
2-base 'version 2' proofs are assembled with this format, where if 'base
key 1' is $G$ then its position in the challenge is filled with 32 zero
bytes,
$$c = \mathcal{H}_n(\mathfrak{m}\textrm{, public key 2, proof part 1, proof part 2, $T_{txprf2}$, public key 1, base key 2, base key 1})$$

### Prove creation of a transaction input (`SpendProofV1`) {#subsec:proofs-input-creation-spendproof}

Suppose we made a transaction, and want to prove it. Clearly, by
remaking a transaction input's signature on a new message, any verifier
would have no choice but to conclude we made the original. Remaking
*all* of a transaction's inputs' signatures means we must have made the
entire transaction (recall Section
[\[full-signature\]](#full-signature){reference-type="ref"
reference="full-signature"}), or at the very least fully funded it.[^3]

A so-called 'SpendProof' contains remade signatures for all of a
transaction's inputs. Importantly, SpendProof ring signatures re-use the
original ring members to avoid identifying the true signer via ring
intersections.

SpendProofs are implemented in Monero, and to encode one for
transmission to verifiers, the prover concatenates the prefix string
"`SpendProofV1`\" with the list of signatures. Note that the prefix
string is not in base-58 and doesn't need to be encoded/decoded, since
its purpose is human readability.

#### The SpendProof {#the-spendproof .unnumbered}

SpendProofs unexpectedly don't use MLSAGs, but rather Monero's original
ring signature scheme that was used in the very first transaction
protocol (pre-RingCT) [@cryptoNoteWhitePaper].

1.  Calculate key image $\tilde{K} = k^o_\pi \mathcal{H}_p(K^o_\pi)$.

2.  Generate random number $\alpha \in_R \mathbb{Z}_l$ and random
    numbers $c_i, r_i \in_R \mathbb{Z}_l$ for $i \in \{1, 2, ..., n\}$
    but excluding $i = \pi$.

3.  Compute
    $$c_{tot} = \mathcal{H}_n(\mathfrak{m},[r_1 G + c_1 K^o_1],[r_1 \mathcal{H}_p(K^o_1) + c_1 \tilde{K}],...,[\alpha G],[\alpha \mathcal{H}_p(K^o_{\pi})],...,\textrm{etc.})$$

4.  Define the real challenge
    $$c_{\pi} = c_{tot} - \sum^{n}_{i=1,i\neq \pi} c_i$$

5.  Define $r_{\pi} = \alpha - c_{\pi}*k^o_{\pi} \pmod l$.

The signature is $\sigma = (c_1, r_1,c_2,r_2,...,c_n,r_n)$.

#### Verification {#verification .unnumbered}

To verify a SpendProof on a given transaction, the verifier confirms
that all ring signatures are valid using information found in the
relevant reference transaction (e.g. key images, and output offsets for
getting one-time addresses from other transactions).

1.  Compute
    $$c_{tot} = \mathcal{H}_n(\mathfrak{m},[r_1 G + c_1 K^o_1],[r_1 \mathcal{H}_p(K^o_1) + c_1 \tilde{K}],...,[r_n G + c_n K^o_n],[r_n \mathcal{H}_p(K^o_n) + c_n \tilde{K}])$$

2.  Check that $$c_{tot} \stackrel{?}{=} \sum^{n}_{i=1} c_i$$

#### Why it works {#why-it-works .unnumbered}

Note how this scheme is the same as bLSAG (Section
[\[blsag_note\]](#blsag_note){reference-type="ref"
reference="blsag_note"}) when there is only one ring member. To add a
fake member, instead of passing the challenge $c_{\pi+1}$ into a new
challenge hash, the member gets added into the original hash. Since the
following equation $$c_{s} = c_{tot} - \sum^{n}_{i=1,i\neq s} c_i$$

trivially holds for any index $s$, a verifier will have no way to
identify the real challenge. Moreover, without knowledge of $k^o_{\pi}$
the prover would never have been able to define $r_{\pi}$ properly
(except with negligible probability).

### Prove creation of a transaction output (`OutProofV2`) {#subsec:proofs-output-creator-outproof}

Now suppose we sent someone money (an output) and want to prove it.
Transaction outputs contain at heart three components: the recipient's
address, the amount sent, and the transaction private key. Amounts are
encoded, so we only really need the address and transaction private key
to get started. Anyone who deletes or loses their transaction private
key will be unable to make an OutProof, so in that sense OutProofs are
the least reliable of all Monero transaction proofs.[^4]

Our task here is to show the one-time address was made from the
recipient's address, and allow verifiers to reconstruct the output
commitment. We do so by providing the sender-receiver shared secret
$rK^v$, then proving we created it and that it corresponds with the
transaction public key and recipient's address by signing a 2-base
signature (Section
[\[sec:proofs-discrete-logarithm-multiple-bases\]](#sec:proofs-discrete-logarithm-multiple-bases){reference-type="ref"
reference="sec:proofs-discrete-logarithm-multiple-bases"}) on the base
keys $G$ and $K^v$. Verifiers can use the shared secret to check the
recipient (Section
[\[sec:one-time-addresses\]](#sec:one-time-addresses){reference-type="ref"
reference="sec:one-time-addresses"}), decode the amount (Section
[\[sec:pedersen_monero\]](#sec:pedersen_monero){reference-type="ref"
reference="sec:pedersen_monero"}), and reconstruct the output commitment
(Section
[\[sec:pedersen_monero\]](#sec:pedersen_monero){reference-type="ref"
reference="sec:pedersen_monero"}). We provide details for both normal
addresses and subaddresses.

#### The OutProof {#the-outproof .unnumbered}

To generate a proof for an output directed to an address $(K^{v},K^{s})$
or subaddress $(K^{v,i},K^{s,i})$, with transaction private key $r$,
where the sender-receiver shared secret is $rK^v$, recall that the
transaction public key stored in transaction data is either $rG$ or
$rK^{s,i}$ depending on whether or not the recipient is a subaddress
(Section [\[sec:subaddresses\]](#sec:subaddresses){reference-type="ref"
reference="sec:subaddresses"}).

1.  Generate random number $\alpha \in_R \mathbb{Z}_l$, and compute

    1.  *Normal address*: $\alpha G$ and $\alpha K^v$

    2.  *Subaddress*: $\alpha K^{s,i}$ and $\alpha K^{v,i}$

2.  Calculate the challenge

    1.  *Normal address*:[^5]
        $$c = \mathcal{H}_n(\mathfrak{m},[rK^v], [\alpha G], [\alpha K^v], [T_{txprf2}], [rG], [K^v], [0])$$

    2.  *Subaddress*:
        $$c = \mathcal{H}_n(\mathfrak{m},[rK^{v,i}], [\alpha K^{s,i}], [\alpha K^{v,i}], [T_{txprf2}], [rK^{s,i}], [K^{v,i}], [K^{s,i}])$$

3.  Define the response[^6] $r^{resp} = \alpha - c*r$.

4.  The signature is $\sigma^{outproof} = (c, r^{resp})$.

A prover can generate a bunch of OutProofs, and send them all together
to a verifier. He concatenates prefix string "`OutProofV2`\" with a list
of proofs, where each item (encoded in base-58) consists of the
sender-receiver shared secret $r K^v$ (or $r K^{v,i}$ for a subaddress),
and its corresponding $\sigma^{outproof}$. We assume the verifier knows
the appropriate address for each proof.

#### Verification {#verification-1 .unnumbered}

1.  Calculate the challenge

    1.  *Normal address*:
        $$c' = \mathcal{H}_n(\mathfrak{m},[rK^v], [r^{resp} G + c*r G], [r^{resp} K^v + c*r K^v], [T_{txprf2}], [rG], [K^v], [0])$$

    2.  *Subaddress*:
        $$c' = \mathcal{H}_n(\mathfrak{m},[rK^{v,i}], [r^{resp} K^{s,i} + c*r K^{s,i}], [r^{resp} K^{v,i} + c*r K^{v,i}], [T_{txprf2}], [rK^{s,i}], [K^{v,i}], [K^{s,i}])$$

2.  If $c = c'$ then the prover knows $r$, and $rK^v$ is legitimately a
    shared secret between $r G$ and $K^v$ (except with negligible
    probability).

3.  The verifier should check the recipient's address provided can be
    used to make a one-time address from the relevant transaction (it's
    the same computation for normal addresses and subaddresses)
    $$K^s \stackrel{?}{=} K^o_t - \mathcal{H}_n(r K^v,t)$$

4.  They should also decode the output amount $b_t$, compute the output
    mask $y_t$, and try to reconstruct the corresponding output
    commitment[^7] $$C^b_t \stackrel{?}{=} y_t G + b_t H$$

### Prove ownership of an output (`InProofV2`) {#subsec:proofs-output-ownership-inproof}

An OutProof shows the prover sent an output to an address, while an
InProof shows an output was received to a certain address. It is
essentially the other 'side' of the sender-receiver shared secret
$r K^v$. This time the prover proves knowledge of $k^v$ in $K^v$, and
that in combination with the transaction public key $r G$ the shared
secret $k^v*r G$ appears.

Once a verifier has $r K^v$, they can check if the corresponding
one-time address is owned by the prover's address with
$K^o - \mathcal{H}_n(k^v*rG,t)*G \stackrel{?}{=} K^s$ (Section
[\[sec:multi_out_transactions\]](#sec:multi_out_transactions){reference-type="ref"
reference="sec:multi_out_transactions"}). By making an InProof for all
transaction public keys on the blockchain, a prover will reveal all his
owned outputs.

Giving the view key directly to a verifier would have the same effect,
but once they have that key the verifier would be able to identify
ownership of outputs to be created in the future. With InProofs the
prover is able to retain control of his private keys, at the cost of the
time it takes to prove (and then verify) each output is owned or
unowned.

#### The InProof {#the-inproof .unnumbered}

An InProof is constructed the same way as an OutProof, except the base
keys are now $\mathcal{J} = \{G, r G\}$, the public keys are
$\mathcal{K} = \{K^v, r K^{v}\}$, and the signing key is $k^v$ instead
of $r$. We will show just the verification step to clarify our meaning.
Note that the order of key prefixing changes ($r G$ and $K^v$ swap
places) to coincide with the different role each key has.

A multitude of InProofs, related to many outputs owned by the same
address, can be sent together to the verifier. They are prefixed with
the string "`InProofV2`\", and each item (encoded in base-58) contains
the sender-receiver shared secret $r K^v$ (or $r K^{v,i}$), and its
corresponding $\sigma^{inproof}$.

#### Verification {#verification-2 .unnumbered}

1.  Calculate the challenge

    1.  *Normal address*:
        $$c' = \mathcal{H}_n(\mathfrak{m},[rK^v], [r^{resp} G + c*K^v], [r^{resp}*r G + c*k^v*r G], [T_{txprf2}], [K^v], [rG], [0])$$

    2.  *Subaddress*:
        $$c' = \mathcal{H}_n(\mathfrak{m},[rK^{v,i}], [r^{resp} K^{s,i} + c*K^{v,i}], [r^{resp}*r K^{s,i} + c*k^v*r K^{s,i}], [T_{txprf2}], [K^{v,i}], [r K^{s,i}], [K^{s,i}])$$

2.  If $c = c'$ then the prover knows $k^v$, and $k^v*r G$ is
    legitimately a shared secret between $K^v$ and $r G$ (except with
    negligible probability).

#### Prove 'full' ownership with the one-time address key {#prove-full-ownership-with-the-one-time-address-key .unnumbered}

While an InProof shows a one-time address was constructed with a
specific address (except with negligible probability), it doesn't
necessarily mean the prover can *spend* that output. Only those who can
spend an output actually own it.

Proving ownership, once an InProof is complete, is as simple as signing
a message with the spend key.[^8]

### Prove an owned output was not spent in a transaction (UnspentProof) {#subsec:proofs-owned-output-spent-unspentproof}

It would seem like proving an output is spent or unspent is as simple as
recreating its key image with a multi-base proof on
$\mathcal{J} = \{G,\mathcal{H}_p(K^o)\}$ and
$\mathcal{K} = \{K^o,\tilde{K}\}$. While this does obviously work,
verifiers must learn the key image, which also reveals when an unspent
output is spent *in the future*.

It turns out we can prove an output wasn't spent in a specific
transaction without revealing the key image. Moreover, we can prove it
is currently unspent *full stop*, by extending this UnspentProof
[@unspent-proof-issue-68] to 'all the transactions where it was included
as a ring member'.[^9]

More specifically, our UnspentProof says that a given key image from a
transaction on the blockchain does, or does not, correspond with a
specific one-time address from its corresponding ring. Incidentally, as
we will see, UnspentProofs go hand-in-hand with InProofs.

#### Setting up an UnspentProof {#setting-up-an-unspentproof .unnumbered}

The verifier of an UnspentProof must know $r K^v$, the sender-receiver
shared secret for a given owned output with one-time address $K^o$ and
transaction public key $r G$. He either knows the view key $k^v$, which
allowed him to calculate $k^v*r G$ and check
$K^o - \mathcal{H}_n(k^v*rG,t)*G \stackrel{?}{=} K^s$ so he knows the
output being tested belongs to the prover (recall Section
[\[sec:one-time-addresses\]](#sec:one-time-addresses){reference-type="ref"
reference="sec:one-time-addresses"}), or the prover provided $r K^v$.
This is where InProofs come in, since with an InProof the verifier can
be assured $r K^v$ legitimately came from the prover's view key, and
corresponds with an owned output, without learning the private view key.

Before verifying an UnspentProof, the verifier will learn the key image
to be tested $\tilde{K}_?$, and checks that its corresponding ring
includes the prover's owned output's one-time address $K^o$. He then
calculates the partial 'spend' image $\tilde{K}^s_?$.
$$\tilde{K}^s_? = \tilde{K}_? - \mathcal{H}_n(r K^v,t)*\mathcal{H}_p(K^o)$$

If the tested key image was created from $K^o$ then the resultant point
will be $\tilde{K}^s_? = k^s*\mathcal{H}_p(K^o)$.

#### The UnspentProof {#the-unspentproof .unnumbered}

Our prover creates two multi-base proofs (recall Section
[\[sec:proofs-discrete-logarithm-multiple-bases\]](#sec:proofs-discrete-logarithm-multiple-bases){reference-type="ref"
reference="sec:proofs-discrete-logarithm-multiple-bases"}). His address,
which owns the output in question, is $(K^v, K^s)$ or
$(K^{v,i}, K^{s,i})$.[^10]

1.  A 3-base proof, where the signing key is $k^s$, and
    $$\begin{aligned}
            \mathcal{J}^{unspent}_3 &= \{[G], [K^s], [\tilde{K}^s_?]\}\\
            \mathcal{K}^{unspent}_3 &= \{[K^s], [k^s*K^s], [k^s*\tilde{K}^s_?]\}
        \end{aligned}$$

2.  A 2-base proof, where the signing key is $k^s*k^s$, and
    $$\begin{aligned}
            \mathcal{J}^{unspent}_2 &= \{[G], [\mathcal{H}_p(K^o)]\}\\
            \mathcal{K}^{unspent}_2 &= \{[k^s*K^s], [k^s*k^s*\mathcal{H}_p(K^o)]\}
        \end{aligned}$$

Along with proofs $\sigma^{unspent}_3$ and $\sigma^{unspent}_2$, the
prover makes sure to communicate the public keys $k^s*K^s$,
$k^s*\tilde{K}^s_?$, and $k^s*k^s*\mathcal{H}_p(K^o)$.

#### Verification {#verification-3 .unnumbered}

1.  Confirm $\sigma^{unspent}_3$ and $\sigma^{unspent}_2$ are
    legitimate.

2.  Make sure the same public key $k^s*K^s$ was used in both proofs.

3.  Check whether $k^s*\tilde{K}^s_?$ and $k^s*k^s*\mathcal{H}_p(K^o)$
    are the same. If they are, the output is spent, and if not it is
    unspent (except with negligible probability).

#### Why it works {#why-it-works-1 .unnumbered}

This seemingly roundabout approach prevents the verifier from learning
$k^s*H_p(K^o)$ for an unspent output, which he could use in combination
with $r K^v$ to compute its real key image, while leaving him confident
the tested key image doesn't correspond to that output.

Proof $\sigma^{unspent}_2$ can be reused for any number of UnspentProofs
involving the same output, although if it actually was spent then only
one is really necessary (i.e. UnspentProofs can also be used to
demonstrate an output is spent). Performing UnspentProofs on all ring
signatures where a given unspent output was referenced should not be
computationally expensive. An output is only likely, over time, to be
included as decoys in on the order of 11 (current ring size) different
rings.

### Prove an address has a minimum unspent balance (`ReserveProofV2`) {#subsec:proofs-minimum-balance-reserveproof}

Despite the privacy leak of revealing an output's key image when it
isn't spent yet, it's still a somewhat useful method and was implemented
in Monero [@reserveproofs-pull-request-3027] before UnspentProofs were
invented [@unspent-proof-issue-68]. Monero's so-called 'ReserveProof' is
used to prove an address owns a minimum amount of money by creating key
images for some unspent outputs.

More specifically, given a minimum balance, the prover finds enough
unspent outputs to cover it, demonstrates ownership with InProofs, makes
key images for them and proves they are legitimately based on those
outputs with 2-base proofs (using a different key prefixing format), and
then proves knowledge of the private spend keys used with normal Schnorr
signatures (there may be more than one if some outputs are owned by
different subaddresses). A verifier can check that the key images have
not appeared on the blockchain, and hence their outputs must be unspent.

#### The ReserveProof {#the-reserveproof .unnumbered}

All the sub-proofs within a ReserveProof sign a different message than
other proofs (e.g. OutProofs, InProofs, or SpendProofs). This time it is
$\mathfrak{m} = \mathcal{H}_n(\texttt{message}, \texttt{address}, \tilde{K}^o_1, ..., \tilde{K}^o_n)$,
where `address` is the encoded form (see [@luigi-address]) of the
prover's normal address $(K^v, K^s)$, and the key images correspond with
unspent outputs to be included in the proof.

1.  Each output has an InProof, which shows the prover's address (or one
    of his subaddresses) owns the output.

2.  Each output's key image is signed with a 2-base proof, where the
    challenge is formatted like this
    $$c = \mathcal{H}_n(\mathfrak{m}, [r G + c*K^o], [r \mathcal{H}_p(K^o) + c*\tilde{K}])$$

3.  Each address (and subaddress) that owns at least one output has a
    normal Schnorr signature (Section
    [\[sec:signing-messages\]](#sec:signing-messages){reference-type="ref"
    reference="sec:signing-messages"}), and the challenge looks like
    (it's the same for normal addresses and subaddresses)
    $$c = \mathcal{H}_n(\mathfrak{m}, K^{s,i}, [r G + c*K^{s,i}])$$

To send a ReserveProof to someone else\[.3cm\], the prover concatenates
prefix string "`ReserveProofV2`\" with two lists encoded in base-58
(e.g. "`ReserveProofV2`, list 1, list 2\"). Each item in list 1 is
related to a specific output and contains its transaction hash (Section
[\[subsec:transaction-id\]](#subsec:transaction-id){reference-type="ref"
reference="subsec:transaction-id"}), output index in that transaction
(Section
[\[sec:multi_out_transactions\]](#sec:multi_out_transactions){reference-type="ref"
reference="sec:multi_out_transactions"}), the relevant shared secret
$r K^v$, its key image, its InProof $\sigma^{inproof}$, and its key
image proof. List 2 items are the addresses that own those outputs along
with their Schnorr signatures.

#### Verification {#verification-4 .unnumbered}

1.  Check the ReserveProof key images have not appeared in the
    blockchain.

2.  Verify the InProof for each output, and that one of the provided
    addresses owns each one.

3.  Verify the 2-base key image signatures.

4.  Use the sender-receiver shared secrets to decode the output amounts
    (Section
    [\[sec:pedersen_monero\]](#sec:pedersen_monero){reference-type="ref"
    reference="sec:pedersen_monero"}).

5.  Check each address's signature.

If everything is legitimate, then the prover must own, unspent, at least
the total amount contained in the ReserveProof's outputs (except with
negligible probability).[^11]

## Monero audit framework {#sec:proofs-monero-audit-framework}

In the USA most companies undergo yearly audits of their financial
statements [@investopedia-audits], which include the income statement,
balance sheet, and cash flow statement. Of these the former two involve
in large part a company's internal record-keeping, while the last
involves every transaction that affects how much money the company
currently has. Cryptocurrencies are digital cash, so any audit of a
cryptocurrency user's cash flow statement must relate to transactions
stored on the blockchain.

The first task of an audited person is to identify all the outputs they
currently own (spent and unspent). This can be one with InProofs using
all of their addresses. A large business may have a multitude of
subaddresses, especially retailers operating in online marketplaces (see
Chapter
[\[chapter:escrowed-market\]](#chapter:escrowed-market){reference-type="ref"
reference="chapter:escrowed-market"}). Creating InProofs on all
transactions for every single subaddress may result in enormous
computational and storage requirements for both provers and verifiers.

Instead, we can make InProofs for just the prover's normal addresses (on
all transactions). The auditor uses those sender-receiver shared secrets
to check if any outputs are owned by the prover's main address or its
related subaddresses. Recalling Section
[\[sec:subaddresses\]](#sec:subaddresses){reference-type="ref"
reference="sec:subaddresses"}, a user's view key is enough to identify
all outputs owned by an address's subaddresses.

To ensure the prover is not hoodwinking an auditor by hiding the normal
address for some of his subaddresses, he also must prove all
subaddresses correspond with one of his known normal addresses.

### Prove an address and subaddress correspond (SubaddressProof) {#subsec:proofs-address-subaddress-correspond-subaddressproof}

SubaddressProofs show that a normal address's view key can be used to
identify outputs owned by a given subaddress.[^12]

#### The SubaddressProof {#the-subaddressproof .unnumbered}

SubaddressProofs can be made in much the same way as OutProofs and
InProofs. Here the base keys are $\mathcal{J} = \{G, K^{s,i}\}$, public
keys are $\mathcal{K} = \{K^v, K^{v,i}\}$, and signing key is $k^v$.
Again, we show just the verification step to clarify our meaning.

#### Verification {#verification-5 .unnumbered}

A verifier knows the prover's address $(K^v, K^s)$, subaddress
$(K^{v,i}, K^{s,i})$, and has the SubaddressProof
$\sigma^{subproof} = (c,r)$.

1.  Calculate the challenge
    $$c' = \mathcal{H}_n(\mathfrak{m},[K^{v,i}], [r G + c*K^v], [r K^{s,i} + c*K^{v,i}], [T_{txprf2}], [K^v], [K^{s,i}], [0])$$

2.  If $c = c'$ then the prover knows $k^v$ for $K^v$, and $K^{s,i}$ in
    combination with that view key makes $K^{v,i}$ (except with
    negligible probability).

### The audit framework {#subsec:audit-framework}

Now we are prepared to learn as much as possible about a person's
transaction history.[^13]

1.  The prover gathers a list of all his accounts, where each account
    consists of a normal address and various subaddresses. He makes
    SubaddressProofs for all subaddresses. Much like ReserveProofs, he
    also makes a signature with the spend key of each address and
    subaddress, demonstrating he has spend-rights over all outputs owned
    by those addresses.

2.  The prover generates, for each of his normal addresses, InProofs on
    all transactions (e.g. all transaction public keys) in the
    blockchain. This reveals to the auditor all outputs owned by the
    prover's addresses since they can check all one-time addresses with
    the sender-receiver shared secrets. They can be sure outputs owned
    by subaddresses will be identified, because of the
    SubaddressProofs.[^14]

3.  The prover generates, for each of his owned outputs, UnspentProofs
    on all transaction inputs where they appear as ring members. Now the
    auditor will know the prover's balance, and can further investigate
    spent outputs.[^15]

4.  *Optional*: The prover generates, for each transaction where he
    spent an output, an OutProof to show the auditor the recipient and
    amount. This step is only possible for transactions where the prover
    saved the transaction private key(s).

Importantly, a prover has no way to show the origin of funds directly.
His only recourse is to request a set of proofs from people sending him
money.

1.  For a transaction sending money to the prover, its author makes a
    SpendProof demonstrating they actually sent it.

2.  The prover's funder also makes a signature with an identifying
    public key, for example the spend key of their normal address. Both
    the SpendProof and this signature should sign a message containing
    that identifying public key, to ensure the SpendProof wasn't stolen
    or in fact made by someone else.

[^1]: Just like in Section
    [\[sec:CLSAG\]](#sec:CLSAG){reference-type="ref"
    reference="sec:CLSAG"}, hash functions should be domain separated by
    prefixing them with tags. The current Monero transaction proofs
    implementation has no domain separation, so all the tags in this
    chapter are in features *not* yet implemented.

[^2]: Transaction IDs are usually communicated separately from proofs.

[^3]: As we will see in Chapter
    [\[chapter:txtangle\]](#chapter:txtangle){reference-type="ref"
    reference="chapter:txtangle"}, someone who made one input signature
    didn't necessarily make all input signatures.

[^4]: We can think of an 'OutProof' as showing an output is 'outgoing'
    from the prover. The corresponding 'InProofs' (Section
    [1.1.4](#subsec:proofs-output-ownership-inproof){reference-type="ref"
    reference="subsec:proofs-output-ownership-inproof"}) show outputs
    that are 'incoming' to the prover's address.

[^5]: Here the '0' value is a 32-byte encoding of zero bytes.

[^6]: Due to the limited number of available symbols, we unfortunately
    used $r$ for both responses and the transaction private key.
    Superscript 'resp' for 'response' will be used to differentiate the
    two when necessary.

[^7]: A valid OutProof signature doesn't necessarily mean the recipient
    considered is the real recipient. A malicious prover could generate
    a random view key $K'^v$, compute
    $K'^s = K^o - \mathcal{H}_n(rK'^v,t)*G$, and provide $(K'^v,K'^s)$
    as the nominal recipient. By recalculating the output commitment,
    verifiers can be more confident the recipient address in question is
    legitimate. However, a prover and recipient could collaborate to
    encode the output commitment using $K'^v$, while the one-time
    address uses $(K^v,K^s)$. Since the recipient would need to know the
    private key $k'^v$ (assuming the output amount is still meant to be
    spendable), there is questionable utility to that level of
    deception. Why wouldn't the recipient just use $(K'^v,K'^s)$ (or
    some other single-use address) for the entire output? Since the
    computation of $C^b_t$ is related to the recipient, we consider the
    described OutProof verification process adequate. In other words,
    the prover can't use it to deceive verifiers without coordinating
    with the recipient.

[^8]: The ability to provide such a signature directly does not seem to
    be available in Monero, although as we will see ReserveProofs
    (Section
    [1.1.6](#subsec:proofs-minimum-balance-reserveproof){reference-type="ref"
    reference="subsec:proofs-minimum-balance-reserveproof"}) do include
    them.

[^9]: UnspentProofs have not been implemented in Monero.

[^10]: UnspentProofs are made the same way for subaddresses and normal
    addresses. The full spend key of a subaddress is required, e.g.
    $k^{s,i} = k^s + \mathcal{H}_n(k^v,i)$ (Section
    [\[sec:subaddresses\]](#sec:subaddresses){reference-type="ref"
    reference="sec:subaddresses"}).

[^11]: ReserveProofs, while demonstrating full ownership of funds, do
    not include proofs that given subaddresses actually correspond with
    the prover's normal address.

[^12]: SubaddressProofs have not been implemented in Monero.

[^13]: This audit framework is not completely available in Monero.
    SubaddressProofs and UnspentProofs are not implemented, InProofs are
    not prepared for the optimization related to subaddresses that we
    explained, and there is no real structure to easily get or organize
    all the necessary information for both provers and verifiers.

[^14]: This step can also be completed by providing the private view
    keys, although it has obvious privacy implications.

[^15]: Alternatively, he could make ReserveProofs for all owned outputs.
    Again, revealing the key images of unspent outputs has obvious
    privacy implications.
