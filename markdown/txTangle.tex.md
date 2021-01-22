# Joint Monero Transactions (TxTangle) {#chapter:txtangle}

There are a number of unavoidable transaction graph heuristics created
by the nature of different entities and scenarios. In particular, the
behavior of miners, pools (Section 5.1 of [@AnalysisOfLinkability]),
escrowed marketplaces, and exchanges have clear patterns open to
analysis even within Monero's ring signature-based protocol.

We describe here TxTangle, analogous to Bitcoin's CoinJoin
[@coinjoin-wiki], one method to confuse those heuristics.[^1] In
essence, several transactions are squashed into one transaction, making
the behavior patterns of each participant blend together.

To accomplish that obfuscation, it must be unreasonably difficult for
observers to use the information contained in a joint transaction to
group inputs and outputs, and associate them with individual
participants, nor know how many participants there actually were.[^2]
Moreover, even the participants themselves should not be aware of the
number of participants, or be able to group the inputs and outputs of
other participants unless they control all but one participant's
grouping.[^3] Finally, it should be possible to construct joint
transactions without relying on a central authority
[@exa-blockchain-analysis]. Fortunately, all these requirements can be
achieved in Monero.

## Building joint transactions {#sec:building-txtangle}

In a normal transaction, inputs and outputs are tied together using the
proof that amounts balance. From Section
[\[sec:commitments-and-fees\]](#sec:commitments-and-fees){reference-type="ref"
reference="sec:commitments-and-fees"}, the sum of pseudo output
commitments equals the sum of output commitments (plus the fee
commitment). $$\sum_j C'^a_{j} - (\sum_t C^b_{t} + f H) = 0$$

A trivial joint transaction could take all the content of multiple
transactions, and stick them in one. MLSAG messages would sign all the
sub-transactions' data, and amount balancing would quite obviously work
(0 + 0 + 0 = 0).[^4] However, input and output groupings could just as
trivially be identified based on testing if input/output subsets have
balancing amounts.[^5]

We can easily get around this by computing shared secrets between each
pair of participants, then adding these offsets to their pseudo output
commitments' masks (Section
[\[sec:ringct-introduction\]](#sec:ringct-introduction){reference-type="ref"
reference="sec:ringct-introduction"}). In each pair, one participant
adds the shared secret to one of his pseudo output commitments, and the
other participant subtracts it from one of *his* pseudo commitments.
When summed together, the secrets cancel out, and since each pair of
participants has a shared secret the amount balance only appears after
all commitments are combined.[^6]

Shared secrets may hide input/output groupings in the immediate sense,
but participants must learn about all the inputs and outputs somehow,
and the easiest way is if they each communicate their individual
input/output groupings. Clearly this violates the initial premise, and
in any case implies participants know the number of participants.

### $n$-way communication channel {#subsec:n-way-channel}

The maximum number of participants to a TxTangle is either the number of
outputs or inputs (whichever is lower). We model that by each real
participant pretending to be a different person for each output he is
sending. This is primarily for the purpose of setting up a group
communication channel with other would-be participants, without
revealing how many participants there are.

Imagine $n$ ($2 \leq n \leq 16$, although at least 3 is recommended)[^7]
supposedly unrelated people gather at apparently random intervals in a
chatroom, scheduled to open at time $t_0$ and close at $t_1$ (only 16
people can be in a chatroom at once, and the chatroom has conditions
like fee priority, base fee per byte \[to simplify consensus around the
current median and block reward\], and range of acceptable transaction
types since e.g. currently transactions from the beginning of Monero
can't be directly spent in a RingCT transaction
[@pre-ringct-outputs-like-coinbase-research-issue-59]). At $t_1$ all
mock-members signal desire to proceed by publishing a public key, and
the room is converted into an $n$-way communication channel by
constructing a shared secret amongst all the mock-members.[^8] This
shared secret is used to encrypt message contents, while mock-members
sign input-related messages using SAG signatures (Section
[\[SAG_section\]](#SAG_section){reference-type="ref"
reference="SAG_section"}) so it's never clear who sent a given message,
and output-related messages with a bLSAG (Section
[\[blsag_note\]](#blsag_note){reference-type="ref"
reference="blsag_note"}) on the set of mock-member public keys so actual
outputs are dissociated from mock-members.[^9]

### Message rounds to construct a joint transaction {#subsec:message-rounds-txtangle}

After the channel is set up, TxTangle transactions can be constructed in
five rounds of communication, where the next round may only begin after
the previous is finished, and each round is given a timed communication
interval within which messages should be randomly published. These
intervals are intended to prevent message clusters that would reveal
input/output groupings.

1.  Each mock-member privately generates a random scalar for each
    intended output, and signs them with bLSAGs. A sorted list of these
    scalars is used to determine output indices (recall Section
    [\[sec:multi_out_transactions\]](#sec:multi_out_transactions){reference-type="ref"
    reference="sec:multi_out_transactions"}; the smallest scalar gets
    index $t = 0$).[^10] They publish those bLSAGs, and also SAGs which
    sign the transaction version numbers of intended inputs. After this
    round participants can calculate the transaction weight based on
    number of inputs and outputs, and accurately estimate the fee
    required.[^11][^12][^13]

2.  Each mock-member uses the list of public keys to construct a shared
    secret with each other member for offsetting their pseudo output
    commitments, and decides who will add or subtract based on each
    pair's smaller public key.[^14] Each mock-member must pay for
    1/$n$of the fee estimate (using integer division). The mock-member
    with lowest output index is given the responsibility of paying for
    the remainder after dividing (it will be a truly infinitesimal
    amount, but must be taken into account to prevent fingerprinting
    TxTangle transactions). They privately generate transaction public
    keys for each of their outputs (not to be sent to other members just
    yet), and construct their output commitments, encoded amounts, and
    Part A partial proofs to be used for the aggregate Bulletproof range
    proof, signing all of it with bLSAGs (one commitment, one encoded
    amount, and one partial proof per bLSAG message, and the key image
    links these to the original list of random scalars that was used to
    specify output indices). Pseudo output commitments are generated as
    normal (Section
    [\[sec:ringct-introduction\]](#sec:ringct-introduction){reference-type="ref"
    reference="sec:ringct-introduction"}), then offset with the shared
    secrets, and signed with SAGs. After the bLSAGs and SAGs are
    published, and assuming participants estimated the total fee in the
    same way, they may now verify that amounts balance overall.[^15]

3.  If amounts balance properly we begin a small additional round for
    building the aggregate Bulletproof that proves all output amounts
    are in range. Each mock-member uses the previous round's Part A
    partial proofs and output commitments, and privately computes the
    aggregate challenge A. They use it to construct their Part B partial
    proof, which they send to the channel with a bLSAG.

4.  Participants begin filling in the message to be signed by MLSAGs
    (recall the footnote in Section
    [\[full-signature\]](#full-signature){reference-type="ref"
    reference="full-signature"}). Published in random order over the
    communication interval are two kinds of messages. Each input's ring
    member offsets and key images are signed with a SAG and associated
    with the correct pseudo output commitment. Each output's one-time
    address, transaction public key, and Part C partial proof (computed
    based on the Part B partial proofs and an aggregate challenge B) are
    signed with a bLSAG (these can also include a random base
    transaction public key component, which as we will see can be used
    for fake Janus mitigation).

5.  Participants use all the partial proofs to complete the aggregate
    Bulletproof, and privately apply a logarithmic inner product
    technique to compress it for the final proof to be included in
    transaction data. Once all the information to be signed by MLSAGs is
    collected, each participant completes their inputs' MSLAGs and
    randomly sends them (with a SAG for each) to the channel over the
    communication interval. Any participant may submit the transaction
    as soon as they have all the pieces.

#### Transaction public keys and the Janus mitigation {#transaction-public-keys-and-the-janus-mitigation .unnumbered}

If every participant to a TxTangle knows the transaction private key $r$
(Section
[\[sec:one-time-addresses\]](#sec:one-time-addresses){reference-type="ref"
reference="sec:one-time-addresses"}), then any of them may test the
others' one-time output addresses against a list of known addresses. For
this reason it is necessary to construct TxTangle transactions as if
there were a subaddress recipient (Section
[\[sec:subaddresses\]](#sec:subaddresses){reference-type="ref"
reference="sec:subaddresses"}), including different transaction public
keys for each output.

To match with possible implementation of a mitigation for the Janus
attack related to subaddresses, in which one additional 'base'
transaction public key is included in the extra field
[@janus-mitigation-issue-62], TxTangles should also have a fake 'base'
key composed of a sum of random keys generated by each mock-member.[^16]

Many TxTangle participants sending money to a subaddress will likely
have at least two outputs, one of which diverts change back to the
participant. This means any TxTangle participant can still enable Janus
mitigation by making their change's transaction public key also the
'base' key for the subaddress recipient.[^17] The subaddress recipient
might realize the transaction is a TxTangle, and that the 'base' key
probably corresponds with the sender's change output.[^18]

### Weaknesses {#subsec:weaknesses-txtangle}

Malicious actors have two primary ways to defeat the purpose of
TxTangle, which is to hide input/output groupings from potential
adversaries/analysts. They may pollute the transactions, such that the
subset of honest participants is smaller (or even non-existent)
[@coinjoin-pollution]. They may also cause TxTangle attempts to fail,
and use subsequent attempts by the same participants to estimate
input/output groupings.

The former case is not easy to mitigate, especially in the very
decentralized case where no participant has a reputation. One possible
application of TxTangle is with collaborating pools, who may hide which
pool their miners belong to among a collection of pools. Such pools
would know the input/output groupings, but since the purpose is helping
their connected miners it would behoove them to keep the information
secret. Moreover, such TxTangles would not permit bad actors, assuming
the pools are somewhat honest.

The latter case can be defended against by only attempting to TxTangle a
few times before taking a break, and by always regenerating most random
elements of a transaction for new attempts. These elements include the
transaction public keys, pseudo commitment masks, range proof scalars,
and MLSAG scalars. In particular, the set of ring decoys for each input
should remain the same to prevent cross-comparisons revealing the true
input. If possible, different true inputs should be used for different
TxTangle attempts. Since this weakness is inevitable, it makes the next
section's concept more palatable.

## Hosted TxTangle {#sec:hosted-txtangle}

Truly decentralized TxTangle has some open questions. How are the timed
rounds initiated and enforced? How are chatrooms created in the first
place, for participants to find each other? The most straightforward way
is with a TxTangle host, who generates and manages those chatrooms.

Such a host would seem to defy the goal of obfuscated participation,
since each individual must connect, and send it messages that could be
used to correlate input/output groupings (especially if the host
participates and knows the message contents). We can use a network like
I2P[^19] to make each message received by the host appear as if from a
unique individual.

### Basic communication with a host over I2P, and other features {#subsec:txtangle-host-communication}

With I2P, users make so-called 'tunnels' that pass heavily encrypted
messages through other users' clients before reaching their destination.
From what we understand, these tunnels can transport multiple messages
before being destroyed and recreated (e.g. there appears to be a
10-minute timer on tunnels). It is essential for our use case to
carefully control when new tunnels are created, and which messages may
come out of the same tunnel.[^20]

1.  *Applying for TxTangles*: In our original $n$-way proposal (Section
    [1.1.1](#subsec:n-way-channel){reference-type="ref"
    reference="subsec:n-way-channel"}) participants gradually add their
    mock-members to available TxTangle rooms before they are scheduled
    to close. However, if a large enough volume of users try to TxTangle
    concurrently, there is likely to be a high rate of failure as users
    try to randomly put all their intended outputs in the same TxTangle
    'room', but then the rooms get full too soon so they have to back
    out. It would be quite a mess.

    We can make an impactful optimization by telling the host how many
    outputs we have (e.g. giving him a list of our mock-member public
    keys), and letting him assemble each TxTangle's participants. Since
    we still retain the bLSAG and SAG messaging protocol, the host won't
    be able to identify output groupings in the final transaction. All
    he knows is the number of participants, and how many outputs each
    had. Moreover, in this scenario observers can't monitor open
    TxTangle rooms to deduce information about the participants, an
    important privacy improvement. Note that the host's power to pollute
    TxTangles isn't significantly different from the non-host design, so
    this change is neutral to that attack vector.

2.  *Communication method*: Since the host is already acting as the
    locus of message transport, it is simplest for him to manage
    TxTangle communication. During each round the host collects messages
    from mock-members (still at random over a communication interval),
    and at the end of a round there is a short data distribution phase
    where he sends all the collected data to each participant, with a
    buffer period before the next round to ensure the messages are
    received and given time to process.

3.  *Tunnels and input/output groupings*: Once a TxTangle has been
    initiated, users should dissociate their mock-member identities from
    the actual outputs that get created. This means creating new tunnels
    for bLSAG-signed messages, and each such tunnel may only transmit
    messages related to a specific output (it is fine to transmit
    multiple such messages through the same tunnel, since obviously
    information about the same output comes from the same source). They
    should also create new tunnels for SAG-signed messages related to
    specific inputs.

4.  *Threat of host MITM attack*: The host might fool a participant by
    pretending to be other participants, since he controls sending out
    the mock-member list for constructing bLSAGs and SAGs. In other
    words, the list he sends participant A might contain participant A's
    mock-members, and all the rest are his own. Messages received by
    participant B are re-signed using A's list before being
    retransmitted to A. Since all messages signed by A's list belong to
    A, the host would have direct insight into A's input/output
    groupings!

    We can prevent the host from acting as MITM of honest participant
    interactions by modifying how transaction public keys are made.
    Participants send each other their intended transaction public keys
    as normal (with a bLSAG), then, much like robust key aggregation
    from Section
    [\[sec:robust-key-aggregation\]](#sec:robust-key-aggregation){reference-type="ref"
    reference="sec:robust-key-aggregation"}, the actual keys that get
    included in transaction data (and used to make output commitment
    masks, etc.) are prefixed with a hash of the mock-member list. In
    other words, $\mathcal{H}_n(T_{agg},\mathbb{S}_{mock},r_t G)*r_t G$
    is the $t$transaction public key. Baking the mock-member list into
    the transaction itself makes it very difficult to complete TxTangles
    without direct communication between all actual participants.[^21]

### Host as a service {#subsec:txtangle-host-service}

It's important for sustainability and continuous improvement that a
TxTangle service operate for profit.[^22] Rather than compromise user
identities with an account-based model, the host may participate in each
TxTangle as a lone output, and require the participants to fund it. When
accessing the host's 'eepsite'/service to apply for TxTangles, users are
notified of the current hosting charge, which should be paid on a
per-output basis.

Participants would be responsible for paying fractions of the fee *and*
the host charge. This time, the smallest mock-member's public key
(excluding the host's key) would take the remainder of both the fee and
host charge.[^23] Since the host has no inputs, he has no pseudo output
commitment to cancel his output's commitment mask. Instead, he creates
shared secrets with the other mock-members as usual, then separates his
real commitment mask into randomly sized chunks for each other
mock-member and divides them by the shared secrets. He publishes a list
of those scalars (corresponding them with each other mock-member based
on their public key), signing with his mock-member key so participants
know it's from the host. The appearance of this list signals the
beginning of round 1 from Section
[1.1.2](#subsec:message-rounds-txtangle){reference-type="ref"
reference="subsec:message-rounds-txtangle"} (e.g. the end of setup round
'0'). Mock-members will multiply their host-scalar by the appropriate
shared secret, and add that to their pseudo commitment mask. In this
way, even the host's output cannot be identified by any participant in
the final transaction without a full coalition against him.

To simplify calculations of the fee, the host may distribute the total
fee to be used in the transaction at the end of round 1, since he will
learn the transaction weight early. Participants can verify that amount
is similar to the expected amount, and pay their fraction of it.

If participants collaborate to cheat, and not provide the hosting
charge, then the host may terminate the TxTangle at round 3. He may also
terminate if messages appear in the channel that should not be there or
that aren't valid.

At the end of round 5 the host completes the transaction and submits it
to the network for verification, as part of his service. He includes the
transaction hash in the final distribution message.

## Using a trusted dealer {#sec:dealer-txtangle}

There are some drawbacks to decentralized TxTangle. It requires all
participants actively communicate within a strict timing schedule (and
find each other to begin with), and is challenging to implement.

Adding a central dealer, who is responsible for collecting transaction
information from each participant and obfuscating the input/output
groupings, can simplify the proceedings. The cost is a higher bar of
trust, since the dealer must (at minimum) learn those groupings.[^24]

### Dealer-based procedure {#subsec:dealer-procedure-txtangle}

The dealer will advertise that he is available to manage TxTangles, and
collects applications from potential participants (consisting of the
number of intended inputs \[with their types\] and outputs). He may
participate with his own input/output set if he wishes.

After a grouping of almost 16 outputs is assembled (there should be two
or more participants, and no participant may have all but one output or
input), the dealer will start the first of five rounds. In each round he
accumulates information from each participant, makes some decisions, and
sends out messages that signify the beginning of a new round.

1.  To begin, the dealer generates, for each pair of participants, a
    random scalar, and decides which in each pair should have the
    positive or negative version. He uses the number and type of inputs
    and outputs to estimate the total fee required. He sums each
    participant's scalars together, and privately sends to each their
    sum, along with the fee fraction they are expected to pay for, and
    the (randomly chosen) indices of their outputs. These messages
    constitute a signal to participants that a TxTangle is beginning.

2.  Each participant constructs their sub-transaction as they normally
    would, generating separate transaction public keys for their outputs
    (with Janus mitigation as needed), calculating one-time output
    addresses and encoding output amounts, making pseudo output
    commitments that balance output commitments and the fee fraction,
    assembling a list of ring member offsets for use in MLSAG signatures
    along with the appropriate key images, and add to one of their
    pseudo output commitments the dealer-sent scalar (multiplied by
    $G$). They create Part A partial proofs for their outputs, and send
    all this information to the dealer. The dealer verifies that input
    and output amounts balance, and sends the complete list of Part A
    partial proofs to each participant.

3.  Each participant computes the aggregate challenge A, and generates
    Part B partial proofs which they send to the dealer. The dealer
    collects the partial proofs and distributes them to all the other
    participants.

4.  Each participant computes the aggregate challenge B, and generates
    Part C partial proofs which they send to the dealer. The dealer
    collects these, and applies the logarithmic inner product technique
    to compress them into the final proof. Assuming the proof verifies
    as it should, he generates a random fake Janus 'base' transaction
    public key, and sends the message to be signed in MLSAGs to each
    participant.

5.  Each participant completes their MLSAGs and sends them to the
    dealer. Once he has all the pieces, he may finish constructing the
    transaction, and submit it to be included in the blockchain. He may
    also send the transaction ID to each participant so they can confirm
    it was published.

[^1]: This chapter constitutes the proposal for a joint transaction
    protocol. No such protocol has been implemented as of this writing.
    A previous proposal, named MoJoin and created by pseudonymous
    co-author Monero Research Lab (MRL) researcher Sarang Noether,
    required a trusted dealer to function. Such a dealer seems to
    conflict with the Monero project's basic commitment to privacy and
    fungibility, and hence MoJoin was not pursued further.

[^2]: Since in Bitcoin amounts are clearly visible, it is often possible
    to group CoinJoin inputs and outputs based on amount sums.
    [@coinjoin-sudoku]

[^3]: Maliciously polluting joint transactions is a potential attack on
    this method, first identified for CoinJoin. [@coinjoin-pollution]

[^4]: Since Bulletproofs-style range proofs are actually aggregated into
    one (Section
    [\[sec:range_proofs\]](#sec:range_proofs){reference-type="ref"
    reference="sec:range_proofs"}), participants would have to
    collaborate to some extent even in the trivial case.

[^5]: Participants could try to divide up the fee in a fancy manner to
    confuse observers, but it would fail in the face of brute force
    since fees are not that large (around 32 bits or less).

[^6]: We offset the pseudo output commitments instead of output
    commitments since output commitment masks are constructed from the
    recipient's address (Section
    [\[sec:pedersen_monero\]](#sec:pedersen_monero){reference-type="ref"
    reference="sec:pedersen_monero"}).

[^7]: Currently, a transaction may have at most 16 outputs.

[^8]: The multisig method from Section
    [\[sec:m-of-n\]](#sec:m-of-n){reference-type="ref"
    reference="sec:m-of-n"} is one way, extending M-of-N all the way to
    1-of-N.

[^9]: Each separate set of TxTangle bLSAGs should use the same key
    images, since everything related to a given output is linked
    together.

[^10]: Output index selection should match other implementations of
    transaction construction to avoid fingerprinting different software.
    We use this effectively random approach to align with the core
    implementation, which also randomizes outputs.

[^11]: If it turns out there must be only two real participants, based
    on comparing the number of inputs and outputs to one's own
    input/output count, the TxTangle can be abandoned. It's recommended
    for each participant to have at least two inputs and two outputs, in
    case of malicious actors who don't abandon TxTangles even when they
    realize it's just two participants. This recommendation is open to
    debate, since using more inputs and outputs is not heuristically
    neutral.

[^12]: TxTangle transactions should not have extraneous information
    stored in the extra field (e.g. no encrypted payment ID unless it's
    only a 2-output TxTangle which should have at least a dummy
    encrypted payment ID).

[^13]: Fee estimation should be based on a standardized approach, so
    each participant calculates the same thing. Otherwise outputs may be
    clustered based on fee calculation method. This same fee standard
    should be implemented outside of TxTangle, to promote TxTangle
    transactions looking the same as normal transactions.

[^14]: Since points are compressed (Section
    [\[point_compression_section\]](#point_compression_section){reference-type="ref"
    reference="point_compression_section"}), just interpret the keys as
    32-byte integers. The smaller key's owner adds, and larger key's
    owner subtracts, by convention.

[^15]: We don't publish the separate fee amounts paid for in case a
    participant calculated it wrong, which may reveal an output cluster
    due to a collection of non-standard fee amounts. If amounts don't
    balance properly, the TxTangle transaction may be abandoned.

[^16]: Key cancellation (Section
    [\[subsec:drawbacks-naive-aggregation-cancellation\]](#subsec:drawbacks-naive-aggregation-cancellation){reference-type="ref"
    reference="subsec:drawbacks-naive-aggregation-cancellation"}) should
    not be a problem, since it's just a fake key and should ideally be
    randomly indexed within the list of transaction public keys.

[^17]: If sending to your own subaddress, there is no need for Janus
    mitigation. Wallets enabled for Janus mitigation should recognize
    the amount spent in a TxTangle equals the amount received to your
    subaddress, so they don't erroneously notify the user of a problem.

[^18]: This is assuming transaction public keys are 1:1 with the
    outputs, as is apparently the case today. If it was standard for
    transaction public keys to be in random or sorted order within the
    extra field, then TxTangle and non-TxTangle transactions would be
    largely indistinguishable for subaddress recipients. There are niche
    cases where TxTangle participants are unable to include a 'base' key
    (e.g. when all their outputs are to subaddresses), or where it is
    clearly non-TxTangle since the subaddress recipient receives most or
    all of the outputs. Note that since TxTangle transactions would
    generally have a lot more outputs than a typical transaction, this
    heuristic can be used to differentiate TxTangles from normal
    subaddress'd transactions.

[^19]: The Invisible Internet Project (<https://geti2p.net/en/>).

[^20]: In I2P there are 'outbound' and 'inbound' tunnels (see
    <https://geti2p.net/en/docs/how/tunnel-routing>). Everything
    received through an inbound tunnel looks like it's from the same
    source even if from multiple sources, so on the surface it would
    appear TxTangle users don't need to create different tunnels for all
    their usecases. However, if the TxTangle host makes himself the
    entry point for his own inbound tunnel, then he gains direct access
    to the outbound tunnels of TxTangle participants.

[^21]: If Janus mitigation is implemented, this MITM defense should
    instead be done with the fake Janus base key. Each mock-member
    provides a random key $r_{mock} G$, then the actual base key is
    $\sum_{mock} \mathcal{H}_n(T_{agg},\mathbb{S}_{mock},r_{mock} G)*r_{mock} G$.

[^22]: While a deployed TxTangle service may be for profit, the code
    itself could be open source. This would be important for auditing
    wallet software that interacts with a TxTangle service.

[^23]: We must use mock-member keys here since the host doesn't pay a
    fee, and his output index is unknown.

[^24]: This section is inspired by the MoJoin protocol outline.
