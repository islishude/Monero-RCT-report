# Introduction {#chapter:introduction}

In the digital realm it is often trivial to make endless copies of
information, with equally endless alterations. For a currency to exist
digitally and be widely adopted, its users must believe its supply is
strictly limited. A money recipient must trust they are not receiving
counterfeit coins, or coins that have already been sent to someone else.
To accomplish that without requiring the collaboration of any third
party like a central authority, its supply and complete transaction
history must be publicly verifiable.

We can use cryptographic tools to allow data registered in an easily
accessible database - the blockchain - to be virtually immutable and
unforgeable, with legitimacy that cannot be disputed by any party.\
Cryptocurrencies store transactions in the blockchain, which acts as a
public ledger[^1] of all the currency operations. Most cryptocurrencies
store transactions in clear text, to facilitate verification of
transactions by the community of users.\
Clearly, an open blockchain defies any basic understanding of privacy or
fungibility[^2], since it literally *publicizes* the complete
transaction histories of its users.\
To address the lack of privacy, users of cryptocurrencies such as
Bitcoin can obfuscate transactions by using temporary intermediate
addresses [@DBLP:journals/corr/NarayananM17]. However, with appropriate
tools it is possible to analyze flows and to a large extent link true
senders with receivers
[@DBLP:journals/corr/ShenTuY15b; @DK-police-tracing-btc; @Andrew-Cox-Sandia; @chainalysis-2020-report].

In contrast, the cryptocurrency Monero (Moe-neh-row) attempts to tackle
the issue of privacy by storing only single-use addresses for receipt of
funds in the blockchain, and by authenticating the dispersal of funds in
each transaction with ring signatures. With these methods there are no
known generally effective ways to link receivers or trace the origin of
funds.[^3]

Additionally, transaction amounts in the Monero blockchain are concealed
behind cryptographic constructions, rendering currency flows opaque.

The result is a cryptocurrency with a high level of privacy and
fungibility.

## Objectives {#sec:goals}

Monero is an established cryptocurrency with over five years of
development [@bitmonero-launched; @monero-history], and maintains a
steadily increasing level of adoption
[@justin-defcon-2019-community-growth].[^4] Unfortunately, there is
little comprehensive documentation describing the mechanisms it
uses.[^5][^6] Even worse, essential parts of its theoretical framework
have been published in non-peer-reviewed papers that are incomplete or
contain errors. For significant parts of the theoretical framework of
Monero, only the source code is reliable as a source of information.[^7]

Moreover, for those without a background in mathematics, learning the
basics of elliptic curve cryptography, which Monero uses extensively,
can be a haphazard and frustrating endeavor.[^8]

We intend to palliate this situation by introducing the fundamental
concepts necessary to understand elliptic curve cryptography, reviewing
algorithms and cryptographic schemes, and collecting in-depth
information about Monero's inner workings.

To provide the best experience for our readers, we have taken care to
build a constructive, step-by-step description of the Monero
cryptocurrency.

In the second edition of this report we have centered our attention on
version 12 of the Monero protocol[^9], corresponding to version 0.15.x.x
of the Monero software suite. All transaction and blockchain-related
mechanisms described here belong to those versions.[^10][^11] Deprecated
transaction schemes have not been explored to any extent, even if they
may be partially supported for backward compatibility. Likewise with
deprecated blockchain features. The first edition [@ztm-1] corresponded
to version 7 of the protocol, and version 0.12.x.x of the software
suite.

## Readership

We anticipate many readers will encounter this report with little to no
understanding of discrete mathematics, algebraic structures,
cryptography[^12], and blockchains. We have tried to be thorough enough
that laypeople from all perspectives may learn Monero without needing
external research.

We have purposefully omitted, or delegated to footnotes, some
mathematical technicalities, when they would be in the way of clarity.
We have also omitted concrete implementation details where we thought
they were not essential. Our objective has been to present the subject
half-way between mathematical cryptography and computer programming,
aiming at completeness and conceptual clarity.[^13]

## Origins of the Monero cryptocurrency

The cryptocurrency Monero, initially known as BitMonero, was created in
April 2014 as a derivative of the proof-of-concept currency CryptoNote
[@bitmonero-launched]. Monero means 'money' in the language Esperanto,
and its plural form is Moneroj (Moe-neh-rowje, similar to Moneros but
using the -ge from orange).

CryptoNote is a cryptocurrency devised by various individuals. A
landmark whitepaper describing it was published under the pseudonym of
Nicolas van Saberhagen in October 2013 [@cryptoNoteWhitePaper]. It
offered receiver anonymity through the use of one-time addresses, and
sender ambiguity by means of ring signatures.

Since its inception, Monero has further strengthened its privacy aspects
by implementing amount hiding, as described by Greg Maxwell (among
others) in [@Signatures2015BorromeanRS] and integrated into ring
signatures based on Shen Noether's recommendations in
[@MRL-0005-ringct], then made more efficient with Bulletproofs
[@Bulletproofs_paper].

## Outline

As mentioned, our aim is to deliver a self-contained and step-by-step
description of the Monero cryptocurrency. Zero to Monero has been
structured to fulfill this objective, leading the reader through all
parts of the currency's inner workings.

### Part 1: 'Essentials'

In our quest for comprehensiveness, we have chosen to present all the
basic elements of cryptography needed to understand the complexities of
Monero, and their mathematical antecedents. In Chapter
[\[chapter:basicConcepts\]](#chapter:basicConcepts){reference-type="ref"
reference="chapter:basicConcepts"} we develop essential aspects of
elliptic curve cryptography.

Chapter
[\[chapter:advanced-schnorr\]](#chapter:advanced-schnorr){reference-type="ref"
reference="chapter:advanced-schnorr"} expands on the Schnorr signature
scheme from the prior chapter, and outlines the ring signature
algorithms that will be applied to achieve confidential transactions.

Chapter [\[chapter:addresses\]](#chapter:addresses){reference-type="ref"
reference="chapter:addresses"} explores how Monero uses addresses to
control ownership of funds, and the different kinds of addresses.

In Chapter
[\[chapter:pedersen-commitments\]](#chapter:pedersen-commitments){reference-type="ref"
reference="chapter:pedersen-commitments"} we introduce the cryptographic
mechanisms used to conceal amounts.

With all the components in place, we explain the transaction scheme used
in Monero in Chapter
[\[chapter:transactions\]](#chapter:transactions){reference-type="ref"
reference="chapter:transactions"}.

The Monero blockchain is unfolded in Chapter
[\[chapter:blockchain\]](#chapter:blockchain){reference-type="ref"
reference="chapter:blockchain"}.

### Part 2: 'Extensions'

A cryptocurrency is more than just its protocol, and in 'Extensions' we
talk about a number of different ideas, many of which have not been
implemented.[^14]

Various information about a transaction can be proven to observers, and
those methods are the content of Chapter
[\[chapter:tx-knowledge-proofs\]](#chapter:tx-knowledge-proofs){reference-type="ref"
reference="chapter:tx-knowledge-proofs"}.

While not essential to the operation of Monero, there is a lot of
utility in multisignatures that allow multiple people to send and
receive money collaboratively. Chapter
[\[chapter:multisignatures\]](#chapter:multisignatures){reference-type="ref"
reference="chapter:multisignatures"} describes Monero's current
multisignature approach and outlines possible future developments in
that area.

Of extreme importance is applying multisig to the interactions of
vendors and shoppers in online marketplaces. Chapter
[\[chapter:escrowed-market\]](#chapter:escrowed-market){reference-type="ref"
reference="chapter:escrowed-market"} constitutes our original design of
an escrowed marketplace using Monero multisig.

First presented here, TxTangle, outlined in Chapter
[\[chapter:txtangle\]](#chapter:txtangle){reference-type="ref"
reference="chapter:txtangle"}, is a decentralized protocol for joining
the transactions of multiple individuals into one.

### Additional content

Appendix
[\[appendix:RCTTypeBulletproof2\]](#appendix:RCTTypeBulletproof2){reference-type="ref"
reference="appendix:RCTTypeBulletproof2"} explains the structure of a
sample transaction from the blockchain. Appendix
[\[appendix:block-content\]](#appendix:block-content){reference-type="ref"
reference="appendix:block-content"} explains the structure of blocks
(including block headers and miner transactions) in Monero's blockchain.
Finally, Appendix
[\[appendix:genesis-block\]](#appendix:genesis-block){reference-type="ref"
reference="appendix:genesis-block"} brings our report to a close by
explaining the structure of Monero's genesis block. These provide a
connection between the theoretical elements described in earlier
sections with their real-life implementation.

We use margin notes to indicate where Monero implementation details can
be found in the source code.[^15] There is usually a file path, such as
src/ringct/rctOps.cpp, and a function, such as
$\textrm{{\tt ecdhEncode()}}$. Note: '-' indicates split text, such as
crypto- note $\rightarrow$ cryptonote, and we neglect namespace
qualifiers (e.g. `Blockchain::`) in most cases.

## Disclaimer

All signature schemes, applications of elliptic curves, and Monero
implementation details should be considered descriptive only. Readers
considering serious practical applications (as opposed to a hobbyist's
explorations) should consult primary sources and technical
specifications (which we have cited where possible). Signature schemes
need well-vetted security proofs, and Monero implementation details can
be found in Monero's source code. In particular, as a common saying
goes, 'don't roll your own crypto'. Code implementing cryptographic
primitives should be well-reviewed by experts and have a long history of
dependable performance. Moreover, original contributions in this
document may not be well-reviewed and are likely untested, so readers
should exercise their judgement when reading them.

## History of Zero to Monero

Zero to Monero is an expansion of Kurt Alonso's master's thesis, 'Monero
- Privacy in the Blockchain' [@kurt-original], published in May 2018.
The first edition was published in June 2018 [@ztm-1].

For the second edition we have improved how ring signatures are
introduced (Chapter
[\[chapter:advanced-schnorr\]](#chapter:advanced-schnorr){reference-type="ref"
reference="chapter:advanced-schnorr"}), reorganized how transactions are
explained (added Chapter
[\[chapter:addresses\]](#chapter:addresses){reference-type="ref"
reference="chapter:addresses"} on Monero Addresses), modernized the
method used to communicate output amounts (Section
[\[sec:pedersen_monero\]](#sec:pedersen_monero){reference-type="ref"
reference="sec:pedersen_monero"}), replaced Borromean ring signatures
with Bulletproofs (Section
[\[sec:range_proofs\]](#sec:range_proofs){reference-type="ref"
reference="sec:range_proofs"}), deprecated `RCTTypeFull` (Chapter
[\[chapter:transactions\]](#chapter:transactions){reference-type="ref"
reference="chapter:transactions"}), updated and elaborated Monero's
dynamic block weight and fee system (Chapter
[\[chapter:blockchain\]](#chapter:blockchain){reference-type="ref"
reference="chapter:blockchain"}), investigated transaction-related
proofs (Chapter
[\[chapter:tx-knowledge-proofs\]](#chapter:tx-knowledge-proofs){reference-type="ref"
reference="chapter:tx-knowledge-proofs"}), described Monero
multisignatures (Chapter
[\[chapter:multisignatures\]](#chapter:multisignatures){reference-type="ref"
reference="chapter:multisignatures"}), designed solutions for escrowed
marketplaces (Chapter
[\[chapter:escrowed-market\]](#chapter:escrowed-market){reference-type="ref"
reference="chapter:escrowed-market"}), proposed a new decentralized
joint transaction protocol named TxTangle (Chapter
[\[chapter:txtangle\]](#chapter:txtangle){reference-type="ref"
reference="chapter:txtangle"}), updated or added various minor details
to align with the most current protocol (v12) and Monero software suite
(v0.15.x.x), and scoured the document for quality-of-reading edits.[^16]

## Acknowledgements {#sec:acknowledgements}

Written by author 'koe'.

This report would not exist without Kurt's original master's thesis
[@kurt-original], so to him I owe a great debt of gratitude. Monero
Research Lab (MRL) researchers Brandon "Surae Noether\" Goodell and
pseudonymous 'Sarang Noether' (who collaborated with me on Section
[\[sec:range_proofs\]](#sec:range_proofs){reference-type="ref"
reference="sec:range_proofs"} and Chapter
[\[chapter:tx-knowledge-proofs\]](#chapter:tx-knowledge-proofs){reference-type="ref"
reference="chapter:tx-knowledge-proofs"}) have been a reliable and
knowledgeable resource throughout both editions of Zero to Monero's
development. Pseudonymous 'moneromooo', the Monero Project's most
prolific core developer, has probably the most extensive understanding
of the codebase on this planet, and has pointed me in the right
direction numerous times. And of course, many other wonderful Monero
contributors have spent time answering my endless questions. Finally, to
the various individuals who contacted us with proofreading feedback, and
encouraging comments, thank you!

[^1]: In this context ledger just means a record of all currency
    creation and exchange events. Specifically, how much money was
    transferred in each event and to whom.

[^2]: "**Fungible** means capable of mutual substitution in use or
    satisfaction of a contract. \... Examples: \... money,
    etc.\"[@mises-org-fungible] In an open blockchain such as Bitcoin,
    the coins owned by Alice can be differentiated from those owned by
    Bob based on the 'transaction history' of those coins. If Alice's
    transaction history includes transactions related to supposedly
    nefarious actors, then her coins might be 'tainted'
    [@bitcoin-big-bang-taint], and hence less valuable than Bob's (even
    if they own the same amount of coins). Reputable figures claim that
    newly minted Bitcoins trade at a premium over used coins, since they
    don't have a history [@new-bitcoin-premium].

[^3]: Depending on the behavior of users, there may be cases where
    transactions can be analyzed to some extent. For an example see this
    article: [@monero-ring-heuristics-ryo].

[^4]: [\[marketcap_note\]]{#marketcap_note label="marketcap_note"}In
    terms of market capitalization, Monero has been steady relative to
    other cryptocurrencies. It was 14as of June 14, 2018, and 12on
    January 5, 2020; see <https://coinmarketcap.com/>.

[^5]: One documentation effort, at <https://monerodocs.org/>, has some
    helpful entries, especially related to the Command Line Interface.
    The CLI is a Monero wallet accessible through a console/terminal. It
    has the most functionality out of all Monero wallets, at the expense
    of no user-friendly graphical interface.

[^6]: Another, more general, documentation effort called Mastering
    Monero can be found here: [@mastering-monero].

[^7]: Mr. Seguias has created the excellent Monero Building Blocks
    series [@monero-building-blocks], which contains a thorough
    treatment of the cryptographic security proofs used to justify
    Monero's signature schemes. As with Zero to Monero: First Edition
    [@ztm-1], Seguias's series is focused on v7 of the protocol.

[^8]: A previous attempt to explain how Monero works
    [@MRL-0003-about-monero] did not elucidate elliptic curve
    cryptography, was incomplete, and is now over five years outdated.

[^9]: The 'protocol' is the set of rules that each new block is tested
    against before it can be added to the blockchain. This set of rules
    includes the 'transaction protocol' (currently version 2, RingCT),
    which are general rules pertaining to how a transaction is
    constructed. Specific transaction rules can, and do, change, without
    the transaction protocol's version changing. Only large-scale
    changes to the transaction structure warrant moving its version
    number.

[^10]: The Monero codebase's integrity and reliability is predicated on
    assuming enough people have reviewed it to catch most or all
    significant errors. We hope that readers will not take our
    explanations for granted, and verify for themselves the code does
    what it's supposed to. If it doesn't, we hope you will make a
    responsible disclosure (<https://hackerone.com/monero>) for major
    problems, or Github pull request
    (<https://github.com/monero-project/monero>) for minor issues.

[^11]: Several protocols worth considering for the next generation of
    Monero transactions are undergoing research and investigation,
    including Triptych [@triptych-preprint], RingCT3.0
    [@ringct3-preprint], Omniring [@omniring-paper], and Lelantus
    [@lelantus-preprint].

[^12]: An extensive textbook on applied cryptography can be found here:
    [@applied-cryptography-textbook].

[^13]: Some footnotes, especially in chapters related to the protocol,
    spoil future chapters or sections. These are intended to make more
    sense on a second read-through, since they usually involve specific
    implementation details that are only useful to those who have a
    grasp of how Monero works.

[^14]: Please note that future protocol versions of Monero, especially
    those implementing new transaction protocols, may make any or all of
    these ideas impossible or impractical.

[^15]: Our margin notes are accurate for version 0.15.x.x of the Monero
    software suite, but may gradually become inaccurate as the codebase
    is constantly changing. However, the code is stored in a git
    repository (<https://github.com/monero-project/monero>), so a
    complete history of changes is available.

[^16]: The LaTeX source code for both editions of Zero to Monero can be
    found here (the first edition is in branch 'ztm1'):
    <https://github.com/UkoeHB/Monero-RCT-report>.
