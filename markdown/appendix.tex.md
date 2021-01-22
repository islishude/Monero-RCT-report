# `RCTTypeBulletproof2` Transaction Structure {#appendix:RCTTypeBulletproof2}

We present in this appendix a dump from a real Monero transaction of
type `RCTTypeBulletproof2`, together with explanatory notes for relevant
fields.

The dump was obtained from the block explorer <https://xmrchain.net>. It
can also be acquired by executing command
`print_tx <TransactionID> +hex +json` in the `monerod` daemon run in
non-detached mode. `<TransactionID>` is a hash of the transaction
(Section
[\[subsec:transaction-id\]](#subsec:transaction-id){reference-type="ref"
reference="subsec:transaction-id"}). The first line printed shows the
actual command to run.

To replicate our results, readers can do the following:

1.  We need the Monero command line tool (CLI), which can be found at
    <https://web.getmonero.org/downloads/> (among other places). Get the
    'Command Line Tools Only' for your operating system, move the file
    to a useful location, and unzip it.

2.  Open the terminal/command line and navigate into the folder created
    by unzipping.

3.  Run `monerod` with `./monerod`. Now the Monero blockchain will
    download. Unfortunately, there is currently no easy way to print
    transactions on your own system (e.g. without using a block
    explorer) without downloading the blockchain.

4.  After the syncing process is done, commands like `print_tx` will
    work. Use `help` to learn other commands.

Component `rctsig_prunable`, as indicated by its name, is *prunable*
from the blockchain. That is, once a block has been consensuated and the
current chain length rules out all possibilities of double-spending
attacks, this whole field can be pruned and replaced with its hash for
the Merkle tree.

Key images are stored separately, in the non-prunable area of
transactions. These are essential for detecting double-spend attacks and
can't be pruned away.\
Our sample transaction has 2 inputs and 2 outputs, and was added to the
blockchain at timestamp 2020-03-02 19:01:10 UTC (as reported by its
block's miner).

``` {.numberLines commandchars="\\\\\\{\\}" numbers="left"}
print_tx 84799c2fc4c18188102041a74cef79486181df96478b717e8703512c7f7f3349
Found in blockchain at height 2045821
\{
  "version": 2, 
  "unlock_time": 0, 
  "vin": [ \{
      "key": \{
        "amount": 0, 
        "key_offsets": [ 14401866, 142824, 615514, 18703, 5949, 22840, 5572, 16439,
        983, 4050, 320
        ], 
        "k_image": "c439b9f0da76ca0bb17920ca1f1f3f1d216090751752b091bef9006918cb3db4"
      \}
    \}, \{
      "key": \{
        "amount": 0, 
        "key_offsets": [ 14515357, 640505, 8794, 1246, 20300, 18577, 17108, 9824, 581,
        637, 1023
        ], 
        "k_image": "03750c4b23e5be486e62608443151fa63992236910c41fa0c4a0a938bc6f5a37"
      \}
    \}
  ], 
  "vout": [ \{
      "amount": 0, 
      "target": \{
        "key": "d890ba9ebfa1b44d0bd945126ad29a29d8975e7247189e5076c19fa7e3a8cb00"
      \}
    \}, \{
      "amount": 0, 
      "target": \{
        "key": "dbec330f8a67124860a9bfb86b66db18854986bd540e710365ad6079c8a1c7b0"
      \}
    \}
  ], 
  "extra": [ 1, 3, 39, 58, 185, 169, 82, 229, 226, 22, 101, 230, 254, 20, 143,
  37, 139, 28, 114, 77, 160, 229, 250, 107, 73, 105, 64, 208, 154, 182, 158, 200,
  73, 2, 9, 1, 12, 76, 161, 40, 250, 50, 135, 231
  ], 
  "rct_signatures": \{
    "type": 4, 
    "txnFee": 32460000, 
    "ecdhInfo": [ \{
        "amount": "171f967524e29632"
      \}, \{
        "amount": "5c2a1a9f54ccf40b"
      \}], 
    "outPk": [ "fed8aded6914f789b63c37f9d2eb5ee77149e1aa4700a482aea53f82177b3b41",
    "670e086e40511a279e0e4be89c9417b4767251c5a68b4fc3deb80fdae7269c17"]
  \}, 
  "rctsig_prunable": \{
    "nbp": 1, 
    "bp": [ \{
        "A": "98e5f23484e97bb5b2d453505db79caadf20dc2b69dd3f2b3dbf2a53ca280216", 
        "S": "b791d4bc6a4d71de5a79673ed4a5487a184122321ede0b7341bc3fdc0915a796", 
        "T1": "5d58cfa9b69ecdb2375647729e34e24ce5eb996b5275aa93f9871259f3a1aecd", 
        "T2": "1101994fea209b71a2aa25586e429c4c0f440067e2b197469aa1a9a1512f84b7", 
        "taux": "b0ad39da006404ccacee7f6d4658cf17e0f42419c284bdca03c0250303706c03", 
        "mu": "cacd7ca5404afa28e7c39918d9f80b7fe5e572a92a10696186d029b4923fa200", 
        "L": [ "d06404fc35a60c6c47a04e2e43435cb030267134847f7a49831a61f82307fc32",
        "c9a5932468839ee0cda1aa2815f156746d4dce79dab3013f4c9946fce6b69eff",
        "efdae043dcedb79512581480d80871c51e063fe9b7a5451829f7a7824bcc5a0b",
        "56fd2e74ac6e1766cfd56c8303a90c68165a6b0855fae1d5b51a2e035f333a1d",
        "81736ed768f57e7f8d440b4b18228d348dce1eca68f969e75fab458f44174c99",
        "695711950e076f54cf24ad4408d309c1873d0f4bf40c449ef28d577ba74dd86d",
        "4dc3147619a6c9401fec004652df290800069b776fe31b3c5cf98f64eb13ef2c"
        ], 
        "R": [ "7650b8da45c705496c26136b4c1104a8da601ea761df8bba07f1249495d8f1ce",
        "e87789fbe99a44554871fcf811723ee350cba40276ad5f1696a62d91a4363fa6",
        "ebf663fe9bb580f0154d52ce2a6dae544e7f6fb2d3808531b0b0749f5152ddbf",
        "5a4152682a1e812b196a265a6ba02e3647a6bd456b7987adff288c5b0b556ec6",
        "dc0dcb2e696e11e4b62c20b6bfcb6182290748c5de254d64bf7f9e3c38fb46c9",
        "101e2271ced03b229b88228d74b36088b40c88f26db8b1f9935b85fb3ab96043",
        "b14aae1d35c9b176ac526c23f31b044559da75cf95bc640d1005bfcc6367040b"
        ], 
        "a": "4809857de0bd6becdb64b85e9dfbf6085743a8496006b72ceb81e01080965003", 
        "b": "791d8dc3a4ddde5ba2416546127eb194918839ced3dea7399f9c36a17f36150e", 
        "t": "aace86a7a1cbdec3691859fa07fdc83eed9ca84b8a064ca3f0149e7d6b721c03"
      \}
    ], 
    "MGs": [ \{
        "ss": [[ "d7a9b87cfa74ad5322eedd1bff4c4dca08bcff6f8578a29a8bc4ad6789dee106",
        "f08e5dfade29d2e60e981cb561d749ea96ddc7e6855f76f9b807842d1a17fe00"],
        ["de0a86d12be2426f605a5183446e3323275fe744f52fb439041ad2d59136ea0b",
        "0028f97976630406e12c54094cbbe23a23fe5098f43bcae37339bfc0c4c74c07"],
        ["f6eef1f99e605372cb1ec2b3dd4c6e56a550fec071c8b1d830b9fda34de5cc05",
        "cd98fc987374a0ac993edf4c9af0a6f2d5b054f2af601b612ea118f405303306"],
        ["5a8437575dae7e2183a1c620efbce655f3d6dc31e64c96276f04976243461e08",
        "5090103f7f73a33024fbda999cd841b99b87c45fa32c4097cdc222fa3d7e9502"],
        ["88d34246afbccbd24d2af2ba29d835813634e619912ea4ca194a32281ac14e0e",
        "eacdf59478f132dd8dbb9580546f96de194092558ffceeff410ee9eb30ce570e"],
        ["571dab8557921bbae30bda9b7e613c8a0cff378d1ec6413f59e4972f30f2470d",
        "5ca78da9a129619299304d9b03186233370023debfdaddcd49c1a338c1f0c50d"],
        ["ac8dbe6bb28839cf98f02908bd1451742a10c713fdd51319f2d42a58bf1d7507",
        "7347bf16cba5ee6a6f2d4f6a59d1ed0c1a43060c3a235531e7f1a75cd8c8530d"],
        ["b8876bd3a5766150f0fbc675ba9c774c2851c04afc4de0b17d3ac4b6de617402",
        "e39f1d2452d76521cbf02b85a6b626eeb5994f6f28ce5cf81adc0ff2b8adb907"],
        ["1309f8ead30b7be8d0c5932743b343ef6c0001cef3a4101eae98ffde53f46300",
        "370693fa86838984e9a7232bca42fd3d6c0c2119d44471d61eee5233ba53c20f"],
        ["80bc2da5fc5951f2c7406fce37a7aa72ffef9cfa21595b1b68dfab4b7b9f9f0c",
        "c37137898234f00bce00746b131790f3223f97960eefe67231eb001092f5510c"],
        ["01c89e07571fd365cac6744b34f1b44e06c1c31cbf3ee4156d08309345fdb20e",
        "a35c8786695a86c0a4e677b102197a11dadc7171dd8c2e1de90d828f050ec00f"]], 
        "cc": "0d8b70c600c67714f3e9a0480f1ffc7477023c793752c1152d5df0813f75ff0f"
      \}, \{
        "ss": [[ "4536e585af58688b69d932ef3436947a13d2908755d1c644ca9d6a978f0f0206",
        "9aab6509f4650482529219a805ee09cd96bb439ee1766ced5d3877bf1518370b"],
        ["5849d6bf0f850fcee7acbef74bd7f02f77ecfaaa16a872f52479ebd27339760f",
        "96a9ec61486b04201313ac8687eaf281af59af9fd10cf450cb26e9dc8f1ce804"],
        ["7fe5dcc4d3eff02fca4fb4fa0a7299d212cd8cd43ec922d536f21f92c8f93f00",
        "d306a62831b49700ae9daad44fcd00c541b959da32c4049d5bdd49be28d96701"],
        ["2edb125a5670d30f6820c01b04b93dd8ff11f4d82d78e2379fe29d7a68d9c103",
        "753ac25628c0dada7779c6f3f13980dfc5b7518fb5855fd0e7274e3075a3410c"],
        ["264de632d9cb867e052f95007dfdf5a199975136c907f1d6ad73061938f49c01",
        "dd7eb6028d0695411f647058f75c42c67660f10e265c83d024c4199bed073d01"],
        ["b2ac07539336954f2e9b9cba298d4e1faa98e13e7039f7ae4234ac801641340f",
        "69e130422516b82b456927b64fe02732a3f12b5ee00c7786fe2a381325bf3004"],
        ["49ea699ca8cf2656d69020492cdfa69815fb69145e8f922bb32e358c23cebb0f",
        "c5706f903c04c7bed9c74844f8e24521b01bc07b8dbf597621cceeeb3afc1d0c"],
        ["a1faf85aa942ba30b9f0511141fcab3218c00953d046680d36e09c35c04be905",
        "7b6b1b6fb23e0ee5ea43c2498ea60f4fcf62f70c7e0e905eb4d9afa1d0a18800"],
        ["785d0993a70f1c2f0ac33c1f7632d64e34dd730d1d8a2fb0606f5770ed633506",
        "e12777c49ffc3f6c35d27a9ccb3d9b8fed7f0864a880f7bae7399e334207280e"],
        ["ab31972bf1d2f904d6b0bf18f4664fa2b16a1fb2644cd4e6278b63ade87b6d09",
        "1efb04fe9a75c01a0fe291d0ae00c716e18c64199c1716a086dd6e32f63e0a07"],
        ["a6f4e21a27bf8d28fc81c873f63f8d78e017666adbf038da0b83c2ad04ef6805",
        "c02103455f93c2d7ec4b7152db7de00d1c9e806b1945426b6773026b4a85dd03"]], 
        "cc": "d5ac037bb78db41cf924af713b7379c39a4e13901d3eac017238550a1a3b910a"
      \}],
    "pseudoOuts": [ "b313c1ae9ca06213684fbdefa9412f4966ad192bc0b2f74ed1731381adb7ab58",
    "7148e7ef5cfd156c62a6e285e5712f8ef123575499ff9a11f838289870522423"]
  \}
\}
```

## Transaction components {#transaction-components .unnumbered}

-   (line 2) - The command `print_tx` would report the block where it
    found the transaction, which we replicate here for demonstration
    purposes.

-   `version` (line 4) - Transaction format/era version; '2' corresponds
    to RingCT.

-   `unlock_time` (line 5) - Prevents a transaction's outputs from being
    spent until the time has past. It is either a block height, or a
    UNIX timestamp if the number is larger than the beginning of UNIX
    time. It defaults to zero when no limit is specified.

-   `vin` (line 6-23) - List of inputs (there are two here)

-   `amount` (line 8) - Deprecated (legacy) amount field for type 1
    transactions

-   `key_offset` (line 9) - This allows verifiers to find ring member
    keys and commitments in the blockchain, and makes it obvious those
    members are legitimate. The first offset is absolute within the
    blockchain history, and each subsequent offset is relative to the
    previous. For example, with real offsets {7,11,15,20}, the
    blockchain records {7,4,4,5}. Verifiers compute the last offset like
    (7+4+4+5 = 20) (Section
    [\[subsec:space-and-ver-rcttypefull\]](#subsec:space-and-ver-rcttypefull){reference-type="ref"
    reference="subsec:space-and-ver-rcttypefull"}).

-   `k_image` (line 12) - Key image $\tilde{K_j}$ from Section
    [\[sec:MLSAG\]](#sec:MLSAG){reference-type="ref"
    reference="sec:MLSAG"}, where $j = 1$ since this is the first input.

-   `vout` (lines 24-35) - List of outputs (there are two here)

-   `amount` (line 25) - Deprecated amount field for type 1 transactions

-   `key` (line 27) - One-time destination key for output $t = 0$ as
    described in Section
    [\[sec:one-time-addresses\]](#sec:one-time-addresses){reference-type="ref"
    reference="sec:one-time-addresses"}

-   `extra` (lines 36-39) - Miscellaneous data, including the
    *transaction public key*, i.e. the share secret $r G$ of Section
    [\[sec:one-time-addresses\]](#sec:one-time-addresses){reference-type="ref"
    reference="sec:one-time-addresses"}, and encrypted payment ID from
    Section
    [\[sec:integrated-addresses\]](#sec:integrated-addresses){reference-type="ref"
    reference="sec:integrated-addresses"}. It typically works like this:
    each number is one byte (it can be 0-255), and each kind of thing
    that can be in the field has a 'tag' and 'length'. The tag indicates
    which information comes next, and length indicates how many bytes
    that info occupies. The first number is always a tag. Here, '1'
    indicates a 'transaction public key'. Tx public keys are always 32
    bytes, so we don't need to include the length. Thirty-two numbers
    later we find a new tag '2' which means 'extra nonce', its length is
    '9', and the next byte is '1' which means an 8-byte encrypted
    payment ID (the extra nonce can have fields inside it, for some
    reason). Eight bytes go by, and that's the end of this extra field.
    See [@extra-field-stackexchange] for more details. (note: in the
    original Cryptonote specification the first byte indicated the size
    of the field. Monero doesn't use that.) [@tx-extra-field]

-   `rct_signatures` (lines 40-50) - First part of signature data

-   `type` (line 41) - Signature type; `RCTTypeBulletproof2` is type 4.
    Deprecated RingCT types `RCTTypeFull` and `RCTTypeSimple` were 1 and
    2 respectively. Miner transactions use `RCTTypeNull`, type 0.

-   `txnFee` (line 42) - Transaction fee in clear text, in this case
    0.00003246 XMR

-   `ecdhInfo` (lines 43-47) - 'elliptic curve diffie-hellman info':
    Obscured amount for each of the outputs $t \in \{0, ..., p-1\}$;
    here $p = 2$

-   `amount` (line 44) - Field *amount* at $t = 0$ as described in
    Section
    [\[sec:pedersen_monero\]](#sec:pedersen_monero){reference-type="ref"
    reference="sec:pedersen_monero"}

-   `outPk` (lines 48-49) - Commitments for each output, Section
    [\[sec:ringct-introduction\]](#sec:ringct-introduction){reference-type="ref"
    reference="sec:ringct-introduction"}

-   `rctsig_prunable` (lines 51-132) - Second part of signature data

-   `nbp` (line 52) - Number of Bulletproof range proofs in this
    transaction

-   `bp` (lines 53-80) - Bulletproof proof elements (Bulletproofs were
    not explored in this document, so we will not itemize further)
    $$\Pi_{BP} = (A, S, T_1, T_2, \tau_x, \mu, \mathbb{L}, \mathbb{R}, a, b, t)$$

-   `MGs` (lines 81-129) - MLSAG signatures

-   `ss` (lines 82-103) - Components $r_{i,1}$ and $r_{i,2}$ from the
    first input's MLSAG signature
    $$\sigma_j(\mathfrak{m}) = (c_1, r_{1, 1}, r_{1, 2}, ..., r_{v+1, 1}, r_{v+1, 2})$$

-   `cc` (line 104) - Component $c_1$ from aforementioned MLSAG
    signature

-   `pseudoOuts` (lines 130-131) - Pseudo output commitments $C'^a_j$,
    as described in Section
    [\[sec:pedersen_monero\]](#sec:pedersen_monero){reference-type="ref"
    reference="sec:pedersen_monero"}. Please recall that the sum of
    these commitments will equal the sum of the two output commitments
    of this transaction (plus the transaction fee commitment $f H$).

# Block Content {#appendix:block-content}

In this appendix we show the structure of a sample block, namely the
1582196block after the genesis block. The block has 5 transactions, and
was added to the blockchain at timestamp 2018-05-27 21:56:01 UTC (as
reported by the block's miner).

``` {.numberLines commandchars="\\\\\\{\\}" numbers="left"}
print_block 1582196
timestamp: 1527458161
previous hash: 30bb9b475a08f2ea6fe07a1fd591ea209a7f633a400b2673b8835a975348b0eb
nonce: 2147489363
is orphan: 0
height: 1582196
depth: 2
hash: 50c8e5e51453c2ab85ef99d817e166540b40ef5fd2ed15ebc863091ca2a04594
difficulty: 51333809600
reward: 4634817937431
\{
  "major_version": 7,
  "minor_version": 7,
  "timestamp": 1527458161,
  "prev_id": "30bb9b475a08f2ea6fe07a1fd591ea209a7f633a400b2673b8835a975348b0eb",
  "nonce": 2147489363,
  "miner_tx": \{
    "version": 2,
    "unlock_time": 1582256,
    "vin": [ \{
        "gen": \{
          "height": 1582196
        \}
      \}
    ],
    "vout": [ \{
        "amount": 4634817937431,
        "target": \{
          "key": "39abd5f1c13dc6644d1c43db68691996bb3cd4a8619a37a227667cf2bf055401"
        \}
      \}
    ],
    "extra": [ 1, 89, 148, 148, 232, 110, 49, 77, 175, 158, 102, 45, 72, 201, 193,
    18, 142, 202, 224, 47, 73, 31, 207, 236, 251, 94, 179, 190, 71, 72, 251, 110, 
    134, 2, 8, 1, 242, 62, 180, 82, 253, 252, 0
    ],
    "rct_signatures": \{
      "type": 0
    \}
  \},
  "tx_hashes": [ "e9620db41b6b4e9ee675f7bfdeb9b9774b92aca0c53219247b8f8c7aecf773ae",
                 "6d31593cd5680b849390f09d7ae70527653abb67d8e7fdca9e0154e5712591bf",
                 "329e9c0caf6c32b0b7bf60d1c03655156bf33c0b09b6a39889c2ff9a24e94a54",
                 "447c77a67adeb5dbf402183bc79201d6d6c2f65841ce95cf03621da5a6bffefc",
                 "90a698b0db89bbb0704a4ffa4179dc149f8f8d01269a85f46ccd7f0007167ee4"
  ]
\}
```

## Block components {#block-components .unnumbered}

-   (lines 2-10) - Block information collected by software, not actually
    part of the block properly speaking.

-   `is orphan` (line 5) - Signifies if this block was orphaned. Nodes
    usually store all branches during a fork situation, and discard
    unnecessary branches when a cumulative difficulty winner emerges,
    thereby orphaning the blocks.

-   `depth` (line 7) - In a blockchain copy, the depth of any given
    block is how far back in the chain it is relative to the most recent
    block.

-   `hash` (line 8) - This block's block ID.

-   `difficulty` (line 9) - Difficulty isn't stored in a block, since
    users can compute *all* block difficulties from block timestamps and
    the rules in Section
    [\[sec:difficulty\]](#sec:difficulty){reference-type="ref"
    reference="sec:difficulty"}.

-   `major_version` (line 12) - Corresponds to the protocol version used
    to verify this block.

-   `minor_version` (line 13) - Originally intended as a voting
    mechanism among miners, it now merely reiterates the
    `major_version`. Since the field does not occupy much space, the
    developers probably thought deprecating it would not be worth the
    effort.

-   `timestamp` (line 14) - An integer representation of this block's
    UTC timestamp, as reported by the block's miner.

-   `prev_id` (line 15) - The previous block's block ID. Herein lies the
    essence of Monero's blockchain.

-   `nonce` (line 16) - The nonce used by this block's miner to pass its
    difficulty target. Anyone can recompute the proof of work and verify
    the nonce is valid.

-   `miner_tx` (lines 17-40) - This block's miner transaction.

-   `version` (line 18) - Transaction format/era version; '2'
    corresponds to RingCT.

-   `unlock_time` (line 19) - The miner transaction's output can't be
    spent until the 1582256block, after 59 more blocks have been mined
    (it is a 60 block lock time since it can't be spent until 60 block
    time intervals have passed, e.g. $2*60 = 120$ minutes).

-   `vin` (lines 20-25) - Inputs to the miner tx. There are none, since
    the miner tx is used to generate block rewards and collect
    transaction fees.

-   `gen` (line 21) - Short for 'generate'.

-   `height` (line 22) - The block height for which this miner tx's
    block reward was generated. Each block height can only generate a
    block reward once.

-   `vout` (lines 26-32) - Outputs of the miner tx.

-   `amount` (line 27) - Amount dispersed by the miner tx, containing
    block reward and fees from this block's transactions. Recorded in
    atomic units.

-   `key` (line 29) - One-time address assigning ownership of the miner
    tx's amount.

-   `extra` (lines 33-36) - Extra information for the miner tx,
    including the transaction public key.

-   `type` (line 38) - Type of transaction, in this case '0' for
    `RCTTypeNull`, indicating a miner tx.

-   `tx_hashes` (lines 41-46) - All transaction IDs included in this
    block (but not the miner tx ID, which is
    `06fb3e1cf889bb972774a8535208d98db164394ef2b14ecfe74814170557e6e9`).

# Genesis Block {#appendix:genesis-block}

In this appendix we show the structure of the Monero genesis block. The
block has 0 transactions (it just sends the first block reward to
thankful_for_today [@bitmonero-launched]). Monero's founder did not add
a timestamp, perhaps as a relic of Bytecoin, the coin Monero's code was
forked from, whose creators apparently tried to hide a large pre-mine
[@monero-history], and may operate a shady network of
cryptocurrency-related software and services [@bytecoin-network].

Block 1 was added to the blockchain at timestamp 2014-04-18 10:49:53 UTC
(as reported by the block's miner), so we can assume the genesis block
was created the same day. This corresponds with the launch date
announced by thankful_for_today [@bitmonero-launched].

``` {.numberLines commandchars="\\\\\\{\\}" numbers="left"}
print_block 0
timestamp: 0
previous hash: 0000000000000000000000000000000000000000000000000000000000000000
nonce: 10000
is orphan: 0
height: 0
depth: 1580975
hash: 418015bb9ae982a1975da7d79277c2705727a56894ba0fb246adaabb1f4632e3
difficulty: 1
reward: 17592186044415
\{
  "major_version": 1,
  "minor_version": 0,
  "timestamp": 0,
  "prev_id": "0000000000000000000000000000000000000000000000000000000000000000",
  "nonce": 10000,
  "miner_tx": \{
    "version": 1,
    "unlock_time": 60,
    "vin": [ \{
        "gen": \{
          "height": 0
        \}
      \}
    ],
    "vout": [ \{
        "amount": 17592186044415,
        "target": \{
          "key": "9b2e4c0281c0b02e7c53291a94d1d0cbff8883f8024f5142ee494ffbbd088071"
        \}
      \}
    ],
    "extra": [ 1, 119, 103, 170, 252, 222, 155, 224, 13, 207, 208, 152, 113, 94, 188, 
    247, 244, 16, 218, 235, 197, 130, 253, 166, 157, 36, 162, 142, 157, 11, 200, 144, 
    209
    ],
    "signatures": [ ]
  \},
  "tx_hashes": [ ]
\}
```

## Genesis block components {#genesis-block-components .unnumbered}

Since we used the same software to print the genesis block and the block
from Appendix [2](#appendix:block-content){reference-type="ref"
reference="appendix:block-content"}, the structure appears basically the
same. We point out some unique differences.

-   `difficulty` (line 9) - The genesis block's difficulty is reported
    as 1, which means any nonce could work.

-   `timestamp` (line 14) - The genesis block doesn't have a meaningful
    timestamp.

-   `prev_id` (line 15) - We use an empty 32 bytes for the previous ID,
    by convention.

-   `nonce` (line 16) - $n = 10000$ by convention.

-   `amount` (line 27) - This exactly corresponds to our calculation for
    the first block reward (17.592186044415 XMR) in Section
    [\[subsec:block-reward\]](#subsec:block-reward){reference-type="ref"
    reference="subsec:block-reward"}.

-   `key` (line 29) - The very first Moneroj were dispersed to Monero's
    founder thankful_for_today.

-   `extra` (lines 33-36) - Using the encoding discussed in Appendix
    [1](#appendix:RCTTypeBulletproof2){reference-type="ref"
    reference="appendix:RCTTypeBulletproof2"}, the genesis block's miner
    tx `extra` field just contains one transaction public key.

-   `signatures` (line 37) - There are no signatures in the genesis
    block. This is here as an artifact of the `print_block` function.
    The same is true for `tx_hashes` in line 39.
