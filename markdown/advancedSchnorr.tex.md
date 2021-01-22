# Advanced Schnorr-like Signatures {#chapter:advanced-schnorr}

A basic Schnorr signature has one signing key. As it happens, we can
apply its core concepts to create a variety of progressively more
complex signature schemes. One of those schemes, MLSAG, will be of
central importance in Monero's transaction protocol.

## Prove knowledge of a discrete logarithm across multiple bases {#sec:proofs-discrete-logarithm-multiple-bases}

It is often useful to prove the same private key was used to construct
public keys on different 'base' keys. For example, we could have a
normal public key $k G$, and a Diffie-Hellman shared secret $k R$ with
some other person's public key (recall Section
[\[DH_exchange_section\]](#DH_exchange_section){reference-type="ref"
reference="DH_exchange_section"}), where the base keys are $G$ and $R$.
As we will soon see, we can prove knowledge of the discrete log $k$ in
$k G$, prove knowledge of $k$ in $k R$, *and* prove that $k$ is the same
in both cases (all without revealing $k$).

### Non-interactive proof {#non-interactive-proof .unnumbered}

Suppose we have a private key $k$, and $d$ base keys
$\mathcal{J} = \{J_1,...,J_d\}$. The corresponding public keys are
$\mathcal{K} = \{K_1,...,K_d\}$. We make a Schnorr-like proof (recall
Section
[\[sec:schnorr-fiat-shamir\]](#sec:schnorr-fiat-shamir){reference-type="ref"
reference="sec:schnorr-fiat-shamir"}) across all bases.[^1] Assume the
existence of a hash function $\mathcal{H}_n$ mapping to integers from 0
to $l-1$.[^2]

1.  Generate random number $\alpha \in_R \mathbb{Z}_l$, and compute, for
    all $i \in (1,...,d)$, $\alpha J_i$.

2.  Calculate the challenge,
    $$c = \mathcal{H}_n(\mathcal{J},\mathcal{K},[\alpha J_1],[\alpha J_2],...,[\alpha J_d])$$

3.  Define the response $r = \alpha - c*k$.

4.  Publish the signature $(c, r)$.

### Verification {#verification .unnumbered}

Assuming the verifier knows $\mathcal{J}$ and $\mathcal{K}$, he does the
following.

1.  Calculate the challenge:
    $$c' = \mathcal{H}(\mathcal{J},\mathcal{K},[r J_1 + c*K_1],[r J_2 + c*K_2],...,[r J_d + c*K_d])$$

2.  If $c = c'$ then the signer must know the discrete logarithm across
    all bases, and it's the same discrete logarithm in each case (as
    always, except with negligible probability).

### Why it works {#why-it-works .unnumbered}

If instead of $d$ base keys there was just one, this proof would clearly
be the same as our original Schnorr proof (Section
[\[sec:schnorr-fiat-shamir\]](#sec:schnorr-fiat-shamir){reference-type="ref"
reference="sec:schnorr-fiat-shamir"}). We can imagine each base key in
isolation to see that the multi-base proof is just a bunch of Schnorr
proofs connected together. Moreover, by using only one challenge and
response for all of those proofs, they must have the same discrete
logarithm $k$. To get a single response that works for multiple keys the
challenge would need to be known before defining an $\alpha$ for each
key, but $c$ is a function of $\alpha$!

## Multiple private keys in one proof {#sec:multiple_private_keys_in_one_proof}

Much like a multi-base proof, we can combine many Schnorr proofs that
use different private keys. Doing so proves we know all the private keys
for a set of public keys, and reduces storage requirements by making
just one challenge for all proofs.

### Non-interactive proof {#non-interactive-proof-1 .unnumbered}

Suppose we have $d$ private keys $k_1,...,k_d$, and base keys
$\mathcal{J} = \{J_1,...,J_d\}$.[^3] The corresponding public keys are
$\mathcal{K} = \{K_1,...,K_d\}$. We make a Schnorr-like proof for all
keys simultaneously.

1.  Generate random numbers $\alpha_i \in_R \mathbb{Z}_l$ for all
    $i \in (1,...,d)$, and compute all $\alpha_i J_i$.

2.  Calculate the challenge,
    $$c = \mathcal{H}_n(\mathcal{J},\mathcal{K},[\alpha_1 J_1],[\alpha_2 J_2],...,[\alpha_d J_d])$$

3.  Define each response $r_i = \alpha_i - c*k_i$.

4.  Publish the signature $(c, r_1,...,r_d)$.

### Verification {#verification-1 .unnumbered}

Assuming the verifier knows $\mathcal{J}$ and $\mathcal{K}$, he does the
following.

1.  Calculate the challenge:
    $$c' = \mathcal{H}(\mathcal{J},\mathcal{K},[r_1 J_1 + c*K_1],[r_2 J_2 + c*K_2],...,[r_d J_d + c*K_d])$$

2.  If $c = c'$ then the signer must know the private keys for all
    public keys in $\mathcal{K}$ (except with negligible probability).

## Spontaneous Anonymous Group (SAG) signatures {#SAG_section}

Group signatures are a way of proving a signer belongs to a group,
without necessarily identifying him. Originally (Chaum in
[@Chaum:1991:GS:1754868.1754897]), group signature schemes required the
system be set up, and in some cases managed, by a trusted person in
order to prevent illegitimate signatures, and, in a few schemes,
adjudicate disputes. These relied on a *group secret* which is not
desirable since it creates a disclosure risk that could undermine
anonymity. Moreover, requiring coordination between group members (i.e.
for setup and management) is not scalable beyond small groups or inside
companies.

Liu *et al.* presented a more interesting scheme in [@Liu2004] building
on the work of Rivest *et al.* in [@rivest-leak-secret]. The authors
detailed a group signature algorithm called LSAG characterized by three
properties: *anonymity, linkability,* and *spontaneity*. Here we discuss
SAG, the non-linkable version of LSAG, for conceptual clarity. We
reserve the idea of linkability for later sections.\
Schemes with anonymity and spontaneity are typically referred to as
'ring signatures'. In the context of Monero they will ultimately allow
for unforgeable, signer-ambiguous transactions that leave currency flows
largely untraceable.

### Signature {#signature .unnumbered}

Ring signatures are composed of a ring and a signature. Each *ring* is a
set of public keys, one of which belongs to the signer and the rest of
which are unrelated. The *signature* is generated with that ring of
keys, and anyone verifying it would not be able to tell which ring
member was the actual signer.

Our Schnorr-like signature scheme in Section
[\[sec:signing-messages\]](#sec:signing-messages){reference-type="ref"
reference="sec:signing-messages"} can be considered a one-key ring
signature. We get to two keys by, instead of defining $r$ right away,
generating a decoy $r'$ and creating a new challenge to define $r$
with.\
Let $\mathfrak{m}$ be the message to sign,
$\mathcal{R} = \{K_1, K_2, ..., K_n\}$ a set of distinct public keys (a
group/ring), and $k_\pi$ the signer's private key corresponding to his
public key $K_\pi \in \mathcal{R}$, where $\pi$ is a secret index.

1.  Generate random number $\alpha \in_R \mathbb{Z}_l$ and fake
    responses $r_i \in_R \mathbb{Z}_l$ for $i \in \{1, 2, ..., n\}$ but
    excluding $i = \pi$.

2.  Calculate
    $$c_{\pi+1} = \mathcal{H}_n(\mathcal{R}, \mathfrak{m}, [\alpha G])$$

3.  For $i = \pi+1, \pi+2, ..., n, 1, 2, ..., \pi-1$ calculate,
    replacing $n + 1 \rightarrow 1$,
    $$c_{i+1} = \mathcal{H}_n(\mathcal{R}, \mathfrak{m}, [r_i G + c_i K_i])$$

4.  Define the real response $r_\pi$ such that
    $\alpha = r_\pi + c_\pi k_\pi \pmod l$.

The ring signature contains the signature
$\sigma(\mathfrak{m}) = (c_1, r_1, ..., r_n)$, and the ring
$\mathcal{R}$.

### Verification {#verification-2 .unnumbered}

Verification means proving $\sigma(\mathfrak{m})$ is a valid signature
created by a private key corresponding to a public key in $\mathcal{R}$
(without necessarily knowing which one), and is done in the following
manner:

1.  For $i = 1, 2, ..., n$ iteratively compute, replacing
    $n + 1 \rightarrow 1$, $$\begin{aligned}
        c'_{i+1}   = \mathcal{H}_n(\mathcal{R}, \mathfrak{m}, [r_i G + c_i {K_i}])
        \end{aligned}$$

2.  If $c_1 = c'_1$ then the signature is valid. Note that $c'_1$ is the
    last term calculated.

In this scheme we store (1+$n$) integers and use $n$ public keys.

### Why it works {#why-it-works-1 .unnumbered}

We can informally convince ourselves the algorithm works by going
through an example. Consider ring $R = \{K_1, K_2, K_3\}$ with
$k_\pi = k_2$. First the signature:

1.  Generate random numbers: $\alpha$, $r_1$, $r_3$ $$\begin{aligned}
        \intertext{\item Seed the signature loop:}  c_3 &= \mathcal{H}_n(\mathcal{R}, \mathfrak{m}, [\alpha G])
        \intertext{\item Iterate: \vspace{-.2cm}}
            c_1 &= \mathcal{H}_n(\mathcal{R}, \mathfrak{m}, [r_3 G + c_3 K_3])\\
            c_2 &= \mathcal{H}_n(\mathcal{R}, \mathfrak{m}, [r_1 G + c_1 K_1])\end{aligned}$$

2.  Close the loop by responding: $r_2 = \alpha - c_2 k_2 \pmod{l}$

We can substitute $\alpha$ into $c_3$ to see where the word 'ring' comes
from: $$\begin{aligned}
{3}
    c_3 &= \mathcal{H}_n(\mathcal{R}, \mathfrak{m}, [(r_2 + c_2 k_2) G &&])\\
    c_3 &= \mathcal{H}_n(\mathcal{R}, \mathfrak{m}, [r_2 G + c_2 K_2 &&])\end{aligned}$$

Then verification using $\mathcal{R}$, and
$\sigma(\mathfrak{m}) = (c_1, r_1, r_2, r_3)$:

1.  We use $r_1$ and $c_1$ to compute $$\begin{aligned}
    c'_2 &= \mathcal{H}_n(\mathcal{R}, \mathfrak{m}, [r_1 G + c_1 K_1])
        \intertext{\item From when we made the signature, we see $c'_2 = c_2$. With $r_2$ and $c'_2$ we compute\vspace{.175cm}}
    c'_3 &= \mathcal{H}_n(\mathcal{R}, \mathfrak{m}, [r_2 G + c'_2 K_2])
        \intertext{\item We can easily see that $c'_3 = c_3$ by substituting $c_2$ for $c'_2$. Using $r_3$ and $c'_3$ we get\vspace{.175cm}}
    c'_1 &= \mathcal{H}_n(\mathcal{R}, \mathfrak{m}, [r_3 G + c'_3 K_3])
        \end{aligned}$$

No surprises here: $c'_1 = c_1$ if we substitute $c_3$ for $c'_3$.

## Back's Linkable Spontaneous Anonymous Group (bLSAG) signatures {#blsag_note}

The ring signature schemes discussed here on out display several
properties that will be useful for producing confidential
transactions.[^4] Note that both 'signer ambiguity' and 'unforgeability'
also apply to SAG signatures.

Signer Ambiguity

:   An observer should be able to determine the signer must be a member
    of the ring (except with negligible probability), but not which
    member.[^5] Monero uses this to obfuscate the origin of funds in
    each transaction.

Linkability

:   If a private key is used to sign two different messages then the
    messages will become linked.[^6] As we will show, this property is
    used to prevent double-spending attacks in Monero (except with
    negligible probability).

Unforgeability

:   No attacker can forge a signature except with negligible
    probability.[^7] This is used to prevent theft of Monero funds by
    those not in possession of the appropriate private keys.

In the LSAG signature scheme [@Liu2004], the owner of a private key
could produce one anonymous unlinked signature per ring.[^8] In this
section we present an enhanced version of the LSAG algorithm where
linkability is independent of the ring's decoy members.[^9]

The modification was unraveled in [@MRL-0005-ringct] based on a
publication by Adam Back [@AdamBack-ring-efficiency] regarding the
CryptoNote [@cryptoNoteWhitePaper] ring signature algorithm (previously
used in Monero, and now deprecated; see Section
[\[subsec:proofs-input-creation-spendproof\]](#subsec:proofs-input-creation-spendproof){reference-type="ref"
reference="subsec:proofs-input-creation-spendproof"}), which was in turn
inspired by Fujisaki and Suzuki's work in [@Fujisaki2007].

### Signature {#signature-1 .unnumbered}

As with SAG, let $\mathfrak{m}$ be the message to sign,
$\mathcal{R} = \{K_1, K_2, ..., K_n\}$ a set of distinct public keys,
and $k_\pi$ the signer's private key corresponding to his public key
$K_\pi \in \mathcal{R}$, where $\pi$ is a secret index. Assume the
existence of a hash function $\mathcal{H}_p$, which maps to curve points
in EC.[^10][^11]

1.  Calculate key image $\tilde{K} = k_\pi \mathcal{H}_p(K_\pi)$.[^12]

2.  Generate random number $\alpha \in_R \mathbb{Z}_l$ and random
    numbers $r_i \in_R \mathbb{Z}_l$ for $i \in \{1, 2, ..., n\}$ but
    excluding $i = \pi$.

3.  Compute
    $$c_{\pi+1} = \mathcal{H}_n(\mathfrak{m}, [\alpha G], [\alpha \mathcal{H}_p(K_\pi)])$$

4.  For $i = \pi+1, \pi+2, ..., n, 1, 2, ..., \pi-1$ calculate,
    replacing $n + 1 \rightarrow 1$,
    $$c_{i+1} = \mathcal{H}_n(\mathfrak{m}, [r_i G + c_i K_i], [r_i \mathcal{H}_p(K_i) + c_i \tilde{K}])$$

5.  Define $r_\pi = \alpha - c_\pi k_\pi \pmod l$.

The signature will be $\sigma(\mathfrak{m}) = (c_1, r_1, ..., r_n)$,
with key image $\tilde{K}$ and ring $\mathcal{R}$.

### Verification {#verification-3 .unnumbered}

Verification means proving $\sigma(\mathfrak{m})$ is a valid signature
created by a private key corresponding to a public key in $\mathcal{R}$,
and is done in the following manner:

1.  Check $l \tilde{K} \stackrel{?}{=} 0$.

2.  For $i = 1, 2, ..., n$ iteratively compute, replacing
    $n + 1 \rightarrow 1$, $$\begin{aligned}
        c'_{i+1} = \mathcal{H}_n(\mathfrak{m}, [r_i G + c_i {K_i}], [r_i \mathcal{H}_p(K_i) + c_i \tilde{K}])
        \end{aligned}$$

3.  If $c_1 = c'_1$ then the signature is valid.

In this scheme we store (1+$n$) integers, have one EC key image, and use
$n$ public keys.

We must check $l \tilde{K} \stackrel{?}{=} 0$ because it is possible to
add an EC point from the subgroup of size $h$ (the cofactor) to
$\tilde{K}$ and, if all $c_i$ are multiples of $h$ (which we could
achieve with automated trial and error using different $\alpha$ and
$r_i$ values), make $h$ unlinked valid signatures using the same ring
and signing key.[^13] This is because an EC point multiplied by its
subgroup's order is zero.[^14]

To be clear, given some point $K$ in the subgroup of order $l$, some
point $K^h$ with order $h$, and an integer $c$ divisible by $h$:
$$\begin{aligned}
    c*(K + K^h) &= cK + cK^h\\
                &= cK + 0\end{aligned}$$

We can demonstrate correctness (i.e. 'how it works') in a similar way to
the more simple SAG signature scheme.

Our description attempts to be faithful to the original explanation of
bLSAG, which does not include $\mathcal{R}$ in the hash that calculates
$c_i$. Including keys in the hash is known as 'key prefixing'. Recent
research [@key-prefix-paper] suggests it may not be necessary, although
adding the prefix is standard practice for similar signature schemes
(LSAG uses key prefixing).

### Linkability {#linkability .unnumbered}

Given two valid signatures that are different in some way (e.g.
different fake responses, different messages, different overall ring
members), $$\begin{aligned}
    \sigma(\mathfrak{m})   &= (c_1, r_1, ..., r_n)\textrm{ with } \tilde{K}\textrm{, and}\\
    \sigma'(\mathfrak{m}')  &= (c_1', r'_1, ..., r'_{n'})\textrm{ with } \tilde{K}'\textrm{,}\end{aligned}$$
if $\tilde{K} =  \tilde{K}'$ then clearly both signatures come from the
same private key.

While an observer could link $\sigma$ and $\sigma'$, he wouldn't
necessarily know which $K_i$ in $\mathcal{R}$ or $\mathcal{R}'$ was the
culprit unless there was only one common key between them. If there was
more than one common ring member, his only recourse would be solving the
DLP or auditing the rings in some way (such as learning all $k_i$ with
$i \neq \pi$, or learning $k_\pi$).[^15]

## Multilayer Linkable Spontaneous Anonymous Group (MLSAG) signatures {#sec:MLSAG}

In order to sign transactions, one has to sign with multiple private
keys. In [@MRL-0005-ringct], Shen Noether *et al.* describe a
multi-layered generalization of the bLSAG signature scheme applicable
when we have a set of $n \cdot m$ keys; that is, the set
$$\mathcal{R} = \{K_{i,j}\}  \quad \textrm{for} \quad  i \in \{1, 2, ..., n\} \quad \textrm{and} \quad j \in \{1, 2, ..., m\}$$

where we know the $m$ private keys $\{k_{\pi, j}\}$ corresponding to the
subset $\{K_{\pi, j}\}$ for some index $i = \pi$. Such an algorithm
would address our needs if we generalize the notion of linkability.

Linkability

:   If any private key $k_{\pi, j}$ is used in 2 different signatures,
    then those signatures will be automatically linked.

### Signature {#signature-2 .unnumbered}

1.  Calculate key images
    $\tilde{K_j} = k_{\pi, j} \mathcal{H}_p(K_{\pi, j})$ for all
    $j \in \{1, 2, ..., m\}$.

2.  Generate random numbers $\alpha_j \in_R \mathbb{Z}_l$, and
    $r_{i, j} \in_R \mathbb{Z}_l$ for $i \in \{1, 2, ..., n\}$ (except
    $i = \pi$) and $j \in \{1, 2, ..., m\}$.

3.  Compute[^16]
    $$c_{\pi+1} = \mathcal{H}_n(\mathfrak{m}, [\alpha_1 G], [\alpha_1 \mathcal{H}_p(K_{\pi, 1})], ..., [\alpha_m G], [\alpha_m \mathcal{H}_p(K_{\pi, m})])$$

4.  For $i = \pi+1, \pi+2, ..., n, 1, 2, ..., \pi-1$ calculate,
    replacing $n + 1 \rightarrow 1$,
    $$c_{i+1} = \mathcal{H}_n(\mathfrak{m}, [r_{i, 1} G + c_i K_{i, 1}], [r_{i, 1} \mathcal{H}_p(K_{i, 1}) + c_i \tilde{K}_1], 
        ..., [r_{i, m} G + c_i K_{i, m}], [r_{i, m} \mathcal{H}_p(K_{i, m}) + c_i \tilde{K}_m])$$

5.  Define all $r_{\pi, j} = \alpha_j - c_\pi k_{\pi, j} \pmod l$.

The signature will be
$\sigma(\mathfrak{m}) = (c_1, r_{1, 1}, ..., r_{1, m}, ..., r_{n, 1}, ..., r_{n, m})$,
with key images $(\tilde{K}_1, ...,  \tilde{K}_m)$.

### Verification {#verification-4 .unnumbered}

Verification of a signature is done in the following manner:

1.  For all $j \in \{1,...,m\}$ check $l \tilde{K}_j \stackrel{?}{=} 0$.

2.  For $i = 1, ..., n$ compute, replacing $n + 1 \rightarrow 1$,
    $$\begin{aligned}
        c'_{i+1} = \mathcal{H}_n(\mathfrak{m}, [r_{i, 1} G + c_i K_{i, 1}], [r_{i, 1} \mathcal{H}_p(K_{i, 1}) + c_i \tilde{K}_1], 
        ..., [r_{i, m} G + c_i K_{i, m}], [r_{i, m} \mathcal{H}_p(K_{i, m}) + c_i \tilde{K}_m])
        \end{aligned}$$

3.  If $c_1 = c'_1$ then the signature is valid.

### Why it works {#why-it-works-2 .unnumbered}

Just as with the SAG algorithm, we can readily observe that

-   If $i \ne \pi$, then clearly the values $c'_{i + 1}$ are calculated
    as described in the signature algorithm.

-   If $i = \pi$ then, since $r_{\pi, j} = \alpha_j - c_\pi k_{\pi, j}$
    closes the loop, $$\begin{aligned}
    {6}
            r_{\pi, j} G + c_\pi K_{\pi,j} &= (\alpha_j - c_\pi k_{\pi, j}) G + c_\pi K_{\pi,j} = \alpha_j G\\
            \intertext{and}
            r_{\pi, j} \mathcal{H}_p(K_{\pi, j}) + c_\pi \tilde{K}_j &= (\alpha_j - c_\pi k_{\pi, j}) \mathcal{H}_p(K_{\pi, j}) + c_\pi \tilde{K}_j = \alpha_j \mathcal{H}_p(K_{\pi, j})\\
        \end{aligned}$$ In other words, it holds also that
    $c'_{\pi + 1} = c_{\pi+1}$.

### Linkability {#linkability-1 .unnumbered}

If a private key $k_{\pi, j}$ is re-used to make any signature, the
corresponding key image $\tilde{K}_j$ supplied in the signature will
reveal it. This observation matches our generalized definition of
linkability.[^17]

### Space requirements {#space-requirements .unnumbered}

In this scheme we store (1+$m*n$) integers, have $m$ EC key images, and
use $m*n$ public keys.

## Concise Linkable Spontaneous Anonymous Group (CLSAG) signatures {#sec:CLSAG}

CLSAG [@MRL-0011-CLSAG][^18] is sort of half-way between bLSAG and
MLSAG. Suppose you have a 'primary' key, and associated with it are
several 'auxiliary' keys. It is important to prove knowledge of all
private keys, but linkability only applies to the primary. This
linkability retraction allows smaller, faster signatures than afforded
by MLSAG.

As with MLSAG, we have a set of $n \cdot m$ keys ($n$ is the ring size,
$m$ is the number of signing keys), and the primary keys are at index 1.
In other words, there are $n$ primary keys, and the $\pi$such key and
its auxiliaries will sign.
$$\mathcal{R} = \{K_{i,j}\}  \quad \textrm{for} \quad  i \in \{1, 2, ..., n\} \quad \textrm{and} \quad j \in \{1, 2, ..., m\}$$

We know the private keys $\{k_{\pi, j}\}$ corresponding to the subset
$\{K_{\pi, j}\}$ for some index $i = \pi$.

### Signature {#signature-3 .unnumbered}

1.  Calculate key images
    $\tilde{K_j} = k_{\pi, j} \mathcal{H}_p(K_{\pi, 1})$ for all
    $j \in \{1, 2, ..., m\}$. Note the base key is always the same, and
    so key images with $j>1$ are 'auxiliary key images'. For notational
    simplicity we call them all $\tilde{K}_j$.

2.  Generate random numbers $\alpha \in_R \mathbb{Z}_l$, and
    $r_{i} \in_R \mathbb{Z}_l$ for $i \in \{1, 2, ..., n\}$ (except
    $i = \pi$).

3.  Calculate aggregate public keys $W_i$ for $i \in \{1, 2, ..., n\}$,
    and aggregate key image $\tilde{W}$[^19] $$\begin{aligned}
        W_i &= \sum^{m}_{j=1} \mathcal{H}_n(T_j, \mathcal{R}, \tilde{K}_1,...,\tilde{K}_{m})*K_{i,j}\\
        \tilde{W} &= \sum^{m}_{j=1} \mathcal{H}_n(T_j, \mathcal{R}, \tilde{K}_1,...,\tilde{K}_{m})*\tilde{K}_j
        \end{aligned}$$ where
    $w_{\pi} = \sum_j \mathcal{H}_n(T_j,...)*k_{\pi,j}$ is the aggregate
    private key.

4.  Compute
    $$c_{\pi+1} = \mathcal{H}_n(T_c, \mathcal{R}, \mathfrak{m}, [\alpha G], [\alpha \mathcal{H}_p(K_{\pi, 1})])$$

5.  For $i = \pi+1, \pi+2, ..., n, 1, 2, ..., \pi-1$ calculate,
    replacing $n + 1 \rightarrow 1$,
    $$c_{i+1} = \mathcal{H}_n(T_c, \mathcal{R}, \mathfrak{m}, [r_i G + c_i W_i], [r_{i} \mathcal{H}_p(K_{i,1}) + c_i \tilde{W}])$$

6.  Define $r_{\pi} = \alpha - c_\pi w_\pi \pmod l$.

Therefore $\sigma(\mathfrak{m}) = (c_1, r_1, ..., r_n)$, with primary
key image $\tilde{K}_1$, and auxiliary images
$(\tilde{K}_2,...,\tilde{K}_{m})$.

### Verification {#verification-5 .unnumbered}

The verification of a signature is done in the following manner:

1.  For all $j \in \{1,...,m\}$ check
    $l \tilde{K}_j \stackrel{?}{=} 0$.[^20]

2.  Calculate aggregate public keys $W_i$ for $i \in \{1, 2, ..., n\}$,
    and aggregate key image $\tilde{W}$ $$\begin{aligned}
        W_i &= \sum^{m}_{j=1} \mathcal{H}_n(T_j, \mathcal{R}, \tilde{K}_1,...,\tilde{K}_{m})*K_{i,j}\\
        \tilde{W} &= \sum^{m}_{j=1} \mathcal{H}_n(T_j, \mathcal{R}, \tilde{K}_1,...,\tilde{K}_{m})*\tilde{K}_j
        \end{aligned}$$

3.  For $i = 1, ..., n$ compute, replacing $n + 1 \rightarrow 1$,
    $$c_{i+1} = \mathcal{H}_n(T_c, \mathcal{R}, \mathfrak{m}, [r_i G + c_i W_i], [r_{i} \mathcal{H}_p(K_{i,1}) + c_i \tilde{W}])$$

4.  If $c_1 = c'_1$ then the signature is valid.

### Why it works {#why-it-works-3 .unnumbered}

The biggest danger in concise signatures like this is key cancellation,
where the key images reported aren't legitimate, yet still sum to a
legitimate aggregate value. This is where the aggregation coefficients
$\mathcal{H}_n(T_j, \mathcal{R}, \tilde{K}_1,...,\tilde{K}_{m})$ come
into play, locking down each key to its expected value. We leave tracing
out the circular repercussions of faking a key image as an exercise to
the reader (perhaps start by imagining those coefficients don't exist).
Auxiliary key images are an artifact of proving the primary image is
legitimate, since the aggregate private key $w_{\pi}$, which contains
all the private keys, is applied to base point
$\mathcal{H}_p(K_{\pi,1})$.

### Linkability {#linkability-2 .unnumbered}

If a private key $k_{\pi, 1}$ is re-used to make any signature, the
corresponding primary key image $\tilde{K}_1$ supplied in the signature
will reveal it. Auxiliary key images are ignored, as they only exist to
facilitate the 'Concise' part of CLSAG.

### Space requirements {#space-requirements-1 .unnumbered}

We store (1+$n$) integers, have $m$ key images, and use $m*n$ public
keys.

[^1]: While we say 'proof', it can be trivially made a signature by
    including a message $\mathfrak{m}$ in the challenge hash. The
    terminology is loosely interchangeable in this context.

[^2]: In Monero, the hash function
    $\mathcal{H}_n(x) = \textrm{sc\textunderscore reduce32}(\mathit{Keccak}(x))$
    where $\mathit{Keccak}$ is the basis of SHA3 and screduce32() puts
    the 256 bit result in the range 0 to $l-1$ (although it should
    really be 1 to $l-1$).

[^3]: There is no reason $\mathcal{J}$ can't contain duplicate base keys
    here, or for all base keys to be the same (e.g. $G$). Duplicates
    would be redundant for multi-base proofs, but now we are dealing
    with different private keys.

[^4]: Keep in mind that all robust signature schemes have security
    models which contain various properties. The properties mentioned
    here are perhaps most relevant to understanding the purpose of
    Monero's ring signatures, but are not a comprehensive overview of
    linkable ring signature properties.

[^5]: [\[anonymity_note\]]{#anonymity_note
    label="anonymity_note"}Anonymity for an action is usually in terms
    of an 'anonymity set', which is 'all the people who could have
    possibly taken that action'. The largest anonymity set is
    'humanity', and for Monero it is the ring size, or e.g. the
    so-called 'mixin level' $v$ plus the real signer. Mixin refers to
    how many fake members each ring signature has. If the mixin is $v$ =
    4 then there are 5 possible signers. Expanding anonymity sets makes
    it progressively harder to track down real actors.

[^6]: [\[linkability_note\]]{#linkability_note
    label="linkability_note"}The linkability property does not apply to
    non-signing public keys. That is, a ring member whose public key has
    been used in different ring signatures will not cause linkage.

[^7]: [\[unforgeability_note\]]{#unforgeability_note
    label="unforgeability_note"}Certain ring signature schemes,
    including the one in Monero, are strong against adaptive
    chosen-message and adaptive chosen-public-key attacks. An attacker
    who can obtain legitimate signatures for chosen messages and
    corresponding to specific public keys in rings of his choice cannot
    discover how to forge the signature of even one message. This is
    called *existential unforgeability*; see [@MRL-0005-ringct] and
    [@Liu2004].

[^8]: [\[lsag_linkability_note\]]{#lsag_linkability_note
    label="lsag_linkability_note"}In the LSAG scheme linkability only
    applies to signatures using rings with the same members and in the
    same order, the 'exact same ring.' It is really "one anonymous
    signature per ring member per ring." Signatures can be linked even
    if made for different messages.

[^9]: LSAG was discussed in the first edition of this report. [@ztm-1]

[^10]: It doesn't matter if points from $\mathcal{H}_p$ are compressed
    or not. They can always be decompressed.

[^11]: Monero uses a hash function that returns curve points directly,
    rather than computing some integer that is then multiplied by $G$.
    $\mathcal{H}_p$ would be broken if someone discovered a way to find
    $n_x$ such that $n_x G = \mathcal{H}_p(x)$. See a description of the
    algorithm in [@hashtopoint-writeup]. According to the CryptoNote
    whitepaper [@cryptoNoteWhitePaper] its origin was this paper:
    [@hashtopoint-original-paper].

[^12]: In Monero it's important to use the hash to point function for
    key images instead of another base point so linearity doesn't lead
    to linking signatures created by the same address (even if for
    different one-time addresses). See [@cryptoNoteWhitePaper] page 18.

[^13]: We are not concerned with points from other subgroups because the
    output of $\mathcal{H}_n$ is confined to $\mathbb{Z}_l$. For EC
    order $N = h l$, all divisors of $N$ (and hence, possible subgroups)
    are either multiples of $l$ (a prime) or divisors of $h$.

[^14]: In Monero's early history this was not checked for. Fortunately,
    it was not exploited before a fix was implemented in April 2017 (v5
    of the protocol) [@key-image-bug].

[^15]: [\[lsag_unforgeable_note\]]{#lsag_unforgeable_note
    label="lsag_unforgeable_note"}LSAG, which is quite similar to bLSAG,
    is unforgeable, meaning no attacker could make a valid ring
    signature without knowing a private key. If he invents a fake
    $\tilde{K}$ and seeds his signature computation with $c_{\pi+1}$,
    then, not knowing $k_\pi$, he can't calculate a number
    $r_\pi = \alpha - c_\pi k_\pi$ that would produce
    $[r_\pi G + c_\pi K_\pi] = \alpha G$. A verifier would reject his
    signature. Liu *et al.* prove forgeries that manage to pass
    verification are extremely improbable [@Liu2004].

[^16]: Monero MLSAG uses key prefixing. Each challenge contains explicit
    public keys like this (adding the $K$ terms absent from bLSAG; key
    images are included in the message signed):
    $$c_{\pi+1} = \mathcal{H}_n(\mathfrak{m}, K_{\pi, 1}, [\alpha_1 G], [\alpha_1 \mathcal{H}_p(K_{\pi, 1})], ..., K_{\pi, m}, [\alpha_m G], [\alpha_m \mathcal{H}_p(K_{\pi, m})])$$

[^17]: As with bLSAG, linked MLSAG signatures do not indicate which
    public key was used to sign it. However, if the linking key image's
    sub-loops' rings have only one key in common, the culprit is
    obvious. If the culprit is identified, all other signing members of
    both signatures are revealed since they share the culprit's indices.

[^18]: The paper this section is based on is a pre-print being finalized
    for external review. CLSAG is promising as a replacement for MLSAG
    in future protocol versions, but has not been implemented, and might
    not be in the future.

[^19]: The CLSAG paper says to use different hash functions for domain
    separation, which we model by prefixing each hash with a tag
    [@MRL-0011-CLSAG], e.g. $T_1 =$ "CLSAG_1\", $T_c =$ "CLSAG_c\", etc.
    Domain separated hash functions have different outputs even with the
    same inputs. We also use key prefixing here (including
    $\mathcal{R}$, which has all the keys, in the hash). Domain
    separating is a new policy for Monero development, and will likely
    be done with all applications of hash functions added in the future
    (v13+). Historical uses of hash functions will probably be left
    alone.

[^20]: In Monero we would only check $l*\tilde{K}_1 \stackrel{?}{=} 0$
    for the primary key image. Auxiliary keys would be stored as
    $(1/8)*\tilde{K}_j$, and during verification multiplied by 8 (recall
    Section
    [\[elliptic_curves_section\]](#elliptic_curves_section){reference-type="ref"
    reference="elliptic_curves_section"}), which is more efficient. The
    method discrepancy is an implementation choice, since linkable key
    images are very important and so shouldn't be messed with
    aggressively, and the other method was employed in prior protocol
    versions.
