# Monero in an Escrowed Marketplace {#chapter:escrowed-market}

Most of the time purchasing from an online retailer goes smoothly. A
buyer sends money to a vendor, and the expected product arrives at their
doorstep. If the product has a defect, or in some cases if the buyer
changes their mind, they can return it and get a refund.

It's difficult to trust a person or organization you have never met, and
many shoppers can feel safe in their purchases knowing their credit card
company will reverse a payment on request [@credit-card-reversals].

Cryptocurrency transactions are not reversible, and there is limited
legal recourse a buyer or seller can take when something goes wrong,
especially for Monero which is not open to easy chain analysis
[@chainalysis-2020-report]. The cornerstone of robust online shopping
with cryptocurrencies is 2-of-3 multisignature-based escrowed exchanges,
which enable third parties to mediate disputes. By trusting those third
parties, even completely anonymous vendors and shoppers can interact
without formality.

Since Monero multisig interactions can be rather complex (recall Section
[\[sec:simplified-communication\]](#sec:simplified-communication){reference-type="ref"
reference="sec:simplified-communication"}), we dedicate this chapter to
describing a maximally efficient escrowed shopping environment.[^1][^2]

## Essential features {#sec:escrowed-marketplace-essential-features}

There are several basic requirements and features for streamlined
interactions between buyers and sellers online. We take these points
from René's OpenBazaar investigation
[@openbazaar-rbrunner-investigation], as they are quite sensible and
extensible.

-   *Offline selling*: A buyer should be able to access a vendor's
    online shop and place an order while the vendor is offline.
    Obviously, the vendor must actually go online to receive the order
    and fulfill it.[^3]

-   *Purchase order-based payments*: Vendor addresses for receipt of
    funds are unique for each purchase order, in order to match orders
    and payments.

-   *High-trust purchasing*: A buyer may, if they trust a vendor, pay
    for a product even before it has been fulfilled or delivered.

    -   *Online direct payment*: After confirming the vendor is online,
        and that their product listing is available, the purchaser sends
        money in a single transaction to the vendor via a
        vendor-provided address, who then signals the order is being
        fulfilled.

    -   *Offline payment*: If a vendor is offline, the buyer creates and
        funds a 1-of-2 multisig address with enough money to cover their
        intended purchase. When the vendor comes online, they may take
        money out of the multisig address (sending change back to the
        buyer), and fulfill the order. If the vendor never comes back
        online (or e.g. after some reasonable waiting period), or if the
        buyer changes their mind before he comes back, the buyer may
        empty the 1-of-2 address back into her personal wallet.

-   *Moderated purchasing*: A 2-of-3 multisig address is constructed
    between the buyer, vendor, and a moderator agreed on by both buyer
    and vendor. The buyer funds this address before vendor fulfillment,
    and then once the product is delivered two of the parties cooperate
    to release the funds. If the vendor and buyer can't reach an
    agreement, they may enlist the moderator's judgement.

We will not cover high-trust purchasing, as, without any complex
communication required, the features are fairly trivial.[^4]

### Purchasing workflow {#subsec:escrowed-marketplace-purchasing-workflow}

All purchases should fit within the same set of steps, assuming all
parties do their due diligence. A number of steps are related to what a
moderator should expect when stepping in, e.g. "did you request a
refund, before getting me involved?\".

1.  A buyer accesses the vendor's online shop, identifies a purchase to
    make, selects 'I want to purchase it', makes funding available for
    that purchase, then submits the purchase order to the vendor.

2.  The vendor receives the purchase order, verifies the product is in
    stock and the available funding is enough, and either returns money
    to the buyer or fulfills the order by shipping out the product and
    notifying the buyer with a receipt.

    -   For a 2-of-3 multisig, the buyer can optionally authorize
        payment when receiving notification of fulfillment.

3.  The buyer either receives the product as expected, or doesn't
    receive the product on time or receives a defective product.

    -   *Good product*: The buyer either gives feedback to the vendor,
        or does nothing.

        -   *Buyer sends feedback*: The buyer can leave either positive,
            or negative feedback.

            -   *Positive feedback*: If this is a 2-of-3 multisig that
                hasn't been paid yet, then this is the step where the
                buyer confirms payment to the vendor. Otherwise it's
                just a positive review. \[END OF WORKFLOW\]

            -   *Negative feedback*: If this is a 2-of-3 multisig, then
                this step leads into the 'bad product' workflow.
                Otherwise it's just a negative review.

        -   *Buyer does nothing*: Either the vendor has already been
            paid, or it's a 2-of-3 multisig and he needs to cooperate
            with someone to receive funds.

            -   *Vendor has been paid*: \[END OF WORKFLOW\]

            -   *Vendor has not been paid*: The vendor pursues payment.

                1.  The vendor contacts the buyer requesting payment (or
                    sends out a reminder).

                2.  The buyer either responds, or does not respond.

                    -   *Buyer responds*: The buyer's response can be to
                        make a payment, or pursue a refund.\
                        $>$ *Buyer makes payment*: \[END OF WORKFLOW\]\
                        $>$ *Buyer pursues refund*: Go to the 'bad
                        product' workflow.

                    -   *Buyer does not respond*: The vendor enlists the
                        moderator's help to release funds. \[END OF
                        WORKFLOW\]

    -   *No product or bad product*: The buyer pursues a refund.

        1.  The buyer contacts the vendor requesting a refund, perhaps
            with an explanation.

        2.  The vendor complies with the refund request, or contests it
            (or ignores it).

            -   *Vendor complies*: Money is refunded to the buyer. \[END
                OF WORKFLOW\]

            -   *Vendor contests*: Either it's not a 2-of-3 multisig, or
                it is.

                -   *It's not a 2-of-3*: \[END OF WORKFLOW\]

                -   *It's a 2-of-3*: Either the buyer gives up on the
                    refund request (literally, or by failing to respond
                    in a timely manner), or the buyer is adamant.

                    -   *Buyer gives up*: Either the buyer authorized
                        the vendor's payment, or not.\
                        $>$ *Buyer authorized payment*: \[END OF
                        WORKFLOW\]\
                        $>$ *Buyer didn't authorize*: The vendor
                        contacts the moderator, who authorizes the
                        payment. \[END OF WORKFLOW\]

                    -   *Buyer is adamant*: The vendor or buyer contacts
                        the moderator, who cooperates with the
                        participants to pass judgement. \[END OF
                        WORKFLOW\]

## Seamless Monero multisig {#sec:escrowed-marketplace-seamless-multisig}

We can take advantage of the natural purchase order workflow to squeeze
in nearly all parts of a Monero 2-of-3 multisignature interaction
without the participants even noticing. There is an extra small step for
the vendor at the end, where he must sign and submit the final
transaction to receive payment, analogous to 'emptying the cash
register'.[^5]

### Basics of a multisig interaction {#subsec:escrowed-marketplace-multisig-interaction-basics}

All 2-of-3 multisig interactions contain the same set of communication
rounds, involving address setup and transaction building. In order to
comply with the normal workflow we use a reorganized transaction
construction process compared to our multisig chapter (recall Sections
[\[sec:simplified-communication\]](#sec:simplified-communication){reference-type="ref"
reference="sec:simplified-communication"} and
[\[sec:n-1-of-n\]](#sec:n-1-of-n){reference-type="ref"
reference="sec:n-1-of-n"}).[^6]

1.  *Address setup*

    1.  All users must first learn the other participants' base keys,
        which they will use to construct shared secrets. They transmit
        the public keys of those shared secrets (e.g.
        $K^{sh} = \mathcal{H}_n(k^{base}_A*k^{base}_B G) G$) to the
        other users.

    2.  After learning all shared secret public keys, each user may
        `premerge` and then `merge` them into the address's public spend
        key. The aggregation private spend keys will be used for signing
        transactions. A hash of the primary signers' (the buyer and
        vendor) shared secret private key (e.g.
        $k^{sh} = \mathcal{H}_n(k^{base}_A*k^{base}_B G)$) will be used
        as the view key (e.g. $k^v = \mathcal{H}_n(k^{sh})$). We go into
        more detail on these keys later (Section
        [1.2.2](#subsec:escrowed-marketplace-escrow-user-experience){reference-type="ref"
        reference="subsec:escrowed-marketplace-escrow-user-experience"}).

2.  *Transaction building*: Assume the address owns at least one output
    already, and the key images are unknown. There are two signers, the
    initiator and the cosigner.

    1.  *Initiate a transaction*: The initiator decides to start a
        transaction. She generates opening values (e.g. $\alpha G$) for
        all owned outputs (she isn't sure which ones will get used yet),
        and commits to them. She also creates partial key images for
        those owned outputs, and signs them with a proof of legitimacy
        (recall Section
        [\[sec:recalculating-key-images-multisig\]](#sec:recalculating-key-images-multisig){reference-type="ref"
        reference="sec:recalculating-key-images-multisig"}). She sends
        that information, along with her own personal address for
        receipt of funds (e.g. for change if appropriate, etc.), to the
        cosigner.

    2.  *Make a partial transaction*: The cosigner verifies that all
        information in the initiated transaction is valid. He decides
        the output recipients and amounts (they could be partially based
        on the initiator's recommendation), inputs to be used along with
        their respective ring member decoys, and the transaction fee. He
        generates a transaction private key (or keys if there are
        subaddresses involved), creates one-time addresses, output
        commitments, encoded amounts, pseudo output commitment masks,
        and opening values for the commitments to zero. To prove amounts
        are in range, he builds the Bulletproof range proof for all
        outputs. He also generates opening values for his signature (but
        does not commit to them), random scalars for the MLSAG
        signatures, partial key images for owned outputs, and proofs of
        legitimacy for those partial images. All of this is sent to the
        initiator.

    3.  *Initiator's partial signature*: The initiator verifies the
        partial transaction's information is valid, and conforms with
        her expectations (e.g. amounts and recipients are as they should
        be). She completes the MLSAG signatures and signs them with her
        private keys, then sends the partially signed transaction to the
        cosigner along with her revealed opening values.

    4.  *Finish the transaction*: The cosigner finishes signing the
        transaction, and submits it to the network.

#### Single-commitment signing {#single-commitment-signing .unnumbered}

Unlike what is recommended in our multisig chapter, only one commitment
is provided per partial transaction (by the transaction initiator), and
it is revealed after the cosigner sends out their opening value
explicitly. The purpose of committing to opening values (e.g.
$\alpha G$) is to prevent a malicious cosigner from using their own
opening value to affect the challenge that gets produced, which could
allow him to discover other cosigners' aggregation keys (recall Section
[\[sec:threshold-schnorr\]](#sec:threshold-schnorr){reference-type="ref"
reference="sec:threshold-schnorr"}). If even one partial opening value
is unavailable when the malicious actor generates his own, then it is
impossible (or at least negligibly probable) for him to control the
challenge.[^7][^8][^9]

Simplifying in this way removes one communication round, which has
important consequences for the buyer-vendor interaction experience.

### Escrowed user experience {#subsec:escrowed-marketplace-escrow-user-experience}

Here is our detailed walk-through of buyer-vendor-moderator interactions
involving a 2-of-3 multisig-based online purchase using Monero.

1.  *Buyer makes a purchase*

    1.  *Buyer's new shopping session*: A shopper enters an online
        marketplace, and her client generates a new subaddress to be
        used if she starts a new purchase order.[^10] In that
        marketplace she finds vendors, and each vendor is offering a
        selection of products and prices. Invisible to the shopper
        herself, but visible to her client (i.e. the software she is
        using to buy things), each product has a base key for use in
        multisig-based purchases. Alongside that base key is a list of
        preselected moderators, and each such moderator has a base key
        and precomputed vendor-moderator shared secret public key.[^11]

    2.  *Buyer adds a product to cart*: Our shopper decides she wants
        something, selects the payment option (i.e. direct payment,
        1-of-2 multisig, or 2-of-3 multisig), and if she selects 2-of-3
        multisig she is presented with a list of available moderators
        that she can choose from. When she adds the product to her cart,
        her client, invisible to her (and assuming she selected 2-of-3
        multisig), uses the product's base key, the moderator's base
        key, and the vendor-moderator shared secret public key, to, in
        combination with her own shopping-session subaddress's spend key
        (as her base key), construct a 2-of-3 buyer-vendor-moderator
        multisig address.[^12]\
        The view key is a hash of the buyer-vendor shared secret private
        key (not the aggregation private key, i.e. before `premerge`),
        and the encryption key for communications between the buyer and
        vendor is a hash of the view key.[^13]

    3.  *Buyer moves to checkout*: The shopper views her cart with all
        its products, and decides to proceed to checkout. This is where
        she makes funding available before finalizing the purchase
        order. Her client constructs a transaction (but does not sign it
        yet) that will either pay directly to the vendor, or fund a
        multisig address (with a little extra for future fees). If
        funding a 2-of-3 multisig address, the client also initiates two
        transactions sending money out of that address. One can be used
        to pay the vendor, and the other to refund the buyer. Their
        inputs' partial key images are based on the funding transaction
        that has not been signed yet.\
        In reality, she only needs committed opening values for the two
        transactions, and then separately one copy of the partial key
        images (with proof of legitimacy) and one copy of her
        shopping-session subaddress. That subaddress has a dual purpose;
        it is the buyer's address for refunds or change outputs, and its
        spend key is the buyer's multisig base key.[^14]

    4.  *Buyer authorizes payment*: After looking over all the purchase
        order details, the shopper authorizes it.[^15] Her client
        finishes signing the funding transaction, and submits it to the
        network.[^16] It sends the purchase order, along with the
        funding transaction's hash and initiated multisig transactions,
        and the buyer-moderator shared secret public key, to the
        vendor.[^17]

2.  *Vendor fulfills a purchase order*

    1.  *Vendor appraises purchase order*: The vendor examines our
        shopper's purchase order, then approves it for shipping. If he
        was paid directly then there is nothing else to consider, and if
        he was paid via 1-of-2 multisig then he can make a transaction
        paying himself out of that address. For 2-of-3 multisig his
        client generates a subaddress for receipt of money in the
        purchase order, and makes two partial transactions out of the
        buyer's initialized transactions. The payment transaction sends
        the product price to the vendor, and the rest to the buyer as
        change, while the refund transaction just empties the multisig
        address back to the buyer.[^18] Note that he reconstructs the
        multisig address out of the buyer-vendor-moderator base keys in
        combination with the buyer-moderator shared secret public key.

    2.  *Vendor ships the product*: The vendor ships the product, and
        sends a fulfillment notification to the buyer. That notification
        includes a receipt for the purchase, as well as a request for
        the user to complete payment (everything from here on out refers
        to 2-of-3 multisig). Hidden to the user is the vendor's purchase
        order subaddress, which can be used in case of dispute
        resolution, and both partial transactions.

3.  *Buyer completes payment or requests a refund*: A buyer can do this
    as soon as they receive fulfillment notification, or wait until the
    product has been delivered.

    1.  *Buyer submits partially signed transaction*: The buyer decides
        whether to pay for her purchase, or request a refund. Her client
        creates a partial signature on the appropriate partial
        transaction, and sends it to the vendor. Any refund would
        presumably include an explanation justifying it.

    2.  *Vendor completes transaction*: The vendor receives a partially
        signed transaction, finishes signing it, and submits it to the
        network. If necessary he sends a refund notification, with
        proof, to the buyer.

4.  *Moderated dispute*: At any point after the buyer submits a purchase
    order and before the multisig address is emptied of funds, either
    the vendor or buyer can decide to get the moderator involved.
    Party_A is whoever raised the dispute, while Party_B is the
    defendant.[^19]

    1.  *Party_A contacts moderator*: Party_A initiates two
        transactions, for payment or refund, this time geared toward
        Party_A-moderator signing, and send them to the moderator along
        with necessary information for building the multisig address
        (the base keys, the Party_A-Party_B shared secret public key,
        and the private view key) and reading the multisig wallet's
        balance (the partial key images and their proofs).

    2.  *Moderator processes dispute*

        1.  *Moderator acknowledges dispute*: The moderator acknowledges
            they are looking into the dispute, at the same time creating
            partial transactions out of the initiated transactions and
            sending them to Party_A. They make sure to notify Party_B
            about the dispute, and also initiate two more transactions
            with Party_B to expedite failure of Party_A to comply with
            the final verdict.

        2.  *Moderator pursues a verdict*: The moderator looks at the
            available evidence, and can interact with the parties to
            gather more information. They may try to mediate the
            argument, in hopes of both parties resolving it without the
            need to pass a verdict.

        3.  *Dispute reaches an end*: Either the buyer and vendor
            resolve it on their own in the end, or the moderator passes
            a verdict which they communicate to both parties.

        -   Note: If the defendant party should receive funds per the
            verdict, but hasn't provided an address for whatever reason,
            the moderator can try to contact them and cooperate with
            them to receive those funds. Since it doesn't involve the
            disputer, that contact can be made (or pursued further)
            after the dispute has been resolved.

    3.  *Party_A or B accepts the verdict*: If no Party_A-Party_B
        transactions were finalized, it implies the dispute was resolved
        by moderator's decision.

        1.  *Party_A accepts*

            1.  Party_A completes their partial signature on the verdict
                transaction, and sends it to the moderator.

            2.  The moderator completes the signature, and submits the
                transaction.

        2.  *Party_B accepts*

            1.  Party_B creates a partial transaction for the
                moderator's initialized verdict transaction, and sends
                it to the moderator. This step can be performed before
                the verdict is finalized, in which case Party_B would
                make partial transactions for both potential verdicts.

            2.  The moderator partially signs that partial transaction,
                and sends it to Party_B.

            3.  Party_B finishes signing the transaction, and submits it
                to the network. He sends the transaction hash to the
                moderator.

    4.  *Moderator closes out the dispute*: The moderator summarizes the
        dispute and its resolution, and sends their report to the buyer
        and vendor.

There are four key design optimizations installed.

#### Preselected moderators {#preselected-moderators .unnumbered}

By choosing the moderators ahead of time, vendors can create a shared
secret with each of them for each of their products and publish its
public key with the product information.[^20] This way buyers can
construct the complete merged multisig address in one step, as soon as
they decide to purchase something, harmonizing with the requirement for
'offline selling'. Preselecting multiple moderators allows buyers to
choose the one they trust more.

Buyers may also, if they don't trust a vendor's accepted moderators,
cooperate with an online moderator of their choosing to make a multisig
address with the vendor's product base key. After receiving a purchase
order, the vendor may accept that new moderator or decline the
sale.[^21]

We expect the mutual desire of buyers and vendors for good moderators
to, over time, create a hierarchy of moderators organized by the quality
and fairness of the service they provide. Lower quality moderators or
those with less of a reputation would likely earn less money or service
fewer or less significant transactions.[^22]

#### Subaddresses and product IDs {#subaddresses-and-product-ids .unnumbered}

Vendors create a new base key for each product line/ID, and those keys
are used to construct 2-of-3 multisig addresses.[^23] When vendors
fulfill a purchase order they create a unique subaddress for receipt of
funds, which can be used to match purchase orders with payments
received.

The requirement for 'purchase order-based payments' is met efficiently
here, especially since funds directed to different subaddresses are
trivially accessible from the same wallet (recall Section
[\[sec:subaddresses\]](#sec:subaddresses){reference-type="ref"
reference="sec:subaddresses"}).

#### Anticipatory partial transactions {#anticipatory-partial-transactions .unnumbered}

Multisig transactions take multiple rounds, so we begin making them as
soon as possible. For user convenience, partial transactions that are
only rarely used (e.g. refund transactions) get made early, so they are
immediately available for signing if the need arises.

#### Conditional moderator access {#conditional-moderator-access .unnumbered}

For the sake of both efficiency and privacy, moderators only need access
to the details of a trade when settling disputes. To accomplish this, we
make the multisig private view key a hash of the buyer-vendor shared
secret private key
$k^{v,grp}_{purchase-order} = \mathcal{H}_n(T_{mv},k^{sh,\textrm{2x3}}_{AB})$
where $T_{mv}$ is the marketplace view key domain separator and A and B
correspond with vendor and buyer, and
$k^{sh,\textrm{2x3}}_{AB} = \mathcal{H}_n(k^{base}_{A}*k^{base}_{B} G)$.
We extend what it can 'view' to the buyer-vendor communication
transcript. In other words, the communication encryption key is
$k^{ce}_{purchase-order} = \mathcal{H}_n(T_{me},k^{v,grp}_{purchase-order})$
($T_{me}$ is the marketplace encryption key domain separator).[^24][^25]

Moderators gain access to the buyer-vendor communications, and the
ability to authorize payments, only when one of the original parties
releases the view key to them.[^26]

Moreover, vendors can verify the marketplace host (who may also be the
only moderator available, depending on how this concept is implemented)
is not MITM ('man in the middle') of their conversations with customers
(i.e. pretending to be the buyer or vendor) by checking that the base
keys they publish for each product match what gets displayed. Since the
buyer's base key, which gets used to create the multisig address, is
also part of the encryption key, a malicious host would have a hard time
orchestrating a MITM attack.

[^1]: René "rbrunner7\" Brunner, a Monero contributor who created the
    MMS [@mms-project-proposal; @mms-manual], investigated integrating
    Monero multisig into the decentralized cryptocurrency-based digital
    marketplace OpenBazaar <https://openbazaar.org/>. The concepts laid
    out here are inspired by the hurdles René encountered
    [@openbazaar-rbrunner-investigation] (his 'earlier analysis').

[^2]: Our initial impression is Monero's current implementation of
    multisig already has a similar transaction creation flow to what we
    need for an escrowed shopping environment, which is good news for
    potential implementation efforts. Readers should note that Monero
    multisig requires some security updates before it can see heavy use
    [@multisig-research-issue-67].

[^3]: Fulfilling a purchase order means sending the product out to be
    delivered to the purchaser.

[^4]: 1-of-2 multisig can take advantage of some concepts useful for
    2-of-3 multisig, in particular constructing the address in the first
    place.

[^5]: Extending this beyond (N-1)-of-N is likely infeasible without more
    steps, due to the additional rounds necessary for setting up a lower
    threshold multisig address.

[^6]: This procedure is actually quite similar to how Monero currently
    organizes multisig transactions.

[^7]: This is also why the initiator only reveals her opening values
    after all transaction information has been determined, so neither
    signer can alter the MLSAG message and influence the challenge.

[^8]: Single-commitment signing could be generalized as (M-1)-commitment
    signing, where only the partial transaction author does not
    commit-and-reveal and other co-signers only reveal after a
    transaction is fully determined. For example, suppose there is a
    3-of-3 address with cosigners (A,B,C), who will attempt
    single-commitment signing. Signers B and C are in a malicious
    coalition against A, while C is the initiator and B is the partial
    transaction author. C initiates with a commitment, then A provides
    his opening value (without commitment). When B constructs the
    partial transaction, he can conspire with C to control the signature
    challenge in order to expose A's private key. Please also note that
    (M-1)-commitment signing is an original concept first presented
    here, and is not backed by any advanced research material or code
    implementation. It may end up being completely erroneous.

[^9]: One way of thinking about this is to consider the meaning and
    purpose of a 'commitment' (recall Section
    [\[sec:commitments\]](#sec:commitments){reference-type="ref"
    reference="sec:commitments"}). Once Alice commits to value A she is
    stuck with it, and can't take advantage of new information from
    event B (caused by Bob) that happens later. Moreover, if A hasn't
    been revealed then B can't be influenced by it. Alice and Bob can be
    sure that A and B are independent. It is our contention that
    single-commitment signing as described meets that standard, and is
    equivalent to full-commitment signing. If the commitment $c$ is a
    one-way function of opening values $\alpha_A G$ and $\alpha_B G$
    (e.g. $c = \mathcal{H}_n(\alpha_A G,\alpha_B G)$), then if
    $\alpha_A G$ is committed to initially, $\alpha_B G$ is revealed
    after $C(\alpha_A G)$ appears, and $\alpha_A G$ is revealed after
    $\alpha_B G$ appears, then $\alpha_B G$ and $\alpha_A G$ are
    independent, and $c$ will be random from both Alice's and Bob's
    perspectives (unless they collaborate, and except with negligible
    probability).

[^10]: Using a new subaddress for each purchase order, or even a new
    subaddress for each separate vendor or vendor's product, makes it
    more difficult for vendors to track the behavior of their customers.
    It also helps make sure each purchase order is unique, in the case
    of someone buying the same thing twice.

[^11]: It would be straightforward for vendors to also include,
    invisible to shoppers, commitments to opening values for
    transactions. However, to handle multiple purchase orders for the
    same product, he would have to provide many commitments up front for
    each potential buyer. We can only imagine how messy that could
    become. This is part of the utility brought by our single-commitment
    signing simplification.

[^12]: Exactly how a marketplace should be implemented is open to
    interpretation, since for example selecting the payment type for a
    product could be presented to the user at checkout instead of in the
    'add to cart' interface.

[^13]: This same process would take place for 1-of-2 multisig, leaving
    out the moderator.

[^14]: It is important to initiate separate transactions, since
    committed opening values can only be used once.

[^15]: If the buyer cancels the purchase order, her funding transaction
    and partial multisig transactions get deleted.

[^16]: If her cart contained multiple vendors' products, then her client
    can create multiple purchase orders and handle them separately. The
    vendors can all be paid by the same funding transaction.

[^17]: The buyer's client should keep track of payment order details
    like total price, to later verify the content of multisig
    transactions before signing them.

[^18]: The partial transactions could plausibly share a lot of values
    since they involve the same inputs, and only one of them should
    ultimately get signed. For the sake of modularity and robust design
    we think it's best to handle them separately.

[^19]: Our dispute resolution design assumes actors are in good faith.
    People who are uncooperative, and for example don't initiate or sign
    transactions that don't favor themselves, will no doubt make the
    process much more tedious for everyone.

[^20]: Importantly, these multisig addresses are still resistant to key
    aggregation tests since the buyer's shared secrets are unknown to
    observers.

[^21]: For expediency, an escrow service could be 'always online', and
    instead of using preselected moderators all 2-of-3 multisig
    addresses are actively constructed with that service when a purchase
    order is made. Another possibility is using nested multisig (Section
    [\[sec:general-key-families\]](#sec:general-key-families){reference-type="ref"
    reference="sec:general-key-families"}), where the preselected
    moderator is actually a 1-of-N multisig group. That way whenever a
    dispute arises any moderator from that group who happens to be
    available can step in. It would likely require substantial
    development effort to implement.

[^22]: It is not clear to us the best, or most likely, funding method
    for moderators. Perhaps they would get paid a flat or percentage fee
    of each moderated transaction or transaction where they are added as
    a moderator (and then if the fee wasn't provided in the original
    partial transactions, refuse to cooperate in a dispute), or users
    and/or vendors and/or marketplace platforms would contract with
    them.

[^23]: This base key is also used for 1-of-2 multisig purchasing. We
    feel it is important not to expose the private spend key in the
    communication channel, so using a buyer-vendor shared secret makes a
    lot of sense.

[^24]: Separating the view key and encryption key allows handing out
    just view rights to the communication log without view rights to the
    multisig address's transaction history.

[^25]: This method is also used for 1-of-2 multisig addresses.

[^26]: It is important for moderators to verify the communication log
    they receive hasn't been tampered with. One way might be for each
    cosigner to include a signed hash of the current message log
    whenever they send out a new message. Moderators can look at the
    back-and-forth, and series of hashed logs, to identify
    discrepancies. It would also help cosigners identify messages that
    failed to transmit, and alternatively create evidence that
    particular signers did in fact receive certain messages.
