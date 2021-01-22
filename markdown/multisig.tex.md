# Multisignatures in Monero {#chapter:multisignatures}

Cryptocurrency transactions are not reversible. If someone steals
private keys or succeeds in a scam, the money lost could be gone
forever. Dividing signing power between people can weaken the potential
danger of a miscreant.

Say you deposit money into a joint account with a security company that
monitors for suspicious activity related to your account. Transactions
can only be signed if both you and the company cooperate. If someone
steals your keys, you can notify the company there is a problem and the
company will stop signing transactions for your account. This is usually
called an 'escrow' service.[^1]\
Cryptocurrencies use a 'multisignature' technique to achieve
collaborative signing with so-called 'M-of-N multisig'. In M-of-N, N
people cooperate to make a joint key, and only M people (M $\leq$ N) are
needed to sign with that key. We begin this chapter by introducing the
basics of N-of-N multisig, progress into N-of-N Monero multisig,
generalize for M-of-N multisig, and then explain how to nest multisig
keys inside other multisig keys.\
In this chapter we focus on how we feel multisig *should* be done, based
on the recommendations in [@MRL-0009-multisig], and various observations
about efficient implementation. We try to point out in footnotes where
the current implementation deviates from what is described.[^2] Our
contributions are detailing M-of-N multisig, and a novel approach to
nesting multisig keys.

## Communicating with co-signers {#sec:communicating}

Building joint keys and joint transactions requires communicating secret
information between people who could be located all around the globe. To
keep that information secure from observers, co-signers need to encrypt
the messages they send each other.

Diffie-Hellman exchange (ECDH) is a very simple way to encrypt messages
using elliptic curve cryptography. We already mentioned this in Section
[\[sec:pedersen_monero\]](#sec:pedersen_monero){reference-type="ref"
reference="sec:pedersen_monero"}, where Monero output amounts are
communicated to recipients via the shared secret $r K^v$. It looked like
this: $$\begin{aligned}
  \mathit{amount}_t = b_t \oplus_8 \mathcal{H}_n(``amount”, \mathcal{H}_n(r K_B^v, t))\end{aligned}$$

We could easily extend this to any message. First encode the message as
a series of bits, then break it into chunks equal in size to the output
of $\mathcal{H}_n$. Generate a random number $r \in \mathbb{Z}_l$ and
perform a Diffie-Hellman exchange on all the message chunks using the
recipient's public key $K$. Send those encrypted chunks along with the
public key $r G$ to the intended recipient, who can then decrypt the
message with the shared secret $k r G$. Message senders should also
create a signature on their encrypted message (or just the encrypted
message's hash for simplicity) so receivers can confirm messages weren't
tampered with (a signature is only verifiable on the correct message
$\mathfrak{m}$).

Since encryption is not essential to the operation of a cryptocurrency
like Monero, we do not feel it necessary to go into more detail. Curious
readers can look at this excellent conceptual overview
[@tutorialspoint-cryptography], or see a technical description of the
popular AES encryption scheme here [@AES-encryption]. Also, Dr.
Bernstein developed an encryption scheme known as ChaCha
[@Bernstein_chacha; @chacha-irtf], which the primary Monero
implementation uses to encrypt certain sensitive information related to
users' wallets (such as key images for owned outputs).

## Key aggregation for addresses {#sec:key-aggregation}

### Naive approach {#sec:naive-key-aggregation}

Let's say N people want to create a group multisignature address, which
we denote $(K^{v,grp},K^{s,grp})$. Funds can be sent to that address
just like any normal address, but, as we will see later, to spend those
funds all N people have to work together to sign transactions.

Since all N participants should be able to view funds received by the
group address, we can let everyone know the group view key $k^{v,grp}$
(recall Sections
[\[sec:user-keys\]](#sec:user-keys){reference-type="ref"
reference="sec:user-keys"} and
[\[sec:one-time-addresses\]](#sec:one-time-addresses){reference-type="ref"
reference="sec:one-time-addresses"}). To give all participants equal
power, the view key can be a sum of view key components that all
participants send each other securely. For participant
$e \in \{1,...,N\}$, his base view key component is
$k^{v,base}_e \in_R \mathbb{Z}_l$, and all participants can compute the
group private view key $$k^{v,grp} = \sum^{N}_{e=1} k^{v,base}_e$$

In a similar fashion, the group spend key $K^{s,grp} = k^{s,grp} G$
could be a sum of private spend key base components. However, if someone
knows all the private spend key components then they know the total
private spend key. Add in the private view key and he can sign
transactions on his own. It wouldn't be multisignature, just a plain old
signature.

Instead, we get the same effect if the group spend key is a sum of
public spend keys. Say the participants have base public spend keys
$K^{s,base}_e$ which they send each other securely. Now let them each
compute $$K^{s,grp} = \sum_e K^{s,base}_e$$

Clearly this is the same as $$K^{s,grp} = (\sum_e k^{s,base}_e)*G$$

### Drawbacks to the naive approach {#subsec:drawbacks-naive-aggregation-cancellation}

Using a sum of public spend keys is intuitive and seemingly
straightforward, but leads to a couple issues.

#### Key aggregation test {#key-aggregation-test .unnumbered}

An outside adversary who knows all the base public spend keys
$K^{s,base}_e$ can trivially test a given public address $(K^v,K^s)$ for
key aggregation by computing $K^{s,grp} = \sum_e K^{s,base}_e$ and
checking $K^s \stackrel{?}{=} K^{s,grp}$. This ties in with a broader
requirement that aggregated keys be indistinguishable from normal keys,
so observers can't gain any insight into users' activities based on the
kind of address they publish.[^3]

We can get around this by creating new base spend keys for each
multisignature address, or by masking old keys. The former case is easy,
but may be inconvenient.

The second case proceeds like this: given participant $e$'s old key pair
$(K^v_e,K^s_e)$ with private keys $(k^v_e,k^s_e)$ and random masks
$\mu^v_e,\mu^s_e$,[^4] let his new base private key components for the
group address be $$\begin{aligned}
    k^{v,base}_e &= \mathcal{H}_n(k^v_e,\mu^v_e)\\
    k^{s,base}_e &= \mathcal{H}_n(k^s_e,\mu^s_e)\end{aligned}$$

If participants don't want observers to gather the new keys and test for
key aggregation, they would have to communicate their new key components
to each other securely.[^5]

If key aggregation tests are not a concern, they could publish their
public key base components $(K^{v,base}_e,K^{s,base}_e)$ as normal
addresses. Any third party could then compute the group address from
those individual addresses and send funds to it, without interacting
with any of the joint recipients [@maxwell2018simple-musig].

#### Key cancellation {#key-cancellation .unnumbered}

If the group spend key is a sum of public keys, a dishonest participant
who learns his collaborators' spend key base components ahead of time
can cancel them.

For example, say Alice and Bob want to make a group address. Alice, in
good faith, tells Bob her key components $(k^{v,base}_A,K^{s,base}_A)$.
Bob privately makes his key components $(k^{v,base}_B,K^{s,base}_B)$ but
doesn't tell Alice right away. Instead, he computes
$K'^{s,base}_B = K^{s,base}_B - K^{s,base}_A$ and tells Alice
$(k^{v,base}_B,K'^{s,base}_B)$. The group address is: $$\begin{aligned}
    K^{v,grp} &= (k^{v,base}_A + k^{v,base}_B) G \\
             &= k^{v,grp} G\\
    K^{s,grp} &= K^{s,base}_A + K'^{s,base}_B \\
             &= K^{s,base}_A + (K^{s,base}_B - K^{s,base}_A)\\
             &= K^{s,base}_B\end{aligned}$$

This leaves a group address $(k^{v,grp} G,K^{s,base}_B)$ where Alice
knows the private group view key, and Bob knows both the private view
key *and* private spend key! Bob can sign transactions on his own,
fooling Alice, who might believe funds sent to the address can only be
spent with her permission.

We could solve this issue by requiring each participant, before
aggregating keys, to make a signature proving they know the private key
to their spend key component [@old-multisig-mrl-note].[^6] This is
inconvenient and vulnerable to implementation mistakes. Fortunately a
solid alternative is available.

### Robust key aggregation {#sec:robust-key-aggregation}

To easily resist key cancellation we make a small change to spend key
aggregation (leaving view key aggregation the same). Let the set of N
signers' base spend key components be
$\mathbb{S}^{base} = \{K^{s,base}_1,...,K^{s,base}_N\}$, ordered
according to some convention (such as smallest to largest numerically,
i.e. lexicographically).[^7] The robust aggregated spend key is
[@MRL-0009-multisig][^8][^9]
$$K^{s,grp} = \sum_e \mathcal{H}_n(T_{agg},\mathbb{S}^{base},K^{s,base}_e)K^{s,base}_e$$

Now if Bob tries to cancel Alice's spend key, he gets stuck with a very
difficult problem. $$\begin{aligned}
    K^{s,grp} &= \mathcal{H}_n(T_{agg},\mathbb{S},K^{s}_A)K^{s}_A + \mathcal{H}_n(T_{agg},\mathbb{S},K'^{s}_B)K'^{s}_B \\
             &= \mathcal{H}_n(T_{agg},\mathbb{S},K^{s}_A)K^{s}_A + \mathcal{H}_n(T_{agg},\mathbb{S},K'^{s}_B)K^{s}_B - \mathcal{H}_n(T_{agg},\mathbb{S},K'^{s}_B)K^{s}_A \\
             &= [\mathcal{H}_n(T_{agg},\mathbb{S},K^{s}_A) - \mathcal{H}_n(T_{agg},\mathbb{S},K'^{s}_B)]K^{s}_A + \mathcal{H}_n(T_{agg},\mathbb{S},K'^{s}_B)K^{s}_B\end{aligned}$$

We leave Bob's frustration to the reader's imagination.

Just like with the naive approach, any third party who knows
$\mathbb{S}^{base}$ and the corresponding public view keys can compute
the group address.

Since participants don't need to prove they know their private spend
keys, or really interact at all before signing transactions, our robust
key aggregation meets the so-called *plain public-key model*, where "the
only requirement is that each potential signer has a public
key\"[@maxwell2018simple-musig].[^10]

#### Functions `premerge` and `merge` {#functions-premerge-and-merge .unnumbered}

More formally, and for the sake of clarity going forward, we can say
there is an operation `premerge` which takes in a set of base keys
$\mathbb{S}^{base}$, and outputs a set of aggregation keys
$\mathbb{K}^{agg}$ of equal size, where element[^11]
$$\mathbb{K}^{agg}[e] = \mathcal{H}_n(T_{agg},\mathbb{S}^{base},K^{s,base}_e)K^{s,base}_e$$

The aggregation private keys $k^{agg}_e$ are used in group
signatures.[^12]

There is another operation `merge` which takes the aggregation keys from
`premerge` and constructs the group signing key (e.g. spend key for
Monero) $$K^{grp} = \sum_e \mathbb{K}^{agg}[e]$$

We generalize these functions for (N-1)-of-N and M-of-N in Section
[1.6.2](#sec:n-1-of-n){reference-type="ref" reference="sec:n-1-of-n"},
and further generalize them for nested multisig in Section
[1.7.2](#subsec:nesting-multisig-keys){reference-type="ref"
reference="subsec:nesting-multisig-keys"}.

## Thresholded Schnorr-like signatures {#sec:threshold-schnorr}

It takes a certain amount of signers for a multisignature to work, so we
say there is a 'threshold' of signers below which the signature can't be
produced. A multisignature with N participants that requires all N
people to build a signature, usually referred to as *N-of-N multisig*,
would have a threshold of N. Later we will extend this to M-of-N (M
$\leq$ N) multisig where N participants create the group address but
only M people are needed to make signatures.

Let's take a step back from Monero. All signature schemes in this
document lead from Maurer's general zero-knowledge proof of knowledge
[@simple-zk-proof-maurer], so we can demonstrate the essential form of
thresholded signatures using a simple Schnorr-like signature (recall
Section
[\[sec:signing-messages\]](#sec:signing-messages){reference-type="ref"
reference="sec:signing-messages"}) [@old-multisig-mrl-note].

### Signature {#signature .unnumbered}

Say there are N people who each have a public key in the set
$\mathbb{K}^{agg}$, where each person $e \in \{1,...,N\}$ knows the
private key $k^{agg}_e$. Their N-of-N group public key, which they will
use to sign messages, is $K^{grp}$. Suppose they want to jointly sign a
message $\mathfrak{m}$. They could collaborate on a basic Schnorr-like
signature like this

1.  Each participant $e \in \{1,...,N\}$ does the following:

    1.  picks random component $\alpha_e \in_R \mathbb{Z}_l$,

    2.  computes $\alpha_e G$

    3.  commits to it with
        $C^{\alpha}_e = \mathcal{H}_n(T_{com},\alpha_e G)$,

    4.  and sends $C^{\alpha}_e$ to the other participants securely.

2.  Once all commitments $C^{\alpha}_e$ have been collected, each
    participant sends their $\alpha_e G$ to the other participants
    securely. They must verify that
    $C^{\alpha}_e \stackrel{?}{=} \mathcal{H}_n(T_{com},\alpha_e G)$ for
    all other participants.

3.  Each participant computes $$\alpha G = \sum_e \alpha_e G$$

4.  Each participant $e \in \{1,...,N\}$ does the following:[^13]

    1.  computes the challenge
        $c = \mathcal{H}_n(\mathfrak{m},[\alpha G])$,

    2.  defines their response component
        $r_e = \alpha_e - c* k^{agg}_e \pmod l$,

    3.  and sends $r_e$ to the other participants securely.

5.  Each participant computes $$r = \sum_e r_e$$

6.  Any participant can publish the signature
    $\sigma(\mathfrak{m}) = (c,r)$.

### Verification {#verification .unnumbered}

Given $K^{grp}$, $\mathfrak{m}$, and $\sigma(\mathfrak{m}) = (c,r)$:

1.  Compute the challenge
    $c' = \mathcal{H}_n(\mathfrak{m},[r G + c*K^{grp}])$.

2.  If $c = c'$ then the signature is legitimate except with negligible
    probability.

We included the superscript $grp$ for clarity, but in reality the
verifier has no way to tell $K^{grp}$ is a merged key unless a
participant tells him, or unless he knows the base or aggregation key
components.

### Why it works {#why-it-works .unnumbered}

Response $r$ is the core of this signature. Participant $e$ knows two
secrets in $r_e$ ($\alpha_e$ and $k^{agg}_e$), so his private key
$k^{agg}_e$ is information-theoretically secure from other participants
(assuming he never reuses $\alpha_e$). Moreover, verifiers use the group
public key $K^{grp}$, so all key components are needed to build
signatures. $$\begin{aligned}
    r G &= (\sum_e r_e) G \\
      &= (\sum_e (\alpha_e - c*k^{agg}_e)) G \\
      &= (\sum_e \alpha_e) G - c*(\sum_e k^{agg}_e) G \\
      &= \alpha G - c*K^{grp} \\
    \alpha G &= r G + c*K^{grp} \\
    \mathcal{H}_n(\mathfrak{m},[\alpha G]) &= \mathcal{H}_n(\mathfrak{m},[r G + c*K^{grp}]) \\
    c &= c'\end{aligned}$$

### Additional commit-and-reveal step {#additional-commit-and-reveal-step .unnumbered}

The reader may be wondering where Step 2 came from. Without
commit-and-reveal [@MRL-0009-multisig], a malicious co-signer could
learn all $\alpha_e G$ *before* the challenge is computed. This lets him
control the challenge produced to some degree, by modifying his own
$\alpha_e G$ prior to sending it out. He can use the response components
collected from multiple controlled signatures to derive other signers'
private keys $k^{agg}_e$ in sub-exponential time
[@cryptoeprint:2018:417], a serious security threat. This threat relies
on Wagner's generalization [@generalized-birthday-wagner] (see also
[@adam-wagnerian-tragedies] for a more intuitive explanation) of the
birthday problem [@birthday-problem].[^14]

## MLSTAG Ring Confidential signatures for Monero {#sec:MLSTAG-RingCT}

Monero thresholded ring confidential transactions add some complexity
because MLSTAG (thresholded MLSAG) signing keys are one-time addresses
and commitments to zero (for input amounts).

Recalling Section
[\[sec:multi_out_transactions\]](#sec:multi_out_transactions){reference-type="ref"
reference="sec:multi_out_transactions"}, a one-time address assigning
ownership of a transaction's $t$output to whoever has public address
$(K^v_t,K^s_t)$ goes like this $$\begin{aligned}
  K_t^o &= \mathcal{H}_n(r K_t^v, t)G + K_t^s = (\mathcal{H}_n(r K_t^v, t) + k_t^s)G  \\ 
  k_t^o &= \mathcal{H}_n(r K_t^v, t) + k_t^s\end{aligned}$$

We can update our notation for outputs received by a group address
$(K^{v,grp}_t,K^{s,grp}_t)$: $$\begin{aligned}
  K^{o,grp}_t &= \mathcal{H}_n(r K^{v,grp}_t, t)G + K^{s,grp}_t  \\ 
  k^{o,grp}_t &= \mathcal{H}_n(r K^{v,grp}_t, t) + k^{s,grp}_t\end{aligned}$$

Just as before, anyone with $k^{v,grp}_t$ and $K^{s,grp}_t$ can discover
$K^{o,grp}_t$ is their address's owned output, and can decode the
Diffie-Hellman term for output amount and reconstruct the corresponding
commitment mask (Section
[\[sec:pedersen_monero\]](#sec:pedersen_monero){reference-type="ref"
reference="sec:pedersen_monero"}).

This also means multisig subaddresses are possible (Section
[\[sec:subaddresses\]](#sec:subaddresses){reference-type="ref"
reference="sec:subaddresses"}). Multisig transactions using funds
received to a subaddress require some fairly straightforward
modifications to the following algorithms, which we mention in
footnotes.[^15]

### `RCTTypeBulletproof2` with N-of-N multisig {#sec:rcttypebulletproof2-multisig}

Most parts of a multisig transaction can be completed by whoever
initiated it. Only the MLSTAG signatures require collaboration. An
initiator should do these things to prepare for an `RCTTypeBulletproof2`
transaction (recall Section
[\[sec:RCTTypeBulletproof2\]](#sec:RCTTypeBulletproof2){reference-type="ref"
reference="sec:RCTTypeBulletproof2"}):

1.  Generate a transaction private key $r \in_R \mathbb{Z}_l$ (Section
    [\[sec:one-time-addresses\]](#sec:one-time-addresses){reference-type="ref"
    reference="sec:one-time-addresses"}) and compute the corresponding
    public key $r G$ (or multiple such keys if dealing with a subaddress
    recipient; Section
    [\[sec:subaddresses\]](#sec:subaddresses){reference-type="ref"
    reference="sec:subaddresses"}).

2.  Decide the inputs to be spent ($j \in \{1,...,m\}$ owned outputs
    with one-time addresses $K^{o,grp}_j$ and amounts $a_1,...,a_m$),
    and recipients to receive funds ($t \in \{0,...,p-1\}$ new outputs
    with amounts $b_0,...,b_{p-1}$ and one-time addresses $K^{o}_t$).
    This includes the miner's fee $f$ and its commitment $f H$. Decide
    each input's set of decoy ring members.

3.  Encode each output's amount $\mathit{amount}_t$ (Section
    [\[sec:pedersen_monero\]](#sec:pedersen_monero){reference-type="ref"
    reference="sec:pedersen_monero"}), and compute the output
    commitments $C^b_t$.

4.  Select, for each input $j \in \{1,...,m-1\}$, pseudo output
    commitment mask components $x'_{j} \in_R \mathbb{Z}_l$, and compute
    the $m$mask as (Section
    [\[sec:ringct-introduction\]](#sec:ringct-introduction){reference-type="ref"
    reference="sec:ringct-introduction"})
    $$x'_m = \sum_t y_t - \sum_{j=1}^{m-1} x'_j$$ Compute the pseudo
    output commitments $C'^a_{j}$.

5.  Produce the aggregate Bulletproof range proof for all outputs.
    Recall Section
    [\[sec:range_proofs\]](#sec:range_proofs){reference-type="ref"
    reference="sec:range_proofs"}.

6.  Prepare for MLSTAG signatures by generating, for the commitments to
    zero, seed components $\alpha^z_{j} \in_R \mathbb{Z}_l$, and
    computing $\alpha^z_{j} G$.[^16]

He sends all this information to the other participants securely. Now
the group of signers is ready to build input signatures with their
private keys $k^{s,agg}_e$, and the commitments to zero
$C^a_{\pi,j} - C'^a_{\pi,j} = z_j G$.

#### MLSTAG RingCT {#mlstag-ringct .unnumbered}

First they construct the group key images for all inputs
$j \in \{1,...,m\}$ with one-time addresses $K^{o,grp}_{\pi,j}$.[^17]

1.  For each input $j$ each participant $e$ does the following:

    1.  computes partial key image
        $\tilde{K}^{o}_{j,e} = k^{s,agg}_e \mathcal{H}_p(K^{o,grp}_{\pi,j})$,

    2.  and sends $\tilde{K}^{o}_{j,e}$ to the other participants
        securely.

2.  Each participant can now compute, using $u_j$ as the output index in
    the transaction where $K^{o,grp}_{\pi,j}$ was sent to the multisig
    address,[^18]
    $$\tilde{K}^{o,grp}_j = \mathcal{H}_n(k^{v,grp} r G, u_j) \mathcal{H}_p(K^{o,grp}_{\pi,j}) + \sum_e \tilde{K}^{o}_{j,e}$$

Then they build a MLSTAG signature for each input $j$.

1.  Each participant $e$ does the following:

    1.  generates seed components $\alpha_{j,e} \in_R \mathbb{Z}_l$ and
        computes $\alpha_{j,e} G$, and
        $\alpha_{j,e} \mathcal{H}_p(K^{o,grp}_{\pi,j})$,

    2.  generates, for $i \in \{1,...,v+1\}$ except $i = \pi$, random
        components $r_{i,j,e}$ and $r^z_{i,j,e}$,

    3.  computes the commitment
        $$C^{\alpha}_{j,e} = \mathcal{H}_n(T_{com},\alpha_{j,e} G, \alpha_{j,e} \mathcal{H}_p(K^{o,grp}_{\pi,j}),r_{1,j,e},...,r_{v+1,j,e},r^z_{1,j,e},...,r^z_{v+1,j,e})$$

    4.  and sends $C^{\alpha}_{j,e}$ to the other participants securely.

2.  Upon receiving all $C^{\alpha}_{j,e}$ from the other participants,
    send all $\alpha_{j,e} G$,
    $\alpha_{j,e} \mathcal{H}_p(K^{o,grp}_{\pi,j})$, and $r_{i,j,e}$ and
    $r^z_{i,j,e}$, and verify each participant's original commitment was
    valid.

3.  Each participant can compute all $$\begin{aligned}
            \alpha_{j} G &= \sum_e \alpha_{j,e} G\\
            \alpha_{j} \mathcal{H}_p(K^{o,grp}_{\pi,j}) &= \sum_e \alpha_{j,e} \mathcal{H}_p(K^{o,grp}_{\pi,j})\\
            r_{i,j} &= \sum_e r_{i,j,e}\\
            r^{z}_{i,j} &= \sum_e r^z_{i,j,e}
        \end{aligned}$$

4.  Each participant can build the signature loop (see Section
    [\[sec:MLSAG\]](#sec:MLSAG){reference-type="ref"
    reference="sec:MLSAG"}).

5.  To finish closing the signature, each participant $e$ does the
    following:

    1.  defines
        $r_{\pi,j,e} = \alpha_{j,e} - c_{\pi} k^{s,agg}_e \pmod l$,

    2.  and sends $r_{\pi,j,e}$ to the other participants securely.

6.  Everyone can compute (recall $\alpha^z_{j,e}$ was created by the
    initiator)[^19]
    $$r_{\pi,j} = \sum_e r_{\pi,j,e} - c_{\pi}*\mathcal{H}_n(k^{v,grp} r G, u_j)$$
    $$r^{z}_{\pi,j} = \alpha^z_{j,e} - c_{\pi} z_j \pmod l$$

The signature for input $j$ is
$\sigma_j(\mathfrak{m}) = (c_1,r_{1,j},r^{z}_{1,j},...,r_{v+1,j},r^{z}_{v+1,j})$
with $\tilde{K}^{o,grp}_j$.

Since in Monero the message $\mathfrak{m}$ and the challenge $c_{\pi}$
depend on all other parts of the transaction, any participant who tries
to cheat by sending the wrong value, at any point in the whole process,
to his fellow signers will cause the signature to fail. The response
$r_{\pi,j}$ is only useful for the $\mathfrak{m}$ and $c_{\pi}$ it is
defined for.

### Simplified communication {#sec:simplified-communication}

It takes a lot of steps to build a multisignature Monero transaction. We
can reorganize and simplify some of them so that signer interactions are
encompassed by two parts with five total rounds.

1.  *Key aggregation for a multisig public address*: Anyone with a set
    of public addresses can run `premerge` on them and then `merge` an
    N-of-N address, but no participant will know the group view key
    unless they learn all the components, so the group starts by sending
    $k^{v}_e$ and $K^{s,base}_e$ to each other securely. Any participant
    can `premerge` and `merge` and publish $(K^{v,grp},K^{s,grp})$,
    allowing the group to receive funds to the group address. M-of-N
    aggregation requires more steps, which we describe in Section
    [1.6](#sec:smaller-thresholds){reference-type="ref"
    reference="sec:smaller-thresholds"}.

2.  *Transactions*:

    1.  Some participant or sub-coalition (the initiator) decides to
        write a transaction. They choose $m$ inputs with one-time
        addresses $K^{o,grp}_{j}$ and amount commitments $C^a_j$, $m$
        sets of $v$ additional one-time addresses and commitments to be
        used as ring decoys, pick $p$ output recipients with public
        addresses $(K^v_t,K^s_t)$ and amounts $b_t$ to send them, decide
        a transaction fee $f$, pick a transaction private key $r$,[^20]
        generate pseudo output commitment masks $x'_{j}$ with
        $j \neq m$, construct the ECDH term $\mathit{amount}_t$ for each
        output, produce an aggregate range proof, and generate signature
        openers $\alpha^z_j$ for all inputs' commitments to zero and
        random scalars $r_{i,j}$ and $r^z_{i,j}$ with
        $i \neq \pi_j$.[^21] They also prepare their contribution for
        the next communication round.\
        The initiator sends all this information to the other
        participants securely.[^22] The other participants can signal
        agreement by sending their part of the next communication round,
        or negotiate for changes.

    2.  Each participant chooses their opening components for the MLSTAG
        signature(s), commits to them, calculates their partial key
        images, and sends those commitments and partial images to other
        participants securely.\
        MLSTAG Signature(s): key image $\tilde{K}^{o}_{j,e}$, signature
        randomness $\alpha_{j,e} G$, and
        $\alpha_{j,e} \mathcal{H}_p(K^{o,grp}_{\pi,j})$. Partial key
        images don't need to be in committed data, as they can't be used
        to extract signers' private keys. They are also useful for
        viewing which owned outputs have been spent, so for the sake of
        modular design should be handled separately.

    3.  Upon receiving all signature commitments, each participant sends
        the committed information to the other participants securely.

    4.  Each participant closes their part of the MLSTAG signature(s),
        sending all $r_{{\pi_j},j,e}$ to the other participants
        securely.[^23]

Assuming the process went well, all participants can finish writing the
transaction and broadcast it on their own. Transactions authored by a
multisig coalition are indistinguishable from those authored by
individuals.

## Recalculating key images {#sec:recalculating-key-images-multisig}

If someone loses their records and wants to calculate their address's
balance (received minus spent funds), they need to check the blockchain.
View keys are only useful for reading received funds, so users need to
calculate key images for all owned outputs to see if they have been
spent, by comparing with key images stored in the blockchain. Since
members of a group address can't compute key images on their own, they
need to enlist the other participants' help.

Calculating key images from a simple sum of components might fail if
dishonest participants report false keys.[^24] Given a received output
with one-time address $K^{o,grp}$, the group can produce a simple
'linkable' Schnorr-like proof (basically single-key bLSTAG, recall
Sections
[\[sec:proofs-discrete-logarithm-multiple-bases\]](#sec:proofs-discrete-logarithm-multiple-bases){reference-type="ref"
reference="sec:proofs-discrete-logarithm-multiple-bases"} and
[\[blsag_note\]](#blsag_note){reference-type="ref"
reference="blsag_note"}) to prove the key image $\tilde{K}^{o,grp}$ is
legitimate without revealing their private spend key components or
needing to trust each other.

### Proof {#proof .unnumbered}

1.  Each participant $e$ does the following:

    1.  computes
        $\tilde{K}^{o}_{e} = k^{s,agg}_e \mathcal{H}_p(K^{o,grp})$,

    2.  generates seed component $\alpha_e \in_R \mathbb{Z}_l$ and
        computes $\alpha_e G$ and $\alpha_e \mathcal{H}_p(K^{o,grp})$,

    3.  commits to the data with
        $C^{\alpha}_{e} = \mathcal{H}_n(T_{com}, \alpha_e G, \alpha_e \mathcal{H}_p(K^{o,grp}))$,

    4.  and sends $C^{\alpha}_{e}$ and $\tilde{K}^{o}_{e}$ to the other
        participants securely.

2.  Upon receiving all $C^{\alpha}_{e}$, each participant sends the
    committed information and verifies other participants' commitments
    were legitimate.

3.  Each participant can compute:[^25]
    $$\tilde{K}^{o,grp} = \mathcal{H}_n(k^{v,grp} r G, u) \mathcal{H}_p(K^{o,grp}) + \sum_e \tilde{K}^{o}_{e}$$
    $$\alpha G = \sum_e \alpha_{e} G$$
    $$\alpha \mathcal{H}_p(K^{o,grp}) = \sum_e \alpha_{e} \mathcal{H}_p(K^{o,grp})$$

4.  Each participant computes the challenge[^26]
    $$c = \mathcal{H}_n([\alpha G],[\alpha \mathcal{H}_p(K^{o,grp})])$$

5.  Each participant does the following:

    1.  defines $r_e = \alpha_e - c*k^{s,agg}_e \pmod l$,

    2.  and sends $r_e$ to the other participants securely.

6.  Each participant can compute[^27]
    $$r^{resp} = \sum_e r_e - c*\mathcal{H}_n(k^{v,grp} r G, u)$$

The proof is $(c,r^{resp})$ with $\tilde{K}^{o,grp}$.

### Verification {#verification-1 .unnumbered}

1.  Check $l \tilde{K}^{o,grp} \stackrel{?}{=} 0$.

2.  Compute
    $c' = \mathcal{H}_n([r^{resp} G + c*K^{o,grp}],[r^{resp} \mathcal{H}_p(K^{o,grp}) + c*\tilde{K}^{o,grp}])$.

3.  If $c = c'$ then the key image $\tilde{K}^{o,grp}$ corresponds to
    one-time address $K^{o,grp}$ (except with negligible probability).

## Smaller thresholds {#sec:smaller-thresholds}

At the beginning of this chapter we discussed escrow services, which
used 2-of-2 multisig to split signing power between a user and a
security company. That setup isn't ideal, because if the security
company is compromised, or refuses to cooperate, your funds may get
stuck.

We can get around that potentiality with a 2-of-3 multisig address,
which has three participants but only needs two of them to sign
transactions. An escrow service provides one key and users provide two
keys. Users can store one key in a secure location (like a safety
deposit box), and use the other for day-to-day purchases. If the escrow
service fails, a user can use the secure key and day key to withdraw
funds.

Multisignatures with sub-N thresholds have a wide range of uses.

### 1-of-N key aggregation {#sec:1-of-n}

Suppose a group of people want to make a multisig key $K^{grp}$ they can
all sign with. The solution is trivial: let everyone know the private
key $k^{grp}$. There are three ways to do this.

1.  One participant or sub-coalition selects a key and sends it to
    everyone else securely.

2.  All participants compute private key components and send them
    securely, using the simple sum as the merged key.[^28]

3.  Participants extend M-of-N multisig to 1-of-N. This might be useful
    if an adversary has access to the group's communications.

In this case, for Monero, everyone would know the private keys
$(k^{v,grp,{1\textrm{xN}}},k^{s,grp,{1\textrm{xN}}})$. Before this
section all group keys were N-of-N, but now we use superscript 1xN to
denote keys related to 1-of-N signing.

### (N-1)-of-N key aggregation {#sec:n-1-of-n}

In an (N-1)-of-N group key, such as 2-of-3 or 4-of-5, any set of (N-1)
participants can sign. We achieve this with Diffie-Hellman shared
secrets. Lets say there are participants $e \in \{1,...,N\}$, with base
public keys $K^{base}_e$ which they are all aware of.

Each participant $e$ computes, for $w \in \{1,...,N\}$ but $w \neq e$
$$k^{sh,\textrm{(N-1)xN}}_{e,w} = \mathcal{H}_n(k^{base}_e K^{base}_w)$$

Then he computes all
$K^{sh,\textrm{(N-1)xN}}_{e,w} = k^{sh,\textrm{(N-1)xN}}_{e,w} G$ and
sends them to the other participants securely. We now use superscript
$sh$ to denote keys shared by a sub-group of participants.

Each participant will have (N-1) shared private key components
corresponding to each of the other participants, making N\*(N-1) total
keys between everyone. All keys are shared by two Diffie-Hellman
partners, so there are really \[N\*(N-1)\]/2 unique keys. Those unique
keys compose the set $\mathbb{S}^{\textrm{(N-1)xN}}$.

#### Generalizing `premerge` and `merge` {#generalizing-premerge-and-merge .unnumbered}

This is where we update the definition of `premerge` from Section
[1.2.3](#sec:robust-key-aggregation){reference-type="ref"
reference="sec:robust-key-aggregation"}. Its input will be the set
$\mathbb{S}^{\textrm{MxN}}$, where $M$ is the 'threshold' that the set's
keys are prepared for. When $M = N$,
$\mathbb{S}^{\textrm{NxN}} = \mathbb{S}^{base}$, and when $M < N$ it
contains shared keys. The output is $\mathbb{K}^{agg,\textrm{MxN}}$.

The \[N\*(N-1)\]/2 key components in $\mathbb{K}^{agg,\textrm{(N-1)xN}}$
can be sent into `merge`, outputting $K^{grp,\textrm{(N-1)xN}}$.
Importantly, all \[N\*(N-1)\]/2 private key components can be assembled
with just (N-1) participants since each participant shares one
Diffie-Hellman secret with the Nguy.

#### A 2-of-3 example {#a-2-of-3-example .unnumbered}

Say there are three people with public keys
$\{K^{base}_1,K^{base}_2,K^{base}_3\}$, to which they each know a
private key, who want to make a 2-of-3 multisig key. After
Diffie-Hellman and sending each other the public keys they each know the
following:

1.  Person 1: $k^{sh,\textrm{2x3}}_{1,2}$, $k^{sh,\textrm{2x3}}_{1,3}$,
    $K^{sh,\textrm{2x3}}_{2,3}$

2.  Person 2: $k^{sh,\textrm{2x3}}_{2,1}$, $k^{sh,\textrm{2x3}}_{2,3}$,
    $K^{sh,\textrm{2x3}}_{1,3}$

3.  Person 3: $k^{sh,\textrm{2x3}}_{3,1}$, $k^{sh,\textrm{2x3}}_{3,2}$,
    $K^{sh,\textrm{2x3}}_{1,2}$

Where $k^{sh,\textrm{2x3}}_{1,2} = k^{sh,\textrm{2x3}}_{2,1}$, and so
on. The set
$\mathbb{S}^{\textrm{2x3}} = \{ K^{sh,\textrm{2x3}}_{1,2}, K^{sh,\textrm{2x3}}_{1,3}, K^{sh,\textrm{2x3}}_{2,3}\}$.

Performing `premerge` and `merge` creates the group key:[^29]
$$\begin{aligned}
    K^{grp,\textrm{2x3}} = &\mathcal{H}_n(T_{agg},\mathbb{S}^{\textrm{2x3}},K^{sh,\textrm{2x3}}_{1,2}) K^{sh,\textrm{2x3}}_{1,2} + \\
                           &\mathcal{H}_n(T_{agg},\mathbb{S}^{\textrm{2x3}},K^{sh,\textrm{2x3}}_{1,3}) K^{sh,\textrm{2x3}}_{1,3} + \\
                           &\mathcal{H}_n(T_{agg},\mathbb{S}^{\textrm{2x3}},K^{sh,\textrm{2x3}}_{2,3}) K^{sh,\textrm{2x3}}_{2,3}\end{aligned}$$

Now let's say persons 1 and 2 want to sign a message $\mathfrak{m}$. We
will use a basic Schnorr-like signature to demonstrate.

1.  Each participant $e \in \{1,2\}$ does the following:

    1.  picks random component $\alpha_e \in_R \mathbb{Z}_l$,

    2.  computes $\alpha_e G$,

    3.  commits with
        $C^{\alpha}_{e} = \mathcal{H}_n(T_{com},\alpha_e G)$,

    4.  and sends $C^{\alpha}_{e}$ to the other participants securely.

2.  On receipt of all $C^{\alpha}_{e}$, each participant sends out
    $\alpha_e G$ and verifies the other commitments were legitimate.

3.  Each participant computes $$\alpha G = \sum_e \alpha_e G$$
    $$c = \mathcal{H}_n(\mathfrak{m},[\alpha G])$$

4.  Participant 1 does the following:

    1.  computes
        $r_1 = \alpha_1 - c*[k^{agg,\textrm{2x3}}_{1,3} + k^{agg,\textrm{2x3}}_{1,2}]$,

    2.  and sends $r_1$ to participant 2 securely.

5.  Participant 2 does the following:

    1.  computes $r_2 = \alpha_2 - c*k^{agg,\textrm{2x3}}_{2,3}$,

    2.  and sends $r_2$ to participant 1 securely.

6.  Each participant computes $$r = \sum_e r_e$$

7.  Either participant can publish the signature
    $\sigma(\mathfrak{m}) = (c,r)$.

The only change with sub-N threshold signatures is how to 'close the
loop' by defining $r_{\pi,e}$ (in the case of ring signatures, with
secret index $\pi$). Each participant must include their shared secret
corresponding to the 'missing person', but since all the other shared
secrets are doubled up there is a trick. Given the set
$\mathbb{S}^{base}$ of all participants' original keys, only the *first
person* - ordered by index in $\mathbb{S}^{base}$ - with the copy of a
shared secret uses it to calculate his $r_{\pi,e}$.[^30][^31]

In the previous example, participant 1 computes
$$r_1 = \alpha_1 - c*[k^{agg,\textrm{2x3}}_{1,3} + k^{agg,\textrm{2x3}}_{1,2}]$$

while participant 2 only computes
$$r_2 = \alpha_2 - c*k^{agg,\textrm{2x3}}_{2,3}$$

The same principle applies to computing the group key image in sub-N
threshold Monero multisig transactions.

### M-of-N key aggregation {#sec:m-of-n}

We can understand M-of-N by adjusting our perspective on (N-1)-of-N. In
(N-1)-of-N every shared secret between two public keys, such as
$K^{base}_1$ and $K^{base}_2$, contains two private keys,
$k^{base}_1 k^{base}_2 G$. It's a secret because only person 1 can
compute $k^{base}_1 K^{base}_2$, and only person 2 can compute
$k^{base}_2 K^{base}_1$.

What if there is a third person with $K^{base}_3$, there exist shared
secrets $k^{base}_1 k^{base}_2 G$, $k^{base}_1 k^{base}_3 G$, and
$k^{base}_2 k^{base}_3 G$, and the participants send those public keys
to each other (making them no longer secret)? They each contributed a
private key to two of the public keys. Now say they make a new shared
secret with that third public key.

Person 1 computes shared secret $k^{base}_1*(k^{base}_2 k^{base}_3 G)$,
person 2 computes $k^{base}_2*(k^{base}_1 k^{base}_3 G)$, and person 3
computes $k^{base}_3*(k^{base}_1 k^{base}_2 G)$. Now they all know
$k^{base}_1 k^{base}_2 k^{base}_3 G$, making a three-way shared secret
(so long as no one publishes it).

The group could use
$k^{sh,\textrm{1x3}} = \mathcal{H}_n(k^{base}_1 k^{base}_2 k^{base}_3 G)$
as a shared private key, and publish
$$K^{grp,\textrm{1x3}} = \mathcal{H}_n(T_{agg},\mathbb{S}^{\textrm{1x3}},K^{sh,\textrm{1x3}}) K^{sh,\textrm{1x3}}$$
as a 1-of-3 multisig address.

In a 3-of-3 multisig every 1 person has a secret, in a 2-of-3 multisig
every group of 2 people has a shared secret, and in 1-of-3 every group
of 3 people has a shared secret.

Now we can generalize to M-of-N: every possible group of (N-M+1) people
has a shared secret [@old-multisig-mrl-note]. If (N-M) people are
missing, all their shared secrets are owned by at least one of the M
remaining people, who can collaborate to sign with the group's key.

#### M-of-N algorithm {#m-of-n-algorithm .unnumbered}

Given participants $e \in \{1,...,N\}$ with initial private keys
$k^{base}_1,...,k^{base}_N$ who wish to produce an M-of-N merged key (M
$\leq$ N; M $\geq$ 1 and N $\geq$ 2), we can use an interactive
algorithm.

We will use $\mathbb{S}_s$ to denote all the *unique* public keys at
stage $s \in \{0,...,(N-M)\}$. The final set $\mathbb{S}_{N-M}$ is
ordered according to a sorting convention (such as smallest to largest
numerically, i.e. lexicographically). This notation is a convenience,
and $\mathbb{S}_s$ is the same as $\mathbb{S}^{\textrm{(N-s)xN}}$ from
the previous sections.

We will use $\mathbb{S}^K_{s,e}$ to denote the set of public keys each
participant created at stage $s$ of the algorithm. In the beginning
$\mathbb{S}^K_{0,e} = \{K^{base}_e\}$.

The set $\mathbb{S}^{k}_{e}$ will contain each participant's aggregation
private keys at the end.

1.  Each participant $e$ sends their original public key set
    $\mathbb{S}^K_{0,e} = \{K^{base}_e\}$ to the other participants
    securely.

2.  Each participant builds $\mathbb{S}_{0}$ by collecting all
    $\mathbb{S}^K_{0,e}$ and removing duplicates.

3.  For stage $s \in \{1,...,(N-M)\}$ (skip if M = N)

    1.  Each participant $e$ does the following:

        1.  For each element $g_{s-1}$ of
            $\mathbb{S}_{s-1} \notin \mathbb{S}^K_{s-1,e}$, compute a
            new shared secret $$k^{base}_e*\mathbb{S}_{s-1}[g_{s-1}]$$

        2.  Put all new shared secrets in $\mathbb{S}^K_{s,e}$.

        3.  If $s = (N-M)$, compute the shared private key for each
            element $x$ in $\mathbb{S}^K_{N-M,e}$
            $$\mathbb{S}^{k}_{e}[x] = \mathcal{H}_n(\mathbb{S}^K_{N-M,e}[x])$$

            and overwrite the public key by setting
            $\mathbb{S}^K_{N-M,e}[x] = \mathbb{S}^{k}_{e}[x]*G$.

        4.  Send the other participants $\mathbb{S}^K_{s,e}$.

    2.  Each participant builds $\mathbb{S}_{s}$ by collecting all
        $\mathbb{S}^K_{s,e}$ and removing duplicates.[^32]

4.  Each participant sorts $\mathbb{S}_{N-M}$ according to the
    convention.

5.  The `premerge` function takes $\mathbb{S}_{(N-M)}$ as input, and
    each aggregation key is, for
    $g \in \{1,...,(\textrm{size of }\mathbb{S}_{N-M})\}$,
    $$\mathbb{K}^{agg,\textrm{MxN}}[g] = \mathcal{H}_n(T_{agg},\mathbb{S}_{(N-M)},\mathbb{S}_{(N-M)}[g])*\mathbb{S}_{(N-M)}[g]$$

6.  The `merge` function takes $\mathbb{K}^{agg,\textrm{MxN}}$ as input,
    and the group key is
    $$K^{grp,\textrm{MxN}} = \sum^{\textrm{size of }\mathbb{S}_{N-M}}_{g = 1} \mathbb{K}^{agg,\textrm{MxN}}[g]$$

7.  Each participant $e$ overwrites each element $x$ in
    $\mathbb{S}^k_{e}$ with their aggregation private key
    $$\mathbb{S}^k_{e}[x] = \mathcal{H}_n(T_{agg},\mathbb{S}_{(N-M)},\mathbb{S}^k_{e}[x] G)*\mathbb{S}^k_{e}[x]$$

Note: If users want to have unequal signing power in a multisig, like 2
shares in a 3-of-4, they should use multiple starting key components
instead of reusing the same one.

## Key families {#sec:general-key-families}

Up to this point we have considered key aggregation between a simple
group of signers. For example, Alice, Bob, and Carol each contributing
key components to a 2-of-3 multisig address.

Now imagine Alice wants to sign all transactions from that address, but
doesn't want Bob and Carol to sign without her. In other words, (Alice +
Bob) or (Alice + Carol) are acceptable, but not (Bob + Carol).

We can achieve that scenario with two layers of key aggregation. First a
1-of-2 multisig aggregation $\mathbb{K}^{agg,{1\textrm{x}2}}_{BC}$
between Bob and Carol, then a 2-of-2 group key $K^{grp,{2\textrm{x}2}}$
between Alice and $\mathbb{K}^{agg,{1\textrm{x}2}}_{BC}$. Basically, a
(2-of-(\[1-of-1\] and \[1-of-2\])) multisig address.

This implies access structures to signing rights can be fairly
open-ended.

### Family trees

We can diagram the (2-of-(\[1-of-1\] and \[1-of-2\])) multisig address
like this:

::: {.center}
forked edges, for tree = edge = \<-, \> = triangle 60 ,fork sep = 4.5
mm, ,l sep = 8 mm ,circle, draw , where n children=0tier=terminus,
\[$K^{grp,{2\textrm{x}2}}$ \[$K^{base}_A$\]
\[$\mathbb{K}^{agg,{1\textrm{x}2}}_{BC}$ \[$K^{base}_B$\]
\[$K^{base}_C$\] \] \]
:::

The keys $K^{base}_A,K^{base}_B,K^{base}_C$ are considered *root
ancestors*, while $\mathbb{K}^{agg,{1\textrm{x}2}}_{BC}$ is the *child*
of *parents* $K^{base}_B$ and $K^{base}_C$. Parents can have more than
one child, though for conceptual clarity we consider each copy of a
parent as distinct. This means there can be multiple root ancestors that
are the same key.

For example, in this 2-of-3 and 1-of-2 joined in a 2-of-2, Carol's key
$K^{base}_C$ is used twice and displayed twice:

::: {.center}
forked edges, for tree = edge = \<-, \> = triangle 60 ,fork sep = 4.5
mm, ,l sep = 8 mm ,circle, draw , where n children=0tier=terminus,
\[$K^{grp,{2\textrm{x}2}}$ \[$\mathbb{K}^{agg,{2\textrm{x}3}}_{ABC}$
\[$K^{base}_A$\] \[$K^{base}_B$\] \[$K^{base}_C$\] \]
\[$\mathbb{K}^{agg,{1\textrm{x}2}}_{CD}$ \[$K^{base}_C$\]
\[$K^{base}_D$\] \] \]
:::

Separate sets $\mathbb{S}$ are defined for each multisig sub-coalition.
There are three premerge sets in the previous example:
$\mathbb{S}^{\textrm{2x3}}_{ABC} = \{K^{sh,\textrm{2x3}}_{AB},K^{sh,\textrm{2x3}}_{BC},K^{sh,\textrm{2x3}}_{AC}\}$,
$\mathbb{S}^{\textrm{1x2}}_{CD} = \{K^{sh,\textrm{1x2}}_{CD}\}$, and
$\mathbb{S}^{\textrm{2x3}}_{final} = \{\mathbb{K}^{agg,{2\textrm{x}3}}_{ABC},\mathbb{K}^{agg,{1\textrm{x}2}}_{CD}\}$.

### Nesting multisig keys {#subsec:nesting-multisig-keys}

Suppose we have the following key family

::: {.center}
forked edges, for tree = edge = \<-, \> = triangle 60 ,fork sep = 4.5
mm, ,l sep = 8 mm ,circle, draw , where n children=0tier=terminus,
\[$K^{grp,{2\textrm{x}3}}$ \[$K^{grp,{2\textrm{x}3}}_{ABC}$
\[$K^{base}_A$\] \[$K^{base}_B$\] \[$K^{base}_C$\] \] \[$K^{base}_D$\]
\[$K^{base}_E$\] \]
:::

If we merge the keys in $\mathbb{S}^{\textrm{2x3}}_{ABC}$ corresponding
to the first 2-of-3, we run into an issue at the next level. Let's take
just one shared secret, between $K^{grp,\textrm{2x3}}_{ABC}$ and
$K^{base}_D$, to illustrate:
$$k_{ABC,D} = \mathcal{H}_n(k^{grp,\textrm{2x3}}_{ABC} K^{base}_D)$$

Now, two people from ABC could easily contribute aggregation key
components so the sub-coalition can compute
$$k^{grp,\textrm{2x3}}_{ABC} K^{base}_D = \sum k^{agg,\textrm{2x3}}_{ABC} K^{base}_D$$

The problem is everyone from ABC can compute
$k^{sh,\textrm{2x3}}_{ABC,D} = \mathcal{H}_n(k^{grp,\textrm{2x3}}_{ABC} K^{base}_D)$!
If everyone from a lower-tier multisig knows all its private keys for a
higher-tier multisig, then the lower-tier multisig might as well be
1-of-N.

We get around this by not completely merging keys until the final child
key. Instead, we just do `premerge` for all keys output by low-tier
multisigs.

#### Solution for nesting {#solution-for-nesting .unnumbered}

To use $\mathbb{K}^{agg,\textrm{MxN}}$ in a new multisig, we pass it
around just like a normal key, with one change. Operations involving
$\mathbb{K}^{agg,\textrm{MxN}}$ use each of its member keys, instead of
the merged group key. For example, the public 'key' of a shared secret
between $\mathbb{K}^{agg,\textrm{2x3}}_x$ and $K^{base}_A$ would look
like
$$\mathbb{K}^{sh,\textrm{1x2}}_{x,A} = \{ [\mathcal{H}_n(k^{base}_A \mathbb{K}^{agg,\textrm{2x3}}_x[1])*G], [\mathcal{H}_n(k^{base}_A \mathbb{K}^{agg,\textrm{2x3}}_x[2])*G], ...\}$$

This way all members of $\mathbb{K}^{agg,\textrm{2x3}}_x$ only know
shared secrets corresponding to their private keys from the lower-tier
2-of-3 multisig. An operation between a keyset of size two
${}^{2}\mathbb{K}_A$ and keyset of size three ${}^{3}\mathbb{K}_B$ would
produce a keyset of size six ${}^{6}\mathbb{K}_{AB}$. We can generalize
all keys in a key family as keysets, where single keys are denoted
${}^{1}\mathbb{K}$. Elements of a keyset are ordered according to some
convention (i.e. smallest to largest numerically), and sets containing
keysets (e.g. $\mathbb{S}$ sets) are ordered by the first element in
each keyset, according to some convention.\
We let the key sets propagate through the family structure, with each
nested multisig group sending their `premerge` aggregation set as the
'base key' for the next level,[^33] until the last child's aggregation
set appears, at which point `merge` is finally used.\
Users should store their base private keys, the aggregation private keys
for all levels of a multisig family structure, and the public keys for
all levels. Doing so facilitates creating new structures, `merging`
nested multisigs, and collaborating with other signers to rebuild a
structure if there is a problem.

### Implications for Monero

Each sub-coalition contributing to the final key needs to contribute
components to Monero transactions (such as the opening values
$\alpha G$), and so every sub-sub-coalition needs to contribute to its
child sub-coalition.

This means every root ancestor, even when there are multiple copies of
the same key in the family structure, must contribute one root component
to their child, and each child one component to its child and so on. We
use simple sums at each level.

For example, let's take this family

::: {.center}
forked edges, for tree = edge = \<-, \> = triangle 60 ,fork sep = 4.5
mm, ,l sep = 8 mm ,circle, draw , where n children=0tier=terminus,
\[${}^{1}\mathbb{K}^{grp,{2\textrm{x}2}}$
\[${}^{1}\mathbb{K}^{base}_A$\]
\[${}^{2}\mathbb{K}^{agg,{2\textrm{x}2}}_{AB}$
\[${}^{1}\mathbb{K}^{base}_A$\] \[${}^{1}\mathbb{K}^{base}_B$\] \] \]
:::

Say they need to compute some group value $x$ for a signature. Root
ancestors contribute: $x_{A,1}$, $x_{A,2}$, $x_B$. The total is
$x = x_{A,1} + x_{A,2} + x_B$.

There are currently no implementations of nested multisig in Monero.

[^1]: Multisignatures have a diversity of applications, from corporate
    accounts to newspaper subscriptions to online marketplaces.

[^2]: As of this writing we are aware of three multisig implementations.
    First is a very basic manual process using the CLI (command line
    interface) [@cli-22multisig-instructions]. Second is the truly
    excellent MMS (Multisig Messaging System) which enables secure,
    highly automated multisig via the CLI
    [@mms-manual; @mms-project-proposal]. Third is the commercially
    available 'Exa Wallet', which has initial release code available on
    their Github repository at <https://github.com/exantech> (it does
    not appear up to date with current release version). All three of
    these rely on the same fundamental core team's codebase, which
    essentially means only one implementation exists.

[^3]: If at least one honest participant uses components selected
    randomly from a uniform distribution, then keys aggregated by a
    simple sum are indistinguishable [@SCOZZAFAVA1993313] from normal
    keys.

[^4]: The random masks could easily be derived from some password. For
    example, $\mu^s = \mathcal{H}_n(password)$ and
    $\mu^v = \mathcal{H}_n(\mu^s)$. Or, as is done in Monero, mask the
    spend and view keys with a string e.g. $\mu^s,\mu^v =$ "Multisig\".
    This implies Monero only supports one multisig base spend key per
    normal address, although in reality making a wallet multisig causes
    users to lose access to the original wallet
    [@cli-22multisig-instructions]. Users must make a new wallet with
    their normal address to access its funds, assuming the multisig
    wasn't made from a brand new normal address.

[^5]: As we will see in Section
    [1.6](#sec:smaller-thresholds){reference-type="ref"
    reference="sec:smaller-thresholds"}, key aggregation does not work
    on M-of-N multisig when M $<$ N due to the presence of shared
    secrets.

[^6]: Monero's current (and first) iteration of multisig, made available
    in April 2018 [@lithiumluna-v7] (with M-of-N integration following
    in October 2018 [@berylliumbullet-v8]), used this naive key
    aggregation, and required users sign their spend key components.

[^7]: $\mathbb{S}^{base}$ needs to be ordered consistently so
    participants can be sure they are all hashing the same thing.

[^8]: Recalling Section [\[sec:CLSAG\]](#sec:CLSAG){reference-type="ref"
    reference="sec:CLSAG"}, hash functions should be domain separated by
    prefixing them with tags, e.g. $T_{agg} =$ "Multisig_Aggregation\".
    We leave tags out for examples like the next section's Schnorr
    signatures.

[^9]: It is important to include $\mathbb{S}^{base}$ in the aggregation
    hashes to avoid sophisticated key cancellation attacks involving
    Wagner's generalized solution to the birthday problem
    [@generalized-birthday-wagner]. [@adam-wagnerian-tragedies]
    [@maxwell2018simple-musig]

[^10]: As we will see later, key aggregation only meets the plain
    public-key model for N-of-N and 1-of-N multisig.

[^11]: Notation: $\mathbb{K}^{agg}[e]$ is the eelement of the set.

[^12]: Robust key aggregation has not yet been implemented in Monero,
    but since participants can store and use private key $k^{agg}_e$
    (for naive key aggregation, $k^{agg}_e = k^{base}_e$), updating
    Monero to use robust key aggregation will only change the premerge
    process.

[^13]: As in Section
    [\[sec:schnorr-fiat-shamir\]](#sec:schnorr-fiat-shamir){reference-type="ref"
    reference="sec:schnorr-fiat-shamir"}, it is important not to reuse
    $\alpha_e$ for different challenges $c$. This means to reset a
    multisignature process where responses have been sent out, it should
    start again from the beginning with new $\alpha_e$ values.

[^14]: Commit-and-reveal is not used in the current implementation of
    Monero multisig, although it is being looked at for future releases.
    [@multisig-research-issue-67]

[^15]: Multisig subaddresses are supported in Monero.

[^16]: There is no need to commit-and-reveal these since the commitments
    to zero are known by all signers.

[^17]: If $K^{o,grp}_{\pi,j}$ is built from an $i$-indexed multisig
    subaddress, then (from Section
    [\[sec:subaddresses\]](#sec:subaddresses){reference-type="ref"
    reference="sec:subaddresses"}) its private key is a composite:
    $$k^{o,grp}_{\pi,j} = \mathcal{H}_n(k^{v,grp} r_{u_j} K^{s,grp,i}, u_j) + \sum_e k^{s,agg}_e + \mathcal{H}_n(k^{v,grp},i)$$

[^18]: If the one-time address corresponds to an $i$-indexed multisig
    subaddress, add
    $$\tilde{K}^{o,grp}_j = ... + \mathcal{H}_n(k^{v,grp},i) \mathcal{H}_p(K^{o,grp}_{\pi,j})$$

[^19]: If the one-time address $K^{o,grp}_{\pi,j}$ corresponds to an
    $i$-indexed multisig subaddress, include
    $$r_{\pi,j} = ... - c_{\pi}*\mathcal{H}_n(k^{v,grp},i)$$

[^20]: Or transaction private keys $r_{t}$ if sending to at least one
    subaddress.

[^21]: Note that we simplify the signing process by letting the
    initiator generate random scalars $r_{i,j}$ and $r^z_{i,j}$, instead
    of each co-signer generating components that eventually get summed
    together.

[^22]: He doesn't need to send the output amounts $b_t$ directly, as
    they can be computed from $\mathit{amount}_t$. Monero takes the
    reasonable approach of creating a partial transaction filled with
    the information selected by the initiator, and sending that to other
    cosigners along with a list of related information like transaction
    private keys, destination addresses, the real inputs, etc.

[^23]: It is imperative that each signing attempt by a signer use a
    unique $\alpha_{j,e}$, to avoid leaking his private spend key to
    other signers (recall Section
    [\[sec:schnorr-fiat-shamir\]](#sec:schnorr-fiat-shamir){reference-type="ref"
    reference="sec:schnorr-fiat-shamir"}) [@MRL-0009-multisig]. Wallets
    should fundamentally enforce this by always deleting $\alpha_{j,e}$
    whenever a response that uses it has been transmitted outside of the
    wallet.

[^24]: Currently Monero appears to use a simple sum.

[^25]: If the one-time address corresponds to an $i$-indexed multisig
    subaddress, add
    $$\tilde{K}^{o,grp} = ... + \mathcal{H}_n(k^{v,grp},i) \mathcal{H}_p(K^{o,grp})$$

[^26]: This proof should include domain separation and key prefixing,
    which we omit for brevity.

[^27]: If the one-time address $K^{o,grp}$ corresponds to an $i$-indexed
    multisig subaddress, include
    $$r^{resp} = ... - c*\mathcal{H}_n(k^{v,grp},i)$$

[^28]: Note that key cancellation is largely meaningless here because
    everyone knows the full private key.

[^29]: Since the merged key is composed of shared secrets, an observer
    who just knows the original base public keys would not be able to
    aggregate them (Section
    [1.2.2](#subsec:drawbacks-naive-aggregation-cancellation){reference-type="ref"
    reference="subsec:drawbacks-naive-aggregation-cancellation"}) and
    identify members of the merged key.

[^30]: In practice this means an initiator should determine which subset
    of M signers will sign a given message. If he discovers O signers
    are willing to sign, with (O $\geq$ M), he can orchestrate multiple
    concurrent signing attempts for each M-size subset within O to
    increase the chances of one succeeding. It appears Monero uses this
    approach. It also turns out (an esoteric point) that the *original*
    list of output destinations created by the initiator is randomly
    shuffled, and that random list is then used by all concurrent
    signing attempts, and all other co-signers (this is related to the
    obscure flag `shuffle_outs`).

[^31]: Currently Monero appears to use a round-robin signing method,
    where the initiator signs with all his private keys, passes the
    partially signed transaction to another signer who signs with all
    *his* private keys (that have not been used to sign with yet), who
    passes to yet another signer, and so on, until the final signer who
    can either publish the transaction or send it to other signers so
    they can publish it.

[^32]: Participants should keep track of who has which keys at the last
    stage ($s = N-M$), to facilitate collaborative signing, where only
    the first person in $\mathbb{S}_0$ with a certain private key uses
    it to sign. See Section [1.6.2](#sec:n-1-of-n){reference-type="ref"
    reference="sec:n-1-of-n"}.

[^33]: Note that `premerge` needs to be done to the outputs of *all*
    nested multisigs, even when an N'-of-N' multisig is nested into an
    N-of-N, because the set $\mathbb{S}$ will change.
