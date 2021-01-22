# Monero Addresses {#chapter:addresses}

The ownership of digital currency stored in a blockchain is controlled
by so-called 'addresses'. Addresses are sent money which only the
address-holder can spend.[^1]

More specifically, an address owns the 'outputs' from some transactions,
which are like notes giving the address-holder spending rights to an
'amount' of money. Such a note might say "Address C now owns 5.3 XMR\".

To spend an owned output, the address-holder references it as the input
to a new transaction. This new transaction has outputs owned by other
addresses (or by the sender's address, if the sender wants). A
transaction's total input amount equals its total output amount, and
once spent an owned output can't be respent. Carol, who has Address C,
could reference that old output in a new transaction (e.g. "In this
transaction I'd like to spend that old output.\") and add a note saying
"Address B now owns 5.3 XMR\".

An address's balance is the sum of amounts contained in its unspent
outputs.[^2]

We discuss hiding the amount from observers in Chapter
[\[chapter:pedersen-commitments\]](#chapter:pedersen-commitments){reference-type="ref"
reference="chapter:pedersen-commitments"}, the structure of transactions
in Chapter
[\[chapter:transactions\]](#chapter:transactions){reference-type="ref"
reference="chapter:transactions"} (which includes how to prove you are
spending an owned and previously unspent output, without even revealing
which output is being spent), and the money creation process and role of
observers in Chapter
[\[chapter:blockchain\]](#chapter:blockchain){reference-type="ref"
reference="chapter:blockchain"}.

## User keys {#sec:user-keys}

Unlike Bitcoin, Monero users have two sets of private/public keys,
$(k^v, K^v)$ and $(k^s, K^s)$, generated as described in Section
[\[ec:keys\]](#ec:keys){reference-type="ref" reference="ec:keys"}.

The *address* of a user is the pair of public keys $(K^v, K^s)$. Her
private keys will be the corresponding pair $(k^v, k^s)$.[^3]\
Using two sets of keys allows function segregation. The rationale will
become clear later in this chapter, but for the moment let us call
private key $k^v$ the *view key*, and $k^s$ the *spend key*. A person
can use their view key to determine if their address owns an output, and
their spend key will allow them to spend that output in a transaction
(and retroactively figure out it has been spent).[^4]

## One-time addresses {#sec:one-time-addresses}

To receive money, a Monero user may distribute their address to other
users, who can then send it money via transaction outputs.

The address is never used directly.[^5] Instead, a Diffie-Hellman-like
exchange is applied to it, creating a unique *one-time address* for each
transaction output to be paid to the user. In this way, even external
observers who know all users' addresses cannot use them to identify
which user owns any given transaction output.[^6]

Let's start with a very simple mock transaction, containing exactly one
output --- a payment of '0' amount from Alice to Bob.

Bob has private/public keys $(k_B^v, k_B^s)$ and $(K_B^v, K_B^s)$, and
Alice knows his public keys (his address). The mock transaction could
proceed as follows [@cryptoNoteWhitePaper]:

1.  Alice generates a random number $r \in_R \mathbb{Z}_l$, and
    calculates the one-time address[^7]
    $$K^o  = \mathcal{H}_n(r K_B^v)G + K_B^s\marginnote{src/crypto/ crypto.cpp {\tt derive\_pu- blic\_key()}}$$

2.  Alice sets $K^o$ as the addressee of the payment, adds the output
    amount '0' and the value $r G$ to the transaction data, and submits
    it to the network.

3.  Bob receives the data and sees the values $r G$ and $K^o$. He can
    calculate $k_B^v r G = r K_B^v$. He can then calculate
    $K'^s_B = K^o - \mathcal{H}_n(r K_B^v)G$. When he sees that
    $K'^s_B = K_B^s$, he knows the output is addressed to him.[^8]

    The private key $k_B^v$ is called the 'view key' because anyone who
    has it (and Bob's public spend key $K_B^s$) can calculate $K'^s_B$
    for every transaction output in the blockchain (record of
    transactions), and 'view' which ones belong to Bob.

4.  The one-time keys for the output are: $$\begin{aligned}
            K^o &= \mathcal{H}_n(r K_B^v)G + K_B^s = (\mathcal{H}_n(r K_B^v) + k_B^s)G  \\ 
            k^o &= \mathcal{H}_n(r K_B^v) + k_B^s
        \end{aligned}$$

To spend his '0' amount output \[sic\] in a new transaction, all Bob
needs to do is prove ownership by signing a message with the one-time
key $K^o$. The private key $k_B^s$ is the 'spend key' since it is
required for proving output ownership, while $k_B^v$ is the 'view key'
since it can be used to find outputs spendable by Bob.

As will become clear in Chapter
[\[chapter:transactions\]](#chapter:transactions){reference-type="ref"
reference="chapter:transactions"}, without $k^o$ Alice can't compute the
output's key image, so she can never know for sure if Bob spends the
output she sent him.[^9]

Bob may give a third party his view key. Such a third party could be a
trusted custodian, an auditor, a tax authority, etc. Somebody who could
be allowed read access to the user's transaction history, without any
further rights. This third party would also be able to decrypt the
output's amount (to be explained in Section
[\[sec:pedersen_monero\]](#sec:pedersen_monero){reference-type="ref"
reference="sec:pedersen_monero"}). See Chapter
[\[chapter:tx-knowledge-proofs\]](#chapter:tx-knowledge-proofs){reference-type="ref"
reference="chapter:tx-knowledge-proofs"} for other ways Bob could
provide information about his transaction history.

### Multi-output transactions {#sec:multi_out_transactions}

Most transactions will contain more than one output. If nothing else, to
transfer 'change' back to the sender.[^10][^11]

Monero senders usually generate only one random value $r$. The curve
point $r G$ is typically known as the *transaction public key* and is
published alongside other transaction data in the blockchain.\
To\[-.8cm\] ensure that all one-time addresses in a transaction with $p$
outputs are different even in cases where the same addressee is used
twice, Monero uses an output index. Every output from a transaction has
an index $t \in \{0, ..., p-1\}$. By appending this value to the shared
secret before hashing it, one can ensure the resulting one-time
addresses are unique:\[1.2cm\] $$\begin{aligned}
  K_t^o &= \mathcal{H}_n(r K_t^v, t)G + K_t^s = (\mathcal{H}_n(r K_t^v, t) + k_t^s)G  \\ 
  k_t^o &= \mathcal{H}_n(r K_t^v, t) + k_t^s\end{aligned}$$

## Subaddresses {#sec:subaddresses}

Monero users can generate subaddresses from each address
[@MRL-0006-subaddresses]. Funds sent to a subaddress can be viewed and
spent using its main address's view and spend keys. By analogy: an
online bank account may have multiple balances corresponding to credit
cards and deposits, yet they are all accessible and spendable from the
same point of view -- the account holder.\
Subaddresses are convenient for receiving funds to the same place when a
user doesn't want to link his activities together by publishing/using
the same address. As we will see, most observers would have to solve the
DLP to determine a given subaddress is derived from any particular
address [@MRL-0006-subaddresses].[^12]

They are also useful for differentiating between received outputs. For
example, if Alice wants to buy an apple from Bob on a Tuesday, Bob could
write a receipt describing the purchase and make a subaddress for that
receipt, then ask Alice to use that subaddress when she sends him the
money. This way Bob can associate the money he receives with the apple
he sold. We explore another way to distinguish between received outputs
in the next section.

Bob generates his $i^\nth$ subaddress $(i = 1, 2, ...)$ from his address
as a pair of public keys $(K^{v,i}, K^{s,i})$:[^13] $$\begin{aligned}
    K^{s,i} &= K^s + \mathcal{H}_n(k^v, i) G\\
    K^{v,i} &= k^v K^{s,i}\end{aligned}$$ So, $$\begin{aligned}
{2}
    K^{v,i} &= k^v&&(k^s + \mathcal{H}_n(k^v, i))G\\
    K^{s,i} &= &&(k^s + \mathcal{H}_n(k^v, i))G\end{aligned}$$

### Sending to a subaddress

Let's say Alice is going to send Bob '0' amount again, this time via his
subaddress $(K_B^{v,1}, K_B^{s,1})$.

1.  Alice generates a random number $r \in_R \mathbb{Z}_l$, and
    calculates the one-time address
    $$K^o  = \mathcal{H}_n(r K_B^{v,1},0)G + K_B^{s,1}$$

2.  Alice sets $K^o$ as the addressee of the payment, adds the output
    amount '0' and the value $r K_B^{s,1}$ to the transaction data, and
    submits it to the network.

3.  Bob receives the data and sees the values $r K_B^{s,1}$ and $K^o$.
    He can calculate $k_B^v r K_B^{s,1} = r K_B^{v,1}$. He can then
    calculate $K'^{s}_B = K^o - \mathcal{H}_n(r K_B^{v,1},0)G$. When he
    sees that $K'^{s}_B = K^{s,1}_B$, he knows the transaction is
    addressed to him.[^14]

    Bob only needs his private view key $k_B^v$ and subaddress public
    spend key $K^{s,1}_B$ to find transaction outputs sent to his
    subaddress.

4.  The one-time keys for the output are: $$\begin{aligned}
            K^o &= \mathcal{H}_n(r K_B^{v,1},0)G + K_B^{s,1} = (\mathcal{H}_n(r K_B^{v,1},0) + k_B^{s,1})G  \\ 
            k^o &= \mathcal{H}_n(r K_B^{v,1},0) + k_B^{s,1}
        \end{aligned}$$

Now, Alice's transaction public key is particular to Bob ($r K_B^{s,1}$
instead of $r G$). If she creates a $p$-output transaction with at least
one output intended for a subaddress, Alice needs to make a unique
transaction public key for each output $t \in \{0,...,p-1\}$. In other
words, if Alice is sending to Bob's subaddress $(K_B^{v,1}, K_B^{s,1})$
and Carol's address $(K_C^v, K_C^s)$, she will put two transaction
public keys {$r_1 K_B^{s,1},r_2 G$} in the transaction data.[^15][^16]

## Integrated addresses {#sec:integrated-addresses}

To differentiate between the outputs they receive, a recipient can
request senders include a *payment ID* in transaction data.[^17] For
example, if Alice wants to buy an apple from Bob on a Tuesday, Bob could
write a receipt describing the purchase and ask Alice to include the
receipt's ID number when she sends him the money. This way Bob can
associate the money he receives with the apple he sold.

At one point senders could communicate payment IDs in clear text, but
manually including the IDs in transactions is inconvenient, and
cleartext is a privacy hazard for recipients, who might inadvertently
expose their activities.[^18] In Monero, recipients can integrate
payment IDs into their addresses, and provide those *integrated
addresses*, containing ($K^v$, $K^s$, payment ID), to senders. Payment
IDs can technically be integrated into any kind of address, including
normal addresses, subaddresses, and multisignature addresses.[^19]

Senders addressing outputs to integrated addresses can encode payment
IDs using the shared secret $r K_t^v$ and an XOR operation (recall
Section [\[sec:XOR_section\]](#sec:XOR_section){reference-type="ref"
reference="sec:XOR_section"}), which recipients can then decode with the
appropriate transaction public key and another XOR operation
[@integrated-addresses]. Encoding payment IDs in this way also allows
senders to prove they made particular transaction outputs (e.g. for
audits, refunds, etc.).[^20]

#### Encoding {#encoding .unnumbered}

The sender encodes the payment ID for inclusion in transaction data[^21]
$$\begin{aligned}
         k_{\textrm{mask}} &= \mathcal{H}_n(r K_t^v,\textrm{pid\_tag}) \\
      k_{\textrm{payment ID}} &= k_{\textrm{mask}} \rightarrow \textrm{reduced to bit length of payment ID}\\
  \textrm{encoded payment ID} &= \textrm{XOR}(k_{\textrm{payment ID}}, \textrm{payment ID})\end{aligned}$$

We include pid_tag to ensure $k_{\textrm{mask}}$ is different from the
component $\mathcal{H}_n(r K_t^v, t)$ in one-time output addresses.[^22]

#### Decoding {#decoding .unnumbered}

Whichever recipient the payment ID was created for can find it using his
view key and the transaction public key $r G$:[^23] $$\begin{aligned}
         k_{\textrm{mask}} &= \mathcal{H}_n(k_t^v r G,\textrm{pid\_tag}) \\
      k_{\textrm{payment ID}} &= k_{\textrm{mask}} \rightarrow \textrm{reduced to bit length of payment ID}\\
          \textrm{payment ID} &= \textrm{XOR}(k_{\textrm{payment ID}}, \textrm{encoded payment ID})\end{aligned}$$

Similarly, senders can decode payment IDs they had previously encoded by
recalculating the shared secret.

## Multisignature addresses {#sec:multisignature-addresses}

Sometimes it is useful to share ownership of funds between different
people/addresses. We dedicate Chapter
[\[chapter:multisignatures\]](#chapter:multisignatures){reference-type="ref"
reference="chapter:multisignatures"} to elaborating this topic.

[^1]: Except with negligible probability.

[^2]: Computer applications known as 'wallets' are used to find and
    organize the outputs owned by an address, to maintain custody of its
    private keys for authoring new transactions, and to submit those
    transactions to the network for verification and inclusion in the
    blockchain.

[^3]: To communicate an address to other users, it is extremely common
    to encode it in base-58, a binary-to-text encoding scheme first
    created for Bitcoin [@base-58-encoding]. See [@luigi-address] for
    more details.

[^4]: It is currently most common for the view key $k^v$ to equal
    $\mathcal{H}_n(k^s)$. This means a person only needs to save their
    spend key $k^s$ in order to access (view and spend) all of the
    outputs they own (spent and unspent). The spend key is typically
    represented as a series of 25 words (where the 25th word is a
    checksum). Other, less popular methods include: generating $k^v$ and
    $k^s$ as separate random numbers, or generating a random 12-word
    mnemonic $a$, where
    $k^s = {\tt sc\textunderscore reduce32}(\mathit{Keccak}(a))$ and
    $k^v = {\tt sc\textunderscore reduce32}(\mathit{Keccak}(\mathit{Keccak}(a)))$.
    [@luigi-address]

[^5]: The method described here is not enforced by the protocol, just by
    wallet implementation standards. This means an alternate wallet
    could follow the style of Bitcoin where recipients' addresses are
    included directly in transaction data. Such a non-compliant wallet
    would produce transaction outputs unusable by other wallets, and
    each Bitcoin-esque address could only be used once due to key image
    uniqueness.

[^6]: Except with negligible probability.

[^7]: In Monero, every instance (including when it's used for other
    parts of the transaction) of $r k^v G$ is multiplied by the cofactor
    8, so in this case Alice computes $8*r K^v_B$ and Bob computes
    $8*k^v_B r G$. As far as we can tell this serves no purpose (but it
    *is* a rule that users must follow). Multiplying by the cofactor
    ensures the resulting point is in $G$'s subgroup, but if $R$ and
    $K^v$ don't share a subgroup to begin with, then the discrete logs
    $r$ and $k^v$ can't be used to make a shared secret regardless.

[^8]: $K'^s_B$ is computed with `derive_subaddress_public_key()` because
    normal address spend keys are stored at index 0 in the spend key
    lookup table, while subaddresses are at indices 1,2\... This will
    make sense soon: see Section
    [1.3](#sec:subaddresses){reference-type="ref"
    reference="sec:subaddresses"}.

[^9]: Imagine Alice produces two transactions, each containing the same
    one-time output address $K^o$ that Bob can spend. Since $K^o$ only
    depends on $r$ and $K_B^v$, there is no reason she can't do it. Bob
    can only spend one of those outputs because each one-time address
    only has one key image, so if he isn't careful Alice might trick
    him. She could make transaction 1 with a lot of money for Bob, and
    later transaction 2 with a small amount for Bob. If he spends the
    money in 2, he can never spend the money in 1. In fact, no one could
    spend the money in 1, effectively 'burning' it. Monero wallets have
    been designed to ignore the smaller amount in this scenario.

[^10]: Actually, as of protocol v12 two outputs are *required* from each
    (non-miner) transaction, even if it means one output has 0 amount
    (`HF_VERSION_MIN_2_OUTPUTS`). This improves transaction
    indistinguishability by mixing 1-output cases with the much more
    common 2-output transactions. Previous to v12 the core wallet
    software was already creating 0-value outputs. The core
    implementation sends 0-amount outputs to a random address.

[^11]: After Bulletproofs were implemented in protocol v8, each
    transaction became limited to no more than 16 outputs
    (`BULLETPROOF_MAX_OUTPUTS`). Previously there was no limit, aside
    from a restraint on transaction size (in bytes).

[^12]: Prior to subaddresses (added in the software update corresponding
    with protocol v7 [@subaddress-pull-request]), Monero users could
    simply generate many normal addresses. To view each address's
    balance, you needed to do a separate scan of the blockchain record.
    This was very inefficient. With subaddresses, users maintain a
    look-up table of (hashed) spend keys, so one scan of the blockchain
    takes the same amount of time for 1 subaddress, or 10,000
    subaddresses.

[^13]: It turns out the subaddress hash is domain separated, so it's
    really $\mathcal{H}_n(T_{sub},k^v,i)$ where $T_{sub} =$"SubAddr\".
    We omit $T_{sub}$ throughout this document for brevity.

[^14]: An advanced attacker may be able to link subaddresses
    [@janus-attack] (a.k.a. the Janus attack). With subaddresses (one of
    which can be a normal address) $K_B^1$ $\&$ $K_B^2$ the attacker
    thinks may be related, he makes a transaction output with
    $K^o = \mathcal{H}_n(r K_B^{v,2},0)G + K_B^{s,1}$ and includes
    transaction public key $r K_B^{s,2}$. Bob calculates $r K_B^{v,2}$
    to find $K'^{s,1}_B$ but has no way of knowing it was his *other*
    (sub)address's key used! If he tells the attacker that he received
    funds to $K_B^1$, the attacker will know $K_B^2$ is a related
    subaddress (or normal address). Since subaddresses are outside the
    protocol's scope, mitigations are up to wallet implementers. No
    known wallets have done so, and any mitigation would only work for
    compliant wallets. Potential mitigations include: not informing
    attackers of received funds, including encrypted transaction private
    key $r$ in transaction data, a Schnorr signature on the shared
    secret using $K^{s,1}$ as the base point instead of $G$, and
    including $rG$ in transaction data and verifying the shared secret
    with $rK^{s,1} \stackrel{?}{=} (k^s + \mathcal{H}_n(k^v, 1))*rG$
    (requires the private spend key). Outputs received by a normal
    address should also be verified. See [@janus-mitigation-issue-62]
    for a discussion of the last mitigation listed.

[^15]: In Monero subaddresses are prefixed with an '8', separating them
    from addresses, which are prefixed with '4'. This helps senders
    choose the correct procedure when constructing transactions.

[^16]: There is some intricacy to when additional transaction public
    keys are used (see the code path `transfer_selected_rct()`
    $\rightarrow$ `construct_tx_and_get_tx_key()` $\rightarrow$
    `construct_tx_with_tx_key()` $\rightarrow$
    `generate_output_ephemeral_keys()` and `classify_addresses()`)
    surrounding change outputs where the transaction author knows the
    recipient's view key (since it's himself; also the case for dummy
    change outputs, which are created when a 0-amount output is
    necessary, since authors generate those addresses). Whenever there
    are at least two non-change outputs, and at least one of their
    recipients is a subaddress, proceed in the normal way explained
    above (a current bug in the core implementation adds an extra
    transaction public key to transaction data even beyond the
    additional keys, which is not used for anything). If either just the
    change output is to a subaddress, or there is just one non-change
    output and it's to a subaddress, then only one transaction public
    key is created. In the former case, the transaction public key is
    $rG$ and the change's one-time key is (subaddress index 1, using $c$
    subscript to denote the change's keys)
    $K^o = \mathcal{H}_n(k^v_c r G,t)G + K_c^{s,1}$ using the normal
    view key and subaddress's spend key. In the latter case the
    transaction public key $r K^{v,1}$ is based off the subaddress's
    view key, and the change's one time key is
    $K^o = \mathcal{H}_n(k^v_c*r K^{v,1},t)G + K_c^s$. These details
    help mingle a portion of subaddress transactions amongst the more
    common normal address transactions, and 2-output transactions which
    compose around 95% of transaction volume as of this writing.

[^17]: Currently, Monero implementations only support one payment ID per
    transaction regardless of how many outputs it has.

[^18]: These long-form (256 bit) cleartext payment IDs were deprecated
    in v0.15 of the core software implementation (coincident with
    protocol v12 in November 2019). While other wallets may still
    support them and allow their inclusion in transaction data, the core
    wallet will ignore them.

[^19]: Within the authors' knowledge, integrated addresses have only
    ever been implemented for normal addresses.

[^20]: Since an observer can recognize the difference between
    transactions with and without payment IDs, using them is thought to
    make the Monero transaction history less uniform. Because of this,
    since protocol v10 the core implementation adds a dummy encrypted
    payment ID to all 2-output transactions. Decoding one will reveal
    all 0s (this is not required by the protocol, just best practice).

[^21]: In Monero payment IDs for integrated addresses are conventionally
    64 bits long.

[^22]: In Monero, pid_tag = `ENCRYPTED_PAYMENT_ID_TAIL` = 141. In, for
    example, multi-input transactions we compute
    $\mathcal{H}_n(r K_t^v, t) \pmod l$ to ensure we are using a scalar
    less than the EC subgroup order, but since $l$ is 253 bits and
    payment IDs are only 64 bits, taking the modulus for encoding
    payment IDs would be meaningless, so we don't.

[^23]: Transaction data does not indicate which output a payment ID
    'belongs' to. Recipients have to identify their own payment IDs.
