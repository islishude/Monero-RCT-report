# The Monero Blockchain {#chapter:blockchain}

The Internet Age has brought a new dimension to the human experience. We
can correspond with people on every corner of the planet, and an
unimaginable wealth of information is at our fingertips. Exchanging
goods and services is fundamental to a peaceful and prosperous society
[@human-action], and in the digital realm we can offer our productivity
to the whole world.

Media of exchange (moneys) are essential, giving us a point of reference
to an immense diversity of economic goods that would otherwise be
impossible to evaluate, and enabling mutually beneficial interactions
between people with nothing in common [@human-action]. Throughout
history there have been many kinds of money, from seashells to paper to
gold. Those were exchanged by hand, and now money can be exchanged
electronically.

In the current, by far most pervasive, model, electronic transactions
are handled by third-party financial institutions. These institutions
are given custody of money and trusted to transfer it upon request. Such
institutions must mediate disputes, their payments are reversible, and
they can be censored or controlled by powerful organizations.
[@Nakamoto_bitcoin]

To alleviate these drawbacks decentralized digital currencies have been
engineered.[^1]

## Digital currency {#sec:digital-currency}

Designing a digital currency is non-trivial. There are three types:
personal, centralized, or distributed. Keep in mind that a digital
currency is just a collection of messages, and the 'amounts' recorded in
those messages are interpreted as monetary quantities.

In the **email model** anyone can make coins (e.g. a message saying 'I
own 5 coins'), and anyone can send their coins over and over to whoever
has an email address. It does not have a limited supply, nor does it
prevent spending the same coins over and over (double spending).

In the **video game model**, where the entire currency is
stored/recorded on one central database, users rely on the custodian to
be honest. The currency's supply is unverifiable for observers, and the
custodian can change the rules at any time, or be censored by powerful
outsiders.

### Distributed/shared version of events {#subsec:shared-version-events}

In digital 'shared' money, many computers each have a record of every
currency transaction. When a new transaction is made on one computer it
is broadcast to the other computers, and accepted if it follows
predefined rules.

Users only benefit from coins when other users accept them in exchange,
and users only accept coins they feel are legitimate. To maximize the
utility of their coins, users are naturally inclined to settle on one
commonly accepted rule-set, without the presence of a central
authority.[^2]

-   **Rule 1**: Money can only be created in clearly defined scenarios.

-   **Rule 2**: Transactions spend money that already exists.

-   **Rule 3**: A person can only spend a piece of money once.

-   **Rule 4**: Only the person who owns a piece of money can spend it.

-   **Rule 5**: Transactions output money equal to the money spent.

-   **Rule 6**: Transactions are formatted correctly.

Rules 2-6 are covered by the transaction scheme discussed in Chapter
[\[chapter:transactions\]](#chapter:transactions){reference-type="ref"
reference="chapter:transactions"}, which adds the fungibility and
privacy-related benefits of ambiguous signing, anonymous receipt of
funds, and unreadable amount transfers. We explain Rule 1 later in this
chapter.[^3] Transactions use cryptography, so we call their content a
*cryptocurrency*.

If two computers receive different legitimate transactions spending the
same money before they have a chance to send the information to each
other, how do they decide which is correct? There is a 'fork' in the
currency, because two different copies that follow the same rules exist.

Clearly the earliest legitimate transaction spending a piece of money
should be canonical. This is easier said than done. As we will see,
obtaining consensus for transaction histories constitutes the raison
d'être of blockchain technology.

### Simple blockchain {#subsec:simple-blockchain}

First we need all computers, henceforth referred to as *nodes*, to agree
on the order of transactions.

Let's say a currency started with a 'genesis' declaration: "Let the
SampleCoin begin!\". We call this message a 'block', and its block hash
is
$$\mathit{BH}_G = \mathcal{H}(\textrm{``Let the SampleCoin begin!"})$$

Every time a node receives some transactions, they use hashes of those
transactions, $\mathit{TH}$, like messages, along with the previous
block's hash, and compute new block hashes
$$\mathit{BH}_1 = \mathcal{H}(\mathit{BH}_G, \mathit{TH}_1, \mathit{TH}_2,...)$$
$$\mathit{BH}_2 = \mathcal{H}(\mathit{BH}_1, \mathit{TH}_3, \mathit{TH}_4,...)$$

And so on, publishing each new block of messages as it's made. Each new
block references the previous, most recently published block. In this
way a clear order of events extends/chains all the way back to the
genesis message. We have a very simple 'blockchain'.[^4]

Nodes can include a timestamp in their blocks to aid record keeping. If
most nodes are honest with timestamps then the blockchain provides a
decent picture of when each transaction was recorded.

If different blocks referencing the same previous block are published at
the same time, then the network of nodes will fork as each node receives
one of the new blocks before the other (for simplicity, imagine about
half the nodes end up with each side of the fork).

## Difficulty {#sec:difficulty}

If nodes can publish new blocks whenever they want, the network might
fracture and diverge into many different, equally legitimate, chains.
Say it takes 30 seconds to make sure everyone in the network gets a new
block. What if new blocks are sent out every 31, 15 seconds, 10 seconds,
etc?

We can control how fast the entire network makes new blocks. If the time
it takes to make a new block is much higher than the time for the
previous block to reach most nodes, the network will tend to remain
intact.

### Mining a block

The output of a cryptographic hash function is uniformly distributed and
apparently independent of the input. This means, given a potential
input, its hash is equally likely to be every single possible output.
Furthermore, it takes a certain amount of time to compute a single hash.

Let's imagine a hash function $\mathcal{H}_i(x)$ which outputs a number
from 1 to 100: $\mathcal{H}_i(x) \in^D_R \{1,...,100\}$.[^5] Given some
$x$, $\mathcal{H}_i(x)$ selects the same 'random' number from
{$1,...,100$} every time you calculate it. It takes 1 minute to
calculate $\mathcal{H}_i(x)$.

Say we are given a message $\mathfrak{m}$, and told to find a 'nonce'
$n$ (some integer) such that $\mathcal{H}_i(\mathfrak{m},n)$ outputs a
number less than or equal to the *target* $t = 5$ (i.e.
$\mathcal{H}_i(\mathfrak{m},n) \in \{1,...,5\}$).

Since only $1/20$of outputs from $\mathcal{H}_i(x)$ will meet the
target, it should take around 20 guesses of $n$ to find one that works
(and hence 20 minutes of computing time).

Searching for a useful nonce is called *mining*, and publishing the
message with its nonce is a *proof of work* because it proves we found a
useful nonce (even if we were lucky and found it with just one hash, or
even blindly published a good nonce), which anyone can verify by
computing $\mathcal{H}_i(\mathfrak{m},n)$.

Now say we have a hash function for generating proofs of work,
$\mathcal{H}_{PoW} \in^D_R \{0,...,m\}$, where $m$ is its maximum
possible output. Given a message $\mathfrak{m}$ (a block of
information), a nonce $n$ to mine, and a target $t$, we can define the
expected average number of hashes, the *difficulty* $d$, like this:
$d = m/t$. If $\mathcal{H}_{PoW}(\mathfrak{m},n)*d \leq m$, then
$\mathcal{H}_{PoW}(\mathfrak{m},n) \leq t$ and $n$ is acceptable.[^6]

With smaller targets the difficulty rises and it takes a computer more
and more hashes, and therefore longer and longer periods of time, to
find useful nonces.[^7]

### Mining speed

Assume all nodes are mining at the same time, but quit on their
'current' block when they receive a new one from the network. They
immediately start mining a fresh block that references the new one.

Suppose we collect a bunch $b$ of recent blocks from the blockchain
(say, with index $u \in \{1,...,b\}$) which each had a difficulty $d_u$.
For now, assume the nodes who mined them were honest, so each block
timestamp ${TS}_u$ is accurate.[^8] The total time between the earliest
block and most recent block is $\mathit{totalTime} = {TS}_b - {TS}_1$.
The approximate number of hashes it took to mine all the blocks is
$\mathit{totalDifficulty} = \sum_u d_u$.

Now we can guess how fast the network, with all its nodes, can compute
hashes. If the actual speed didn't change much while the bunch of blocks
was being produced, it should be effectively[^9]
$$\mathit{hashSpeed} \approx \mathit{totalDifficulty}/\mathit{totalTime}$$

If we want to set the target time to mine new blocks so blocks are
produced at a rate\
$\textrm{(one block)/(target time)}$, then we calculate how many hashes
it should take for the network to spend that amount of time mining.
Note: we round up so the difficulty never equals zero.
$$\mathit{newDifficulty} = \mathit{hashSpeed}*\mathit{targetTime}$$

There is no guarantee the next block will take $\mathit{newDifficulty}$
amount of total network hashes to mine, but over time and many blocks
and constantly re-calibrating, the difficulty will track with the
network's real hash speed and blocks will tend to take
$\mathit{targetTime}$.[^10]

### Consensus: largest cumulative difficulty

Now we can resolve conflicts between chain forks.

By convention, the chain with highest cumulative difficulty (from all
blocks in the chain), and therefore with most work (network hashes)
spent constructing, is considered the real, legitimate version. If a
chain splits and each fork has the same cumulative difficulty, nodes
continue mining on the branch they received first. When one branch gets
ahead of the other they discard ('orphan') the weaker branch.

If nodes wish to change or upgrade the basic protocol, i.e. the set of
rules a node considers when deciding if a blockchain copy or new block
is legitimate, they may easily do so by forking the chain. Whether the
new branch has any impact on users depends on how many nodes switch and
how much software infrastructure is modified.[^11]

For an attacker to convince honest nodes to alter the transaction
history, perhaps in order to respend/unspend funds, he must create a
chain fork (on the current protocol) with higher total difficulty than
the main chain (which meanwhile continues to grow). This is very hard to
do unless you control over 50% of the network hash speed and can outwork
other miners. [@Nakamoto_bitcoin]

### Mining in Monero

To make sure chain forks are on an even footing, we don't sample the
most recent blocks (for calculating new difficulties), instead lagging
our bunch $b$ by $l$. For example, if there are 29 blocks in the chain
(blocks $1,...,29$), $b = 10$, and $l = 5$, we sample blocks 15-24 in
order to compute block 30's difficulty.

If mining nodes are dishonest they can manipulate timestamps so new
difficulties don't match the network's real hash speed. We get around
this by sorting timestamps chronologically, then chopping off the first
$o$ outliers and last $o$ outliers. Now we have a 'window' of blocks
$w = b-2*o$. From the previous example, if $o = 3$ and timestamps are
honest then we would chop blocks 15-17 and 22-24, leaving blocks 18-21
to compute block 30's difficulty from.

Before chopping outliers we sorted timestamps, but *only* timestamps.
Block difficulties are left unsorted. We use the cumulative difficulty
for each block, which is that block's difficulty plus the difficulty of
all previous blocks in the chain.

Using\[-1.8cm\] the chopped arrays of $w$ sorted timestamps and unsorted
cumulative difficulties (indexed from $1,...,w$), we define
$$\mathit{totalTime} = \mathit{choppedSortedTimestamps}[w] - \mathit{choppedSortedTimestamps}[1]$$
$$\mathit{totalDifficulty} = \mathit{choppedCumulativeDifficulties}[w] - \mathit{choppedCumulativeDifficulties}[1]$$

In Monero the target time is 120 seconds (2 minutes), $l = 15$ (30
mins), $b = 720$ (one day), and $o = 60$ (2 hours).[^12][^13]

Block difficulties are not stored in the blockchain, so someone
downloading a copy of the blockchain and verifying all blocks are
legitimate needs to recalculate difficulties from recorded timestamps.
There are a few rules to consider for the first $b+l = 735$ blocks.

-   **Rule 1**: Ignore the genesis block (block 0, with $d = 1$)
    completely. Blocks 1 and 2 have $d = 1$.

-   **Rule 2**: Before chopping off outliers, try to get the window $w$
    to compute totals from.

-   **Rule 3**: After $w$ blocks, chop off high and low outliers,
    scaling the amount chopped until $b$ blocks. If the amount of
    previous blocks (minus $w$) is odd, remove one more low outlier than
    high.

-   **Rule 4**: After $b$ blocks, sample the earliest $b$ blocks until
    $b+l$ blocks, after which everything proceeds normally - lagging by
    $l$.

### Monero proof of work (PoW) {#monero-proof-of-work-pow .unnumbered}

Monero has used a few different proof of work hash algorithms (with 32
byte outputs) in different protocol versions. The original, known as
Cryptonight, was designed to be relatively inefficient on GPU, FPGA, and
ASIC architectures [@CryptoNight] compared to standard hash functions
like SHA256. In April 2018 (v7 of the protocol), new blocks were
required to begin using a slightly modified variant that countered the
advent of Cryptonight ASICs [@cryptonight7]. Another slight variant,
named Cryptonight V2, was implemented in October 2018 (v8)
[@berylliumbullet-v8], and Cryptonight-R (based on Cryptonight but with
more substantial changes than just a tweak) started being used for new
blocks in March 2019 (v10) [@boronbutterfly-v10]. A radical new proof of
work called RandomX [@randomx-pr-5549] was designed and made mandatory
for new blocks in November 2019 (v12) with the intention of long-term
ASIC resistance [@randomx].

## Money supply {#sec:money-supply}

There are two basic mechanisms for creating money in a blockchain-based
cryptocurrency.

First, the currency's creators can conjure coins and distribute them to
people in the genesis message. This is often called an 'airdrop'.
Sometimes creators give themselves a large amount in a so-called
'pre-mine'. [@premine-description]

Second, the currency can be automatically distributed as reward for
mining a block, much like mining for gold. There are two types here. In
the Bitcoin model the total possible supply is capped. Block rewards
slowly decline to zero, after which no more money is ever made. In the
inflation model supply increases indefinitely.

Monero is based on a currency known as Bytecoin that had a sizeable
pre-mine, followed by block rewards [@monero-history]. Monero had no
pre-mine, and as we will see, its block rewards slowly decline to a
small amount after which all new blocks reward that same amount, making
Monero inflationary.

### Block reward {#subsec:block-reward}

Block miners, before mining for a nonce, make a 'miner transaction' with
no inputs and at least one output.[^14] The total output amount is equal
to the block reward, plus transaction fees from all transactions to be
included in the block, and is communicated in clear text. Nodes who
receive a mined block must verify the block reward is correct, and can
calculate the current money supply by summing all past block rewards
together.

Besides distributing money, block rewards incentivize mining. If there
were no block rewards (and no other mechanism), why would anyone mine
new blocks? Perhaps altruism or curiosity. However, few miners makes it
easy for a malicious actor to assemble $>$50% of the network's hash rate
and easily rewrite recent chain history.[^15] This is also why in Monero
block rewards do not fall all the way to zero.

With block rewards, competition between miners drives total hash rate up
until the marginal cost of adding more hash rate is higher than the
marginal reward of obtaining that proportion of mined blocks (which
appear at a constant rate) (plus some premiums like risk and opportunity
cost). This means as a cryptocurrency becomes more valuable, its total
hash rate will increase and it becomes progressively more difficult and
expensive to gather $>$50%.

#### Bit shifting {#bit-shifting .unnumbered}

Bit shifting is used for calculating the base block reward (as we will
see in Section [1.3.3](#subsec:penalty){reference-type="ref"
reference="subsec:penalty"}, the actual block reward can sometimes be
reduced below the base amount).

Suppose we have an integer A = 13 with bit representation \[1101\]. If
we shift the bits of A down by 2 using the bitwise shift right operator,
denoted A $>>$ 2, we get \[0011\].01, which equals 3.25. In reality that
last part gets thrown away - 'shifted' into oblivion, leaving us with
\[0011\] = 3.[^16]

#### Calculating base block reward for Monero {#calculating-base-block-reward-for-monero .unnumbered}

Let's call the current total money supply M, and the 'limit' of the
money supply L = $2^{64} - 1$ (in binary it is \[11\....11\], with 64
bits).[^17] In the beginning of Monero the base block reward was
$\textrm{B = (L-M) $>>$ 20}$. If M = 0, then, in decimal format,
$$\textrm{L} = 18,446,744,073,709,551,615$$
$$\textrm{B}_0 = (L-0) >> 20 = 17,592,186,044,415$$

These numbers are in 'atomic units' - 1 atomic unit of Monero can't be
divided. Clearly atomic units are ridiculous - L is over 18 quintillion!
We can divide everything by $10^{12}$ to move the decimal point over,
giving us the standard units of Monero (a.k.a. XMR, Monero's so-called
'stock ticker').
$$\frac{\textrm{L}}{10^{12}} = 18,446,744.073709551615$$
$$\textrm{B}_0 = \frac{(L-0) >> 20}{10^{12}} = 17.592186044415$$

And there it is, the very first block reward, dispersed to pseudonymous
thankful_for_today (who was responsible for starting the Monero project)
in Monero's genesis block [@bitmonero-launched], was about 17.6 Moneroj!
See Appendix
[\[appendix:genesis-block\]](#appendix:genesis-block){reference-type="ref"
reference="appendix:genesis-block"} to confirm this for yourself.[^18]

As blocks are mined M grows, lowering subsequent block rewards.
Initially (since the genesis block in April 2014) Monero blocks were
mined once per minute, but in March 2016, it became two minutes per
block [@monero-0.9.3]. To keep the rate of money creation, i.e. the
'emission schedule',[^19] the same, block rewards were doubled. This
just means, after the change, we use (L-M) $>>$ 19 instead of $>>$ 20
for new blocks. Currently the base block reward is
$$\textrm{B} = \frac{(L-M) >> 19}{10^{12}}$$

### Dynamic block weight {#subsec:dynamic-block-weight}

It would be nice to mine every new transaction into a block right away.
What if someone submits a lot of transactions maliciously? The
blockchain, storing every transaction, would quickly grow enormous.

One mitigation is a fixed block size (in bytes), so the number of
transactions per block is limited. What if honest transaction volume
rises? Each transaction author would bid for a spot in new blocks by
offering fees to miners. Miners would focus on mining transactions with
the highest fees. As transaction volume increases, fees would become
prohibitively large for transactions of small amounts (such as Alice
buying an apple from Bob). Only people willing to outbid everyone else
would get their transactions into the blockchain.[^20]\
Monero avoids those extremes (unlimited vs fixed) with a dynamic block
weight.

#### Size vs Weight {#size-vs-weight .unnumbered}

Since Bulletproofs were added (v8), transaction and block sizes are no
longer considered strictly. The term used now is *transaction weight*.
Transaction weight for a miner transaction (see Section
[1.3.6](#subsec:miner-transaction){reference-type="ref"
reference="subsec:miner-transaction"}), or a normal transaction with two
outputs, is equal to the size in bytes. When a normal transaction has
more than two outputs the weight is somewhat higher than the size.

Recalling Section
[\[sec:range_proofs\]](#sec:range_proofs){reference-type="ref"
reference="sec:range_proofs"}, a Bulletproof occupies
$(2 \cdot \lceil \textrm{log}_2(64 \cdot p) \rceil + 9) \cdot 32$ bytes,
so as more outputs are added the additional storage for range proofs is
sub-linear. However, Bulletproof verification is linear, so artificially
increasing transaction weights 'prices in' that extra verification time
(it's called a 'clawback').

Suppose we have a transaction with $p$ outputs, and imagine that if $p$
isn't a power of 2 we create enough dummy outputs to fill the gap. We
find the difference between the actual Bulletproof size, and the size of
all the Bulletproofs if those $p$ + 'dummy outputs' had been in 2-out
transactions (it's 0 if $p = 2$). We only claw back 80% of the
difference.[^21]
$$\textrm{transaction\_clawback} = 0.8*[(23*(p + \textrm{num\_dummy\_outs})/2) \cdot 32 - (2 \cdot \lceil \textrm{log}_2(64 \cdot p) \rceil + 9) \cdot 32]$$

Therefore the transaction weight is
$$\textrm{transaction\_weight} = \textrm{transaction\_size} + \textrm{transaction\_clawback}$$

A block's weight is equal to the sum of its component transactions'
weights plus the miner transaction's weight.

#### Long term block weight {#long-term-block-weight .unnumbered}

If dynamic blocks are allowed to grow at a rapid pace the blockchain can
quickly become unmanageable [@big-bang-github]. To mitigate this,
maximum block weights are tethered by *long term block weights*. Each
block has, in addition to its normal weight, a 'long term weight'
calculated based on the previous block's effective median long term
weight.[^22] A block's effective median long term weight is related to
the median of the most recent 100000 blocks' long term weights
(including its own).[^23][^24]

$$\begin{aligned}
    \textrm{longterm\_block\_weight} &= min\{\textrm{block\_weight}, 1.4*\textrm{previous\_effective\_longterm\_median}\}\\
    \textrm{effective\_longterm\_median} &= max\{\textrm{300kB}, \textrm{median\_100000blocks\_longterm\_weights}\}%m_long_term_effective_median_block_weight\end{aligned}$$

If normal block weights stay large for a long time, then it will take at
least 50,000 blocks (about 69 days) for the effective long term median
to rise by 40% (that's how long it takes a given long term weight to
become the median).

#### Cumulative median weight {#cumulative-median-weight .unnumbered}

Transaction volume can change dramatically in a short period of time,
especially around holidays [@visa-seasonality]. To accommodate this,
Monero allows short term flexibility in block weights. To smooth out
transient variability, a block's cumulative median uses the median of
the last 100 blocks' normal block weights (including its own).
$$\begin{aligned}
    \textrm{cumulative\_weights\_median} = max\{\textrm{300kB}, min\{&max\{\textrm{300kB}, \textrm{median\_100blocks\_weights}\},\\
    &50*\textrm{effective\_longterm\_median}\}\}%HF_VERSION_EFFECTIVE_SHORT_TERM_MEDIAN_IN_PENALTY %update_next_cumulative_weight_limit() %m_current_block_cumul_weight_median %CRYPTONOTE_SHORT_TERM_BLOCK_WEIGHT_SURGE_FACTOR = 50\end{aligned}$$

The next block to be added to the blockchain is constrained in this
way:[^25]
$$\textrm{max\_next\_block\_weight}\marginnote{src/crypto- note\_basic/ cryptonote\_ basic\_ impl.cpp {\tt get\_block\_ reward()}} = 2*\textrm{cumulative\_weights\_median}$$

While the maximum block weight can rise up to 100 times the effective
median long term weight after a few hundred blocks, it cannot rise more
than 40% beyond that over the next 50,000 blocks. Therefore long-term
block weight growth is tethered by the long term weights, and in the
short term weights may surge above their steady-state values.

### Block reward penalty {#subsec:penalty}

To mine blocks bigger than the cumulative median, miners have to pay a
price, or penalty, in the form of reduced block reward. This means there
are functionally two zones within the maximum block weight: the
penalty-free zone, and the penalty zone. The median can slowly rise,
allowing progressively larger blocks with no penalty.

If the intended block weight is greater than the cumulative median,
then, given base block reward B, the block reward penalty is
$$\textrm{P} = \textrm{B}*((\textrm{block\_weight}/\textrm{cumulative\_weights\_median}) - 1)^2$$

The actual block reward is therefore[^26] $$\begin{aligned}
    \textrm{B}^{\textrm{actual}} &= \textrm{B} - \textrm{P} \\
    \textrm{B}^{\textrm{actual}} &= \textrm{B}*(1-((\textrm{block\_weight}/\textrm{cumulative\_weights\_median}) - 1)^2)\end{aligned}$$

Using the \^2 operation means penalties are sub-proportional to block
weight. A block weight 10% larger than the previous
cumulative_weights_median has just a 1% penalty, 50% larger is 25%
penalty, 90% larger is 81% penalty, and so on. [@monero-coin-emission]\
We can expect miners to create blocks larger than the cumulative median
when the fee from adding another transaction is bigger than the penalty
incurred.

### Dynamic minimum fee {#subsec:dynamic-minimum-fee}

To prevent malicious actors from flooding the blockchain with
transactions that could be used to pollute ring signatures, and
generally bloat it unnecessarily, Monero has a minimum fee per byte of
transaction data.[^27] Originally this was 0.01 XMR/KiB (added early
during protocol v1) [@fee-old-stackexchange], then it became 0.002
XMR/KiB in September 2016 (v3).[^28]

In January 2017 (v4), a dynamic fee per KiB algorithm
[@articmine-fee-video; @articmine-36c3-dynamics; @articmine-defcon27-video; @jollymore-old-analysis]
was added,[^29] and then along with transaction weight reductions due to
Bulletproofs (v8) it changed from per KiB to per byte. The most
important feature of the algorithm is that it prevents minimum possible
total fees from exceeding the block reward (even with small block
rewards and large block weights), which is thought to cause instability
[@fee-reward-instability; @no-reward-instability; @selfish-miner].[^30]

#### The fee algorithm {#the-fee-algorithm .unnumbered}

We base our fee algorithm around a reference transaction
[@jollymore-old-analysis] of weight 3000 bytes (similar to a basic
`RCTTypeBulletproof2` 2-input, 2-output transaction, which is usually
about 2600 bytes)[^31], and the fees it would take to offset the penalty
when the median is at its minimum (the smallest penalty-free zone,
300kB) [@articmine-36c3-dynamics]. In other words, the penalty induced
by a 303kB block weight.

Firstly, the fee F to balance the marginal penalty MP from adding a
transaction with weight TW to a block with weight BW, is
$$\begin{aligned}
    \textrm{F} = \textrm{MP} = \textrm{B}&*(([\textrm{BW} + \textrm{TW}]/\textrm{cumulative\_median} - 1)^2 -\\ \textrm{B}&*((\textrm{BW}/\textrm{cumulative\_median} - 1)^2\end{aligned}$$

Defining the block weight factor
$\textrm{WF}_b = (\textrm{BW}/\textrm{cumulative\_median} - 1)$, and
transaction weight factor
$\textrm{WF}_t = (\textrm{TW}/\textrm{cumulative\_median})$, lets us
simplify
$$\textrm{F} = \textrm{B}*(2*\textrm{WF}_b*\textrm{WF}_t + \textrm{WF}_t^2)$$

Using a block weighing 300kB (with a cumulative median at the default
300kB) and our reference transaction with 3000 bytes, $$\begin{aligned}
    \textrm{F}_{\textrm{ref}} &= \textrm{B}*(2*0*\textrm{WF}_t + \textrm{WF}_t^2)\\
    \textrm{F}_{\textrm{ref}} &= \textrm{B}*\textrm{WF}_t^2\\
    \textrm{F}_{\textrm{ref}} &= \textrm{B}*(\frac{\textrm{TW}_{\textrm{ref}}}{\textrm{cumulative\_median}_{\textrm{ref}}})^2\end{aligned}$$

This fee is spread out over 1% of the penalty zone (3000 out of 300000).
We can spread the same fee over 1% of any penalty zone with a
generalized reference transaction. $$\begin{aligned}
    \frac{\textrm{TW}_{\textrm{ref}}}{\textrm{cumulative\_median}_{\textrm{ref}}} &= \frac{\textrm{TW}_{\textrm{general-ref}}}{\textrm{cumulative\_median}_{\textrm{general}}}\\
    1 &= (\frac{\textrm{TW}_{\textrm{general-ref}}}{\textrm{cumulative\_median}_{\textrm{general}}}) * (\frac{\textrm{cumulative\_median}_{\textrm{ref}}}{\textrm{TW}_{\textrm{ref}}})\\
    \textrm{F}_{\textrm{general-ref}} &= \textrm{F}_{\textrm{ref}}\\
    &= \textrm{F}_{\textrm{ref}}*(\frac{\textrm{TW}_{\textrm{general-ref}}}{\textrm{cumulative\_median}_{\textrm{general}}}) * (\frac{\textrm{cumulative\_median}_{\textrm{ref}}}{\textrm{TW}_{\textrm{ref}}})\\
    \textrm{F}_{\textrm{general-ref}} &= \textrm{B}*(\frac{\textrm{TW}_{\textrm{general-ref}}}{\textrm{cumulative\_median}_{\textrm{general}}}) * (\frac{\textrm{TW}_{\textrm{ref}}}{\textrm{cumulative\_median}_{\textrm{ref}}})\end{aligned}$$

Now we can scale the fee based on a real transaction weight at a given
median, so e.g. if the transaction is 2% of the penalty zone the fee
gets doubled. $$\begin{aligned}
    \textrm{F}_{\textrm{general}} &= \textrm{F}_{\textrm{general-ref}} * \frac{\textrm{TW}_{\textrm{general}}}{\textrm{TW}_{\textrm{general-ref}}}\\
    \textrm{F}_{\textrm{general}} &= \textrm{B}*(\frac{\textrm{TW}_{\textrm{general}}}{\textrm{cumulative\_median}_{\textrm{general}}}) * (\frac{\textrm{TW}_{\textrm{ref}}}{\textrm{cumulative\_median}_{\textrm{ref}}})\end{aligned}$$

This rearranges to the default fee per byte, which we have been working
toward. $$\begin{aligned}
    f^{B}_{default} &= \textrm{F}_{\textrm{general}}/\textrm{TW}_{\textrm{general}}\\
    f^{B}_{default} &= \textrm{B}*(\frac{1}{\textrm{cumulative\_median}_{\textrm{general}}}) * (\frac{3000}{300000})\end{aligned}$$

When transaction volume is below the median there is no real reason for
fees to be at the reference level [@jollymore-old-analysis]. We set the
minimum to be 1/5the default. $$\begin{aligned}
    f^{B}_{min} &= \textrm{B}*(\frac{1}{\textrm{cumulative\_weights\_median}}) * (\frac{3000}{300000}) * (\frac{1}{5})\\
    f^{B}_{min} &= \textrm{B}*(\frac{1}{\textrm{cumulative\_weights\_median}}) * 0.002\end{aligned}$$

#### The fee median {#the-fee-median .unnumbered}

It turns out using the cumulative median for fees enables a spam attack.
By raising the short term median to its highest value (50 x long term
median), an attacker can use minimum fees to maintain high block weights
(relative to organic transaction volume) with very low cost.

To avoid this we limit fees for transactions to go in the next block
with the smallest median available, which favors higher fees in all
cases.[^32]
$$\textrm{smallest\_median}\marginnote{src/crypto- note\_core\ block- chain.cpp {\tt check\_fee()}} = max\{\textrm{300kB}, min\{\textrm{median\_100blocks\_weights}, \textrm{effective\_longterm\_median}\}\}$$

Favoring higher fees during rising transaction volume also facilitates
adjusting the short term median and ensuring transactions aren't left
pending, as miners are more likely to mine into the penalty zone.

The actual minimum fee is therefore[^33][^34]

$$f^{B}_{min-actual}\marginnote{src/crypto- note\_core\ block- chain.cpp {\tt get\_dyna- mic\_base\_ fee()}} = \textrm{B}*(\frac{1}{\textrm{smallest\_median}}) * 0.002$$

#### Transaction fees {#transaction-fees .unnumbered}

As Caba$\tilde{\textrm{n}}$as said in his insightful presentation on
this topic [@articmine-36c3-dynamics], "\[f\]ees tell the miner how deep
into the penalty \[transaction authors are\] willing to pay for, in
order to get a transaction mined.\" Miners will fill up their blocks by
adding transactions in descending order of fee amount
[@articmine-36c3-dynamics] (assuming all transactions have the same
weight), so to move into the penalty zone there must be numerous
transactions with large fees. This means it is likely the block weight
cap can only be reached if total fees are at least about 3-4 times the
base block reward (at which point the actual block reward is zero).[^35]

To calculate fees for a transaction, Monero's core implementation wallet
uses 'priority' multipliers. A 'slow' transaction uses the minimum fee
directly, 'normal' is the default fee (5x), if all transactions use
'fast' (25x) they can reach 2.5% of the penalty zone, and a block with
'super urgent' (1000x) transactions can fill 100% of the penalty zone.

One important consequence of dynamic block weights is average total
block fees will tend to be of a magnitude lower than, or at least the
same as, the block reward (total fees can be expected to equal the base
block reward at about 37% of the penalty zone \[68.5% of the maximum
block weight\], when the penalty is 13%). Transactions competing for
block space with higher fees leads to a bigger supply of block space,
and lower fees.[^36] This feedback mechanism is a strong counter to the
renowned 'selfish miner' [@selfish-miner] threat.

### Emission tail {#subsec:emission-tail}

Let's suppose a cryptocurrency with fixed maximum supply and dynamic
block weight. After a while its block rewards fall to zero. With no more
penalty on increasing block weight, miners add any transaction with a
non-zero fee to their blocks.

Block weights stabilize around the average rate of transactions
submitted to the network, and transaction authors have no compelling
reason to use transaction fees above the minimum, which would be zero
according to Section
[1.3.4](#subsec:dynamic-minimum-fee){reference-type="ref"
reference="subsec:dynamic-minimum-fee"}.

This introduces an unstable, insecure situation. Miners have little to
no incentive to mine new blocks, leading to a fall in network hash rate
as returns on investment decline. Block times remain the same as
difficulties adjust, but the cost of performing a double-spend attack
may become feasible.[^37] If minimum fees are forced to be non-zero then
the 'selfish miner' [@selfish-miner] threat becomes realistic
[@no-reward-instability].\
Monero prevents this by not allowing the block reward to fall below 0.6
XMR (0.3 XMR per minute). When the following condition is met,
$$\begin{aligned}
               0.6 &> ((L-M) >> 19)/10^{12} \\
        \textrm{M} &> \textrm{L} - 0.6*2^{19}*10^{12} \\
\textrm{M}/10^{12} &> \textrm{L}/10^{12} - 0.6*2^{19} \\
\textrm{M}/10^{12} &> 18,132,171.273709551615\end{aligned}$$

the Monero chain will enter a so-called 'emission tail', with constant
0.6 XMR (0.3 XMR/minute) block rewards forever after.[^38] This
corresponds with about 0.9% yearly inflation to begin with, steadily
declining thereafter.

### Miner transaction: `RCTTypeNull` {#subsec:miner-transaction}

A block's miner has the right to claim ownership of the fees provided in
its transactions, and to mint new money in the form of a block reward.
The mechanism is a miner transaction (a.k.a. coinbase transaction),
which is similar to a normal transaction.[^39]

The output amount(s) of a miner transaction must be no more than the sum
of transaction fees and block reward, and are communicated in clear
text.[^40] In place of an input, the block's height is recorded (i.e. "I
claim the block reward and fees for the nblock\").

Ownership of the miner output(s) is assigned to a standard one-time
address[^41], with a corresponding transaction public key stored in the
extra field. The funds are locked, unspendable, until the 60block after
it is published [@transaction-lock].[^42]

Since RingCT was implemented in January 2017 (v4 of the protocol)
[@ringct-dates], people downloading a new copy of the blockchain compute
a commitment to the miner transaction (a.k.a. tx) amount $a$, as
$C = 1G + aH$, and store it for referral. This allows block miners to
spend their miner transaction outputs just like a normal transaction's
outputs, putting them in MLSAG rings with other normal and miner tx
outputs.\
Blockchain verifiers store each post-RingCT block's miner tx amount
commitment, for 32 bytes each.

## Blockchain structure {#sec:blockchain-structure}

Monero's blockchain style is simple.

It starts with a genesis message\[-.8cm\] of some kind (in our case
basically a miner transaction dispersing the first block reward), which
constitutes the genesis block (see Appendix
[\[appendix:genesis-block\]](#appendix:genesis-block){reference-type="ref"
reference="appendix:genesis-block"}). The next block contains a
reference to the previous block, in the form of block ID.

A block ID is simply a hash of\[1.2cm\] the block's header (a list of
information about a block), a so-called 'Merkle root' that attaches all
the block's transaction IDs (which are hashes of each transaction), and
the number of transactions (including the miner
transaction).\[4.5cm\][^43]
$$\textrm{Block ID} = \mathcal{H}_n(\textrm{Block header}, \textrm{Merkle root}, \# \textrm{transactions} + 1)$$

To produce a new block, one must do proof of work hashes by changing a
nonce value stored in the block header until the difficulty target
condition is met.[^44] The proof of work and block ID hash the same
information, except use different hash functions. Blocks are
mined\[5.55cm\] by, while $({PoW}_{output} * {difficulty}) > 2^{256}-1$,
repeatedly changing the nonce and recalculating
$${PoW}_{output} = \mathcal{H}_{PoW}(\textrm{Block header}, \textrm{Merkle root}, \# \textrm{transactions} + 1)$$

### Transaction ID {#subsec:transaction-id}

Transaction IDs are similar to the message signed by input MLSAG
signatures (Section
[\[full-signature\]](#full-signature){reference-type="ref"
reference="full-signature"}), but include the MLSAG signatures too.

The following information is hashed:

-   TX Prefix = {transaction era version (e.g. ringCT = 2), inputs {key
    offsets, key images}, outputs {one-time addresses}, extra
    {transaction public key, encoded payment ID, misc.}}

-   TX Stuff = {signature type (`RCTTypeNull` or `RCTTypeBulletproof2`),
    transaction fee, pseudo output commitments for inputs, ecdhInfo
    (encrypted or cleartext amounts), output commitments}

-   Signatures = {MLSAGs, range proofs}

In this tree diagram the black arrow indicates a hash of inputs.

::: {.center}
forked edges, for tree = grow'=90, edge = \<-, \> = triangle 60, fork
sep = 4.5 mm, l sep = 8 mm, rectangle, draw , sn edges, where n
children=0tier=terminus, \[Transaction ID \[$\mathcal{H}_n$(TX Prefix)\]
\[$\mathcal{H}_n$(TX Stuff)\] \[$\mathcal{H}_n$(Signatures)\] \]
:::

In place of an 'input', a miner transaction records the block height of
its block. This ensures the miner transaction's ID, which is simply a
normal transaction ID except with $\mathcal{H}_n$(Signatures)
$\rightarrow$ 0, is always unique, for simpler ID-searching.

### Merkle tree {#subsec:merkle-tree}

Some users may want to discard data from their copy of the blockchain.
For example, once you verify a transaction's range proofs and input
signatures, the only reason to keep that signature information is so
users who obtain it from you can verify it for themselves.

To facilitate 'pruning' transaction data, and to more generally organize
it within a block, we use a Merkle tree [@merkle-tree], which is just a
binary hash tree. Any branch in a Merkle tree can be pruned if you keep
its root hash.[^45]\
An example Merkle tree based on four transactions and a miner
transaction is diagrammed in Figure
[1](#chapter:blockchain){reference-type="ref"
reference="chapter:blockchain"}.1.[^46]

::: {.center}
forked edges, for tree = grow'=90, edge = \<-, \> = triangle 60, fork
sep = 4.5 mm, l sep = 8 mm, rectangle, draw , sn edges, where n
children=0tier=terminus, \[Merkle Root \[$Hash$ B \[Transaction ID\
1\] \[Transaction ID\
2\] \] \[$Hash$ C \[Transaction ID\
3\] \[$Hash$ A \[Transaction ID\
4\] \[Miner Transaction ID\] \] \] \] at (current bounding box.south)
\[below=3ex,thick,draw,rectangle\] *Figure
[1](#chapter:blockchain){reference-type="ref"
reference="chapter:blockchain"}.1: Merkle Tree*;
:::

A Merkle root is inherently a reference to all its included
transactions.

### Blocks {#subsec:blocks}

A block is basically a block header and some transactions. Block headers
record important information about each block. A block's transactions
can be referenced with their Merkle root. We present here the outline of
a block's content. Our readers can find a real block example in Appendix
[\[appendix:block-content\]](#appendix:block-content){reference-type="ref"
reference="appendix:block-content"}.

-   [Block header]{.ul}:

    -   **Major version**: Used to track hard forks (changes to the
        protocol).

    -   **Minor version**: Once used for voting, now it just displays
        the major version again.

    -   **Timestamp**: UTC (Coordinated Universal Time) time of the
        block. Added by miners, timestamps are unverified but they won't
        be accepted if lower than the median timestamp of the previous
        60 blocks.

    -   **Previous block's ID**: Referencing the previous block, this is
        the essential feature of a blockchain.

    -   **Nonce**: A 4-byte integer that miners change over and over
        until the PoW hash meets the difficulty target. Block verifiers
        can easily recalculate the PoW hash.

-   [Miner transaction]{.ul}: Disperses the block reward and transaction
    fees to the block's miner.

-   [Transaction IDs]{.ul}: References to non-miner transactions added
    to the blockchain by this block. Tx IDs can, in combination with the
    miner tx ID, be used to calculate the Merkle root, and to find the
    actual transactions wherever they are stored.\

In addition to the data in each transaction (Section
[\[sec:transaction_summary\]](#sec:transaction_summary){reference-type="ref"
reference="sec:transaction_summary"}), we store the following
information:

-   Major and minor versions: variable integers $\leq 9$ bytes

-   Timestamp: variable integer $\leq 9$ bytes

-   Previous block's ID: 32 bytes

-   Nonce: 4 bytes, can extend its effective size with the miner tx
    extra field's extra nonce[^47]

-   Miner transaction: 32 bytes for a one-time address, 32 bytes for a
    transaction public key (+1 byte for its 'extra' tag), and variable
    integers for the unlock time, corresponding block's height, and
    amount. After downloading the blockchain, we also need 32 bytes to
    store an amount commitment $C = 1G + a H$ (only for post-RingCT
    miner tx amounts).

-   Transaction IDs: 32 bytes each

[^1]: This chapter includes more implementation details than previous
    chapters, as a blockchain's nature depends heavily on its specific
    structure.

[^2]: In political science this is called a Schelling Point
    [@friedman-schelling], social minima, or social contract.

[^3]: In commodity money like gold these rules are met by physical
    reality.

[^4]: A blockchain is technically a 'directed acyclic graph' (DAG), with
    Bitcoin-style blockchains a one-dimensional variant. DAGs contain a
    finite number of nodes and one-directional edges (vectors)
    connecting nodes. If you start at one node, you will never loop back
    to it no matter what path you take. [@DAG-wikipedia]

[^5]: We use $\in^D_R$ to say the output is deterministically random.

[^6]: In Monero only difficulties are recorded/computed since
    $\mathcal{H}_{PoW}(\mathfrak{m},n)*d \leq m$ doesn't need $t$.

[^7]: Mining and verifying are asymmetric since it takes the same time
    to verify a proof of work (one computation of the proof of work
    algorithm) no matter what the difficulty is.

[^8]: Timestamps are determined when a miner *starts* mining a block, so
    they are likely to lag behind the actual publication moment. The
    next block starts mining right away, so the timestamp that appears
    *after* a given block indicates how long miners spent on it.

[^9]: If node 1 tries nonce $n = 23$ and later node 2 also tries
    $n = 23$, node 2's effort is wasted because the network already
    'knows' $n = 23$ doesn't work (otherwise node 1 would have published
    that block). The network's *effective* hash rate depends on how fast
    it hashes *unique* nonces for a given block of messages. As we will
    see, since miners include a miner transaction with one-time address
    $K^o \in_{ER} \mathbb{Z}_l$ (ER = effectively random) in their
    blocks, blocks are always unique between miners except with
    negligible probability, so trying the same nonces doesn't matter.

[^10]: If we assume network hash rate is constantly, gradually,
    increasing, then since new difficulties depend on *past* hashes
    (i.e. before the hash rate increased a tiny bit) we should expect
    actual block times to, on average, be slightly less than
    $\mathit{targetTime}$. The effect of this on the emission schedule
    (Section [1.3.1](#subsec:block-reward){reference-type="ref"
    reference="subsec:block-reward"}) could be canceled out by penalties
    from increasing block weights, which we explore in Section
    [1.3.3](#subsec:penalty){reference-type="ref"
    reference="subsec:penalty"}.

[^11]: Monero developers have successfully changed its protocol 11
    times, with nearly all users and miners adopting each fork: v1 April
    18, 2014 (genesis version) [@bitmonero-launched]; v2 March 2016; v3
    September 2016; v4 January 2017; v5 April 2017; v6 September 2017;
    v7 April 2018; v8 and v9 October 2018; v10 and v11 March 2019; v12
    November 2019. The core git repository's README contains a summary
    of protocol changes in each version.

[^12]: In March 2016 (v2 of the protocol), Monero changed from 1 minute
    target block times to 2 minute target block times [@monero-0.9.3].
    Other difficulty parameters have always been the same.

[^13]: Monero's difficulty algorithm may be suboptimal compared to state
    of the art algorithms [@difficuly-algorithm-summary]. Fortunately it
    is 'fairly resilient to selfish mining'
    [@selfish-miner-profitability-algorithm-analysis], an essential
    feature.

[^14]: A miner transaction can have any number of outputs, although
    currently the core implementation is only able to make one.
    Moreover, unlike normal transactions there are no explicit
    restrictions on miner transaction weight. They are functionally
    limited by the maximum block weight.

[^15]: As an attacker gets higher shares of the hash rate (beyond 50%),
    it takes less time to rewrite older and older blocks. Given a block
    $x$ days old, owned hash speed $v$, and honest hash speed $v_h$
    ($v > v_h$), it will take $y = x*(v_h/(v-v_h))$ days to rewrite.

[^16]: Bitwise shift right by $n$ bits is equivalent to integer division
    by $2^n$.

[^17]: Perhaps now it is clear why range proofs (Section
    [\[sec:range_proofs\]](#sec:range_proofs){reference-type="ref"
    reference="sec:range_proofs"}) limit transaction amounts to 64 bits.

[^18]: Monero amounts are stored in atomic-unit format in the
    blockchain.

[^19]: For an interesting comparison of Monero and Bitcoin's emission
    schedules see [@monero-coin-emission].

[^20]: Bitcoin has a history of overloaded transaction volume. This
    website (<https://bitcoinfees.info/>) charts the ridiculous fee
    levels encountered (up to the equivalent of 35\$ per transaction at
    one point).

[^21]: Note that $\textrm{log}_2(64 \cdot 2) = 7$, and $2*7 + 9 = 23$.

[^22]: Similar to block difficulties, block weights and long term block
    weights are calculated and stored by blockchain verifiers rather
    than being included in blockchain data.

[^23]: Blocks made before long term weights were implemented have long
    term weights equal to their normal weights, so there is no concern
    for us about details surrounding the genesis block or early blocks.
    A brand new chain could easily make sensible choices.

[^24]: In the beginning of Monero the '300kB' term was 20kB, then
    increased to 60kB in March 2016, (v2 of the protocol)
    [@monero-0.9.3], and has been 300kB since April 2017 (v5 of the
    protocol) [@monero-v5]. This non-zero 'floor' within the dynamic
    block weight medians helps transient transaction volume changes when
    the absolute volume is low, especially in the early stages of Monero
    adoption.

[^25]: The cumulative median replaced 'M100' (a similar median term) in
    protocol v8. Penalties and fees described in the first edition of
    this report [@ztm-1] used M100.

[^26]: Before confidential transactions (RingCT) were implemented (v4),
    all amounts were communicated in clear text and in some early
    protocol versions split into chunks (e.g. 1244 $\rightarrow$ 1000 +
    200 + 40 + 4). To reduce miner tx size, the core implementation
    chopped off the lowest significant digits of block rewards (anything
    less than 0.0001 Moneroj; see `BASE_REWARD_CLAMP_THRESHOLD`) in
    v2-v3. The extra little bit was not lost, just made available for
    future block rewards. More generally, since v2 the block reward
    calculation here is just an upper limit on the real block reward
    that can be dispersed in a miner tx's outputs. Also of note, very
    early transactions' outputs with cleartext amounts *not* split into
    chunks can't be used in ring signatures in the current
    implementation, so to spend them they are migrated into chunked,
    'mixable', outputs, which can then be spent in normal RingCT
    transactions by creating rings out of other chunks with the same
    amount. Exact modern protocol rules around these ancient pre-RingCT
    outputs are not clear.

[^27]: This minimum is enforced by the node consensus protocol, not the
    blockchain protocol. Most nodes won't relay a transaction to other
    nodes if it has a fee below the minimum (at least in part so only
    transactions likely to be mined by someone are passed along
    [@articmine-36c3-dynamics]), but they *will* accept a new block
    containing that transaction. In particular, this means there is no
    need to maintain backward compatibility with fee algorithms.

[^28]: The unit KiB (kibibyte, 1 KiB = 1024 bytes) is different from kB
    (kilobyte, 1 kB = 1000 bytes).

[^29]: The base fee was changed from 0.002 XMR/KiB to 0.0004 XMR/KiB in
    April 2017 (v5 of the protocol) [@monero-v5]. The first edition of
    this report described the original dynamic fee algorithm [@ztm-1].

[^30]: Credit for the concepts in this section largely belongs to
    Francisco Caba$\tilde{\textrm{n}}$as (a.k.a. 'ArticMine'), the
    architect of Monero's dynamic block and fee system. See
    [@articmine-fee-video; @articmine-36c3-dynamics; @articmine-defcon27-video].

[^31]: A basic 1-input, 2-output Bitcoin transaction is 250 bytes
    [@bitcoin-txsizes-2015], or 430 bytes for 2-in/2-out.

[^32]: An attacker can spend just enough in fees for the short term
    median to hit 50\*long-term-median. With current (as of this
    writing) block rewards at 2 XMR, an optimized attacker can increase
    the short term median by 17% every 50 blocks, and reach the upper
    bound after about 1300 blocks (about 43 hours), spending 0.39\*2 XMR
    per block, for a total setup cost of about 1000 XMR (or around 65k
    USD at current valuations), and then go back to the minimum fee.
    When the fee median equals the penalty-free zone, then the minimum
    total fee to fill the penalty-free zone is 0.004 XMR (about 0.26 USD
    at current valuations). If the fee median equals the long term
    median, it would in the spam scenario be 1/50th the penalty-free
    zone. Therefore it would just be 50x the short-median case, for 0.2
    XMR per block (13 USD per block). This comes out to 2.88 XMR per day
    vs 144 XMR per day (for 69 days, until the long term median rises by
    40%) to maintain every block with 50\*long-term-median block weight.
    The 1000 XMR setup cost would be worthwhile in the former case, but
    not the latter. This will reduce to 300 XMR setup, and 43 XMR
    maintenance, at the emission tail.

[^33]: To check if a given fee is correct, we allow a 2% buffer on
    $f^{B}_{min-actual}$ in case of integer overflow (we must compute
    fees before tx weights are completely determined). This means the
    effective minimum fee is 0.98\*$f^{B}_{min-actual}$.

[^34]: Research to improve minimum fees even further is ongoing.
    [@min-fee-research-issue-70]

[^35]: [\[penaltyzonecost_footnote\]]{#penaltyzonecost_footnote
    label="penaltyzonecost_footnote"}The marginal penalty from the last
    bytes to fill up a block can be considered a 'transaction'
    comparable to other transactions. In order for a clump of
    transactions to buy that transaction space from a miner, all its
    individual transaction fees should be higher than the penalty, since
    if any one of them is lower then the miner will keep the marginal
    reward instead. This last marginal reward, assuming a block filled
    with small transactions, requires at least 4x the base block reward
    in total fees to be purchased. If transaction weights are maximized
    (50% of the minimum penalty-free zone, i.e. 150kB) then if the
    median is minimized (300kB) the last marginal transaction requires
    at least 3x in total fees.

[^36]: As block rewards decline over time, and the median rises due to
    increased adoption (theoretically), fees should steadily become
    smaller and smaller. In 'real purchasing power' terms, this may be
    less impactful on transaction costs if the value of Moneroj rises
    due to adoption and economic deflation.

[^37]: The case of fixed supply and fixed block weight, as in Bitcoin,
    is also thought to be unstable. [@no-reward-instability]

[^38]: The Monero emission tail's estimated arrival is May 2022
    [@monero-tail-emission]. The money supply limit L will be reached in
    May 2024, but since coin emission will no longer depend on the
    supply it will have no effect. Based on Monero's range proof, it
    will be impossible to send more money than L in one output, even if
    someone manages to accumulate more than that (and assuming they have
    wallet software that can handle that much).

[^39]: Apparently, at one point miner transactions could be constructed
    using deprecated transaction format versions, and could include some
    normal transaction (RingCT) components. The issues were fixed in
    protocol v12 after this hackerone report was published:
    [@miner-tx-checks].

[^40]: In the current version miners may claim less than the calculated
    block reward. The leftovers are pushed back into the emission
    schedule for future miners.

[^41]: The miner transaction output can theoretically be sent to a
    subaddress and/or use multisig and/or an encoded payment ID. We
    don't know if any implementations have any of those features.

[^42]: The miner tx can't be locked for more or less than 60 blocks. If
    it is published in the 10block, its unlock height is 70, and it may
    be spent in the 70block or later.\[.5cm\]

[^43]: +1 accounts for the miner tx.

[^44]: In Monero a typical miner (from <https://monerobenchmarks.info/>
    as of this writing) can do less than 50,000 hashes per second, so
    less than 6 million hashes per block. This means the nonce variable
    doesn't need to be that big. Monero's nonce is 4 bytes (max 4.3
    billion), and it would be strange for any miner to require all the
    bits.

[^45]: The first known pruning method was added in v0.14.1 of the core
    Monero implementation (March 2019, coinciding with protocol v10).
    After verifying a transaction, full nodes can delete all its
    signature data (including Bulletproofs, MLSAGS, and pseudo output
    commitments) while keeping $\mathcal{H}_n$(Signatures) for computing
    the transaction ID. They only do this with 7/8of all transactions,
    so every transaction is fully stored by at least 1/8of the network's
    full nodes. This reduces blockchain storage by about 2/3.
    [@monero-pruning-1/8]

[^46]: A bug in Monero's Merkle tree code led to a serious, though
    apparently non-critical, real-world attack on September 4, 2014
    [@MRL-0002-merkle-problem].

[^47]: Within each transaction is an 'extra' field which can contain
    more-or-less arbitrary data. If a miner needs a wider range of
    nonces than just 4 bytes, they can add or alter data in their miner
    tx's extra field to 'extend' the nonce size.
    [@extra-field-stackexchange]
