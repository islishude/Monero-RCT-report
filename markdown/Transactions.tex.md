# Monero Ring Confidential Transactions (RingCT) {#chapter:transactions}

Throughout Chapters
[\[chapter:addresses\]](#chapter:addresses){reference-type="ref"
reference="chapter:addresses"} and
[\[chapter:pedersen-commitments\]](#chapter:pedersen-commitments){reference-type="ref"
reference="chapter:pedersen-commitments"} we built up several aspects of
Monero transactions. At this point a simple one-input, one-output
transaction from some unknown author to some unknown recipient sounds
like:

"My transaction uses transaction public key $r G$. I will spend old
output $X$ (note that it has a hidden amount $A_X$, committed to in
$C_X$). I will give it a pseudo output commitment $C'_X$. I will make
one output $Y$, which may be spent by the one-time address $K^o_Y$. It
has a hidden amount $A_Y$ committed to in $C_Y$, encrypted for the
recipient, and proven in range with a Bulletproofs-style range proof.
Please note that $C'_X - C_Y = 0$.\"

Some questions remain. Did the author actually own $X$? Does the pseudo
output commitment $C'_X$ actually correspond to $C_X$, such that
$A_X = A'_X = A_Y$? Has someone tampered with the transaction, and
perhaps directed the output at a recipient unintended by the original
author?\
As mentioned in Section
[\[sec:one-time-addresses\]](#sec:one-time-addresses){reference-type="ref"
reference="sec:one-time-addresses"}, we can prove ownership of an output
by signing a message with its one-time address (whoever has the
address's key owns the output). We can also prove it has the same amount
as a pseudo output commitment by proving knowledge of the commitment to
zero's private key ($C_X - C'_X = z_X G$). Moreover, if that message is
*all the transaction data* (except the signature itself), then verifiers
can be assured everything is as the author intended (the signature only
works with the original message). MLSAG signatures allow us to do all of
this while also obscuring the actual spent output amongst other outputs
from the blockchain, so observers can't be sure which one is being
spent.

## Transaction types {#sec:transaction_types}

Monero is a cryptocurrency under steady development. Transaction
structures, protocols, and cryptographic schemes are always prone to
evolving as new innovations, objectives, or threats are found.

In this report we have focused our attention on *Ring Confidential
Transactions*, a.k.a. *RingCT*, as they are implemented in the current
version of Monero. RingCT is mandatory for all new Monero transactions,
so we will not describe any deprecated transaction schemes, even if they
are still partially supported.[^1] The transaction type we have
discussed so far, and which will be further elaborated in this chapter,
is `RCTTypeBulletproof2`.[^2]

We present a conceptual summary of transactions in Section
[1.3](#sec:transaction_summary){reference-type="ref"
reference="sec:transaction_summary"}.

## Ring Confidential Transactions of type `RCTTypeBulletproof2` {#sec:RCTTypeBulletproof2}

Currently (protocol v12) all new transactions must use this transaction
type, in which each input is signed separately. An actual example of an
`RCTTypeBulletproof2` transaction, with all its components, can be
inspected in Appendix
[\[appendix:RCTTypeBulletproof2\]](#appendix:RCTTypeBulletproof2){reference-type="ref"
reference="appendix:RCTTypeBulletproof2"}.

### Amount commitments and transaction fees {#sec:commitments-and-fees}

Assume a transaction sender has previously received various outputs with
amounts $a_1, ..., a_m$ addressed to one-time addresses
$K^o_{\pi,1}, ..., K^o_{\pi,m}$ and with amount commitments
$C^a_{\pi,1}, ..., C^a_{\pi,m}$.

This sender knows the private keys $k^o_{\pi,1}, ..., k^o_{\pi,m}$
corresponding to the one-time addresses (Section
[\[sec:one-time-addresses\]](#sec:one-time-addresses){reference-type="ref"
reference="sec:one-time-addresses"}). The sender also knows the blinding
factors $x_j$ used in commitments $C^a_{\pi,j}$ (Section
[\[sec:pedersen_monero\]](#sec:pedersen_monero){reference-type="ref"
reference="sec:pedersen_monero"}).

Typically transaction outputs are *lower* in total than transaction
inputs, in order to provide a fee that will incentivize miners to
include the transaction in the blockchain.[^3] Transaction fee amounts
$f$ are stored in clear text in the transaction data transmitted to the
network. Miners can create an additional output for themselves with the
fee (see Section
[\[subsec:miner-transaction\]](#subsec:miner-transaction){reference-type="ref"
reference="subsec:miner-transaction"}).

A transaction consists of inputs $a_1, ..., a_m$ and outputs
$b_0, ..., b_{p-1}$ such that
$\sum\limits_{j=1}^m a_j - \sum\limits_{t=0}^{p-1} b_t - f = 0$.[^4]

The sender calculates pseudo output commitments for the input amounts,
$C'^a_{\pi,1}, ..., C'^a_{\pi,m}$, and creates commitments for intended
output amounts $b_0, ..., b_{p-1}$. Let these new commitments be
$C^b_0, ..., C^b_{p-1}$.

He knows the private keys $z_1,...,z_m$ to the commitments to zero
$(C^a_{\pi,1} - C'^a_{\pi,1}),...,(C^a_{\pi,m} - C'^a_{\pi,m})$.

For verifiers to confirm transaction amounts sum to zero, the fee amount
must be converted into a commitment. The solution is to calculate the
commitment of the fee $f$ without the masking effect of any blinding
factor. That is, $C(f) = f H$.

Now we can prove input amounts equal output amounts:\
$$(\sum_j C'^a_{j} - \sum_t C^b_{t}) - f H = 0$$

### Signature {#full-signature}

The sender selects $m$ sets of size $v$, of additional unrelated
one-time addresses and their commitments from the blockchain,
corresponding to apparently unspent outputs.[^5][^6] To sign input $j$,
she stirs a set of size $v$ into a *ring* with her own $j$unspent
one-time address (placed at unique index $\pi$), along with false
commitments to zero, as follows:[^7]

$$\begin{aligned}
    \mathcal{R}_j = \{&\{K^o_{1, j}, (C_{1, j} - C'^a_{\pi, j})\}, \\
    &... \\
    &\{ K^o_{\pi, j}, (C^a_{\pi, j} - C'^a_{\pi, j})\}, \\
    &... \\
    &\{ K^o_{v+1, j}, (C_{v+1, j} - C'^a_{\pi, j})\}\}\end{aligned}$$

Alice uses an MLSAG signature (Section
[\[sec:MLSAG\]](#sec:MLSAG){reference-type="ref" reference="sec:MLSAG"})
to sign this ring, where she knows the private keys $k^o_{\pi,j}$ for
$K^o_{\pi,j}$, and $z_j$ for the commitment to zero $(C^a_{\pi,j}$ -
$C'^a_{\pi,j})$. Since no key image is needed for the commitments to
zero, there is consequently no corresponding key image component in the
signature's construction.[^8]

Each input in a transaction is signed individually using rings like
$\mathcal{R}_j$ as defined above, thereby obscuring the real outputs
being spent, ($K^o_{\pi,1},...,K^o_{\pi,m}$), amongst other unspent
outputs.[^9] Since part of each ring includes a commitment to zero, the
pseudo output commitment used must contain an amount equal to the real
input being spent. This ties input amounts to the proof that amounts
balance, without compromising which ring member is the real input.

The message $\mathfrak{m}$ signed by each input is essentially a hash of
all transaction data *except* for the MLSAG signatures.[^10] This
ensures transactions are tamper-proof from the perspective of both
transaction authors and verifiers. Only one message is produced, and
each input MLSAG signs it.

One-time private key $k^o$ is the essence of Monero's transaction model.
Signing $\mathfrak{m}$ with $k^o$ proves you are the owner of the amount
committed to in $C^a$. Verifiers can be confident that transaction
authors are spending their own funds, without even knowing which funds
are being spent, how much is being spent, or what other funds they might
own!

### Avoiding double-spending

An MLSAG signature (Section
[\[sec:MLSAG\]](#sec:MLSAG){reference-type="ref" reference="sec:MLSAG"})
contains images $\tilde{K}_{j}$ of private keys $k_{\pi, j}$. An
important property for any cryptographic signature scheme is that it
should be unforgeable with non-negligible probability. Therefore, to all
practical effects, we can assume a signature's key images must have been
deterministically produced from legitimate private keys.

The network only needs to verify that key images included with MLSAG
signatures (corresponding to inputs and calculated as
$\tilde{K}^o_{j} = k^o_{\pi,j} \mathcal{H}_p(K^o_{\pi,j})$) have not
appeared before in other transactions.[^11] If they have, then we can be
sure we are witnessing an attempt to re-spend an output
$(C^a_{\pi,j}, K_{\pi,j}^o)$.

### Space requirements {#subsec:space-and-ver-rcttypefull}

#### MLSAG signature (inputs) {#mlsag-signature-inputs .unnumbered}

From Section [\[sec:MLSAG\]](#sec:MLSAG){reference-type="ref"
reference="sec:MLSAG"} we recall that an MLSAG signature in this context
would be expressed as

$\sigma_j(\mathfrak{m}) = (c_1, r_{1, 1}, r_{1, 2}, ..., r_{v+1, 1}, r_{v+1, 2}) \textrm{ with } \tilde{K}^o_j$

As a legacy of CryptoNote, the values $\tilde{K}^o_j$ are not referred
to as part of the signature, but rather as *images* of the private keys
$k^o_{\pi,j}$. These *key images* are normally stored separately in the
transaction structure, as they are used to detect double-spending
attacks.

With this in mind and assuming point compression (Section
[\[point_compression_section\]](#point_compression_section){reference-type="ref"
reference="point_compression_section"}), since each ring $\mathcal{R}_j$
contains $(v+1) \cdot 2$ keys, an input signature $\sigma_j$ will
require $(2(v+1) + 1) \cdot 32$ bytes. On top of this, the key image
$\tilde{K}^o_{\pi,j}$ and the pseudo output commitment $C'^a_{\pi,j}$
leave a total of $(2(v+1)+3) \cdot 32$ bytes per input.

To this value we would need additional space to store the ring member
offsets in the blockchain (see Appendix
[\[appendix:RCTTypeBulletproof2\]](#appendix:RCTTypeBulletproof2){reference-type="ref"
reference="appendix:RCTTypeBulletproof2"}). These offsets are used by
verifiers to find each MLSAG signature's ring members' output keys and
commitments in the blockchain, and are stored as variable length
integers, hence we can not exactly quantify the space
needed.[^12][^13][^14]

Verifying\[-1cm\] all of an `RCTTypeBulletproof2` transaction's MLSAGs
includes the computation of $(C_{i, j} - C'^a_{\pi, j})$ and
$(\sum_j C'^a_{j} \stackrel{?}{=} \sum_t C^b_{t} + f H)$, and verifying
key images are in $G$'s subgroup with $l \tilde{K} \stackrel{?}{=} 0$.

#### Range proofs (outputs) {#range-proofs-outputs .unnumbered}

An aggregate Bulletproof range proof will require
$(2 \cdot \lceil \textrm{log}_2(64 \cdot p) \rceil + 9) \cdot 32$ total
bytes.

## Concept summary: Monero transactions {#sec:transaction_summary}

To summarize this chapter, and the previous two chapters, we present the
main content of a transaction, organized for conceptual clarity. A real
example can be found in Appendix
[\[appendix:RCTTypeBulletproof2\]](#appendix:RCTTypeBulletproof2){reference-type="ref"
reference="appendix:RCTTypeBulletproof2"}.

-   [Type]{.ul}: '0' is `RCTTypeNull` (for miners), '4' is
    `RCTTypeBulletproof2`

-   [Inputs]{.ul}: for each input $j \in \{1,...,m\}$ spent by the
    transaction author

    -   **Ring member offsets**: a list of 'offsets' indicating where a
        verifier can find input $j$'s ring members $i \in \{1,...,v+1\}$
        in the blockchain (includes the real input)

    -   **MLSAG Signature**: $\sigma_j$ terms $c_1$, and $r_{i,1}$ &
        $r_{i,2}$ for $i \in \{1,...,v+1\}$

    -   **Key image**: the key image $\tilde{K}^{o,a}_j$ for input $j$

    -   **Pseudo output commitment**: $C'^{a}_j$ for input $j$

-   [Outputs]{.ul}: for each output $t \in \{0,...,p-1\}$ to address or
    subaddress $(K^v_t,K^s_t)$

    -   **One-time address**: $K^{o,b}_t$ for output $t$

    -   **Output commitment**: $C^{b}_t$ for output $t$

    -   **Encoded amount**: so output owners can compute $b_t$ for
        output $t$

        -   *Amount*:
            $b_t \oplus_8 \mathcal{H}_n(``amount”, \mathcal{H}_n(r K_B^v, t))$

    -   **Range proof**: an aggregate Bulletproof for all output amounts
        $b_t$

        -   *Proof*:
            $\Pi_{BP} = (A, S, T_1, T_2, \tau_x, \mu, \mathbb{L}, \mathbb{R}, a, b, t)$

-   [Transaction fee]{.ul}: communicated in clear text multiplied by
    $10^{12}$ (i.e. atomic units, see Section
    [\[subsec:block-reward\]](#subsec:block-reward){reference-type="ref"
    reference="subsec:block-reward"}), so a fee of 1.0 would be recorded
    as 1000000000000

-   [Extra]{.ul}: includes the transaction public key $r G$, or, if at
    least one output is directed to a subaddress, $r_t K^{s,i}_t$ for
    each subaddress'd output $t$ and $r_t G$ for each normal address'd
    output $t$, and maybe an encoded payment ID (should be at most one
    per transaction)[^15]

Our final one-input/one-output example transaction sounds like this: "My
transaction uses transaction public key $r G$. I will spend one of the
outputs in set $\mathbb{X}$ (note that it has a hidden amount $A_X$,
committed to in $C_X$). The output being spent is owned by me (I made a
MSLAG signature on the one-time addresses in $\mathbb{X}$), and hasn't
been spent before (its key image $\tilde{K}$ has not yet appeared in the
blockchain). I will give it a pseudo output commitment $C'_X$. I will
make one output $Y$, which may be spent by the one-time address $K^o_Y$.
It has a hidden amount $A_Y$ committed to in $C_Y$, encrypted for the
recipient, and proven in range with a Bulletproofs-style range proof. My
transaction includes a transaction fee $f$. Please note that
$C'_X - (C_Y + C_f) = 0$, and that I have signed the commitment to zero
$C'_X - C_X = z G$ which means the input amount equals the output amount
($A_X = A'_X = A_Y + f$). My MLSAG signed all transaction data, so
observers can be sure it hasn't been tampered with.\"

### Storage requirements

For `RCTTypeBulletproof2` we need $(2(v+1)+2) \cdot m \cdot 32$ bytes of
storage, and the aggregate Bulletproof range proof needs
$(2 \cdot \lceil \textrm{log}_2(64 \cdot p) \rceil + 9) \cdot 32$ bytes
of storage.[^16]

Miscellaneous requirements:

-   Input key images: $m*32$ bytes

-   One-time output addresses: $p*32$ bytes

-   Output commitments: $p*32$ bytes

-   Encoded output amounts: $p*8$ bytes

-   Transaction public key: 32 bytes normally, $p*32$ bytes if sending
    to at least one subaddress.

-   Payment ID: 8 bytes for an integrated address. There should be no
    more than one per tx.

-   Transaction fee: stored as a variable length integer, so $\leq 9$
    bytes

-   Input offsets: stored as variable length integers, so $\leq 9$ bytes
    per offset, for $m*(v+1)$ ring members

-   Unlock time: stored as a variable length integer, so $\leq 9$
    bytes[^17]

-   'Extra' tags: each piece of data in the 'extra' field (e.g. a
    transaction public key) begins with a 1 byte 'tag', and some pieces
    also have a 1+ byte 'length'; see Appendix
    [\[appendix:RCTTypeBulletproof2\]](#appendix:RCTTypeBulletproof2){reference-type="ref"
    reference="appendix:RCTTypeBulletproof2"} for more details

[^1]: RingCT was first implemented in January 2017 (v4 of the protocol).
    It was made mandatory for all new transactions in September 2017 (v6
    of the protocol) [@ringct-dates]. RingCT is version 2 of Monero's
    transaction protocol.

[^2]: Within the RingCT era there are three deprecated transaction
    types: `RCTTypeFull`, `RCTTypeSimple`, and `RCTTypeBulletproof`. The
    former two coexisted in the first iteration of RingCT and are
    explored in the first edition of this report [@ztm-1], then with the
    advent of Bulletproofs (protocol v8) `RCTTypeFull` was deprecated,
    and `RCTTypeSimple` was upgraded to `RCTTypeBulletproof`.
    `RCTTypeBulletproof2` arrived due to a minor improvement in
    encrypting output commitments' masks and amounts (v10).

[^3]: In Monero there is a minimum base fee that scales with transaction
    weight. It is semi-mandatory because while you can create new blocks
    containing tiny-fee transactions, most Monero nodes won't relay such
    transactions to other nodes. The result is few if any miners will
    try to include them in blocks. Transaction authors can provide miner
    fees above the minimum if they want. We go into more detail on this
    in Section
    [\[subsec:dynamic-minimum-fee\]](#subsec:dynamic-minimum-fee){reference-type="ref"
    reference="subsec:dynamic-minimum-fee"}.

[^4]: Outputs\[-1.9cm\] are randomly shuffled by the core implementation
    before getting assigned an index, so observers can't build
    heuristics around their order. Inputs are sorted by key image within
    transaction data.

[^5]: [\[input-selection\]]{#input-selection label="input-selection"}In
    Monero it is standard for the sets of 'additional unrelated
    addresses' to be selected from a gamma\[1.2cm\] distribution across
    the range of historical outputs (RingCT outputs only, a triangle
    distribution is used for pre-RingCT outputs). This method uses a
    binning procedure to smooth out differences in block densities.
    First calculate the average time between transaction outputs over up
    to a year ago of RingCT outputs (avg time =
    \[\#outputs/\#blocks\]\*blocktime). Select an output via the gamma
    distribution, then look inside its block and grab a random output to
    be a member of the set. [@AnalysisOfLinkability]

[^6]: As of protocol v12, all transaction inputs must be at least 10
    blocks old (`CRYPTONOTE_DEFAULT_TX _SPENDABLE_AGE`). Prior to v12
    the core implementation used 10 blocks by default, but it was not
    required so an alternate wallet could make different choices, and
    some apparently did [@visualizing-monero-vid].

[^7]: In Monero each of a transaction's rings must have the same size,
    and the protocol controls how many ring members there can be per
    output-to-be-spent. It has changed with different protocol versions:
    v2 March 2016 $\geq$ 3, v6 Sept. 2017 $\geq$ 5, v7 April 2018 $\geq$
    7, v8 Oct. 2018 11-only. Since v6 each individual ring can not
    contain duplicate members, though there may be duplicates between
    rings to allow multiple inputs when there are insufficient total
    outputs in the transaction history (i.e. to assemble rings without
    cross-over) [@duplicate-ring-members].

[^8]: Building and verifying the signature excludes the term
    $r_{i,2} \mathcal{H}_p(C_{i, j} - C'^a_{\pi, j}) + c_i \tilde{K}_{z_j}$.

[^9]: The advantage of signing inputs individually is that the set of
    real inputs and commitments to zero need not be placed at the same
    index $\pi$, as they would be in the aggregated case. This means
    even if one input's origin becomes identifiable, the other inputs'
    origins would not. The old transaction type `RCTTypeFull` used
    aggregated ring signatures, combining all rings into one, and as we
    understand it was deprecated for that reason.

[^10]: The actual message is
    $\mathfrak{m} = \mathcal{H}(\mathcal{H}(tx\textunderscore prefix),\mathcal{H}(ss),\mathcal{H}(\text{range proofs}))$
    where:

    $tx\textunderscore prefix =${transaction era version (i.e. RingCT =
    2), inputs {ring member key offsets, key images}, outputs {one-time
    addresses}, extra {transaction public key, payment ID or encoded
    payment ID, misc.}}

    $ss =${transaction type (`RCTTypeBulletproof2` = '4'), transaction
    fee, pseudo output commitments for inputs, ecdhInfo (encrypted
    amounts), output commitments}.

    See Appendix
    [\[appendix:RCTTypeBulletproof2\]](#appendix:RCTTypeBulletproof2){reference-type="ref"
    reference="appendix:RCTTypeBulletproof2"} regarding this
    terminology.

[^11]: Verifiers must also check the key image is a member of the
    generator's subgroup (recall Section
    [\[blsag_note\]](#blsag_note){reference-type="ref"
    reference="blsag_note"}).

[^12]: See [@varint-description] or [@varint-spec] for an explanation of
    Monero's varint data type. It is an integer type that uses up to 9
    bytes, and stores up to 63 bits of information.

[^13]: Imagine the blockchain contains a long list of transaction
    outputs. We report the indices of outputs we want to use in rings.
    Now, bigger indexes require more storage space. We just need the
    'absolute' position of *one* index from each ring, and the
    'relative' positions of the other ring members' indices. For
    example, with real indices {7,11,15,20} we just need to report
    {7,4,4,5}. Verifiers can compute the last index with (7+4+4+5 = 20).
    Ring members are organized in ascending order of blockchain index
    within rings.

[^14]: A transaction with 10 inputs using rings with 11 total members
    will need $((11 \cdot 2 + 3) \cdot 32) \cdot 10 = 8000$ bytes for
    its inputs, with around 110 to 330 bytes for the offsets (there are
    110 ring members).

[^15]: No information stored in the 'extra' field is verified, though it
    *is* signed by input MLSAGs, so no tampering is possible (except
    with negligible probability). The field has no limit on how much
    data it can store, so long as the maximum transaction weight is
    respected. See [@extra-field-stackexchange] for more details.

[^16]: The amount of transaction content is limited by a maximum
    so-called 'transaction weight'. Before Bulletproofs were added in
    protocol v8 (and indeed currently when transactions have only two
    outputs) the transaction weight and size in bytes were equivalent.
    The maximum weight is (0.5\*300kB -
    `CRYPTONOTE_COINBASE_BLOB_RESERVED_SIZE`), where the blob reserve
    (600 bytes) is intended to leave room for the miner transaction
    within blocks. Before v8 the 0.5x multiplier was not included, and
    the 300kB term was smaller in earlier protocol versions (20kB v1,
    60kB v2, 300kB v5). We elaborate on these topics in Section
    [\[subsec:dynamic-block-weight\]](#subsec:dynamic-block-weight){reference-type="ref"
    reference="subsec:dynamic-block-weight"}.

[^17]: Any transaction's author can lock its outputs, rendering them
    unspendable until a specified block height where it may be spent (or
    until a UNIX timestamp, at which time its outputs may be included in
    a block's transaction's ring members). He only has the option to
    lock all outputs to the same block height. It is not clear if this
    offers any meaningful utility to transaction authors (perhaps smart
    contracts). Miner transactions have a mandatory 60-block lock time.
    As of protocol v12 normal outputs can't be spent until after the
    default spendable age (10 blocks) which is functionally equivalent
    to a mandatory minimum 10-block lock time. If a transaction is
    published in the 10block with an unlock time of 25, it may be spent
    in the 25block or later. Unlock time is probably the least used of
    all transaction features for normal transactions.
